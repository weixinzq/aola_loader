using System;
using System.Collections.Generic;
using Newtonsoft.Json.Linq;

namespace AolaLoader.Settings;

internal sealed class LegacySettingsMigrator
{
	private static readonly HashSet<string> LegacyFieldNames = new HashSet<string>(StringComparer.Ordinal)
	{
		"SchemaVersion",
		"SelectedThemeId",
		"PetMorphEnabled",
		"PetMorphLiveBridgeEnabled",
		"PetMorphRules",
		"DocumentVersion",
		"Sections"
	};

	public bool TryMigrate(JObject legacy, out JObject migrated, out string error)
	{
		migrated = null;
		error = null;
		if (legacy == null)
		{
			error = "Legacy settings document is missing.";
			return false;
		}

		JToken schemaVersion = legacy["SchemaVersion"];
		if (schemaVersion == null || schemaVersion.Type != JTokenType.Integer || schemaVersion.Value<int>() != 5)
		{
			error = "Settings document is neither DocumentVersion 1 nor legacy SchemaVersion 5.";
			return false;
		}

		if (!TryReadInteger(legacy, "SelectedThemeId", 0, out int selectedThemeId, out error) ||
			!TryReadBoolean(legacy, "PetMorphEnabled", false, out bool petMorphEnabled, out error) ||
			!TryReadBoolean(legacy, "PetMorphLiveBridgeEnabled", true, out bool liveBridgeEnabled, out error) ||
			!TryReadRules(legacy, out JArray rules, out error))
		{
			return false;
		}

		JObject result = new JObject();
		foreach (JProperty property in legacy.Properties())
		{
			if (!LegacyFieldNames.Contains(property.Name))
			{
				result[property.Name] = property.Value.DeepClone();
			}
		}

		result["DocumentVersion"] = 1;
		result["Sections"] = new JObject
		{
			["theme"] = new JObject
			{
				["Version"] = 1,
				["SelectedThemeId"] = selectedThemeId
			},
			["petMorph"] = new JObject
			{
				["Version"] = 1,
				["Enabled"] = petMorphEnabled,
				["LiveBridgeEnabled"] = liveBridgeEnabled,
				["Rules"] = rules
			},
			["battle"] = CreateDefaultBattleSection()
		};

		migrated = result;
		return true;
	}

	private static JObject CreateDefaultBattleSection()
	{
		return new JObject
		{
			["Version"] = 1,
			["HideDamageNumbers"] = false,
			["HideHealingNumbers"] = false,
			["SkipPetAttackActions"] = false,
			["FightSkillEffect"] = 0,
			["MorphRules"] = new JArray()
		};
	}

	private static bool TryReadInteger(
		JObject source,
		string name,
		int defaultValue,
		out int value,
		out string error)
	{
		JToken token = source[name];
		if (token == null)
		{
			value = defaultValue;
			error = null;
			return true;
		}
		if (token.Type != JTokenType.Integer)
		{
			value = defaultValue;
			error = name + " must be an integer.";
			return false;
		}

		value = token.Value<int>();
		error = null;
		return true;
	}

	private static bool TryReadBoolean(
		JObject source,
		string name,
		bool defaultValue,
		out bool value,
		out string error)
	{
		JToken token = source[name];
		if (token == null)
		{
			value = defaultValue;
			error = null;
			return true;
		}
		if (token.Type != JTokenType.Boolean)
		{
			value = defaultValue;
			error = name + " must be a boolean.";
			return false;
		}

		value = token.Value<bool>();
		error = null;
		return true;
	}

	private static bool TryReadRules(JObject source, out JArray rules, out string error)
	{
		JToken token = source["PetMorphRules"];
		if (token == null)
		{
			rules = new JArray();
			error = null;
			return true;
		}
		if (!(token is JArray sourceRules))
		{
			rules = null;
			error = "PetMorphRules must be an array.";
			return false;
		}

		rules = (JArray)sourceRules.DeepClone();
		foreach (JToken item in rules)
		{
			if (item is JObject rule)
			{
				SetMissingBoolean(rule, "HideOriginalModel");
				SetMissingBoolean(rule, "RemoveOriginalBackground");
				SetMissingBoolean(rule, "ReplaceBackpackIcon");
			}
		}
		error = null;
		return true;
	}

	private static void SetMissingBoolean(JObject value, string name)
	{
		if (value[name] == null)
		{
			value[name] = false;
		}
	}
}

