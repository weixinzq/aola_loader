using System.Collections.Generic;

namespace AolaLoader.Features.Theme.Coordination.Testing;

/// <summary>
/// In-memory IThemeSelectionTarget double that records settings-space theme ids.
/// </summary>
internal sealed class ManualThemeSelectionTarget : IThemeSelectionTarget
{
	private readonly List<int> _appliedIds = new List<int>();

	public IReadOnlyList<int> AppliedIds => _appliedIds;

	public int LastAppliedId => _appliedIds.Count == 0 ? int.MinValue : _appliedIds[_appliedIds.Count - 1];

	public void SetSelectedThemeId(int themeId)
	{
		_appliedIds.Add(themeId);
	}
}
