using System;
using System.Net;
using System.Net.Sockets;
using AolaSocketHack.Contracts;
using AolaSocketHack.Protocol;

namespace AolaSocketHack.Hooking;

internal sealed class AolaSidecarSender : IDisposable
{
	private const int MaximumPolicyLength = 64 * 1024;
	private readonly long _sourceSocket;
	private readonly int _processId;
	private readonly byte[] _loginFrame;
	private readonly Action<long> _excludeSocket;
	private readonly AolaProtocolState _protocol = new AolaProtocolState();
	private Socket _socket;

	public AolaSidecarSender(long sourceSocket, int processId, byte[] loginFrame, Action<long> excludeSocket)
	{
		_sourceSocket = sourceSocket;
		_processId = processId;
		_loginFrame = loginFrame == null ? throw new ArgumentNullException(nameof(loginFrame)) : (byte[])loginFrame.Clone();
		_excludeSocket = excludeSocket;
		AolaPacketEvent login = AolaProtocol.ParseClientFrame(sourceSocket, processId, _loginFrame, _protocol);
		if (!login.DecodeSucceeded || login.Command != "logIn")
		{
			throw new InvalidOperationException("捕获的登录帧无法用于独立发包连接");
		}
	}

	public bool Matches(byte[] loginFrame)
	{
		if (loginFrame == null || loginFrame.Length != _loginFrame.Length)
		{
			return false;
		}
		int difference = 0;
		for (int index = 0; index < loginFrame.Length; index++)
		{
			difference |= loginFrame[index] ^ _loginFrame[index];
		}
		return difference == 0;
	}

	public AolaPacketEvent Send(AolaSendRequest request)
	{
		if (request == null)
		{
			throw new ArgumentNullException(nameof(request));
		}
		EnsureConnected();
		DrainAvailable();
		byte[] frame = AolaProtocol.BuildClientExtensionFrame(_protocol, request.ExtensionId, request.Command, request.ParametersJson);
		try
		{
			SendAll(_socket, frame);
		}
		catch
		{
			CloseSocket();
			throw;
		}

		AolaPacketEvent packet = AolaProtocol.ParseClientFrame(_sourceSocket, _processId, frame, _protocol);
		if (!packet.DecodeSucceeded || !packet.CanExport)
		{
			CloseSocket();
			throw new InvalidOperationException("主动发送帧的本地回读验证失败");
		}
		packet.Summary = "主动发送；" + packet.Summary;
		return packet;
	}

	public void Dispose()
	{
		CloseSocket();
		Array.Clear(_loginFrame, 0, _loginFrame.Length);
	}

	private void EnsureConnected()
	{
		if (_socket != null && _socket.Connected)
		{
			return;
		}
		CloseSocket();
		IPEndPoint endpoint = WinsockNative.GetPeerEndPoint(_sourceSocket);
		Socket socket = new Socket(endpoint.AddressFamily, SocketType.Stream, ProtocolType.Tcp)
		{
			NoDelay = true,
			ReceiveTimeout = 10000,
			SendTimeout = 5000
		};
		try
		{
			_excludeSocket?.Invoke(socket.Handle.ToInt64());
			socket.Connect(endpoint);
			ReadPolicyIfPresent(socket);
			SendAll(socket, _loginFrame);
			ReadFrame(socket);
			_socket = socket;
		}
		catch
		{
			socket.Dispose();
			throw;
		}
	}

	private static void ReadPolicyIfPresent(Socket socket)
	{
		if (!socket.Poll(2000000, SelectMode.SelectRead))
		{
			return;
		}
		byte[] first = new byte[1];
		if (socket.Receive(first, 0, 1, SocketFlags.Peek) != 1 || first[0] != (byte)'<')
		{
			return;
		}
		int count = 0;
		while (count < MaximumPolicyLength)
		{
			if (socket.Receive(first, 0, 1, SocketFlags.None) != 1 || first[0] == 0)
			{
				return;
			}
			count++;
		}
		throw new InvalidOperationException("Flash policy 响应过长");
	}

	private static byte[] ReadFrame(Socket socket)
	{
		byte[] lengthBytes = ReceiveExact(socket, 4);
		int length = unchecked((int)(((uint)lengthBytes[0] << 24) | ((uint)lengthBytes[1] << 16) | ((uint)lengthBytes[2] << 8) | lengthBytes[3]));
		if (length <= 0 || length > 4 * 1024 * 1024)
		{
			throw new InvalidOperationException("独立连接登录响应长度无效");
		}
		return ReceiveExact(socket, length);
	}

	private void DrainAvailable()
	{
		if (_socket == null)
		{
			return;
		}
		byte[] buffer = new byte[8192];
		while (_socket.Available > 0)
		{
			int read = _socket.Receive(buffer, 0, Math.Min(buffer.Length, _socket.Available), SocketFlags.None);
			if (read <= 0)
			{
				throw new SocketException((int)SocketError.ConnectionReset);
			}
		}
	}

	private static byte[] ReceiveExact(Socket socket, int count)
	{
		byte[] result = new byte[count];
		int position = 0;
		while (position < count)
		{
			int read = socket.Receive(result, position, count - position, SocketFlags.None);
			if (read <= 0)
			{
				throw new SocketException((int)SocketError.ConnectionReset);
			}
			position += read;
		}
		return result;
	}

	private static void SendAll(Socket socket, byte[] bytes)
	{
		int position = 0;
		while (position < bytes.Length)
		{
			int sent = socket.Send(bytes, position, bytes.Length - position, SocketFlags.None);
			if (sent <= 0)
			{
				throw new SocketException((int)SocketError.ConnectionReset);
			}
			position += sent;
		}
	}

	private void CloseSocket()
	{
		if (_socket == null)
		{
			return;
		}
		try
		{
			_socket.Shutdown(SocketShutdown.Both);
		}
		catch
		{
		}
		_socket.Dispose();
		_socket = null;
	}
}
