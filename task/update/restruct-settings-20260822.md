# 重构阶段 2：Settings Section 存储（2026-08-22）

## 批次范围

本批次实现 Settings ContractVersion 1 的 Section 存储、新文档格式、原子写入和旧 SchemaVersion 5 文档迁移。旧 `AolaSettingsStore` 与 `AolaAppSettings` 保持生产接线；本批次不迁移 Theme/PetMorph 消费者，不读取或改写用户实际 `settings.json`，也不建立双写路径。

## 实现

- `ISettingsSectionStore`：按稳定 key 加载/保存一个 Section，并返回明确结果。
- `ISettingsSectionCodec<T>`：由模块拥有默认值、版本迁移、规范化和 JSON 转换。
- `JsonSettingsSectionStore`：使用 `DocumentVersion: 1`/`Sections` 容器；每次从最新文件读改写，返回防御性快照，并递归合并保留未知字段及未知 Section。
- `AtomicSettingsWriter`：UTF-8 无 BOM，同目录唯一临时文件，刷新到磁盘后使用 `File.Replace` 或首次 `File.Move`；失败清理临时文件且不破坏旧文件。
- `LegacySettingsMigrator`：只识别 SchemaVersion 5，将 Theme/PetMorph 字段迁入 Version 1 Section，为旧规则补齐三个 false 布尔值，并建立禁用状态的 Battle Version 1 Section。

旧文档加载时，只有结构迁移、目标 Section codec 的反序列化/规范化和原子保存均成功才返回迁移值；任何迁移、codec 或落盘失败都保留原文件并返回模块默认值。旧文档的未知顶层字段会保留，新文档保存时未知根字段、Section 和 Section 内字段均保留。

## 自动验证

`Settings boundary self-test` 使用隔离临时目录覆盖：

- 无文件时返回默认值；
- 保存、重新加载和调用方修改不污染后续快照；
- UTF-8 无 BOM；
- 未知根字段、未知 Section 和 Section 内未知字段保留；
- Theme 与 PetMorph 独立更新；
- 单个损坏 Section 不影响其他 Section；
- SchemaVersion 5 迁移、缺失旧布尔默认值和 Battle 默认 Section；
- 非法旧字段导致迁移失败且原始证据字节不变；
- 模块 codec 拒绝迁移结果时原始旧文件字节不变；
- 注入写入失败后保存返回失败且旧文件字节不变。

验证器直接链接 Settings 模块同一源码，没有新增程序集。

## 待办

阶段 5 需要依次新增 Theme、PetMorph、Battle 正式 DTO/codec，再由协调器切换读取和保存；切换前不得启用新格式生产写入。完成旧设置升级、关闭重启和真实功能恢复验证后，才能删除旧中央设置路径并提升模块状态。
