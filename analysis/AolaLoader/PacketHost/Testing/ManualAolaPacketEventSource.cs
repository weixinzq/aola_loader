// 架构角色：IAolaPacketEventSource 的手工测试实现，可主动发布 packet、status 和发送结果。
// 数据流：测试触发 -> 真实 feature consumers，不经过 IPC 或 Hook。
using System;
using AolaSocketHack.Contracts;

namespace AolaLoader.PacketHost.Testing;

/// <summary>
/// In-memory event source for module verification and consumer migration tests.
/// It intentionally does not subscribe to the remoting service.
/// </summary>
internal sealed class ManualAolaPacketEventSource : IAolaPacketEventSource
{
	private bool _disposed;

	public event Action<AolaPacketEvent> PacketReceived;

	public event Action<AolaHookStatus> StatusReceived;

	public event Action<AolaSendResult> SendCompleted;

	public Func<AolaSendRequest, string> QueueSendHandler { get; set; }

	public string QueueSend(AolaSendRequest request)
	{
		ThrowIfDisposed();
		if (QueueSendHandler == null)
		{
			throw new InvalidOperationException("QueueSendHandler is not configured.");
		}
		return QueueSendHandler(request);
	}

	public void PublishPacket(AolaPacketEvent packet)
	{
		ThrowIfDisposed();
		PacketEventDispatch.InvokeSafely(PacketReceived, packet);
	}

	public void PublishStatus(AolaHookStatus status)
	{
		ThrowIfDisposed();
		PacketEventDispatch.InvokeSafely(StatusReceived, status);
	}

	public void PublishSendCompleted(AolaSendResult result)
	{
		ThrowIfDisposed();
		PacketEventDispatch.InvokeSafely(SendCompleted, result);
	}

	public void Dispose()
	{
		_disposed = true;
		PacketReceived = null;
		StatusReceived = null;
		SendCompleted = null;
		QueueSendHandler = null;
	}

	private void ThrowIfDisposed()
	{
		if (_disposed)
		{
			throw new ObjectDisposedException(nameof(ManualAolaPacketEventSource));
		}
	}
}

