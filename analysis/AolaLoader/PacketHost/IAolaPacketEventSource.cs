using System;
using AolaSocketHack.Contracts;

namespace AolaLoader.PacketHost;

/// <summary>
/// Host-process boundary for packet, hook-status, and active-send events.
/// Events may be raised from a background thread.
/// </summary>
internal interface IAolaPacketEventSource : IDisposable
{
	event Action<AolaPacketEvent> PacketReceived;

	event Action<AolaHookStatus> StatusReceived;

	event Action<AolaSendResult> SendCompleted;

	string QueueSend(AolaSendRequest request);
}

