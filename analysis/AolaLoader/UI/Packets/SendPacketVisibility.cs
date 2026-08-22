using System;
using AolaSocketHack.Contracts;

namespace AolaLoader.UI.Packets;

internal static class SendPacketVisibility
{
	public static bool IsVisible(AolaPacketEvent packet)
	{
		return packet != null &&
			string.Equals(packet.Direction, "发送", StringComparison.Ordinal);
	}
}
