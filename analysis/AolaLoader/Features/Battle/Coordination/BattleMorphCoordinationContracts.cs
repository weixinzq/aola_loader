using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using AolaLoader.Features.Battle.Settings;

namespace AolaLoader.Features.Battle.Coordination;

internal static class BattleMorphRuleValidation
{
	public static string Validate(BattleMorphRule rule)
	{
		if (rule == null || rule.SourceViewId < 4445 || rule.TargetViewId < 4445)
		{
			return "战斗位图模型源 ID 和目标 ID 必须大于等于 4445。";
		}
		if (rule.SourceViewId == rule.TargetViewId)
		{
			return "战斗模型源 ID 与目标 ID 不能相同。";
		}
		if (rule.SourceViewId.ToString().Length != rule.TargetViewId.ToString().Length)
		{
			return "战斗模型源 ID 与目标 ID 必须具有相同位数。";
		}
		return null;
	}
}

internal interface IBattleMorphRuleTarget
{
	string ValidateRule(BattleMorphRule rule);

	Task<BattleMorphPreparationResult> PrepareRulesAsync(
		IReadOnlyList<BattleMorphRule> rules,
		bool enabled,
		CancellationToken cancellationToken);

	void ActivatePreparedRules(BattleMorphPreparationResult preparation);
}

internal sealed class BattleMorphPreparationResult
{
	private BattleMorphPreparationResult(bool succeeded, int preparedRuleCount, string message, object preparedState)
	{
		Succeeded = succeeded;
		PreparedRuleCount = preparedRuleCount;
		Message = message ?? string.Empty;
		PreparedState = preparedState;
	}

	public bool Succeeded { get; }
	public int PreparedRuleCount { get; }
	public string Message { get; }
	internal object PreparedState { get; }

	internal static BattleMorphPreparationResult Success(int count, object preparedState, string message = null) =>
		new BattleMorphPreparationResult(true, count, message, preparedState);

	public static BattleMorphPreparationResult Failure(string message) =>
		new BattleMorphPreparationResult(false, 0, message, null);
}
