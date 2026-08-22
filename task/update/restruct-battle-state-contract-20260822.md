# 重构阶段 2：BattleStateSource 契约（2026-08-22）

## 批次范围

本批次只冻结 Battle ContractVersion 1 的状态源接口并提供无 UI、无 IPC 的手动测试事件源。没有移动或修改现有 `AolaBattleStateTracker`、战斗解析器、F3 窗体、头像 provider，也没有迁移静态 IPC 订阅。

## 实现

- `IBattleStateSource`：提供 `CurrentSnapshot`、`SnapshotChanged` 和 `IDisposable` 生命周期边界。
- `ManualBattleStateSource`：为后续协调器和 UI 迁移提供可控的缓存快照和事件源。
- 初始快照、读取快照、发布快照及每个订阅者收到的快照均独立深复制。
- 单个订阅者异常不会阻断其他订阅者；释放后清除订阅并拒绝继续读取、发布或新增订阅。

契约复用现有 `AolaBattleSnapshot` 模型，避免阶段 2 同时复制模型或改变生产 Tracker 语义。模型和 Tracker 的物理迁移留在后续 Battle 阶段。

## 自动验证

`BattleState contract self-test` 覆盖：

- 构造参数和 `CurrentSnapshot` 的防御性复制；
- 发布后缓存快照不受调用方修改；
- 不同订阅者之间快照隔离及异常隔离；
- 活跃宠物和场下宠物同时保留；
- 最终六维分段/总值和技能 PP/CD 保留；
- Dispose 后的生命周期约束。

验证器直接链接 Battle 模型、契约和测试替身源码，没有新增生产程序集。

## 阶段结论与待办

阶段 2 规划的五类边界现已全部具备最小验证或测试替身：PacketHost、Settings、ResourceInterception、BrowserHost/PageBridge、BattleStateSource。旧生产调用路径仍保持不变，各模块规格继续标记为 `Target`。

下一阶段按 `task/restruct.md` 进入阶段 3 ResourceRulePipeline；Battle Tracker 对 `IBattleStateSource` 和 PacketHost 的生产接线属于后续消费者迁移，必须单独验证订阅、线程、缓存和 Dispose 行为。
