// 架构角色：跨进程 .NET Remoting 服务，连接注入端发布者与宿主静态事件/兼容发送队列。
// 数据流：Hook Publish packet/status/result -> 宿主 adapter；遗留 send request 队列当前生产端拒绝。
using System;
using System.Collections.Generic;

namespace AolaSocketHack.Contracts;

public sealed class AolaHookHostService : MarshalByRefObject
{
	private const int MaximumPendingSends = 256;
	private static readonly object SendSyncRoot = new object();
	private static readonly List<AolaSendRequest> PendingSends = new List<AolaSendRequest>();

	public static event Action<AolaPacketEvent> PacketReceived;

	public static event Action<AolaHookStatus> StatusReceived;

	public static event Action<AolaSendResult> SendCompleted;

	public bool Ping()
	{
		return true;
	}

	public void Publish(AolaPacketEvent packet)
	{
		if (packet != null)
		{
			PacketReceived?.Invoke(packet);
		}
	}

	public void Report(AolaHookStatus status)
	{
		if (status != null)
		{
			StatusReceived?.Invoke(status);
		}
	}

	public AolaSendRequest TakeSendRequest(int processId)
	{
		lock (SendSyncRoot)
		{
			for (int index = 0; index < PendingSends.Count; index++)
			{
				AolaSendRequest request = PendingSends[index];
				if (request.ProcessId == 0 || request.ProcessId == processId)
				{
					PendingSends.RemoveAt(index);
					return request;
				}
			}
		}
		return null;
	}

	public void PublishSendResult(AolaSendResult result)
	{
		if (result != null)
		{
			SendCompleted?.Invoke(result);
		}
	}

	public static string QueueSend(AolaSendRequest request)
	{
		if (request == null)
		{
			throw new ArgumentNullException(nameof(request));
		}
		if (request.ExtensionId < 0 || request.ExtensionId > ushort.MaxValue)
		{
			throw new ArgumentOutOfRangeException(nameof(request.ExtensionId));
		}
		if (string.IsNullOrWhiteSpace(request.Command))
		{
			throw new ArgumentException("命令不能为空", nameof(request));
		}
		if (string.IsNullOrWhiteSpace(request.ParametersJson))
		{
			request.ParametersJson = "{}";
		}
		if (string.IsNullOrWhiteSpace(request.RequestId))
		{
			request.RequestId = Guid.NewGuid().ToString("N");
		}
		request.QueuedAtUtc = DateTime.UtcNow;
		lock (SendSyncRoot)
		{
			if (PendingSends.Count >= MaximumPendingSends)
			{
				throw new InvalidOperationException("发包队列已满");
			}
			PendingSends.Add(request);
		}
		return request.RequestId;
	}

	public static void ReportLocal(AolaHookStatus status)
	{
		if (status != null)
		{
			StatusReceived?.Invoke(status);
		}
	}

	public override object InitializeLifetimeService()
	{
		return null;
	}
}
