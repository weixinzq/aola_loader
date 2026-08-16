using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using EasyHook;

namespace AolaSocketHack.Hooking;

internal sealed class WinsockHooks : IDisposable
{
	private const int MaximumCapturedChunk = 16 * 1024 * 1024;
	private readonly Action<long, byte[]> _sendCaptured;
	private readonly Action<long, byte[]> _receiveCaptured;
	private readonly Action<long, int> _connected;
	private readonly Action<long> _closed;
	private readonly WinsockNative.SendDelegate _sendHandler;
	private readonly WinsockNative.RecvDelegate _recvHandler;
	private readonly WinsockNative.WSASendDelegate _wsaSendHandler;
	private readonly WinsockNative.WSARecvDelegate _wsaRecvHandler;
	private readonly WinsockNative.ConnectDelegate _connectHandler;
	private readonly WinsockNative.CloseSocketDelegate _closeHandler;
	private readonly List<LocalHook> _hooks = new List<LocalHook>();

	public WinsockHooks(Action<long, byte[]> sendCaptured, Action<long, byte[]> receiveCaptured, Action<long, int> connected, Action<long> closed)
	{
		_sendCaptured = sendCaptured;
		_receiveCaptured = receiveCaptured;
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
		byte[] copy = SafeCopy(buffer, length);
		int result = WinsockNative.Send(socket, buffer, length, flags);
		int error = Marshal.GetLastWin32Error();
		try
		{
			if (result > 0 && copy != null)
			{
				if (result != copy.Length)
				{
					Array.Resize(ref copy, result);
				}
				_sendCaptured?.Invoke(socket.ToInt64(), copy);
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
		int result = WinsockNative.Recv(socket, buffer, length, flags);
		int error = Marshal.GetLastWin32Error();
		try
		{
			if (result > 0)
			{
				byte[] copy = SafeCopy(buffer, result);
				if (copy != null)
				{
					_receiveCaptured?.Invoke(socket.ToInt64(), copy);
				}
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
		byte[] copy = SafeCopyBuffers(buffers, bufferCount, null);
		int result = WinsockNative.WSASend(socket, buffers, bufferCount, bytesSent, flags, overlapped, completionRoutine);
		int error = Marshal.GetLastWin32Error();
		try
		{
			if (copy != null && copy.Length != 0)
			{
				int? actual = ReadTransferredCount(result, overlapped, bytesSent);
				if (actual.HasValue && actual.Value >= 0 && actual.Value < copy.Length)
				{
					Array.Resize(ref copy, actual.Value);
				}
				if (copy.Length != 0)
				{
					_sendCaptured?.Invoke(socket.ToInt64(), copy);
				}
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
		int result = WinsockNative.WSARecv(socket, buffers, bufferCount, bytesReceived, flags, overlapped, completionRoutine);
		int error = Marshal.GetLastWin32Error();
		try
		{
			int? actual = ReadTransferredCount(result, overlapped, bytesReceived);
			if (actual.HasValue && actual.Value > 0)
			{
				byte[] copy = SafeCopyBuffers(buffers, bufferCount, actual.Value);
				if (copy != null && copy.Length != 0)
				{
					_receiveCaptured?.Invoke(socket.ToInt64(), copy);
				}
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
		int result = WinsockNative.Connect(socket, name, nameLength);
		int error = Marshal.GetLastWin32Error();
		try
		{
			if (result == 0 && port > 0)
			{
				_connected?.Invoke(socket.ToInt64(), port);
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
		try
		{
			_closed?.Invoke(socket.ToInt64());
		}
		catch
		{
		}
		return WinsockNative.CloseSocket(socket);
	}

	private static int? ReadTransferredCount(int result, IntPtr overlapped, IntPtr countPointer)
	{
		if (result != 0 || overlapped != IntPtr.Zero || countPointer == IntPtr.Zero)
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
