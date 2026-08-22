using System;
using AolaLoader;
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
			&& VerifyTrackerPacketSource();
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
