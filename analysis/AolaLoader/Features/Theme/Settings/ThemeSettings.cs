// 架构角色：定义 theme section 的设置模型与 codec，负责默认值和合法 themeId 规范化。
// 数据流：settings.json theme 节点 <-> ThemeSettings。
using System;
using AolaLoader.Settings;
using Newtonsoft.Json.Linq;

namespace AolaLoader.Features.Theme.Settings;

internal sealed class ThemeSettings
{
	public ThemeSettings(int selectedThemeId)
	{
		SelectedThemeId = selectedThemeId;
	}

	public int SelectedThemeId { get; }
}

internal sealed class ThemeSettingsCodec : ISettingsSectionCodec<ThemeSettings>
{
	public const string SectionKey = "theme";
	public const int CurrentVersion = 1;
	private const int MaximumThemeId = 10;

	public ThemeSettings CreateDefault()
	{
		return new ThemeSettings(0);
	}

	public ThemeSettings DeserializeAndMigrate(JObject section)
	{
		if (section == null)
		{
			throw new ArgumentNullException(nameof(section));
		}
		JToken version = section["Version"];
		if (version == null || version.Type != JTokenType.Integer ||
			version.Value<int>() != CurrentVersion)
		{
			throw new InvalidOperationException("Theme settings version is unsupported.");
		}

		JToken selected = section["SelectedThemeId"];
		if (selected == null)
		{
			return CreateDefault();
		}
		if (selected.Type != JTokenType.Integer)
		{
			throw new InvalidOperationException("SelectedThemeId must be an integer.");
		}
		return new ThemeSettings(selected.Value<int>());
	}

	public ThemeSettings Normalize(ThemeSettings value)
	{
		int selectedThemeId = value?.SelectedThemeId ?? 0;
		if (selectedThemeId < 0 || selectedThemeId > MaximumThemeId)
		{
			selectedThemeId = 0;
		}
		return new ThemeSettings(selectedThemeId);
	}

	public JObject Serialize(ThemeSettings value)
	{
		ThemeSettings normalized = Normalize(value);
		return new JObject
		{
			["Version"] = CurrentVersion,
			["SelectedThemeId"] = normalized.SelectedThemeId
		};
	}
}
