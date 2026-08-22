# Battle

Status: Target  
ContractVersion: 1  
OwnerPaths: `analysis/AolaLoader/Features/Battle/**`, `analysis/AolaLoader/UI/Battle/**`

## 职责

State 子模块消费接收包、解析 roster/增量并发布不可变快照；UI 展示完整敌我数据；Presentation 为未来视觉规则保留独立边界。

## 非职责

State 不依赖 WinForms/CefSharp，不过滤网络捕获，不修改协议消息；Presentation 不改变 State 包处理契约；头像不决定 roster 正确性。

## 公开契约

`IBattleStateSource` 提供 `CurrentSnapshot`、`SnapshotChanged` 和生命周期释放；当前契约位于 `Features/Battle/State`。快照包含战斗生命周期、双方、全部宠物、最终六维、HP 和技能 PP/CD。未来 `IBattlePresentationRule` 只生成资源/表现计划，不消费或改写协议。

## 输入与输出

输入为 PacketHost 的接收方向 DTO；输出为防御性战斗快照和摘要。UI 输入快照，输出只限呈现。

## 允许依赖

State 可依赖 PacketHost 契约和 Contracts DTO；UI 可依赖 State 与头像 provider；Presentation 可依赖 ResourceInterception 契约。

## 禁止依赖

State 禁止 WinForms、CefSharp、Settings JSON 和 Theme/PetMorph 实现；UI 不直接订阅静态 IPC；Presentation 不依赖协议 parser 内部状态。

## 线程与生命周期

PacketHost 事件可在后台线程；State 在锁内更新、锁外发布快照。UI marshal 到 WinForms 线程。Dispose 后退订且不再通知。

## 异常及回退语义

未知/畸形包忽略并保留最后有效快照；解析失败不清空 roster。窗口晚开读取缓存；头像失败使用占位图，不影响数据。

## 设置所有权

独占 `battle` Section，Version 1。可预留表现字段，但未实现功能保持禁用；不得修改 Theme/PetMorph DTO。

## 安全约束

只消费已脱敏 DTO；不展示登录信息或加密原始扩展。接收包不得进入发送表格。

## 缓存语义

`2303` 重置 roster；兼容的近期 roster 可跨 `2401`；按 UQI 后按槽位合并；结束命令重置战斗状态。快照需防御性复制。

## 验证入口

`BattleState contract self-test` 验证初始值、读取值、发布值和逐订阅者通知均为防御性深复制，覆盖全部场下宠物、最终六维、PP/CD、订阅者异常隔离、晚开读取缓存与 Dispose；同时用手动 PacketHost 验证生产 Tracker 只处理接收方向、发布结束快照并在释放后停止消费。2303/2304 完整 roster、2401 保留、后续更新、UQI/槽位合并和结束命令仍由现有 Tracker/解析回归覆盖。

## 完成标准

State/UI/Presentation 物理边界清晰，Tracker 只依赖 PacketHost，F3 与缓存行为不变，自动解析及真实战斗回归通过。

## 已知限制

ContractVersion 1 已冻结；阶段 4 已让生产 tracker 实现 `IBattleStateSource` 并只依赖 `IAolaPacketEventSource`，不再直接订阅静态 IPC。文件仍平铺，头像 provider 仍生成占位图，战斗 Presentation 尚未实现，真实战斗运行回归仍待完成。
