using System.Collections.Generic;
using System.Threading.Tasks;

namespace AolaLoader.Features.PetMorph.Coordination.Testing;

/// <summary>
/// In-memory IPetMorphRuleTarget double for coordinator verification.
/// </summary>
internal sealed class ManualPetMorphRuleTarget : IPetMorphRuleTarget
{
	private readonly List<AolaPetMorphRule> _lastRules = new List<AolaPetMorphRule>();

	public ManualPetMorphRuleTarget(
		bool liveBridgeAvailable = true,
		string validationError = null,
		IReadOnlyDictionary<int, int> posterMappings = null)
	{
		IsLiveBridgeAvailable = liveBridgeAvailable;
		ValidationError = validationError;
		PosterMappings = posterMappings ?? new Dictionary<int, int>();
	}

	public bool IsLiveBridgeAvailable { get; set; }

	public string ValidationError { get; set; }

	public IReadOnlyDictionary<int, int> PosterMappings { get; set; }

	public IReadOnlyList<AolaPetMorphRule> LastRules => _lastRules;

	public bool LastEnabled { get; private set; }

	public int SetRulesCallCount { get; private set; }

	public void SetRules(IReadOnlyList<AolaPetMorphRule> rules, bool enabled)
	{
		SetRulesCallCount++;
		_lastRules.Clear();
		if (rules != null)
		{
			foreach (AolaPetMorphRule rule in rules)
			{
				_lastRules.Add(rule);
			}
		}
		LastEnabled = enabled;
	}

	public string ValidateRule(AolaPetMorphRule rule)
	{
		return ValidationError;
	}

	public Task<IReadOnlyDictionary<int, int>> GetAvailableLivePosterMappingsAsync(
		IReadOnlyList<AolaPetMorphRule> rules,
		bool enabled)
	{
		return Task.FromResult(PosterMappings);
	}
}
