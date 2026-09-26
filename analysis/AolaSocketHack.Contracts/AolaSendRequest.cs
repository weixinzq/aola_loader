// 架构角色：遗留跨进程发送请求 DTO；保留兼容但不是当前生产 ActiveSend 路径。
// 数据流：旧 host queue -> 注入端拒绝结果，当前功能不得依赖它。
using System;

namespace AolaSocketHack.Contracts;

[Serializable]
public sealed class AolaSendRequest
{
	public string RequestId { get; set; }

	public DateTime QueuedAtUtc { get; set; }

	public int ProcessId { get; set; }

	public long SocketHandle { get; set; }

	public int ExtensionId { get; set; }

	public string Command { get; set; }

	public string ParametersJson { get; set; }
}
