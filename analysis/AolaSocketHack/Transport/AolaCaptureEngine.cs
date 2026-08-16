using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using AolaSocketHack.Contracts;
using AolaSocketHack.Protocol;

namespace AolaSocketHack.Transport;

internal sealed class AolaCaptureEngine
{
	private static readonly byte[] PolicyPrefix = Encoding.ASCII.GetBytes("<cross-domain-policy>");
	private readonly ConcurrentDictionary<long, ConnectionState> _connections = new ConcurrentDictionary<long, ConnectionState>();
	private readonly Action<AolaPacketEvent> _publish;
	private readonly int _processId = Process.GetCurrentProcess().Id;

	public AolaCaptureEngine(Action<AolaPacketEvent> publish)
	{
		_publish = publish ?? throw new ArgumentNullException(nameof(publish));
	}

	public void NoteConnect(long socket, int port)
	{
		ConnectionState state = _connections.GetOrAdd(socket, key => new ConnectionState());
		state.LastActivityUtc = DateTime.UtcNow;
		if (port >= 8000 && port <= 8100)
		{
			state.Candidate = true;
		}
	}

	public void Remove(long socket)
	{
		if (_connections.TryRemove(socket, out ConnectionState state))
		{
			state.ClearSensitiveData();
		}
	}

	public void CaptureSend(long socket, byte[] bytes)
	{
		if (bytes == null || bytes.Length == 0)
		{
			return;
		}
		ConnectionState state = _connections.GetOrAdd(socket, key => new ConnectionState());
		lock (state.SyncRoot)
		{
			state.LastActivityUtc = DateTime.UtcNow;
			state.Outgoing.Append(bytes);
			while (state.Outgoing.TryTakeFrame(out byte[] frame))
			{
				if (!state.Confirmed && AolaProtocol.LooksLikeLoginFrame(frame))
				{
					state.Candidate = true;
					state.Confirmed = true;
				}
				if (state.Candidate)
				{
					AolaPacketEvent packet = AolaProtocol.ParseClientFrame(socket, _processId, frame, state.Protocol);
					if (packet.DecodeSucceeded && packet.Command == "logIn")
					{
						state.ReplaceLoginFrame(frame);
					}
					if (packet.DecodeSucceeded || state.Confirmed)
					{
						state.Confirmed = true;
						_publish(packet);
					}
				}
			}
		}
	}

	public void CaptureReceive(long socket, byte[] bytes)
	{
		if (bytes == null || bytes.Length == 0)
		{
			return;
		}
		ConnectionState state = _connections.GetOrAdd(socket, key => new ConnectionState());
		lock (state.SyncRoot)
		{
			state.LastActivityUtc = DateTime.UtcNow;
			state.Incoming.Append(bytes);
			if (state.Incoming.CouldStartWith(PolicyPrefix))
			{
				if (state.Incoming.Count < PolicyPrefix.Length)
				{
					return;
				}
				if (!state.Incoming.TryTakeNullTerminated(out byte[] policy))
				{
					return;
				}
				state.Candidate = true;
				state.Confirmed = true;
				_publish(AolaProtocol.CreatePolicyEvent(socket, _processId, policy));
			}
			if (!state.Candidate)
			{
				return;
			}
			while (state.Incoming.TryTakeFrame(out byte[] frame))
			{
				state.Confirmed = true;
				_publish(AolaProtocol.ParseServerFrame(socket, _processId, frame));
			}
		}
	}

	public bool TryGetSendContext(long requestedSocket, out AolaSendContext context, out string error)
	{
		context = null;
		error = null;
		IEnumerable<KeyValuePair<long, ConnectionState>> candidates = _connections;
		if (requestedSocket != 0)
		{
			candidates = candidates.Where(item => item.Key == requestedSocket);
		}
		foreach (KeyValuePair<long, ConnectionState> item in candidates.OrderByDescending(value => value.Value.LastActivityUtc))
		{
			ConnectionState state = item.Value;
			lock (state.SyncRoot)
			{
				if (!state.Confirmed || !state.Protocol.HasLogin || state.LoginFrame == null)
				{
					continue;
				}
				context = new AolaSendContext(item.Key, (byte[])state.LoginFrame.Clone());
				return true;
			}
		}
		error = requestedSocket == 0
			? "尚未捕获奥拉星登录帧，无法建立独立发包连接"
			: "指定的游戏连接已关闭或尚未捕获登录帧";
		return false;
	}

	private sealed class ConnectionState
	{
		public object SyncRoot { get; } = new object();

		public FrameBuffer Outgoing { get; } = new FrameBuffer();

		public FrameBuffer Incoming { get; } = new FrameBuffer();

		public AolaProtocolState Protocol { get; } = new AolaProtocolState();

		public bool Candidate { get; set; }

		public bool Confirmed { get; set; }

		public DateTime LastActivityUtc { get; set; }

		public byte[] LoginFrame { get; private set; }

		public void ReplaceLoginFrame(byte[] frame)
		{
			ClearSensitiveData();
			LoginFrame = frame == null ? null : (byte[])frame.Clone();
		}

		public void ClearSensitiveData()
		{
			if (LoginFrame != null)
			{
				Array.Clear(LoginFrame, 0, LoginFrame.Length);
				LoginFrame = null;
			}
		}
	}
}

internal sealed class AolaSendContext
{
	public AolaSendContext(long sourceSocket, byte[] loginFrame)
	{
		SourceSocket = sourceSocket;
		LoginFrame = loginFrame;
	}

	public long SourceSocket { get; }

	public byte[] LoginFrame { get; }
}
