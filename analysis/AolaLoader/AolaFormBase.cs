using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace AolaLoader;

/// <summary>
/// 所有窗口的基类：窗口被激活（例如用户点击）时提升到最上层，
/// 保证“点击哪个窗口，哪个窗口就处于最上层”。
/// 子窗口不再使用 Show(owner) 属主关系，否则 Windows 的
/// “被属主窗口永远位于属主之上”规则会让主窗口无法置顶。
/// </summary>
internal abstract class AolaFormBase : Form
{
	private const uint SwpNoMove = 0x0002;
	private const uint SwpNoSize = 0x0001;
	private const uint SwpNoActivate = 0x0010;
	private static readonly IntPtr HwndTopmost = new IntPtr(-1);
	private static readonly IntPtr HwndNotTopmost = new IntPtr(-2);

	protected override void OnActivated(EventArgs e)
	{
		base.OnActivated(e);
		RaiseToTop();
	}

	// 临时进入置顶层再退出，把窗口带到普通层的最上方；
	// SWP_NOACTIVATE 避免在激活回调里再次抢夺焦点。
	private void RaiseToTop()
	{
		if (IsDisposed || !IsHandleCreated)
		{
			return;
		}
		SetWindowPos(Handle, HwndTopmost, 0, 0, 0, 0, SwpNoMove | SwpNoSize | SwpNoActivate);
		SetWindowPos(Handle, HwndNotTopmost, 0, 0, 0, 0, SwpNoMove | SwpNoSize | SwpNoActivate);
	}

	[DllImport("user32.dll", SetLastError = true)]
	private static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int x, int y, int cx, int cy, uint uFlags);
}
