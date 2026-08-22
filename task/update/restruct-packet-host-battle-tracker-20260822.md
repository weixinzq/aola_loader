# 阶段 4：BattleStateTracker 迁移到 PacketHost

本批次只迁移 `AolaBattleStateTracker` 的事件来源和状态契约接线。Tracker 构造函数现在显式接收 `IAolaPacketEventSource`，订阅其 `PacketReceived`，实现已冻结的 `IBattleStateSource`，并在 `Dispose` 时退订；它不拥有也不释放共享 PacketHost。主窗体把与 ReceiveLogger 相同的长期 `AolaHookHostAdapter` 注入 Tracker。

战斗解析与合并算法未改变：`2303` roster 重置、近期 `2303/2304` 跨 `2401` 保留、按 UQI 后按战斗槽位合并、场下宠物、最终六维、技能 PP/CD 和既有结束命令语义均保持原实现。

`BattleState contract self-test` 新增生产 Tracker 接线验证：发送方向的 `2404` 不产生快照，接收方向的 `2404` 产生结束快照；Tracker 释放后继续向手动 PacketHost 发布不会再次通知，事件源本身仍由其所有者释放。真实 Flash 战斗运行回归尚未执行。
