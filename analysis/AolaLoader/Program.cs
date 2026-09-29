// 架构角色：AolaLoader.exe 进程入口，负责单实例、WinForms/CEF 生命周期和组合根边界。
// 数据流：进程启动 -> AolaCompositionRoot -> Application.Run；退出 -> 逆序释放与 Cef.Shutdown。
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
		// app.config 的 PerMonitorV2 在创建任何 WinForms/CEF 控件前启用。
		Application.EnableVisualStyles();
		Directory.SetCurrentDirectory(AppDomain.CurrentDomain.BaseDirectory);
		string mutexName = "Global\\" + (Assembly.GetEntryAssembly()?.GetCustomAttribute<GuidAttribute>()?.Value ?? "AolaLoader");
		using (Mutex mutex = new Mutex(true, mutexName, out bool createdNew))
		{
			if (!createdNew)
			{
				ActivateExistingInstance();
				return;
			}
			Application.SetCompatibleTextRenderingDefault(false);
			try
			{
				// CompositionRoot 是桌面程序的装配器：创建浏览器、Hook、
				// 功能协调器和主窗体。using 保证主窗口退出后统一释放这些长期对象。
				using (AolaCompositionRoot root = new AolaCompositionRoot())
				{
					// 显示主窗体并进入 WinForms 消息循环；用户关闭主窗体前不会正常返回。
					Application.Run(root.MainForm);
				}
			}
			finally
			{
				// 先由 CompositionRoot 释放浏览器和业务对象，最后关闭进程级 CEF。
				// 即使主窗体启动或运行期间抛出异常，这里也会执行。
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
	private static extern bool SetForegroundWindow(IntPtr window);

	[DllImport("user32.dll")]
	private static extern bool ShowWindow(IntPtr window, int command);
}
