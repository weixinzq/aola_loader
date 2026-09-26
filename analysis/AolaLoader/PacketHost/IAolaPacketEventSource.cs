// 架构角色：宿主内 packet/status/send-result 的事件端口，隔离消费者与静态 IPC 服务。
// 数据流：PacketHost adapter -> Logger、Battle、Lineup、Packets UI 等订阅者。
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

