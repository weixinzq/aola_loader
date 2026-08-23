using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Threading;
using System.Windows.Forms;
using AolaLoader.AppShell;
using CefSharp;

namespace AolaLoader;

internal static class Program
{
	private const int SwRestore = 9;

	[STAThread]
	private static void Main()
	{
		Directory.SetCurrentDirectory(AppDomain.CurrentDomain.BaseDirectory);
		if (Environment.OSVersion.Version.Major >= 6)
		{
			SetProcessDPIAware();
		}
		string mutexName = "Global\\" + (Assembly.GetEntryAssembly()?.GetCustomAttribute<GuidAttribute>()?.Value ?? "AolaLoader");
		using (Mutex mutex = new Mutex(true, mutexName, out bool createdNew))
		{
			if (!createdNew)
			{
				ActivateExistingInstance();
				return;
			}
			Application.EnableVisualStyles();
			Application.SetCompatibleTextRenderingDefault(false);
			try
			{
				using (AolaCompositionRoot root = new AolaCompositionRoot())
				{
					Application.Run(root.MainForm);
				}
			}
			finally
			{
				if (Cef.IsInitialized)
				{
					Cef.Shutdown();
				}
			}
		}
	}

	private static void ActivateExistingInstance()
	{
		string processName = Process.GetCurrentProcess().ProcessName;
		foreach (Process process in Process.GetProcessesByName(processName))
		{
			if (process.Id != Process.GetCurrentProcess().Id && process.MainWindowHandle != IntPtr.Zero)
			{
				ShowWindow(process.MainWindowHandle, SwRestore);
				SetForegroundWindow(process.MainWindowHandle);
				break;
			}
		}
	}

	[DllImport("user32.dll")]
	private static extern bool SetProcessDPIAware();

	[DllImport("user32.dll")]
	private static extern bool SetForegroundWindow(IntPtr window);

	[DllImport("user32.dll")]
	private static extern bool ShowWindow(IntPtr window, int command);
}
