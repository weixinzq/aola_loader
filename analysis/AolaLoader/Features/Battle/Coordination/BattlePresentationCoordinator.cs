// 架构角色：协调战斗表现设置、Flash bridge 推送和模型资源快照的延迟激活。
// 数据流：UI 设置 -> 规范化/预检/持久化 -> 资源目标 + BattleBridgeClient。
using System;
using System.Threading;
using System.Threading.Tasks;
using AolaLoader.Features.Battle.Bridge;
using AolaLoader.Features.Battle.Settings;
using AolaLoader.Settings;

namespace AolaLoader.Features.Battle.Coordination;

/// <summary>
/// 协调战斗设置的保存与应用，不直接修改 SWF 或发送战斗协议。
/// 隐藏数字、跳过演出通过页面桥推给 Flash；模型映射由资源拦截层预检并切换。
/// 两条应用路径相互独立，因此“已保存”“演出已应用”“模型待切换”需要分别报告。
/// </summary>
internal sealed class BattlePresentationCoordinator
{
	private readonly ISettingsSectionStore _store;
	private readonly BattleSettingsCodec _codec;
	private readonly BattleBridgeClient _bridge;
	private readonly IBattleMorphRuleTarget _morphRuleTarget;
	// 只保护待切换资源快照，不覆盖整个异步保存过程；不能视作保存操作的串行锁。
	private readonly object _morphSync = new object();
	// 最近加载或成功保存的设置，不代表 Flash 和资源规则都已使用这些设置。
	private BattleSettings _current;
	// 已预检成功但尚未激活的模型资源；后续保存的新快照可以替换它。
	private BattleMorphPreparationResult _pendingMorphPreparation;
	// 每次推送递增，由页面桥回传确认；这是设置请求编号，不是 SWF 资源版本号。
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
		// 构造时只读取 battle Section；启动时的资源准备由 RestoreMorphRulesAsync 完成。
		_current = _store.Load(BattleSettingsCodec.SectionKey, _codec).Value;
	}

	public BattleSettings Current => _current;

	public BattleBridgeClient Bridge => _bridge;

	// 单条规则的基础校验；完整列表冲突和目标资源可用性仍由保存前的预检检查。
	public string ValidateMorphRule(BattleMorphRule rule) => _morphRuleTarget.ValidateRule(rule);

	/// <summary>
	/// 规范化设置 → 预检模型资源 → 保存 JSON → 尝试切换模型 → 推送演出选项。
	/// 预检或保存失败时保留旧设置；保存之后桥调用失败不会撤销已落盘的设置。
	/// </summary>
	public async Task<BattlePresentationApplyResult> SaveAndApplyAsync(
		BattleSettings settings,
		CancellationToken cancellationToken)
	{
		BattleSettings normalized = _codec.Normalize(settings);
		// 沿用的变量名表示模型设置发生变化；满足清理边界时可切换，并非必须重启。
		bool morphRestartRequired = !HaveSameMorphSettings(_current, normalized);
		// 启用模型替换时准备每条规则的双方六分片；这里只生成快照，尚不影响当前战斗。
		// 即使映射未变化，也先调用预检，再决定是否需要安装新的资源快照。
		BattleMorphPreparationResult morphPreparation = await _morphRuleTarget.PrepareRulesAsync(
			normalized.MorphRules,
			normalized.BattleMorphEnabled,
			cancellationToken).ConfigureAwait(false);
		if (!morphPreparation.Succeeded)
		{
			return BattlePresentationApplyResult.SaveFailure(morphPreparation.Message);
		}
		// 只保存 battle Section（含完整 MorphRules），由存储层负责原子写入和保留其他 Section。
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
			// 战斗中或桥不可用时保留旧模型；主窗体后续轮询此方法，等待安全切换时机。
			morphActivationPending = !await TryActivatePendingMorphRulesAsync(cancellationToken)
				.ConfigureAwait(false);
		}
		// 模型暂不能切换也继续推送演出选项。ConfigureAwait(false) 不保证恢复到 UI 线程。
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

	/// <summary>
	/// 供主窗体启动流程恢复已保存的模型映射：重新准备资源，成功后直接安装快照。
	/// 此路径不等待战斗桥、不写 JSON，也不推送演出选项；战斗中改规则应走延迟切换路径。
	/// </summary>
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

	/// <summary>
	/// 尝试激活待切换快照；仅本次真正完成切换时返回 true。
	/// 没有待切换项、桥不可用、尚未清理完或快照已被替换时返回 false，留待后续处理。
	/// </summary>
	public async Task<bool> TryActivatePendingMorphRulesAsync(CancellationToken cancellationToken)
	{
		BattleMorphPreparationResult pending;
		lock (_morphSync) pending = _pendingMorphPreparation;
		if (pending == null) return false;
		// 异步读桥时不持锁。必须同时 active=false、ended=false：
		// ended=true 只表示战斗结束，不能据此认定官方资源清理已经完成。
		BattleBridgeStateResult state = await _bridge.GetStateAsync(cancellationToken).ConfigureAwait(false);
		if (!state.Succeeded || state.State.Active || state.State.Ended) return false;
		lock (_morphSync)
		{
			// 等待桥期间可能保存了新规则；引用检查避免旧任务安装或清除新快照。
			if (!ReferenceEquals(pending, _pendingMorphPreparation)) return false;
			_morphRuleTarget.ActivatePreparedRules(pending);
			_pendingMorphPreparation = null;
		}
		return true;
	}

	/// <summary>
	/// 页面加载等后续时机重推当前演出选项；不重复保存 JSON，也不重新准备模型资源。
	/// </summary>
	public Task<BattleBridgeApplyResult> PushCurrentAsync(CancellationToken cancellationToken)
	{
		return _bridge.ApplyAsync(
			_current,
			Interlocked.Increment(ref _revision),
			cancellationToken);
	}

	// 只比较模型开关和有序规则列表；备注和顺序变化也算变化，演出开关不参与比较。
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

/// <summary>
/// 分别返回持久化、演出桥调用和模型切换的结果，供界面决定提示内容。
/// 这些标志均不证明服务器执行成功或实际画面已经通过验收。
/// </summary>
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

	// battle Section 已成功保存，可能尚未在当前游戏中生效。
	public bool Saved { get; }
	// 页面桥确认接收了本次 revision，结果可能是 Applied，也可能是 Pending。
	public bool Submitted { get; }
	// Flash 返回匹配 revision 的 BattleOptionsApplied，只对应演出选项。
	public bool Applied { get; }
	// 本次模型变更已保存和预检，但未能立即切换资源快照。
	public bool BattleMorphActivationPending { get; }
	public string Message { get; }

	public static BattlePresentationApplyResult SaveFailure(string message) =>
		new BattlePresentationApplyResult(false, false, false, false, message);
}
