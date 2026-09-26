// 架构角色：遗留跨进程发送结果 DTO，供兼容事件与拒绝反馈使用。
// 数据流：注入端/host service -> PacketHost；不代表当前页面桥发送结果。
using System;

namespace AolaSocketHack.Contracts;

[Serializable]
public sealed class AolaSendResult
{
	public string RequestId { get; set; }

	public DateTime CompletedAtUtc { get; set; }

	public int ProcessId { get; set; }

	public long SocketHandle { get; set; }

	public bool Succeeded { get; set; }

	public string Message { get; set; }
}
