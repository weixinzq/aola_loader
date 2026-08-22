# 阶段 5：Theme Section 生产迁移

本批次把主窗体的主题读取与保存正式迁入 `JsonSettingsSectionStore` 和模块自有 `ThemeSettingsCodec`。启动时从 `theme` Section 读取选中主题；用户切换主题时只保存 `theme`，不再修改或序列化中央 `AolaAppSettings.SelectedThemeId`。保存失败仍反馈到状态栏，资源规则的当前内存选择行为保持原实现。

为支持逐模块迁移，旧 `AolaSettingsStore` 被收窄为临时 PetMorph 兼容桥：内部复用同一个 Section store，以原子方式读取和保存 `petMorph`，只序列化 Version、Enabled、LiveBridgeEnabled 和 Rules。它不写 Theme，不覆盖 Battle 或未知字段，也不会把已迁移文档重新写成 SchemaVersion 5。该桥将在 PetMorph 正式 codec 接线后删除。

验证器覆盖完整过渡序列：从带 Theme/PetMorph/未知根字段的 SchemaVersion 5 文件加载 PetMorph，读取并修改强类型 Theme，再通过兼容桥保存 PetMorph；最终文档保持 DocumentVersion 1、主题新值、PetMorph 新值、默认 Battle 和未知字段，且 UTF-8 无 BOM。Release 构建、自测和 PCAP/主动发送基线通过；真实 UI 切换和进程重启恢复仍待运行验证。
