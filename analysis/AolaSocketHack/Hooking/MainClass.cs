// 架构角色：EasyHook 注入入口，装配 socket filter、native hooks、有界队列、解析线程和 IPC 发布。
// 数据流：Winsock callbacks -> CapturedChunk queue -> AolaCaptureEngine -> AolaHookHostService。
using System;
using System.Collections.Concurrent;
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
		// 注入 DLL 运行在 network.mojom 中；通过宿主创建的 channel 连接回 AolaLoader.exe。
		_host = RemoteHooking.IpcConnectClient<AolaHookHostService>(channelName);
	}

	public void Run(RemoteHooking.IContext context, string channelName)
	{
		int processId = Process.GetCurrentProcess().Id;
		// Hook 回调是生产者，Parser 线程是唯一消费者。容量上限保护 CEF 网络进程内存。
		using (BlockingCollection<CapturedChunk> queue = new BlockingCollection<CapturedChunk>(new ConcurrentQueue<CapturedChunk>(), 4096))
		{
			AolaCaptureEngine engine = new AolaCaptureEngine(PublishSafely, ReportStatusSafely);
			CaptureRuntimeMetrics metrics = new CaptureRuntimeMetrics();
			bool diagnosticCaptureAll = string.Equals(Environment.GetEnvironmentVariable("AOLA_CAPTURE_ALL_SOCKETS"), "1", StringComparison.Ordinal);
			AolaSocketCaptureFilter filter = new AolaSocketCaptureFilter(captureAllSockets: diagnosticCaptureAll);
			// 协议解析可能分帧、解密和反序列化，必须离开原生 Winsock Hook 回调执行。
			Thread worker = new Thread((ThreadStart)delegate
			{
				// 队列暂时为空时等待；CompleteAdding 且剩余项耗尽后才退出。
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
						}
						else
						{
							engine.CleanupIdle(chunk.EnqueuedUtc.AddMinutes(-30));
						}
					}
					catch (Exception ex)
					{
						Report("Warning", "抓包解析异常：" + ex.Message, "CaptureInvalid", chunk.Socket);
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

			// 这些 lambda 是“捕获结果回调”，由 WinsockHooks 在复制字节后调用；
			// socket/bytes 的实际值来自被拦截的 ws2_32 调用，而不是这里预先生成。
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
						: "Aola Winsock Hook 已安装（游戏 socket 前置筛选；旁路登录发包已禁用）");
					DateTime nextStatusUtc = DateTime.UtcNow.AddSeconds(5);
					long reportedDrops = 0;
					CaptureRuntimeSnapshot lastStatus = null;
					AolaCaptureEngineMetrics lastEngineStatus = null;
					while (_host.Ping())
					{
						DateTime now = DateTime.UtcNow;
						long drops = metrics.Snapshot().DroppedChunks;
						if (drops > reportedDrops)
						{
							Report("Warning", "捕获队列丢失数据，停止文本执行。", "CaptureInvalid");
							reportedDrops = drops;
						}
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
						RejectLegacySendRequest(request, processId);
					}
				}
				catch (Exception ex)
				{
					Report("Error", "Aola Hook 运行失败：" + ex.Message, "CaptureInvalid");
				}
			}
			// 停止接受新的 Hook 事件，再等待 parser 排空已有数据，避免卸载时截断队列。
			queue.CompleteAdding();
			bool workerStopped = worker.Join(2000);
			if (workerStopped)
			{
				engine.Dispose();
			}
			else
			{
				Report("Warning", "抓包解析线程未在卸载等待期内停止；进程退出时释放剩余分析状态");
			}
		}
		Report("Info", "Aola Winsock Hook 已卸载", "CaptureInvalid");
	}

	private void RejectLegacySendRequest(AolaSendRequest request, int processId)
	{
		AolaSendResult result = new AolaSendResult
		{
			RequestId = request.RequestId,
			CompletedAtUtc = DateTime.UtcNow,
			ProcessId = processId,
			SocketHandle = request.SocketHandle,
			Succeeded = false,
			Message = "已拒绝旧式旁路发包：生产发送必须通过页面/ExternalInterface/Flash 原连接。"
		};
		try
		{
			_host.PublishSendResult(result);
		}
		catch
		{
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

	private void ReportStatusSafely(AolaHookStatus status)
	{
		try { _host.Report(status); } catch { }
	}

	private void Report(string level, string message, string executionEvent = null, long? socket = null)
	{
		try
		{
			_host.Report(new AolaHookStatus
			{
				TimestampUtc = DateTime.UtcNow,
				ProcessId = Process.GetCurrentProcess().Id,
				Level = level,
				Message = message,
				ExecutionEvent = executionEvent,
				SocketHandle = socket
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
			// TryAdd 不阻塞网络线程；容量已满时宁可计数丢弃，也不能卡住 CEF 网络栈。
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
