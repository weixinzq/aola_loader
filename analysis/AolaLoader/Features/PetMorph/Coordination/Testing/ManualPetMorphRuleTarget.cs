// 架构角色：IPetMorphRuleTarget 的测试替身，用于验证协调器的规则安装顺序和参数。
// 数据流：规则列表/开关 -> 调用记录和可注入验证结果。
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
		IReadOnlyDictionary<int, int> skinMappings = null)
	{
		IsLiveBridgeAvailable = liveBridgeAvailable;
		ValidationError = validationError;
		SkinMappings = skinMappings ?? new Dictionary<int, int>();
	}

	public bool IsLiveBridgeAvailable { get; set; }

	public string ValidationError { get; set; }

	public IReadOnlyDictionary<int, int> SkinMappings { get; set; }

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

	public Task<IReadOnlyDictionary<int, int>> GetAvailableLiveSkinMappingsAsync(
		IReadOnlyList<AolaPetMorphRule> rules,
		bool enabled)
	{
		return Task.FromResult(SkinMappings);
	}
}
