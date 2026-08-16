using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Diagnostics;
using System.Threading;
using AolaSocketHack.Contracts;
using AolaSocketHack.Transport;
using EasyHook;

namespace AolaSocketHack.Hooking;

public sealed class MainClass : IEntryPoint
{
	private readonly AolaHookHostService _host;

	public MainClass(RemoteHooking.IContext context, string channelName)
	{
		_host = RemoteHooking.IpcConnectClient<AolaHookHostService>(channelName);
	}

	public void Run(RemoteHooking.IContext context, string channelName)
	{
		int processId = Process.GetCurrentProcess().Id;
		using (BlockingCollection<CapturedChunk> queue = new BlockingCollection<CapturedChunk>(new ConcurrentQueue<CapturedChunk>(), 4096))
		{
			AolaCaptureEngine engine = new AolaCaptureEngine(PublishSafely);
			Dictionary<long, AolaSidecarSender> senders = new Dictionary<long, AolaSidecarSender>();
			Thread worker = new Thread((ThreadStart)delegate
			{
				foreach (CapturedChunk chunk in queue.GetConsumingEnumerable())
				{
					try
					{
						if (chunk.Direction == CaptureDirection.Send)
						{
							engine.CaptureSend(chunk.Socket, chunk.Bytes);
						}
						else if (chunk.Direction == CaptureDirection.Receive)
						{
							engine.CaptureReceive(chunk.Socket, chunk.Bytes);
						}
						else if (chunk.Direction == CaptureDirection.Connect)
						{
							engine.NoteConnect(chunk.Socket, chunk.Port);
						}
						else
						{
							engine.Remove(chunk.Socket);
						}
					}
					catch (Exception ex)
					{
						Report("Warning", "抓包解析异常：" + ex.Message);
					}
				}
			});
			worker.IsBackground = true;
			worker.Name = "AolaSocketHack.Parser";
			worker.Start();

			using (WinsockHooks hooks = new WinsockHooks(
				(socket, bytes) => TryQueue(queue, CaptureDirection.Send, socket, bytes),
				(socket, bytes) => TryQueue(queue, CaptureDirection.Receive, socket, bytes),
				(socket, port) => TryQueue(queue, CaptureDirection.Connect, socket, null, port),
				socket => TryQueue(queue, CaptureDirection.Close, socket, null)))
			{
				try
				{
					hooks.Install();
					Report("Info", "Aola Winsock Hook 已安装（抓包 + 独立连接发包模式）");
					while (_host.Ping())
					{
						AolaSendRequest request = _host.TakeSendRequest(processId);
						if (request == null)
						{
							Thread.Sleep(50);
							continue;
						}
						HandleSendRequest(engine, senders, request, processId);
					}
				}
				catch (Exception ex)
				{
					Report("Error", "Aola Hook 运行失败：" + ex.Message);
				}
			}
			foreach (AolaSidecarSender sender in senders.Values)
			{
				sender.Dispose();
			}
			queue.CompleteAdding();
			worker.Join(2000);
		}
		Report("Info", "Aola Winsock Hook 已卸载");
	}

	private void HandleSendRequest(AolaCaptureEngine engine, Dictionary<long, AolaSidecarSender> senders, AolaSendRequest request, int processId)
	{
		AolaSendContext context = null;
		AolaSendResult result = new AolaSendResult
		{
			RequestId = request.RequestId,
			CompletedAtUtc = DateTime.UtcNow,
			ProcessId = processId
		};
		try
		{
			if (!engine.TryGetSendContext(request.SocketHandle, out context, out string error))
			{
				throw new InvalidOperationException(error);
			}
			result.SocketHandle = context.SourceSocket;
			if (!senders.TryGetValue(context.SourceSocket, out AolaSidecarSender sender) || !sender.Matches(context.LoginFrame))
			{
				if (sender != null)
				{
					sender.Dispose();
				}
				sender = new AolaSidecarSender(context.SourceSocket, processId, context.LoginFrame);
				senders[context.SourceSocket] = sender;
			}
			AolaPacketEvent packet = sender.Send(request);
			PublishSafely(packet);
			result.Succeeded = true;
			result.Message = string.Format("已发送 ext={0}, cmd={1}", request.ExtensionId, request.Command);
		}
		catch (Exception ex)
		{
			if (result.SocketHandle != 0 && senders.TryGetValue(result.SocketHandle, out AolaSidecarSender sender))
			{
				sender.Dispose();
				senders.Remove(result.SocketHandle);
			}
			result.Succeeded = false;
			result.Message = "发送失败：" + ex.Message;
		}
		finally
		{
			if (context?.LoginFrame != null)
			{
				Array.Clear(context.LoginFrame, 0, context.LoginFrame.Length);
			}
			try
			{
				_host.PublishSendResult(result);
			}
			catch
			{
			}
		}
	}

	private void PublishSafely(AolaPacketEvent packet)
	{
		try
		{
			_host.Publish(packet);
		}
		catch
		{
		}
	}

	private void Report(string level, string message)
	{
		try
		{
			_host.Report(new AolaHookStatus
			{
				TimestampUtc = DateTime.UtcNow,
				ProcessId = Process.GetCurrentProcess().Id,
				Level = level,
				Message = message
			});
		}
		catch
		{
		}
	}

	private static void TryQueue(BlockingCollection<CapturedChunk> queue, CaptureDirection direction, long socket, byte[] bytes, int port = 0)
	{
		try
		{
			queue.TryAdd(new CapturedChunk(direction, socket, bytes, port));
		}
		catch
		{
		}
	}

	private enum CaptureDirection
	{
		Send,
		Receive,
		Connect,
		Close
	}

	private sealed class CapturedChunk
	{
		public CapturedChunk(CaptureDirection direction, long socket, byte[] bytes, int port)
		{
			Direction = direction;
			Socket = socket;
			Bytes = bytes;
			Port = port;
		}

		public CaptureDirection Direction { get; }

		public long Socket { get; }

		public byte[] Bytes { get; }

		public int Port { get; }
	}
}
