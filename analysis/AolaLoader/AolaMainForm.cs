using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Management;
using System.Runtime.InteropServices;
using System.Threading.Tasks;
using System.Windows.Forms;
using AolaLoader.Features.PetMorph.Settings;
using AolaLoader.Features.Theme.Coordination;
using AolaLoader.Features.Theme.Settings;
using AolaLoader.PacketHost;
using AolaLoader.Settings;
using AolaSocketHack.Contracts;
using CefSharp;
using CefSharp.WinForms;
using Newtonsoft.Json;

namespace AolaLoader;

internal sealed class AolaMainForm : AolaFormBase
{
	private const string DefaultUrl = "https://aola.100bt.com/play/play.html";
	private const int SwShowNoActivate = 4;
	private readonly ToolStripTextBox _address = new ToolStripTextBox();
	private readonly ToolStripStatusLabel _status = new ToolStripStatusLabel("正在初始化奥拉星登录页面");
	private readonly Timer _injectTimer = new Timer();
	private readonly List<Form> _childrenVisibleBeforeMinimize = new List<Form>();
	private readonly ISettingsSectionStore _sectionSettingsStore;
	private readonly PetMorphSettingsCodec _petMorphSettingsCodec = new PetMorphSettingsCodec();
	private readonly IThemeCoordinator _themeCoordinator;
	private PetMorphSettings _petMorphSettings;
	private readonly AolaHookController _hookController;
	private readonly IAolaPacketEventSource _packetEventSource;
	private readonly AolaReceiveLogger _receiveLogger;
	private readonly AolaBattleStateTracker _battleTracker;
	private readonly AolaThemeRequestHandler _themeRequestHandler;
	private readonly AolaPetMorphLiveBridge _petMorphLiveBridge = new AolaPetMorphLiveBridge();
	private readonly ChromiumWebBrowser _browser;
	private readonly Dictionary<int, ToolStripMenuItem> _themeItems = new Dictionary<int, ToolStripMenuItem>();
	private AolaPacketsForm _packetsForm;
	private AolaBattleAssistantForm _battleAssistantForm;
	private AolaPetMorphForm _petMorphForm;
	private ToolStripMenuItem _themeMenu;
	private bool _mainWindowMinimized;
	private long _petMorphPushRequest;

	public AolaMainForm()
	{
		Text = "Aola Loader";
		StartPosition = FormStartPosition.CenterScreen;
		MinimumSize = new Size(960, 640);
		Size = new Size(1200, 800);
		string settingsPath = Path.Combine(
			AppDomain.CurrentDomain.BaseDirectory,
			"settings.json");
		_sectionSettingsStore = new JsonSettingsSectionStore(settingsPath);
		_petMorphSettings = _sectionSettingsStore.Load(
			PetMorphSettingsCodec.SectionKey,
			_petMorphSettingsCodec).Value;
		InitializeCef();
		_hookController = new AolaHookController();
		_packetEventSource = new AolaHookHostAdapter();
		_receiveLogger = new AolaReceiveLogger(_packetEventSource);
		_battleTracker = new AolaBattleStateTracker(_packetEventSource);
		_themeRequestHandler = new AolaThemeRequestHandler(Path.Combine(
			AppDomain.CurrentDomain.BaseDirectory,
			"Resources",
			"Themes"), Path.Combine(
			AppDomain.CurrentDomain.BaseDirectory,
			"Resources",
			"Data",
			"pet-poster-catalog.json"), Path.Combine(
			AppDomain.CurrentDomain.BaseDirectory,
			"Resources",
			"Patches",
			"newpetpackage-morph-live.fws.swf"),
			_petMorphSettings.LiveBridgeEnabled);
		_themeCoordinator = new ThemeCoordinator(
			_sectionSettingsStore,
			new ThemeSettingsCodec(),
			_themeRequestHandler);

		MenuStrip menuStrip = BuildMenu();
		ToolStrip toolbar = BuildToolbar();
		StatusStrip statusStrip = new StatusStrip();
		statusStrip.Items.Add(_status);
		ThemeChangeResult restoredTheme = _themeCoordinator.ApplyToRule(
			_themeCoordinator.Current.SelectedThemeId);
		UpdateThemeSelection(restoredTheme.RuleApplied ? restoredTheme.AppliedThemeId : 0);
		_themeRequestHandler.SetPetMorphRules(
			ToMorphRules(_petMorphSettings.Rules),
			_petMorphSettings.Enabled);
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
		_packetEventSource.StatusReceived += HookStatusReceived;
		Shown += delegate
		{
			ShowPackets();
			_injectTimer.Start();
			EnsureHookInjected();
			_status.Text = "接收日志正在内存中暂存；点击“保留日志”后写入文件。";
		};
	}

	protected override void OnFormClosed(FormClosedEventArgs e)
	{
		_packetEventSource.StatusReceived -= HookStatusReceived;
		_injectTimer.Stop();
		_injectTimer.Dispose();
		_petMorphForm?.Dispose();
		_battleAssistantForm?.Close();
		_packetsForm?.Close();
		_battleTracker.Dispose();
		_receiveLogger.Dispose();
		_packetEventSource.Dispose();
		_hookController.Dispose();
		_browser.Dispose();
		base.OnFormClosed(e);
	}

	protected override void OnResize(EventArgs e)
	{
		base.OnResize(e);
		bool minimized = WindowState == FormWindowState.Minimized;
		if (minimized && !_mainWindowMinimized)
		{
			_mainWindowMinimized = true;
			_childrenVisibleBeforeMinimize.Clear();
			RememberVisibleChild(_petMorphForm);
			RememberVisibleChild(_battleAssistantForm);
			RememberVisibleChild(_packetsForm);
			foreach (Form child in _childrenVisibleBeforeMinimize)
			{
				child.Hide();
			}
		}
		else if (!minimized && _mainWindowMinimized)
		{
			_mainWindowMinimized = false;
			foreach (Form child in _childrenVisibleBeforeMinimize)
			{
				if (!child.IsDisposed)
				{
					// 不激活子窗口，避免还原主窗口时焦点被抢走。
					ShowWindow(child.Handle, SwShowNoActivate);
				}
			}
			_childrenVisibleBeforeMinimize.Clear();
		}
	}

	private void RememberVisibleChild(Form child)
	{
		if (child != null && !child.IsDisposed && child.Visible)
		{
			_childrenVisibleBeforeMinimize.Add(child);
		}
	}

	[DllImport("user32.dll")]
	private static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

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
		foreach (ThemeOption option in _themeCoordinator.Options)
		{
			int themeId = option.Id;
			string displayName = option.DisplayName;
			ToolStripMenuItem item = new ToolStripMenuItem(displayName)
			{
				Tag = themeId
			};
			item.Click += delegate { ChangeTheme(themeId, displayName); };
			_themeItems.Add(themeId, item);
			_themeMenu.DropDownItems.Add(item);
		}
		_themeItems[0].Checked = true;
		_themeMenu.MouseEnter += delegate { _themeMenu.ShowDropDown(); };
		return _themeMenu;
	}

	private void ChangeTheme(int themeId, string themeName)
	{
		ThemeChangeResult result = _themeCoordinator.ApplyAndSave(themeId);
		if (result.RuleApplied)
		{
			UpdateThemeSelection(result.AppliedThemeId);
		}
		if (result.Succeeded)
		{
			_status.Text = themeId == 0
				? "已恢复默认主题并保存；刷新页面后生效"
				: "已启用并保存主题：" + themeName + "；刷新页面后生效";
			return;
		}
		_status.Text = (result.RuleApplied ? "主题设置保存失败：" : "主题资源替换失败：") + result.Error;
		if (!result.RuleApplied)
		{
			MessageBox.Show(this, result.Error, "主题资源替换失败", MessageBoxButtons.OK, MessageBoxIcon.Warning);
		}
	}

	private static AolaPetMorphRule[] ToMorphRules(IEnumerable<PetMorphRuleSettings> data)
	{
		return (data ?? Enumerable.Empty<PetMorphRuleSettings>())
			.Where(item => item != null && (item.OriginalId > 0 || item.PosterSourceId > 0))
			.Select(item => new AolaPetMorphRule(
				item.Note ?? string.Empty,
				item.OriginalId,
				item.BackpackId,
				item.PosterSourceId,
				item.PosterId,
				item.HideOriginalModel,
				item.RemoveOriginalBackground,
				item.ReplaceBackpackIcon))
			.ToArray();
	}

	private bool TrySavePetMorphSettings()
	{
		SettingsSectionSaveResult result = _sectionSettingsStore.Save(
			PetMorphSettingsCodec.SectionKey,
			_petMorphSettings,
			_petMorphSettingsCodec);
		if (!result.Succeeded)
		{
			_status.Text = "形态设置保存失败：" + result.Error;
			return false;
		}
		return true;
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
				ApplyPetMorphRules,
				ToMorphRules(_petMorphSettings.Rules),
				_petMorphSettings.Enabled);
			_petMorphForm.FormClosed += delegate { _petMorphForm = null; };
			_petMorphForm.Show();
		}
		else
		{
			_petMorphForm.Show();
			_petMorphForm.BringToFront();
			_petMorphForm.Activate();
		}
	}

	private async void ApplyPetMorphRules(IReadOnlyList<AolaPetMorphRule> rules, bool enabled)
	{
		_themeRequestHandler.SetPetMorphRules(rules, enabled);
		_petMorphSettings = _petMorphSettingsCodec.Normalize(new PetMorphSettings(
			enabled,
			_petMorphSettings.LiveBridgeEnabled,
			(rules ?? Array.Empty<AolaPetMorphRule>()).Select(rule => new PetMorphRuleSettings(
				rule.Note,
				rule.OriginalId,
				rule.BackpackId,
				rule.PosterSourceId,
				rule.PosterId,
				rule.HideOriginalModel,
				rule.RemoveOriginalBackground,
				rule.ReplaceBackpackIcon))));
		if (!TrySavePetMorphSettings())
		{
			return;
		}

		if (!_themeRequestHandler.IsPetMorphLiveBridgeAvailable)
		{
			_status.Text = enabled
				? "规则已保存，但动态背包桥接模板不可用；保持官方背包模块"
				: "形态变化已关闭并保存";
			return;
		}

		_status.Text = enabled ? "正在准备背包形态映射并热推送规则……" : "正在关闭形态变化……";
		try
		{
			using (IFrame frame = _browser.GetMainFrame())
			{
				AolaPetMorphPushResult result = await PushPetMorphRulesAsync(frame, rules, enabled);
				if (!result.Superseded)
				{
					_status.Text = DescribePetMorphPush(result, rules, enabled);
				}
			}
		}
		catch (Exception ex) when (ex is InvalidOperationException || ex is ObjectDisposedException)
		{
			_status.Text = "规则已保存；浏览器尚未就绪，打开或重新进入背包时应用：" + ex.Message;
		}
	}

	private async Task<AolaPetMorphPushResult> PushPetMorphRulesAsync(
		IFrame frame,
		IReadOnlyList<AolaPetMorphRule> rules,
		bool enabled)
	{
		long request = System.Threading.Interlocked.Increment(ref _petMorphPushRequest);
		IReadOnlyDictionary<int, int> mappings =
			await _themeRequestHandler.GetAvailableLivePosterMappingsAsync(rules, enabled);
		if (request != System.Threading.Volatile.Read(ref _petMorphPushRequest))
		{
			return AolaPetMorphPushResult.SupersededResult();
		}
		IReadOnlyDictionary<int, bool> hiddenBackgrounds = (rules ?? Array.Empty<AolaPetMorphRule>())
			.Where(rule => rule != null && rule.RemoveOriginalBackground && rule.OriginalId > 0)
			.GroupBy(rule => rule.OriginalId)
			.ToDictionary(group => group.Key, group => true);
		IReadOnlyDictionary<int, int> iconMappings = (rules ?? Array.Empty<AolaPetMorphRule>())
			.Where(rule => rule != null && rule.ReplaceBackpackIcon &&
				rule.OriginalId > 0 && rule.BackpackId > 0)
			.GroupBy(rule => rule.OriginalId)
			.Select(group => group.Last())
			.ToDictionary(rule => rule.OriginalId, rule => rule.BackpackId);
		AolaPetMorphPushResult result = await _petMorphLiveBridge.PushAsync(
			frame, mappings, hiddenBackgrounds, iconMappings, enabled);
		return request == System.Threading.Volatile.Read(ref _petMorphPushRequest)
			? result
			: AolaPetMorphPushResult.SupersededResult();
	}

	private static string DescribePetMorphPush(
		AolaPetMorphPushResult result,
		IReadOnlyList<AolaPetMorphRule> rules,
		bool enabled)
	{
		if (!result.Injected)
		{
			return "规则已保存，但热推送失败：" + (result.Error ?? "未知错误");
		}
		if (!enabled)
		{
			return result.BridgeReady
				? "形态变化已关闭；当前背包显示已刷新"
				: "形态变化已关闭；背包模块尚未加载";
		}
		int requestedMappings = (rules ?? Array.Empty<AolaPetMorphRule>())
			.Count(rule => rule != null && (rule.PosterId > 0 ||
				rule.RemoveOriginalBackground || rule.ReplaceBackpackIcon));
		if (result.BridgeReady || result.RefreshInvoked)
		{
			return "形态规则已热推送并刷新当前背包；不可用的目标海报自动保持原形态";
		}
		return requestedMappings > 0
			? "形态规则已热推送；背包模块打开后自动应用，不需要刷新登录器"
			: "形态规则已热推送；当前没有需要桥接的背景、头像或海报映射";
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
		ToolStripButton retainLog = new ToolStripButton("保留日志");
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
		retainLog.Click += async delegate
		{
			retainLog.Enabled = false;
			string logPath = null;
			string errorMessage = null;
			bool retained = await Task.Run(() => _receiveLogger.TryRetain(out logPath, out errorMessage));
			if (retained)
			{
				retainLog.Text = "日志已保留";
				long discarded = _receiveLogger.DiscardedRecordCount;
				_status.Text = "接收日志已保留：" + logPath + (discarded > 0
					? "（内存上限前已丢弃 " + discarded + " 条较早记录）"
					: string.Empty);
			}
			else
			{
				retainLog.Enabled = true;
				_status.Text = "接收日志保留失败：" + errorMessage;
				MessageBox.Show(this, errorMessage, "保留日志失败", MessageBoxButtons.OK, MessageBoxIcon.Error);
			}
		};
		toolbar.Items.AddRange(new ToolStripItem[] { back, forward, refresh, _address, go, new ToolStripSeparator(), packets, devTools, retainLog });
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
			_packetsForm = new AolaPacketsForm(_packetEventSource);
			_packetsForm.FormClosed += delegate { _packetsForm = null; };
			_packetsForm.Show();
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
			_battleAssistantForm.Show();
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
			AolaPetMorphPushResult morphResult = null;
			if (isAolaPlayPage && _themeRequestHandler.IsPetMorphLiveBridgeAvailable)
			{
				morphResult = await PushPetMorphRulesAsync(
					e.Frame,
					ToMorphRules(_petMorphSettings.Rules),
					_petMorphSettings.Enabled);
			}
			if (morphResult != null && morphResult.Superseded)
			{
				return;
			}
			BeginInvoke(new Action(delegate
			{
				_status.Text = morphResult != null && !morphResult.Superseded && !morphResult.Injected
					? "页面已加载，但形态规则注入失败：" + (morphResult.Error ?? "未知错误")
					: detected
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
