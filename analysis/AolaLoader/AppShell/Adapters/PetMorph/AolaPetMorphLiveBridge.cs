// 架构角色：封装 newpetpackage 形态桥的脚本协议，校验页面返回值并归一化失败原因。
// 数据流：主 Frame + 形态规则 JSON -> JavaScript/ExternalInterface -> AolaPetMorphPushResult。
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Threading;
using System.Threading.Tasks;
using CefSharp;
using AolaLoader.Features.PetMorph.Coordination;
using Newtonsoft.Json;

namespace AolaLoader.AppShell.Adapters.PetMorph;

internal sealed class AolaPetMorphLiveBridge
{
	private long _revision;

	public async Task<AolaPetMorphPushResult> PushAsync(
		IFrame frame,
		IReadOnlyDictionary<int, int> skinMappings,
		IReadOnlyDictionary<int, bool> hiddenBackgrounds,
		IReadOnlyDictionary<int, int> iconMappings,
		bool enabled)
	{
		if (frame == null || !frame.IsValid)
		{
			return AolaPetMorphPushResult.NotInjected("浏览器主框架尚未就绪。");
		}

		long revision = Interlocked.Increment(ref _revision);
		string skinMappingJson = JsonConvert.SerializeObject(
			skinMappings ?? (IReadOnlyDictionary<int, int>)new Dictionary<int, int>());
		string hiddenBackgroundJson = JsonConvert.SerializeObject(
			hiddenBackgrounds ?? (IReadOnlyDictionary<int, bool>)new Dictionary<int, bool>());
		string iconMappingJson = JsonConvert.SerializeObject(
			iconMappings ?? (IReadOnlyDictionary<int, int>)new Dictionary<int, int>());
		string enabledJson = enabled ? "true" : "false";
		string script = @"(function (skinMapping, hiddenBackgrounds, iconMapping, enabled, revision) {
	var state = window.__aolaMorphState || {};
	if ((Number(state.revision) || 0) > revision) return state.bridgeReady ? 2 : 0;
	state.skinMapping = skinMapping || {};
	state.hiddenBackgrounds = hiddenBackgrounds || {};
	state.iconMapping = iconMapping || {};
	state.enabled = !!enabled;
	state.revision = revision;
	state.bridgeReady = !!state.bridgeReady;
	window.__aolaMorphState = state;
	window.aolaMorphResolveSkinId = function (skinId) {
		var current = window.__aolaMorphState || {};
		var key = String(Math.floor(Number(skinId) || 0));
		if (!current.enabled || !Object.prototype.hasOwnProperty.call(current.skinMapping || {}, key)) {
			return Number(skinId) || 0;
		}
		return Number(current.skinMapping[key]) || Number(skinId) || 0;
	};
	window.aolaMorphShouldHideBackground = function (viewId) {
		var current = window.__aolaMorphState || {};
		var key = String(Math.floor(Number(viewId) || 0));
		return !!current.enabled &&
			Object.prototype.hasOwnProperty.call(current.hiddenBackgrounds || {}, key) &&
			current.hiddenBackgrounds[key] === true;
	};
	window.aolaMorphResolveIconId = function (viewId) {
		var current = window.__aolaMorphState || {};
		var key = String(Math.floor(Number(viewId) || 0));
		if (!current.enabled || !Object.prototype.hasOwnProperty.call(current.iconMapping || {}, key)) {
			return Number(viewId) || 0;
		}
		return Number(current.iconMapping[key]) || Number(viewId) || 0;
	};
	window.aolaMorphGetRevision = function () {
		return Number((window.__aolaMorphState || {}).revision) || 0;
	};
	window.aolaMorphBridgeReady = function (moduleVersion) {
		var current = window.__aolaMorphState || {};
		current.bridgeReady = true;
		current.moduleVersion = String(moduleVersion || '');
		window.__aolaMorphState = current;
		return Number(current.revision) || 0;
	};
	var invokeRefresh = function () {
		var candidates = [];
		var primary = document.getElementById('swfContainer');
		if (primary) candidates.push(primary);
		var nodes = document.querySelectorAll('object,embed');
		for (var i = 0; i < nodes.length; i++) {
			if (candidates.indexOf(nodes[i]) < 0) candidates.push(nodes[i]);
		}
		for (var j = 0; j < candidates.length; j++) {
			try {
				if (typeof candidates[j].aolaMorphRefresh === 'function' &&
					candidates[j].aolaMorphRefresh(revision) !== false) return true;
			} catch (ignored) {}
		}
		return false;
	};
	var called = invokeRefresh();
	if (window.__aolaMorphRetryTimer) window.clearInterval(window.__aolaMorphRetryTimer);
	if (!called) {
		var attempts = 0;
		window.__aolaMorphRetryTimer = window.setInterval(function () {
			if (invokeRefresh() || ++attempts >= 16) {
				window.clearInterval(window.__aolaMorphRetryTimer);
				window.__aolaMorphRetryTimer = 0;
			}
		}, 250);
	}
	return state.bridgeReady ? 2 : (called ? 1 : 0);
})(" + skinMappingJson + "," + hiddenBackgroundJson + "," + iconMappingJson + "," + enabledJson + "," +
			revision.ToString(CultureInfo.InvariantCulture) + ")";

		try
		{
			JavascriptResponse response = await frame.EvaluateScriptAsync(script).ConfigureAwait(false);
			if (!response.Success)
			{
				return AolaPetMorphPushResult.NotInjected(response.Message ?? "JavaScript 注入失败。");
			}
			int state = response.Result == null
				? 0
				: Convert.ToInt32(response.Result, CultureInfo.InvariantCulture);
			return new AolaPetMorphPushResult(true, state >= 2, state >= 1, revision, null);
		}
		catch (Exception ex) when (ex is InvalidOperationException ||
			ex is ObjectDisposedException || ex is FormatException || ex is InvalidCastException)
		{
			return AolaPetMorphPushResult.NotInjected(ex.Message);
		}
	}
}
