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
	try {
		if (operation === 'activeSend.submit') {
			var requestId = String(args.requestId || '');
			if (!/^[a-f0-9]{32}$/.test(requestId) ||
				typeof args.extension !== 'string' || !args.extension ||
				typeof args.command !== 'string' || !args.command ||
				typeof args.parametersJson !== 'string') {
				return envelope(false, null, 'InvocationFailed', 'Invalid active-send arguments.');
			}
			var flash = findFlash('aolaSendCommand');
			if (!flash) return envelope(false, null, 'BridgeNotInstalled', 'Flash 发包桥尚未加载；请先打开精灵背包。');
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
			if (!panelFlash) return envelope(false, null, 'BridgeNotInstalled', 'Flash 面板桥尚未加载；请先打开精灵背包。');
			var panelResult = String(panelFlash.aolaOpenPanel(args.resourceUrl, args.resourceClass) || '');
			if (panelResult !== 'PanelOpenRequested') {
				return envelope(false, null, 'InvocationFailed', panelResult || 'Flash rejected the panel request.');
			}
			return envelope(true, { status: panelResult }, '', '');
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
