using System;
using System.Collections.Generic;
using System.Linq;
using AolaLoader.ResourceInterception.Contracts;

namespace AolaLoader.ResourceInterception.Pipeline;

internal sealed class ResourceRulePipeline
{
	private readonly RuleEntry[] _rules;

	public ResourceRulePipeline(IEnumerable<IResourceInterceptionRule> rules)
	{
		if (rules == null)
		{
			throw new ArgumentNullException(nameof(rules));
		}

		HashSet<string> names = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
		_rules = rules.Select((rule, index) =>
		{
			if (rule == null)
			{
				throw new ArgumentException("Rules cannot contain null values.", nameof(rules));
			}
			if (string.IsNullOrWhiteSpace(rule.Name) || !names.Add(rule.Name))
			{
				throw new ArgumentException("Rule names must be non-empty and unique.", nameof(rules));
			}
			if (string.IsNullOrWhiteSpace(rule.PathOwnership))
			{
				throw new ArgumentException("Every rule must declare path ownership.", nameof(rules));
			}
			if (!IsReservedPriority(rule.Priority))
			{
				throw new ArgumentOutOfRangeException(
					nameof(rules),
					"Rule priority must use a reserved ResourceInterception range.");
			}
			return new RuleEntry(rule, index);
		})
		.OrderByDescending(entry => entry.Rule.Priority)
		.ThenBy(entry => entry.RegistrationIndex)
		.ToArray();
	}

	public ResourceRuleEvaluation Evaluate(ResourceRequestContext request, bool enabled = true)
	{
		if (request == null)
		{
			throw new ArgumentNullException(nameof(request));
		}
		if (!enabled)
		{
			return ResourceRuleEvaluation.PassThrough(
				request.OriginalUrl,
				"pipeline.disabled");
		}
		if (request.IsFallbackRequest)
		{
			return ResourceRuleEvaluation.PassThrough(
				request.OriginalUrl,
				"pipeline.fallback");
		}
		if (request.IsRewrittenRequest)
		{
			return ResourceRuleEvaluation.PassThrough(
				request.OriginalUrl,
				"pipeline.rewrite_recursion");
		}

		foreach (IGrouping<int, RuleEntry> priorityGroup in _rules.GroupBy(entry => entry.Rule.Priority))
		{
			List<RuleMatch> matches = new List<RuleMatch>();
			foreach (RuleEntry entry in priorityGroup)
			{
				ResourceInterceptionPlan plan;
				try
				{
					plan = entry.Rule.Evaluate(request);
				}
				catch (Exception ex)
				{
					return ResourceRuleEvaluation.PassThrough(
						request.OriginalUrl,
						"pipeline.rule_exception",
						entry.Rule.Name + ": " + ex.GetType().Name);
				}

				if (plan == null)
				{
					return ResourceRuleEvaluation.PassThrough(
						request.OriginalUrl,
						"pipeline.invalid_plan",
						entry.Rule.Name + " returned null.");
				}
				if (!string.Equals(plan.OriginalUrl, request.OriginalUrl, StringComparison.Ordinal))
				{
					return ResourceRuleEvaluation.PassThrough(
						request.OriginalUrl,
						"pipeline.invalid_plan",
						entry.Rule.Name + " changed the original URL identity.");
				}
				if (plan.Outcome != ResourceInterceptionOutcome.PassThrough)
				{
					matches.Add(new RuleMatch(entry.Rule.Name, plan));
				}
			}

			if (matches.Count > 1)
			{
				return ResourceRuleEvaluation.PassThrough(
					request.OriginalUrl,
					"pipeline.priority_conflict",
					string.Join(",", matches.Select(match => match.RuleName)));
			}
			if (matches.Count == 1)
			{
				return ResourceRuleEvaluation.Match(matches[0].Plan, matches[0].RuleName);
			}
		}

		return ResourceRuleEvaluation.PassThrough(request.OriginalUrl, "pipeline.no_match");
	}

	private static bool IsReservedPriority(int priority)
	{
		return priority >= 1000 && priority <= 1099 ||
			priority >= 800 && priority <= 899 ||
			priority >= 600 && priority <= 699;
	}

	private sealed class RuleEntry
	{
		public RuleEntry(IResourceInterceptionRule rule, int registrationIndex)
		{
			Rule = rule;
			RegistrationIndex = registrationIndex;
		}

		public IResourceInterceptionRule Rule { get; }

		public int RegistrationIndex { get; }
	}

	private sealed class RuleMatch
	{
		public RuleMatch(string ruleName, ResourceInterceptionPlan plan)
		{
			RuleName = ruleName;
			Plan = plan;
		}

		public string RuleName { get; }

		public ResourceInterceptionPlan Plan { get; }
	}
}
