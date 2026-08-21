using System;
using System.Threading;

namespace AolaSocketHack.Hooking;

internal sealed class CaptureRuntimeMetrics
{
	private long _capturedChunks;
	private long _capturedBytes;
	private long _ignoredChunks;
	private long _ignoredBytes;
	private long _droppedChunks;
	private long _droppedBytes;
	private long _queueHighWatermark;
	private long _parserLastProgressTicks = DateTime.UtcNow.Ticks;
	private long _parserLagMilliseconds;

	public void Captured(int bytes, int queueCount)
	{
		Interlocked.Increment(ref _capturedChunks);
		Interlocked.Add(ref _capturedBytes, Math.Max(0, bytes));
		UpdateMaximum(ref _queueHighWatermark, queueCount);
	}

	public void Ignored(int bytes)
	{
		Interlocked.Increment(ref _ignoredChunks);
		Interlocked.Add(ref _ignoredBytes, Math.Max(0, bytes));
	}

	public void Dropped(int bytes)
	{
		Interlocked.Increment(ref _droppedChunks);
		Interlocked.Add(ref _droppedBytes, Math.Max(0, bytes));
	}

	public void ParserProgress(DateTime enqueuedUtc)
	{
		DateTime now = DateTime.UtcNow;
		Interlocked.Exchange(ref _parserLastProgressTicks, now.Ticks);
		long lag = Math.Max(0L, (long)(now - enqueuedUtc).TotalMilliseconds);
		Interlocked.Exchange(ref _parserLagMilliseconds, lag);
	}

	public CaptureRuntimeSnapshot Snapshot()
	{
		return new CaptureRuntimeSnapshot(
			Interlocked.Read(ref _capturedChunks),
			Interlocked.Read(ref _capturedBytes),
			Interlocked.Read(ref _ignoredChunks),
			Interlocked.Read(ref _ignoredBytes),
			Interlocked.Read(ref _droppedChunks),
			Interlocked.Read(ref _droppedBytes),
			Interlocked.Read(ref _queueHighWatermark),
			new DateTime(Interlocked.Read(ref _parserLastProgressTicks), DateTimeKind.Utc),
			Interlocked.Read(ref _parserLagMilliseconds));
	}

	private static void UpdateMaximum(ref long target, long value)
	{
		long current;
		do
		{
			current = Interlocked.Read(ref target);
			if (value <= current)
			{
				return;
			}
		}
		while (Interlocked.CompareExchange(ref target, value, current) != current);
	}
}

internal sealed class CaptureRuntimeSnapshot
{
	public CaptureRuntimeSnapshot(long capturedChunks, long capturedBytes, long ignoredChunks, long ignoredBytes, long droppedChunks, long droppedBytes, long queueHighWatermark, DateTime parserLastProgressUtc, long parserLagMilliseconds)
	{
		CapturedChunks = capturedChunks;
		CapturedBytes = capturedBytes;
		IgnoredChunks = ignoredChunks;
		IgnoredBytes = ignoredBytes;
		DroppedChunks = droppedChunks;
		DroppedBytes = droppedBytes;
		QueueHighWatermark = queueHighWatermark;
		ParserLastProgressUtc = parserLastProgressUtc;
		ParserLagMilliseconds = parserLagMilliseconds;
	}

	public long CapturedChunks { get; }
	public long CapturedBytes { get; }
	public long IgnoredChunks { get; }
	public long IgnoredBytes { get; }
	public long DroppedChunks { get; }
	public long DroppedBytes { get; }
	public long QueueHighWatermark { get; }
	public DateTime ParserLastProgressUtc { get; }
	public long ParserLagMilliseconds { get; }
}
