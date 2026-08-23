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
