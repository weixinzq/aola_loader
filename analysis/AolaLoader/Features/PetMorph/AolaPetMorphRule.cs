// 架构角色：表示一条运行期形态替换规则，是设置、协调器和资源规则之间的共享值对象。
// 数据流：PetMorphSettings -> AolaPetMorphRule -> movie/poster/package 规则与页面推送。
namespace AolaLoader.Features.PetMorph;

internal sealed class AolaPetMorphRule
{
	public AolaPetMorphRule(
		string note,
		int originalId,
		int backpackId,
		int posterSourceId,
		int posterId,
		bool hideOriginalModel = false,
		bool removeOriginalBackground = false,
		bool replaceBackpackIcon = false)
	{
		Note = note ?? string.Empty;
		OriginalId = originalId;
		BackpackId = backpackId;
		PosterSourceId = posterSourceId;
		PosterId = posterId;
		HideOriginalModel = hideOriginalModel;
		RemoveOriginalBackground = removeOriginalBackground;
		ReplaceBackpackIcon = replaceBackpackIcon;
	}

	public string Note { get; }

	public int OriginalId { get; }

	public int BackpackId { get; }

	public int PosterSourceId { get; }

	public int PosterId { get; }

	public bool HideOriginalModel { get; }

	public bool RemoveOriginalBackground { get; }

	public bool ReplaceBackpackIcon { get; }
}
