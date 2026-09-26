// 架构角色：定义主窗体与子窗口生命周期实现之间的窄接口，便于替换和手工验证。
// 数据流：调用者提交窗口键和构造函数；实现负责显示、复用与关闭。
using System;
using System.Windows.Forms;

namespace AolaLoader.AppShell;

/// <summary>
/// AppShell contract for child window reuse, close-reference cleanup, minimize
/// hiding and no-activate restore.
/// </summary>
internal interface IChildWindowCoordinator : IDisposable
{
	/// Shows (or reuses) the child window registered under the stable key.
	Form Show(string key, Func<Form> factory, bool activate = true);

	/// Snapshots visible children and hides them (main window minimizing).
	void RememberAndHideVisible();

	/// Restores previously visible children without activating them.
	void RestoreVisibleAfterUnminimize();
}
