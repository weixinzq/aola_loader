using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using AolaLoader.Settings;
using Newtonsoft.Json.Linq;

namespace AolaLoader.Features.Battle.Settings;

internal sealed class BattleMorphRule
{
	public BattleMorphRule(string note, int sourceViewId, int targetViewId)
	{
		Note = note ?? string.Empty;
		SourceViewId = sourceViewId;
		TargetViewId = targetViewId;
	}

	public string Note { get; }
	public int SourceViewId { get; }
	public int TargetViewId { get; }
}

internal sealed class BattleSettings
{
	public BattleSettings(
		bool hideDamageNumbers,
		bool hideHealingNumbers,
		bool skipBattlePresentation,
		bool battleMorphEnabled,
		IEnumerable<BattleMorphRule> morphRules,
		int ignoredLegacyMorphRuleCount = 0)
	{
		HideDamageNumbers = hideDamageNumbers;
		HideHealingNumbers = hideHealingNumbers;
		SkipBattlePresentation = skipBattlePresentation;
		BattleMorphEnabled = battleMorphEnabled;
		MorphRules = new ReadOnlyCollection<BattleMorphRule>(
			(morphRules ?? Enumerable.Empty<BattleMorphRule>())
				.Where(rule => rule != null)
				.Select(rule => new BattleMorphRule(rule.Note, rule.SourceViewId, rule.TargetViewId))
				.ToList());
		IgnoredLegacyMorphRuleCount = Math.Max(0, ignoredLegacyMorphRuleCount);
	}

	public bool HideDamageNumbers { get; }

	public bool HideHealingNumbers { get; }

	public bool SkipBattlePresentation { get; }

	public bool BattleMorphEnabled { get; }

	public IReadOnlyList<BattleMorphRule> MorphRules { get; }

	public int IgnoredLegacyMorphRuleCount { get; }
}

internal sealed class BattleSettingsCodec : ISettingsSectionCodec<BattleSettings>
{
	public const string SectionKey = "battle";
	public const int CurrentVersion = 6;

	public BattleSettings CreateDefault()
	{
		return new BattleSettings(
			hideDamageNumbers: false,
			hideHealingNumbers: false,
			skipBattlePresentation: false,
			battleMorphEnabled: false,
			Array.Empty<BattleMorphRule>());
	}

	public BattleSettings DeserializeAndMigrate(JObject section)
	{
		if (section == null || section["Version"]?.Type != JTokenType.Integer)
		{
			throw new InvalidOperationException("Battle settings version is unsupported.");
		}
		int version = section.Value<int>("Version");
		if (version < 1 || version > CurrentVersion)
		{
			throw new InvalidOperationException("Battle settings version is unsupported.");
		}

		JToken rulesToken = section["MorphRules"];
		if (rulesToken != null && !(rulesToken is JArray))
		{
			throw new InvalidOperationException("Battle MorphRules must be an array.");
		}

		List<BattleMorphRule> rules = new List<BattleMorphRule>();
		int ignoredLegacyRules = 0;
		foreach (JToken token in rulesToken as JArray ?? new JArray())
		{
			if (!(token is JObject rule) ||
				rule["SourceViewId"]?.Type != JTokenType.Integer ||
				rule["TargetViewId"]?.Type != JTokenType.Integer ||
				(rule["Note"] != null && rule["Note"].Type != JTokenType.String))
			{
				if (version == CurrentVersion)
				{
					throw new InvalidOperationException("Each Battle morph rule must contain integer SourceViewId and TargetViewId values.");
				}
				ignoredLegacyRules++;
				continue;
			}
			if (version == CurrentVersion && rule.Properties().Any(property =>
				property.Name != "Note" && property.Name != "SourceViewId" && property.Name != "TargetViewId"))
			{
				throw new InvalidOperationException("Battle morph rule contains unsupported fields.");
			}
			rules.Add(new BattleMorphRule(
				rule.Value<string>("Note"),
				rule.Value<int>("SourceViewId"),
				rule.Value<int>("TargetViewId")));
		}

		bool skipBattlePresentation = version >= 5
			? ReadBoolean(section, "SkipBattlePresentation", false)
			: version == 4
				? ReadBoolean(section, "SkipAttackAnimation", false)
			: version == 3
				? ReadBoolean(section, "SkipBattlePresentation", false)
				: ReadBoolean(section, "SkipPetAttackActions", false);

		return new BattleSettings(
			ReadBoolean(section, "HideDamageNumbers", false),
			ReadBoolean(section, "HideHealingNumbers", false),
			skipBattlePresentation,
			version == CurrentVersion && ReadBoolean(section, "BattleMorphEnabled", false),
			rules,
			ignoredLegacyRules);
	}

	public BattleSettings Normalize(BattleSettings value)
	{
		BattleSettings source = value ?? CreateDefault();
		return new BattleSettings(
			source.HideDamageNumbers,
			source.HideHealingNumbers,
			source.SkipBattlePresentation,
			source.BattleMorphEnabled,
			source.MorphRules,
			source.IgnoredLegacyMorphRuleCount);
	}

	public JObject Serialize(BattleSettings value)
	{
		BattleSettings normalized = Normalize(value);
		JArray rules = new JArray();
		foreach (BattleMorphRule rule in normalized.MorphRules)
		{
			rules.Add(new JObject
			{
				["Note"] = rule.Note,
				["SourceViewId"] = rule.SourceViewId,
				["TargetViewId"] = rule.TargetViewId
			});
		}
		return new JObject
		{
			["Version"] = CurrentVersion,
			["HideDamageNumbers"] = normalized.HideDamageNumbers,
			["HideHealingNumbers"] = normalized.HideHealingNumbers,
			["SkipBattlePresentation"] = normalized.SkipBattlePresentation,
			["BattleMorphEnabled"] = normalized.BattleMorphEnabled,
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

}
