// 架构角色：IThemeSelectionTarget 的测试替身，记录被应用的 themeId。
// 数据流：ThemeCoordinator 调用 -> 测试可观察的选择历史。
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
