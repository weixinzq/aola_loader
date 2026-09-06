using System;
using System.Collections.Generic;

namespace AolaLoader.Features.Battle.State;

internal sealed class AolaBattleSnapshot
{
	public bool HasBattle { get; set; }

	public bool IsEnded { get; set; }

	public string BattleUniqueId { get; set; }

	public long? SelfPmmId { get; set; }

	public string LastCommand { get; set; }

	public string LastDescription { get; set; }

	public DateTime LastUpdatedUtc { get; set; }

	public List<AolaBattleSideSnapshot> Sides { get; } = new List<AolaBattleSideSnapshot>();

	public AolaBattleSnapshot Clone()
	{
		AolaBattleSnapshot clone = new AolaBattleSnapshot
		{
			HasBattle = HasBattle,
			IsEnded = IsEnded,
			BattleUniqueId = BattleUniqueId,
			SelfPmmId = SelfPmmId,
			LastCommand = LastCommand,
			LastDescription = LastDescription,
			LastUpdatedUtc = LastUpdatedUtc
		};
		foreach (AolaBattleSideSnapshot side in Sides)
		{
			clone.Sides.Add(side.Clone());
		}
		return clone;
	}
}

internal sealed class AolaBattleSideSnapshot
{
	public long PmmId { get; set; }

	public string SideName { get; set; }

	public long? LastHpChange { get; set; }

	public string LastHpChangeDetails { get; set; }

	public string LastHpChangeType { get; set; }

	public List<AolaBattlePetSnapshot> Pets { get; } = new List<AolaBattlePetSnapshot>();

	public AolaBattleSideSnapshot Clone()
	{
		AolaBattleSideSnapshot clone = new AolaBattleSideSnapshot
		{
			PmmId = PmmId,
			SideName = SideName,
			LastHpChange = LastHpChange,
			LastHpChangeDetails = LastHpChangeDetails,
			LastHpChangeType = LastHpChangeType
		};
		foreach (AolaBattlePetSnapshot pet in Pets)
		{
			clone.Pets.Add(pet.Clone());
		}
		return clone;
	}
}

internal sealed class AolaBattlePetSnapshot
{
	public Dictionary<string, BattleConfigurationGroup> Loadout { get; } = new Dictionary<string, BattleConfigurationGroup>(StringComparer.Ordinal);

	public int? BattleSlotId { get; set; }

	public long UniqueId { get; set; }

	public int PetId { get; set; }

	public int RaceId { get; set; }

	public int ViewId { get; set; }

	public string Name { get; set; }

	public string Nickname { get; set; }

	public int? Level { get; set; }

	public string Character { get; set; }

	public long? CurrentHp { get; set; }

	public long? MaximumHp { get; set; }

	public List<AolaBattleAbilitySnapshot> Abilities { get; } = new List<AolaBattleAbilitySnapshot>();

	public List<AolaBattleSkillSnapshot> Skills { get; } = new List<AolaBattleSkillSnapshot>();

	public AolaBattlePetSnapshot Clone()
	{
		AolaBattlePetSnapshot clone = new AolaBattlePetSnapshot
		{
			BattleSlotId = BattleSlotId,
			UniqueId = UniqueId,
			PetId = PetId,
			RaceId = RaceId,
			ViewId = ViewId,
			Name = Name,
			Nickname = Nickname,
			Level = Level,
			Character = Character,
			CurrentHp = CurrentHp,
			MaximumHp = MaximumHp
		};
		foreach (AolaBattleAbilitySnapshot ability in Abilities)
		{
			clone.Abilities.Add(ability.Clone());
		}
		foreach (var pair in Loadout) clone.Loadout[pair.Key] = pair.Value.Clone();
		foreach (AolaBattleSkillSnapshot skill in Skills)
		{
			clone.Skills.Add(skill.Clone());
		}
		return clone;
	}
}

internal sealed class AolaBattleAbilitySnapshot
{
	public string FieldName { get; set; }

	public string DisplayName { get; set; }

	public string RawValue { get; set; }

	public List<long> Segments { get; } = new List<long>();

	public long Total { get; set; }

	public AolaBattleAbilitySnapshot Clone()
	{
		AolaBattleAbilitySnapshot clone = new AolaBattleAbilitySnapshot
		{
			FieldName = FieldName,
			DisplayName = DisplayName,
			RawValue = RawValue,
			Total = Total
		};
		clone.Segments.AddRange(Segments);
		return clone;
	}
}

internal sealed class AolaBattleSkillSnapshot
{
	public int Id { get; set; }

	public string Name { get; set; }

	public string PowerPoints { get; set; }

	public int? Cooldown { get; set; }

	public AolaBattleSkillSnapshot Clone()
	{
		return new AolaBattleSkillSnapshot
		{
			Id = Id,
			Name = Name,
			PowerPoints = PowerPoints,
			Cooldown = Cooldown
		};
	}
}

internal sealed class AolaBattlePacketUpdate
{
	public bool StartsNewBattle { get; set; }

	public bool EndsBattle { get; set; }

	public string BattleUniqueId { get; set; }

	public long? SelfPmmId { get; set; }

	public string Command { get; set; }

	public string Description { get; set; }

	public DateTime TimestampUtc { get; set; }

	public List<AolaBattleSideSnapshot> Sides { get; } = new List<AolaBattleSideSnapshot>();
}
