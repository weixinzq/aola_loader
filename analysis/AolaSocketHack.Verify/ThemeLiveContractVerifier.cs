using System;
using System.Collections.Generic;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using AolaLoader.BrowserHost.Contracts;
using AolaLoader.BrowserHost.Testing;
using AolaLoader.Features.Theme.Coordination;
using AolaLoader.Features.Theme.Coordination.Testing;
using AolaLoader.Features.Theme.ResourceInterception;
using AolaLoader.ResourceInterception.Contracts;
using AolaLoader.Settings;
using Newtonsoft.Json.Linq;

namespace AolaSocketHack.Verify;

internal static class ThemeLiveContractVerifier
{
	public static bool Verify()
	{
		string controlPath = Path.Combine("analysis", "AolaLoader", "Resources", "Patches", "controlv2-theme-live-2026082731219998.fws.swf");
		var control = new ThemeControlBridgeResourceRule(controlPath, true);
		const string controlUrl = "https://aola.100bt.com/play/control/controlv2~2026082731219998.swf";
		if (control.Evaluate(new ResourceRequestContext(controlUrl, "GET", "Other")).Outcome != ResourceInterceptionOutcome.LocalResponse ||
			control.Evaluate(new ResourceRequestContext(controlUrl.Replace("2026082731219998", "1"), "GET", "Other")).Outcome != ResourceInterceptionOutcome.PassThrough ||
			control.Evaluate(new ResourceRequestContext(controlUrl, "POST", "Other")).Outcome != ResourceInterceptionOutcome.PassThrough ||
			control.Evaluate(new ResourceRequestContext(controlUrl.Replace("100bt.com", "invalid.test"), "GET", "Other")).Outcome != ResourceInterceptionOutcome.PassThrough ||
			new ThemeControlBridgeResourceRule(null, false).Evaluate(new ResourceRequestContext(controlUrl, "GET", "Other")).Outcome != ResourceInterceptionOutcome.PassThrough)
			return false;
		byte[] payload = { 1, 2, 3 };
		var rule = new ThemeLeafResourceRule(Array.Empty<KeyValuePair<int, byte[]>>(),
			new[] { new KeyValuePair<int, byte[]>(9, payload) }) { LiveEnabled = true };
		payload[0] = 9;
		const string url = "https://aola.100bt.com/play/aola-helper/theme/skin9.swf";
		if (rule.Evaluate(new ResourceRequestContext(url, "GET", "Other")).LocalContent[0] != 1 ||
			rule.Evaluate(new ResourceRequestContext(url, "POST", "Other")).Outcome != ResourceInterceptionOutcome.PassThrough ||
			rule.Evaluate(new ResourceRequestContext(url.Replace("100bt.com", "invalid.test"), "GET", "Other")).Outcome != ResourceInterceptionOutcome.PassThrough ||
			rule.Evaluate(new ResourceRequestContext("https://aola.100bt.com/play/control/controlbarskin/skin0~123.swf", "GET", "Other")).Outcome != ResourceInterceptionOutcome.PassThrough)
			return false;
		return VerifyExecutionAsync().GetAwaiter().GetResult();
	}

	private static async Task<bool> VerifyExecutionAsync()
	{
		var page = new ManualPageBridge();
		page.SetAvailability(PageBridgeAvailability.Ready);
		var blocked = new TaskCompletionSource<PageBridgeResult>();
		int calls = 0;
		page.InvokeHandler = (request, token) =>
		{
			calls++;
			if (request.Operation != "theme.apply") throw new Exception("Unexpected game command.");
			if (calls == 1) return blocked.Task;
			return Task.FromResult(PageBridgeResult.Success(new JObject
			{
				["status"] = calls == 2 ? "WaitingBattleEnd" : "Applied",
				["requestId"] = request.Arguments["requestId"], ["themeId"] = request.Arguments["themeId"]
			}));
		};
		var coordinator = new ThemeCoordinator(new Store(), new AolaLoader.Features.Theme.Settings.ThemeSettingsCodec(),
			new ManualThemeSelectionTarget(), pushBridge: new ThemeBridgeClient(page));
		coordinator.ApplyAndSave(1);
		int oldId = coordinator.RequestId;
		Task<ThemeLiveResult> old = coordinator.PushCurrentAsync(CancellationToken.None);
		coordinator.ApplyAndSave(9);
		blocked.SetResult(PageBridgeResult.Success(new JObject { ["status"] = "Applied", ["requestId"] = oldId, ["themeId"] = 1 }));
		if ((await old).Status != "Superseded") return false;
		if ((await coordinator.PushCurrentAsync(CancellationToken.None)).Status != "WaitingBattleEnd") return false;
		if ((await coordinator.PushCurrentAsync(CancellationToken.None)).Status != "Applied") return false;
		await coordinator.PushCurrentAsync(CancellationToken.None);
		if (calls != 3) return false;
		coordinator.ResetPage();
		await coordinator.PushCurrentAsync(CancellationToken.None);
		if (calls != 4) return false;
		coordinator.ApplyAndSave(0);
		if ((await coordinator.PushCurrentAsync(CancellationToken.None)).ThemeId != 0) return false;
		page.InvokeHandler = (request, token) => Task.FromResult(PageBridgeResult.Success(
			new JObject { ["status"] = "Failed", ["requestId"] = request.Arguments["requestId"], ["themeId"] = request.Arguments["themeId"], ["message"] = "load failed" }));
		coordinator.ApplyAndSave(6);
		return (await coordinator.PushCurrentAsync(CancellationToken.None)).Status == "Failed";
	}

	private sealed class Store : ISettingsSectionStore
	{
		public SettingsSectionLoadResult<T> Load<T>(string key, ISettingsSectionCodec<T> codec) =>
			new SettingsSectionLoadResult<T>(codec.CreateDefault(), true, false, null);
		public SettingsSectionSaveResult Save<T>(string key, T value, ISettingsSectionCodec<T> codec) => SettingsSectionSaveResult.Success(false);
	}
}
