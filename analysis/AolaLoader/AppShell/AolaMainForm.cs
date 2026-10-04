// 架构角色：WinForms 外壳与运行时编排边界，承载浏览器、菜单、子窗口、注入轮询和页面恢复。
// 数据流：用户/CEF 生命周期事件 -> 各 coordinator；状态与结果 -> UI，不实现底层协议规则。
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
using AolaLoader.Features.ActiveSend;
using AolaLoader.Features.Lineup;
using AolaLoader.UI.Lineup;
using AolaLoader.Features.Battle.State;
using AolaLoader.Features.Battle.Coordination;
using AolaLoader.Features.Battle.Bridge;
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
using Newtonsoft.Json.Linq;

namespace AolaLoader.AppShell;

internal sealed class AolaMainForm : AolaFormBase
{
	internal const string DefaultUrl = "https://aola.100bt.com/play/play.html";
	private const double PageWidth = 962;
	private const double PageHeight = 560;
	private readonly ToolStrip _toolbar;
	private readonly ToolStripDropDownButton _windowSizeMenu = new ToolStripDropDownButton("窗口大小");
	private double _windowScale = 1;
	private int _browserZoomRevision;
	private readonly ToolStripStatusLabel _status = new ToolStripStatusLabel("正在初始化奥拉星登录页面");
	private readonly ToolStripDropDownButton _playbackMenu = new ToolStripDropDownButton("速度");
	private readonly ToolStripDropDownButton _qualityMenu = new ToolStripDropDownButton("画质");
	private readonly System.Windows.Forms.Timer _injectTimer = new System.Windows.Forms.Timer();
	private readonly System.Windows.Forms.Timer _battleMorphTimer = new System.Windows.Forms.Timer();
	private readonly IChildWindowCoordinator _childWindowCoordinator;
	private readonly IThemeCoordinator _themeCoordinator;
	private readonly IPetMorphCoordinator _petMorphCoordinator;
	private readonly BattlePresentationCoordinator _battlePresentationCoordinator;
	private readonly AolaHookController _hookController;
	private readonly IAolaPacketEventSource _packetEventSource;
	private readonly IAolaCommandSender _commandSender;
	private readonly AolaTextSequenceRunner _textSequenceRunner;
	private readonly LineupCoordinator _lineupCoordinator;
	private readonly IPageBridge _pageBridge;
	private readonly AolaReceiveLogger _receiveLogger;
	private readonly AolaBattleStateTracker _battleTracker;
	private readonly ChromiumWebBrowser _browser;
	private readonly IBrowserSession _browserSession;
	private readonly Dictionary<int, ToolStripMenuItem> _themeItems = new Dictionary<int, ToolStripMenuItem>();
	private ToolStripMenuItem _themeMenu;
	private bool _injectCheckInProgress;
	private bool _battleMorphCheckInProgress;
	private bool _isClosing;
	private bool _mainWindowMinimized;

	internal AolaMainForm(
		ChromiumWebBrowser browser,
		IBrowserSession browserSession,
		AolaHookController hookController,
		IAolaPacketEventSource packetEventSource,
		IAolaCommandSender commandSender,
		IPageBridge pageBridge,
		AolaReceiveLogger receiveLogger,
		AolaBattleStateTracker battleTracker,
		IThemeCoordinator themeCoordinator,
		IPetMorphCoordinator petMorphCoordinator,
		BattlePresentationCoordinator battlePresentationCoordinator,
		IChildWindowCoordinator childWindowCoordinator,
		LineupCoordinator lineupCoordinator,
		AolaTextSequenceRunner textSequenceRunner)
	{
		_browser = browser ?? throw new ArgumentNullException(nameof(browser));
		_browserSession = browserSession ?? throw new ArgumentNullException(nameof(browserSession));
		_hookController = hookController ?? throw new ArgumentNullException(nameof(hookController));
		_packetEventSource = packetEventSource ?? throw new ArgumentNullException(nameof(packetEventSource));
		_commandSender = commandSender ?? throw new ArgumentNullException(nameof(commandSender));
		_pageBridge = pageBridge ?? throw new ArgumentNullException(nameof(pageBridge));
		_receiveLogger = receiveLogger ?? throw new ArgumentNullException(nameof(receiveLogger));
		_battleTracker = battleTracker ?? throw new ArgumentNullException(nameof(battleTracker));
		_themeCoordinator = themeCoordinator ?? throw new ArgumentNullException(nameof(themeCoordinator));
		_petMorphCoordinator = petMorphCoordinator ?? throw new ArgumentNullException(nameof(petMorphCoordinator));
		_battlePresentationCoordinator = battlePresentationCoordinator ?? throw new ArgumentNullException(nameof(battlePresentationCoordinator));
		_childWindowCoordinator = childWindowCoordinator ?? throw new ArgumentNullException(nameof(childWindowCoordinator));
		_lineupCoordinator = lineupCoordinator ?? throw new ArgumentNullException(nameof(lineupCoordinator));
		_textSequenceRunner = textSequenceRunner;

		Text = "Aola Loader";
		AutoScaleDimensions = new SizeF(96, 96);
		AutoScaleMode = AutoScaleMode.Dpi;
		StartPosition = FormStartPosition.CenterScreen;
		FormBorderStyle = FormBorderStyle.FixedSingle;
		MaximizeBox = true;

		_toolbar = BuildToolbar();
		StatusStrip statusStrip = new StatusStrip();
	//	statusStrip.Items.Add(_status);
		ThemeChangeResult restoredTheme = _themeCoordinator.ApplyToRule(
			_themeCoordinator.Current.SelectedThemeId);
		UpdateThemeSelection(restoredTheme.RuleApplied ? restoredTheme.AppliedThemeId : 0);
		_petMorphCoordinator.RestoreFromSavedSettings();
		_browserSession.PageLifecycleChanged += OnBrowserLifecycleChanged;
		_browser.FrameLoadEnd += BrowserFrameLoadEnd;
		_browser.ClientSizeChanged += BrowserClientSizeChanged;

		Controls.Add(_browser);
	//	Controls.Add(statusStrip);
		Controls.Add(_toolbar);
		_toolbar.Dock = DockStyle.Top;
		statusStrip.Dock = DockStyle.Bottom;

		_injectTimer.Interval = 750;
		_injectTimer.Tick += delegate { EnsureHookInjectedAsync(); };
		_battleMorphTimer.Interval = 500;
		_battleMorphTimer.Tick += async delegate
		{
			if (_battleMorphCheckInProgress) return;
			_battleMorphCheckInProgress = true;
			try
			{
				if (await _battlePresentationCoordinator.TryActivatePendingMorphRulesAsync(CancellationToken.None))
				{
					_status.Text = "战斗模型规则已在官方资源清理后切换；下一场战斗生效。";
				}
			}
			finally
			{
				_battleMorphCheckInProgress = false;
			}
		};
		_packetEventSource.StatusReceived += HookStatusReceived;
		Shown += async delegate
		{
			await UpdateBrowserZoomAsync();
			_injectTimer.Start();
			_battleMorphTimer.Start();
			EnsureHookInjectedAsync();
			_status.Text = "收发日志默认关闭；点击“保留日志”后开始写入文件。";
			BattleMorphPreparationResult morph = await _battlePresentationCoordinator
				.RestoreMorphRulesAsync(CancellationToken.None);
			if (_battlePresentationCoordinator.Current.BattleMorphEnabled)
			{
				_status.Text = morph.Succeeded
					? "战斗模型规则已准备；请使用全新游戏进程验证替换。"
					: "战斗模型规则未启用：" + morph.Message;
			}
		};
	}

	protected override void OnLoad(EventArgs e)
	{
		base.OnLoad(e);
		ApplyWindowScale(_windowScale);
	}

	protected override void OnDpiChanged(DpiChangedEventArgs e)
	{
		base.OnDpiChanged(e);
		// 等 WinForms 应用新 DPI 的控件尺寸后，再使用最终布局计算页面缩放。
		BeginInvoke(new Action(async delegate
		{
			if (_isClosing || IsDisposed) return;
			if (WindowState == FormWindowState.Normal) ApplyWindowScale(_windowScale);
			await UpdateBrowserZoomAsync();
		}));
	}

	protected override void OnFormClosed(FormClosedEventArgs e)
	{
		_isClosing = true;
		_packetEventSource.StatusReceived -= HookStatusReceived;
		_browser.ClientSizeChanged -= BrowserClientSizeChanged;
		_injectTimer.Stop();
		_injectTimer.Dispose();
		_battleMorphTimer.Stop();
		_battleMorphTimer.Dispose();
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

	private ToolStripDropDownButton BuildExtensionsButton()
	{
		ToolStripDropDownButton extensions = new ToolStripDropDownButton("扩展");
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
		ToolStripMenuItem battlePresentation = new ToolStripMenuItem("战斗表现");
		battlePresentation.Click += delegate { ShowBattlePresentation(); };
		extensions.DropDownItems.Add(featurePanel);
		extensions.DropDownItems.Add(battleAssistant);
		extensions.DropDownItems.Add(battlePresentation);
		ToolStripMenuItem lineup = new ToolStripMenuItem("阵容方案");
		lineup.Click += delegate { _childWindowCoordinator.Show("lineupPresets", () => new LineupPresetsForm(_lineupCoordinator)); };
		extensions.DropDownItems.Add(lineup);
		extensions.DropDownItems.Add(new ToolStripSeparator());
		extensions.DropDownItems.Add(BuildThemeMenu());
		return extensions;
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
		ToolStripDropDownButton extensions = BuildExtensionsButton();
		ToolStripButton refresh = new ToolStripButton("刷新");
		ToolStripButton packets = new ToolStripButton("抓包 / 发包");
		ToolStripButton devTools = new ToolStripButton("开发者工具");
		ToolStripButton retainLog = new ToolStripButton("保留日志");
		AddPlaybackOption("1×（25 FPS）", 25);
		AddPlaybackOption("2×（50 FPS）", 50);
		AddPlaybackOption("3×（75 FPS）", 75);
		AddQualityOption("高（游戏默认）", "high");
		AddQualityOption("最佳", "best");
		AddWindowSizeOption("1×", 1);
		AddWindowSizeOption("1.25×", 1.25);
		AddWindowSizeOption("1.5×", 1.5);
		AddWindowSizeOption("2×", 2);
		_windowSizeMenu.ToolTipText = "超过当前屏幕可用区域时等比缩小";
		refresh.Click += delegate { _browserSession.Refresh(BrowserRefreshMode.IgnoreCache); };
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
				_status.Text = "收发日志已保留：" + logPath + (discarded > 0
					? "（内存上限前已丢弃 " + discarded + " 条较早记录）"
					: string.Empty);
			}
			else
			{
				retainLog.Enabled = true;
				_status.Text = "收发日志保留失败：" + errorMessage;
				MessageBox.Show(this, errorMessage, "保留日志失败", MessageBoxButtons.OK, MessageBoxIcon.Error);
			}
		};
		toolbar.Items.AddRange(new ToolStripItem[]
		{
			extensions, refresh, packets, _playbackMenu, _qualityMenu, _windowSizeMenu, devTools, retainLog
		});
		return toolbar;
	}

	private void AddWindowSizeOption(string text, double scale)
	{
		ToolStripMenuItem item = new ToolStripMenuItem(text) { Tag = scale };
		item.Click += delegate { ApplyWindowScale(scale); };
		_windowSizeMenu.DropDownItems.Add(item);
	}

	private void ApplyWindowScale(double scale)
	{
		_windowScale = scale;
		WindowState = FormWindowState.Normal;
		Rectangle workingArea = Screen.FromControl(this).WorkingArea;
		double dpiScale = DeviceDpi / 96.0;
		int frameWidth = Width - ClientSize.Width;
		int frameHeight = Height - ClientSize.Height;
		double fittedScale = Math.Min(scale, Math.Min(
			(workingArea.Width - frameWidth) / (PageWidth * dpiScale),
			(workingArea.Height - frameHeight - _toolbar.Height) / (PageHeight * dpiScale)));
		ClientSize = new Size(
			(int)Math.Floor(PageWidth * fittedScale * dpiScale),
			(int)Math.Floor(PageHeight * fittedScale * dpiScale) + _toolbar.Height);
		Location = new Point(
			workingArea.Left + (workingArea.Width - Width) / 2,
			workingArea.Top + (workingArea.Height - Height) / 2);
		foreach (ToolStripMenuItem item in _windowSizeMenu.DropDownItems)
		{
			item.Checked = (double)item.Tag == scale;
		}
	}

	private void AddPlaybackOption(string text, int frameRate)
	{
		ToolStripMenuItem item = new ToolStripMenuItem(text);
		item.Click += delegate { ApplyPlaybackSettings(frameRate, string.Empty); };
		_playbackMenu.DropDownItems.Add(item);
	}

	private void AddQualityOption(string text, string quality)
	{
		ToolStripMenuItem item = new ToolStripMenuItem(text);
		item.Click += delegate { ApplyPlaybackSettings(0, quality); };
		_qualityMenu.DropDownItems.Add(item);
	}

	private async void ApplyPlaybackSettings(int frameRate, string quality)
	{
		_playbackMenu.Enabled = false;
		_qualityMenu.Enabled = false;
		try
		{
			PageBridgeResult result = await _pageBridge.InvokeAsync(
				new PageBridgeRequest(
					"playback.apply",
					new JObject
					{
						["frameRate"] = frameRate,
						["quality"] = quality
					},
					TimeSpan.FromSeconds(3)),
				CancellationToken.None);
			if (!result.Succeeded)
			{
				_status.Text = "Flash 播放设置失败：" + result.Message;
				return;
			}
			int appliedFrameRate = result.Value?.Value<int>("frameRate") ?? 0;
			string appliedQuality = result.Value?.Value<string>("quality") ?? string.Empty;
			_playbackMenu.Text = appliedFrameRate == 25 ? "速度 1×" :
				appliedFrameRate == 50 ? "速度 2×" :
				appliedFrameRate == 75 ? "速度 3×" : "速度 " + appliedFrameRate + " FPS";
			_qualityMenu.Text = string.Equals(appliedQuality, "best", StringComparison.OrdinalIgnoreCase)
				? "画质 最佳"
				: "画质 高";
			_status.Text = string.Format("Flash 播放设置已应用：{0} FPS，画质 {1}",
				appliedFrameRate, appliedQuality);
		}
		finally
		{
			_playbackMenu.Enabled = true;
			_qualityMenu.Enabled = true;
		}
	}

	private void ShowPackets()
	{
		_childWindowCoordinator.Show(
			"packets",
			() => new AolaPacketsForm(_packetEventSource, _commandSender, _pageBridge, _textSequenceRunner),
			activate: false);
	}

	private void ShowBattleAssistant()
	{
		_childWindowCoordinator.Show(
			"battleAssistant",
			() => new AolaBattleAssistantForm(_battleTracker));
	}

	private void ShowBattlePresentation()
	{
		_childWindowCoordinator.Show(
			"battlePresentation",
			() => new AolaBattleSettingsForm(_battlePresentationCoordinator));
	}

	private async void EnsureHookInjectedAsync()
	{
		if (_injectCheckInProgress || _isClosing)
		{
			return;
		}
		_injectCheckInProgress = true;
		try
		{
			int processId = await Task.Run(FindNetworkProcessId);
			if (_isClosing || IsDisposed)
			{
				return;
			}
			if (processId == 0)
			{
				_status.Text = "等待 CEF network.mojom 子进程";
				return;
			}
			string libraryPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "AolaSocketHack.dll");
			await Task.Run(() => _hookController.EnsureInjected(processId, libraryPath));
		}
		catch (Exception ex)
		{
			if (!_isClosing && !IsDisposed)
			{
				_status.Text = "检查抓包注入状态失败：" + ex.Message;
			}
		}
		finally
		{
			_injectCheckInProgress = false;
		}
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
			if (IsHandleCreated)
			{
				BeginInvoke(new Action(async delegate { await UpdateBrowserZoomAsync(); }));
			}
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
			BattleBridgeApplyResult battleResult = null;
			if (isAolaPlayPage && _petMorphCoordinator.IsLiveBridgeAvailable)
			{
				morphResult = await _petMorphCoordinator.PushCurrentRulesAsync(CancellationToken.None);
			}
			if (isAolaPlayPage)
			{
				battleResult = await _battlePresentationCoordinator.PushCurrentAsync(CancellationToken.None);
			}
			if (morphResult != null && morphResult.Superseded)
			{
				return;
			}
			BeginInvoke(new Action(delegate
			{
				_status.Text = battleResult != null && !battleResult.Submitted
					? "页面已加载，但战斗表现设置桥接失败：" + battleResult.Message
					: morphResult != null && !morphResult.Superseded && !morphResult.Injected
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

	private async void BrowserClientSizeChanged(object sender, EventArgs e)
	{
		await UpdateBrowserZoomAsync();
	}

	private async Task UpdateBrowserZoomAsync()
	{
		if (_isClosing || IsDisposed || !_browser.IsBrowserInitialized ||
			!_browser.CanExecuteJavascriptInMainFrame || WindowState == FormWindowState.Minimized)
		{
			return;
		}
		int revision = ++_browserZoomRevision;
		try
		{
			double currentZoom = await _browser.GetZoomLevelAsync();
			JavascriptResponse response;
			using (IFrame frame = _browser.GetMainFrame())
			{
				response = await frame.EvaluateScriptAsync(
					"JSON.stringify({width:window.innerWidth,height:window.innerHeight})");
			}
			if (!response.Success || _isClosing || IsDisposed || revision != _browserZoomRevision) return;
			// CSS 视口已反映 CEF 当前 DPI 和页面缩放；不假设它与 WinForms DeviceDpi 相同。
			JObject viewport = JObject.Parse((string)response.Result);
			double adjustment = Math.Min(
				viewport.Value<double>("width") / PageWidth,
				viewport.Value<double>("height") / PageHeight);
			_browser.GetBrowserHost().SetZoomLevel(currentZoom + Math.Log(adjustment, 1.2));
		}
		catch (Exception ex)
		{
			if (!_isClosing && !IsDisposed) _status.Text = "页面缩放失败：" + ex.Message;
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
