// 架构角色：确认战斗入口或首次附着状态，随后按 200ms 间隔经 Flash 原连接提交战斗序列。
// 数据流：plan + 入口 packet/bridge state -> 顺序发送；后续仅检查战斗身份，不逐条等待服务器确认。
using System;
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
	private static readonly TimeSpan MessageDelay = TimeSpan.FromMilliseconds(200);
	private readonly object _syncRoot = new object();
	private readonly IAolaPacketEventSource _packetSource;
	private readonly IAolaCommandSender _sender;
	private readonly BattleBridgeClient _bridge;
	private readonly TimeSpan _battleTimeout;
	private readonly TimeSpan _turnTimeout;
	private readonly TimeSpan _pollInterval;
	private int _identityFlags;
	private int _packetBattleRouteId;
	private int _packetBattleUniqueId;

	public BattleSequenceRunner(
		IAolaPacketEventSource packetSource,
		IAolaCommandSender sender,
		BattleBridgeClient bridge,
		TimeSpan? battleTimeout = null,
		TimeSpan? turnTimeout = null,
		TimeSpan? pollInterval = null)
	{
		_packetSource = packetSource ?? throw new ArgumentNullException(nameof(packetSource));
		_sender = sender ?? throw new ArgumentNullException(nameof(sender));
		_bridge = bridge ?? throw new ArgumentNullException(nameof(bridge));
		_battleTimeout = battleTimeout ?? DefaultBattleTimeout;
		_turnTimeout = turnTimeout ?? DefaultTurnTimeout;
		_pollInterval = pollInterval ?? TimeSpan.FromMilliseconds(200);
		if (_battleTimeout <= TimeSpan.Zero || _turnTimeout <= TimeSpan.Zero ||
			_pollInterval <= TimeSpan.Zero)
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
		}
		_packetSource.PacketReceived += OnPacket;
		try
		{
			bool hasSubmitted = false;
			for (int index = 0; index < plan.SetupItems.Count; index++)
			{
				cancellationToken.ThrowIfCancellationRequested();
				BattleSequenceItem item = plan.SetupItems[index];
				if (hasSubmitted && item.Kind != BattleSequenceItemKind.FlashOwned)
				{
					await Task.Delay(MessageDelay, cancellationToken).ConfigureAwait(false);
				}
				if (item.Kind == BattleSequenceItemKind.PrefixPassThrough)
				{
					Publish(BattleSequenceStatus.SubmittedToFlash,
						string.Format("正在提交普通前缀 {0}_{1}。", item.Request.ExtensionId, item.Request.Command), index);
					AolaCommandSendUpdate prefixSent = await _sender.SendAsync(item.Request, cancellationToken).ConfigureAwait(false);
					hasSubmitted = true;
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
					hasSubmitted = true;
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
					hasSubmitted = true;
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
			for (int groupIndex = 0; groupIndex < plan.TurnGroups.Count; groupIndex++)
			{
				BattleTurnGroup group = plan.TurnGroups[groupIndex];
				int submittedCount = 0;
				for (int itemIndex = 0; itemIndex < group.Items.Count; itemIndex++)
				{
					if (hasSubmitted)
					{
						await Task.Delay(MessageDelay, cancellationToken).ConfigureAwait(false);
					}
					cancellationToken.ThrowIfCancellationRequested();
					// 只检查战斗仍有效；不等待 inputReady/readyEpoch，也不按实时 turn 改写参数。
					BattleBridgeStateResult current = await _bridge.GetStateAsync(cancellationToken).ConfigureAwait(false);
					if (!current.Succeeded)
					{
						Stop("无法读取战斗状态：" + current.Message, groupIndex);
						return;
					}
					if (!current.State.Active || current.State.Ended || current.State.BattleId != battleRouteId)
					{
						Stop("战斗已结束或战斗 ID 已变化。", groupIndex);
						return;
					}
					AolaCommandSendUpdate actionSent = await _sender.SendAsync(
						group.Items[itemIndex].Request, cancellationToken).ConfigureAwait(false);
					if (!WasSubmitted(actionSent))
					{
						Stop(string.Format(
							"回合 {0} 第 {1}/{2} 条未成功提交给 Flash：{3}；本组已提交 {4} 条，不会重试。",
							group.Turn, itemIndex + 1, group.Items.Count, actionSent.Message, submittedCount), groupIndex);
						return;
					}
					hasSubmitted = true;
					submittedCount++;
					Publish(BattleSequenceStatus.SubmittedToFlash,
						string.Format("回合 {0} 第 {1}/{2} 条已提交给 Flash；未等待服务器执行结果。",
							group.Turn, itemIndex + 1, group.Items.Count), groupIndex);
				}
			}
		}
		catch (OperationCanceledException)
		{
			Stop("战斗发送已取消。", -1);
		}
		finally
		{
			_packetSource.PacketReceived -= OnPacket;
		}
	}

	private static bool WasSubmitted(AolaCommandSendUpdate update) =>
		update != null && (update.Status == AolaCommandSendStatus.SubmittedToFlash ||
			update.Status == AolaCommandSendStatus.ServerSucceeded);

	private async Task<BattleBridgeState> AttachCurrentBattleAsync(CancellationToken cancellationToken)
	{
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

		return state;
	}

	private async Task<BattleBridgeState> WaitForBattleAsync(CancellationToken cancellationToken)
	{
		DateTime deadline = DateTime.UtcNow + _battleTimeout;
		while (DateTime.UtcNow < deadline)
		{
			cancellationToken.ThrowIfCancellationRequested();
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

	private void OnPacket(AolaPacketEvent packet)
	{
		if (packet == null || packet.Direction != "接收") return;
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
	}

	private static int ReadInt32(JToken token)
	{
		if (token == null || (token.Type != JTokenType.Integer && token.Type != JTokenType.Float)) return 0;
		double value = token.Value<double>();
		if (value < int.MinValue || value > int.MaxValue || Math.Floor(value) != value || value == 0)
			return 0;
		return (int)value;
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
