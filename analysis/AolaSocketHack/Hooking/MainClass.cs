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
			CaptureRuntimeMetrics metrics = new CaptureRuntimeMetrics();
			bool diagnosticCaptureAll = string.Equals(Environment.GetEnvironmentVariable("AOLA_CAPTURE_ALL_SOCKETS"), "1", StringComparison.Ordinal);
			AolaSocketCaptureFilter filter = new AolaSocketCaptureFilter(captureAllSockets: diagnosticCaptureAll);
			ConcurrentDictionary<long, AolaSidecarSender> senders = new ConcurrentDictionary<long, AolaSidecarSender>();
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
						else if (chunk.Direction == CaptureDirection.Close)
						{
							engine.Remove(chunk.Socket);
							lock (senders)
							{
								if (senders.TryRemove(chunk.Socket, out AolaSidecarSender closedSender))
								{
									closedSender.Dispose();
								}
							}
						}
						else
						{
							engine.CleanupIdle(chunk.EnqueuedUtc.AddMinutes(-30));
						}
					}
					catch (Exception ex)
					{
						Report("Warning", "抓包解析异常：" + ex.Message);
					}
					finally
					{
						metrics.ParserProgress(chunk.EnqueuedUtc);
					}
				}
			});
			worker.IsBackground = true;
			worker.Name = "AolaSocketHack.Parser";
			worker.Start();

			using (WinsockHooks hooks = new WinsockHooks(
				filter,
				(socket, bytes) => TryQueue(queue, metrics, CaptureDirection.Send, socket, bytes),
				(socket, bytes) => TryQueue(queue, metrics, CaptureDirection.Receive, socket, bytes),
				metrics.Ignored,
				(socket, port) => TryQueue(queue, metrics, CaptureDirection.Connect, socket, null, port),
				socket => TryQueue(queue, metrics, CaptureDirection.Close, socket, null)))
			{
				try
				{
					hooks.Install();
					Report("Info", diagnosticCaptureAll
						? "Aola Winsock Hook 已安装（诊断：全 socket 捕获后筛选）"
						: "Aola Winsock Hook 已安装（游戏 socket 前置筛选 + 独立连接发包模式）");
					DateTime nextStatusUtc = DateTime.UtcNow.AddSeconds(5);
					CaptureRuntimeSnapshot lastStatus = null;
					AolaCaptureEngineMetrics lastEngineStatus = null;
					while (_host.Ping())
					{
						DateTime now = DateTime.UtcNow;
						if (now >= nextStatusUtc)
						{
							filter.CleanupIdle(now.AddMinutes(-30));
							TryQueue(queue, metrics, CaptureDirection.Maintenance, 0, null);
							CaptureRuntimeSnapshot current = metrics.Snapshot();
							AolaCaptureEngineMetrics engineMetrics = engine.GetMetrics();
							bool stalled = queue.Count > 0 && (now - current.ParserLastProgressUtc).TotalSeconds >= 5;
							if (lastStatus == null || HasStatusChanged(lastStatus, current) || HasEngineStatusChanged(lastEngineStatus, engineMetrics) || stalled)
							{
								bool newDrops = lastStatus == null ? current.DroppedChunks != 0 : current.DroppedChunks > lastStatus.DroppedChunks;
								bool newOverflows = lastEngineStatus == null ? engineMetrics.BufferOverflows != 0 : engineMetrics.BufferOverflows > lastEngineStatus.BufferOverflows;
								Report(stalled || newDrops || newOverflows ? "Warning" : "Info",
									string.Format("抓包状态：queue={0}/4096, high={1}, captured={2}/{3}B, dropped={4}/{5}B, ignored={6}/{7}B, parserLag={8}ms, connections={9}, buffered={10}B, overflows={11}, protocolErrors={12}{13}",
										queue.Count, current.QueueHighWatermark, current.CapturedChunks, current.CapturedBytes,
										current.DroppedChunks, current.DroppedBytes, current.IgnoredChunks, current.IgnoredBytes,
										current.ParserLagMilliseconds, engineMetrics.Connections, engineMetrics.BufferedBytes,
										engineMetrics.BufferOverflows, engineMetrics.ProtocolErrors, stalled ? ", parserStalled=true" : string.Empty));
								lastStatus = current;
								lastEngineStatus = engineMetrics;
							}
							nextStatusUtc = now.AddSeconds(5);
						}
						AolaSendRequest request = _host.TakeSendRequest(processId);
						if (request == null)
						{
							Thread.Sleep(50);
							continue;
						}
						HandleSendRequest(engine, senders, filter, request, processId);
					}
				}
				catch (Exception ex)
				{
					Report("Error", "Aola Hook 运行失败：" + ex.Message);
				}
			}
			queue.CompleteAdding();
			bool workerStopped = worker.Join(2000);
			lock (senders)
			{
				foreach (AolaSidecarSender sender in senders.Values)
				{
					sender.Dispose();
				}
				senders.Clear();
			}
			if (workerStopped)
			{
				engine.Dispose();
			}
			else
			{
				Report("Warning", "抓包解析线程未在卸载等待期内停止；进程退出时释放剩余分析状态");
			}
		}
		Report("Info", "Aola Winsock Hook 已卸载");
	}

	private void HandleSendRequest(AolaCaptureEngine engine, ConcurrentDictionary<long, AolaSidecarSender> senders, AolaSocketCaptureFilter filter, AolaSendRequest request, int processId)
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
			lock (senders)
			{
				if (!senders.TryGetValue(context.SourceSocket, out AolaSidecarSender sender) || !sender.Matches(context.LoginFrame))
				{
					if (sender != null)
					{
						sender.Dispose();
					}
					sender = new AolaSidecarSender(context.SourceSocket, processId, context.LoginFrame, filter.MarkSidecar);
					senders[context.SourceSocket] = sender;
				}
				AolaPacketEvent packet = sender.Send(request);
				PublishSafely(packet);
			}
			result.Succeeded = true;
			result.Message = string.Format("已发送 ext={0}, cmd={1}", request.ExtensionId, request.Command);
		}
		catch (Exception ex)
		{
			lock (senders)
			{
				if (result.SocketHandle != 0 && senders.TryGetValue(result.SocketHandle, out AolaSidecarSender sender))
				{
					sender.Dispose();
					senders.TryRemove(result.SocketHandle, out _);
				}
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

	private static bool HasStatusChanged(CaptureRuntimeSnapshot previous, CaptureRuntimeSnapshot current)
	{
		return previous.CapturedChunks != current.CapturedChunks ||
			previous.IgnoredChunks != current.IgnoredChunks ||
			previous.DroppedChunks != current.DroppedChunks ||
			previous.QueueHighWatermark != current.QueueHighWatermark;
	}

	private static bool HasEngineStatusChanged(AolaCaptureEngineMetrics previous, AolaCaptureEngineMetrics current)
	{
		return previous == null || previous.Connections != current.Connections ||
			previous.BufferedBytes != current.BufferedBytes ||
			previous.BufferOverflows != current.BufferOverflows ||
			previous.ProtocolErrors != current.ProtocolErrors;
	}

	private static void TryQueue(BlockingCollection<CapturedChunk> queue, CaptureRuntimeMetrics metrics, CaptureDirection direction, long socket, byte[] bytes, int port = 0)
	{
		try
		{
			if (queue.TryAdd(new CapturedChunk(direction, socket, bytes, port)))
			{
				if (bytes != null)
				{
					metrics.Captured(bytes.Length, queue.Count);
				}
				return;
			}
			if (bytes != null)
			{
				metrics.Dropped(bytes.Length);
			}
		}
		catch
		{
			if (bytes != null)
			{
				metrics.Dropped(bytes.Length);
			}
		}
	}

	private enum CaptureDirection
	{
		Send,
		Receive,
		Connect,
		Close,
		Maintenance
	}

	private sealed class CapturedChunk
	{
		public CapturedChunk(CaptureDirection direction, long socket, byte[] bytes, int port)
		{
			Direction = direction;
			Socket = socket;
			Bytes = bytes;
			Port = port;
			EnqueuedUtc = DateTime.UtcNow;
		}

		public CaptureDirection Direction { get; }

		public long Socket { get; }

		public byte[] Bytes { get; }

		public int Port { get; }

		public DateTime EnqueuedUtc { get; }
	}
}
