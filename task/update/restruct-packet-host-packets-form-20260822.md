# 阶段 4：AolaPacketsForm 迁移到 PacketHost

本批次把 `AolaPacketsForm` 的 `PacketReceived`、`StatusReceived`、`SendCompleted` 三个订阅和主动发送入口迁入 `IAolaPacketEventSource`。窗口构造函数显式接收共享 PacketHost；关闭时只退订自己的三个事件，不释放共享事件源。主窗体创建窗口时传入与 Logger、Battle tracker 相同的长期 `AolaHookHostAdapter`。

抓包表格的方向约束被提取为无 WinForms 依赖的 `SendPacketVisibility`：只有 `Direction` 精确等于“发送”才可见，空值、“接收”、尾随空格或英文值均被拒绝。现有 `InvokeRequired/BeginInvoke` 路径、5000 条上限、明文参数与 `InnerPlainHex` 详情、严格 Loader 导出、用户 `:ext_seq;` 移除和发送目标选择均保持不变；加密扩展 `RawHex` 未恢复到详情 UI。

验证器覆盖精确方向策略和 PacketHost 的结构化 `QueueSend`；PCAP 回放继续覆盖 `export_format=True`、`login_redacted=True`、`inner_plaintext=True` 与 `active_send=True`。本批次没有启动真实 WinForms 窗口，因此后台回调的 UI marshal 和关闭窗口后的交互仍需运行时复核。
