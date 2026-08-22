# Settings

Status: Target  
ContractVersion: 1  
OwnerPaths: `analysis/AolaLoader/Settings/**`, `analysis/AolaLoader/Features/*/*Settings*.cs`

## 职责

按稳定 key 加载和原子保存独立版本 Section；保留未知 Section/字段；将旧 SchemaVersion 5 文档一次性迁移。

## 非职责

不决定主题、形态或战斗行为，不暴露整个可变文档给功能模块，不协调 UI。

## 公开契约

`ISettingsSectionStore.Load<T>(key, defaults, migrate, validate)` 返回防御性快照；`Save<T>(key, value)` 返回明确结果并保留其他 Section。容器使用 `DocumentVersion: 1`，每个 Section 自有 `Version`。`LegacySettingsMigrator` 迁移 theme、petMorph，并建立默认 battle Section。

## 输入与输出

输入为路径、Section key、DTO、迁移和规范化函数；输出为不可变/防御性副本及加载/保存结果。

## 允许依赖

文件系统、JSON 库和各功能提供的 DTO/迁移函数。

## 禁止依赖

WinForms、CefSharp、PacketHost、协议类型和跨模块业务协调器。

## 线程与生命周期

同一存储实例串行化读改写；变更通知不得假定 UI 线程。Dispose 后不再发布通知。

## 异常及回退语义

文件/Section 缺失或损坏时返回模块默认值并报告诊断；保存先写同目录临时文件再原子替换，失败时保留旧文件。迁移成功后才替换旧格式。

## 设置所有权

Theme 只拥有 `theme`，PetMorph 只拥有 `petMorph`，Battle 只拥有 `battle`；各模块独立验证和提升 `Version`。

## 安全约束

UTF-8 无 BOM；设置中不得存储 SID、登录帧、账号密码或浏览器密文。

## 缓存语义

可缓存解析文档，但对调用方只返回快照；保存必须基于最新磁盘/受控锁并保留未知内容。

## 验证入口

无文件、SchemaVersion 5 迁移、缺字段、单 Section 损坏、未知内容保留、写入中断、无 BOM、Theme/PetMorph 独立更新。

## 完成标准

所有功能只读写自身 Section；旧文件安全迁移；无双写路径；自动验证和启动恢复通过。

## 已知限制

当前 `AolaSettingsStore` 是 SchemaVersion 5 整体 DTO，直接 `File.WriteAllText`，没有原子替换和 Section 隔离。

