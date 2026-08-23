using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using AolaLoader.Features.PetMorph.Settings;
using AolaLoader.Settings;

namespace AolaLoader.Features.PetMorph.Coordination;

internal sealed class PetMorphCoordinator : IPetMorphCoordinator
{
	private readonly ISettingsSectionStore _store;
	private readonly PetMorphSettingsCodec _codec;
	private readonly IPetMorphRuleTarget _ruleTarget;
	private readonly IPetMorphPushBridge _pushBridge;
	private PetMorphSettings _current;
	private long _pushRequest;

	public PetMorphCoordinator(
		ISettingsSectionStore store,
		PetMorphSettingsCodec codec,
		IPetMorphRuleTarget ruleTarget,
		IPetMorphPushBridge pushBridge)
	{
		_store = store ?? throw new ArgumentNullException(nameof(store));
		_codec = codec ?? throw new ArgumentNullException(nameof(codec));
		_ruleTarget = ruleTarget ?? throw new ArgumentNullException(nameof(ruleTarget));
		_pushBridge = pushBridge ?? throw new ArgumentNullException(nameof(pushBridge));
		_current = _store.Load(PetMorphSettingsCodec.SectionKey, _codec).Value;
	}

	public PetMorphSettings Current => _current;

	public IReadOnlyList<AolaPetMorphRule> CurrentRules => SettingsToRules(_current.Rules);

	public bool IsLiveBridgeAvailable => _ruleTarget.IsLiveBridgeAvailable;

	public string ValidateRule(AolaPetMorphRule rule)
	{
		return _ruleTarget.ValidateRule(rule);
	}

	public void RestoreFromSavedSettings()
	{
		_ruleTarget.SetRules(CurrentRules, _current.Enabled);
	}

	public async Task<PetMorphApplyResult> ApplyAsync(
		IReadOnlyList<AolaPetMorphRule> rules,
		bool enabled,
		CancellationToken cancellationToken)
	{
		long request = Interlocked.Increment(ref _pushRequest);
		AolaPetMorphRule[] snapshot = CloneRules(rules);
		PetMorphSettings candidate = _codec.Normalize(new PetMorphSettings(
			enabled,
			_current.LiveBridgeEnabled,
			snapshot.Select(ToSettingsRule)));

		try
		{
			_ruleTarget.SetRules(snapshot, enabled);
		}
		catch (Exception ex) when (IsRuleError(ex))
		{
			return PetMorphApplyResult.RuleFailed(ex.Message);
		}

		SettingsSectionSaveResult save = _store.Save(
			PetMorphSettingsCodec.SectionKey,
			candidate,
			_codec);
		if (!save.Succeeded)
		{
			return PetMorphApplyResult.SaveFailed(save.Error);
		}
		_current = candidate;

		if (!_ruleTarget.IsLiveBridgeAvailable)
		{
			return PetMorphApplyResult.BridgeUnavailable();
		}

		try
		{
			IReadOnlyDictionary<int, int> mappings =
				await _ruleTarget.GetAvailableLivePosterMappingsAsync(snapshot, enabled).ConfigureAwait(false);
			if (request != Volatile.Read(ref _pushRequest))
			{
				return PetMorphApplyResult.Pushed(AolaPetMorphPushResult.SupersededResult());
			}
			AolaPetMorphPushResult push = await _pushBridge.PushAsync(
				mappings,
				BuildHiddenBackgrounds(snapshot),
				BuildIconMappings(snapshot),
				enabled,
				cancellationToken).ConfigureAwait(false);
			return request == Volatile.Read(ref _pushRequest)
				? PetMorphApplyResult.Pushed(push)
				: PetMorphApplyResult.Pushed(AolaPetMorphPushResult.SupersededResult());
		}
		catch (Exception ex) when (IsPushError(ex))
		{
			return PetMorphApplyResult.PushBlockedResult(ex.Message);
		}
	}

	public async Task<AolaPetMorphPushResult> PushCurrentRulesAsync(CancellationToken cancellationToken)
	{
		if (!_ruleTarget.IsLiveBridgeAvailable)
		{
			return AolaPetMorphPushResult.NotInjected("动态背包桥接模板不可用。");
		}

		long request = Interlocked.Increment(ref _pushRequest);
		try
		{
			AolaPetMorphRule[] snapshot = CurrentRules.ToArray();
			IReadOnlyDictionary<int, int> mappings =
				await _ruleTarget.GetAvailableLivePosterMappingsAsync(snapshot, _current.Enabled).ConfigureAwait(false);
			if (request != Volatile.Read(ref _pushRequest))
			{
				return AolaPetMorphPushResult.SupersededResult();
			}
			AolaPetMorphPushResult push = await _pushBridge.PushAsync(
				mappings,
				BuildHiddenBackgrounds(snapshot),
				BuildIconMappings(snapshot),
				_current.Enabled,
				cancellationToken).ConfigureAwait(false);
			return request == Volatile.Read(ref _pushRequest)
				? push
				: AolaPetMorphPushResult.SupersededResult();
		}
		catch (Exception ex) when (IsPushError(ex))
		{
			return AolaPetMorphPushResult.NotInjected(ex.Message);
		}
	}

	private static IReadOnlyList<AolaPetMorphRule> SettingsToRules(IEnumerable<PetMorphRuleSettings> data)
	{
		return (data ?? Enumerable.Empty<PetMorphRuleSettings>())
			.Where(item => item != null && (item.OriginalId > 0 || item.PosterSourceId > 0))
			.Select(item => new AolaPetMorphRule(
				item.Note ?? string.Empty,
				item.OriginalId,
				item.BackpackId,
				item.PosterSourceId,
				item.PosterId,
				item.HideOriginalModel,
				item.RemoveOriginalBackground,
				item.ReplaceBackpackIcon))
			.ToArray();
	}

	private static AolaPetMorphRule[] CloneRules(IEnumerable<AolaPetMorphRule> rules)
	{
		return (rules ?? Enumerable.Empty<AolaPetMorphRule>())
			.Where(rule => rule != null)
			.Select(rule => new AolaPetMorphRule(
				rule.Note,
				rule.OriginalId,
				rule.BackpackId,
				rule.PosterSourceId,
				rule.PosterId,
				rule.HideOriginalModel,
				rule.RemoveOriginalBackground,
				rule.ReplaceBackpackIcon))
			.ToArray();
	}

	private static PetMorphRuleSettings ToSettingsRule(AolaPetMorphRule rule)
	{
		return new PetMorphRuleSettings(
			rule.Note,
			rule.OriginalId,
			rule.BackpackId,
			rule.PosterSourceId,
			rule.PosterId,
			rule.HideOriginalModel,
			rule.RemoveOriginalBackground,
			rule.ReplaceBackpackIcon);
	}

	private static IReadOnlyDictionary<int, bool> BuildHiddenBackgrounds(IEnumerable<AolaPetMorphRule> rules)
	{
		return (rules ?? Enumerable.Empty<AolaPetMorphRule>())
			.Where(rule => rule != null && rule.RemoveOriginalBackground && rule.OriginalId > 0)
			.GroupBy(rule => rule.OriginalId)
			.ToDictionary(group => group.Key, group => true);
	}

	private static IReadOnlyDictionary<int, int> BuildIconMappings(IEnumerable<AolaPetMorphRule> rules)
	{
		return (rules ?? Enumerable.Empty<AolaPetMorphRule>())
			.Where(rule => rule != null && rule.ReplaceBackpackIcon &&
				rule.OriginalId > 0 && rule.BackpackId > 0)
			.GroupBy(rule => rule.OriginalId)
			.Select(group => group.Last())
			.ToDictionary(rule => rule.OriginalId, rule => rule.BackpackId);
	}

	private static bool IsRuleError(Exception ex)
	{
		return ex is InvalidOperationException ||
			ex is ArgumentOutOfRangeException ||
			ex is ObjectDisposedException;
	}

	private static bool IsPushError(Exception ex)
	{
		return ex is InvalidOperationException || ex is ObjectDisposedException;
	}
}
