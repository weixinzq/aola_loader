using System;
using System.Windows.Forms;
using AolaLoader.AppShell;

namespace AolaSocketHack.Verify;

internal static class ChildWindowCoordinatorVerifier
{
	public static bool Verify()
	{
		ChildWindowCoordinator coordinator = new ChildWindowCoordinator();
		try
		{
			int factoryCalls = 0;
			Form first = coordinator.Show("test", () =>
			{
				factoryCalls++;
				return new Form { Text = "child" };
			}, activate: false);
			Form second = coordinator.Show("test", () =>
			{
				factoryCalls++;
				return new Form();
			}, activate: false);
			if (factoryCalls != 1 || !ReferenceEquals(first, second))
			{
				return false;
			}

			coordinator.RememberAndHideVisible();
			if (first.Visible)
			{
				return false;
			}
			coordinator.RestoreVisibleAfterUnminimize();
			if (!first.Visible)
			{
				return false;
			}

			int callsBeforeClose = factoryCalls;
			first.Close();
			first.Dispose();
			coordinator.Show("test", () =>
			{
				factoryCalls++;
				return new Form();
			}, activate: false);
			if (factoryCalls != callsBeforeClose + 1)
			{
				return false;
			}

			Form disposable = coordinator.Show("dispose", () => new Form(), activate: false);
			coordinator.Dispose();
			if (!disposable.IsDisposed || !Throws<ObjectDisposedException>(
				() => coordinator.Show("after", () => new Form(), activate: false)))
			{
				return false;
			}
		}
		finally
		{
			coordinator.Dispose();
		}
		return true;
	}

	private static bool Throws<TException>(Action action) where TException : Exception
	{
		try
		{
			action();
			return false;
		}
		catch (TException)
		{
			return true;
		}
	}
}
