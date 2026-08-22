# 阶段 5：PetMorph Section 生产迁移

本批次增加 PetMorph 模块拥有的 `PetMorphSettings`、`PetMorphRuleSettings` 和 `PetMorphSettingsCodec`，冻结 `petMorph` Section Version 1，并把主窗体的形态设置读取、面板初始值、规则保存和页面热推送快照全部迁入该强类型边界。

Codec 提供默认关闭、LiveBridge 默认开启、缺失布尔字段补全、字段类型和 Int32 范围检查、无效源规则过滤及防御性复制。Section 顶层未知字段由共享 store 合并保留；规则 DTO 额外携带未知字段快照，因此当前版本规则数组重新保存时也不会丢失未来字段。

中央 `AolaAppSettings`、`AolaPetMorphRuleData` 和临时 `AolaSettingsStore` 兼容桥已从代码中移除。Theme 与 PetMorph 现在共用原子 Section store，但各自只保存自己的 key，不存在 SchemaVersion 5 回写或新旧双写路径。

验证覆盖旧 SchemaVersion 5 同时迁移 Theme/PetMorph、缺失字段默认、无效规则过滤、损坏字段不覆写、规则级未知字段保留、Theme/PetMorph 独立保存、Battle/未知根字段保留及 UTF-8 无 BOM。Release 构建、自测和 PCAP/主动发送基线通过；真实形态面板保存、热推送和新进程恢复仍待运行验证。
