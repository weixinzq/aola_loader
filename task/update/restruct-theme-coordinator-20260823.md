# 阶段 6 批次 1：ThemeCoordinator

本批次冻结 `IThemeCoordinator` 契约与测试替身，实现 `ThemeCoordinator`，并把主窗体的主题读取、菜单选项、切换和 Section 保存全部迁到协调器。

## 实现

- 新增 `Features/Theme/Coordination/ThemeCoordinationContracts.cs`：
  - `ThemeOption`：主题 ID 与显示名（0..9，0 = 默认）；
  - `ThemeChangeResult`：结构化结果，区分规则是否应用、设置是否保存、实际应用 ID 与错误；
  - `IThemeCoordinator`：`Options`、`Current`、`ApplyToRule`（仅更新资源规则）、`ApplyAndSave`（规则 + Section 保存）；
  - `IThemeSelectionTarget`：协调器与资源规则所有者之间的缝隙，输入为设置空间 ID（0..9）。
- 新增 `ThemeCoordinator`：持有 `ThemeSettingsCodec` 规范化、Section store 加载/保存与资源规则应用；模板缺失等规则错误转为 `RuleFailed`，保存失败保留旧文件并保持当前快照不变；主题 ID 越界按 codec 规范化到默认。
- 新增 `Testing/ManualThemeSelectionTarget` 测试替身。
- `AolaThemeRequestHandler` 实现 `IThemeSelectionTarget`，把设置空间 0 映射为规则空间 -1（完全放行），1..9 直接应用。
- `AolaMainForm`：删除 `_themeSettings`/`_themeSettingsCodec`/`ApplySavedTheme`/`TrySaveThemeSettings`，主题菜单改由 `_themeCoordinator.Options` 构建，启动恢复与切换统一走协调器；未改动其他模块与窗口生命周期。

## 自动验证

新增 `ThemeCoordinatorVerifier`（链接同一源码，不新增程序集），覆盖：

- 无文件默认主题与 10 个固定选项；
- `ApplyToRule` 应用到规则但不落盘、越界规范化、0 走默认；
- `ApplyAndSave` 保存 `theme` Section、保留未知字段、无 BOM、重载恢复；
- 规则拒绝（模板缺失）时不落盘并返回错误；
- 保存失败时规则仍已应用、当前快照不变、旧文件字节不变；
- 从已保存 Section 恢复主题。

## 验证结果

```text
Loader Release 构建成功（仅保留 CefSharp 87 的 4 条 NU1903 已知高危漏洞警告）。
Verify Release 构建成功。
PacketHost boundary self-test: PASS
Settings boundary self-test: PASS
ThemeCoordinator boundary self-test: PASS
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

主窗体仍持有 `AolaThemeRequestHandler` 并负责 PetMorph 接线、浏览器创建和子窗口管理；PetMorphCoordinator、BrowserSession 生产适配、ChildWindowCoordinator 与 CompositionRoot 属于后续批次。主题默认/替换的真实 Flash 与缓存路径仍需阶段 9 实机验证，THEME_SPEC 保持 `Target`。
