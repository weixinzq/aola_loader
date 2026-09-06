using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using AolaLoader.Features.ActiveSend;
using AolaLoader.Features.Battle.Bridge;
using AolaLoader.PacketHost;
using AolaSocketHack.Contracts;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace AolaLoader.Features.Battle.Replay;

internal sealed class BattleSequenceRunner
{
	private static readonly TimeSpan DefaultBattleTimeout = TimeSpan.FromSeconds(60);
	private static readonly TimeSpan DefaultTurnTimeout = TimeSpan.FromSeconds(45);
	private static readonly TimeSpan DefaultBatchProbeTimeout = TimeSpan.FromSeconds(1);
	private readonly object _syncRoot = new object();
	private readonly IAolaPacketEventSource _packetSource;
	private readonly IAolaCommandSender _sender;
	private readonly BattleBridgeClient _bridge;
	private readonly TimeSpan _battleTimeout;
	private readonly TimeSpan _turnTimeout;
	private readonly TimeSpan _pollInterval;
	private readonly TimeSpan _batchProbeTimeout;
	private int _identityFlags;
	private int _packetBattleRouteId;
	private int _packetBattleUniqueId;
	private int _activeBattleRouteId;
	private readonly Queue<string> _expectedSignatures = new Queue<string>();
	private string _expectedResultCommand;
	private bool _expectedSeen;
	private bool _serverReadySeen;
	private bool _resultSeen;
	private bool _manualOperationSeen;

	public BattleSequenceRunner(
		IAolaPacketEventSource packetSource,
		IAolaCommandSender sender,
		BattleBridgeClient bridge,
		TimeSpan? battleTimeout = null,
		TimeSpan? turnTimeout = null,
		TimeSpan? pollInterval = null,
		TimeSpan? batchProbeTimeout = null)
	{
		_packetSource = packetSource ?? throw new ArgumentNullException(nameof(packetSource));
		_sender = sender ?? throw new ArgumentNullException(nameof(sender));
		_bridge = bridge ?? throw new ArgumentNullException(nameof(bridge));
		_battleTimeout = battleTimeout ?? DefaultBattleTimeout;
		_turnTimeout = turnTimeout ?? DefaultTurnTimeout;
		_pollInterval = pollInterval ?? TimeSpan.FromMilliseconds(200);
		_batchProbeTimeout = batchProbeTimeout ?? DefaultBatchProbeTimeout;
		if (_battleTimeout <= TimeSpan.Zero || _turnTimeout <= TimeSpan.Zero ||
			_pollInterval <= TimeSpan.Zero || _batchProbeTimeout <= TimeSpan.Zero)
		{
			throw new ArgumentOutOfRangeException(nameof(battleTimeout));
		}
	}

	public event Action<BattleSequenceUpdate> StatusChanged;

	public async Task RunAsync(BattleSequencePlan plan, CancellationToken cancellationToken)
	{
		if (plan == null) throw new ArgumentNullException(nameof(plan));
		lock (_syncRoot)
		{
			_identityFlags = 0;
			_packetBattleRouteId = 0;
			_packetBattleUniqueId = 0;
			_activeBattleRouteId = 0;
			_expectedSignatures.Clear();
			_expectedResultCommand = null;
			_expectedSeen = false;
			_serverReadySeen = false;
			_resultSeen = false;
			_manualOperationSeen = false;
		}
		_packetSource.PacketReceived += OnPacket;
		try
		{
			for (int index = 0; index < plan.SetupItems.Count; index++)
			{
				cancellationToken.ThrowIfCancellationRequested();
				BattleSequenceItem item = plan.SetupItems[index];
				if (item.Kind == BattleSequenceItemKind.PrefixPassThrough)
				{
					Publish(BattleSequenceStatus.SubmittedToFlash,
						string.Format("正在提交普通前缀 {0}_{1}。", item.Request.ExtensionId, item.Request.Command), index);
					AolaCommandSendUpdate prefixSent = await _sender.SendAsync(item.Request, cancellationToken).ConfigureAwait(false);
					if (!WasSubmitted(prefixSent))
					{
						Stop("普通前缀未成功提交给 Flash：" + prefixSent.Message, index);
						return;
					}
					continue;
				}
				if (item.Kind == BattleSequenceItemKind.Prelude)
				{
					Publish(BattleSequenceStatus.SubmittedToFlash, "正在提交活动入口 74_1。", index);
					AolaCommandSendUpdate preludeSent = await _sender.SendAsync(item.Request, cancellationToken).ConfigureAwait(false);
					if (!WasSubmitted(preludeSent))
					{
						Stop("活动入口未成功提交给 Flash：" + preludeSent.Message, index);
						return;
					}
					continue;
				}
				if (item.Kind == BattleSequenceItemKind.Entry)
				{
					Publish(BattleSequenceStatus.SubmittedToFlash, "正在提交战斗入口。", index);
					AolaCommandSendUpdate sent = await _sender.SendAsync(item.Request, cancellationToken).ConfigureAwait(false);
					if (!WasSubmitted(sent))
					{
						Stop("战斗入口未成功提交给 Flash：" + sent.Message, index);
						return;
					}
					continue;
				}
				if (item.Kind == BattleSequenceItemKind.FlashOwned)
				{
					Publish(BattleSequenceStatus.SkippedFlashOwned, "已跳过 preFightLoad；由 Flash 在正确时机自行发送。", index);
					continue;
				}
				throw new InvalidOperationException("战斗计划的初始化阶段包含无效项目。");
			}

			int battleRouteId;
			BattleBridgeState readyState;
			if (plan.StartsNewBattle)
			{
				Publish(BattleSequenceStatus.WaitingForBattle, "等待新的 2303/2304/2401 战斗身份和可操作状态。", -1);
				readyState = await WaitForBattleAsync(cancellationToken).ConfigureAwait(false);
				if (readyState == null) return;
				battleRouteId = readyState.BattleId;
			}
			else
			{
				Publish(BattleSequenceStatus.WaitingForBattle, "正在附着当前战斗并检查当前操作窗口。", -1);
				readyState = await AttachCurrentBattleAsync(cancellationToken).ConfigureAwait(false);
				if (readyState == null) return;
				battleRouteId = readyState.BattleId;
			}
			lock (_syncRoot) { _activeBattleRouteId = battleRouteId; }

			bool requiresFreshInput = true;
			for (int groupIndex = 0; groupIndex < plan.TurnGroups.Count; groupIndex++)
			{
				cancellationToken.ThrowIfCancellationRequested();
				BattleTurnGroup group = plan.TurnGroups[groupIndex];

				if (IsManualOperationSeen())    //直接发送
				{
					Stop("检测到队列之外的手动战斗操作，已停止剩余消息。", groupIndex);
					return;
				}

				if (readyState == null || readyState.BattleId != battleRouteId || readyState.Ended || !readyState.Active)
				{
					Stop("战斗状态已经失效。", groupIndex);
					return;
				}
				int submittedCount = 0;
				for (int itemIndex = 0; itemIndex < group.Items.Count; itemIndex++)
				{
					if (IsManualOperationSeen())
					{
						Stop(string.Format(
							"回合 {0} 检测到队列之外或顺序不匹配的战斗操作；本组已提交 {1}/{2} 条，已停止且不会重试。",
							group.Turn, submittedCount, group.Items.Count), groupIndex);
						return;
					}
					if (requiresFreshInput && readyState.Turn != group.Turn)
					{
						Stop(string.Format(
							"回合不匹配：回合 {0} 第 {1}/{2} 条等待发送，但 Flash turn={3}。",
							group.Turn, itemIndex + 1, group.Items.Count, readyState.Turn), groupIndex);
						return;
					}
					if (!TrySetExpected(group.Items[itemIndex]))
					{
						Stop("检测到队列之外的手动战斗操作，已停止剩余消息。", groupIndex);
						return;
					}
					int previousEpoch = readyState.ReadyEpoch;
					AolaCommandSendUpdate actionSent = await _sender.SendAsync(
						group.Items[itemIndex].Request, cancellationToken).ConfigureAwait(false);
					if (!WasSubmitted(actionSent))
					{
						Stop(string.Format(
							"回合 {0} 第 {1}/{2} 条未成功提交给 Flash：{3}；本组已提交 {4} 条，不会重试。",
							group.Turn, itemIndex + 1, group.Items.Count, actionSent.Message, submittedCount), groupIndex);
						return;
					}
					submittedCount++;
					Publish(BattleSequenceStatus.SubmittedToFlash,
						string.Format("回合 {0} 第 {1}/{2} 条已提交一次。",
							group.Turn, itemIndex + 1, group.Items.Count), groupIndex);
					bool hasNextMessage = itemIndex < group.Items.Count - 1 ||
						groupIndex < plan.TurnGroups.Count - 1;
					Publish(BattleSequenceStatus.WaitingForTurn,
						string.Format("等待回合 {0} 第 {1}/{2} 条发送抓包及服务器 2405 确认。",
							group.Turn, itemIndex + 1, group.Items.Count), groupIndex);
					BattleActionAdvance advance = await WaitForActionProgressAsync(
						battleRouteId, previousEpoch, hasNextMessage, cancellationToken, groupIndex).ConfigureAwait(false);
					if (advance == null) return;
					readyState = advance.State;
					requiresFreshInput = advance.RequiresFreshInput;
					if (hasNextMessage && !requiresFreshInput)
					{
						Publish(BattleSequenceStatus.WaitingForTurn,
							"服务器已确认本条，但本批尚未返回执行结果；继续提交同一操作批的下一条。", groupIndex);
					}
				}
				Publish(BattleSequenceStatus.SubmittedToFlash,
					string.Format("回合 {0} 的 {1} 条操作已按服务器确认逐条提交。", group.Turn, group.Items.Count), groupIndex);
				if (groupIndex == plan.TurnGroups.Count - 1)
				{
					return;
				}
			}
		}
		catch (OperationCanceledException)
		{
			Stop("状态驱动发送已取消。", -1);
		}
		finally
		{
			_packetSource.PacketReceived -= OnPacket;
			ClearExpected();
		}
	}

	private static bool WasSubmitted(AolaCommandSendUpdate update) =>
		update != null && (update.Status == AolaCommandSendStatus.SubmittedToFlash ||
			update.Status == AolaCommandSendStatus.ServerSucceeded);

	private async Task<BattleBridgeState> AttachCurrentBattleAsync(CancellationToken cancellationToken)
	{
		if (IsManualOperationSeen())
		{
			Stop("检测到队列之外的手动战斗操作，已停止剩余消息。", -1);
			return null;
		}

		BattleBridgeStateResult initial = await _bridge.GetStateAsync(cancellationToken).ConfigureAwait(false);
		if (!initial.Succeeded)
		{
			Stop("无法读取当前战斗状态：" + initial.Message, -1);
			return null;
		}
		BattleBridgeState state = initial.State;
		if (!state.Active || state.Ended || state.BattleId == 0)
		{
			Stop("当前没有可附着的活动战斗。", -1);
			return null;
		}

		int battleRouteId = state.BattleId;
		DateTime deadline = DateTime.UtcNow + _turnTimeout;
		while (!state.InputReady)
		{
			cancellationToken.ThrowIfCancellationRequested();
			if (IsManualOperationSeen())
			{
				Stop("检测到队列之外的手动战斗操作，已停止剩余消息。", -1);
				return null;
			}
			if (DateTime.UtcNow >= deadline)
			{
				Stop("等待当前战斗操作窗口超时；没有自动重发。", -1);
				return null;
			}

			await Task.Delay(_pollInterval, cancellationToken).ConfigureAwait(false);
			BattleBridgeStateResult result = await _bridge.GetStateAsync(cancellationToken).ConfigureAwait(false);
			if (!result.Succeeded)
			{
				Stop("无法读取当前战斗状态：" + result.Message, -1);
				return null;
			}
			state = result.State;
			if (state.Ended || !state.Active || state.BattleId != battleRouteId)
			{
				Stop("当前战斗已结束或战斗 ID 已变化。", -1);
				return null;
			}
		}

		if (IsManualOperationSeen())
		{
			Stop("检测到队列之外的手动战斗操作，已停止剩余消息。", -1);
			return null;
		}
		return state;
	}

	private async Task<BattleBridgeState> WaitForBattleAsync(CancellationToken cancellationToken)
	{
		DateTime deadline = DateTime.UtcNow + _battleTimeout;
		while (DateTime.UtcNow < deadline)
		{
			cancellationToken.ThrowIfCancellationRequested();
			if (IsManualOperationSeen())
			{
				Stop("检测到队列之外的手动战斗操作，已停止剩余消息。", -1);
				return null;
			}
			BattleBridgeStateResult result = await _bridge.GetStateAsync(cancellationToken).ConfigureAwait(false);
			int flags;
			int packetBattleRouteId;
			int packetBattleUniqueId;
			lock (_syncRoot)
			{
				flags = _identityFlags;
				packetBattleRouteId = _packetBattleRouteId;
				packetBattleUniqueId = _packetBattleUniqueId;
			}
			if (flags == 7 && packetBattleRouteId != 0 && packetBattleUniqueId > 0 &&
				result.Succeeded && result.State.Active && !result.State.Ended && result.State.InputReady &&
				result.State.BattleId == packetBattleRouteId)
			{
				return result.State;
			}
			await Task.Delay(_pollInterval, cancellationToken).ConfigureAwait(false);
		}
		Stop("等待战斗身份或可操作状态超时；没有自动重发。", -1);
		return null;
	}

	private async Task<BattleActionAdvance> WaitForActionProgressAsync(
		int battleRouteId,
		int previousEpoch,
		bool hasNextMessage,
		CancellationToken cancellationToken,
		int itemIndex)
	{
		DateTime deadline = DateTime.UtcNow + _turnTimeout;
		BattleBridgeState state = null;
		while (DateTime.UtcNow < deadline)
		{
			cancellationToken.ThrowIfCancellationRequested();
			bool manual;
			bool expectedSeen;
			bool serverReadySeen;
			lock (_syncRoot)
			{
				manual = _manualOperationSeen;
				expectedSeen = _expectedSeen;
				serverReadySeen = _serverReadySeen;
			}
			if (manual)
			{
				Stop("检测到队列之外的手动战斗操作，已停止剩余消息。", itemIndex);
				return null;
			}
			BattleBridgeStateResult result = await _bridge.GetStateAsync(cancellationToken).ConfigureAwait(false);
			if (!result.Succeeded)
			{
				Stop("无法读取战斗状态：" + result.Message, itemIndex);
				return null;
			}
			state = result.State;
			if (state.Ended || !state.Active || state.BattleId != battleRouteId)
			{
				Stop("战斗已结束或战斗 ID 已变化。", itemIndex);
				return null;
			}
			if (expectedSeen && serverReadySeen)
			{
				break;
			}
			await Task.Delay(_pollInterval, cancellationToken).ConfigureAwait(false);
		}
		if (state == null || !WasServerReadySeen())
		{
			Stop("等待本条发送抓包或服务器 2405 确认超时；该操作没有自动重发。", itemIndex);
			return null;
		}
		DateTime probeDeadline = DateTime.UtcNow + _batchProbeTimeout;
		if (probeDeadline > deadline) probeDeadline = deadline;
		while (DateTime.UtcNow < probeDeadline)
		{
			cancellationToken.ThrowIfCancellationRequested();
			if (IsManualOperationSeen())
			{
				Stop("检测到队列之外的手动战斗操作，已停止剩余消息。", itemIndex);
				return null;
			}

			BattleBridgeStateResult result = await _bridge.GetStateAsync(cancellationToken).ConfigureAwait(false);
			if (!result.Succeeded)
			{
				Stop("无法读取战斗状态：" + result.Message, itemIndex);
				return null;
			}
			state = result.State;
			if (state.Ended || !state.Active || state.BattleId != battleRouteId)
			{
				Stop("战斗已结束或战斗 ID 已变化。", itemIndex);
				return null;
			}
			if (WasResultSeen() || state.ReadyEpoch > previousEpoch)
			{
				if (!hasNextMessage)
				{
					ClearExpected();
					return new BattleActionAdvance(state, false);
				}
				return await WaitForNextInputAsync(
					battleRouteId, previousEpoch, deadline, cancellationToken, itemIndex).ConfigureAwait(false);
			}
			await Task.Delay(_pollInterval, cancellationToken).ConfigureAwait(false);
		}

		if (!hasNextMessage)
		{
			Stop("服务器已确认最后一条，但未观察到本批执行结果；输入可能缺少同一操作批的后续消息。", itemIndex);
			return null;
		}
		ClearExpected();
		return new BattleActionAdvance(state, false);
	}

	private async Task<BattleActionAdvance> WaitForNextInputAsync(
		int battleRouteId,
		int previousEpoch,
		DateTime deadline,
		CancellationToken cancellationToken,
		int itemIndex)
	{
		while (DateTime.UtcNow < deadline)
		{
			cancellationToken.ThrowIfCancellationRequested();
			if (IsManualOperationSeen())
			{
				Stop("检测到队列之外的手动战斗操作，已停止剩余消息。", itemIndex);
				return null;
			}
			BattleBridgeStateResult result = await _bridge.GetStateAsync(cancellationToken).ConfigureAwait(false);
			if (!result.Succeeded)
			{
				Stop("无法读取战斗状态：" + result.Message, itemIndex);
				return null;
			}
			BattleBridgeState state = result.State;
			if (state.Ended || !state.Active || state.BattleId != battleRouteId)
			{
				Stop("战斗已结束或战斗 ID 已变化。", itemIndex);
				return null;
			}
			if (state.InputReady && state.ReadyEpoch > previousEpoch)
			{
				ClearExpected();
				return new BattleActionAdvance(state, true);
			}
			await Task.Delay(_pollInterval, cancellationToken).ConfigureAwait(false);
		}
		Stop("等待下一次操作窗口超时；该操作没有自动重发。", itemIndex);
		return null;
	}

	private void OnPacket(AolaPacketEvent packet)
	{
		if (packet == null) return;
		if (packet.Direction == "接收")
		{
			bool currentPlayerPacket = IsCurrentPlayerPacket(packet.ParametersJson);
			lock (_syncRoot)
			{
				if (_expectedSeen && currentPlayerPacket && packet.Command == "2405") _serverReadySeen = true;
				if (_expectedSeen && currentPlayerPacket &&
					string.Equals(packet.Command, _expectedResultCommand, StringComparison.Ordinal))
					_resultSeen = true;
			}
			int flag = packet.Command == "2303" ? 1 : packet.Command == "2304" ? 2 : packet.Command == "2401" ? 4 : 0;
			if (flag == 0) return;
			int battleRouteId = 0;
			int battleUniqueId = 0;
			if (flag == 4)
			{
				try
				{
					JObject parameters = JObject.Parse(packet.ParametersJson ?? "{}");
					battleRouteId = ReadInt32(parameters["br"]);
					battleUniqueId = ReadInt32(parameters["battleUniqueId"]);
					if (battleUniqueId < 0) battleUniqueId = 0;
				}
				catch (JsonException) { }
			}
			lock (_syncRoot)
			{
				_identityFlags |= flag;
				if (battleRouteId != 0) _packetBattleRouteId = battleRouteId;
				if (battleUniqueId > 0) _packetBattleUniqueId = battleUniqueId;
			}
			return;
		}
		if (packet.Direction != "发送" || packet.ExtensionId != 13 ||
			!IsTurnCommand(packet.Command)) return;
		string signature = CreateSignature(packet.Command, packet.ParametersJson);
		lock (_syncRoot)
		{
			if (_expectedSignatures.Count > 0 &&
				string.Equals(_expectedSignatures.Peek(), signature, StringComparison.Ordinal))
			{
				_expectedSignatures.Dequeue();
				_expectedSeen = _expectedSignatures.Count == 0;
			}
			else
			{
				_manualOperationSeen = true;
			}
		}
	}

	private static int ReadInt32(JToken token)
	{
		if (token == null || (token.Type != JTokenType.Integer && token.Type != JTokenType.Float)) return 0;
		double value = token.Value<double>();
		if (value < int.MinValue || value > int.MaxValue || Math.Floor(value) != value || value == 0)
			return 0;
		return (int)value;
	}

	private bool IsCurrentPlayerPacket(string parametersJson)
	{
		int battleRouteId;
		lock (_syncRoot) { battleRouteId = _activeBattleRouteId; }
		if (battleRouteId == 0) return false;
		try
		{
			int requestId = ReadInt32(JObject.Parse(parametersJson ?? "{}")["reqId"]);
			return requestId != 0 && Math.Abs((long)requestId) == Math.Abs((long)battleRouteId);
		}
		catch (JsonException)
		{
			return false;
		}
	}

	private bool TrySetExpected(BattleSequenceItem item)
	{
		lock (_syncRoot)
		{
			if (_manualOperationSeen) return false;
			_expectedSignatures.Clear();
			_expectedSignatures.Enqueue(CreateSignature(item.Request.Command, item.Request.ParametersJson));
			_expectedResultCommand = GetResultCommand(item.Request.Command);
			_expectedSeen = false;
			_serverReadySeen = false;
			_resultSeen = false;
			return true;
		}
	}

	private void ClearExpected()
	{
		lock (_syncRoot)
		{
			_expectedSignatures.Clear();
			_expectedResultCommand = null;
			_expectedSeen = false;
			_serverReadySeen = false;
			_resultSeen = false;
		}
	}

	private bool WasServerReadySeen()
	{
		lock (_syncRoot) { return _expectedSeen && _serverReadySeen; }
	}

	private bool WasResultSeen()
	{
		lock (_syncRoot) { return _resultSeen; }
	}

	private static string GetResultCommand(string command)
	{
		switch (command)
		{
			case "1401": return "2411";
			case "1402": return "2412";
			case "1403": return "2413";
			case "1404": return "2414";
			case "1405": return "2415";
			case "1406": return "2416";
			case "1407": return "2417";
			case "1410": return "2420";
			default: return null;
		}
	}

	private static bool IsTurnCommand(string command) =>
		command == "1401" || command == "1402" || command == "1403" || command == "1404" ||
			command == "1405" || command == "1406" || command == "1407" || command == "1410";

	private sealed class BattleActionAdvance
	{
		public BattleActionAdvance(BattleBridgeState state, bool requiresFreshInput)
		{
			State = state;
			RequiresFreshInput = requiresFreshInput;
		}

		public BattleBridgeState State { get; }
		public bool RequiresFreshInput { get; }
	}

	private bool IsManualOperationSeen()
	{
		lock (_syncRoot) { return _manualOperationSeen; }
	}

	private static string CreateSignature(string command, string parametersJson)
	{
		try { return command + "|" + Canonicalize(JObject.Parse(parametersJson ?? "{}")).ToString(Formatting.None); }
		catch (JsonException) { return command + "|<invalid>"; }
	}

	private static JToken Canonicalize(JToken token)
	{
		if (token is JObject obj)
		{
			return new JObject(obj.Properties()
				.OrderBy(property => property.Name, StringComparer.Ordinal)
				.Select(property => new JProperty(property.Name, Canonicalize(property.Value))));
		}
		if (token is JArray array)
			return new JArray(array.Select(Canonicalize));
		return token.DeepClone();
	}

	private void Stop(string message, int itemIndex) => Publish(BattleSequenceStatus.Stopped, message, itemIndex);

	private void Publish(BattleSequenceStatus status, string message, int itemIndex)
	{
		Action<BattleSequenceUpdate> handlers = StatusChanged;
		if (handlers == null) return;
		BattleSequenceUpdate update = new BattleSequenceUpdate(status, message, itemIndex);
		foreach (Action<BattleSequenceUpdate> handler in handlers.GetInvocationList())
		{
			try { handler(update); } catch { }
		}
	}
}

internal enum BattleSequenceStatus
{
	WaitingForBattle,
	WaitingForTurn,
	SubmittedToFlash,
	SkippedFlashOwned,
	Stopped
}

internal sealed class BattleSequenceUpdate
{
	public BattleSequenceUpdate(BattleSequenceStatus status, string message, int itemIndex)
	{
		Status = status;
		Message = message ?? string.Empty;
		ItemIndex = itemIndex;
	}
	public BattleSequenceStatus Status { get; }
	public string Message { get; }
	public int ItemIndex { get; }
}
