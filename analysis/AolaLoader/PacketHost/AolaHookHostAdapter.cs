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
		lock (_syncRoot)
		{
			if (!_disposed)
			{
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

