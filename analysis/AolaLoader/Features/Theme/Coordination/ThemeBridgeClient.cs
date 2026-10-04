// 架构角色：主题协调器到页面桥的类型化适配，不提交游戏协议。
// 数据流：themeId/requestId -> theme.apply -> Flash 应用状态。
using System;
using System.Threading;
using System.Threading.Tasks;
using AolaLoader.BrowserHost.Contracts;
using Newtonsoft.Json.Linq;

namespace AolaLoader.Features.Theme.Coordination;

internal sealed class ThemeBridgeClient : IThemePushBridge
{
	private readonly IPageBridge _pageBridge;
	public ThemeBridgeClient(IPageBridge pageBridge) { _pageBridge = pageBridge; }
	public async Task<ThemeLiveResult> ApplyAsync(int themeId, int requestId, CancellationToken token)
	{
		PageBridgeResult result = await _pageBridge.InvokeAsync(new PageBridgeRequest("theme.apply",
			new JObject { ["themeId"] = themeId, ["requestId"] = requestId }, TimeSpan.FromSeconds(5)), token).ConfigureAwait(false);
		if (!result.Succeeded)
			return new ThemeLiveResult(result.FailureKind == PageBridgeFailureKind.PageNotReady ? "NotReady" : "Failed", requestId, themeId, result.Message);
		JToken value = result.Value;
		if (value?.Value<int?>("requestId") != requestId || value?.Value<int?>("themeId") != themeId)
			return new ThemeLiveResult("Failed", requestId, themeId, "主题桥返回的请求身份不匹配。");
		string status = value.Value<string>("status");
		if (status != "Applied" && status != "WaitingBattleEnd" && status != "NotReady" && status != "Loading" && status != "Failed" && status != "Superseded")
			return new ThemeLiveResult("Failed", requestId, themeId, "主题桥返回了未知状态。");
		return new ThemeLiveResult(status, requestId, themeId, value.Value<string>("message"));
	}
}
