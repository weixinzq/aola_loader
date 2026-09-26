// 架构角色：为多订阅者事件提供逐个安全分发，避免一个消费者异常阻断其他消费者。
// 数据流：事件快照 + payload -> 每个 handler；异常在边界内隔离。
using System;

namespace AolaLoader.PacketHost;

internal static class PacketEventDispatch
{
	public static void InvokeSafely<T>(Action<T> handlers, T value)
	{
		if (handlers == null)
		{
			return;
		}

		foreach (Action<T> handler in handlers.GetInvocationList())
		{
			try
			{
				handler(value);
			}
			catch (Exception)
			{
				// A single consumer must not interrupt delivery to the remaining consumers.
			}
		}
	}
}

