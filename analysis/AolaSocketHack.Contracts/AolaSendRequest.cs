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
