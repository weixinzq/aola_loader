using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Text;
using AolaSocketHack.Protocol;

namespace AolaSocketHack.Hooking;

internal enum SocketCaptureKind
{
	Unknown,
	Game,
	Policy,
	Ignore
}

internal sealed class AolaSocketCaptureFilter
{
	private const int MaximumProbeBytes = 4 * 1024;
	private static readonly byte[] PolicyRequestPrefix = Encoding.ASCII.GetBytes("<policy-file-request/>");
	private static readonly byte[] PolicyResponsePrefix = Encoding.ASCII.GetBytes("<cross-domain-policy>");
	private readonly ConcurrentDictionary<long, SocketState> _sockets = new ConcurrentDictionary<long, SocketState>();
	private readonly Func<long, int> _peerPortLookup;
	private readonly bool _captureAllSockets;

	public AolaSocketCaptureFilter(Func<long, int> peerPortLookup = null, bool captureAllSockets = false)
	{
		_peerPortLookup = peerPortLookup ?? WinsockNative.TryGetPeerPort;
		_captureAllSockets = captureAllSockets;
	}

	public SocketCaptureKind NoteConnect(long socket, int port)
	{
		SocketState state = _sockets.GetOrAdd(socket, key => new SocketState());
		lock (state.SyncRoot)
		{
			if (state.Sidecar)
			{
				state.Kind = SocketCaptureKind.Ignore;
				state.LastActivityUtc = DateTime.UtcNow;
				return state.Kind;
			}
			state.Port = port;
			state.EndpointKnown = port > 0;
			state.PeerLookupAttempted = true;
			state.Kind = _captureAllSockets || IsGamePort(port) ? SocketCaptureKind.Game : SocketCaptureKind.Ignore;
			state.LastActivityUtc = DateTime.UtcNow;
			state.ClearProbe();
			return state.Kind;
		}
	}

	public SocketCaptureKind ClassifyForIo(long socket)
	{
		SocketState state = _sockets.GetOrAdd(socket, key => new SocketState());
		lock (state.SyncRoot)
		{
			state.LastActivityUtc = DateTime.UtcNow;
			if (_captureAllSockets)
			{
				state.Kind = SocketCaptureKind.Game;
				return state.Kind;
			}
			if (state.Kind != SocketCaptureKind.Unknown || state.PeerLookupAttempted)
			{
				return state.Kind;
			}
			state.PeerLookupAttempted = true;
			int port;
			try
			{
				port = _peerPortLookup(socket);
			}
			catch
			{
				port = 0;
			}
			if (port > 0)
			{
				state.Port = port;
				state.EndpointKnown = true;
				state.Kind = IsGamePort(port) ? SocketCaptureKind.Game : SocketCaptureKind.Ignore;
			}
			return state.Kind;
		}
	}

	public SocketCaptureKind ObserveProbe(long socket, byte[] bytes, bool sending, out byte[] previousProbe)
	{
		previousProbe = null;
		SocketState state = _sockets.GetOrAdd(socket, key => new SocketState());
		lock (state.SyncRoot)
		{
			state.LastActivityUtc = DateTime.UtcNow;
			if (state.Kind != SocketCaptureKind.Unknown)
			{
				return state.Kind;
			}
			if (state.ProbeSending.HasValue && state.ProbeSending.Value != sending)
			{
				state.ClearProbe();
			}
			state.ProbeSending = sending;
			int existingCount = state.Probe.Count;
			int available = MaximumProbeBytes - existingCount;
			if (bytes != null && available > 0)
			{
				int count = Math.Min(available, bytes.Length);
				for (int index = 0; index < count; index++)
				{
					state.Probe.Add(bytes[index]);
				}
			}

			SocketCaptureKind detected = DetectProbe(state.Probe, sending);
			if (detected != SocketCaptureKind.Unknown)
			{
				if (existingCount > 0)
				{
					previousProbe = state.Probe.GetRange(0, existingCount).ToArray();
				}
				state.Kind = detected;
				state.ClearProbe();
				return detected;
			}
			if (state.Probe.Count >= MaximumProbeBytes)
			{
				state.Kind = SocketCaptureKind.Ignore;
				state.ClearProbe();
			}
			return state.Kind;
		}
	}

	public void MarkSidecar(long socket)
	{
		SocketState state = _sockets.GetOrAdd(socket, key => new SocketState());
		lock (state.SyncRoot)
		{
			state.Kind = SocketCaptureKind.Ignore;
			state.Sidecar = true;
			state.EndpointKnown = true;
			state.PeerLookupAttempted = true;
			state.LastActivityUtc = DateTime.UtcNow;
			state.ClearProbe();
		}
	}

	public void Remove(long socket)
	{
		if (_sockets.TryRemove(socket, out SocketState state))
		{
			lock (state.SyncRoot)
			{
				state.ClearProbe();
			}
		}
	}

	public int CleanupIdle(DateTime cutoffUtc)
	{
		int removed = 0;
		foreach (KeyValuePair<long, SocketState> item in _sockets)
		{
			if (item.Value.LastActivityUtc >= cutoffUtc || !_sockets.TryRemove(item.Key, out SocketState state))
			{
				continue;
			}
			lock (state.SyncRoot)
			{
				state.ClearProbe();
			}
			removed++;
		}
		return removed;
	}

	private static bool IsGamePort(int port)
	{
		return port >= 8000 && port <= 8100;
	}

	private static SocketCaptureKind DetectProbe(List<byte> probe, bool sending)
	{
		if (sending && StartsWith(probe, PolicyRequestPrefix))
		{
			return SocketCaptureKind.Policy;
		}
		if (!sending && StartsWith(probe, PolicyResponsePrefix))
		{
			return SocketCaptureKind.Policy;
		}
		if (sending && probe.Count >= 15)
		{
			byte[] header = probe.GetRange(0, 15).ToArray();
			if (AolaProtocol.LooksLikeLoginFrame(header))
			{
				return SocketCaptureKind.Game;
			}
		}
		return SocketCaptureKind.Unknown;
	}

	private static bool StartsWith(List<byte> value, byte[] prefix)
	{
		if (value.Count < prefix.Length)
		{
			return false;
		}
		for (int index = 0; index < prefix.Length; index++)
		{
			if (value[index] != prefix[index])
			{
				return false;
			}
		}
		return true;
	}

	private sealed class SocketState
	{
		public object SyncRoot { get; } = new object();
		public List<byte> Probe { get; } = new List<byte>(MaximumProbeBytes);
		public SocketCaptureKind Kind { get; set; }
		public int Port { get; set; }
		public bool EndpointKnown { get; set; }
		public bool PeerLookupAttempted { get; set; }
		public bool Sidecar { get; set; }
		public bool? ProbeSending { get; set; }
		public DateTime LastActivityUtc { get; set; } = DateTime.UtcNow;

		public void ClearProbe()
		{
			for (int index = 0; index < Probe.Count; index++)
			{
				Probe[index] = 0;
			}
			Probe.Clear();
			ProbeSending = null;
		}
	}
}
