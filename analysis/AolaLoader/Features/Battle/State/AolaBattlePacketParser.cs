using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using AolaSocketHack.Contracts;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace AolaLoader.Features.Battle.State;

internal static class AolaBattlePacketParser
{
	private static readonly HashSet<string> BattleCommands = new HashSet<string>(StringComparer.Ordinal)
	{
		"2303",
		"2304",
		"2401",
		"2426",
		"2411",
		"2404",
		"2309"
	};

	private static readonly string[] AbilityNames = { "生命", "攻击", "防御", "特攻", "特防", "速度" };

	public static bool TryParse(AolaPacketEvent packet, out AolaBattlePacketUpdate update)
	{
		update = null;
		if (packet == null || !string.Equals(packet.Direction, "接收", StringComparison.Ordinal) ||
			string.IsNullOrWhiteSpace(packet.Command) || !BattleCommands.Contains(packet.Command))
		{
			return false;
		}

		JObject parameters;
		try
		{
			parameters = string.IsNullOrWhiteSpace(packet.ParametersJson)
				? new JObject()
				: JObject.Parse(packet.ParametersJson);
		}
		catch (JsonException)
		{
			return false;
		}

		update = new AolaBattlePacketUpdate
		{
			StartsNewBattle = string.Equals(packet.Command, "2401", StringComparison.Ordinal),
			EndsBattle = string.Equals(packet.Command, "2404", StringComparison.Ordinal) ||
				string.Equals(packet.Command, "2309", StringComparison.Ordinal),
			BattleUniqueId = ReadText(parameters["battleUniqueId"]),
			SelfPmmId = packet.ConnectionPlayerId,
			Command = packet.Command,
			Description = ReadDescription(packet.Command, parameters),
			TimestampUtc = packet.TimestampUtc
		};

		Dictionary<long, AolaBattleSideSnapshot> sides = new Dictionary<long, AolaBattleSideSnapshot>();
		foreach (BattleViewEntry entry in EnumerateBattleViews(parameters))
		{
			AolaBattleSideSnapshot side = ParseSide(entry.View, entry.Container);
			if (side != null)
			{
				if (sides.TryGetValue(side.PmmId, out AolaBattleSideSnapshot existing))
				{
					MergePacketSide(existing, side);
				}
				else
				{
					sides[side.PmmId] = side;
				}
			}
		}
		update.Sides.AddRange(sides.Values);
		if (update.SelfPmmId.HasValue && update.Sides.Count <= 2 &&
			(packet.Command == "2303" || packet.Command == "2304" || packet.Command == "2401"))
		{
			foreach (AolaBattleSideSnapshot side in update.Sides)
				side.SideName = side.PmmId == update.SelfPmmId.Value ? "己方" : "敌方";
		}
		return true;
	}

	private static IEnumerable<BattleViewEntry> EnumerateBattleViews(JObject parameters)
	{
		if (parameters["battleView"] is JObject directView)
		{
			yield return new BattleViewEntry(directView, parameters);
		}

		if (parameters["b"] is JArray battleItems)
		{
			foreach (JObject item in battleItems.OfType<JObject>())
			{
				if (item["battleView"] is JObject view)
				{
					yield return new BattleViewEntry(view, item);
				}
			}
		}

		if (parameters["pmmList"] is JArray participants)
		{
			foreach (JObject item in participants.OfType<JObject>())
			{
				if (item["battleView"] is JObject view)
				{
					yield return new BattleViewEntry(view, item);
				}
			}
		}
	}

	private static AolaBattleSideSnapshot ParseSide(JObject battleView, JObject container)
	{
		long? pmmId = ReadLong(battleView["pmmId"]);
		if (!pmmId.HasValue || !(battleView["pmList"] is JArray pets))
		{
			return null;
		}

		AolaBattleSideSnapshot side = new AolaBattleSideSnapshot
		{
			PmmId = pmmId.Value,
			LastHpChange = ReadLong(container?["hpInc"]),
			LastHpChangeDetails = ReadText(container?["hpIncList"]),
			LastHpChangeType = ReadText(container?["hpType"])
		};
		int? battleSlotId = ReadInt(battleView["slotId"]);
		int petIndex = 0;
		foreach (JObject petObject in pets.OfType<JObject>())
		{
			AolaBattlePetSnapshot pet = ParsePet(petObject, petIndex == 0 ? battleSlotId : null);
			if (pet != null)
			{
				side.Pets.Add(pet);
			}
			petIndex++;
		}
		return side;
	}

	private static AolaBattlePetSnapshot ParsePet(JObject petObject, int? battleSlotId)
	{
		if (!(petObject["pmSView"] is JObject view))
		{
			return null;
		}

		int raceId = ReadInt(view["r"]) ?? 0;
		int skinId = ReadInt(view["skin"]) ?? -1;
		int faciesId = ReadInt(view["f"]) ?? -1;
		AolaBattlePetSnapshot pet = new AolaBattlePetSnapshot
		{
			BattleSlotId = battleSlotId,
			UniqueId = ReadLong(view["uqi"]) ?? ReadLong(petObject["uqi"]) ?? 0,
			PetId = ReadInt(view["i"]) ?? 0,
			RaceId = raceId,
			ViewId = skinId > 0 ? skinId : faciesId > 0 ? faciesId : raceId,
			Name = ReadText(view["nm"]) ?? "未命名亚比",
			Nickname = ReadText(view["nick"]),
			Level = ReadInt(view["lv"]),
			Character = ReadText(view["ch"]),
			CurrentHp = ReadCompositeNumber(view["c0"]),
			MaximumHp = ReadCompositeNumber(view["s0"])
		};

		AolaBattleLoadoutParser.Parse(petObject, view, pet);
		for (int index = 0; index < AbilityNames.Length; index++)
		{
			AolaBattleAbilitySnapshot ability = ParseAbility(view["ea" + index], index);
			if (ability != null)
			{
				pet.Abilities.Add(ability);
			}
		}

		if (petObject["skills"] is JArray skills)
		{
			foreach (JObject skillObject in skills.OfType<JObject>())
			{
				pet.Skills.Add(new AolaBattleSkillSnapshot
				{
					Id = ReadInt(skillObject["id"]) ?? 0,
					Name = ReadText(skillObject["name"]) ?? "未命名技能",
					PowerPoints = ReadText(skillObject["pp"]),
					Cooldown = ReadInt(skillObject["cd"])
				});
			}
		}
		return pet;
	}

	private static void MergePacketSide(AolaBattleSideSnapshot target, AolaBattleSideSnapshot incoming)
	{
		if (incoming.LastHpChange.HasValue)
		{
			target.LastHpChange = (target.LastHpChange ?? 0) + incoming.LastHpChange.Value;
		}
		target.LastHpChangeDetails = JoinValues(target.LastHpChangeDetails, incoming.LastHpChangeDetails);
		target.LastHpChangeType = JoinValues(target.LastHpChangeType, incoming.LastHpChangeType);
		foreach (AolaBattlePetSnapshot pet in incoming.Pets)
		{
			MergePet(target.Pets, pet);
		}
	}

	private static void MergePet(List<AolaBattlePetSnapshot> pets, AolaBattlePetSnapshot incoming)
	{
		if (incoming.BattleSlotId.HasValue && incoming.UniqueId != 0)
		{
			foreach (AolaBattlePetSnapshot pet in pets.Where(pet =>
				pet.BattleSlotId == incoming.BattleSlotId && pet.UniqueId != incoming.UniqueId))
			{
				pet.BattleSlotId = null;
			}
		}

		int index = incoming.UniqueId != 0
			? pets.FindIndex(pet => pet.UniqueId == incoming.UniqueId)
			: -1;
		if (index < 0 && incoming.BattleSlotId.HasValue)
		{
			index = pets.FindIndex(pet => pet.BattleSlotId == incoming.BattleSlotId);
		}
		if (index >= 0)
		{
			AolaBattleLoadoutParser.PreserveMissing(incoming, pets[index]);
			if (!incoming.BattleSlotId.HasValue && pets[index].BattleSlotId.HasValue)
			{
				incoming.BattleSlotId = pets[index].BattleSlotId;
			}
			pets[index] = incoming;
		}
		else
		{
			pets.Add(incoming);
		}
	}

	private static string JoinValues(string first, string second)
	{
		if (string.IsNullOrWhiteSpace(first))
		{
			return second;
		}
		if (string.IsNullOrWhiteSpace(second) || string.Equals(first, second, StringComparison.Ordinal))
		{
			return first;
		}
		return first + " | " + second;
	}

	private static AolaBattleAbilitySnapshot ParseAbility(JToken token, int index)
	{
		string raw = ReadText(token);
		if (string.IsNullOrWhiteSpace(raw))
		{
			return null;
		}
		AolaBattleAbilitySnapshot ability = new AolaBattleAbilitySnapshot
		{
			FieldName = "ea" + index,
			DisplayName = AbilityNames[index],
			RawValue = raw
		};
		foreach (string part in raw.Split('#'))
		{
			if (long.TryParse(part, NumberStyles.Integer, CultureInfo.InvariantCulture, out long value))
			{
				ability.Segments.Add(value);
				ability.Total += value;
			}
		}
		return ability.Segments.Count == 0 ? null : ability;
	}

	private static string ReadDescription(string command, JObject parameters)
	{
		string description = ReadText(parameters["desc"]);
		if (!string.IsNullOrWhiteSpace(description))
		{
			return description;
		}
		switch (command)
		{
			case "2303": return "已接收战斗参与者资料";
			case "2304": return "已接收新增参与者资料";
			case "2401": return "战斗初始化";
			case "2426": return "双方参战单位已上场";
			case "2411": return "收到技能与回合结算";
			case "2404":
			case "2309": return "战斗已结束";
			default: return command;
		}
	}

	private static long? ReadCompositeNumber(JToken token)
	{
		long? direct = ReadLong(token);
		if (direct.HasValue)
		{
			return direct;
		}
		string text = ReadText(token);
		if (string.IsNullOrWhiteSpace(text))
		{
			return null;
		}
		long total = 0;
		bool found = false;
		foreach (string part in text.Split('#'))
		{
			if (long.TryParse(part, NumberStyles.Integer, CultureInfo.InvariantCulture, out long value))
			{
				total += value;
				found = true;
			}
		}
		return found ? total : (long?)null;
	}

	private static int? ReadInt(JToken token)
	{
		long? value = ReadLong(token);
		return value.HasValue && value.Value >= int.MinValue && value.Value <= int.MaxValue
			? (int)value.Value
			: (int?)null;
	}

	private static long? ReadLong(JToken token)
	{
		if (token == null || token.Type == JTokenType.Null || token.Type == JTokenType.Undefined)
		{
			return null;
		}
		if (token.Type == JTokenType.Integer)
		{
			return token.Value<long>();
		}
		if (token.Type == JTokenType.Float)
		{
			double value = token.Value<double>();
			return value >= long.MinValue && value <= long.MaxValue ? Convert.ToInt64(value) : (long?)null;
		}
		return long.TryParse(token.ToString(), NumberStyles.Integer, CultureInfo.InvariantCulture, out long parsed)
			? parsed
			: (long?)null;
	}

	private static string ReadText(JToken token)
	{
		if (token == null || token.Type == JTokenType.Null || token.Type == JTokenType.Undefined)
		{
			return null;
		}
		return token.Type == JTokenType.String ? token.Value<string>() : token.ToString(Formatting.None);
	}

	private sealed class BattleViewEntry
	{
		public BattleViewEntry(JObject view, JObject container)
		{
			View = view;
			Container = container;
		}

		public JObject View { get; }

		public JObject Container { get; }
	}
}
