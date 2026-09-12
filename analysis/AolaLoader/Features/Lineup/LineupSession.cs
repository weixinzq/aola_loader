using System;
using System.IO;
using System.Diagnostics;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using AolaLoader.Features.ActiveSend;
using AolaLoader.PacketHost;
using AolaSocketHack.Contracts;
using Newtonsoft.Json.Linq;

namespace AolaLoader.Features.Lineup;

// One operation owns one subscription. No response bodies or credentials are persisted.
internal sealed class LineupSession : IDisposable
{
	private readonly IAolaPacketEventSource _source;
	private readonly IAolaCommandSender _sender;
	private readonly object _sync = new object();
	private TaskCompletionSource<JObject> _pending;
	private string _command;
	private string _response;
	private JObject _parameters;
	private int _extension;
	private bool _sent;
	private readonly Stopwatch _sendClock = new Stopwatch();
	private bool _disposed;
	private int? _process;
	private long? _socket;
	private long? _player;
	private string _failure;

	public LineupSession(IAolaPacketEventSource source, IAolaCommandSender sender)
	{
		_source = source;
		_sender = sender;
		_source.PacketReceived += OnPacket;
	}

	public void SetOwner(long playerId)
	{
		lock (_sync)
		{
			Check();
			if (playerId <= 0 || (_player.HasValue && _player != playerId)) throw new InvalidDataException("当前账号身份不一致，已停止。");
			_player = playerId;
		}
	}

	public void Check()
	{
		lock (_sync)
		{
			if (_disposed) throw new ObjectDisposedException(nameof(LineupSession));
			if (_failure != null) throw new InvalidOperationException(_failure);
		}
	}

	public async Task<JObject> RequestAsync(int extension, string command, JObject parameters, string response, CancellationToken token)
	{
		token.ThrowIfCancellationRequested();
		TimeSpan remaining;
		lock (_sync)
		{
			Check();
			remaining = _sendClock.IsRunning ? TimeSpan.FromMilliseconds(500) - _sendClock.Elapsed : TimeSpan.Zero;
		}
		if (remaining > TimeSpan.Zero) await Task.Delay(remaining, token).ConfigureAwait(false);
		token.ThrowIfCancellationRequested();
		TaskCompletionSource<JObject> pending;
		lock (_sync)
		{
			Check();
			if (_pending != null) throw new InvalidOperationException("阵容操作必须串行执行。");
			_pending = pending = new TaskCompletionSource<JObject>(TaskCreationOptions.RunContinuationsAsynchronously);
			_extension = extension;
			_command = command;
			_response = response;
			_parameters = (JObject)parameters.DeepClone();
			_sent = false;
		}
		try
		{
			AolaCommandSendUpdate submitted = await _sender.SendAsync(new AolaSendRequest
			{
				ExtensionId = extension, Command = command, ParametersJson = parameters.ToString(Newtonsoft.Json.Formatting.None)
			}, token).ConfigureAwait(false);
			if (submitted.Status != AolaCommandSendStatus.SubmittedToFlash && submitted.Status != AolaCommandSendStatus.ServerSucceeded)
				throw new InvalidOperationException(command + " 未成功提交：" + submitted.Message);
			using (var deadline = CancellationTokenSource.CreateLinkedTokenSource(token))
			{
				deadline.CancelAfter(TimeSpan.FromSeconds(15));
				using (deadline.Token.Register(() => pending.TrySetCanceled()))
				{
					JObject result;
					try { result = await pending.Task.ConfigureAwait(false); }
					catch (OperationCanceledException) when (!token.IsCancellationRequested)
					{
						string stage;
						lock (_sync) stage = _sent
							? "已捕获发送，但未收到匹配的 " + response + " 响应"
							: "Flash 已接受调用，但未捕获到匹配的发送消息";
						int? petId = parameters.Value<int?>("petId") ?? parameters.Value<int?>("id");
						throw new TimeoutException(command + (petId.HasValue ? "（亚比 " + petId.Value + "）" : "")
							+ "：" + stage + "，等待 15 秒后停止，未自动重发。"
							+ (IsMutation(command) ? "已提交的更改仍可能生效。" : ""));
					}
					token.ThrowIfCancellationRequested();
					Check();
					return result;
				}
			}
		}
		finally { lock (_sync) { _pending = null; _parameters = null; } }
	}

	private void Fail(string message)
	{
		_failure = _failure ?? message;
		_pending?.TrySetException(new InvalidOperationException(_failure));
	}

	private static bool IsMutation(string command)
	{
		return new[] { "1222", "1217", "1218", "1219", "1220", "1221", "54_9", "54_25", "54_27",
			"ASC221104_2", "ATT231229_1", "ATT231229_1b", "ATT231229_2",
			"ACK241227_2", "ACK241227_3", "ACK241227_4" }.Contains(command);
	}

	private void OnPacket(AolaPacketEvent packet)
	{
		lock (_sync)
		{
			if (_disposed || _failure != null) return;
			bool outgoing = packet.Direction == "发送";
			bool incoming = packet.Direction == "接收";
			if (!outgoing && !incoming) return;
			bool relevant = IsMutation(packet.Command) || packet.Command == _command || packet.Command == _response;
			if (_process.HasValue && (packet.ProcessId != _process || packet.SocketHandle != _socket))
			{
				if (relevant) Fail("游戏连接发生变化，已停止阵容操作。");
				return;
			}
			if (_process.HasValue && packet.ConnectionPlayerId.HasValue && _player.HasValue && packet.ConnectionPlayerId != _player)
			{
				Fail("当前账号发生变化，已停止阵容操作。");
				return;
			}
			if (incoming && (packet.Command == "2303" || packet.Command == "2401" || packet.Command == "logOK"))
			{
				Fail("检测到进入战斗或重新登录，已停止阵容操作。");
				return;
			}
			try
			{
				if (outgoing)
				{
					if (_pending != null && !_sent && packet.Command == _command && packet.ExtensionId == _extension)
					{
						JObject actual = JObject.Parse(packet.ParametersJson ?? "{}");
						actual.Remove(":ext_seq;");
						if (!JToken.DeepEquals(actual, _parameters)) { Fail("检测到额外的同类操作，请停止手动操作后重试。"); return; }
						_process = packet.ProcessId;
						_socket = packet.SocketHandle;
						if (packet.ConnectionPlayerId.HasValue) SetOwner(packet.ConnectionPlayerId.Value);
						_sent = true;
						_sendClock.Restart();
					}
					else if (IsMutation(packet.Command) || packet.Command == "logIn" || (_pending != null && packet.Command == _command && packet.ExtensionId == _extension)) Fail("检测到额外的同类请求、换宠、配置操作或登录，已停止。");
					return;
				}
				if (_pending == null || !_sent || packet.Command != _response) return;
				JObject result = JObject.Parse(packet.ParametersJson ?? "{}");
				if (packet.ConnectionPlayerId.HasValue) SetOwner(packet.ConnectionPlayerId.Value);
				_pending.TrySetResult(result);
			}
			catch (Exception ex) { Fail("无法读取阵容响应：" + ex.Message); }
		}
	}

	public void Dispose()
	{
		lock (_sync)
		{
			if (_disposed) return;
			_disposed = true;
			_pending?.TrySetCanceled();
		}
		_source.PacketReceived -= OnPacket;
	}
}

