// 架构角色：暴露只读 packet-derived 战斗快照和变更事件，隐藏 tracker 的合并实现。
// 数据流：状态生产者 -> UI、性能记录、阵容与战斗序列消费者。
using System;

namespace AolaLoader.Features.Battle.State;

internal interface IBattleStateSource : IDisposable
{
	AolaBattleSnapshot CurrentSnapshot { get; }

	event Action<AolaBattleSnapshot> SnapshotChanged;
}
