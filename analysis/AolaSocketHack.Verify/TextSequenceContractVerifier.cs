using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Threading;
using System.Threading.Tasks;
using AolaLoader.BrowserHost.Contracts;
using AolaLoader.BrowserHost.Testing;
using AolaLoader.Features.ActiveSend;
using AolaLoader.Features.Battle.Bridge;
using AolaLoader.Features.Battle.Replay;
using AolaLoader.PacketHost.Testing;
using AolaSocketHack.Contracts;
using Newtonsoft.Json.Linq;
namespace AolaSocketHack.Verify;

internal static class TextSequenceContractVerifier
{
	public static bool Verify()
	{
		try
		{
			CheckParser();
			CheckExecutionAsync().GetAwaiter().GetResult();
			Console.WriteLine("Text parser, timing, lifecycle, cancellation and native-auto routing: PASS");
			return true;
		}
		catch (Exception ex) { Console.WriteLine("Text sequence failure: " + ex); return false; }
	}
	private static void Assert(bool value, string name)
	{ if (!value) throw new InvalidOperationException(name); }
	private const string Send = "#send={\"id\":42,\"cmd\":\"VERIFY\",\"param\":{}}|";
	private static void CheckParser()
	{
		var steps = AolaSendRequestParser.ParseSequence("\uFEFF// comment\n||#send={\n\"cmd\":\"VERIFY\",\"param\":{\"v\":\"a|b\\\"c\",\":ext_seq;\":1},\"id\":42\n}|#wait|#time = 2.5");
		Assert(steps.Count == 3 && steps[1].Kind == AolaTextStepKind.WaitBattleEnd && steps[2].Seconds == 2.5, "typed parser");
		Assert(JObject.Parse(steps[0].Request.ParametersJson).Value<string>("v") == "a|b\"c" &&
			JObject.Parse(steps[0].Request.ParametersJson)[":ext_seq;"] == null, "JSON boundary/sequence ownership");
		foreach (var text in new[] { "#time = -1", "#time = NaN", "#time = Infinity", Send + "\n#waitx", "#send={\"id\":42,\"id\":13,\"cmd\":\"X\",\"param\":{}}" })
		{
			try { AolaSendRequestParser.ParseSequence(text); throw new Exception("accepted invalid text"); }
			catch (InvalidOperationException ex) { Assert(ex.Message.Contains("第 "), "line number"); }
		}
	}
	private static async Task CheckExecutionAsync()
	{
		using (var h = new Harness())
		{
			await h.Run(Send + Send);
			Assert(h.Sender.Times[1] - h.Sender.Times[0] >= 199, "200ms minimum");
		}
		using (var h = new Harness())
		{
			await h.Run(Send + "#time = .25|" + Send);
			double gap = h.Sender.Times[1] - h.Sender.Times[0];
			Assert(gap >= 245 && gap < 440, "delay counted without extra 200ms");
		}
		using (var h = new Harness())
		{
			await h.Run(Send, groups: 2, rest: 70);
			Assert(h.Sender.Times.Count == 2 && h.Sender.Times[1] - h.Sender.Times[0] < 250, "group rest without extra interval");
		}
		using (var h = new Harness())
		{
			try { await h.Run(Send + "#send={\"id\":80,\"cmd\":\"BAD\",\"param\":{}}"); throw new Exception("precheck accepted"); }
			catch (InvalidOperationException) { Assert(h.Sender.Times.Count == 0, "precheck zero sends"); }
		}
		using (var h = new Harness())
		{
			h.Sender.Fail = true;
			try { await h.Run(Send + Send); throw new Exception("failure ignored"); }
			catch (InvalidOperationException) { Assert(h.Sender.Times.Count == 1, "failure stops without retry"); }
		}
		using (var h = new Harness())
		{
			h.Battle();
			Task task = h.Run("#wait|" + Send);
			await Task.Delay(20);
			h.Packet("2403", new JObject { ["battleUniqueId"] = 100 });
			await Task.Delay(20);
			Assert(!task.IsCompleted && h.Sender.Times.Count == 0, "old end ignored");
			h.Packet("2403", new JObject { ["battleUniqueId"] = 99 });
			await task;
			Assert(h.State.Current.Phase == AolaExecutionPhase.Idle && h.Sender.Times.Count == 1, "natural end");
		}
		foreach (string reason in new[] { "ConnectionClosed", "CaptureInvalid" })
		using (var h = new Harness())
		{
			h.Battle();
			Task task = h.Run("#wait|" + Send);
			h.Source.PublishStatus(new AolaHookStatus { ProcessId = 7, SocketHandle = 9, ExecutionEvent = reason, Message = reason });
			try { await task; throw new Exception("loss ignored"); }
			catch (InvalidOperationException) { Assert(h.Sender.Times.Count == 0, "loss stops"); }
		}
		using (var h = new Harness())
		using (var cancel = new CancellationTokenSource())
		{
			h.Battle();
			Task task = h.Run("#wait|" + Send, token: cancel.Token);
			cancel.Cancel();
			try { await task; throw new Exception("cancel ignored"); }
			catch (OperationCanceledException) { Assert(h.Sender.Times.Count == 0, "cancel only text"); }
			h.Packet("2403", new JObject { ["battleUniqueId"] = 99 });
			await h.Run("#wait|" + Send);
		}
		using (var h = new Harness())
		{
			const string entry = "#send={\"id\":15,\"cmd\":\"54_22\",\"param\":{\"si\":1,\"dr\":1,\"isHurtFight\":false,\"index\":1,\"type\":1,\"ddr\":1,\"t\":1,\"bb\":1,\"lv\":1,\"handler\":\"\",\"pb\":1}}|";
			h.Sender.OnSend = request => { if (request.Command == "54_22") h.Battle(); };
			// 首次确认后等待结束，再进入下一场；入口所需身份包从真实事件端口进入。
			Task task = h.Run(entry + "#wait|" + entry);
			await Task.Delay(20);
			h.Packet("2403", new JObject { ["battleUniqueId"] = 99 });
			await task;
			Assert(h.Sender.Times.Count == 2, "multiple battles");
		}
		using (var h = new Harness())
		{
			int calls = 0;
			h.Page.InvokeHandler = (request, token) =>
			{
				Assert(request.Operation == "battle.auto", "native auto uses dedicated bridge");
				calls++; return Task.FromResult(PageBridgeResult.Success(new JObject { ["status"] = "SubmittedToFlash" }));
			};
			var sender = new AolaFlashCommandSender(h.Page);
			var result = await sender.SendAsync(new AolaSendRequest { ExtensionId = 13, Command = "1409", ParametersJson = "{\"useAiType\":1}" }, CancellationToken.None);
			Assert(calls == 1 && result.Status == AolaCommandSendStatus.SubmittedToFlash, "no duplicate auto send");
		}
	}
	private sealed class Harness : IDisposable
	{
		public readonly ManualAolaPacketEventSource Source = new ManualAolaPacketEventSource();
		public readonly ManualPageBridge Page = new ManualPageBridge();
		public readonly FakeSender Sender = new FakeSender();
		public readonly AolaExecutionState State;
		private readonly AolaTextSequenceRunner _runner;
		public Harness()
		{
			State = new AolaExecutionState(Source);
			Packet("joinOK", new JObject());
			Page.SetAvailability(PageBridgeAvailability.Ready);
			Page.InvokeHandler = (request, token) => Task.FromResult(PageBridgeResult.Success(new JObject
			{
				["version"] = 5, ["active"] = State.Current.Phase == AolaExecutionPhase.Active,
				["battleId"] = State.Current.BattleId, ["turn"] = 0, ["inputReady"] = true,
				["readyEpoch"] = 1, ["ended"] = false
			}));
			_runner = new AolaTextSequenceRunner(Source, State, Sender, new BattleBridgeClient(Page));
		}
		public void Packet(string command, JObject p) => Source.PublishPacket(new AolaPacketEvent
		{
			ProcessId = 7, SocketHandle = 9, ConnectionPlayerId = 10, Direction = "接收",
			Command = command, ParametersJson = p.ToString(), DecodeSucceeded = true
		});
		public void Battle()
		{
			Packet("2303", new JObject { ["battleId"] = -42 });
			Packet("2304", new JObject());
			Packet("2401", new JObject { ["br"] = -42, ["battleUniqueId"] = 99 });
		}
		public Task Run(string text, int groups = 1, int rest = 1000, CancellationToken token = default) =>
			_runner.RunAsync(AolaSendRequestParser.ParseSequence(text), groups, rest, token);
		public void Dispose() { State.Dispose(); Source.Dispose(); Page.Dispose(); }
	}
	private sealed class FakeSender : IAolaCommandSender
	{
		public event Action<AolaCommandSendUpdate> StatusChanged { add { } remove { } }
		public readonly List<double> Times = new List<double>();
		private readonly Stopwatch _clock = Stopwatch.StartNew();
		public bool Fail;
		public Action<AolaSendRequest> OnSend;
		public Task<AolaCommandSendUpdate> SendAsync(AolaSendRequest request, CancellationToken token)
		{
			token.ThrowIfCancellationRequested();
			Times.Add(_clock.Elapsed.TotalMilliseconds);
			OnSend?.Invoke(request);
			return Task.FromResult(new AolaCommandSendUpdate("", request.ExtensionId, request.Command,
				Fail ? AolaCommandSendStatus.SubmissionFailed : AolaCommandSendStatus.SubmittedToFlash, "test"));
		}
	}
}
