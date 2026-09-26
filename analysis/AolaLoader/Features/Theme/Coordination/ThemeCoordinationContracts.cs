// 架构角色：定义主题选项、协调器和资源目标之间的窄接口及变更结果。
// 数据流：UI themeId -> IThemeCoordinator -> settings store + selection target。
using System.Collections.Generic;
using AolaLoader.Features.Theme.Settings;

namespace AolaLoader.Features.Theme.Coordination;

internal sealed class ThemeOption
{
	public ThemeOption(int id, string displayName)
	{
		Id = id;
		DisplayName = displayName ?? string.Empty;
	}

	public int Id { get; }

	public string DisplayName { get; }
}

internal sealed class ThemeChangeResult
{
	private ThemeChangeResult(bool ruleApplied, bool settingsSaved, int appliedThemeId, string error)
	{
		RuleApplied = ruleApplied;
		SettingsSaved = settingsSaved;
		AppliedThemeId = appliedThemeId;
		Error = error;
	}

	public bool RuleApplied { get; }

	public bool SettingsSaved { get; }

	public int AppliedThemeId { get; }

	public string Error { get; }

	public bool Succeeded => RuleApplied && SettingsSaved;

	public static ThemeChangeResult Applied(int appliedThemeId, bool settingsSaved)
	{
		return new ThemeChangeResult(true, settingsSaved, appliedThemeId, null);
	}

	public static ThemeChangeResult RuleFailed(int requestedThemeId, string error)
	{
		return new ThemeChangeResult(false, false, requestedThemeId, error);
	}

	public static ThemeChangeResult SaveFailed(int appliedThemeId, string error)
	{
		return new ThemeChangeResult(true, false, appliedThemeId, error);
	}
}

/// <summary>
/// Theme module contract for selection, resource rule updates and Section persistence.
/// Theme ids are in settings space: 0 = default (full pass-through), 1..9 = local template.
/// </summary>
internal interface IThemeCoordinator
{
	IReadOnlyList<ThemeOption> Options { get; }

	ThemeSettings Current { get; }

	/// Applies a theme selection to the resource rule without persisting.
	ThemeChangeResult ApplyToRule(int themeId);

	/// Applies a theme selection to the resource rule and persists it to the theme Section.
	ThemeChangeResult ApplyAndSave(int themeId);
}

/// <summary>
/// Seam between the Theme coordinator and the resource rule owner (the Cef adapter).
/// The rule owner maps settings-space 0 to its internal no-interception state.
/// </summary>
internal interface IThemeSelectionTarget
{
	void SetSelectedThemeId(int themeId);
}
