using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using AolaLoader.BrowserHost.Contracts;
using AolaLoader.BrowserHost.Testing;
using Newtonsoft.Json.Linq;

namespace AolaSocketHack.Verify;

internal static class BrowserHostContractVerifier
{
	public static bool Verify()
	{
		return VerifyBrowserSession() && VerifyPageBridge();
	}

	private static bool VerifyBrowserSession()
	{
		List<BrowserPageLifecycleKind> lifecycle = new List<BrowserPageLifecycleKind>();
		ManualBrowserSession session = new ManualBrowserSession();
		session.PageLifecycleChanged += value => throw new InvalidOperationException("expected subscriber failure");
		session.PageLifecycleChanged += value => lifecycle.Add(value.Kind);
		session.Navigate("https://aola.100bt.com/play/play.html");
		session.PublishMainFrameReady();
		session.Refresh(BrowserRefreshMode.IgnoreCache);

		JObject scriptValue = new JObject { ["ready"] = true };
		session.ScriptHandler = (request, cancellationToken) =>
			Task.FromResult(BrowserScriptResult.Success(scriptValue));
		BrowserScriptResult scriptResult = session.ExecuteScriptAsync(
			new BrowserScriptRequest("bridge.probe", "window.aolaBridgeReady === true", TimeSpan.FromSeconds(2)),
			CancellationToken.None).GetAwaiter().GetResult();
		scriptValue["ready"] = false;
		JObject firstRead = (JObject)scriptResult.Value;
		firstRead["ready"] = false;
		if (!scriptResult.Succeeded || !scriptResult.Value.Value<bool>("ready") ||
			session.CurrentAddress != "https://aola.100bt.com/play/play.html" ||
			session.RefreshCount != 1 || session.LastRefreshMode != BrowserRefreshMode.IgnoreCache ||
			lifecycle.Count != 2 || lifecycle[0] != BrowserPageLifecycleKind.NavigationStarted ||
			lifecycle[1] != BrowserPageLifecycleKind.MainFrameReady)
		{
			session.Dispose();
			return false;
		}

		session.Dispose();
		BrowserScriptResult closedResult = session.ExecuteScriptAsync(
			new BrowserScriptRequest("bridge.closed", "true", TimeSpan.FromSeconds(1)),
			CancellationToken.None).GetAwaiter().GetResult();
		return session.IsClosed && lifecycle.Count == 3 &&
			lifecycle[2] == BrowserPageLifecycleKind.Closed &&
			!closedResult.Succeeded && closedResult.FailureKind == BrowserScriptFailureKind.BrowserClosed &&
			Throws<ObjectDisposedException>(() => session.Navigate("https://aola.100bt.com/")) &&
			Throws<ArgumentException>(() => new BrowserScriptRequest("invalid operation", "true", TimeSpan.FromSeconds(1)));
	}

	private static bool VerifyPageBridge()
	{
		JObject arguments = new JObject { ["enabled"] = true };
		PageBridgeRequest request = new PageBridgeRequest(
			"petMorph.refresh",
			arguments,
			TimeSpan.FromSeconds(3));
		arguments["enabled"] = false;
		JObject requestRead = request.Arguments;
		requestRead["enabled"] = false;
		if (!request.Arguments.Value<bool>("enabled"))
		{
			return false;
		}

		ManualPageBridge bridge = new ManualPageBridge();
		bridge.SetAvailability(PageBridgeAvailability.PageNotReady);
		PageBridgeResult pageNotReady = bridge.InvokeAsync(request, CancellationToken.None)
			.GetAwaiter().GetResult();
		bridge.SetAvailability(PageBridgeAvailability.BridgeNotInstalled);
		PageBridgeResult notInstalled = bridge.InvokeAsync(request, CancellationToken.None)
			.GetAwaiter().GetResult();
		bridge.SetAvailability(PageBridgeAvailability.Ready);
		bridge.InvokeHandler = (value, cancellationToken) => Task.FromResult(
			PageBridgeResult.Success(new JObject { ["revision"] = 4 }));
		PageBridgeResult invoked = bridge.InvokeAsync(request, CancellationToken.None)
			.GetAwaiter().GetResult();

		JObject state = new JObject { ["rules"] = new JArray(1, 2) };
		PageFeatureStatePush push = new PageFeatureStatePush(
			"petMorph",
			4,
			state,
			TimeSpan.FromSeconds(3));
		state["rules"] = new JArray();
		bridge.PushHandler = (value, cancellationToken) => Task.FromResult(
			PageBridgeResult.Failure(PageBridgeFailureKind.Timeout, "simulated timeout"));
		PageBridgeResult timeout = bridge.PushFeatureStateAsync(push, CancellationToken.None)
			.GetAwaiter().GetResult();

		bridge.InvokeHandler = (value, cancellationToken) => throw new InvalidOperationException("simulated failure");
		PageBridgeResult failed = bridge.InvokeAsync(request, CancellationToken.None)
			.GetAwaiter().GetResult();
		bridge.Dispose();
		PageBridgeResult closed = bridge.InvokeAsync(request, CancellationToken.None)
			.GetAwaiter().GetResult();

		return !pageNotReady.Succeeded && pageNotReady.FailureKind == PageBridgeFailureKind.PageNotReady &&
			!notInstalled.Succeeded && notInstalled.FailureKind == PageBridgeFailureKind.BridgeNotInstalled &&
			invoked.Succeeded && invoked.Value.Value<int>("revision") == 4 &&
			push.State["rules"] is JArray rules && rules.Count == 2 &&
			!timeout.Succeeded && timeout.FailureKind == PageBridgeFailureKind.Timeout &&
			!failed.Succeeded && failed.FailureKind == PageBridgeFailureKind.InvocationFailed &&
			bridge.Availability == PageBridgeAvailability.Closed &&
			!closed.Succeeded && closed.FailureKind == PageBridgeFailureKind.BrowserClosed &&
			Throws<ArgumentException>(() => new PageBridgeRequest("bad operation", null, TimeSpan.FromSeconds(1)));
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

