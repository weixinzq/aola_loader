using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Management;
using System.Windows.Forms;
using AolaSocketHack.Contracts;
using CefSharp;
using CefSharp.WinForms;

namespace AolaLoader;

internal sealed class AolaMainForm : Form
{
	private const string DefaultUrl = "https://aola.100bt.com/play/play.html";
	private readonly ToolStripTextBox _address = new ToolStripTextBox();
	private readonly ToolStripStatusLabel _status = new ToolStripStatusLabel("正在初始化奥拉星登录页面");
	private readonly Timer _injectTimer = new Timer();
	private readonly AolaHookController _hookController;
	private readonly AolaReceiveLogger _receiveLogger;
	private readonly AolaBattleStateTracker _battleTracker;
	private readonly AolaThemeRequestHandler _themeRequestHandler;
	private readonly ChromiumWebBrowser _browser;
	private readonly Dictionary<int, ToolStripMenuItem> _themeItems = new Dictionary<int, ToolStripMenuItem>();
	private AolaPacketsForm _packetsForm;
	private AolaBattleAssistantForm _battleAssistantForm;
	private AolaPetMorphForm _petMorphForm;
	private ToolStripMenuItem _themeMenu;

	public AolaMainForm()
	{
		Text = "Aola Loader";
		StartPosition = FormStartPosition.CenterScreen;
		MinimumSize = new Size(960, 640);
		Size = new Size(1200, 800);
		InitializeCef();
		_hookController = new AolaHookController();
		_receiveLogger = new AolaReceiveLogger();
		_battleTracker = new AolaBattleStateTracker();

		MenuStrip menuStrip = BuildMenu();
		ToolStrip toolbar = BuildToolbar();
		StatusStrip statusStrip = new StatusStrip();
		statusStrip.Items.Add(_status);
		_themeRequestHandler = new AolaThemeRequestHandler(Path.Combine(
			AppDomain.CurrentDomain.BaseDirectory,
			"Resources",
			"Themes"));
		_browser = new ChromiumWebBrowser(DefaultUrl)
		{
			Dock = DockStyle.Fill,
			RequestHandler = _themeRequestHandler
		};
		_browser.AddressChanged += BrowserAddressChanged;
		_browser.FrameLoadEnd += BrowserFrameLoadEnd;
		_browser.LoadError += BrowserLoadError;

		Controls.Add(_browser);
		Controls.Add(statusStrip);
		Controls.Add(toolbar);
		Controls.Add(menuStrip);
		MainMenuStrip = menuStrip;
		menuStrip.Dock = DockStyle.Top;
		toolbar.Dock = DockStyle.Top;
		statusStrip.Dock = DockStyle.Bottom;

		_injectTimer.Interval = 750;
		_injectTimer.Tick += delegate { EnsureHookInjected(); };
		AolaHookHostService.StatusReceived += HookStatusReceived;
		Shown += delegate
		{
			ShowPackets();
			_injectTimer.Start();
			EnsureHookInjected();
			_status.Text = _receiveLogger.IsActive
				? "接收日志已启用：" + _receiveLogger.LogPath
				: "接收日志启用失败：" + _receiveLogger.ErrorMessage;
		};
	}

	protected override void OnFormClosed(FormClosedEventArgs e)
	{
		AolaHookHostService.StatusReceived -= HookStatusReceived;
		_injectTimer.Stop();
		_injectTimer.Dispose();
		_petMorphForm?.Dispose();
		_battleAssistantForm?.Close();
		_packetsForm?.Close();
		_battleTracker.Dispose();
		_receiveLogger.Dispose();
		_hookController.Dispose();
		_browser.Dispose();
		base.OnFormClosed(e);
	}

	private MenuStrip BuildMenu()
	{
		MenuStrip menu = new MenuStrip
		{
			GripStyle = ToolStripGripStyle.Hidden,
			BackColor = SystemColors.Control
		};
		ToolStripMenuItem extensions = new ToolStripMenuItem("扩展");
		ToolStripMenuItem featurePanel = new ToolStripMenuItem("功能面板")
		{
			ShortcutKeys = Keys.F2,
			ShowShortcutKeys = true
		};
		featurePanel.Click += delegate { ShowPetMorphPanel(); };
		ToolStripMenuItem battleAssistant = new ToolStripMenuItem("对战助手")
		{
			ShortcutKeys = Keys.F3,
			ShowShortcutKeys = true
		};
		battleAssistant.Click += delegate { ShowBattleAssistant(); };
		extensions.DropDownItems.Add(featurePanel);
		extensions.DropDownItems.Add(battleAssistant);
		extensions.DropDownItems.Add(new ToolStripSeparator());
		extensions.DropDownItems.Add(BuildThemeMenu());
		menu.Items.Add(extensions);
		return menu;
	}

	private ToolStripMenuItem BuildThemeMenu()
	{
		_themeMenu = new ToolStripMenuItem("游戏主题界面");
		string[] names =
		{
			"默认",
			"女皇花嫁主题风格",
			"星尘花嫁主题风格",
			"阿比斯花嫁主题风格",
			"奥拉星怀旧风格",
			"提亚玛特花嫁主题风格",
			"渡至臻主题风格",
			"梦花嫁主题风格",
			"羲和花嫁主题风格",
			"深海银河主题风格"
		};
		for (int id = 0; id < names.Length; id++)
		{
			int themeId = id;
			ToolStripMenuItem item = new ToolStripMenuItem(names[id])
			{
				Tag = themeId
			};
			item.Click += delegate { ChangeTheme(themeId, item.Text); };
			_themeItems.Add(themeId, item);
			_themeMenu.DropDownItems.Add(item);
		}
		_themeItems[0].Checked = true;
		_themeMenu.MouseEnter += delegate { _themeMenu.ShowDropDown(); };
		return _themeMenu;
	}

	private void ChangeTheme(int themeId, string themeName)
	{
		try
		{
			_themeRequestHandler.SelectedThemeId = themeId == 0 ? -1 : themeId;
			UpdateThemeSelection(themeId);
			_status.Text = themeId == 0
				? "已关闭主题资源替换，正在恢复官方默认资源"
				: "已启用 skin*.swf 本地替换，正在重新加载：" + themeName;
			_browser.Reload(true);
		}
		catch (Exception ex) when (ex is InvalidOperationException || ex is ArgumentOutOfRangeException || ex is ObjectDisposedException)
		{
			_status.Text = "主题资源替换失败：" + ex.Message;
			MessageBox.Show(this, ex.Message, "主题资源替换失败", MessageBoxButtons.OK, MessageBoxIcon.Warning);
		}
	}

	private void UpdateThemeSelection(int themeId)
	{
		foreach (KeyValuePair<int, ToolStripMenuItem> entry in _themeItems)
		{
			entry.Value.Checked = entry.Key == themeId;
		}
	}

	private void ShowPetMorphPanel()
	{
		if (_petMorphForm == null || _petMorphForm.IsDisposed)
		{
			_petMorphForm = new AolaPetMorphForm(
				_themeRequestHandler.ValidatePetMorphRule,
				ApplyPetMorphRules);
			_petMorphForm.FormClosed += delegate { _petMorphForm = null; };
			_petMorphForm.Show(this);
		}
		else
		{
			_petMorphForm.Show();
			_petMorphForm.BringToFront();
			_petMorphForm.Activate();
		}
	}

	private void ApplyPetMorphRules(IReadOnlyList<AolaPetMorphRule> rules, bool enabled)
	{
		_themeRequestHandler.SetPetMorphRules(rules, enabled);
		_status.Text = enabled
			? "形态变化已启用；重新进入背包或重启游戏后应用远程资源替换"
			: "形态变化已关闭，官方资源不再被拦截";
		_browser.Reload(true);
	}

	private static void InitializeCef()
	{
		if (Cef.IsInitialized)
		{
			return;
		}
		string flashPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "runtime", "pepflashplayer.dll");
		if (!File.Exists(flashPath))
		{
			throw new FileNotFoundException("找不到 PPAPI Flash 运行库", flashPath);
		}
		CefSharpSettings.SubprocessExitIfParentProcessClosed = true;
		CefSettings settings = new CefSettings
		{
			CachePath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "cache"),
			LogFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "cef.log"),
			LogSeverity = LogSeverity.Warning,
			WindowlessRenderingEnabled = true
		};
		settings.CefCommandLineArgs["ppapi-flash-version"] = "99.0.0.999";
		settings.CefCommandLineArgs["ppapi-flash-path"] = flashPath;
		settings.CefCommandLineArgs["allow-outdated-plugins"] = "1";
		settings.CefCommandLineArgs["always-authorize-plugins"] = "1";
		settings.CefCommandLineArgs["plugin-policy"] = "allow";
		settings.CefCommandLineArgs["enable-features"] = "RunAllFlashInAllowMode";
		settings.CefCommandLineArgs["disable-features"] = "PreferHtmlOverPlugins";
		settings.SetOffScreenRenderingBestPerformanceArgs();
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

	private ToolStrip BuildToolbar()
	{
		ToolStrip toolbar = new ToolStrip { GripStyle = ToolStripGripStyle.Hidden };
		ToolStripButton back = new ToolStripButton("后退");
		ToolStripButton forward = new ToolStripButton("前进");
		ToolStripButton refresh = new ToolStripButton("刷新");
		ToolStripButton go = new ToolStripButton("打开");
		ToolStripButton packets = new ToolStripButton("抓包 / 发包");
		ToolStripButton devTools = new ToolStripButton("开发者工具");
		_address.AutoSize = false;
		_address.Width = 520;
		_address.Text = DefaultUrl;
		back.Click += delegate { if (_browser.CanGoBack) _browser.Back(); };
		forward.Click += delegate { if (_browser.CanGoForward) _browser.Forward(); };
		refresh.Click += delegate { _browser.Reload(); };
		go.Click += delegate { Navigate(); };
		_address.KeyDown += delegate(object sender, KeyEventArgs e)
		{
			if (e.KeyCode == Keys.Enter)
			{
				e.SuppressKeyPress = true;
				Navigate();
			}
		};
		packets.Click += delegate { ShowPackets(); };
		devTools.Click += delegate { _browser.ShowDevTools(); };
		toolbar.Items.AddRange(new ToolStripItem[] { back, forward, refresh, _address, go, new ToolStripSeparator(), packets, devTools });
		return toolbar;
	}

	private void Navigate()
	{
		string address = _address.Text.Trim();
		if (!Uri.TryCreate(address, UriKind.Absolute, out Uri uri) || (uri.Scheme != Uri.UriSchemeHttp && uri.Scheme != Uri.UriSchemeHttps))
		{
			MessageBox.Show(this, "请输入有效的 HTTP/HTTPS 地址。", "地址无效", MessageBoxButtons.OK, MessageBoxIcon.Warning);
			return;
		}
		_browser.Load(uri.AbsoluteUri);
	}

	private void ShowPackets()
	{
		if (_packetsForm == null || _packetsForm.IsDisposed)
		{
			_packetsForm = new AolaPacketsForm();
			_packetsForm.FormClosed += delegate { _packetsForm = null; };
			_packetsForm.Show(this);
		}
		else
		{
			_packetsForm.Show();
			_packetsForm.BringToFront();
		}
	}

	private void ShowBattleAssistant()
	{
		if (_battleAssistantForm == null || _battleAssistantForm.IsDisposed)
		{
			_battleAssistantForm = new AolaBattleAssistantForm(_battleTracker);
			_battleAssistantForm.FormClosed += delegate { _battleAssistantForm = null; };
			_battleAssistantForm.Show(this);
		}
		else
		{
			_battleAssistantForm.Show();
			_battleAssistantForm.BringToFront();
			_battleAssistantForm.Activate();
		}
	}

	private void EnsureHookInjected()
	{
		int processId = FindNetworkProcessId();
		if (processId == 0)
		{
			_status.Text = "等待 CEF network.mojom 子进程";
			return;
		}
		string libraryPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "AolaSocketHack.dll");
		_hookController.EnsureInjected(processId, libraryPath);
	}

	private static int FindNetworkProcessId()
	{
		string query = string.Format("select CommandLine,ProcessId from Win32_Process where ParentProcessID={0} and Name='CefSharp.BrowserSubprocess.exe'", Process.GetCurrentProcess().Id);
		try
		{
			using (ManagementObjectSearcher searcher = new ManagementObjectSearcher(query))
			using (ManagementObjectCollection processes = searcher.Get())
			{
				foreach (ManagementObject process in processes.Cast<ManagementObject>())
				{
					string commandLine = Convert.ToString(process["CommandLine"]);
					if (commandLine.IndexOf("type=network.mojom", StringComparison.OrdinalIgnoreCase) >= 0)
					{
						return Convert.ToInt32(process["ProcessId"]);
					}
				}
			}
		}
		catch (ManagementException)
		{
		}
		return 0;
	}

	private void BrowserAddressChanged(object sender, AddressChangedEventArgs e)
	{
		if (IsDisposed)
		{
			return;
		}
		BeginInvoke(new Action(delegate { _address.Text = e.Address; }));
	}

	private void BrowserLoadError(object sender, LoadErrorEventArgs e)
	{
		if (e.ErrorCode == CefErrorCode.Aborted || IsDisposed)
		{
			return;
		}
		BeginInvoke(new Action(delegate { _status.Text = "页面加载失败：" + e.ErrorText; }));
	}

	private async void BrowserFrameLoadEnd(object sender, FrameLoadEndEventArgs e)
	{
		if (!e.Frame.IsMain || IsDisposed)
		{
			return;
		}
		try
		{
			bool isAolaPlayPage = Uri.TryCreate(e.Url, UriKind.Absolute, out Uri pageUri) &&
				string.Equals(pageUri.Host, "aola.100bt.com", StringComparison.OrdinalIgnoreCase) &&
				pageUri.AbsolutePath.StartsWith("/play/", StringComparison.OrdinalIgnoreCase);
			string script = isAolaPlayPage
				? @"(function () {
	var plugins = navigator.plugins || [];
	var flash = plugins['Shockwave Flash'] || Array.from(plugins).find(function (p) {
		return /flash/i.test(p.name || '');
	});
	if (!flash) return false;
	var attempts = 0;
	var timer = window.setInterval(function () {
		if (typeof window.flashHeartBeat === 'function') window.flashHeartBeat();
		var game = document.getElementById('swfContainer');
		if (game) game.style.display = 'block';
		var fallback = document.getElementById('normalize-flash-launch-wrapper');
		if (fallback) fallback.style.display = 'none';
		if (++attempts >= 16) window.clearInterval(timer);
	}, 250);
	return true;
})()"
				: "Array.from(navigator.plugins || []).some(function(p){ return /flash/i.test(p.name || ''); })";
			JavascriptResponse response = await e.Frame.EvaluateScriptAsync(script);
			bool detected = response.Success && response.Result is bool value && value;
			BeginInvoke(new Action(delegate
			{
				_status.Text = detected
					? (isAolaPlayPage ? "Flash 插件已启用，已兼容 1×1 心跳探针" : "Flash 插件已启用")
					: "页面已加载，但 navigator.plugins 尚未识别 Flash";
			}));
		}
		catch
		{
		}
	}

	private void HookStatusReceived(AolaHookStatus status)
	{
		if (status == null || IsDisposed)
		{
			return;
		}
		if (InvokeRequired)
		{
			BeginInvoke(new Action<AolaHookStatus>(HookStatusReceived), status);
			return;
		}
		_status.Text = string.Format("[{0}] {1}", status.Level, status.Message);
	}
}
