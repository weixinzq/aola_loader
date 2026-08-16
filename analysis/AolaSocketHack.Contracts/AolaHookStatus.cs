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
