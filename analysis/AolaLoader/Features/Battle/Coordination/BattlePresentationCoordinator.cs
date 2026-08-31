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
	private BattleSettings _current;
	private int _revision;

	public BattlePresentationCoordinator(
		ISettingsSectionStore store,
		BattleSettingsCodec codec,
		BattleBridgeClient bridge)
	{
		_store = store ?? throw new ArgumentNullException(nameof(store));
		_codec = codec ?? throw new ArgumentNullException(nameof(codec));
		_bridge = bridge ?? throw new ArgumentNullException(nameof(bridge));
		_current = _store.Load(BattleSettingsCodec.SectionKey, _codec).Value;
	}

	public BattleSettings Current => _current;

	public BattleBridgeClient Bridge => _bridge;

	public async Task<BattlePresentationApplyResult> SaveAndApplyAsync(
		BattleSettings settings,
		CancellationToken cancellationToken)
	{
		BattleSettings normalized = _codec.Normalize(settings);
		SettingsSectionSaveResult save = _store.Save(
			BattleSettingsCodec.SectionKey,
			normalized,
			_codec);
		if (!save.Succeeded)
		{
			return BattlePresentationApplyResult.SaveFailure(save.Error);
		}
		_current = normalized;
		BattleBridgeApplyResult applied = await _bridge.ApplyAsync(
			normalized,
			Interlocked.Increment(ref _revision),
			cancellationToken).ConfigureAwait(false);
		return new BattlePresentationApplyResult(true, applied.Submitted, applied.Applied, applied.Message);
	}

	public Task<BattleBridgeApplyResult> PushCurrentAsync(CancellationToken cancellationToken)
	{
		return _bridge.ApplyAsync(
			_current,
			Interlocked.Increment(ref _revision),
			cancellationToken);
	}
}

internal sealed class BattlePresentationApplyResult
{
	public BattlePresentationApplyResult(bool saved, bool submitted, bool applied, string message)
	{
		Saved = saved;
		Submitted = submitted;
		Applied = applied;
		Message = message ?? string.Empty;
	}

	public bool Saved { get; }
	public bool Submitted { get; }
	public bool Applied { get; }
	public string Message { get; }

	public static BattlePresentationApplyResult SaveFailure(string message) =>
		new BattlePresentationApplyResult(false, false, false, message);
}
