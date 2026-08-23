using System;
using System.Collections.Generic;
using System.Linq;
using AolaLoader.Features.Theme.Settings;
using AolaLoader.Settings;

namespace AolaLoader.Features.Theme.Coordination;

internal sealed class ThemeCoordinator : IThemeCoordinator
{
	private static readonly ThemeOption[] DefaultOptions =
	{
		new ThemeOption(0, "默认"),
		new ThemeOption(1, "女皇花嫁主题风格"),
		new ThemeOption(2, "星尘花嫁主题风格"),
		new ThemeOption(3, "阿比斯花嫁主题风格"),
		new ThemeOption(4, "奥拉星怀旧风格"),
		new ThemeOption(5, "提亚玛特花嫁主题风格"),
		new ThemeOption(6, "渡至臻主题风格"),
		new ThemeOption(7, "梦花嫁主题风格"),
		new ThemeOption(8, "羲和花嫁主题风格"),
		new ThemeOption(9, "深海银河主题风格")
	};

	private readonly ISettingsSectionStore _store;
	private readonly ThemeSettingsCodec _codec;
	private readonly IThemeSelectionTarget _target;
	private readonly IReadOnlyList<ThemeOption> _options;
	private ThemeSettings _current;

	public ThemeCoordinator(
		ISettingsSectionStore store,
		ThemeSettingsCodec codec,
		IThemeSelectionTarget target,
		IEnumerable<ThemeOption> options = null)
	{
		_store = store ?? throw new ArgumentNullException(nameof(store));
		_codec = codec ?? throw new ArgumentNullException(nameof(codec));
		_target = target ?? throw new ArgumentNullException(nameof(target));
		_options = (options ?? DefaultOptions).ToArray();
		_current = _store.Load(ThemeSettingsCodec.SectionKey, _codec).Value;
	}

	public IReadOnlyList<ThemeOption> Options => _options;

	public ThemeSettings Current => _current;

	public ThemeChangeResult ApplyToRule(int themeId)
	{
		int normalized = Normalize(themeId);
		try
		{
			_target.SetSelectedThemeId(normalized);
			return ThemeChangeResult.Applied(normalized, settingsSaved: false);
		}
		catch (Exception ex) when (IsRuleError(ex))
		{
			return ThemeChangeResult.RuleFailed(normalized, ex.Message);
		}
	}

	public ThemeChangeResult ApplyAndSave(int themeId)
	{
		int normalized = Normalize(themeId);
		try
		{
			_target.SetSelectedThemeId(normalized);
		}
		catch (Exception ex) when (IsRuleError(ex))
		{
			return ThemeChangeResult.RuleFailed(normalized, ex.Message);
		}

		ThemeSettings candidate = _codec.Normalize(new ThemeSettings(normalized));
		SettingsSectionSaveResult save = _store.Save(ThemeSettingsCodec.SectionKey, candidate, _codec);
		if (!save.Succeeded)
		{
			return ThemeChangeResult.SaveFailed(normalized, save.Error);
		}
		_current = candidate;
		return ThemeChangeResult.Applied(normalized, settingsSaved: true);
	}

	private int Normalize(int themeId)
	{
		return _codec.Normalize(new ThemeSettings(themeId)).SelectedThemeId;
	}

	private static bool IsRuleError(Exception ex)
	{
		return ex is InvalidOperationException || ex is ArgumentOutOfRangeException;
	}
}
