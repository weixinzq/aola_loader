// 架构角色：协调主题选择、theme section 持久化和带请求身份的 Flash 热切换。
// 数据流：themeId -> 资源目标/设置；最新选择 -> IThemePushBridge -> Flash 应用结果。
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
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
		new ThemeOption(9, "深海银河主题风格"),
		new ThemeOption(10, "遐蝶·紫夜蝶影")
	};

	private readonly ISettingsSectionStore _store;
	private readonly ThemeSettingsCodec _codec;
	private readonly IThemeSelectionTarget _target;
	private readonly IReadOnlyList<ThemeOption> _options;
	private ThemeSettings _current;
	private readonly IThemePushBridge _pushBridge;
	private int _revision;
	private int _selectedId;
	private ThemeLiveResult _lastPush;

	public ThemeCoordinator(
		ISettingsSectionStore store,
		ThemeSettingsCodec codec,
		IThemeSelectionTarget target,
		IEnumerable<ThemeOption> options = null,
		IThemePushBridge pushBridge = null)
	{
		_store = store ?? throw new ArgumentNullException(nameof(store));
		_codec = codec ?? throw new ArgumentNullException(nameof(codec));
		_target = target ?? throw new ArgumentNullException(nameof(target));
		_options = (options ?? DefaultOptions).Where(option => pushBridge != null || option.Id != 10).ToArray();
		_current = _store.Load(ThemeSettingsCodec.SectionKey, _codec).Value;
		_selectedId = _current.SelectedThemeId;
		_pushBridge = pushBridge;
	}

	public IReadOnlyList<ThemeOption> Options => _options;

	public ThemeSettings Current => _current;
	public int RequestId => Volatile.Read(ref _revision);

	public ThemeChangeResult ApplyToRule(int themeId)
	{
		int normalized = Normalize(themeId);
		if (normalized == 10 && _pushBridge == null)
			return ThemeChangeResult.RuleFailed(normalized, "遐蝶主题仅支持热切换；当前保持官方界面，保存的主题选择未更改。");
		try
		{
			_target.SetSelectedThemeId(normalized);
			_selectedId = normalized;
			Interlocked.Increment(ref _revision);
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
		if (normalized == 10 && _pushBridge == null)
			return ThemeChangeResult.RuleFailed(normalized, "遐蝶主题仅支持热切换；当前保持官方界面，保存的主题选择未更改。");
		try
		{
			_target.SetSelectedThemeId(normalized);
			_selectedId = normalized;
			Interlocked.Increment(ref _revision);
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

	public void ResetPage()
	{
		Interlocked.Increment(ref _revision);
		_lastPush = null;
	}

	public async Task<ThemeLiveResult> PushCurrentAsync(CancellationToken token)
	{
		int revision = Volatile.Read(ref _revision);
		int themeId = _selectedId;
		if (_pushBridge == null) return new ThemeLiveResult(themeId == 10 ? "Unavailable" : "RefreshRequired", revision, themeId,
			themeId == 10 ? "遐蝶主题仅支持热切换；当前保持官方界面，保存的主题选择未更改。" : null);
		if (_lastPush?.RequestId == revision && (_lastPush.Status == "Applied" || _lastPush.Status == "Failed")) return _lastPush;
		ThemeLiveResult result = await _pushBridge.ApplyAsync(themeId, revision, token).ConfigureAwait(false);
		if (revision != Volatile.Read(ref _revision)) return new ThemeLiveResult("Superseded", revision, themeId);
		_lastPush = result;
		return result;
	}

	private static bool IsRuleError(Exception ex)
	{
		return ex is InvalidOperationException || ex is ArgumentOutOfRangeException;
	}
}
