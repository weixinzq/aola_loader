using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using AolaLoader.BrowserHost.Contracts;
using AolaLoader.BrowserHost.Testing;
using AolaLoader.Features.ActiveSend;
using AolaLoader.Features.Battle.Bridge;
using AolaLoader.Features.Battle.Diagnostics;
using AolaLoader.Features.Battle.Replay;
using AolaLoader.PacketHost.Testing;
using AolaSocketHack.Contracts;
using Newtonsoft.Json.Linq;

namespace AolaSocketHack.Verify;

internal static class BattleReplayContractVerifier
{
	public static bool Verify()
	{
		return VerifyStrictValidation() && VerifyStrictBridgeState() && VerifyStrictDiagnostics() &&
			VerifyStateDrivenProgression() && VerifyMixedPrefixProgression() &&
			VerifySameTurnPacing() && VerifyServerReadyIsRequired() &&
			VerifyDoesNotAdvanceWhileFlashTurnStaysCurrent() &&
			VerifyCurrentBattleAttachment() &&
			VerifyPrefixFailureStopsBeforeBattle() && VerifyGroupPartialFailureDoesNotRetry() &&
			VerifySignatureOrderMismatchStopsGroup() && VerifyNextTurnBridgeFailureStops() &&
			VerifyAttachmentStopsOnInvalidState() && VerifyAttachmentBridgeFailure() &&
			VerifyTimeoutDoesNotRetry();
	}

	private static bool VerifyStrictBridgeState()
	{
		ManualPageBridge page = new ManualPageBridge();
		page.SetAvailability(PageBridgeAvailability.Ready);
		page.InvokeHandler = (request, token) => Task.FromResult(PageBridgeResult.Success(new JObject
		{
			["version"] = 5,
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

	private static bool VerifyStrictDiagnostics()
	{
		ManualPageBridge page = new ManualPageBridge();
		page.SetAvailability(PageBridgeAvailability.Ready);
		bool invalidMemory = false;
		page.InvokeHandler = (request, token) => Task.FromResult(PageBridgeResult.Success(
			request.Operation == "battle.diagnostics.events"
				? new JObject
				{
					["version"] = 1,
					["droppedEventCount"] = 0,
					["events"] = new JArray
					{
						new JObject
						{
							["sequence"] = 1,
							["atMs"] = 12000,
							["type"] = "resource-ended",
							["resource"] = "pet/fight/example",
							["durationMs"] = 87,
							["value"] = 3,
							["futureField"] = true
						}
					}
				}
				: DiagnosticsSnapshot(invalidMemory)));
		BattleDiagnosticsResult valid = new BattleDiagnosticsClient(page).GetAsync(CancellationToken.None)
			.GetAwaiter().GetResult();
		BattleTraceResult trace = new BattleDiagnosticsClient(page).DrainTraceEventsAsync(CancellationToken.None)
			.GetAwaiter().GetResult();
		invalidMemory = true;
		BattleDiagnosticsResult invalidResult = new BattleDiagnosticsClient(page).GetAsync(CancellationToken.None)
			.GetAwaiter().GetResult();
		page.Dispose();
		return valid.Succeeded && valid.Snapshot.TotalMemory == 128L * 1024 * 1024 &&
			valid.Snapshot.LiveFightPanels == 1 &&
			valid.Snapshot.LiveStartMovies == 1 && valid.Snapshot.LiveApplicationDomains == 1 &&
			valid.Snapshot.PreloadInFlightCount == 1 && valid.Snapshot.StageFrameRate == 50 &&
			valid.Snapshot.FrameSampleCount == 750 && valid.Snapshot.MaxFrameGapMs == 123 &&
			valid.Snapshot.FreeMemory == -1 && trace.Succeeded && trace.Events.Count == 1 &&
			trace.Events[0].Resource == "pet/fight/example" && trace.Events[0].DurationMs == 87 &&
			!invalidResult.Succeeded;
	}

	private static JObject DiagnosticsSnapshot(bool invalidMemory)
	{
		return new JObject
		{
			["version"] = 4,
			["conservativeCleanupEnabled"] = true,
			["flashUptimeMs"] = 12050,
			["totalMemory"] = invalidMemory ? (JToken)"128" : 128 * 1024 * 1024,
			["privateMemory"] = 256 * 1024 * 1024,
			["freeMemory"] = -1,
			["liveFightPanels"] = 1,
			["disposedFightPanels"] = 0,
			["panelCreatedCount"] = 1,
			["panelDisposeStartedCount"] = 0,
			["panelDisposedCount"] = 0,
			["liveStartMovies"] = 1,
			["disposedStartMovies"] = 0,
			["startMovieCreatedCount"] = 1,
			["startMovieDisposedCount"] = 0,
			["liveApplicationDomains"] = 1,
			["releasedApplicationDomains"] = 0,
			["applicationDomainCreatedCount"] = 1,
			["applicationDomainReleasedCount"] = 0,
			["livePreloadSessions"] = 1,
			["activePreloadSessions"] = 1,
			["disposedPreloadSessions"] = 0,
			["preloadInFlightCount"] = 1,
			["preloadPendingCount"] = 2,
			["preloadStartedCount"] = 1,
			["preloadCompletedCount"] = 0,
			["preloadDisposedWhileLoadingCount"] = 0,
			["currentResourceAgeMs"] = 50,
			["liveSkillEffectLoaders"] = 1,
			["skillEffectRequestInFlightCount"] = 1,
			["skillEffectRequestStartedCount"] = 2,
			["skillEffectRequestCompletedCount"] = 1,
			["skillEffectDisposedWhileLoadingCount"] = 0,
			["skillEffectCallbackAfterDisposeCount"] = 0,
			["activeAttackCount"] = 1,
			["oldestAttackAgeMs"] = 50,
			["attackMissingStrategyCount"] = 0,
			["attackWatchdogTimeoutCount"] = 0,
			["attackRecoveryErrorCount"] = 0,
			["traceDroppedCount"] = 0,
			["stageChildren"] = 4,
			["panelChildren"] = 12,
			["stageFrameRate"] = 50,
			["frameWindowMs"] = 30000,
			["frameSampleCount"] = 750,
			["longFrame50Count"] = 2,
			["longFrame100Count"] = 1,
			["longFrame200Count"] = 0,
			["maxFrameGapMs"] = 123,
			["futureField"] = true
		};
	}

	private static bool VerifyStrictValidation()
	{
		BattleSequencePlan valid = BattleSequenceValidator.Validate(new[]
		{
			Prelude(),
			Entry(),
			Request(16, "preFightLoad", new JObject { ["ul"] = "1,-2", ["msg"] = "1:1" }),
			Skill(0),
			Request(13, "1403", new JObject { ["pmId"] = 3478, ["reqPSId"] = 0, ["turn"] = 1 })
		});
		BattleSequencePlan attach = BattleSequenceValidator.Validate(new[] { Skill(0), Request(13, "1403", new JObject { ["pmId"] = 3478, ["reqPSId"] = 0, ["turn"] = 1 }) });
		BattleSequencePlan sameTurn = BattleSequenceValidator.Validate(new[]
		{
			Skill(0),
			Request(13, "1403", new JObject { ["pmId"] = 3478, ["reqPSId"] = 0, ["turn"] = 0 }),
			Request(13, "1404", new JObject { ["reqPSId"] = 0, ["turn"] = 1 })
		});
		return valid.StartsNewBattle && valid.SetupItems.Count == 3 &&
			valid.SetupItems[0].Kind == BattleSequenceItemKind.Prelude &&
			valid.SetupItems[2].Kind == BattleSequenceItemKind.FlashOwned &&
			valid.TurnGroups.Count == 2 && valid.TurnGroups[0].Turn == 0 && valid.TurnGroups[1].Turn == 1 &&
			!attach.StartsNewBattle && attach.SetupItems.Count == 0 && attach.TurnGroups.Count == 2 &&
			attach.TurnGroups.All(group => group.Items.All(item => item.Kind == BattleSequenceItemKind.TurnAction)) &&
			sameTurn.TurnGroups.Count == 2 && sameTurn.TurnGroups[0].Items.Count == 2 &&
			Throws<InvalidOperationException>(() => BattleSequenceValidator.Validate(new[]
			{
				Prelude(), Prelude(), Entry(), Skill(0)
			})) &&
			Throws<InvalidOperationException>(() => BattleSequenceValidator.Validate(new[]
			{
				Prelude(), Skill(0)
			})) &&
			Throws<InvalidOperationException>(() => BattleSequenceValidator.Validate(new[]
			{
				Request(16, "preFightLoad", new JObject { ["ul"] = "1,-2", ["msg"] = "1:1" }), Skill(0)
			})) &&
			Throws<InvalidOperationException>(() => BattleSequenceValidator.Validate(new[]
			{
				Request(42, "74_1", new JObject { ["eventId"] = 0 }), Entry(), Skill(0)
			})) &&
			Throws<InvalidOperationException>(() => BattleSequenceValidator.Validate(new[]
			{
				Entry(), Request(13, "1408", new JObject { ["auto"] = true })
			})) &&
			Throws<InvalidOperationException>(() => BattleSequenceValidator.Validate(new[]
			{
				Request(13, "1409", new JObject()), Entry(), Skill(0)
			})) &&
			Throws<InvalidOperationException>(() => BattleSequenceValidator.Validate(new[]
			{
				Request(15, "54_4", new JObject { ["nd"] = true, ["ap"] = true })
			})) &&
			Throws<InvalidOperationException>(() => BattleSequenceValidator.Validate(new[]
			{
				Entry(), Request(13, "1212", new JObject()), Skill(0)
			})) &&
			Throws<InvalidOperationException>(() => BattleSequenceValidator.Validate(new[]
			{
				Entry(), Entry(), Skill(0)
			})) &&
			Throws<InvalidOperationException>(() => BattleSequenceValidator.Validate(new[]
			{
				Skill(0), Skill(2)
			})) &&
			Throws<InvalidOperationException>(() => BattleSequenceValidator.Validate(new[]
			{
				Skill(0), Skill(1), Skill(0)
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
		const int BattleRouteId = -94617668;
		const int BattleUniqueId = 170735;
		page.InvokeHandler = (request, token) => Task.FromResult(
			PageBridgeResult.Success(new JObject
			{
				["version"] = 5,
				["active"] = true,
				["battleId"] = BattleRouteId,
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
				packets.PublishPacket(Receive("2401", new JObject
				{
					["br"] = BattleRouteId,
					["battleUniqueId"] = BattleUniqueId
				}));
			}
			else if (request.ExtensionId == 13)
			{
				packets.PublishPacket(Send(request));
				packets.PublishPacket(ServerReady(BattleRouteId));
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
			Prelude(),
			Entry(),
			Request(16, "preFightLoad", new JObject { ["ul"] = "1,-2", ["msg"] = "1:1" }),
			Skill(0),
			Request(13, "1403", new JObject { ["pmId"] = 3478, ["reqPSId"] = 0, ["turn"] = 1 })
		}), CancellationToken.None).GetAwaiter().GetResult();
		page.Dispose();
		packets.Dispose();
		return sender.Requests.Count == 4 &&
			sender.Requests[0].ExtensionId == 42 && sender.Requests[0].Command == "74_1" &&
			sender.Requests[1].ExtensionId == 15 &&
			sender.Requests[2].Command == "1401" && sender.Requests[3].Command == "1403" &&
			statuses.Contains(BattleSequenceStatus.WaitingForBattle) &&
			statuses.Contains(BattleSequenceStatus.WaitingForTurn) &&
			statuses.Contains(BattleSequenceStatus.SkippedFlashOwned) &&
			!statuses.Contains(BattleSequenceStatus.Stopped);
	}

	private static bool VerifyMixedPrefixProgression()
	{
		List<AolaSendRequest> requests = AolaSendRequestParser.ParseLines(string.Join("\r\n", new[]
		{
			"#send={\"id\":15,\"param\":{\"nd\":true,\"ap\":true},\"cmd\":\"54_4\"}|",
			"#send={\"id\":13,\"param\":{},\"cmd\":\"1212\"}|",
			"#send={\"id\":15,\"param\":{\"pb\":0,\"type\":99,\"index\":0,\"t\":0,\"isHurtFight\":false,\"si\":0,\"bb\":68,\"ddr\":0,\"lv\":5,\"handler\":\"TP230818\",\"dr\":0},\"cmd\":\"54_22\"}|",
			"#send={\"id\":16,\"param\":{\"msg\":\"94617668:1\",\"ul\":\"94617668,-1213203\"},\"cmd\":\"preFightLoad\"}|",
			"#send={\"id\":13,\"param\":{\"pmId\":3380,\"turn\":0,\"reqPSId\":0},\"cmd\":\"1403\"}|",
			"#send={\"id\":13,\"param\":{\"pmId\":2560,\"turn\":1,\"reqPSId\":0},\"cmd\":\"1403\"}|",
			"#send={\"id\":13,\"param\":{\"pmId\":2980,\"turn\":2,\"reqPSId\":0},\"cmd\":\"1403\"}|"
		}));
		BattleSequencePlan plan = BattleSequenceValidator.Validate(requests);
		if (plan.SetupItems.Count != 4 || plan.TurnGroups.Count != 3 ||
			plan.SetupItems[0].Kind != BattleSequenceItemKind.PrefixPassThrough ||
			plan.SetupItems[1].Kind != BattleSequenceItemKind.PrefixPassThrough)
		{
			return false;
		}

		ManualAolaPacketEventSource packets = new ManualAolaPacketEventSource();
		ManualPageBridge page = new ManualPageBridge();
		page.SetAvailability(PageBridgeAvailability.Ready);
		int turn = 0;
		int epoch = 1;
		const int BattleRouteId = -94617668;
		page.InvokeHandler = (request, token) => Task.FromResult(PageBridgeResult.Success(
			State(true, BattleRouteId, turn, true, epoch, false)));
		FakeSender sender = new FakeSender(request =>
		{
			if (request.Command == "54_22")
			{
				packets.PublishPacket(Receive("2303", new JObject()));
				packets.PublishPacket(Receive("2304", new JObject()));
				packets.PublishPacket(Receive("2401", new JObject
				{
					["br"] = BattleRouteId,
					["battleUniqueId"] = 170735
				}));
			}
			else if (request.Command == "1403")
			{
				packets.PublishPacket(Send(request));
				packets.PublishPacket(ServerReady(BattleRouteId));
				turn++;
				epoch++;
			}
		});
		BattleSequenceRunner runner = new BattleSequenceRunner(
			packets, sender, new BattleBridgeClient(page),
			TimeSpan.FromSeconds(1), TimeSpan.FromSeconds(1), TimeSpan.FromMilliseconds(1));
		List<BattleSequenceStatus> statuses = new List<BattleSequenceStatus>();
		runner.StatusChanged += update => statuses.Add(update.Status);
		runner.RunAsync(plan, CancellationToken.None).GetAwaiter().GetResult();
		page.Dispose();
		packets.Dispose();
		return sender.Requests.Select(request => request.Command).SequenceEqual(new[]
			{ "54_4", "1212", "54_22", "1403", "1403", "1403" }) &&
			statuses.IndexOf(BattleSequenceStatus.SkippedFlashOwned) >= 0 &&
			statuses.IndexOf(BattleSequenceStatus.SkippedFlashOwned) < statuses.IndexOf(BattleSequenceStatus.WaitingForBattle) &&
			!statuses.Contains(BattleSequenceStatus.Stopped);
	}

	private static bool VerifySameTurnPacing()
	{
		ManualAolaPacketEventSource packets = new ManualAolaPacketEventSource();
		ManualPageBridge page = new ManualPageBridge();
		page.SetAvailability(PageBridgeAvailability.Ready);
		int reads = 0;
		int turn = 0;
		int epoch = 7;
		const int BattleRouteId = -7654321;
		page.InvokeHandler = (request, token) =>
		{
			reads++;
			return Task.FromResult(PageBridgeResult.Success(State(true, BattleRouteId, turn, true, epoch, false)));
		};
		int actionCount = 0;
		List<int> readsAtSend = new List<int>();
		FakeSender sender = new FakeSender(request =>
		{
			readsAtSend.Add(reads);
			packets.PublishPacket(Send(request));
			actionCount++;
			packets.PublishPacket(ServerReady(BattleRouteId));
			if (actionCount == 1)
			{
				packets.PublishPacket(ServerResult("2413", 999));
			}
			else if (actionCount == 2)
			{
				packets.PublishPacket(ServerResult("2413", BattleRouteId));
				turn = 1;
				epoch++;
			}
			else if (actionCount == 4)
			{
				packets.PublishPacket(ServerResult("2413", BattleRouteId));
			}
		});
		BattleSequenceRunner runner = new BattleSequenceRunner(
			packets, sender, new BattleBridgeClient(page),
			TimeSpan.FromSeconds(1), TimeSpan.FromSeconds(1), TimeSpan.FromMilliseconds(1),
			TimeSpan.FromMilliseconds(5));
		List<BattleSequenceStatus> statuses = new List<BattleSequenceStatus>();
		runner.StatusChanged += update => statuses.Add(update.Status);
		runner.RunAsync(BattleSequenceValidator.Validate(new[]
		{
			Request(13, "1403", new JObject { ["pmId"] = 3130, ["reqPSId"] = 0, ["turn"] = 0 }),
			Request(13, "1403", new JObject { ["pmId"] = 3380, ["reqPSId"] = 0, ["turn"] = 0 }),
			Skill(1),
			Request(13, "1403", new JObject { ["pmId"] = 2540, ["reqPSId"] = 0, ["turn"] = 2 })
		}), CancellationToken.None).GetAwaiter().GetResult();
		page.Dispose();
		packets.Dispose();
		return sender.Requests.Count == 4 && readsAtSend.Count == 4 &&
			readsAtSend[1] > readsAtSend[0] && readsAtSend[2] > readsAtSend[1] &&
			readsAtSend[3] > readsAtSend[2] &&
			statuses.Count(status => status == BattleSequenceStatus.WaitingForTurn) >= 4 &&
			!statuses.Contains(BattleSequenceStatus.Stopped);
	}

	private static bool VerifyServerReadyIsRequired()
	{
		ManualAolaPacketEventSource packets = new ManualAolaPacketEventSource();
		ManualPageBridge page = ReadyBattlePage(1357, 0, 1);
		FakeSender sender = new FakeSender(request =>
		{
			packets.PublishPacket(Send(request));
			packets.PublishPacket(ServerReady(999));
		});
		BattleSequenceRunner runner = new BattleSequenceRunner(
			packets, sender, new BattleBridgeClient(page),
			TimeSpan.FromMilliseconds(25), TimeSpan.FromMilliseconds(25), TimeSpan.FromMilliseconds(1),
			TimeSpan.FromMilliseconds(5));
		int stopped = 0;
		runner.StatusChanged += update => { if (update.Status == BattleSequenceStatus.Stopped) stopped++; };
		runner.RunAsync(BattleSequenceValidator.Validate(new[] { Skill(0), Skill(0) }), CancellationToken.None)
			.GetAwaiter().GetResult();
		page.Dispose();
		packets.Dispose();
		return sender.Requests.Count == 1 && stopped == 1;
	}

	private static bool VerifyDoesNotAdvanceWhileFlashTurnStaysCurrent()
	{
		ManualAolaPacketEventSource packets = new ManualAolaPacketEventSource();
		ManualPageBridge page = new ManualPageBridge();
		page.SetAvailability(PageBridgeAvailability.Ready);
		int epoch = 1;
		page.InvokeHandler = (request, token) => Task.FromResult(
			PageBridgeResult.Success(State(true, 2468, 0, true, epoch, false)));
		FakeSender sender = new FakeSender(request =>
		{
			packets.PublishPacket(Send(request));
			packets.PublishPacket(ServerReady(2468));
			epoch++;
		});
		BattleSequenceRunner runner = new BattleSequenceRunner(
			packets, sender, new BattleBridgeClient(page),
			TimeSpan.FromSeconds(1), TimeSpan.FromSeconds(1), TimeSpan.FromMilliseconds(1));
		int stopped = 0;
		runner.StatusChanged += update => { if (update.Status == BattleSequenceStatus.Stopped) stopped++; };
		runner.RunAsync(BattleSequenceValidator.Validate(new[]
		{
			Skill(0), Skill(0), Skill(0), Skill(1)
		}), CancellationToken.None).GetAwaiter().GetResult();
		page.Dispose();
		packets.Dispose();
		return sender.Requests.Count == 3 && sender.Requests.All(request =>
			JObject.Parse(request.ParametersJson).Value<int>("turn") == 0) && stopped == 1;
	}

	private static bool VerifyPrefixFailureStopsBeforeBattle()
	{
		ManualAolaPacketEventSource packets = new ManualAolaPacketEventSource();
		ManualPageBridge page = new ManualPageBridge();
		page.SetAvailability(PageBridgeAvailability.Ready);
		int reads = 0;
		page.InvokeHandler = (request, token) =>
		{
			reads++;
			return Task.FromResult(PageBridgeResult.Success(State(true, 123, 0, true, 1, false)));
		};
		FakeSender sender = new FakeSender(null) { FailAtIndex = 0 };
		BattleSequenceRunner runner = new BattleSequenceRunner(
			packets, sender, new BattleBridgeClient(page),
			TimeSpan.FromMilliseconds(50), TimeSpan.FromMilliseconds(50), TimeSpan.FromMilliseconds(1));
		int stopped = 0;
		runner.StatusChanged += update => { if (update.Status == BattleSequenceStatus.Stopped) stopped++; };
		runner.RunAsync(BattleSequenceValidator.Validate(new[]
		{
			Request(15, "54_4", new JObject { ["nd"] = true, ["ap"] = true }), Skill(0)
		}), CancellationToken.None).GetAwaiter().GetResult();
		page.Dispose();
		packets.Dispose();
		return sender.Requests.Count == 1 && reads == 0 && stopped == 1;
	}

	private static bool VerifyGroupPartialFailureDoesNotRetry()
	{
		ManualAolaPacketEventSource packets = new ManualAolaPacketEventSource();
		ManualPageBridge page = new ManualPageBridge();
		page.SetAvailability(PageBridgeAvailability.Ready);
		int epoch = 1;
		page.InvokeHandler = (request, token) => Task.FromResult(
			PageBridgeResult.Success(State(true, 321, 0, true, epoch, false)));
		FakeSender sender = new FakeSender(request =>
		{
			packets.PublishPacket(Send(request));
			packets.PublishPacket(ServerReady(321));
			epoch++;
		}) { FailAtIndex = 1 };
		BattleSequenceRunner runner = new BattleSequenceRunner(
			packets, sender, new BattleBridgeClient(page),
			TimeSpan.FromMilliseconds(50), TimeSpan.FromMilliseconds(50), TimeSpan.FromMilliseconds(1));
		string stopMessage = null;
		runner.StatusChanged += update => { if (update.Status == BattleSequenceStatus.Stopped) stopMessage = update.Message; };
		runner.RunAsync(BattleSequenceValidator.Validate(new[] { Skill(0), Skill(0) }), CancellationToken.None)
			.GetAwaiter().GetResult();
		page.Dispose();
		packets.Dispose();
		return sender.Requests.Count == 2 && stopMessage != null && stopMessage.Contains("已提交 1 条");
	}

	private static bool VerifySignatureOrderMismatchStopsGroup()
	{
		AolaSendRequest first = Skill(0);
		AolaSendRequest second = Request(13, "1403", new JObject { ["pmId"] = 3478, ["reqPSId"] = 0, ["turn"] = 0 });
		ManualAolaPacketEventSource packets = new ManualAolaPacketEventSource();
		ManualPageBridge page = ReadyBattlePage(654, 0, 1);
		FakeSender sender = new FakeSender(request => packets.PublishPacket(Send(second)));
		BattleSequenceRunner runner = new BattleSequenceRunner(
			packets, sender, new BattleBridgeClient(page),
			TimeSpan.FromMilliseconds(50), TimeSpan.FromMilliseconds(50), TimeSpan.FromMilliseconds(1));
		int stopped = 0;
		runner.StatusChanged += update => { if (update.Status == BattleSequenceStatus.Stopped) stopped++; };
		runner.RunAsync(BattleSequenceValidator.Validate(new[] { first, second }), CancellationToken.None)
			.GetAwaiter().GetResult();
		page.Dispose();
		packets.Dispose();
		return sender.Requests.Count == 1 && stopped == 1;
	}

	private static bool VerifyNextTurnBridgeFailureStops()
	{
		ManualAolaPacketEventSource packets = new ManualAolaPacketEventSource();
		ManualPageBridge page = new ManualPageBridge();
		page.SetAvailability(PageBridgeAvailability.Ready);
		int reads = 0;
		page.InvokeHandler = (request, token) => reads++ == 0
			? Task.FromResult(PageBridgeResult.Success(State(true, 987, 0, true, 1, false)))
			: Task.FromResult(PageBridgeResult.Failure(PageBridgeFailureKind.InvocationFailed, "bridge unavailable"));
		FakeSender sender = new FakeSender(request => packets.PublishPacket(Send(request)));
		BattleSequenceRunner runner = new BattleSequenceRunner(
			packets, sender, new BattleBridgeClient(page),
			TimeSpan.FromMilliseconds(50), TimeSpan.FromMilliseconds(50), TimeSpan.FromMilliseconds(1));
		int stopped = 0;
		runner.StatusChanged += update => { if (update.Status == BattleSequenceStatus.Stopped) stopped++; };
		runner.RunAsync(BattleSequenceValidator.Validate(new[] { Skill(0), Skill(1) }), CancellationToken.None)
			.GetAwaiter().GetResult();
		page.Dispose();
		packets.Dispose();
		return sender.Requests.Count == 1 && stopped == 1;
	}

	private static bool VerifyCurrentBattleAttachment()
	{
		ManualAolaPacketEventSource packets = new ManualAolaPacketEventSource();
		ManualPageBridge page = new ManualPageBridge();
		page.SetAvailability(PageBridgeAvailability.Ready);
		int reads = 0;
		int turn = 0;
		int epoch = 7;
		const int BattleRouteId = -123456;
		page.InvokeHandler = (request, token) => Task.FromResult(
			PageBridgeResult.Success(new JObject
			{
				["version"] = 5,
				["active"] = true,
				["battleId"] = BattleRouteId,
				["turn"] = turn,
				["inputReady"] = ++reads >= 3,
				["readyEpoch"] = epoch,
				["ended"] = false
			}));
		FakeSender sender = new FakeSender(request =>
		{
			if (request.ExtensionId == 13)
			{
				packets.PublishPacket(Send(request));
				packets.PublishPacket(ServerReady(BattleRouteId));
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
			Skill(0),
			Request(13, "1403", new JObject { ["pmId"] = 3478, ["reqPSId"] = 0, ["turn"] = 1 })
		}), CancellationToken.None).GetAwaiter().GetResult();
		page.Dispose();
		packets.Dispose();
		return sender.Requests.Count == 2 &&
			sender.Requests.All(request => request.ExtensionId == 13) &&
			sender.Requests[0].Command == "1401" && sender.Requests[1].Command == "1403" &&
			statuses.Contains(BattleSequenceStatus.WaitingForBattle) &&
			statuses.Contains(BattleSequenceStatus.WaitingForTurn) &&
			!statuses.Contains(BattleSequenceStatus.Stopped) && reads >= 4;
	}

	private static bool VerifyAttachmentStopsOnInvalidState()
	{
		return VerifyAttachmentFailure(_ => State(false, 0, 0, false, 0, false)) &&
			VerifyAttachmentFailure(_ => State(true, 0, 0, true, 1, false)) &&
			VerifyAttachmentFailure(_ => State(true, 123, 0, true, 1, true)) &&
			VerifyAttachmentFailure(_ => State(true, 123, 1, true, 1, false)) &&
			VerifyAttachmentFailure(index => index == 0
				? State(true, 123, 0, false, 1, false)
				: State(true, 456, 0, true, 2, false)) &&
			VerifyAttachmentFailure(_ => State(true, 123, 0, true, 1, false), packets =>
				packets.PublishPacket(Send(Skill(0))));
	}

	private static bool VerifyAttachmentFailure(
		Func<int, JObject> stateFactory,
		Action<ManualAolaPacketEventSource> onRead = null)
	{
		ManualAolaPacketEventSource packets = new ManualAolaPacketEventSource();
		ManualPageBridge page = new ManualPageBridge();
		page.SetAvailability(PageBridgeAvailability.Ready);
		int reads = 0;
		page.InvokeHandler = (request, token) =>
		{
			onRead?.Invoke(packets);
			return Task.FromResult(PageBridgeResult.Success(stateFactory(reads++)));
		};
		FakeSender sender = new FakeSender(null);
		BattleSequenceRunner runner = new BattleSequenceRunner(
			packets,
			sender,
			new BattleBridgeClient(page),
			TimeSpan.FromMilliseconds(50),
			TimeSpan.FromMilliseconds(50),
			TimeSpan.FromMilliseconds(1));
		int stopped = 0;
		runner.StatusChanged += update => { if (update.Status == BattleSequenceStatus.Stopped) stopped++; };
		runner.RunAsync(BattleSequenceValidator.Validate(new[] { Skill(0) }), CancellationToken.None)
			.GetAwaiter().GetResult();
		page.Dispose();
		packets.Dispose();
		return sender.Requests.Count == 0 && stopped == 1;
	}

	private static bool VerifyAttachmentBridgeFailure()
	{
		ManualAolaPacketEventSource packets = new ManualAolaPacketEventSource();
		ManualPageBridge page = new ManualPageBridge();
		page.SetAvailability(PageBridgeAvailability.Ready);
		page.InvokeHandler = (request, token) =>
			Task.FromResult(PageBridgeResult.Failure(PageBridgeFailureKind.InvocationFailed, "bridge unavailable"));
		FakeSender sender = new FakeSender(null);
		BattleSequenceRunner runner = new BattleSequenceRunner(
			packets,
			sender,
			new BattleBridgeClient(page),
			TimeSpan.FromMilliseconds(50),
			TimeSpan.FromMilliseconds(50),
			TimeSpan.FromMilliseconds(1));
		int stopped = 0;
		runner.StatusChanged += update => { if (update.Status == BattleSequenceStatus.Stopped) stopped++; };
		runner.RunAsync(BattleSequenceValidator.Validate(new[] { Skill(0) }), CancellationToken.None)
			.GetAwaiter().GetResult();
		page.Dispose();
		packets.Dispose();
		return sender.Requests.Count == 0 && stopped == 1;
	}

	private static JObject State(bool active, int battleId, int turn, bool inputReady, int readyEpoch, bool ended) => new JObject
	{
		["version"] = 5,
		["active"] = active,
		["battleId"] = battleId,
		["turn"] = turn,
		["inputReady"] = inputReady,
		["readyEpoch"] = readyEpoch,
		["ended"] = ended
	};

	private static ManualPageBridge ReadyBattlePage(int battleId, int turn, int readyEpoch)
	{
		ManualPageBridge page = new ManualPageBridge();
		page.SetAvailability(PageBridgeAvailability.Ready);
		page.InvokeHandler = (request, token) => Task.FromResult(
			PageBridgeResult.Success(State(true, battleId, turn, true, readyEpoch, false)));
		return page;
	}

	private static bool VerifyTimeoutDoesNotRetry()
	{
		ManualAolaPacketEventSource packets = new ManualAolaPacketEventSource();
		ManualPageBridge page = new ManualPageBridge();
		page.SetAvailability(PageBridgeAvailability.Ready);
		page.InvokeHandler = (request, token) => Task.FromResult(PageBridgeResult.Success(new JObject
		{
			["version"] = 5,
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

	private static AolaSendRequest Prelude() => Request(42, "74_1", new JObject
	{
		["eventId"] = 41751
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

	private static AolaPacketEvent ServerReady(int battleRouteId) => Receive("2405", new JObject
	{
		["reqId"] = Math.Abs((long)battleRouteId)
	});

	private static AolaPacketEvent ServerResult(string command, int battleRouteId) => Receive(command, new JObject
	{
		["reqId"] = Math.Abs((long)battleRouteId)
	});

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
		public int FailAtIndex { get; set; } = -1;
		public event Action<AolaCommandSendUpdate> StatusChanged;

		public Task<AolaCommandSendUpdate> SendAsync(AolaSendRequest request, CancellationToken cancellationToken)
		{
			int requestIndex = Requests.Count;
			Requests.Add(request);
			bool failed = requestIndex == FailAtIndex;
			if (!failed) _onSend?.Invoke(request);
			AolaCommandSendUpdate update = new AolaCommandSendUpdate(
				Guid.NewGuid().ToString("N"), request.ExtensionId, request.Command,
				failed ? AolaCommandSendStatus.SubmissionFailed : AolaCommandSendStatus.SubmittedToFlash,
				failed ? "failed" : "submitted");
			StatusChanged?.Invoke(update);
			return Task.FromResult(update);
		}
	}
}
