using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using EasyHook;

namespace AolaSocketHack.Hooking;

internal sealed class WinsockHooks : IDisposable
{
	private const int MaximumCapturedChunk = 16 * 1024 * 1024;
	private const int MaximumProbeChunk = 4 * 1024;
	private const int WsaIoPending = 997;
	private readonly AolaSocketCaptureFilter _filter;
	private readonly Action<long, byte[]> _sendCaptured;
	private readonly Action<long, byte[]> _receiveCaptured;
	private readonly Action<int> _ignored;
	private readonly Action<long, int> _connected;
	private readonly Action<long> _closed;
	private readonly WinsockNative.SendDelegate _sendHandler;
	private readonly WinsockNative.RecvDelegate _recvHandler;
	private readonly WinsockNative.WSASendDelegate _wsaSendHandler;
	private readonly WinsockNative.WSARecvDelegate _wsaRecvHandler;
	private readonly WinsockNative.ConnectDelegate _connectHandler;
	private readonly WinsockNative.CloseSocketDelegate _closeHandler;
	private readonly List<LocalHook> _hooks = new List<LocalHook>();

	public WinsockHooks(AolaSocketCaptureFilter filter, Action<long, byte[]> sendCaptured, Action<long, byte[]> receiveCaptured, Action<int> ignored, Action<long, int> connected, Action<long> closed)
	{
		_filter = filter ?? throw new ArgumentNullException(nameof(filter));
		_sendCaptured = sendCaptured;
		_receiveCaptured = receiveCaptured;
		_ignored = ignored;
		_connected = connected;
		_closed = closed;
		_sendHandler = SendHook;
		_recvHandler = RecvHook;
		_wsaSendHandler = WSASendHook;
		_wsaRecvHandler = WSARecvHook;
		_connectHandler = ConnectHook;
		_closeHandler = CloseSocketHook;
	}

	public void Install()
	{
		Install("send", _sendHandler);
		Install("recv", _recvHandler);
		Install("WSASend", _wsaSendHandler);
		Install("WSARecv", _wsaRecvHandler);
		Install("connect", _connectHandler);
		Install("closesocket", _closeHandler);
	}

	public void Dispose()
	{
		foreach (LocalHook hook in _hooks)
		{
			try
			{
				hook.Dispose();
			}
			catch
			{
			}
		}
		_hooks.Clear();
		LocalHook.Release();
	}

	private void Install(string function, Delegate callback)
	{
		LocalHook hook = LocalHook.Create(LocalHook.GetProcAddress("ws2_32.dll", function), callback, this);
		hook.ThreadACL.SetExclusiveACL(new[] { 0 });
		_hooks.Add(hook);
	}

	private int SendHook(IntPtr socket, IntPtr buffer, int length, int flags)
	{
		long handle = socket.ToInt64();
		SocketCaptureKind kind = SafeClassify(handle);
		int result = WinsockNative.Send(socket, buffer, length, flags);
		int error = Marshal.GetLastWin32Error();
		try
		{
			if (result > 0)
			{
				CaptureSingle(handle, buffer, result, true, kind);
			}
		}
		catch
		{
		}
		WinsockNative.WSASetLastError(error);
		return result;
	}

	private int RecvHook(IntPtr socket, IntPtr buffer, int length, int flags)
	{
		long handle = socket.ToInt64();
		SocketCaptureKind kind = SafeClassify(handle);
		int result = WinsockNative.Recv(socket, buffer, length, flags);
		int error = Marshal.GetLastWin32Error();
		try
		{
			if (result > 0)
			{
				CaptureSingle(handle, buffer, result, false, kind);
			}
		}
		catch
		{
		}
		WinsockNative.WSASetLastError(error);
		return result;
	}

	private int WSASendHook(IntPtr socket, IntPtr buffers, uint bufferCount, IntPtr bytesSent, uint flags, IntPtr overlapped, IntPtr completionRoutine)
	{
		long handle = socket.ToInt64();
		SocketCaptureKind kind = SafeClassify(handle);
		int result = WinsockNative.WSASend(socket, buffers, bufferCount, bytesSent, flags, overlapped, completionRoutine);
		int error = Marshal.GetLastWin32Error();
		try
		{
			if (ShouldCaptureWsaSend(result, error, overlapped))
			{
				int? actual = ReadTransferredCount(result, bytesSent);
				CaptureBuffers(handle, buffers, bufferCount, actual, true, kind);
			}
		}
		catch
		{
		}
		WinsockNative.WSASetLastError(error);
		return result;
	}

	private int WSARecvHook(IntPtr socket, IntPtr buffers, uint bufferCount, IntPtr bytesReceived, IntPtr flags, IntPtr overlapped, IntPtr completionRoutine)
	{
		long handle = socket.ToInt64();
		SocketCaptureKind kind = SafeClassify(handle);
		int result = WinsockNative.WSARecv(socket, buffers, bufferCount, bytesReceived, flags, overlapped, completionRoutine);
		int error = Marshal.GetLastWin32Error();
		try
		{
			int? actual = ReadTransferredCount(result, bytesReceived);
			if (actual.HasValue && actual.Value > 0)
			{
				CaptureBuffers(handle, buffers, bufferCount, actual, false, kind);
			}
		}
		catch
		{
		}
		WinsockNative.WSASetLastError(error);
		return result;
	}

	private int ConnectHook(IntPtr socket, IntPtr name, int nameLength)
	{
		int port = TryReadPort(name, nameLength);
		long handle = socket.ToInt64();
		SocketCaptureKind kind = _filter.NoteConnect(handle, port);
		int result = WinsockNative.Connect(socket, name, nameLength);
		int error = Marshal.GetLastWin32Error();
		try
		{
			if ((kind == SocketCaptureKind.Game || kind == SocketCaptureKind.Policy) && port > 0)
			{
				_connected?.Invoke(handle, port);
			}
		}
		catch
		{
		}
		WinsockNative.WSASetLastError(error);
		return result;
	}

	private int CloseSocketHook(IntPtr socket)
	{
		long handle = socket.ToInt64();
		try
		{
			_filter.Remove(handle);
			_closed?.Invoke(handle);
		}
		catch
		{
		}
		return WinsockNative.CloseSocket(socket);
	}

	internal static bool ShouldCaptureWsaSend(int result, int error, IntPtr overlapped)
	{
		return result == 0 ||
			result != 0 && overlapped != IntPtr.Zero && error == WsaIoPending;
	}

	private static int? ReadTransferredCount(int result, IntPtr countPointer)
	{
		if (result != 0 || countPointer == IntPtr.Zero)
		{
			return null;
		}
		return unchecked((int)(uint)Marshal.ReadInt32(countPointer));
	}

	private static byte[] SafeCopy(IntPtr buffer, int length)
	{
		if (buffer == IntPtr.Zero || length <= 0 || length > MaximumCapturedChunk)
		{
			return null;
		}
		byte[] result = new byte[length];
		Marshal.Copy(buffer, result, 0, length);
		return result;
	}

	private SocketCaptureKind SafeClassify(long socket)
	{
		try
		{
			return _filter.ClassifyForIo(socket);
		}
		catch
		{
			return SocketCaptureKind.Ignore;
		}
	}

	private void CaptureSingle(long socket, IntPtr buffer, int length, bool sending, SocketCaptureKind kind)
	{
		if (kind == SocketCaptureKind.Ignore)
		{
			_ignored?.Invoke(length);
			return;
		}
		if (kind == SocketCaptureKind.Game || kind == SocketCaptureKind.Policy)
		{
			Dispatch(socket, SafeCopy(buffer, length), sending);
			return;
		}
		byte[] probe = SafeCopy(buffer, Math.Min(length, MaximumProbeChunk));
		SocketCaptureKind detected = _filter.ObserveProbe(socket, probe, sending, out byte[] previousProbe);
		if (detected == SocketCaptureKind.Game || detected == SocketCaptureKind.Policy)
		{
			Dispatch(socket, previousProbe, sending);
			Dispatch(socket, SafeCopy(buffer, length), sending);
		}
		else if (detected == SocketCaptureKind.Ignore)
		{
			_ignored?.Invoke(length);
		}
	}

	private void CaptureBuffers(long socket, IntPtr buffers, uint bufferCount, int? actual, bool sending, SocketCaptureKind kind)
	{
		if (kind == SocketCaptureKind.Ignore)
		{
			_ignored?.Invoke(actual ?? 0);
			return;
		}
		if (kind == SocketCaptureKind.Game || kind == SocketCaptureKind.Policy)
		{
			Dispatch(socket, SafeCopyBuffers(buffers, bufferCount, actual), sending);
			return;
		}
		int? probeMaximum = actual.HasValue ? Math.Min(actual.Value, MaximumProbeChunk) : MaximumProbeChunk;
		byte[] probe = SafeCopyBuffers(buffers, bufferCount, probeMaximum);
		SocketCaptureKind detected = _filter.ObserveProbe(socket, probe, sending, out byte[] previousProbe);
		if (detected == SocketCaptureKind.Game || detected == SocketCaptureKind.Policy)
		{
			Dispatch(socket, previousProbe, sending);
			Dispatch(socket, SafeCopyBuffers(buffers, bufferCount, actual), sending);
		}
		else if (detected == SocketCaptureKind.Ignore)
		{
			_ignored?.Invoke(actual ?? probe?.Length ?? 0);
		}
	}

	private void Dispatch(long socket, byte[] bytes, bool sending)
	{
		if (bytes == null || bytes.Length == 0)
		{
			return;
		}
		if (sending)
		{
			_sendCaptured?.Invoke(socket, bytes);
		}
		else
		{
			_receiveCaptured?.Invoke(socket, bytes);
		}
	}

	private static byte[] SafeCopyBuffers(IntPtr buffers, uint bufferCount, int? maximumBytes)
	{
		if (buffers == IntPtr.Zero || bufferCount == 0 || bufferCount > 1024)
		{
			return null;
		}
		int structureSize = Marshal.SizeOf(typeof(WinsockNative.WSABUF));
		List<byte[]> chunks = new List<byte[]>();
		long total = 0;
		for (uint i = 0; i < bufferCount; i++)
		{
			IntPtr address = IntPtr.Add(buffers, checked((int)i * structureSize));
			WinsockNative.WSABUF value = (WinsockNative.WSABUF)Marshal.PtrToStructure(address, typeof(WinsockNative.WSABUF));
			int wanted = checked((int)value.Length);
			if (maximumBytes.HasValue)
			{
				wanted = Math.Min(wanted, Math.Max(0, maximumBytes.Value - (int)total));
			}
			if (wanted == 0)
			{
				continue;
			}
			total += wanted;
			if (total > MaximumCapturedChunk)
			{
				return null;
			}
			byte[] chunk = SafeCopy(value.Buffer, wanted);
			if (chunk == null)
			{
				return null;
			}
			chunks.Add(chunk);
			if (maximumBytes.HasValue && total >= maximumBytes.Value)
			{
				break;
			}
		}

		byte[] result = new byte[(int)total];
		int position = 0;
		foreach (byte[] chunk in chunks)
		{
			Buffer.BlockCopy(chunk, 0, result, position, chunk.Length);
			position += chunk.Length;
		}
		return result;
	}

	private static int TryReadPort(IntPtr socketAddress, int length)
	{
		if (socketAddress == IntPtr.Zero || length < 4)
		{
			return 0;
		}
		short family = Marshal.ReadInt16(socketAddress);
		if (family != 2 && family != 23)
		{
			return 0;
		}
		int high = Marshal.ReadByte(socketAddress, 2);
		int low = Marshal.ReadByte(socketAddress, 3);
		return (high << 8) | low;
	}
}
