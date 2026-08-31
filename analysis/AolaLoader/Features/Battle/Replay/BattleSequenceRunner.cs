using System;
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
	private readonly object _syncRoot = new object();
	private readonly IAolaPacketEventSource _packetSource;
	private readonly IAolaCommandSender _sender;
	private readonly BattleBridgeClient _bridge;
	private readonly TimeSpan _battleTimeout;
	private readonly TimeSpan _turnTimeout;
	private readonly TimeSpan _pollInterval;
	private int _identityFlags;
	private int _packetBattleId;
	private string _expectedSignature;
	private bool _expectedSeen;
	private bool _manualOperationSeen;

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
		if (_battleTimeout <= TimeSpan.Zero || _turnTimeout <= TimeSpan.Zero || _pollInterval <= TimeSpan.Zero)
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
			_packetBattleId = 0;
			_expectedSignature = null;
			_expectedSeen = false;
			_manualOperationSeen = false;
		}
		_packetSource.PacketReceived += OnPacket;
		try
		{
			int lastActionIndex = -1;
			for (int index = 0; index < plan.Items.Count; index++)
			{
				if (plan.Items[index].Kind == BattleSequenceItemKind.TurnAction) lastActionIndex = index;
			}

			int battleId = 0;
			BattleBridgeState readyState = null;
			for (int index = 0; index < plan.Items.Count; index++)
			{
				cancellationToken.ThrowIfCancellationRequested();
				BattleSequenceItem item = plan.Items[index];
				if (item.Kind == BattleSequenceItemKind.Entry)
				{
					Publish(BattleSequenceStatus.SubmittedToFlash, "正在提交战斗入口。", index);
					AolaCommandSendUpdate sent = await _sender.SendAsync(item.Request, cancellationToken).ConfigureAwait(false);
					if (sent.Status != AolaCommandSendStatus.SubmittedToFlash && sent.Status != AolaCommandSendStatus.ServerSucceeded)
					{
						Stop("战斗入口未成功提交给 Flash：" + sent.Message, index);
						return;
					}
					Publish(BattleSequenceStatus.WaitingForBattle, "等待新的 2303/2304/2401 战斗身份和可操作状态。", index);
					readyState = await WaitForBattleAsync(cancellationToken).ConfigureAwait(false);
					if (readyState == null) return;
					battleId = readyState.BattleId;
					continue;
				}
				if (item.Kind == BattleSequenceItemKind.FlashOwned)
				{
					Publish(BattleSequenceStatus.SkippedFlashOwned, "已跳过 preFightLoad；由 Flash 在正确时机自行发送。", index);
					continue;
				}

				if (readyState == null || readyState.BattleId != battleId || readyState.Ended || !readyState.Active)
				{
					Stop("战斗状态已经失效。", index);
					return;
				}
				if (item.Turn != readyState.Turn)
				{
					Stop(string.Format("回合不匹配：消息 turn={0}，Flash turn={1}。", item.Turn, readyState.Turn), index);
					return;
				}

				SetExpected(item.Request);
				int previousEpoch = readyState.ReadyEpoch;
				AolaCommandSendUpdate actionSent = await _sender.SendAsync(item.Request, cancellationToken).ConfigureAwait(false);
				if (actionSent.Status != AolaCommandSendStatus.SubmittedToFlash && actionSent.Status != AolaCommandSendStatus.ServerSucceeded)
				{
					Stop("回合操作未成功提交给 Flash：" + actionSent.Message, index);
					return;
				}
				Publish(BattleSequenceStatus.SubmittedToFlash,
					string.Format("回合 {0} 操作已提交一次。", item.Turn), index);
				if (index == lastActionIndex)
				{
					return;
				}
				Publish(BattleSequenceStatus.WaitingForTurn, "等待 Flash 打开下一次操作窗口。", index);
				readyState = await WaitForNextTurnAsync(
					battleId, previousEpoch, cancellationToken, index).ConfigureAwait(false);
				if (readyState == null) return;
			}
		}
		catch (OperationCanceledException)
		{
			Stop("状态驱动发送已取消。", -1);
		}
		finally
		{
			_packetSource.PacketReceived -= OnPacket;
		}
	}

	private async Task<BattleBridgeState> WaitForBattleAsync(CancellationToken cancellationToken)
	{
		DateTime deadline = DateTime.UtcNow + _battleTimeout;
		while (DateTime.UtcNow < deadline)
		{
			cancellationToken.ThrowIfCancellationRequested();
			BattleBridgeStateResult result = await _bridge.GetStateAsync(cancellationToken).ConfigureAwait(false);
			int flags;
			int packetBattleId;
			lock (_syncRoot) { flags = _identityFlags; packetBattleId = _packetBattleId; }
			if (flags == 7 && packetBattleId > 0 && result.Succeeded && result.State.Active &&
				!result.State.Ended && result.State.InputReady && result.State.BattleId == packetBattleId)
			{
				return result.State;
			}
			await Task.Delay(_pollInterval, cancellationToken).ConfigureAwait(false);
		}
		Stop("等待战斗身份或可操作状态超时；没有自动重发。", -1);
		return null;
	}

	private async Task<BattleBridgeState> WaitForNextTurnAsync(
		int battleId,
		int previousEpoch,
		CancellationToken cancellationToken,
		int itemIndex)
	{
		DateTime deadline = DateTime.UtcNow + _turnTimeout;
		while (DateTime.UtcNow < deadline)
		{
			cancellationToken.ThrowIfCancellationRequested();
			bool manual;
			bool expectedSeen;
			lock (_syncRoot) { manual = _manualOperationSeen; expectedSeen = _expectedSeen; }
			if (manual)
			{
				Stop("检测到队列之外的手动战斗操作，已停止剩余消息。", itemIndex);
				return null;
			}
			BattleBridgeStateResult result = await _bridge.GetStateAsync(cancellationToken).ConfigureAwait(false);
			if (result.Succeeded)
			{
				BattleBridgeState state = result.State;
				if (state.Ended || !state.Active || state.BattleId != battleId)
				{
					Stop("战斗已结束或战斗 ID 已变化。", itemIndex);
					return null;
				}
				if (expectedSeen && state.InputReady && state.ReadyEpoch > previousEpoch)
				{
					ClearExpected();
					return state;
				}
			}
			await Task.Delay(_pollInterval, cancellationToken).ConfigureAwait(false);
		}
		Stop("等待下一回合超时；该操作没有自动重发。", itemIndex);
		return null;
	}

	private void OnPacket(AolaPacketEvent packet)
	{
		if (packet == null) return;
		if (packet.Direction == "接收")
		{
			int flag = packet.Command == "2303" ? 1 : packet.Command == "2304" ? 2 : packet.Command == "2401" ? 4 : 0;
			if (flag == 0) return;
			int battleId = 0;
			if (flag == 4)
			{
				try
				{
					JToken token = JObject.Parse(packet.ParametersJson ?? "{}")["battleUniqueId"];
					if (token != null && (token.Type == JTokenType.Integer || token.Type == JTokenType.Float))
					{
						double value = token.Value<double>();
						if (value > 0 && value <= int.MaxValue && Math.Floor(value) == value) battleId = (int)value;
					}
				}
				catch (JsonException) { }
			}
			lock (_syncRoot)
			{
				_identityFlags |= flag;
				if (battleId > 0) _packetBattleId = battleId;
			}
			return;
		}
		if (packet.Direction != "发送" || packet.ExtensionId != 13 ||
			!IsTurnCommand(packet.Command)) return;
		string signature = CreateSignature(packet.Command, packet.ParametersJson);
		lock (_syncRoot)
		{
			if (_expectedSignature != null && string.Equals(_expectedSignature, signature, StringComparison.Ordinal) && !_expectedSeen)
			{
				_expectedSeen = true;
			}
			else
			{
				_manualOperationSeen = true;
			}
		}
	}

	private void SetExpected(AolaSendRequest request)
	{
		lock (_syncRoot)
		{
			_expectedSignature = CreateSignature(request.Command, request.ParametersJson);
			_expectedSeen = false;
			_manualOperationSeen = false;
		}
	}

	private void ClearExpected()
	{
		lock (_syncRoot) { _expectedSignature = null; _expectedSeen = false; }
	}

	private static bool IsTurnCommand(string command) =>
		command == "1401" || command == "1402" || command == "1403" || command == "1404" ||
		command == "1405" || command == "1406" || command == "1407" || command == "1410";

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
