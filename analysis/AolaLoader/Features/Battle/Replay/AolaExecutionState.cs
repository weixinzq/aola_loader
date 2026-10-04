// 架构角色：长期订阅 Hook 事件，保存文本执行所需的连接和战斗生命周期。
// 数据流：PacketHost packet/status -> 不可变快照 + 状态变化信号；不读取 socket。
using System;
using System.Threading;
using System.Threading.Tasks;
using AolaLoader.PacketHost;
using AolaSocketHack.Contracts;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
namespace AolaLoader.Features.Battle.Replay;

internal enum AolaExecutionPhase { Unknown, Idle, Entering, Active, Ending }
internal sealed class AolaExecutionSnapshot
{
	public int ProcessId;
	public long SocketHandle;
	public long? PlayerId;
	// 捕获失效也递增，避免后续回包恢复状态后旧任务继续提交。
	public long SessionEpoch;
	public long BattleEpoch;
	public int BattleId;
	public long BattleUniqueId;
	public int Turn;
	public bool Connected;
	public AolaExecutionPhase Phase;
	public string Error;
	public AolaExecutionSnapshot Clone() => (AolaExecutionSnapshot)MemberwiseClone();
}
internal sealed class AolaExecutionState : IDisposable
{
	private readonly object _sync = new object();
	private readonly IAolaPacketEventSource _source;
	private AolaExecutionSnapshot _current = new AolaExecutionSnapshot { Phase = AolaExecutionPhase.Unknown };
	private TaskCompletionSource<bool> _changed = NewSignal();
	public AolaExecutionState(IAolaPacketEventSource source)
	{
		_source = source;
		source.PacketReceived += OnPacket;
		source.StatusReceived += OnStatus;
	}
	private static TaskCompletionSource<bool> NewSignal() =>
		new TaskCompletionSource<bool>(TaskCreationOptions.RunContinuationsAsynchronously);
	public AolaExecutionSnapshot Read(out Task changed)
	{ lock (_sync) { changed = _changed.Task; return _current.Clone(); } }
	public AolaExecutionSnapshot Current => Read(out _);
	private void Notify()
	{ var previous = _changed; _changed = NewSignal(); previous.TrySetResult(true); }
	public void BeginEntry()
	{
		lock (_sync)
		{
			if (_current.Phase != AolaExecutionPhase.Idle)
				throw new InvalidOperationException("上一场尚未确认结束或状态未知；请先 #wait，或显式发送 1404 后 #wait。");
			_current.Phase = AolaExecutionPhase.Entering;
			_current.BattleId = 0; _current.BattleUniqueId = 0; _current.Error = null;
			Notify();
		}
	}
	public void MarkEnding()
	{ lock (_sync) { if (_current.Phase == AolaExecutionPhase.Active) _current.Phase = AolaExecutionPhase.Ending; Notify(); } }
	public void Invalidate(string error)
	{ lock (_sync) { _current.SessionEpoch++; _current.Phase = AolaExecutionPhase.Unknown; _current.Error = error; Notify(); } }
	private void OnStatus(AolaHookStatus status)
	{
		if (status == null || string.IsNullOrEmpty(status.ExecutionEvent)) return;
		lock (_sync)
		{
			if (status.ProcessId != _current.ProcessId || ! _current.Connected) return;
			if (status.SocketHandle.HasValue && status.SocketHandle.Value != _current.SocketHandle) return;
			_current.SessionEpoch++;
			_current.Phase = AolaExecutionPhase.Unknown;
			_current.Error = status.Message;
			if (status.ExecutionEvent == "ConnectionClosed") _current.Connected = false;
			Notify();
		}
	}
	private void OnPacket(AolaPacketEvent packet)
	{
		if (packet == null || packet.Direction != "接收" || !packet.ConnectionPlayerId.HasValue) return;
		lock (_sync)
		{
			if (!_current.Connected || _current.ProcessId != packet.ProcessId ||
				_current.SocketHandle != packet.SocketHandle || _current.PlayerId != packet.ConnectionPlayerId)
			{
				_current = new AolaExecutionSnapshot
				{
					ProcessId = packet.ProcessId, SocketHandle = packet.SocketHandle,
					PlayerId = packet.ConnectionPlayerId, Connected = true,
					SessionEpoch = _current.SessionEpoch + 1,
					BattleEpoch = _current.BattleEpoch, Phase = AolaExecutionPhase.Unknown
				};
			}
			if (!packet.DecodeSucceeded) { _current.SessionEpoch++; _current.Phase = AolaExecutionPhase.Unknown; _current.Error = "游戏消息解码失败，执行状态不完整。"; Notify(); return; }
			JObject p;
			try { p = JObject.Parse(packet.ParametersJson ?? "{}"); }
			catch (JsonException) { _current.SessionEpoch++; _current.Phase = AolaExecutionPhase.Unknown; _current.Error = "游戏回包参数无法解析。"; Notify(); return; }
			string cmd = packet.Command;
			if (cmd == "joinOK")
			{
				if (_current.Phase == AolaExecutionPhase.Active || _current.Phase == AolaExecutionPhase.Entering || _current.Phase == AolaExecutionPhase.Ending)
				{ _current.SessionEpoch++; _current.Phase = AolaExecutionPhase.Unknown; _current.Error = "活动战斗期间房间已改变。"; }
				else { _current.Phase = AolaExecutionPhase.Idle; _current.BattleId = 0; _current.BattleUniqueId = 0; _current.Error = null; }
			}
			else if (cmd == "logout" || cmd == "logKO" || cmd == "leaveRoom")
			{ _current.SessionEpoch++; _current.Phase = AolaExecutionPhase.Unknown; _current.Error = "当前游戏连接或房间已失效。"; }
			else if (cmd == "2303" && !string.IsNullOrEmpty(p.Value<string>("msg")))
			{ _current.SessionEpoch++; _current.Phase = AolaExecutionPhase.Unknown; _current.Error = p.Value<string>("msg"); }
			else if (cmd == "2303")
			{
				int id = p.Value<int?>("battleId") ?? 0;
				if (id != 0 && (_current.Phase == AolaExecutionPhase.Idle || _current.Phase == AolaExecutionPhase.Entering ||
					_current.Phase == AolaExecutionPhase.Unknown))
				{
					_current.BattleEpoch++; _current.BattleId = id; _current.BattleUniqueId = 0;
					_current.Phase = AolaExecutionPhase.Active; _current.Error = null;
				}
				else if (id != 0 && id != _current.BattleId)
				{ _current.SessionEpoch++; _current.Phase = AolaExecutionPhase.Unknown; _current.Error = "战斗身份已改变。"; }
			}
			else if (cmd == "2401" && (_current.Phase == AolaExecutionPhase.Active || _current.Phase == AolaExecutionPhase.Entering))
			{
				int route = p.Value<int?>("br") ?? _current.BattleId;
				long unique = p.Value<long?>("battleUniqueId") ?? 0;
				if (_current.BattleUniqueId != 0 && (unique != _current.BattleUniqueId || route != _current.BattleId))
				{ _current.SessionEpoch++; _current.Phase = AolaExecutionPhase.Unknown; _current.Error = "2401 战斗身份已改变。"; }
				else { _current.BattleId = route; _current.BattleUniqueId = unique; }
			}
			else if (cmd == "2402") _current.Turn = p.Value<int?>("pt") ?? _current.Turn;
			else if (cmd == "2403" && (_current.Phase == AolaExecutionPhase.Active || _current.Phase == AolaExecutionPhase.Ending))
			{
				long? unique = p.Value<long?>("battleUniqueId");
				if (_current.BattleUniqueId != 0 && unique == _current.BattleUniqueId)
				{ _current.Phase = AolaExecutionPhase.Idle; _current.Error = null; }
			}
			Notify();
		}
	}
	public static async Task AwaitChangeAsync(Task changed, CancellationToken token)
	{
		var cancelled = NewSignal();
		using (token.Register(() => cancelled.TrySetCanceled()))
		{
			await Task.WhenAny(changed, cancelled.Task).ConfigureAwait(false);
			token.ThrowIfCancellationRequested();
		}
	}
	public void Dispose()
	{
		_source.PacketReceived -= OnPacket; _source.StatusReceived -= OnStatus;
		Invalidate("宿主执行状态已释放。");
	}
}
