# 阶段 5：Theme Section 强类型边界

本批次增加 Theme 模块拥有的 `ThemeSettings` 和 `ThemeSettingsCodec`，冻结 `theme` Section Version 1。Codec 默认选择官方主题 0，只接受 Version 1，缺失 `SelectedThemeId` 时使用默认值，并把超出资源规则支持范围 0..9 的值规范为 0；序列化只写 Theme 自己拥有的字段。

生产 `AolaMainForm` 和旧 `AolaSettingsStore` 本批次没有切换。这样避免 Theme 先把文件迁移成 Section 容器后，仍使用 SchemaVersion 5 的 PetMorph 保存路径把新文档覆盖回旧格式，也避免短期双写。

`SettingsBoundaryVerifier` 现使用强类型 Theme codec 验证：无文件默认值、非法 ID 规范化、旧 SchemaVersion 5 的主题值迁移、UTF-8 无 BOM，以及保存 Theme 后 PetMorph、Battle 和未知根字段继续保留。完整构建、自测与 PCAP/主动发送基线通过。
