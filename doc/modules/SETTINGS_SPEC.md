# Settings

Status: Implemented
ContractVersion: 1  
OwnerPaths: `analysis/AolaLoader/Settings/**`, `analysis/AolaLoader/Features/*/*Settings*.cs`

## 职责

按稳定 key 加载和原子保存独立版本 Section；保留未知 Section/字段；将旧 SchemaVersion 5 文档一次性迁移。

## 非职责

不决定主题、形态或战斗行为，不暴露整个可变文档给功能模块，不协调 UI。

## 公开契约

`ISettingsSectionStore.Load<T>(key, codec)` 返回防御性快照；`Save<T>(key, value, codec)` 返回明确结果并保留其他 Section。模块拥有的 `ISettingsSectionCodec<T>` 提供默认值、Section 版本迁移、规范化和序列化。容器使用 `DocumentVersion: 1`，每个 Section 自有 `Version`。`LegacySettingsMigrator` 迁移 theme、petMorph，并建立默认 battle Section。

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

战斗模型全部映射统一保存在程序目录的 `settings.json` → `Sections.battle.MorphRules` 数组，单项包含 `Note`、`SourceViewId`、`TargetViewId`。列表添加/删除后点击“保存并应用”写入完整数组；重启恢复全部规则。删除最后一条会关闭模型替换并可保存空数组，不创建额外映射文件或双写路径。

## 安全约束

UTF-8 无 BOM；设置中不得存储 SID、登录帧、账号密码或浏览器密文。

## 缓存语义

可缓存解析文档，但对调用方只返回快照；保存必须基于最新磁盘/受控锁并保留未知内容。

## 验证入口

`AolaSocketHack.Verify --self-test` 覆盖无文件、SchemaVersion 5 迁移、缺字段、单 Section 损坏、未知内容保留、写入中断、无 BOM、Theme/PetMorph 独立更新和防御性快照。Theme 强类型 codec 验证版本拒绝、ID 规范化和旧值迁移；PetMorph 强类型 codec 验证缺失字段默认值、无效规则过滤、损坏字段拒绝、规则内未知字段保留，以及 Theme 与 PetMorph 按任意顺序保存时互不覆盖。Battle 强类型 codec 验证无文件默认、旧迁移建立 Version 6、Version 1/2 的 `SkipPetAttackActions`、Version 3 的 `SkipBattlePresentation` 与 Version 4 的 `SkipAttackAnimation` 均迁移为当前 `SkipBattlePresentation`，并覆盖缺字段默认、版本与字段类型拒绝、强类型 MorphRules、无法识别旧规则的禁用报告、任意顺序独立保存、损坏 Section 隔离和保存失败保留旧文件。

## 完成标准

所有功能只读写自身 Section；旧文件安全迁移；无双写路径；自动验证和启动恢复通过。

## 已知限制

Theme 与 PetMorph 使用模块自有 Version 1 codec，Battle 使用 Version 6；旧 SchemaVersion 5 只经 `LegacySettingsMigrator` 单向原子迁移，不存在旧格式回写或双写路径。Battle Version 6 规范字段为 `HideDamageNumbers`、`HideHealingNumbers`、`SkipBattlePresentation`、`BattleMorphEnabled` 和 `MorphRules[{Note,SourceViewId,TargetViewId}]`，序列化后不保留已迁移的旧跳过字段。旧版模型规则只迁移可识别字段，未知形状不猜测转换且不会自动启用。模型规则保存时完成六分片预检；状态桥成功返回 `active=false` 且 `ended=false` 时切换，战斗中则等待该清理边界后用于下一场，无法确认时由下次进程启动恢复。
