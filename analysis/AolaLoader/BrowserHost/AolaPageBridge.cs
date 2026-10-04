// 架构角色：宿主到页面/Flash 的白名单控制边界，把类型化操作翻译为受限 JavaScript 调用。
// 数据流：PageBridgeRequest/功能状态 -> IBrowserSession -> envelope 校验后的 PageBridgeResult。
using System;
using System.Threading;
using System.Threading.Tasks;
using AolaLoader.BrowserHost.Contracts;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace AolaLoader.BrowserHost;

internal sealed class AolaPageBridge : IPageBridge
{
	private readonly object _syncRoot = new object();
	private readonly IBrowserSession _browserSession;
	private PageBridgeAvailability _availability = PageBridgeAvailability.Unknown;
	private bool _disposed;

	public AolaPageBridge(IBrowserSession browserSession)
	{
		_browserSession = browserSession ?? throw new ArgumentNullException(nameof(browserSession));
		_browserSession.PageLifecycleChanged += OnPageLifecycleChanged;
	}

	public PageBridgeAvailability Availability
	{
		get
		{
			lock (_syncRoot)
			{
				return _disposed ? PageBridgeAvailability.Closed : _availability;
			}
		}
	}

	public Task<PageBridgeResult> InvokeAsync(
		PageBridgeRequest request,
		CancellationToken cancellationToken)
	{
		if (request == null)
		{
			throw new ArgumentNullException(nameof(request));
		}
		return ExecuteAsync(request.Operation, request.Arguments, request.Timeout, cancellationToken);
	}

	public Task<PageBridgeResult> PushFeatureStateAsync(
		PageFeatureStatePush state,
		CancellationToken cancellationToken)
	{
		if (state == null)
		{
			throw new ArgumentNullException(nameof(state));
		}
		JObject arguments = new JObject
		{
			["feature"] = state.FeatureName,
			["revision"] = state.Revision,
			["state"] = state.State
		};
		return ExecuteAsync("feature.push", arguments, state.Timeout, cancellationToken);
	}

	public void Dispose()
	{
		lock (_syncRoot)
		{
			if (_disposed)
			{
				return;
			}
			_disposed = true;
			_availability = PageBridgeAvailability.Closed;
		}
		_browserSession.PageLifecycleChanged -= OnPageLifecycleChanged;
	}

	internal static string BuildInvocationScript(string operation, JObject arguments)
	{
		string operationJson = JsonConvert.SerializeObject(operation);
		string argumentsJson = (arguments ?? new JObject()).ToString(Formatting.None);
		return @"(function (operation, args) {
	function envelope(ok, value, failure, message) {
		return JSON.stringify({ ok: !!ok, value: value || null, failure: failure || '', message: message || '' });
	}
	var state = window.__aolaCommandBridgeState;
	if (!state || typeof state !== 'object') {
		state = { results: Object.create(null), featureState: Object.create(null) };
		window.__aolaCommandBridgeState = state;
	}
	if (!state.results || typeof state.results !== 'object') state.results = Object.create(null);
	if (!state.featureState || typeof state.featureState !== 'object') state.featureState = Object.create(null);
	if (!state.battle || typeof state.battle !== 'object') {
		state.battle = { options: null, revision: -1, appliedRevision: -1, timer: 0 };
	}
	window.aolaCommandCompleted = function (requestId, status, code) {
		requestId = String(requestId || '');
		status = String(status || '');
		if (!Object.prototype.hasOwnProperty.call(state.results, requestId)) return false;
		if (status !== 'ServerSucceeded' && status !== 'ServerRejected') return false;
		state.results[requestId] = { status: status, code: String(code || '') };
		return true;
	};
	function findFlash(methodName) {
		var candidates = [];
		var primary = document.getElementById('swfContainer');
		if (primary) candidates.push(primary);
		var nodes = document.querySelectorAll('object,embed');
		for (var i = 0; i < nodes.length; i++) {
			if (candidates.indexOf(nodes[i]) < 0) candidates.push(nodes[i]);
		}
		for (var j = 0; j < candidates.length; j++) {
			try {
				if (typeof candidates[j][methodName] === 'function') return candidates[j];
			} catch (ignored) {}
		}
		return null;
	}
	function applyBattleOptions() {
		if (!state.battle.options) return false;
		var battleFlash = findFlash('aolaBattleApplyOptions');
		if (!battleFlash) {
			state.battle.appliedRevision = -1;
			return false;
		}
		if (state.battle.appliedRevision === state.battle.revision) return true;
		var result = String(battleFlash.aolaBattleApplyOptions(JSON.stringify(state.battle.options)) || '');
		if (result === 'BattleOptionsApplied|' + String(state.battle.revision)) {
			state.battle.appliedRevision = state.battle.revision;
			return true;
		}
		state.battle.lastError = result || 'Flash rejected battle options.';
		return false;
	}
	function ensureBattlePump() {
		if (state.battle.timer) return;
		state.battle.timer = window.setInterval(function () {
			try { applyBattleOptions(); } catch (ignored) {}
		}, 100);
	}
	function validDiagnosticNumber(value) {
		return typeof value === 'number' && isFinite(value) && Math.floor(value) === value && value >= -1;
	}
	try {
		if (operation === 'theme.apply') {
			var themeId = Number(args.themeId), themeRequest = Number(args.requestId);
			if (!Number.isInteger(themeId) || themeId < 0 || themeId > 9 || !Number.isInteger(themeRequest) || themeRequest < 0)
				return envelope(false, null, 'InvocationFailed', 'Invalid theme request.');
			if (!state.theme || state.theme.requestId !== themeRequest) state.theme = { requestId: themeRequest, value: null };
			window.aolaThemeCompleted = function (id, json) {
				if (Number(id) !== state.theme.requestId) return false;
				var value = JSON.parse(String(json));
				if (value.requestId !== state.theme.requestId || value.themeId !== themeId) return false;
				state.theme.value = value;
				return true;
			};
			if (state.theme.value && (state.theme.value.status === 'Applied' || state.theme.value.status === 'Failed'))
				return envelope(true, state.theme.value, '', '');
			var themeFlash = findFlash('aolaThemeApply');
			if (!themeFlash) return envelope(true, {status:'NotReady',requestId:themeRequest,themeId:themeId}, '', '');
			var themeValue = JSON.parse(String(themeFlash.aolaThemeApply(themeId, themeRequest)));
			state.theme.value = themeValue;
			return envelope(true, themeValue, '', '');
		}
		if (operation === 'activeSend.submit') {
			var requestId = String(args.requestId || '');
			if (!/^[a-f0-9]{32}$/.test(requestId) ||
				typeof args.extension !== 'string' || !args.extension ||
				typeof args.command !== 'string' || !args.command ||
				typeof args.parametersJson !== 'string') {
				return envelope(false, null, 'InvocationFailed', 'Invalid active-send arguments.');
			}
			var flash = findFlash('aolaSendCommand');
			if (!flash) return envelope(false, null, 'BridgeNotInstalled', '游戏桥尚未就绪，请等待游戏加载完成。');
			state.results[requestId] = { status: 'SubmittedToFlash', code: '' };
			var submitted = flash.aolaSendCommand(
				requestId, args.extension, args.command, args.parametersJson);
			if (String(submitted || '') !== 'SubmittedToFlash') {
				delete state.results[requestId];
				return envelope(false, null, 'InvocationFailed', String(submitted || 'Flash rejected the request.'));
			}
			var submitResult = state.results[requestId];
			delete state.results[requestId];
			return envelope(true, submitResult, '', '');
		}
		if (operation === 'panel.open') {
			if (typeof args.resourceUrl !== 'string' || !args.resourceUrl || args.resourceUrl.length > 2048 ||
				typeof args.resourceClass !== 'string' || !args.resourceClass || args.resourceClass.length > 2048) {
				return envelope(false, null, 'InvocationFailed', 'Invalid panel arguments.');
			}
			var panelFlash = findFlash('aolaOpenPanel');
			if (!panelFlash) return envelope(false, null, 'BridgeNotInstalled', '游戏桥尚未就绪，请等待游戏加载完成。');
			var panelResult = String(panelFlash.aolaOpenPanel(args.resourceUrl, args.resourceClass) || '');
			if (panelResult !== 'PanelOpenRequested') {
				return envelope(false, null, 'InvocationFailed', panelResult || 'Flash rejected the panel request.');
			}
			return envelope(true, { status: panelResult }, '', '');
		}
		if (operation === 'playback.apply') {
			var frameRate = Math.floor(Number(args.frameRate) || 0);
			var quality = String(args.quality || '').toLowerCase();
			if ([0, 25, 50, 75].indexOf(frameRate) < 0 ||
				['', 'high', 'best'].indexOf(quality) < 0 ||
				(frameRate === 0 && quality === '')) {
				return envelope(false, null, 'InvocationFailed', 'Invalid playback arguments.');
			}
			var playbackFlash = findFlash('aolaSetPlayback');
			if (!playbackFlash) return envelope(false, null, 'BridgeNotInstalled', '游戏桥尚未就绪，请等待游戏加载完成。');
			var playbackResult = String(playbackFlash.aolaSetPlayback(frameRate, quality) || '');
			var playbackParts = playbackResult.split('|');
			if (playbackParts.length !== 3 || playbackParts[0] !== 'PlaybackApplied') {
				return envelope(false, null, 'InvocationFailed', playbackResult || 'Flash rejected playback settings.');
			}
			return envelope(true, {
				status: playbackParts[0],
				frameRate: Math.floor(Number(playbackParts[1]) || 0),
				quality: String(playbackParts[2] || '')
			}, '', '');
		}
		if (operation === 'battle.apply') {
			var optionKeys = ['version', 'revision', 'hideDamageNumbers', 'hideHealingNumbers',
				'skipBattlePresentation'];
			var actualKeys = Object.keys(args).sort();
			var expectedKeys = optionKeys.slice(0).sort();
			if (actualKeys.length !== expectedKeys.length ||
				actualKeys.some(function (key, index) { return key !== expectedKeys[index]; }) ||
				typeof args.version !== 'number' || args.version !== 5 ||
				typeof args.revision !== 'number' || Math.floor(args.revision) !== args.revision || args.revision < 0 ||
				typeof args.hideDamageNumbers !== 'boolean' || typeof args.hideHealingNumbers !== 'boolean' ||
				typeof args.skipBattlePresentation !== 'boolean') {
				return envelope(false, null, 'InvocationFailed', 'Invalid battle options.');
			}
			state.battle.options = {
				version: 5,
				revision: Number(args.revision),
				hideDamageNumbers: args.hideDamageNumbers,
				hideHealingNumbers: args.hideHealingNumbers,
				skipBattlePresentation: args.skipBattlePresentation
			};
			state.battle.revision = Number(args.revision);
			state.battle.appliedRevision = -1;
			ensureBattlePump();
			var applied = applyBattleOptions();
			return envelope(true, {
				status: applied ? 'BattleOptionsApplied' : 'BattleOptionsPending',
				revision: state.battle.revision,
				message: applied ? '' : String(state.battle.lastError || '战斗模块尚未加载，进入战斗后自动应用。')
			}, '', '');
		}
		if (operation === 'battle.auto') {
			if (typeof args.enabled !== 'boolean') return envelope(false, null, 'InvocationFailed', 'enabled must be boolean.');
			var autoFlash = findFlash('aolaBattleSetAuto');
			if (!autoFlash) return envelope(false, null, 'BridgeNotInstalled', '自动战斗桥尚未就绪。');
			var autoResult = JSON.parse(String(autoFlash.aolaBattleSetAuto(JSON.stringify(args)) || ''));
			if (!autoResult || autoResult.status !== 'SubmittedToFlash') return envelope(false, null, 'InvocationFailed', (autoResult && autoResult.message) || 'Flash 未接受自动战斗设置。');
			return envelope(true, autoResult, '', '');
		}
		if (operation === 'battle.state') {
			var stateFlash = findFlash('aolaBattleGetState');
			if (!stateFlash) return envelope(false, null, 'BridgeNotInstalled', '战斗桥尚未就绪。');
			var rawState = String(stateFlash.aolaBattleGetState() || '');
			var battleState = JSON.parse(rawState);
			var stateKeys = ['version', 'active', 'battleId', 'turn', 'inputReady', 'readyEpoch', 'ended'];
			var returnedKeys = Object.keys(battleState || {}).sort();
			var requiredStateKeys = stateKeys.slice(0).sort();
			if (!battleState || returnedKeys.length !== requiredStateKeys.length ||
				returnedKeys.some(function (key, index) { return key !== requiredStateKeys[index]; }) ||
				Number(battleState.version) !== 5 || typeof battleState.active !== 'boolean' ||
				typeof battleState.inputReady !== 'boolean' || typeof battleState.ended !== 'boolean' ||
				typeof battleState.battleId !== 'number' || Math.floor(battleState.battleId) !== battleState.battleId ||
				battleState.battleId < -2147483648 || battleState.battleId > 2147483647 ||
				typeof battleState.turn !== 'number' || Math.floor(battleState.turn) !== battleState.turn || battleState.turn < 0 ||
				typeof battleState.readyEpoch !== 'number' || Math.floor(battleState.readyEpoch) !== battleState.readyEpoch || battleState.readyEpoch < 0) {
				return envelope(false, null, 'InvocationFailed', 'Flash returned an invalid battle state.');
			}
			return envelope(true, battleState, '', '');
		}
		if (operation === 'battle.diagnostics') {
			var diagnosticsFlash = findFlash('aolaBattleGetDiagnostics');
			if (!diagnosticsFlash) return envelope(false, null, 'BridgeNotInstalled', '战斗诊断桥尚未就绪。');
			var rawDiagnostics = String(diagnosticsFlash.aolaBattleGetDiagnostics() || '');
			var diagnostics = JSON.parse(rawDiagnostics);
			var diagnosticsKeys = ['version', 'flashUptimeMs', 'totalMemory', 'privateMemory', 'freeMemory',
				'liveFightPanels', 'disposedFightPanels', 'panelCreatedCount',
				'panelDisposeStartedCount', 'panelDisposedCount',
				'liveStartMovies', 'disposedStartMovies', 'startMovieCreatedCount', 'startMovieDisposedCount',
				'liveApplicationDomains', 'releasedApplicationDomains',
				'applicationDomainCreatedCount', 'applicationDomainReleasedCount',
				'livePreloadSessions', 'activePreloadSessions', 'disposedPreloadSessions',
				'preloadInFlightCount', 'preloadPendingCount', 'preloadStartedCount',
				'preloadCompletedCount', 'preloadDisposedWhileLoadingCount', 'currentResourceAgeMs',
				'liveSkillEffectLoaders', 'skillEffectRequestInFlightCount',
				'skillEffectRequestStartedCount', 'skillEffectRequestCompletedCount',
				'skillEffectDisposedWhileLoadingCount', 'skillEffectCallbackAfterDisposeCount',
				'activeAttackCount', 'oldestAttackAgeMs', 'attackMissingStrategyCount',
				'attackWatchdogTimeoutCount', 'attackRecoveryErrorCount',
				'traceDroppedCount', 'stageChildren', 'panelChildren',
				'frameWindowMs', 'frameSampleCount', 'longFrame50Count', 'longFrame100Count',
				'longFrame200Count', 'maxFrameGapMs'];
			if (!diagnostics || Number(diagnostics.version) !== 4 ||
				typeof diagnostics.conservativeCleanupEnabled !== 'boolean' ||
				diagnosticsKeys.slice(1).some(function (key) {
					return !Object.prototype.hasOwnProperty.call(diagnostics, key) ||
						!validDiagnosticNumber(diagnostics[key]);
				}) || typeof diagnostics.stageFrameRate !== 'number' ||
				!isFinite(diagnostics.stageFrameRate) || diagnostics.stageFrameRate < -1) {
				return envelope(false, null, 'InvocationFailed', 'Flash returned invalid battle diagnostics.');
			}
			return envelope(true, diagnostics, '', '');
		}
		if (operation === 'battle.diagnostics.events') {
			var traceFlash = findFlash('aolaBattleDrainTraceEvents');
			if (!traceFlash) return envelope(false, null, 'BridgeNotInstalled', '战斗资源事件桥尚未就绪。');
			var rawTrace = String(traceFlash.aolaBattleDrainTraceEvents() || '');
			var trace = JSON.parse(rawTrace);
			if (!trace || Number(trace.version) !== 1 || !validDiagnosticNumber(trace.droppedEventCount) ||
				!Array.isArray(trace.events) || trace.events.length > 512 || trace.events.some(function (item) {
					return !item || !validDiagnosticNumber(item.sequence) || item.sequence < 0 ||
						!validDiagnosticNumber(item.atMs) || item.atMs < 0 ||
						typeof item.type !== 'string' || !item.type || item.type.length > 64 ||
						typeof item.resource !== 'string' || item.resource.length > 512 ||
						!validDiagnosticNumber(item.durationMs) || !validDiagnosticNumber(item.value);
				})) {
				return envelope(false, null, 'InvocationFailed', 'Flash returned invalid battle resource events.');
			}
			return envelope(true, trace, '', '');
		}
		if (operation === 'feature.push') {
			var feature = String(args.feature || '');
			var revision = Math.floor(Number(args.revision) || 0);
			var previous = state.featureState[feature];
			if (!previous || Number(previous.revision) <= revision) {
				state.featureState[feature] = { revision: revision, state: args.state || {} };
			}
			return envelope(true, { revision: Number(state.featureState[feature].revision) || 0 }, '', '');
		}
		return envelope(false, null, 'InvocationFailed', 'Unsupported page bridge operation.');
	} catch (error) {
		return envelope(false, null, 'InvocationFailed', String(error && error.message || error));
	}
})(" + operationJson + "," + argumentsJson + ")";
	}

	private async Task<PageBridgeResult> ExecuteAsync(
		string operation,
		JObject arguments,
		TimeSpan timeout,
		CancellationToken cancellationToken)
	{
		PageBridgeAvailability availability;
		lock (_syncRoot)
		{
			availability = _disposed ? PageBridgeAvailability.Closed : _availability;
		}
		if (availability == PageBridgeAvailability.Closed)
		{
			return PageBridgeResult.Failure(PageBridgeFailureKind.BrowserClosed, "浏览器已关闭。");
		}
		if (availability == PageBridgeAvailability.Unknown || availability == PageBridgeAvailability.PageNotReady)
		{
			return PageBridgeResult.Failure(PageBridgeFailureKind.PageNotReady, "页面主框架尚未就绪。");
		}

		BrowserScriptResult scriptResult = await _browserSession.ExecuteScriptAsync(
			new BrowserScriptRequest(operation, BuildInvocationScript(operation, arguments), timeout),
			cancellationToken).ConfigureAwait(false);
		if (!scriptResult.Succeeded)
		{
			return PageBridgeResult.Failure(MapFailure(scriptResult.FailureKind), scriptResult.Message);
		}

		try
		{
			string json = scriptResult.Value?.Type == JTokenType.String
				? scriptResult.Value.Value<string>()
				: scriptResult.Value?.ToString(Formatting.None);
			JObject envelope = JObject.Parse(json ?? string.Empty);
			if (envelope.Value<bool>("ok"))
			{
				SetAvailability(PageBridgeAvailability.Ready);
				return PageBridgeResult.Success(envelope["value"]);
			}
			PageBridgeFailureKind failure = ParseFailure(envelope.Value<string>("failure"));
			if (failure == PageBridgeFailureKind.BridgeNotInstalled)
			{
				SetAvailability(PageBridgeAvailability.BridgeNotInstalled);
			}
			return PageBridgeResult.Failure(failure, envelope.Value<string>("message"));
		}
		catch (Exception ex) when (ex is JsonException || ex is InvalidOperationException)
		{
			return PageBridgeResult.Failure(PageBridgeFailureKind.InvocationFailed, ex.Message);
		}
	}

	private void OnPageLifecycleChanged(BrowserPageLifecycleEvent value)
	{
		switch (value.Kind)
		{
			case BrowserPageLifecycleKind.MainFrameReady:
				SetAvailability(PageBridgeAvailability.Ready);
				break;
			case BrowserPageLifecycleKind.Closed:
				SetAvailability(PageBridgeAvailability.Closed);
				break;
			default:
				SetAvailability(PageBridgeAvailability.PageNotReady);
				break;
		}
	}

	private void SetAvailability(PageBridgeAvailability availability)
	{
		lock (_syncRoot)
		{
			if (!_disposed)
			{
				_availability = availability;
			}
		}
	}

	private static PageBridgeFailureKind MapFailure(BrowserScriptFailureKind failure)
	{
		switch (failure)
		{
			case BrowserScriptFailureKind.PageNotReady:
				return PageBridgeFailureKind.PageNotReady;
			case BrowserScriptFailureKind.BrowserClosed:
				return PageBridgeFailureKind.BrowserClosed;
			case BrowserScriptFailureKind.Timeout:
				return PageBridgeFailureKind.Timeout;
			case BrowserScriptFailureKind.Cancelled:
				return PageBridgeFailureKind.Cancelled;
			default:
				return PageBridgeFailureKind.InvocationFailed;
		}
	}

	private static PageBridgeFailureKind ParseFailure(string value)
	{
		return string.Equals(value, "BridgeNotInstalled", StringComparison.Ordinal)
			? PageBridgeFailureKind.BridgeNotInstalled
			: PageBridgeFailureKind.InvocationFailed;
	}
}
