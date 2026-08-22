using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using AolaLoader.Settings;
using Newtonsoft.Json.Linq;

namespace AolaLoader.Features.PetMorph.Settings;

internal sealed class PetMorphSettings
{
	public PetMorphSettings(
		bool enabled,
		bool liveBridgeEnabled,
		IEnumerable<PetMorphRuleSettings> rules)
	{
		Enabled = enabled;
		LiveBridgeEnabled = liveBridgeEnabled;
		Rules = new ReadOnlyCollection<PetMorphRuleSettings>(
			(rules ?? Enumerable.Empty<PetMorphRuleSettings>())
				.Where(rule => rule != null)
				.Select(rule => rule.Clone())
				.ToList());
	}

	public bool Enabled { get; }

	public bool LiveBridgeEnabled { get; }

	public IReadOnlyList<PetMorphRuleSettings> Rules { get; }
}

internal sealed class PetMorphRuleSettings
{
	private readonly JObject _unknownFields;

	public PetMorphRuleSettings(
		string note,
		int originalId,
		int backpackId,
		int posterSourceId,
		int posterId,
		bool hideOriginalModel = false,
		bool removeOriginalBackground = false,
		bool replaceBackpackIcon = false)
		: this(
			note,
			originalId,
			backpackId,
			posterSourceId,
			posterId,
			hideOriginalModel,
			removeOriginalBackground,
			replaceBackpackIcon,
			new JObject())
	{
	}

	internal PetMorphRuleSettings(
		string note,
		int originalId,
		int backpackId,
		int posterSourceId,
		int posterId,
		bool hideOriginalModel,
		bool removeOriginalBackground,
		bool replaceBackpackIcon,
		JObject unknownFields)
	{
		Note = note ?? string.Empty;
		OriginalId = originalId;
		BackpackId = backpackId;
		PosterSourceId = posterSourceId;
		PosterId = posterId;
		HideOriginalModel = hideOriginalModel;
		RemoveOriginalBackground = removeOriginalBackground;
		ReplaceBackpackIcon = replaceBackpackIcon;
		_unknownFields = unknownFields == null ? new JObject() : (JObject)unknownFields.DeepClone();
	}

	public string Note { get; }
	public int OriginalId { get; }
	public int BackpackId { get; }
	public int PosterSourceId { get; }
	public int PosterId { get; }
	public bool HideOriginalModel { get; }
	public bool RemoveOriginalBackground { get; }
	public bool ReplaceBackpackIcon { get; }

	internal JObject CloneUnknownFields() => (JObject)_unknownFields.DeepClone();

	internal PetMorphRuleSettings Clone()
	{
		return new PetMorphRuleSettings(
			Note,
			OriginalId,
			BackpackId,
			PosterSourceId,
			PosterId,
			HideOriginalModel,
			RemoveOriginalBackground,
			ReplaceBackpackIcon,
			_unknownFields);
	}
}

internal sealed class PetMorphSettingsCodec : ISettingsSectionCodec<PetMorphSettings>
{
	public const string SectionKey = "petMorph";
	public const int CurrentVersion = 1;
	private static readonly HashSet<string> KnownRuleFields = new HashSet<string>(StringComparer.Ordinal)
	{
		"Note", "OriginalId", "BackpackId", "PosterSourceId", "PosterId",
		"HideOriginalModel", "RemoveOriginalBackground", "ReplaceBackpackIcon"
	};

	public PetMorphSettings CreateDefault()
	{
		return new PetMorphSettings(false, true, Array.Empty<PetMorphRuleSettings>());
	}

	public PetMorphSettings DeserializeAndMigrate(JObject section)
	{
		if (section == null || section["Version"]?.Type != JTokenType.Integer ||
			section.Value<int>("Version") != CurrentVersion)
		{
			throw new InvalidOperationException("PetMorph settings version is unsupported.");
		}
		bool enabled = ReadBoolean(section, "Enabled", false);
		bool liveBridgeEnabled = ReadBoolean(section, "LiveBridgeEnabled", true);
		JToken rulesToken = section["Rules"];
		if (rulesToken != null && !(rulesToken is JArray))
		{
			throw new InvalidOperationException("PetMorph Rules must be an array.");
		}

		List<PetMorphRuleSettings> rules = new List<PetMorphRuleSettings>();
		foreach (JToken token in rulesToken as JArray ?? new JArray())
		{
			if (!(token is JObject rule))
			{
				throw new InvalidOperationException("Each PetMorph rule must be an object.");
			}
			JObject unknown = new JObject();
			foreach (JProperty property in rule.Properties())
			{
				if (!KnownRuleFields.Contains(property.Name))
				{
					unknown[property.Name] = property.Value.DeepClone();
				}
			}
			rules.Add(new PetMorphRuleSettings(
				ReadString(rule, "Note", string.Empty),
				ReadInteger(rule, "OriginalId", 0),
				ReadInteger(rule, "BackpackId", 0),
				ReadInteger(rule, "PosterSourceId", 0),
				ReadInteger(rule, "PosterId", 0),
				ReadBoolean(rule, "HideOriginalModel", false),
				ReadBoolean(rule, "RemoveOriginalBackground", false),
				ReadBoolean(rule, "ReplaceBackpackIcon", false),
				unknown));
		}
		return new PetMorphSettings(enabled, liveBridgeEnabled, rules);
	}

	public PetMorphSettings Normalize(PetMorphSettings value)
	{
		PetMorphSettings source = value ?? CreateDefault();
		IEnumerable<PetMorphRuleSettings> rules = source.Rules
			.Where(rule => rule != null && (rule.OriginalId > 0 || rule.PosterSourceId > 0))
			.Select(rule => rule.Clone());
		return new PetMorphSettings(source.Enabled, source.LiveBridgeEnabled, rules);
	}

	public JObject Serialize(PetMorphSettings value)
	{
		PetMorphSettings normalized = Normalize(value);
		JArray rules = new JArray();
		foreach (PetMorphRuleSettings rule in normalized.Rules)
		{
			JObject item = rule.CloneUnknownFields();
			item["Note"] = rule.Note;
			item["OriginalId"] = rule.OriginalId;
			item["BackpackId"] = rule.BackpackId;
			item["PosterSourceId"] = rule.PosterSourceId;
			item["PosterId"] = rule.PosterId;
			item["HideOriginalModel"] = rule.HideOriginalModel;
			item["RemoveOriginalBackground"] = rule.RemoveOriginalBackground;
			item["ReplaceBackpackIcon"] = rule.ReplaceBackpackIcon;
			rules.Add(item);
		}
		return new JObject
		{
			["Version"] = CurrentVersion,
			["Enabled"] = normalized.Enabled,
			["LiveBridgeEnabled"] = normalized.LiveBridgeEnabled,
			["Rules"] = rules
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

	private static string ReadString(JObject source, string name, string defaultValue)
	{
		JToken token = source[name];
		if (token == null || token.Type == JTokenType.Null)
		{
			return defaultValue;
		}
		if (token.Type != JTokenType.String)
		{
			throw new InvalidOperationException(name + " must be a string.");
		}
		return token.Value<string>() ?? defaultValue;
	}
}
