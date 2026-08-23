# 阶段 5：Battle Section 自有 DTO/Codec

本批次完成阶段 5 的 Battle 部分：为 Battle 模块建立最小 `BattleSettings` DTO 和 `BattleSettingsCodec`，冻结 `battle` Section key、Version 1。

## 实现

- 新增 `analysis/AolaLoader/Features/Battle/Settings/BattleSettings.cs`：DTO 只含预留表现字段（`HideDamageNumbers`、`HideHealingNumbers`、`SkipPetAttackActions`、`FightSkillEffect`、`MorphRules`），默认全部为禁用/空值，不引入任何新战斗功能。`MorphRules` 尚无定义 schema，规则对象按不透明防御性快照原样保留。
- `BattleSettingsCodec` 提供默认值、Version 检查、布尔/整数类型与 Int32 范围检查、MorphRules 数组校验、规范化与防御性复制；未知 Section 顶层字段仍由共享 store 合并保留。
- `LegacySettingsMigrator` 不再内联构造 Battle Section，改由 `BattleSettingsCodec.Serialize(CreateDefault())` 生成，旧 SchemaVersion 5 迁移与 Section store 共用同一正式边界；不存在新旧双写路径。
- `AolaSocketHack.Verify.csproj` 以共享源码链接方式编译 Battle Settings 文件，未新增程序集。

## 自动验证

`SettingsBoundaryVerifier` 新增 `VerifyTypedBattleSettings`，覆盖：

- 无文件时返回禁用默认值；
- 旧 SchemaVersion 5 迁移建立 Battle Version 1 默认 Section；
- 缺字段使用默认值；
- 不支持版本、错误类型字段、MorphRules 非数组时拒绝并回退默认且原文件字节不变；
- 未知 Section 字段与规则对象在保存后保留；
- 快照防御性复制（修改返回快照不影响后续加载）；
- Theme、PetMorph、Battle 任意顺序独立保存互不覆盖；
- 损坏的 Battle Section 不影响 Theme；
- 保存失败不破坏旧文件；
- 保存结果 UTF-8 无 BOM。

## 验证结果

```text
Loader Release 构建成功（仅保留 CefSharp 87 的 4 条 NU1903 已知高危漏洞警告）。
Verify Release 构建成功。
PacketHost boundary self-test: PASS
Settings boundary self-test: PASS
ResourceInterception contract self-test: PASS
BrowserHost contract self-test: PASS
BattleState contract self-test: PASS
Capture boundary self-test: PASS
client_bytes=12373 server_bytes=286678
sent=172 received=423 policy=1 exportable=164 failures=0
export_format=True login_redacted=True inner_plaintext=True active_send=True
Aola PCAP replay: PASS
```

## 已知限制

Battle 当前没有可配置行为，也未增加任何生产消费者或主窗体接线；真实 Battle/主题/形态运行回归仍待阶段 9。`SETTINGS_SPEC.md` 与 `BATTLE_SPEC.md` 保持 `Target`，未因静态验证通过而标记 `Implemented`。
