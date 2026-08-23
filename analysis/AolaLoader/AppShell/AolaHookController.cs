using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Runtime.Remoting;
using AolaSocketHack.Contracts;
using EasyHook;

namespace AolaLoader.AppShell;

internal sealed class AolaHookController : IDisposable
{
	private readonly object _syncRoot = new object();
	private readonly HashSet<int> _injectedProcesses = new HashSet<int>();
	private readonly string _channelName;
	private bool _disposed;

	public AolaHookController()
	{
		string channelName = null;
		RemoteHooking.IpcCreateServer<AolaHookHostService>(ref channelName, WellKnownObjectMode.Singleton);
		_channelName = channelName;
	}

	public bool EnsureInjected(int processId, string libraryPath)
	{
		if (processId <= 0)
		{
			return false;
		}
		if (string.IsNullOrWhiteSpace(libraryPath) || !File.Exists(libraryPath))
		{
			Report("Error", "找不到 AolaSocketHack.dll：" + libraryPath);
			return false;
		}
		lock (_syncRoot)
		{
			if (_disposed)
			{
				return false;
			}
			if (_injectedProcesses.Contains(processId) && IsRunning(processId))
			{
				return true;
			}
			_injectedProcesses.RemoveWhere(id => !IsRunning(id));
			try
			{
				RemoteHooking.Inject(processId, InjectionOptions.Default, libraryPath, libraryPath, _channelName);
				_injectedProcesses.Add(processId);
				Report("Info", "AolaSocketHack 已注入 network.mojom，PID=" + processId);
				return true;
			}
			catch (Exception ex)
			{
				Report("Error", "AolaSocketHack 注入失败：" + ex.Message);
				return false;
			}
		}
	}

	public void Dispose()
	{
		lock (_syncRoot)
		{
			_disposed = true;
			_injectedProcesses.Clear();
		}
	}

	private static bool IsRunning(int processId)
	{
		try
		{
			return !Process.GetProcessById(processId).HasExited;
		}
		catch
		{
			return false;
		}
	}

	private static void Report(string level, string message)
	{
		AolaHookHostService.ReportLocal(new AolaHookStatus
		{
			TimestampUtc = DateTime.UtcNow,
			ProcessId = Process.GetCurrentProcess().Id,
			Level = level,
			Message = message
		});
	}
}
