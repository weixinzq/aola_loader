# 阶段 4：ReceiveLogger 迁移到 PacketHost

本批次只迁移 `AolaReceiveLogger` 的事件来源和生命周期。Logger 构造函数现在显式接收 `IAolaPacketEventSource`，订阅其 `PacketReceived`，并在 `Dispose` 时退订；它不拥有也不释放事件源。主窗体开始创建一个长期 `AolaHookHostAdapter`，把它注入 Logger，并在 Logger 释放后再释放适配器。

日志业务语义未改变：只接受方向为“接收”的事件；保留 UTF-8 无 BOM、每行一个 JSON 对象、解密参数、`InnerPlainHex` 与接收侧 `RawHex`；发送方向不会进入日志。写入失败后的本地状态报告仍沿用现有路径，本批次没有改变 IPC DTO、登录脱敏或协议解析。

`AolaSocketHack.Verify --self-test` 新增真实临时文件验证，覆盖发送过滤、缓冲后保留、无 BOM、参数/明文/原始帧字段，以及 Logger 释放后事件源仍可用且文件不再增长。Battle tracker、PacketsForm 和主窗状态将在后续三个独立批次迁移。
