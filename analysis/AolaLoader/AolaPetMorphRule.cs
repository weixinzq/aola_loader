namespace AolaLoader;

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
