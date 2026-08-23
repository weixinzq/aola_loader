# 阶段 7：Packets UI 目录与命名空间迁移（2026-08-23）

## 批次范围

本批次只迁移 `AolaPacketsForm` 的物理目录、命名空间和必要引用，不改变发送方向过滤、列表容量、包详情、严格 Loader 导出、`:ext_seq;` 清理、主动发送或窗口生命周期行为，也未迁移其他 UI 或开始阶段 8。

## 实现

- `AolaPacketsForm.cs` 已从项目根目录迁入现有 `UI/Packets/`，与 `SendPacketVisibility.cs` 一同使用 `AolaLoader.UI.Packets` 命名空间。
- `AolaMainForm` 只增加了必要的 `AolaLoader.UI.Packets` 引用。
- 物理移动保持旧命名空间时，Loader 与 Verify 已分别构建通过；随后才调整命名空间并再次验证。
- `PACKET_HOST_SPEC.md` 已记录发送包表格及方向策略的实际 UI 路径。

## 验证结果

- Loader Release 构建：PASS，输出 `analysis/build/AolaLoader/Release/net48/AolaLoader.exe`。
- Verify Release 构建：PASS。
- Loader 构建仍报告 CefSharp 87.1.132 的 4 条 `NU1903` 已知高危漏洞警告（两个 advisory 在还原和构建阶段各报告一次）；本批次未更新固定运行时。
- Verify `--self-test`：PASS，10 项边界自测全部通过，其中 `PacketHost boundary self-test: PASS` 覆盖精确发送方向策略。
- PCAP replay：PASS；`exportable=164`、`failures=0`、`export_format=True`、`login_redacted=True`、`inner_plaintext=True`、`active_send=True`。
- `git diff --check`：PASS。

## 未完成项

真实 WinForms/Flash 会话中的发送表格、窗口关闭重开和独立连接主动发送仍待阶段 9 实机回归。本批次不迁移 PetMorph UI、MainForm 或其他平铺文件，也不清理兼容路径。
