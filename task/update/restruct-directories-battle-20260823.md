# 阶段 7：Battle 目录与命名空间迁移（2026-08-23）

## 批次范围

本批次只迁移 Battle 模块的物理目录、命名空间和必要引用，不改变包解析、roster 合并、快照缓存、F3 窗口或头像生成行为，也未开始阶段 8。

## 实现

- `AolaBattleModels.cs`、`AolaBattlePacketParser.cs`、`AolaBattleStateTracker.cs` 已从项目根目录迁入 `Features/Battle/State/`，命名空间调整为 `AolaLoader.Features.Battle.State`。
- `AolaBattleAssistantForm.cs`、`AolaPetPortraitProvider.cs` 已从项目根目录迁入 `UI/Battle/`，命名空间调整为 `AolaLoader.UI.Battle`。
- `AolaMainForm`、`AolaCompositionRoot` 和 `BattleStateContractVerifier` 只增加或调整了必要的命名空间引用。
- `AolaSocketHack.Verify.csproj` 的三个 Battle 源码链接已同步到 `Features/Battle/State/` 的实际路径。
- 物理移动保持旧命名空间时，Loader 与 Verify 已分别构建通过；随后才调整命名空间并再次验证。

## 验证结果

- Loader Release 构建：PASS，输出 `analysis/build/AolaLoader/Release/net48/AolaLoader.exe`。
- Verify Release 构建：PASS。
- Loader 构建仍报告 CefSharp 87.1.132 的 4 条 `NU1903` 已知高危漏洞警告（两个 advisory 在还原和构建阶段各报告一次）；本批次未更新固定运行时。
- Verify `--self-test`：PASS，10 项边界自测全部通过，其中 `BattleState contract self-test: PASS`。
- PCAP replay：PASS；`exportable=164`、`failures=0`、`export_format=True`、`login_redacted=True`、`inner_plaintext=True`、`active_send=True`。
- `git diff --check`：PASS。

## 未完成项

头像 provider 仍只生成基于 View ID/名称的占位图；Battle Presentation 尚未实现；真实 Flash 战斗、F3 窗口关闭重开和缓存快照行为仍待阶段 9 实机回归。本批次不据静态构建将 Battle 状态改为 `Implemented`。
