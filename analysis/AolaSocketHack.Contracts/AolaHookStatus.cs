// 架构角色：跨进程 Hook 运行状态 DTO，必须保持可序列化且不依赖宿主实现。
// 数据流：注入 DLL metrics/status -> Remoting -> 宿主状态显示。
using System;

namespace AolaSocketHack.Contracts;

[Serializable]
public sealed class AolaHookStatus
{
	public DateTime TimestampUtc { get; set; }

	public int ProcessId { get; set; }

	public string Level { get; set; }

	public string Message { get; set; }
}
