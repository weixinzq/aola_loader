using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using AolaLoader.BrowserHost;
using AolaLoader.BrowserHost.Contracts;
using AolaLoader.BrowserHost.Testing;
using AolaLoader.Features.ActiveSend;
using AolaSocketHack.Contracts;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace AolaSocketHack.Verify;

internal static class ActiveSendContractVerifier
{
	public static bool Verify()
	{
		return VerifyStrictParser() && VerifyProductionPageBridge() &&
			VerifySubmittedSend() && VerifyRejectedAndUnknownSend() && VerifyTimedOutSubmit();
	}

	private static bool VerifyStrictParser()
	{
		List<AolaSendRequest> requests = AolaSendRequestParser.ParseLines(
			"#send={\"id\":42,\"param\":{\":ext_seq;\":9,\"value\":1},\"cmd\":\"VERIFY\"}|");
		return requests.Count == 1 && requests[0].ExtensionId == 42 &&
			requests[0].Command == "VERIFY" &&
			JObject.Parse(requests[0].ParametersJson)[":ext_seq;"] == null &&
			Throws<InvalidOperationException>(() => AolaSendRequestParser.ParseLines(
				"#send={\"param\":{},\"id\":42,\"cmd\":\"VERIFY\"}|")) &&
			Throws<InvalidOperationException>(() => AolaSendRequestParser.ParseLines(
				"#send={\"id\":42,\"param\":{},\"cmd\":\"VERIFY\",\"extra\":1}|")) &&
			Throws<JsonException>(() => AolaSendRequestParser.ParseLines(
				"#send={\"id\":42,\"id\":43,\"param\":{},\"cmd\":\"VERIFY\"}|"));
	}

	private static bool VerifyProductionPageBridge()
	{
		ManualBrowserSession session = new ManualBrowserSession();
		session.Navigate("https://aola.100bt.com/play/play.html");
		AolaPageBridge bridge = new AolaPageBridge(session);
		PageBridgeRequest request = new PageBridgeRequest(
			"activeSend.submit",
			new JObject
			{
				["requestId"] = "0123456789abcdef0123456789abcdef",
				["extension"] = "HolidayExtension",
				["command"] = "VERIFY",
				["parametersJson"] = "{}"
			},
			TimeSpan.FromSeconds(1));
		PageBridgeResult notReady = bridge.InvokeAsync(request, CancellationToken.None)
			.GetAwaiter().GetResult();
		string sendScript = null;
		string panelScript = null;
		string playbackScript = null;
		string battleApplyScript = null;
		string battleStateScript = null;
		session.ScriptHandler = (script, cancellationToken) =>
		{
			if (script.OperationName == "panel.open")
			{
				panelScript = script.Script;
				return Task.FromResult(BrowserScriptResult.Success(
					JValue.CreateString("{\"ok\":true,\"value\":{\"status\":\"PanelOpenRequested\"},\"failure\":\"\",\"message\":\"\"}")));
			}
			if (script.OperationName == "playback.apply")
			{
				playbackScript = script.Script;
				return Task.FromResult(BrowserScriptResult.Success(
					JValue.CreateString("{\"ok\":true,\"value\":{\"status\":\"PlaybackApplied\",\"frameRate\":50,\"quality\":\"best\"},\"failure\":\"\",\"message\":\"\"}")));
			}
			if (script.OperationName == "battle.apply")
			{
				battleApplyScript = script.Script;
				return Task.FromResult(BrowserScriptResult.Success(
					JValue.CreateString("{\"ok\":true,\"value\":{\"status\":\"BattleOptionsPending\",\"revision\":1},\"failure\":\"\",\"message\":\"\"}")));
			}
			if (script.OperationName == "battle.state")
			{
				battleStateScript = script.Script;
				return Task.FromResult(BrowserScriptResult.Success(
					JValue.CreateString("{\"ok\":true,\"value\":{\"version\":4,\"active\":true,\"battleId\":-94617668,\"turn\":0,\"inputReady\":true,\"readyEpoch\":1,\"ended\":false},\"failure\":\"\",\"message\":\"\"}")));
			}
			sendScript = script.Script;
			return Task.FromResult(BrowserScriptResult.Success(
				JValue.CreateString("{\"ok\":true,\"value\":{\"status\":\"SubmittedToFlash\",\"code\":\"\"},\"failure\":\"\",\"message\":\"\"}")));
		};
		session.PublishMainFrameReady();
		PageBridgeResult ready = bridge.InvokeAsync(request, CancellationToken.None)
			.GetAwaiter().GetResult();
		PageBridgeResult panel = bridge.InvokeAsync(
			new PageBridgeRequest(
				"panel.open",
				new JObject
				{
					["resourceUrl"] = "activityres/example/panel_code",
					["resourceClass"] = "mmo.example.Panel"
				},
				TimeSpan.FromSeconds(1)),
			CancellationToken.None).GetAwaiter().GetResult();
		PageBridgeResult playback = bridge.InvokeAsync(
			new PageBridgeRequest(
				"playback.apply",
				new JObject { ["frameRate"] = 50, ["quality"] = "best" },
				TimeSpan.FromSeconds(1)),
			CancellationToken.None).GetAwaiter().GetResult();
		PageBridgeResult battleApply = bridge.InvokeAsync(
			new PageBridgeRequest(
				"battle.apply",
				new JObject
				{
					["version"] = 4, ["revision"] = 1,
					["hideDamageNumbers"] = true, ["hideHealingNumbers"] = false,
					["skipBattlePresentation"] = true
				},
				TimeSpan.FromSeconds(1)),
			CancellationToken.None).GetAwaiter().GetResult();
		PageBridgeResult battleState = bridge.InvokeAsync(
			new PageBridgeRequest("battle.state", new JObject(), TimeSpan.FromSeconds(1)),
			CancellationToken.None).GetAwaiter().GetResult();
		bridge.Dispose();
		session.Dispose();
		return !notReady.Succeeded && notReady.FailureKind == PageBridgeFailureKind.PageNotReady &&
			ready.Succeeded && ready.Value.Value<string>("status") == "SubmittedToFlash" &&
			panel.Succeeded && panel.Value.Value<string>("status") == "PanelOpenRequested" &&
			playback.Succeeded && playback.Value.Value<int>("frameRate") == 50 &&
			battleApply.Succeeded && battleState.Succeeded && battleState.Value.Value<int>("battleId") == -94617668 &&
			sendScript != null && panelScript != null && playbackScript != null &&
			battleApplyScript != null && battleStateScript != null &&
			sendScript.IndexOf("aolaSendCommand", StringComparison.Ordinal) >= 0 &&
			sendScript.IndexOf("aolaCommandCompleted", StringComparison.Ordinal) >= 0 &&
			panelScript.IndexOf("aolaOpenPanel", StringComparison.Ordinal) >= 0 &&
			panelScript.IndexOf("activityres/example/panel_code", StringComparison.Ordinal) >= 0 &&
			panelScript.IndexOf("mmo.example.Panel", StringComparison.Ordinal) >= 0 &&
			playbackScript.IndexOf("aolaSetPlayback", StringComparison.Ordinal) >= 0 &&
			playbackScript.IndexOf("[0, 25, 50, 75]", StringComparison.Ordinal) >= 0 &&
			battleApplyScript.IndexOf("aolaBattleApplyOptions", StringComparison.Ordinal) >= 0 &&
			battleApplyScript.IndexOf("skipBattlePresentation", StringComparison.Ordinal) >= 0 &&
			battleStateScript.IndexOf("aolaBattleGetState", StringComparison.Ordinal) >= 0 &&
			battleStateScript.IndexOf("readyEpoch", StringComparison.Ordinal) >= 0 &&
			battleStateScript.IndexOf("-2147483648", StringComparison.Ordinal) >= 0 &&
			sendScript.IndexOf("游戏桥尚未就绪，请等待游戏加载完成", StringComparison.Ordinal) >= 0 &&
			sendScript.IndexOf("请先打开精灵背包", StringComparison.Ordinal) < 0 &&
			sendScript.IndexOf("logIn", StringComparison.OrdinalIgnoreCase) < 0 &&
			sendScript.IndexOf("SID", StringComparison.OrdinalIgnoreCase) < 0 &&
			panelScript.IndexOf("logIn", StringComparison.OrdinalIgnoreCase) < 0 &&
			panelScript.IndexOf("SID", StringComparison.OrdinalIgnoreCase) < 0;
	}

	private static bool VerifySubmittedSend()
	{
		ManualPageBridge bridge = new ManualPageBridge();
		bridge.SetAvailability(PageBridgeAvailability.Ready);
		int polls = 0;
		bridge.InvokeHandler = (request, cancellationToken) =>
		{
			if (request.Operation == "activeSend.submit")
			{
				return Task.FromResult(PageBridgeResult.Success(
					new JObject { ["status"] = "SubmittedToFlash", ["code"] = "" }));
			}
			if (request.Operation == "activeSend.poll")
			{
				polls++;
				return Task.FromResult(PageBridgeResult.Success(
					new JObject { ["status"] = "ServerSucceeded", ["code"] = "1" }));
			}
			return Task.FromResult(PageBridgeResult.Success(new JObject()));
		};
		AolaFlashCommandSender sender = new AolaFlashCommandSender(bridge);
		List<AolaCommandSendStatus> statuses = new List<AolaCommandSendStatus>();
		sender.StatusChanged += update => statuses.Add(update.Status);
		AolaCommandSendUpdate result = sender.SendAsync(
			new AolaSendRequest { ExtensionId = 42, Command = "VERIFY", ParametersJson = "{}" },
			CancellationToken.None).GetAwaiter().GetResult();
		bridge.Dispose();
		return polls == 0 && result.Status == AolaCommandSendStatus.SubmittedToFlash &&
			statuses.Count == 1 && statuses[0] == AolaCommandSendStatus.SubmittedToFlash;
	}

	private static bool VerifyRejectedAndUnknownSend()
	{
		ManualPageBridge bridge = new ManualPageBridge();
		bridge.SetAvailability(PageBridgeAvailability.Ready);
		int invocations = 0;
		bridge.InvokeHandler = (request, cancellationToken) =>
		{
			invocations++;
			return Task.FromResult(PageBridgeResult.Success(
				new JObject { ["status"] = "ServerRejected", ["code"] = "-5" }));
		};
		AolaFlashCommandSender sender = new AolaFlashCommandSender(bridge);
		AolaCommandSendUpdate unknown = sender.SendAsync(
			new AolaSendRequest { ExtensionId = 51, Command = "VERIFY", ParametersJson = "{}" },
			CancellationToken.None).GetAwaiter().GetResult();
		AolaCommandSendUpdate rejected = sender.SendAsync(
			new AolaSendRequest { ExtensionId = 42, Command = "VERIFY", ParametersJson = "{}" },
			CancellationToken.None).GetAwaiter().GetResult();
		bridge.Dispose();
		return unknown.Status == AolaCommandSendStatus.SubmissionFailed &&
			rejected.Status == AolaCommandSendStatus.ServerRejected && invocations == 1;
	}

	private static bool VerifyTimedOutSubmit()
	{
		ManualPageBridge bridge = new ManualPageBridge();
		bridge.SetAvailability(PageBridgeAvailability.Ready);
		bridge.InvokeHandler = (request, cancellationToken) => Task.FromResult(
			PageBridgeResult.Failure(PageBridgeFailureKind.Timeout, "submit timeout"));
		AolaFlashCommandSender sender = new AolaFlashCommandSender(bridge);
		AolaCommandSendUpdate result = sender.SendAsync(
			new AolaSendRequest { ExtensionId = 42, Command = "VERIFY", ParametersJson = "{}" },
			CancellationToken.None).GetAwaiter().GetResult();
		bridge.Dispose();
		return result.Status == AolaCommandSendStatus.TimedOut;
	}

	private static bool Throws<TException>(Action action) where TException : Exception
	{
		try
		{
			action();
			return false;
		}
		catch (TException)
		{
			return true;
		}
	}
}
