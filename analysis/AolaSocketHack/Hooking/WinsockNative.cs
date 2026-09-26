// 架构角色：声明与 Winsock ABI 精确匹配的委托、P/Invoke 和地址读取辅助函数。
// 数据流：WinsockHooks <-> ws2_32.dll；签名、调用约定和 last-error 语义不可随意改变。
using System;
using System.Net;
using System.Net.Sockets;
using System.Runtime.InteropServices;

namespace AolaSocketHack.Hooking;

internal static class WinsockNative
{
	[StructLayout(LayoutKind.Sequential)]
	internal struct WSABUF
	{
		public uint Length;

		public IntPtr Buffer;
	}

	[UnmanagedFunctionPointer(CallingConvention.StdCall, SetLastError = true)]
	internal delegate int SendDelegate(IntPtr socket, IntPtr buffer, int length, int flags);

	[UnmanagedFunctionPointer(CallingConvention.StdCall, SetLastError = true)]
	internal delegate int RecvDelegate(IntPtr socket, IntPtr buffer, int length, int flags);

	[UnmanagedFunctionPointer(CallingConvention.StdCall, SetLastError = true)]
	internal delegate int WSASendDelegate(IntPtr socket, IntPtr buffers, uint bufferCount, IntPtr bytesSent, uint flags, IntPtr overlapped, IntPtr completionRoutine);

	[UnmanagedFunctionPointer(CallingConvention.StdCall, SetLastError = true)]
	internal delegate int WSARecvDelegate(IntPtr socket, IntPtr buffers, uint bufferCount, IntPtr bytesReceived, IntPtr flags, IntPtr overlapped, IntPtr completionRoutine);

	[UnmanagedFunctionPointer(CallingConvention.StdCall, SetLastError = true)]
	internal delegate int ConnectDelegate(IntPtr socket, IntPtr name, int nameLength);

	[UnmanagedFunctionPointer(CallingConvention.StdCall, SetLastError = true)]
	internal delegate int CloseSocketDelegate(IntPtr socket);

	[DllImport("ws2_32.dll", EntryPoint = "send", CallingConvention = CallingConvention.StdCall, SetLastError = true)]
	internal static extern int Send(IntPtr socket, IntPtr buffer, int length, int flags);

	[DllImport("ws2_32.dll", EntryPoint = "recv", CallingConvention = CallingConvention.StdCall, SetLastError = true)]
	internal static extern int Recv(IntPtr socket, IntPtr buffer, int length, int flags);

	[DllImport("ws2_32.dll", EntryPoint = "WSASend", CallingConvention = CallingConvention.StdCall, SetLastError = true)]
	internal static extern int WSASend(IntPtr socket, IntPtr buffers, uint bufferCount, IntPtr bytesSent, uint flags, IntPtr overlapped, IntPtr completionRoutine);

	[DllImport("ws2_32.dll", EntryPoint = "WSARecv", CallingConvention = CallingConvention.StdCall, SetLastError = true)]
	internal static extern int WSARecv(IntPtr socket, IntPtr buffers, uint bufferCount, IntPtr bytesReceived, IntPtr flags, IntPtr overlapped, IntPtr completionRoutine);

	[DllImport("ws2_32.dll", EntryPoint = "connect", CallingConvention = CallingConvention.StdCall, SetLastError = true)]
	internal static extern int Connect(IntPtr socket, IntPtr name, int nameLength);

	[DllImport("ws2_32.dll", EntryPoint = "closesocket", CallingConvention = CallingConvention.StdCall, SetLastError = true)]
	internal static extern int CloseSocket(IntPtr socket);

	[DllImport("ws2_32.dll", CallingConvention = CallingConvention.StdCall)]
	internal static extern void WSASetLastError(int error);

	[DllImport("ws2_32.dll", EntryPoint = "getpeername", CallingConvention = CallingConvention.StdCall, SetLastError = true)]
	private static extern int GetPeerName(IntPtr socket, byte[] address, ref int addressLength);

	internal static IPEndPoint GetPeerEndPoint(long socket)
	{
		byte[] address = new byte[128];
		int length = address.Length;
		if (GetPeerName(new IntPtr(socket), address, ref length) != 0 || length < 8)
		{
			throw new SocketException(Marshal.GetLastWin32Error());
		}
		int family = address[0] | address[1] << 8;
		int port = address[2] << 8 | address[3];
		if (family == 2 && length >= 16)
		{
			return new IPEndPoint(new IPAddress(new[] { address[4], address[5], address[6], address[7] }), port);
		}
		if (family == 23 && length >= 28)
		{
			byte[] bytes = new byte[16];
			Buffer.BlockCopy(address, 8, bytes, 0, bytes.Length);
			long scope = BitConverter.ToUInt32(address, 24);
			return new IPEndPoint(new IPAddress(bytes, scope), port);
		}
		throw new NotSupportedException("不支持的游戏服务器地址族：" + family);
	}

	internal static int TryGetPeerPort(long socket)
	{
		byte[] address = new byte[128];
		int length = address.Length;
		if (GetPeerName(new IntPtr(socket), address, ref length) != 0 || length < 4)
		{
			return 0;
		}
		int family = address[0] | address[1] << 8;
		if (family != 2 && family != 23)
		{
			return 0;
		}
		return address[2] << 8 | address[3];
	}
}
