# 阶段 7：PetMorph 领域文件目录与命名空间迁移（2026-08-23）

本批次只把 `AolaPetMorphRule.cs` 与 `AolaPetPosterCatalog.cs` 从项目根目录迁入 `Features/PetMorph/`，命名空间改为 `AolaLoader.Features.PetMorph`，并同步 Verify 源码链接及必要引用。规则字段、目录解析、映射查找和资源行为均未改变。

物理移动保持旧命名空间时，Loader 与 Verify 构建通过；随后调整命名空间并再次构建通过。沙箱内构建曾因 `analysis/obj` 写入被拒绝而失败，获准在沙箱外使用相同命令后通过，不属于源码回归。

最终验证：10 项边界自测全部 PASS；PCAP replay PASS，保持 `exportable=164`、`failures=0`、`export_format=True`、`login_redacted=True`、`inner_plaintext=True`、`active_send=True`；两个移动文件比较仅含预期命名空间变化；`git diff --check` PASS。真实 PetMorph 与海报资源运行验证仍待阶段 9。
