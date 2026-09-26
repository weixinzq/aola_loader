// 架构角色：集中计算主动发送区域的可见性，保持 UI 布局判断为纯函数。
// 数据流：窗口/功能状态 -> 控件显示布尔值。
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
