using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using AolaLoader.Settings;
using Newtonsoft.Json.Linq;

namespace AolaLoader.Features.Battle.Settings;

/// <summary>
/// Battle module-owned settings. No Battle presentation feature is enabled yet;
/// the fields below are reserved placeholders that must stay at their defaults.
/// </summary>
internal sealed class BattleSettings
{
	public BattleSettings(
		bool hideDamageNumbers,
		bool hideHealingNumbers,
		bool skipPetAttackActions,
		int fightSkillEffect,
		IEnumerable<JObject> morphRules)
	{
		HideDamageNumbers = hideDamageNumbers;
		HideHealingNumbers = hideHealingNumbers;
		SkipPetAttackActions = skipPetAttackActions;
		FightSkillEffect = fightSkillEffect;
		MorphRules = new ReadOnlyCollection<JObject>(
			(morphRules ?? Enumerable.Empty<JObject>())
				.Where(rule => rule != null)
				.Select(rule => (JObject)rule.DeepClone())
				.ToList());
	}

	public bool HideDamageNumbers { get; }

	public bool HideHealingNumbers { get; }

	public bool SkipPetAttackActions { get; }

	public int FightSkillEffect { get; }

	/// <summary>
	/// Battle morph rules have no defined schema yet, so each entry is preserved
	/// as an opaque defensive snapshot until a Battle presentation feature is specified.
	/// </summary>
	public IReadOnlyList<JObject> MorphRules { get; }
}

internal sealed class BattleSettingsCodec : ISettingsSectionCodec<BattleSettings>
{
	public const string SectionKey = "battle";
	public const int CurrentVersion = 1;

	public BattleSettings CreateDefault()
	{
		return new BattleSettings(
			hideDamageNumbers: false,
			hideHealingNumbers: false,
			skipPetAttackActions: false,
			fightSkillEffect: 0,
			Array.Empty<JObject>());
	}

	public BattleSettings DeserializeAndMigrate(JObject section)
	{
		if (section == null || section["Version"]?.Type != JTokenType.Integer ||
			section.Value<int>("Version") != CurrentVersion)
		{
			throw new InvalidOperationException("Battle settings version is unsupported.");
		}

		JToken rulesToken = section["MorphRules"];
		if (rulesToken != null && !(rulesToken is JArray))
		{
			throw new InvalidOperationException("Battle MorphRules must be an array.");
		}

		List<JObject> rules = new List<JObject>();
		foreach (JToken token in rulesToken as JArray ?? new JArray())
		{
			if (!(token is JObject rule))
			{
				throw new InvalidOperationException("Each Battle morph rule must be an object.");
			}
			rules.Add((JObject)rule.DeepClone());
		}

		return new BattleSettings(
			ReadBoolean(section, "HideDamageNumbers", false),
			ReadBoolean(section, "HideHealingNumbers", false),
			ReadBoolean(section, "SkipPetAttackActions", false),
			ReadInteger(section, "FightSkillEffect", 0),
			rules);
	}

	public BattleSettings Normalize(BattleSettings value)
	{
		BattleSettings source = value ?? CreateDefault();
		return new BattleSettings(
			source.HideDamageNumbers,
			source.HideHealingNumbers,
			source.SkipPetAttackActions,
			source.FightSkillEffect,
			source.MorphRules);
	}

	public JObject Serialize(BattleSettings value)
	{
		BattleSettings normalized = Normalize(value);
		JArray rules = new JArray();
		foreach (JObject rule in normalized.MorphRules)
		{
			rules.Add((JObject)rule.DeepClone());
		}
		return new JObject
		{
			["Version"] = CurrentVersion,
			["HideDamageNumbers"] = normalized.HideDamageNumbers,
			["HideHealingNumbers"] = normalized.HideHealingNumbers,
			["SkipPetAttackActions"] = normalized.SkipPetAttackActions,
			["FightSkillEffect"] = normalized.FightSkillEffect,
			["MorphRules"] = rules
		};
	}

	private static bool ReadBoolean(JObject source, string name, bool defaultValue)
	{
		JToken token = source[name];
		if (token == null)
		{
			return defaultValue;
		}
		if (token.Type != JTokenType.Boolean)
		{
			throw new InvalidOperationException(name + " must be a boolean.");
		}
		return token.Value<bool>();
	}

	private static int ReadInteger(JObject source, string name, int defaultValue)
	{
		JToken token = source[name];
		if (token == null)
		{
			return defaultValue;
		}
		if (token.Type != JTokenType.Integer)
		{
			throw new InvalidOperationException(name + " must be an integer.");
		}
		long value = token.Value<long>();
		if (value < int.MinValue || value > int.MaxValue)
		{
			throw new InvalidOperationException(name + " is outside the Int32 range.");
		}
		return (int)value;
	}
}
