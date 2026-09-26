// 架构角色：跨进程结构化收发消息 DTO，承载方向、连接身份、解码字段和脱敏原始数据。
// 数据流：AolaProtocol -> Remoting -> PacketHost consumers。
using System;

namespace AolaSocketHack.Contracts;

[Serializable]
public sealed class AolaPacketEvent
{
	public DateTime TimestampUtc { get; set; }

	public int ProcessId { get; set; }

	public long SocketHandle { get; set; }

	[field: System.Runtime.Serialization.OptionalField]
	public long? ConnectionPlayerId { get; set; }

	public string Direction { get; set; }

	public int FrameLength { get; set; }

	public long? OuterSequence { get; set; }

	public int? MessageType { get; set; }

	public int? Action { get; set; }

	public int? ExtensionId { get; set; }

	public string Command { get; set; }

	public string ParametersJson { get; set; }

	public string InnerPlainHex { get; set; }

	public string Summary { get; set; }

	public string RawHex { get; set; }

	public bool DecodeSucceeded { get; set; }

	public bool CanExport { get; set; }
}
