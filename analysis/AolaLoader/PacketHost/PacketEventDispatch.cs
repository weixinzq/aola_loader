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

