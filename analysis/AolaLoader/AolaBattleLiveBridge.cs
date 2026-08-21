using System;
using System.Collections.Generic;
using System.Globalization;
using System.Threading;
using System.Threading.Tasks;
using CefSharp;
using Newtonsoft.Json;

namespace AolaLoader;

/// <summary>
/// Host → 战斗模块 (petfightnew) 的选项推送桥接。
/// 注入 window.aolaBattleBridgeReady 并枚举 object/embed 调用
/// aolaBattleApplyOptions(json)；模型 ID 映射由 HTTP 拦截层处理，不进 SWF。
/// </summary>
internal sealed class AolaBattleLiveBridge
{
	private long _revision;

	public async Task<AolaBattlePushResult> PushAsync(
		IFrame frame,
		bool hideDamageNumbers,
		bool hideHealingNumbers,
		bool skipPetAttackActions,
		bool disableSkillEffects)
	{
		if (frame == null || !frame.IsValid)
		{
			return AolaBattlePushResult.NotInjected("浏览器主框架尚未就绪。");
		}

		long revision = Interlocked.Increment(ref _revision);
		string optionsJson = JsonConvert.SerializeObject(new Dictionary<string, object>
		{
			["hideDamageNumbers"] = hideDamageNumbers,
			["hideHealingNumbers"] = hideHealingNumbers,
			["skipPetAttackActions"] = skipPetAttackActions,
			["fightSkillEffect"] = disableSkillEffects ? 2 : 0
		});
		string script = @"(function (options, revision) {
	var state = window.__aolaBattleState || {};
	state.options = options || {};
	state.revision = revision;
	state.ready = !!state.ready;
	window.__aolaBattleState = state;
	var pushOptions = function () {
		var candidates = [];
		var primary = document.getElementById('swfContainer');
		if (primary) candidates.push(primary);
		var nodes = document.querySelectorAll('object,embed');
		for (var i = 0; i < nodes.length; i++) {
			if (candidates.indexOf(nodes[i]) < 0) candidates.push(nodes[i]);
		}
		var json = JSON.stringify(window.__aolaBattleState.options || {});
		var applied = false;
		for (var j = 0; j < candidates.length; j++) {
			try {
				if (typeof candidates[j].aolaBattleApplyOptions === 'function') {
					candidates[j].aolaBattleApplyOptions(json);
					applied = true;
				}
			} catch (ignored) {}
		}
		return applied;
	};
	window.aolaBattleBridgeReady = function (moduleVersion) {
		var current = window.__aolaBattleState || {};
		current.ready = true;
		current.moduleVersion = String(moduleVersion || '');
		window.__aolaBattleState = current;
		pushOptions();
		return Number(current.revision) || 0;
	};
	var applied = pushOptions();
	return state.ready ? 2 : (applied ? 1 : 0);
})(" + optionsJson + "," +
			revision.ToString(CultureInfo.InvariantCulture) + ")";

		try
		{
			JavascriptResponse response = await frame.EvaluateScriptAsync(script).ConfigureAwait(false);
			if (!response.Success)
			{
				return AolaBattlePushResult.NotInjected(response.Message ?? "JavaScript 注入失败。");
			}
			int result = response.Result == null
				? 0
				: Convert.ToInt32(response.Result, CultureInfo.InvariantCulture);
			return new AolaBattlePushResult(true, result >= 2, result >= 1, revision, null);
		}
		catch (Exception ex) when (ex is InvalidOperationException ||
			ex is ObjectDisposedException || ex is FormatException || ex is InvalidCastException)
		{
			return AolaBattlePushResult.NotInjected(ex.Message);
		}
	}
}

internal sealed class AolaBattlePushResult
{
	public AolaBattlePushResult(
		bool injected,
		bool bridgeReady,
		bool optionsApplied,
		long revision,
		string error,
		bool superseded = false)
	{
		Injected = injected;
		BridgeReady = bridgeReady;
		OptionsApplied = optionsApplied;
		Revision = revision;
		Error = error;
		Superseded = superseded;
	}

	public bool Injected { get; }
	public bool BridgeReady { get; }
	public bool OptionsApplied { get; }
	public long Revision { get; }
	public string Error { get; }
	public bool Superseded { get; }

	public static AolaBattlePushResult NotInjected(string error)
	{
		return new AolaBattlePushResult(false, false, false, 0, error);
	}
}
