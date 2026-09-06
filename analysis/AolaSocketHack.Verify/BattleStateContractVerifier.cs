using System;
using System.IO;
using System.Linq;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using AolaLoader.Features.Battle.State;
using AolaLoader.Features.Battle.State.Testing;
using AolaLoader.PacketHost.Testing;
using AolaSocketHack.Contracts;

namespace AolaSocketHack.Verify;

internal static class BattleStateContractVerifier
{
	public static bool Verify()
	{
		AolaBattleSnapshot initial = CreateSnapshot("2303", 480, 9);
		using ManualBattleStateSource source = new ManualBattleStateSource(initial);

		initial.Sides[0].Pets[0].CurrentHp = 1;
		AolaBattleSnapshot firstRead = source.CurrentSnapshot;
		if (firstRead.Sides[0].Pets[0].CurrentHp != 480)
		{
			return false;
		}
		firstRead.Sides[0].Pets.Clear();
		if (source.CurrentSnapshot.Sides[0].Pets.Count != 2)
		{
			return false;
		}

		bool secondObserverCalled = false;
		source.SnapshotChanged += snapshot =>
		{
			snapshot.Sides[0].Pets[0].CurrentHp = 0;
			throw new InvalidOperationException("observer failure");
		};
		source.SnapshotChanged += snapshot =>
		{
			secondObserverCalled = snapshot.Sides[0].Pets[0].CurrentHp == 321
				&& snapshot.Sides[0].Pets.Count == 2
				&& snapshot.Sides[0].Pets[1].BattleSlotId == null
				&& snapshot.Sides[0].Pets[0].Abilities.Count == 6
				&& snapshot.Sides[0].Pets[0].Skills[0].PowerPoints == "7/10"
				&& snapshot.Sides[0].Pets[0].Skills[0].Cooldown == 2;
		};

		AolaBattleSnapshot update = CreateSnapshot("2401", 321, 7);
		source.PublishSnapshot(update);
		update.Sides[0].Pets[0].CurrentHp = 2;
		if (!secondObserverCalled || source.CurrentSnapshot.Sides[0].Pets[0].CurrentHp != 321)
		{
			return false;
		}

		source.Dispose();
		return ThrowsDisposed(() => _ = source.CurrentSnapshot)
			&& ThrowsDisposed(() => source.PublishSnapshot(update))
			&& ThrowsDisposed(() => source.SnapshotChanged += _ => { })
			&& VerifyTrackerPacketSource()
			&& VerifyOwnershipAndLoadout()
			&& SystemMessageContractVerifier.VerifyConnectionIdentity();
	}

	private static bool VerifyOwnershipAndLoadout()
	{
		foreach (long opponent in new long[] { 2002, -2002 })
		{
			using var packets = new ManualAolaPacketEventSource();
			using var tracker = new AolaBattleStateTracker(packets);
			JObject Pet(long uqi, bool configuration) => JObject.Parse("{pmSView:{uqi:" + uqi + ",r:5393,nm:'pet',c0:100,s0:100" +
				(configuration ? ",pcp:'<p soc=\"10:1#0:0\" tt=\"99;2;1:3\" ctk=\"1_0\"/>'},eqp:[{eq:'9,24195,0,0,12,0,0,12,0,0,12,0',l:1}]" : "}") + "}");
			JObject Side(long owner, params JObject[] pets) => new JObject { ["battleView"] = new JObject { ["pmmId"] = owner, ["slotId"] = 0, ["pmList"] = new JArray(pets) } };
			DateTime timestamp = DateTime.UtcNow;
			void Publish(string command, JObject value, bool identityKnown = true) => packets.PublishPacket(new AolaPacketEvent { Direction = "接收", Command = command, ConnectionPlayerId = identityKnown ? 1001 : (long?)null, ParametersJson = value.ToString(Formatting.None), TimestampUtc = timestamp = timestamp.AddSeconds(30) });
			Publish("2401", new JObject { ["br"] = 11822, ["pmmList"] = new JArray(Side(opponent, Pet(2, false))) }, false);
			if (tracker.CurrentSnapshot.Sides.Any(side => side.SideName == "敌方")) return false;
			Publish("2303", new JObject { ["battleId"] = 11822, ["pmmList"] = new JArray(Side(1001, Pet(1, false))) });
			Publish("2304", new JObject { ["b"] = new JArray(Side(opponent, Pet(2, true), Pet(3, true))) });
			Publish("2401", new JObject { ["br"] = 11822, ["pmmList"] = new JArray(Side(1001, Pet(1, false)), Side(opponent, Pet(2, false))) });
			Publish("2411", new JObject { ["b"] = new JArray(Side(opponent, Pet(3, false))) });
			var snapshot = tracker.CurrentSnapshot;
			var enemy = snapshot.Sides.Single(side => side.SideName == "敌方");
			if (snapshot.SelfPmmId != 1001 || enemy.Pets.Count != 2 || enemy.Pets[0].UniqueId != 2 || enemy.Pets[1].UniqueId != 3) return false;
			var loadout = enemy.Pets[0].Loadout;
			if (loadout["equipment"].Items[0].Id != 24195 || loadout["equipment"].Items[0].InstanceId != 9 || loadout["soul-card"].Items[0].Id != 1 || loadout["soul-artifact"].Items[0].Id != 2 || loadout["crystal-key"].Items[0].Id != 1) return false;
			var empty = Pet(2, false); empty["eqp"] = new JArray();
			Publish("2411", new JObject { ["b"] = new JArray(Side(opponent, empty)) });
			if (tracker.CurrentSnapshot.Sides.Single(side => side.SideName == "敌方").Pets[0].Loadout["equipment"].State != BattleConfigurationState.Empty) return false;
			var invalid = Pet(2, false); invalid["pmSView"]["pcp"] = "<broken";
			Publish("2411", new JObject { ["b"] = new JArray(Side(opponent, invalid)) });
			if (tracker.CurrentSnapshot.Sides.Single(side => side.SideName == "敌方").Pets[0].Loadout["soul-card"].State != BattleConfigurationState.Invalid) return false;
			Publish("2303", new JObject { ["pmmList"] = new JArray(Side(opponent, Pet(2, true), Pet(3, true)), Side(1001, Pet(1, false))) });
			Publish("2401", new JObject { ["pmmList"] = new JArray(Side(1001, Pet(1, false)), Side(opponent, Pet(2, false))) });
			if (tracker.CurrentSnapshot.SelfPmmId != 1001 || tracker.CurrentSnapshot.Sides.Single(side => side.SideName == "敌方").Pets.Count != 2) return false;
		}
		return true;
	}

	public static bool VerifySample(string path, long selfPmmId = 94617668, long enemyPmmId = 241627493)
	{
		using var packets = new ManualAolaPacketEventSource();
		using var tracker = new AolaBattleStateTracker(packets);
		using var stream = File.OpenText(path);
		using var reader = new JsonTextReader(stream) { SupportMultipleContent = true };
		long[] initialOrder = null;
		string[][] initialCategories = null;
		int records = 0;
		int battles = 0;
		while (reader.Read())
		{
			var record = JObject.Load(reader);
			if ((string)record["cmd"] == "2303") { initialOrder = null; initialCategories = null; battles++; }
			packets.PublishPacket(new AolaPacketEvent { Direction = (string)record["direction"], Command = (string)record["cmd"], ConnectionPlayerId = (long?)record["connectionPlayerId"] ?? selfPmmId, ParametersJson = record["param"].ToString(Formatting.None), TimestampUtc = DateTime.UtcNow });
			records++;
			var snapshot = tracker.CurrentSnapshot;
			var enemy = snapshot.Sides.SingleOrDefault(side => side.SideName == "敌方");
			if (enemy == null)
			{
				if ((string)record["cmd"] == "2401") return false;
				continue;
			}
			if (snapshot.SelfPmmId != selfPmmId || enemy.PmmId != enemyPmmId || enemy.Pets.Count != 6)
			{
				Console.WriteLine("Roster mismatch at record " + records + ": count=" + enemy.Pets.Count);
				return false;
			}
			long[] order = enemy.Pets.Select(pet => pet.UniqueId).ToArray();
			if (initialOrder == null)
			{
				initialOrder = order;
				initialCategories = enemy.Pets.Select(pet => pet.Loadout.Keys.ToArray()).ToArray();
			}
			if (!initialOrder.SequenceEqual(order) || enemy.Pets.Where((pet, index) => initialCategories[index].Any(category => !pet.Loadout.ContainsKey(category))).Any())
			{
				Console.WriteLine("Order/loadout mismatch at record " + records + ": order=" + initialOrder.SequenceEqual(order) + ", categories=" + string.Join(",", enemy.Pets.Select(pet => pet.Loadout.Count)));
				return false;
			}
		}
		Console.WriteLine("Battle sample: records=" + records + ", battles=" + battles + ", enemy=" + (initialOrder?.Length ?? 0));
		return records > 0 && initialOrder?.Length == 6 && tracker.CurrentSnapshot.IsEnded;
	}

	private static bool VerifyTrackerPacketSource()
	{
		ManualAolaPacketEventSource packets = new ManualAolaPacketEventSource();
		AolaBattleStateTracker tracker = new AolaBattleStateTracker(packets);
		int changes = 0;
		tracker.SnapshotChanged += snapshot =>
		{
			if (snapshot.LastCommand == "2404" && snapshot.IsEnded)
			{
				changes++;
			}
		};
		packets.PublishPacket(new AolaPacketEvent
		{
			TimestampUtc = DateTime.UtcNow,
			Direction = "发送",
			Command = "2404",
			ParametersJson = "{}"
		});
		packets.PublishPacket(new AolaPacketEvent
		{
			TimestampUtc = DateTime.UtcNow,
			Direction = "接收",
			Command = "2404",
			ParametersJson = "{}"
		});
		if (changes != 1 || tracker.CurrentSnapshot.LastCommand != "2404" ||
			!tracker.CurrentSnapshot.IsEnded)
		{
			tracker.Dispose();
			packets.Dispose();
			return false;
		}

		tracker.Dispose();
		packets.PublishPacket(new AolaPacketEvent
		{
			TimestampUtc = DateTime.UtcNow,
			Direction = "接收",
			Command = "2404",
			ParametersJson = "{}"
		});
		packets.Dispose();
		return changes == 1;
	}

	private static AolaBattleSnapshot CreateSnapshot(string command, long hp, int remainingPowerPoints)
	{
		AolaBattleSnapshot snapshot = new AolaBattleSnapshot
		{
			HasBattle = true,
			BattleUniqueId = "battle-contract-test",
			SelfPmmId = 1001,
			LastCommand = command,
			LastDescription = "contract snapshot",
			LastUpdatedUtc = new DateTime(2026, 8, 22, 0, 0, 0, DateTimeKind.Utc)
		};
		AolaBattleSideSnapshot side = new AolaBattleSideSnapshot { PmmId = 1001, SideName = "self" };
		AolaBattlePetSnapshot activePet = new AolaBattlePetSnapshot
		{
			BattleSlotId = 0,
			UniqueId = 70001,
			PetId = 101,
			RaceId = 11,
			ViewId = 201,
			Name = "active",
			CurrentHp = hp,
			MaximumHp = 500
		};
		string[] abilityNames = { "Attack", "Defense", "SpecialAttack", "SpecialDefense", "Speed", "MaximumHp" };
		foreach (string abilityName in abilityNames)
		{
			AolaBattleAbilitySnapshot ability = new AolaBattleAbilitySnapshot
			{
				FieldName = abilityName,
				DisplayName = abilityName,
				RawValue = "100+20",
				Total = 120
			};
			ability.Segments.Add(100);
			ability.Segments.Add(20);
			activePet.Abilities.Add(ability);
		}
		activePet.Skills.Add(new AolaBattleSkillSnapshot
		{
			Id = 3001,
			Name = "skill",
			PowerPoints = remainingPowerPoints + "/10",
			Cooldown = 2
		});
		side.Pets.Add(activePet);
		side.Pets.Add(new AolaBattlePetSnapshot
		{
			BattleSlotId = null,
			UniqueId = 70002,
			PetId = 102,
			RaceId = 12,
			ViewId = 202,
			Name = "reserve",
			CurrentHp = 400,
			MaximumHp = 400
		});
		snapshot.Sides.Add(side);
		return snapshot;
	}

	private static bool ThrowsDisposed(Action action)
	{
		try
		{
			action();
			return false;
		}
		catch (ObjectDisposedException)
		{
			return true;
		}
	}
}
