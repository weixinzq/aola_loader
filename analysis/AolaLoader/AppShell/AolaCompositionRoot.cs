// 架构角色：桌面宿主的唯一组合根，创建共享基础设施、功能协调器、UI，并按依赖逆序释放。
// 数据流：运行目录/设置/资源 -> Browser、Hook、PacketHost、Features -> AolaMainForm。
using System;
using System.IO;
using System.Windows.Forms;
using AolaLoader.AppShell.Adapters.PetMorph;
using AolaLoader.BrowserHost;
using AolaLoader.BrowserHost.Contracts;
using AolaLoader.Features.ActiveSend;
using AolaLoader.Features.Lineup;
using AolaLoader.Features.Battle.State;
using AolaLoader.Features.Battle.Bridge;
using AolaLoader.Features.Battle.Coordination;
using AolaLoader.Features.Battle.Diagnostics;
using AolaLoader.Features.Battle.Settings;
using AolaLoader.Features.PetMorph.Coordination;
using AolaLoader.Features.PetMorph.Settings;
using AolaLoader.Features.Theme.Coordination;
using AolaLoader.Features.Theme.Settings;
using AolaLoader.PacketHost;
using AolaLoader.PacketHost.Consumers;
using AolaLoader.ResourceInterception.Cef;
using AolaLoader.Settings;
using CefSharp;
using CefSharp.WinForms;

namespace AolaLoader.AppShell;

/// <summary>
/// The single composition point that constructs long-lived services, the browser
/// session and the main window, and releases them in reverse dependency order.
/// </summary>
internal sealed class AolaCompositionRoot : IDisposable
{
	private readonly AolaHookController _hookController;
	private readonly AolaHookHostAdapter _packetEventSource;
	private readonly AolaReceiveLogger _receiveLogger;
	private readonly AolaBattleStateTracker _battleTracker;
	private readonly AolaResourceRequestHandler _resourceRequestHandler;
	private readonly ThemeCoordinator _themeCoordinator;
	private readonly PetMorphCoordinator _petMorphCoordinator;
	private readonly BattlePresentationCoordinator _battlePresentationCoordinator;
	private readonly BattlePerformanceRecorder _battlePerformanceRecorder;
	private readonly ChromiumWebBrowser _browser;
	private readonly AolaBrowserSession _browserSession;
	private readonly IPageBridge _pageBridge;
	private readonly IAolaCommandSender _commandSender;
	private readonly AolaLoader.Features.Battle.Replay.AolaExecutionState _executionState;
	private readonly AolaTextSequenceRunner _textSequenceRunner;
	private readonly LineupCoordinator _lineupCoordinator;
	private readonly ChildWindowCoordinator _childWindowCoordinator;
	private bool _disposed;

	public AolaCompositionRoot()
	{
		// 所有运行资源都相对于 exe 目录定位，避免从不同工作目录启动时找错文件。
		string baseDirectory = AppDomain.CurrentDomain.BaseDirectory;
		// 设置仓库由多个功能共享，但每个功能只通过自己的 Codec 读写所属 Section。
		JsonSettingsSectionStore settingsStore = new JsonSettingsSectionStore(
			Path.Combine(baseDirectory, "settings.json"));
		PetMorphSettingsCodec petMorphCodec = new PetMorphSettingsCodec();
		// 资源请求处理器创建时就需要知道是否启用形态 live bridge，因此先读初始设置。
		PetMorphSettings initialPetMorph = settingsStore.Load(
			PetMorphSettingsCodec.SectionKey,
			petMorphCodec).Value;

		// 初始化进程级 CEF、缓存、日志和 PPAPI Flash；必须先于 ChromiumWebBrowser。
		AolaCefInitializer.Initialize();

		// 建立网络观察链：IPC Adapter 接收 Hook 消息，日志和战斗状态共同订阅它。
		_hookController = new AolaHookController();
		_packetEventSource = new AolaHookHostAdapter();
		_receiveLogger = new AolaReceiveLogger(_packetEventSource);
		_battleTracker = new AolaBattleStateTracker(_packetEventSource);
		// 唯一的 CEF 资源请求处理器集中注册主题、主动发送桥、战斗桥和形态规则。
		_resourceRequestHandler = new AolaResourceRequestHandler(
			Path.Combine(baseDirectory, "Resources", "Themes"), // 本地主题 SWF 目录
			Path.Combine(baseDirectory, "Resources", "Data", "pet-poster-catalog.json"), // 海报资源目录表
			Path.Combine(baseDirectory, "Resources", "Patches", "start-bridge-2107300001.fws.swf"), // 主动发送桥
			Path.Combine(baseDirectory, "Resources", "Patches", "petfightnew-battle-state.current.json"), // 战斗桥清单
			Path.Combine(baseDirectory, "Resources", "Battle", "background.jpg"), // 自定义战斗背景 JPEG
			Path.Combine(baseDirectory, "Resources", "Data", "battle-pet-movie-versions.current.json"), // 战斗模型版本表
			Path.Combine(baseDirectory, "Resources", "Patches", "newpetpackage-morph-20260919895706432-visual-v3.fws.swf"), // 形态 live bridge
			initialPetMorph.LiveBridgeEnabled); // 是否启用形态 live bridge
		// CEF 已在上面全局初始化；这里创建真正显示网页的 WinForms 浏览器控件。
		_browser = new ChromiumWebBrowser(AolaMainForm.DefaultUrl)
		{
			Dock = DockStyle.Fill, // 加入主窗口后自动填满父容器
			RequestHandler = _resourceRequestHandler // 让 SWF/资源请求经过项目规则管线
		};
		// PetMorph 同时使用设置、资源规则和页面 main frame；lambda 每次取当前 frame。
		_petMorphCoordinator = new PetMorphCoordinator(
			settingsStore,
			petMorphCodec,
			_resourceRequestHandler,
			new AolaBrowserPetMorphPushBridge(
				() => _browser.GetMainFrame(),
				new AolaPetMorphLiveBridge()));
		// BrowserSession 封装具体 CefSharp 控件；PageBridge 在其上提供受控页面调用。
		_browserSession = new AolaBrowserSession(_browser);
		_pageBridge = new AolaPageBridge(_browserSession);
		// 主题协调器通过页面桥请求 Flash 完成切换，初始官方皮肤不拦截。
		_themeCoordinator = new ThemeCoordinator(settingsStore, new ThemeSettingsCodec(),
			_resourceRequestHandler, pushBridge: _resourceRequestHandler.ThemeLiveEnabled ? new ThemeBridgeClient(_pageBridge) : null);
		// 把 packet 战斗快照与 Flash 页面诊断数据记录到性能日志。
		_battlePerformanceRecorder = new BattlePerformanceRecorder(
			_battleTracker,
			new BattleDiagnosticsClient(_pageBridge),
			Path.Combine(baseDirectory, "logs", "performance"));
		// 保存并应用战斗表现设置，同时协调战斗模型资源规则。
		_battlePresentationCoordinator = new BattlePresentationCoordinator(
			settingsStore,
			new BattleSettingsCodec(),
			new BattleBridgeClient(_pageBridge),
			_resourceRequestHandler);
		// 生产主动发送只通过 PageBridge 复用当前 Flash 原连接。
		_commandSender = new AolaFlashCommandSender(_pageBridge);
		_executionState = new AolaLoader.Features.Battle.Replay.AolaExecutionState(_packetEventSource);
		_textSequenceRunner = new AolaTextSequenceRunner(_packetEventSource, _executionState, _commandSender, new BattleBridgeClient(_pageBridge));
		// 阵容功能需要发送、匹配收发 packet，并在活动战斗中拒绝操作。
		_lineupCoordinator = new LineupCoordinator(_packetEventSource, _commandSender, _battleTracker);
		// 统一复用和释放抓包、战斗、形态、阵容等子窗口。
		_childWindowCoordinator = new ChildWindowCoordinator();

		// 最后创建主窗体：此时它需要的所有长期依赖都已准备完成。
		// 参数声明为接口时，实际传入的仍是上面创建的具体实现对象。
		MainForm = new AolaMainForm(
			_browser, // 可视化 CEF 浏览器控件
			_browserSession, // 浏览器生命周期和脚本执行接口
			_hookController, // network.mojom Hook 注入控制器
			_packetEventSource, // Hook IPC 收发消息的宿主事件源
			_commandSender, // 经 Flash 原连接主动发送命令
			_pageBridge, // 页面 JavaScript / ExternalInterface 桥
			_receiveLogger, // 按需保留收发 JSONL 日志
			_battleTracker, // packet 派生的 BattleSnapshot 状态源
			_themeCoordinator, // 主题应用和持久化
			_petMorphCoordinator, // 背包/海报形态规则
			_battlePresentationCoordinator, // 战斗表现和模型规则
			_childWindowCoordinator, // 子窗口复用及生命周期
			_lineupCoordinator,
			_textSequenceRunner); // 统一文本序列执行
	}

	public AolaMainForm MainForm { get; }

	public void Dispose()
	{
		if (_disposed)
		{
			return;
		}
		_disposed = true;
		// 按依赖关系从上层消费者向下层基础设施释放，最后停止 Hook 控制器。
		_battlePerformanceRecorder.Dispose();
		_childWindowCoordinator.Dispose();
		_executionState.Dispose();
		_pageBridge.Dispose();
		_browserSession.Dispose();
		_browser.Dispose();
		_packetEventSource.Dispose();
		_receiveLogger.Dispose();
		_battleTracker.Dispose();
		_hookController.Dispose();
	}
}
