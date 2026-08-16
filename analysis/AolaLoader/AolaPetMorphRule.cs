namespace AolaLoader;

internal sealed class AolaPetMorphRule
{
	public AolaPetMorphRule(string note, int originalId, int backpackId, int posterId)
	{
		Note = note ?? string.Empty;
		OriginalId = originalId;
		BackpackId = backpackId;
		PosterId = posterId;
	}

	public string Note { get; }

	public int OriginalId { get; }

	public int BackpackId { get; }

	public int PosterId { get; }
}
