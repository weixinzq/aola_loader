// 架构角色：IChildWindowCoordinator 的手工测试替身，仅记录调用，不创建真实 WinForms 窗口。
// 数据流：测试动作 -> 调用记录/计数，供契约验证断言。
using System;
using System.Collections.Generic;
using System.Windows.Forms;

namespace AolaLoader.AppShell.Testing;

/// <summary>
/// In-memory IChildWindowCoordinator double for composition tests.
/// </summary>
internal sealed class ManualChildWindowCoordinator : IChildWindowCoordinator
{
	private readonly Dictionary<string, Form> _windows = new Dictionary<string, Form>(StringComparer.Ordinal);

	public int FactoryCallCount { get; private set; }

	public int RememberCount { get; private set; }

	public int RestoreCount { get; private set; }

	public IReadOnlyList<string> ShownKeys { get; } = new List<string>();

	public Form Show(string key, Func<Form> factory, bool activate = true)
	{
		if (!_windows.TryGetValue(key, out Form child) || child == null || child.IsDisposed)
		{
			FactoryCallCount++;
			child = factory();
			_windows[key] = child;
		}
		((List<string>)ShownKeys).Add(key);
		return child;
	}

	public void RememberAndHideVisible()
	{
		RememberCount++;
	}

	public void RestoreVisibleAfterUnminimize()
	{
		RestoreCount++;
	}

	public void Dispose()
	{
		_windows.Clear();
	}
}
