# 阶段 7：PacketHost 接收日志消费者目录与命名空间迁移（2026-08-23）

## 批次范围

本批次只迁移 `AolaReceiveLogger` 的物理目录、命名空间和必要引用，不改变仅接收过滤、JSONL 格式、UTF-8 无 BOM、缓存上限、写入失败处理或生命周期行为，也未迁移 Packets UI、主窗状态或开始阶段 8。

## 实现

- `AolaReceiveLogger.cs` 已从项目根目录迁入 `PacketHost/Consumers/`，命名空间调整为 `AolaLoader.PacketHost.Consumers`。
- `AolaMainForm`、`AolaCompositionRoot` 和 `PacketHostBoundaryVerifier` 只增加或调整了必要的消费者命名空间引用。
- `AolaSocketHack.Verify.csproj` 的 ReceiveLogger 源码链接已同步到实际路径。
- 物理移动保持旧命名空间时，Loader 与 Verify 已分别构建通过；随后才调整命名空间并再次验证。
- `PACKET_HOST_SPEC.md` 已记录消费者实际路径，并关闭“适配器尚待 CompositionRoot 收口”的过期限制；真实运行限制保持不变。

## 验证结果

- Loader Release 构建：PASS，输出 `analysis/build/AolaLoader/Release/net48/AolaLoader.exe`。
- Verify Release 构建：PASS。
- Loader 构建仍报告 CefSharp 87.1.132 的 4 条 `NU1903` 已知高危漏洞警告（两个 advisory 在还原和构建阶段各报告一次）；本批次未更新固定运行时。
- Verify `--self-test`：PASS，10 项边界自测全部通过，其中 `PacketHost boundary self-test: PASS`。
- PCAP replay：PASS；`exportable=164`、`failures=0`、`export_format=True`、`login_redacted=True`、`inner_plaintext=True`、`active_send=True`。
- `git diff --check`：PASS。

## 未完成项

PacketHost 的真实 WinForms/Flash 后台状态更新、日志保留以及相关窗口关闭重开仍待阶段 9 实机回归。本批次不迁移 `AolaPacketsForm` 或主窗体，也不据静态验证清理任何兼容路径。
