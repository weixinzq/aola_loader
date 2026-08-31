using System;
using System.IO;
using System.Windows.Forms;
using AolaLoader.AppShell.Adapters.PetMorph;
using AolaLoader.BrowserHost;
using AolaLoader.BrowserHost.Contracts;
using AolaLoader.Features.ActiveSend;
using AolaLoader.Features.Battle.State;
using AolaLoader.Features.Battle.Bridge;
using AolaLoader.Features.Battle.Coordination;
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
	private readonly ChromiumWebBrowser _browser;
	private readonly AolaBrowserSession _browserSession;
	private readonly IPageBridge _pageBridge;
	private readonly IAolaCommandSender _commandSender;
	private readonly ChildWindowCoordinator _childWindowCoordinator;
	private bool _disposed;

	public AolaCompositionRoot()
	{
		string baseDirectory = AppDomain.CurrentDomain.BaseDirectory;
		JsonSettingsSectionStore settingsStore = new JsonSettingsSectionStore(
			Path.Combine(baseDirectory, "settings.json"));
		PetMorphSettingsCodec petMorphCodec = new PetMorphSettingsCodec();
		PetMorphSettings initialPetMorph = settingsStore.Load(
			PetMorphSettingsCodec.SectionKey,
			petMorphCodec).Value;

		AolaCefInitializer.Initialize();

		_hookController = new AolaHookController();
		_packetEventSource = new AolaHookHostAdapter();
		_receiveLogger = new AolaReceiveLogger(_packetEventSource);
		_battleTracker = new AolaBattleStateTracker(_packetEventSource);
		_resourceRequestHandler = new AolaResourceRequestHandler(
			Path.Combine(baseDirectory, "Resources", "Themes"),
			Path.Combine(baseDirectory, "Resources", "Data", "pet-poster-catalog.json"),
			Path.Combine(baseDirectory, "Resources", "Patches", "start-bridge-2107300001.fws.swf"),
			null,
			Path.Combine(baseDirectory, "Resources", "Patches", "newpetpackage-morph-2026082731219998.fws.swf"),
			initialPetMorph.LiveBridgeEnabled);
		_themeCoordinator = new ThemeCoordinator(
			settingsStore,
			new ThemeSettingsCodec(),
			_resourceRequestHandler);
		_browser = new ChromiumWebBrowser(AolaMainForm.DefaultUrl)
		{
			Dock = DockStyle.Fill,
			RequestHandler = _resourceRequestHandler
		};
		_petMorphCoordinator = new PetMorphCoordinator(
			settingsStore,
			petMorphCodec,
			_resourceRequestHandler,
			new AolaBrowserPetMorphPushBridge(
				() => _browser.GetMainFrame(),
				new AolaPetMorphLiveBridge()));
		_browserSession = new AolaBrowserSession(_browser);
		_pageBridge = new AolaPageBridge(_browserSession);
		_battlePresentationCoordinator = new BattlePresentationCoordinator(
			settingsStore,
			new BattleSettingsCodec(),
			new BattleBridgeClient(_pageBridge));
		_commandSender = new AolaFlashCommandSender(_pageBridge);
		_childWindowCoordinator = new ChildWindowCoordinator();
		MainForm = new AolaMainForm(
			_browser,
			_browserSession,
			_hookController,
			_packetEventSource,
			_commandSender,
			_pageBridge,
			_receiveLogger,
			_battleTracker,
			_themeCoordinator,
			_petMorphCoordinator,
			_battlePresentationCoordinator,
			_childWindowCoordinator);
	}

	public AolaMainForm MainForm { get; }

	public void Dispose()
	{
		if (_disposed)
		{
			return;
		}
		_disposed = true;
		_childWindowCoordinator.Dispose();
		_pageBridge.Dispose();
		_browserSession.Dispose();
		_browser.Dispose();
		_packetEventSource.Dispose();
		_receiveLogger.Dispose();
		_battleTracker.Dispose();
		_hookController.Dispose();
	}
}
