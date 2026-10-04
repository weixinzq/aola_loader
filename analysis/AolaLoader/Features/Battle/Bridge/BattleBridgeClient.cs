// 架构角色：封装 battle.* 页面桥操作，区分表现设置提交与 Flash 输入状态读取。
// 数据流：BattleSettings/revision 或状态请求 -> IPageBridge -> 类型化 battle 结果。
using System;
using System.Threading;
using System.Threading.Tasks;
using AolaLoader.BrowserHost.Contracts;
using AolaLoader.Features.Battle.Settings;
using Newtonsoft.Json.Linq;

namespace AolaLoader.Features.Battle.Bridge;

internal sealed class BattleBridgeClient
{
	private static readonly TimeSpan Timeout = TimeSpan.FromSeconds(3);
	private readonly IPageBridge _pageBridge;

	public BattleBridgeClient(IPageBridge pageBridge)
	{
		_pageBridge = pageBridge ?? throw new ArgumentNullException(nameof(pageBridge));
	}

	public async Task<BattleBridgeApplyResult> ApplyAsync(
		BattleSettings settings,
		int revision,
		CancellationToken cancellationToken)
	{
		if (settings == null)
		{
			throw new ArgumentNullException(nameof(settings));
		}
		JObject arguments = new JObject
		{
			["version"] = 5,
			["revision"] = revision,
			["hideDamageNumbers"] = settings.HideDamageNumbers,
			["hideHealingNumbers"] = settings.HideHealingNumbers,
			["skipBattlePresentation"] = settings.SkipBattlePresentation
		};
		PageBridgeResult result = await _pageBridge.InvokeAsync(
			new PageBridgeRequest("battle.apply", arguments, Timeout),
			cancellationToken).ConfigureAwait(false);
		if (!result.Succeeded)
		{
			return BattleBridgeApplyResult.Failure(result.Message);
		}
		string status = result.Value?.Value<string>("status") ?? string.Empty;
		int appliedRevision = result.Value?.Value<int?>("revision") ?? -1;
		if (appliedRevision != revision ||
			(status != "BattleOptionsApplied" && status != "BattleOptionsPending"))
		{
			return BattleBridgeApplyResult.Failure("页面桥返回了无效的战斗设置结果。");
		}
		return new BattleBridgeApplyResult(
			true,
			status == "BattleOptionsApplied",
			result.Value?.Value<string>("message"));
	}

	public Task<PageBridgeResult> SetAutoBattleAsync(bool enabled, CancellationToken token) =>
		_pageBridge.InvokeAsync(new PageBridgeRequest("battle.auto", new JObject { ["enabled"] = enabled }, Timeout), token);

	public async Task<BattleBridgeStateResult> GetStateAsync(CancellationToken cancellationToken)
	{
		PageBridgeResult result = await _pageBridge.InvokeAsync(
			new PageBridgeRequest("battle.state", new JObject(), Timeout),
			cancellationToken).ConfigureAwait(false);
		if (!result.Succeeded)
		{
			return BattleBridgeStateResult.Failure(result.Message);
		}
		JToken value = result.Value;
		if (!(value is JObject state) || !IsStrictState(state))
		{
			return BattleBridgeStateResult.Failure("页面桥返回了无效的战斗状态。");
		}
		return BattleBridgeStateResult.Success(new BattleBridgeState(
			state.Value<bool>("active"),
			state.Value<int>("battleId"),
			state.Value<int>("turn"),
			state.Value<bool>("inputReady"),
			state.Value<int>("readyEpoch"),
			state.Value<bool>("ended")));
	}

	private static bool IsStrictState(JObject state)
	{
		if (state.Count != 7 || state["version"]?.Type != JTokenType.Integer || state.Value<int>("version") != 5 ||
			state["active"]?.Type != JTokenType.Boolean || state["inputReady"]?.Type != JTokenType.Boolean ||
			state["ended"]?.Type != JTokenType.Boolean || state["battleId"]?.Type != JTokenType.Integer ||
			state["turn"]?.Type != JTokenType.Integer || state["readyEpoch"]?.Type != JTokenType.Integer)
		{
			return false;
		}
		return state.Value<int>("turn") >= 0 && state.Value<int>("readyEpoch") >= 0;
	}
}


internal sealed class BattleBridgeApplyResult
{
	public BattleBridgeApplyResult(bool submitted, bool applied, string message)
	{
		Submitted = submitted;
		Applied = applied;
		Message = message ?? string.Empty;
	}

	public bool Submitted { get; }

	public bool Applied { get; }

	public string Message { get; }

	public static BattleBridgeApplyResult Failure(string message) =>
		new BattleBridgeApplyResult(false, false, message);
}

internal sealed class BattleBridgeState
{
	public BattleBridgeState(bool active, int battleId, int turn, bool inputReady, int readyEpoch, bool ended)
	{
		Active = active;
		BattleId = battleId;
		Turn = turn;
		InputReady = inputReady;
		ReadyEpoch = readyEpoch;
		Ended = ended;
	}

	public bool Active { get; }
	public int BattleId { get; }
	public int Turn { get; }
	public bool InputReady { get; }
	public int ReadyEpoch { get; }
	public bool Ended { get; }
}

internal sealed class BattleBridgeStateResult
{
	private BattleBridgeStateResult(bool succeeded, BattleBridgeState state, string message)
	{
		Succeeded = succeeded;
		State = state;
		Message = message ?? string.Empty;
	}

	public bool Succeeded { get; }
	public BattleBridgeState State { get; }
	public string Message { get; }

	public static BattleBridgeStateResult Success(BattleBridgeState state) =>
		new BattleBridgeStateResult(true, state, null);

	public static BattleBridgeStateResult Failure(string message) =>
		new BattleBridgeStateResult(false, null, message);
}
