// 架构角色：一次性初始化进程级 CEF、缓存、日志和 PPAPI Flash 参数，必须先于浏览器控件创建。
// 数据流：exe/runtime/pepflashplayer.dll + CefSettings -> Cef.Initialize 和全局插件偏好。
using System;
using System.IO;
using CefSharp;
using CefSharp.WinForms;

namespace AolaLoader.BrowserHost;

/// <summary>
/// Process-level CefSharp and PPAPI Flash initialization owned by BrowserHost.
/// </summary>
internal static class AolaCefInitializer
{
	public static void Initialize()
	{
		if (Cef.IsInitialized)
		{
			return;
		}
		string flashPath = Path.Combine(
			AppDomain.CurrentDomain.BaseDirectory,
			"runtime",
			"pepflashplayer.dll");
		if (!File.Exists(flashPath))
		{
			throw new FileNotFoundException("找不到 PPAPI Flash 运行库", flashPath);
		}
		CefSharpSettings.SubprocessExitIfParentProcessClosed = true;
		CefSettings settings = new CefSettings
		{
			CachePath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "cache"),
			LogFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "cef.log"),
			LogSeverity = LogSeverity.Warning
		};
		settings.CefCommandLineArgs["ppapi-flash-version"] = "99.0.0.999";
		settings.CefCommandLineArgs["ppapi-flash-path"] = flashPath;
		settings.CefCommandLineArgs["allow-outdated-plugins"] = "1";
		settings.CefCommandLineArgs["always-authorize-plugins"] = "1";
		settings.CefCommandLineArgs["plugin-policy"] = "allow";
		settings.CefCommandLineArgs["enable-features"] = "RunAllFlashInAllowMode";
		settings.CefCommandLineArgs["disable-features"] = "PreferHtmlOverPlugins";
		// GPU 加速为可选实验开关：仅 AOLA_GPU_MODE=accelerated 时追加；未设置或设为 default 时命令参数与原先完全一致。
		// 边界：这些参数只影响 Chromium 自身合成、光栅化与磁盘缓存，不改变 Flash 画面内容；
		// 不覆盖上面的 enable-features/disable-features，也不加入 disable-gpu、single-process 等关闭项。
		// 回退：把 AOLA_GPU_MODE 设为 default 或删除该变量后重启，即恢复原有参数，无需改代码或重装。
		if (string.Equals(Environment.GetEnvironmentVariable("AOLA_GPU_MODE"), "accelerated", StringComparison.OrdinalIgnoreCase))
		{
			settings.CefCommandLineArgs["ignore-gpu-blocklist"] = "1";
			settings.CefCommandLineArgs["enable-gpu-rasterization"] = "1";
			settings.CefCommandLineArgs["enable-zero-copy"] = "1";
			settings.CefCommandLineArgs["disk-cache-size"] = "268435456";
		}
		if (!Cef.Initialize(settings))
		{
			throw new InvalidOperationException("CEF 初始化失败");
		}
		IRequestContext context = Cef.GetGlobalRequestContext();
		Cef.UIThreadTaskFactory.StartNew(delegate
		{
			context.SetPreference("profile.default_content_setting_values.plugins", 1, out string _);
			context.SetPreference("plugins.run_all_flash_in_allow_mode", true, out string _);
		});
	}
}
