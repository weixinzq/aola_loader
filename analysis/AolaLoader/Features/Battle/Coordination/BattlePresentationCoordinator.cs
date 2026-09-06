using System;
using System.Threading;
using System.Threading.Tasks;
using AolaLoader.Features.Battle.Bridge;
using AolaLoader.Features.Battle.Settings;
using AolaLoader.Settings;

namespace AolaLoader.Features.Battle.Coordination;

internal sealed class BattlePresentationCoordinator
{
	private readonly ISettingsSectionStore _store;
	private readonly BattleSettingsCodec _codec;
	private readonly BattleBridgeClient _bridge;
	private readonly IBattleMorphRuleTarget _morphRuleTarget;
	private readonly object _morphSync = new object();
	private BattleSettings _current;
	private BattleMorphPreparationResult _pendingMorphPreparation;
	private int _revision;

	public BattlePresentationCoordinator(
		ISettingsSectionStore store,
		BattleSettingsCodec codec,
		BattleBridgeClient bridge,
		IBattleMorphRuleTarget morphRuleTarget)
	{
		_store = store ?? throw new ArgumentNullException(nameof(store));
		_codec = codec ?? throw new ArgumentNullException(nameof(codec));
		_bridge = bridge ?? throw new ArgumentNullException(nameof(bridge));
		_morphRuleTarget = morphRuleTarget ?? throw new ArgumentNullException(nameof(morphRuleTarget));
		_current = _store.Load(BattleSettingsCodec.SectionKey, _codec).Value;
	}

	public BattleSettings Current => _current;

	public BattleBridgeClient Bridge => _bridge;

	public string ValidateMorphRule(BattleMorphRule rule) => _morphRuleTarget.ValidateRule(rule);

	public async Task<BattlePresentationApplyResult> SaveAndApplyAsync(
		BattleSettings settings,
		CancellationToken cancellationToken)
	{
		BattleSettings normalized = _codec.Normalize(settings);
		bool morphRestartRequired = !HaveSameMorphSettings(_current, normalized);
		BattleMorphPreparationResult morphPreparation = await _morphRuleTarget.PrepareRulesAsync(
			normalized.MorphRules,
			normalized.BattleMorphEnabled,
			cancellationToken).ConfigureAwait(false);
		if (!morphPreparation.Succeeded)
		{
			return BattlePresentationApplyResult.SaveFailure(morphPreparation.Message);
		}
		SettingsSectionSaveResult save = _store.Save(
			BattleSettingsCodec.SectionKey,
			normalized,
			_codec);
		if (!save.Succeeded)
		{
			return BattlePresentationApplyResult.SaveFailure(save.Error);
		}
		_current = normalized;
		bool morphActivationPending = false;
		if (morphRestartRequired)
		{
			lock (_morphSync) _pendingMorphPreparation = morphPreparation;
			morphActivationPending = !await TryActivatePendingMorphRulesAsync(cancellationToken)
				.ConfigureAwait(false);
		}
		BattleBridgeApplyResult applied = await _bridge.ApplyAsync(
			normalized,
			Interlocked.Increment(ref _revision),
			cancellationToken).ConfigureAwait(false);
		return new BattlePresentationApplyResult(
			true,
			applied.Submitted,
			applied.Applied,
			morphActivationPending,
			applied.Message);
	}

	public async Task<BattleMorphPreparationResult> RestoreMorphRulesAsync(CancellationToken cancellationToken)
	{
		BattleMorphPreparationResult preparation = await _morphRuleTarget.PrepareRulesAsync(
			_current.MorphRules,
			_current.BattleMorphEnabled,
			cancellationToken).ConfigureAwait(false);
		if (preparation.Succeeded)
		{
			_morphRuleTarget.ActivatePreparedRules(preparation);
		}
		return preparation;
	}

	public async Task<bool> TryActivatePendingMorphRulesAsync(CancellationToken cancellationToken)
	{
		BattleMorphPreparationResult pending;
		lock (_morphSync) pending = _pendingMorphPreparation;
		if (pending == null) return false;
		BattleBridgeStateResult state = await _bridge.GetStateAsync(cancellationToken).ConfigureAwait(false);
		if (!state.Succeeded || state.State.Active || state.State.Ended) return false;
		lock (_morphSync)
		{
			if (!ReferenceEquals(pending, _pendingMorphPreparation)) return false;
			_morphRuleTarget.ActivatePreparedRules(pending);
			_pendingMorphPreparation = null;
		}
		return true;
	}

	public Task<BattleBridgeApplyResult> PushCurrentAsync(CancellationToken cancellationToken)
	{
		return _bridge.ApplyAsync(
			_current,
			Interlocked.Increment(ref _revision),
			cancellationToken);
	}

	private static bool HaveSameMorphSettings(BattleSettings left, BattleSettings right)
	{
		if (left.BattleMorphEnabled != right.BattleMorphEnabled ||
			left.MorphRules.Count != right.MorphRules.Count)
		{
			return false;
		}
		for (int index = 0; index < left.MorphRules.Count; index++)
		{
			BattleMorphRule leftRule = left.MorphRules[index];
			BattleMorphRule rightRule = right.MorphRules[index];
			if (leftRule.Note != rightRule.Note || leftRule.SourceViewId != rightRule.SourceViewId ||
				leftRule.TargetViewId != rightRule.TargetViewId)
			{
				return false;
			}
		}
		return true;
	}
}

internal sealed class BattlePresentationApplyResult
{
	public BattlePresentationApplyResult(
		bool saved,
		bool submitted,
		bool applied,
		bool battleMorphActivationPending,
		string message)
	{
		Saved = saved;
		Submitted = submitted;
		Applied = applied;
		BattleMorphActivationPending = battleMorphActivationPending;
		Message = message ?? string.Empty;
	}

	public bool Saved { get; }
	public bool Submitted { get; }
	public bool Applied { get; }
	public bool BattleMorphActivationPending { get; }
	public string Message { get; }

	public static BattlePresentationApplyResult SaveFailure(string message) =>
		new BattlePresentationApplyResult(false, false, false, false, message);
}
