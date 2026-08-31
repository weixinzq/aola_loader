using System;
using System.Collections.Generic;
using System.Linq;
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

internal static class BattleReplayContractVerifier
{
	public static bool Verify()
	{
		return VerifyStrictValidation() && VerifyStrictBridgeState() &&
			VerifyStateDrivenProgression() && VerifyTimeoutDoesNotRetry();
	}

	private static bool VerifyStrictBridgeState()
	{
		ManualPageBridge page = new ManualPageBridge();
		page.SetAvailability(PageBridgeAvailability.Ready);
		page.InvokeHandler = (request, token) => Task.FromResult(PageBridgeResult.Success(new JObject
		{
			["version"] = 3,
			["active"] = true,
			["battleId"] = "777",
			["turn"] = 0,
			["inputReady"] = true,
			["readyEpoch"] = 1,
			["ended"] = false
		}));
		BattleBridgeStateResult result = new BattleBridgeClient(page).GetStateAsync(CancellationToken.None)
			.GetAwaiter().GetResult();
		page.Dispose();
		return !result.Succeeded;
	}

	private static bool VerifyStrictValidation()
	{
		BattleSequencePlan valid = BattleSequenceValidator.Validate(new[]
		{
			Entry(),
			Request(16, "preFightLoad", new JObject { ["ul"] = "1,-2", ["msg"] = "1:1" }),
			Skill(0),
			Request(13, "1403", new JObject { ["pmId"] = 3478, ["reqPSId"] = 0, ["turn"] = 1 })
		});
		return valid.Items.Count == 4 &&
			valid.Items[1].Kind == BattleSequenceItemKind.FlashOwned &&
			valid.Items[2].Turn == 0 && valid.Items[3].Turn == 1 &&
			Throws<InvalidOperationException>(() => BattleSequenceValidator.Validate(new[] { Skill(0) })) &&
			Throws<InvalidOperationException>(() => BattleSequenceValidator.Validate(new[]
			{
				Entry(), Request(13, "1408", new JObject { ["auto"] = true })
			})) &&
			Throws<InvalidOperationException>(() => BattleSequenceValidator.Validate(new[]
			{
				Entry(), Request(13, "1403", new JObject { ["pmId"] = 1, ["reqPSId"] = 0, ["turn"] = 0, ["extra"] = 1 })
			})) &&
			Throws<InvalidOperationException>(() => BattleSequenceValidator.Validate(new[]
			{
				Entry(), Request(13, "1410", new JObject { ["reqPSId"] = 0, ["turn"] = 0, ["ussi"] = -1, ["gmb"] = 1 })
			}));
	}

	private static bool VerifyStateDrivenProgression()
	{
		ManualAolaPacketEventSource packets = new ManualAolaPacketEventSource();
		ManualPageBridge page = new ManualPageBridge();
		page.SetAvailability(PageBridgeAvailability.Ready);
		int turn = 0;
		int epoch = 1;
		page.InvokeHandler = (request, token) => Task.FromResult(
			PageBridgeResult.Success(new JObject
			{
				["version"] = 3,
				["active"] = true,
				["battleId"] = 777,
				["turn"] = turn,
				["inputReady"] = true,
				["readyEpoch"] = epoch,
				["ended"] = false
			}));
		FakeSender sender = new FakeSender(request =>
		{
			if (request.ExtensionId == 15)
			{
				packets.PublishPacket(Receive("2303", new JObject()));
				packets.PublishPacket(Receive("2304", new JObject()));
				packets.PublishPacket(Receive("2401", new JObject { ["battleUniqueId"] = 777 }));
			}
			else if (request.ExtensionId == 13)
			{
				packets.PublishPacket(Send(request));
				turn++;
				epoch++;
			}
		});
		BattleSequenceRunner runner = new BattleSequenceRunner(
			packets,
			sender,
			new BattleBridgeClient(page),
			TimeSpan.FromSeconds(1),
			TimeSpan.FromSeconds(1),
			TimeSpan.FromMilliseconds(1));
		List<BattleSequenceStatus> statuses = new List<BattleSequenceStatus>();
		runner.StatusChanged += update => statuses.Add(update.Status);
		runner.RunAsync(BattleSequenceValidator.Validate(new[]
		{
			Entry(),
			Request(16, "preFightLoad", new JObject { ["ul"] = "1,-2", ["msg"] = "1:1" }),
			Skill(0),
			Request(13, "1403", new JObject { ["pmId"] = 3478, ["reqPSId"] = 0, ["turn"] = 1 })
		}), CancellationToken.None).GetAwaiter().GetResult();
		page.Dispose();
		packets.Dispose();
		return sender.Requests.Count == 3 &&
			sender.Requests[0].ExtensionId == 15 &&
			sender.Requests[1].Command == "1401" && sender.Requests[2].Command == "1403" &&
			statuses.Contains(BattleSequenceStatus.WaitingForBattle) &&
			statuses.Contains(BattleSequenceStatus.WaitingForTurn) &&
			statuses.Contains(BattleSequenceStatus.SkippedFlashOwned) &&
			!statuses.Contains(BattleSequenceStatus.Stopped);
	}

	private static bool VerifyTimeoutDoesNotRetry()
	{
		ManualAolaPacketEventSource packets = new ManualAolaPacketEventSource();
		ManualPageBridge page = new ManualPageBridge();
		page.SetAvailability(PageBridgeAvailability.Ready);
		page.InvokeHandler = (request, token) => Task.FromResult(PageBridgeResult.Success(new JObject
		{
			["version"] = 3,
			["active"] = false,
			["battleId"] = 0,
			["turn"] = 0,
			["inputReady"] = false,
			["readyEpoch"] = 0,
			["ended"] = false
		}));
		FakeSender sender = new FakeSender(null);
		BattleSequenceRunner runner = new BattleSequenceRunner(
			packets,
			sender,
			new BattleBridgeClient(page),
			TimeSpan.FromMilliseconds(25),
			TimeSpan.FromMilliseconds(25),
			TimeSpan.FromMilliseconds(2));
		int stopped = 0;
		runner.StatusChanged += update => { if (update.Status == BattleSequenceStatus.Stopped) stopped++; };
		runner.RunAsync(BattleSequenceValidator.Validate(new[] { Entry(), Skill(0) }), CancellationToken.None)
			.GetAwaiter().GetResult();
		page.Dispose();
		packets.Dispose();
		return sender.Requests.Count == 1 && stopped == 1;
	}

	private static AolaSendRequest Entry() => Request(15, "54_22", new JObject
	{
		["si"] = 0, ["dr"] = 0, ["isHurtFight"] = false, ["index"] = 0,
		["type"] = 99, ["ddr"] = 0, ["t"] = 0, ["bb"] = 68,
		["lv"] = 5, ["handler"] = "TP230818", ["pb"] = 0
	});

	private static AolaSendRequest Skill(int turn) => Request(13, "1401", new JObject
	{
		["skillId"] = 420138, ["tarSId"] = 0, ["isAuto"] = false,
		["tarPSId"] = 0, ["reqPSId"] = 0, ["turn"] = turn, ["ussi"] = -1
	});

	private static AolaSendRequest Request(int id, string command, JObject parameters) => new AolaSendRequest
	{
		ExtensionId = id,
		Command = command,
		ParametersJson = parameters.ToString(Newtonsoft.Json.Formatting.None)
	};

	private static AolaPacketEvent Receive(string command, JObject parameters) => new AolaPacketEvent
	{
		Direction = "接收",
		Command = command,
		ParametersJson = parameters.ToString(Newtonsoft.Json.Formatting.None),
		DecodeSucceeded = true
	};

	private static AolaPacketEvent Send(AolaSendRequest request) => new AolaPacketEvent
	{
		Direction = "发送",
		ExtensionId = request.ExtensionId,
		Command = request.Command,
		ParametersJson = new JObject(JObject.Parse(request.ParametersJson).Properties()
			.Reverse()
			.Select(property => new JProperty(property.Name, property.Value.DeepClone())))
			.ToString(Newtonsoft.Json.Formatting.None),
		DecodeSucceeded = true
	};

	private static bool Throws<TException>(Action action) where TException : Exception
	{
		try { action(); return false; }
		catch (TException) { return true; }
	}

	private sealed class FakeSender : IAolaCommandSender
	{
		private readonly Action<AolaSendRequest> _onSend;
		public FakeSender(Action<AolaSendRequest> onSend) { _onSend = onSend; }
		public List<AolaSendRequest> Requests { get; } = new List<AolaSendRequest>();
		public event Action<AolaCommandSendUpdate> StatusChanged;

		public Task<AolaCommandSendUpdate> SendAsync(AolaSendRequest request, CancellationToken cancellationToken)
		{
			Requests.Add(request);
			_onSend?.Invoke(request);
			AolaCommandSendUpdate update = new AolaCommandSendUpdate(
				Guid.NewGuid().ToString("N"), request.ExtensionId, request.Command,
				AolaCommandSendStatus.SubmittedToFlash, "submitted");
			StatusChanged?.Invoke(update);
			return Task.FromResult(update);
		}
	}
}
