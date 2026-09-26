// 架构角色：封装单条规则评估结果、命中原因和异常信息，供 pipeline 冲突处理与诊断。
// 数据流：rule + request -> evaluation record。
using System;
using AolaLoader.ResourceInterception.Contracts;

namespace AolaLoader.ResourceInterception.Pipeline;

internal sealed class ResourceRuleEvaluation
{
	private ResourceRuleEvaluation(
		ResourceInterceptionPlan plan,
		string ruleName,
		string diagnosticCode,
		string message)
	{
		Plan = plan ?? throw new ArgumentNullException(nameof(plan));
		RuleName = ruleName;
		DiagnosticCode = diagnosticCode ?? string.Empty;
		Message = message ?? string.Empty;
	}

	public ResourceInterceptionPlan Plan { get; }

	public string RuleName { get; }

	public string DiagnosticCode { get; }

	public string Message { get; }

	public bool IsMatch => Plan.Outcome != ResourceInterceptionOutcome.PassThrough;

	public static ResourceRuleEvaluation Match(
		ResourceInterceptionPlan plan,
		string ruleName)
	{
		if (plan == null || plan.Outcome == ResourceInterceptionOutcome.PassThrough)
		{
			throw new ArgumentException("A matching evaluation requires a non-pass-through plan.", nameof(plan));
		}
		if (string.IsNullOrWhiteSpace(ruleName))
		{
			throw new ArgumentException("Rule name is required.", nameof(ruleName));
		}
		return new ResourceRuleEvaluation(plan, ruleName, "pipeline.match", string.Empty);
	}

	public static ResourceRuleEvaluation PassThrough(
		string originalUrl,
		string diagnosticCode,
		string message = null)
	{
		return new ResourceRuleEvaluation(
			ResourceInterceptionPlan.PassThrough(originalUrl),
			null,
			diagnosticCode,
			message);
	}
}
