using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using AolaSocketHack.Contracts;
using AolaSocketHack.Protocol;

namespace AolaSocketHack.Transport;

internal sealed class AolaCaptureEngine : IDisposable
{
	private const int MaximumConnectionBufferedBytes = 16 * 1024 * 1024;
	private const int MaximumPolicyBytes = 64 * 1024;
	private static readonly byte[] PolicyPrefix = Encoding.ASCII.GetBytes("<cross-domain-policy>");
	private static readonly byte[] PolicyRequestPrefix = Encoding.ASCII.GetBytes("<policy-file-request/>");
	private readonly ConcurrentDictionary<long, ConnectionState> _connections = new ConcurrentDictionary<long, ConnectionState>();
	private readonly Action<AolaPacketEvent> _publish;
	private readonly int _processId = Process.GetCurrentProcess().Id;
	private long _bufferOverflows;
	private long _protocolErrors;

	public AolaCaptureEngine(Action<AolaPacketEvent> publish)
	{
		_publish = publish ?? throw new ArgumentNullException(nameof(publish));
	}

	public void NoteConnect(long socket, int port)
	{
		ConnectionState state = _connections.GetOrAdd(socket, key => new ConnectionState());
		lock (state.SyncRoot)
		{
			state.LastActivityUtc = DateTime.UtcNow;
			if (port >= 8000 && port <= 8100)
			{
				state.Candidate = true;
			}
		}
	}

	public void Remove(long socket)
	{
		if (_connections.TryRemove(socket, out ConnectionState state))
		{
			lock (state.SyncRoot)
			{
				state.ClearSensitiveData();
			}
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
			if (bytes.Length > MaximumConnectionBufferedBytes - state.Outgoing.Count - state.Incoming.Count || !state.Outgoing.TryAppend(bytes))
			{
				System.Threading.Interlocked.Increment(ref _bufferOverflows);
				return;
			}
			if (state.Outgoing.CouldStartWith(PolicyRequestPrefix))
			{
				bool policyExceeded = false;
				if (state.Outgoing.Count < PolicyRequestPrefix.Length || !state.Outgoing.TryTakeNullTerminated(MaximumPolicyBytes, out _, out policyExceeded))
				{
					if (policyExceeded)
					{
						System.Threading.Interlocked.Increment(ref _protocolErrors);
					}
					return;
				}
			}
			bool invalidLength;
			while (state.Outgoing.TryTakeFrame(out byte[] frame, out invalidLength))
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
			if (invalidLength)
			{
				System.Threading.Interlocked.Increment(ref _protocolErrors);
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
			if (bytes.Length > MaximumConnectionBufferedBytes - state.Outgoing.Count - state.Incoming.Count || !state.Incoming.TryAppend(bytes))
			{
				System.Threading.Interlocked.Increment(ref _bufferOverflows);
				return;
			}
			if (state.Incoming.CouldStartWith(PolicyPrefix))
			{
				if (state.Incoming.Count < PolicyPrefix.Length)
				{
					return;
				}
				if (!state.Incoming.TryTakeNullTerminated(MaximumPolicyBytes, out byte[] policy, out bool policyExceeded))
				{
					if (policyExceeded)
					{
						System.Threading.Interlocked.Increment(ref _protocolErrors);
					}
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
			bool invalidLength;
			while (state.Incoming.TryTakeFrame(out byte[] frame, out invalidLength))
			{
				state.Confirmed = true;
				_publish(AolaProtocol.ParseServerFrame(socket, _processId, frame));
			}
			if (invalidLength)
			{
				System.Threading.Interlocked.Increment(ref _protocolErrors);
			}
		}
	}

	public int CleanupIdle(DateTime cutoffUtc)
	{
		int removed = 0;
		foreach (KeyValuePair<long, ConnectionState> item in _connections)
		{
			ConnectionState state = item.Value;
			if (state.LastActivityUtc >= cutoffUtc || !_connections.TryRemove(item.Key, out ConnectionState removedState))
			{
				continue;
			}
			lock (removedState.SyncRoot)
			{
				removedState.ClearSensitiveData();
			}
			removed++;
		}
		return removed;
	}

	public void Dispose()
	{
		foreach (long socket in _connections.Keys)
		{
			Remove(socket);
		}
	}

	public AolaCaptureEngineMetrics GetMetrics()
	{
		long bufferedBytes = 0;
		foreach (ConnectionState state in _connections.Values)
		{
			lock (state.SyncRoot)
			{
				bufferedBytes += state.Outgoing.Count + state.Incoming.Count;
			}
		}
		return new AolaCaptureEngineMetrics(
			_connections.Count,
			bufferedBytes,
			System.Threading.Interlocked.Read(ref _bufferOverflows),
			System.Threading.Interlocked.Read(ref _protocolErrors));
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
			ClearLoginFrame();
			LoginFrame = frame == null ? null : (byte[])frame.Clone();
		}

		public void ClearSensitiveData()
		{
			Outgoing.Clear();
			Incoming.Clear();
			ClearLoginFrame();
		}

		private void ClearLoginFrame()
		{
			if (LoginFrame != null)
			{
				Array.Clear(LoginFrame, 0, LoginFrame.Length);
				LoginFrame = null;
			}
		}
	}
}

internal sealed class AolaCaptureEngineMetrics
{
	public AolaCaptureEngineMetrics(int connections, long bufferedBytes, long bufferOverflows, long protocolErrors)
	{
		Connections = connections;
		BufferedBytes = bufferedBytes;
		BufferOverflows = bufferOverflows;
		ProtocolErrors = protocolErrors;
	}

	public int Connections { get; }
	public long BufferedBytes { get; }
	public long BufferOverflows { get; }
	public long ProtocolErrors { get; }
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
