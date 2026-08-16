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
