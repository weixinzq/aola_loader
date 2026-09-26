// 架构角色：把 Contracts 的静态 Remoting 事件适配为可注入、可退订的宿主 packet 事件源。
// 数据流：AolaHookHostService events -> IAolaPacketEventSource consumers；异常按订阅者隔离。
using System;
using AolaSocketHack.Contracts;

namespace AolaLoader.PacketHost;

/// <summary>
/// The single host-side adapter for the legacy static remoting events.
/// Existing consumers remain on the legacy path until their migration batch.
/// </summary>
internal sealed class AolaHookHostAdapter : IAolaPacketEventSource
{
	private readonly object _syncRoot = new object();
	private bool _disposed;
	private Action<AolaPacketEvent> _packetReceived;
	private Action<AolaHookStatus> _statusReceived;
	private Action<AolaSendResult> _sendCompleted;

	public AolaHookHostAdapter()
	{
		// Contracts 使用静态事件跨越 Remoting 边界；只有本适配器直接订阅，避免全局状态扩散。
		AolaHookHostService.PacketReceived += OnPacketReceived;
		AolaHookHostService.StatusReceived += OnStatusReceived;
		AolaHookHostService.SendCompleted += OnSendCompleted;
	}

	public event Action<AolaPacketEvent> PacketReceived
	{
		add
		{
			lock (_syncRoot)
			{
				ThrowIfDisposed();
				_packetReceived += value;
			}
		}
		remove
		{
			lock (_syncRoot)
			{
				_packetReceived -= value;
			}
		}
	}

	public event Action<AolaHookStatus> StatusReceived
	{
		add
		{
			lock (_syncRoot)
			{
				ThrowIfDisposed();
				_statusReceived += value;
			}
		}
		remove
		{
			lock (_syncRoot)
			{
				_statusReceived -= value;
			}
		}
	}

	public event Action<AolaSendResult> SendCompleted
	{
		add
		{
			lock (_syncRoot)
			{
				ThrowIfDisposed();
				_sendCompleted += value;
			}
		}
		remove
		{
			lock (_syncRoot)
			{
				_sendCompleted -= value;
			}
		}
	}

	public string QueueSend(AolaSendRequest request)
	{
		lock (_syncRoot)
		{
			ThrowIfDisposed();
			return AolaHookHostService.QueueSend(request);
		}
	}

	public void Dispose()
	{
		lock (_syncRoot)
		{
			if (_disposed)
			{
				return;
			}

			_disposed = true;
			AolaHookHostService.PacketReceived -= OnPacketReceived;
			AolaHookHostService.StatusReceived -= OnStatusReceived;
			AolaHookHostService.SendCompleted -= OnSendCompleted;
			_packetReceived = null;
			_statusReceived = null;
			_sendCompleted = null;
		}
	}

	private void OnPacketReceived(AolaPacketEvent packet)
	{
		// Remoting 回调线程不是 WinForms UI 线程；消费者需要自行切回 UI 或保持线程安全。
		lock (_syncRoot)
		{
			if (!_disposed)
			{
				// 逐订阅者隔离异常，日志失败不能阻断战斗状态和抓包窗口。
				PacketEventDispatch.InvokeSafely(_packetReceived, packet);
			}
		}
	}

	private void OnStatusReceived(AolaHookStatus status)
	{
		lock (_syncRoot)
		{
			if (!_disposed)
			{
				PacketEventDispatch.InvokeSafely(_statusReceived, status);
			}
		}
	}

	private void OnSendCompleted(AolaSendResult result)
	{
		lock (_syncRoot)
		{
			if (!_disposed)
			{
				PacketEventDispatch.InvokeSafely(_sendCompleted, result);
			}
		}
	}

	private void ThrowIfDisposed()
	{
		if (_disposed)
		{
			throw new ObjectDisposedException(nameof(AolaHookHostAdapter));
		}
	}
}

