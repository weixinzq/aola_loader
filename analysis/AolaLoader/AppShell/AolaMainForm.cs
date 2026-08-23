using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Management;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;
using AolaLoader.BrowserHost.Contracts;
using AolaLoader.Features.Battle.State;
using AolaLoader.Features.PetMorph;
using AolaLoader.Features.PetMorph.Coordination;
using AolaLoader.Features.Theme.Coordination;
using AolaLoader.PacketHost;
using AolaLoader.PacketHost.Consumers;
using AolaLoader.UI.Battle;
using AolaLoader.UI.Common;
using AolaLoader.UI.Packets;
using AolaLoader.UI.PetMorph;
using AolaSocketHack.Contracts;
using CefSharp;
using CefSharp.WinForms;

namespace AolaLoader.AppShell;

internal sealed class AolaMainForm : AolaFormBase
{
	internal const string DefaultUrl = "https://aola.100bt.com/play/play.html";
	private readonly ToolStripTextBox _address = new ToolStripTextBox();
	private readonly ToolStripStatusLabel _status = new ToolStripStatusLabel("正在初始化奥拉星登录页面");
	private readonly System.Windows.Forms.Timer _injectTimer = new System.Windows.Forms.Timer();
	private readonly IChildWindowCoordinator _childWindowCoordinator;
	private readonly IThemeCoordinator _themeCoordinator;
	private readonly IPetMorphCoordinator _petMorphCoordinator;
	private readonly AolaHookController _hookController;
	private readonly IAolaPacketEventSource _packetEventSource;
	private readonly AolaReceiveLogger _receiveLogger;
	private readonly AolaBattleStateTracker _battleTracker;
	private readonly ChromiumWebBrowser _browser;
	private readonly IBrowserSession _browserSession;
	private readonly Dictionary<int, ToolStripMenuItem> _themeItems = new Dictionary<int, ToolStripMenuItem>();
	private ToolStripMenuItem _themeMenu;
	private bool _mainWindowMinimized;

	internal AolaMainForm(
		ChromiumWebBrowser browser,
		IBrowserSession browserSession,
		AolaHookController hookController,
		IAolaPacketEventSource packetEventSource,
		AolaReceiveLogger receiveLogger,
		AolaBattleStateTracker battleTracker,
		IThemeCoordinator themeCoordinator,
		IPetMorphCoordinator petMorphCoordinator,
		IChildWindowCoordinator childWindowCoordinator)
	{
		_browser = browser ?? throw new ArgumentNullException(nameof(browser));
		_browserSession = browserSession ?? throw new ArgumentNullException(nameof(browserSession));
		_hookController = hookController ?? throw new ArgumentNullException(nameof(hookController));
		_packetEventSource = packetEventSource ?? throw new ArgumentNullException(nameof(packetEventSource));
		_receiveLogger = receiveLogger ?? throw new ArgumentNullException(nameof(receiveLogger));
		_battleTracker = battleTracker ?? throw new ArgumentNullException(nameof(battleTracker));
		_themeCoordinator = themeCoordinator ?? throw new ArgumentNullException(nameof(themeCoordinator));
		_petMorphCoordinator = petMorphCoordinator ?? throw new ArgumentNullException(nameof(petMorphCoordinator));
		_childWindowCoordinator = childWindowCoordinator ?? throw new ArgumentNullException(nameof(childWindowCoordinator));

		Text = "Aola Loader";
		StartPosition = FormStartPosition.CenterScreen;
		MinimumSize = new Size(960, 640);
		Size = new Size(1200, 800);

		MenuStrip menuStrip = BuildMenu();
		ToolStrip toolbar = BuildToolbar();
		StatusStrip statusStrip = new StatusStrip();
		statusStrip.Items.Add(_status);
		ThemeChangeResult restoredTheme = _themeCoordinator.ApplyToRule(
			_themeCoordinator.Current.SelectedThemeId);
		UpdateThemeSelection(restoredTheme.RuleApplied ? restoredTheme.AppliedThemeId : 0);
		_petMorphCoordinator.RestoreFromSavedSettings();
		_browserSession.PageLifecycleChanged += OnBrowserLifecycleChanged;
		_browser.FrameLoadEnd += BrowserFrameLoadEnd;

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
		_childWindowCoordinator.Dispose();
		base.OnFormClosed(e);
	}

	protected override void OnResize(EventArgs e)
	{
		base.OnResize(e);
		bool minimized = WindowState == FormWindowState.Minimized;
		if (minimized && !_mainWindowMinimized)
		{
			_mainWindowMinimized = true;
			_childWindowCoordinator.RememberAndHideVisible();
		}
		else if (!minimized && _mainWindowMinimized)
		{
			_mainWindowMinimized = false;
			_childWindowCoordinator.RestoreVisibleAfterUnminimize();
		}
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

	private void UpdateThemeSelection(int themeId)
	{
		foreach (KeyValuePair<int, ToolStripMenuItem> entry in _themeItems)
		{
			entry.Value.Checked = entry.Key == themeId;
		}
	}

	private void ShowPetMorphPanel()
	{
		_childWindowCoordinator.Show(
			"petMorph",
			() => new AolaPetMorphForm(
				_petMorphCoordinator.ValidateRule,
				ApplyPetMorphRules,
				_petMorphCoordinator.CurrentRules,
				_petMorphCoordinator.Current.Enabled));
	}

	private async void ApplyPetMorphRules(IReadOnlyList<AolaPetMorphRule> rules, bool enabled)
	{
		_status.Text = enabled ? "正在准备背包形态映射并热推送规则……" : "正在关闭形态变化……";
		PetMorphApplyResult result = await _petMorphCoordinator.ApplyAsync(
			rules, enabled, CancellationToken.None);
		if (!result.RulesApplied)
		{
			_status.Text = "形态规则应用失败：" + result.Error;
			return;
		}
		if (!result.SettingsSaved)
		{
			_status.Text = "形态设置保存失败：" + result.Error;
			return;
		}
		if (!result.BridgeAvailable)
		{
			_status.Text = enabled
				? "规则已保存，但动态背包桥接模板不可用；保持官方背包模块"
				: "形态变化已关闭并保存";
			return;
		}
		if (result.PushBlocked)
		{
			_status.Text = "规则已保存；浏览器尚未就绪，打开或重新进入背包时应用：" + result.Error;
			return;
		}
		AolaPetMorphPushResult push = result.Push;
		if (push != null && !push.Superseded)
		{
			_status.Text = DescribePetMorphPush(push, rules, enabled);
		}
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
		refresh.Click += delegate { _browserSession.Refresh(BrowserRefreshMode.Normal); };
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
		if (!Uri.TryCreate(address, UriKind.Absolute, out Uri uri) ||
			(uri.Scheme != Uri.UriSchemeHttp && uri.Scheme != Uri.UriSchemeHttps))
		{
			MessageBox.Show(this, "请输入有效的 HTTP/HTTPS 地址。", "地址无效", MessageBoxButtons.OK, MessageBoxIcon.Warning);
			return;
		}
		_browserSession.Navigate(uri.AbsoluteUri);
	}

	private void ShowPackets()
	{
		_childWindowCoordinator.Show(
			"packets",
			() => new AolaPacketsForm(_packetEventSource),
			activate: false);
	}

	private void ShowBattleAssistant()
	{
		_childWindowCoordinator.Show(
			"battleAssistant",
			() => new AolaBattleAssistantForm(_battleTracker));
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

	private void OnBrowserLifecycleChanged(BrowserPageLifecycleEvent value)
	{
		if (IsDisposed)
		{
			return;
		}
		BeginInvoke(new Action(delegate
		{
			switch (value.Kind)
			{
				case BrowserPageLifecycleKind.NavigationStarted:
					_address.Text = value.Address;
					break;
				case BrowserPageLifecycleKind.NavigationFailed:
					_status.Text = "页面加载失败：" + value.Error;
					break;
			}
		}));
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
			if (isAolaPlayPage && _petMorphCoordinator.IsLiveBridgeAvailable)
			{
				morphResult = await _petMorphCoordinator.PushCurrentRulesAsync(CancellationToken.None);
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
