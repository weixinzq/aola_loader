using System;

namespace AolaLoader.Features.Battle.State;

internal interface IBattleStateSource : IDisposable
{
	AolaBattleSnapshot CurrentSnapshot { get; }

	event Action<AolaBattleSnapshot> SnapshotChanged;
}
