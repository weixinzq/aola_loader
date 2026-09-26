// 架构角色：构造 PetMorph live bridge 的目标皮肤候选，不执行网络探测或页面调用。
// 数据流：规则快照 -> BackpackId 默认映射 + PosterId 显式覆盖 -> 每个源 ID 的唯一候选。
using System.Collections.Generic;
using System.Linq;

namespace AolaLoader.Features.PetMorph.Coordination;

internal static class PetMorphLiveSkinMapping
{
	// 闪耀背景同时校验压缩响应长度和 SWF 声明长度；5436 的官方资源分别约为 16.8 MB 和 21.0 MB。
	public const int MaximumBackgroundSwfBytes = 32 * 1024 * 1024;

	public static IReadOnlyDictionary<int, int> BuildCandidates(IEnumerable<AolaPetMorphRule> rules)
	{
		AolaPetMorphRule[] snapshot = (rules ?? Enumerable.Empty<AolaPetMorphRule>())
			.Where(rule => rule != null)
			.ToArray();
		IEnumerable<KeyValuePair<int, int>> backpackCandidates = snapshot
			.Where(rule => rule.OriginalId > 0 && rule.BackpackId > 0 && rule.PosterId <= 0)
			.Select(rule => new KeyValuePair<int, int>(rule.OriginalId, rule.BackpackId));
		IEnumerable<KeyValuePair<int, int>> explicitPosterCandidates = snapshot
			.Where(rule => rule.PosterId > 0)
			.Select(rule => new KeyValuePair<int, int>(
				rule.PosterSourceId > 0 ? rule.PosterSourceId : rule.OriginalId,
				rule.PosterId))
			.Where(pair => pair.Key > 0);
		return backpackCandidates.Concat(explicitPosterCandidates)
			.GroupBy(pair => pair.Key)
			.Select(group => group.Last())
			.ToDictionary(pair => pair.Key, pair => pair.Value);
	}
}
