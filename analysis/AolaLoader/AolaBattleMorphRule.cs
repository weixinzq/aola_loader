namespace AolaLoader;

internal sealed class AolaBattleMorphRule
{
	public AolaBattleMorphRule(
		string note,
		int sourceId,
		int targetId,
		BattleScope scope = BattleScope.Both,
		bool enabled = true)
	{
		Note = note ?? string.Empty;
		SourceId = sourceId;
		TargetId = targetId;
		Scope = scope;
		Enabled = enabled;
	}

	public string Note { get; }

	public int SourceId { get; }

	public int TargetId { get; }

	public BattleScope Scope { get; }

	public bool Enabled { get; }

	public AolaBattleMorphRule WithEnabled(bool enabled)
	{
		return new AolaBattleMorphRule(Note, SourceId, TargetId, Scope, enabled);
	}
}

internal enum BattleScope
{
	Self = 0,
	Enemy = 1,
	Both = 2
}
