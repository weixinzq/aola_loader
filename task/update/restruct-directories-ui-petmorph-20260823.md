# 阶段 7：PetMorph UI 目录与命名空间迁移（2026-08-23）

本批次只把 `AolaPetMorphForm.cs` 从项目根目录迁入 `UI/PetMorph/`，命名空间改为 `AolaLoader.UI.PetMorph`，并在 `AolaMainForm` 增加必要引用。规则校验、保存、热推送、控件行为和窗口生命周期均未改变。

物理移动保持旧命名空间时，Loader 与 Verify 构建通过；随后调整命名空间并再次构建通过。沙箱内 Loader 构建曾因 `analysis/obj` 临时文件写入被拒绝而失败，使用相同源码在获准的沙箱外重跑成功，该失败不属于编译或功能回归。

最终验证：10 项边界自测全部 PASS；PCAP replay PASS，保持 `exportable=164`、`failures=0`、`export_format=True`、`login_redacted=True`、`inner_plaintext=True`、`active_send=True`；移动文件比较仅含预期命名空间变化；`git diff --check` PASS。真实形态面板保存、热推送、关闭重开和新进程恢复仍待阶段 9 实机回归。
