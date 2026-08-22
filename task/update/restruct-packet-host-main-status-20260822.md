# 阶段 4：主窗状态迁移与 PacketHost 收口

本批次把 `AolaMainForm` 状态栏从 `AolaHookHostService.StatusReceived` 直接订阅迁入主窗体持有的共享 `IAolaPacketEventSource`。现有 `InvokeRequired/BeginInvoke` UI 线程切换保持不变；关闭时先退订主窗状态、关闭子窗口并释放 Logger/Tracker，再释放 PacketHost，避免消费者晚于事件源存活。

新增 `PacketHostSourceGuardVerifier`：从仓库根扫描 `analysis/AolaLoader/**/*.cs`，禁止除 `PacketHost/AolaHookHostAdapter.cs` 外的文件引用 `AolaHookHostService.PacketReceived`、`StatusReceived` 或 `SendCompleted`。该守卫在每次 `AolaSocketHack.Verify` 自测和 PCAP 回放前执行。

至此阶段 4 的四个消费者均完成生产迁移。Release 构建、自测、严格发送方向策略、接收日志临时文件验证、Battle tracker 手动事件源验证和 PCAP/主动发送基线均通过。真实 WinForms/Flash 会话尚未执行，因此主窗状态后台 marshal、PacketsForm 关闭/重开和真实战斗通知仍标记为运行时待验证。
