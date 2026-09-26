// 架构角色：定义形态协调、资源规则目标和页面推送之间的端口与组合结果。
// 数据流：UI 设置 -> IPetMorphCoordinator -> rule target + push bridge。
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using AolaLoader.Features.PetMorph.Settings;

namespace AolaLoader.Features.PetMorph.Coordination;

internal sealed class PetMorphApplyResult
{
	private PetMorphApplyResult(
		bool rulesApplied,
		bool settingsSaved,
		bool bridgeAvailable,
		bool pushBlocked,
		AolaPetMorphPushResult push,
		string error)
	{
		RulesApplied = rulesApplied;
		SettingsSaved = settingsSaved;
		BridgeAvailable = bridgeAvailable;
		PushBlocked = pushBlocked;
		Push = push;
		Error = error;
	}

	public bool RulesApplied { get; }

	public bool SettingsSaved { get; }

	public bool BridgeAvailable { get; }

	public bool PushBlocked { get; }

	public AolaPetMorphPushResult Push { get; }

	public string Error { get; }

	public bool Succeeded => RulesApplied && SettingsSaved;

	public static PetMorphApplyResult RuleFailed(string error)
	{
		return new PetMorphApplyResult(false, false, false, false, null, error);
	}

	public static PetMorphApplyResult SaveFailed(string error)
	{
		return new PetMorphApplyResult(true, false, false, false, null, error);
	}

	public static PetMorphApplyResult BridgeUnavailable()
	{
		return new PetMorphApplyResult(true, true, false, false, null, null);
	}

	public static PetMorphApplyResult PushBlockedResult(string error)
	{
		return new PetMorphApplyResult(true, true, true, true, null, error);
	}

	public static PetMorphApplyResult Pushed(AolaPetMorphPushResult push)
	{
		return new PetMorphApplyResult(true, true, true, false, push, null);
	}
}

/// <summary>
/// PetMorph module contract for the rule snapshot, validation, Section persistence,
/// resource rule updates and page bridge push outcomes.
/// </summary>
internal interface IPetMorphCoordinator
{
	PetMorphSettings Current { get; }

	IReadOnlyList<AolaPetMorphRule> CurrentRules { get; }

	bool IsLiveBridgeAvailable { get; }

	string ValidateRule(AolaPetMorphRule rule);

	/// Restores the saved rule snapshot to the resource rule target without saving or pushing.
	void RestoreFromSavedSettings();

	/// Applies rules, persists the petMorph Section, then pushes when the bridge is available.
	Task<PetMorphApplyResult> ApplyAsync(
		IReadOnlyList<AolaPetMorphRule> rules,
		bool enabled,
		CancellationToken cancellationToken);

	/// Pushes the current saved rules to the page without changing or persisting settings.
	Task<AolaPetMorphPushResult> PushCurrentRulesAsync(CancellationToken cancellationToken);
}

/// <summary>
/// Seam for PetMorph resource rules hosted by the Cef adapter.
/// </summary>
internal interface IPetMorphRuleTarget
{
	bool IsLiveBridgeAvailable { get; }

	void SetRules(IReadOnlyList<AolaPetMorphRule> rules, bool enabled);

	string ValidateRule(AolaPetMorphRule rule);

	Task<IReadOnlyDictionary<int, int>> GetAvailableLiveSkinMappingsAsync(
		IReadOnlyList<AolaPetMorphRule> rules,
		bool enabled);
}

/// <summary>
/// Framework-free page bridge seam for PetMorph pushes.
/// </summary>
internal interface IPetMorphPushBridge
{
	Task<AolaPetMorphPushResult> PushAsync(
		IReadOnlyDictionary<int, int> skinMappings,
		IReadOnlyDictionary<int, bool> hiddenBackgrounds,
		IReadOnlyDictionary<int, int> iconMappings,
		bool enabled,
		CancellationToken cancellationToken);
}
