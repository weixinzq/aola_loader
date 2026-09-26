// 架构角色：统一复用、激活和关闭功能子窗口，避免同一功能重复创建多个窗体实例。
// 数据流：窗口键 + factory -> 已有或新 Form；FormClosed/Dispose -> 生命周期清理。
using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace AolaLoader.AppShell;

internal sealed class ChildWindowCoordinator : IChildWindowCoordinator
{
	private const int SwShowNoActivate = 4;
	private readonly Dictionary<string, Form> _windows = new Dictionary<string, Form>(StringComparer.Ordinal);
	private readonly List<Form> _visibleBeforeMinimize = new List<Form>();
	private bool _disposed;

	public Form Show(string key, Func<Form> factory, bool activate = true)
	{
		if (key == null)
		{
			throw new ArgumentNullException(nameof(key));
		}
		if (factory == null)
		{
			throw new ArgumentNullException(nameof(factory));
		}
		ThrowIfDisposed();

		if (!_windows.TryGetValue(key, out Form child) || child == null || child.IsDisposed)
		{
			child = factory();
			if (child == null)
			{
				throw new InvalidOperationException("Child window factory returned null.");
			}
			Form instance = child;
			child.FormClosed += delegate { RemoveReference(key, instance); };
			_windows[key] = child;
		}

		child.Show();
		child.BringToFront();
		if (activate)
		{
			child.Activate();
		}
		return child;
	}

	public void RememberAndHideVisible()
	{
		ThrowIfDisposed();
		_visibleBeforeMinimize.Clear();
		foreach (Form child in _windows.Values)
		{
			if (child != null && !child.IsDisposed && child.Visible)
			{
				_visibleBeforeMinimize.Add(child);
			}
		}
		foreach (Form child in _visibleBeforeMinimize)
		{
			child.Hide();
		}
	}

	public void RestoreVisibleAfterUnminimize()
	{
		ThrowIfDisposed();
		foreach (Form child in _visibleBeforeMinimize)
		{
			if (!child.IsDisposed)
			{
				// 不激活子窗口，避免还原主窗口时焦点被抢走。
				ShowWindow(child.Handle, SwShowNoActivate);
			}
		}
		_visibleBeforeMinimize.Clear();
	}

	public void Dispose()
	{
		if (_disposed)
		{
			return;
		}
		_disposed = true;
		Form[] children = _windows.Values.ToArray();
		foreach (Form child in children)
		{
			try
			{
				child.Close();
			}
			catch (Exception)
			{
			}
		}
		foreach (Form child in children)
		{
			if (!child.IsDisposed)
			{
				child.Dispose();
			}
		}
		_windows.Clear();
		_visibleBeforeMinimize.Clear();
	}

	private void RemoveReference(string key, Form instance)
	{
		if (_windows.TryGetValue(key, out Form current) && ReferenceEquals(current, instance))
		{
			_windows.Remove(key);
		}
	}

	private void ThrowIfDisposed()
	{
		if (_disposed)
		{
			throw new ObjectDisposedException(nameof(ChildWindowCoordinator));
		}
	}

	[DllImport("user32.dll")]
	private static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
