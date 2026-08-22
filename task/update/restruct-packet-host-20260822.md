# 重构阶段 2：PacketHost 接口与兼容适配器（2026-08-22）

## 批次范围

本批次只实现 PacketHost ContractVersion 1 的接口、静态 IPC 兼容适配器和测试替身。按照 `task/restruct.md` 的渐进迁移规则，`AolaReceiveLogger`、`AolaBattleStateTracker`、`AolaPacketsForm` 和 `AolaMainForm` 暂时继续走旧静态事件路径；本批次不修改运行接线或可见行为。

## 实现

- `IAolaPacketEventSource`：三类 DTO 事件和结构化 `QueueSend`。
- `AolaHookHostAdapter`：订阅 `AolaHookHostService` 静态事件，逐订阅者隔离异常，Dispose 时退订并保证返回后不再分发。
- `ManualAolaPacketEventSource`：不连接 remoting 的内存测试事件源，供后续消费者迁移使用。
- `PacketEventDispatch`：PacketHost 域内的逐订阅者安全分发逻辑。
- `AolaSocketHack.Verify` 直接链接上述同一源码，避免新增程序集或复制验证实现。

## 验证覆盖

`PacketHost boundary self-test` 覆盖：

- 包、状态和主动发送结果转发；
- 首个订阅者抛出异常后，后续订阅者仍收到事件；
- Dispose 后静态 IPC 发布不再到达适配器；
- Dispose 后 QueueSend 明确抛出 `ObjectDisposedException`；
- 结构化请求进入原有有界队列并可按进程取回；
- 手动测试事件源的异常隔离、发送替身和释放语义。

## 兼容与待办

适配器当前尚未由 CompositionRoot 创建，因此不能声称已成为生产环境唯一静态订阅者。后续阶段 4 按 logger、Battle tracker、PacketsForm、主窗状态的顺序迁移，每个消费者都需验证后台事件到 UI 线程的 marshal 和关闭退订；全部完成后才添加静态事件源码守卫并将模块状态提升。

