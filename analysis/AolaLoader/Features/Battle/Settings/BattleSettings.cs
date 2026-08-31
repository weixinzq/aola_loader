using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using AolaLoader.Settings;
using Newtonsoft.Json.Linq;

namespace AolaLoader.Features.Battle.Settings;

internal sealed class BattleSettings
{
	public BattleSettings(
		bool hideDamageNumbers,
		bool hideHealingNumbers,
		bool skipAttackAnimation,
		IEnumerable<JObject> morphRules)
	{
		HideDamageNumbers = hideDamageNumbers;
		HideHealingNumbers = hideHealingNumbers;
		SkipAttackAnimation = skipAttackAnimation;
		MorphRules = new ReadOnlyCollection<JObject>(
			(morphRules ?? Enumerable.Empty<JObject>())
				.Where(rule => rule != null)
				.Select(rule => (JObject)rule.DeepClone())
				.ToList());
	}

	public bool HideDamageNumbers { get; }

	public bool HideHealingNumbers { get; }

	public bool SkipAttackAnimation { get; }

	/// <summary>
	/// Battle morph rules have no defined schema yet, so each entry is preserved
	/// as an opaque defensive snapshot until a Battle presentation feature is specified.
	/// </summary>
	public IReadOnlyList<JObject> MorphRules { get; }
}

internal sealed class BattleSettingsCodec : ISettingsSectionCodec<BattleSettings>
{
	public const string SectionKey = "battle";
	public const int CurrentVersion = 4;

	public BattleSettings CreateDefault()
	{
		return new BattleSettings(
			hideDamageNumbers: false,
			hideHealingNumbers: false,
			skipAttackAnimation: false,
			Array.Empty<JObject>());
	}

	public BattleSettings DeserializeAndMigrate(JObject section)
	{
		if (section == null || section["Version"]?.Type != JTokenType.Integer)
		{
			throw new InvalidOperationException("Battle settings version is unsupported.");
		}
		int version = section.Value<int>("Version");
		if (version != 1 && version != 2 && version != 3 && version != CurrentVersion)
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

		bool skipAttackAnimation = version >= 4
			? ReadBoolean(section, "SkipAttackAnimation", false)
			: version == 3
				? ReadBoolean(section, "SkipBattlePresentation", false)
				: ReadBoolean(section, "SkipPetAttackActions", false);

		return new BattleSettings(
			ReadBoolean(section, "HideDamageNumbers", false),
			ReadBoolean(section, "HideHealingNumbers", false),
			skipAttackAnimation,
			rules);
	}

	public BattleSettings Normalize(BattleSettings value)
	{
		BattleSettings source = value ?? CreateDefault();
		return new BattleSettings(
			source.HideDamageNumbers,
			source.HideHealingNumbers,
			source.SkipAttackAnimation,
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
			["SkipAttackAnimation"] = normalized.SkipAttackAnimation,
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
