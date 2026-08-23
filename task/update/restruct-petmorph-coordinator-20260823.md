# 阶段 6 批次 2：PetMorphCoordinator

本批次冻结 `IPetMorphCoordinator` 契约与测试替身，实现 `PetMorphCoordinator`，并把主窗体的形态规则应用、校验入口、Section 保存、资源规则更新和页面推送全部迁到协调器。

## 实现

- 新增 `Features/PetMorph/Coordination/`：
  - `PetMorphPushResult.cs`：`AolaPetMorphPushResult` 从 Cef 桥接文件移入 PetMorph 模块，作为框架无关推送结果；
  - `PetMorphCoordinationContracts.cs`：`IPetMorphCoordinator`（`Current`、`CurrentRules`、`ValidateRule`、`RestoreFromSavedSettings`、`ApplyAsync`、`PushCurrentRulesAsync`）、结构化 `PetMorphApplyResult`、`IPetMorphRuleTarget` 与 `IPetMorphPushBridge` 缝隙；
  - `PetMorphCoordinator.cs`：规则快照规范化、Section 保存、隐藏背景/图标映射计算、推送请求序号防覆盖（superseded）与错误回退；
  - `Testing/`：`ManualPetMorphRuleTarget`、`ManualPetMorphPushBridge` 测试替身。
- `AolaThemeRequestHandler` 实现 `IPetMorphRuleTarget`；新增 Cef 适配 `AolaBrowserPetMorphPushBridge` 实现 `IPetMorphPushBridge`（主框架懒获取 + 既有 live bridge）。
- `AolaMainForm`：删除 `_petMorphSettings`/`_petMorphSettingsCodec`/`_petMorphLiveBridge`/`_petMorphPushRequest`、`TrySavePetMorphSettings`、`PushPetMorphRulesAsync` 与 `ToMorphRules`；面板校验/初值、保存与两次推送（面板应用 + 帧加载完成后）均走协调器。

## 自动验证

新增 `PetMorphCoordinatorVerifier`（链接同一源码，不新增程序集），覆盖：

- 无文件默认关闭、LiveBridge 默认开启；
- 从已保存 Section 恢复规则到目标；
- `ApplyAsync` 成功：规则应用、Section 保存（未知字段保留、无 BOM）、隐藏背景/图标/海报映射计算、推送调用；
- 保存失败：规则已应用、文件与当前快照不变、不推送；
- 桥接模板不可用：设置已保存但不推送；
- 映射探测异常：`PushBlocked` 且设置已保存；
- 规则目标拒绝：不保存、不推送；
- `PushCurrentRulesAsync`：仅推送不保存不改规则；桥不可用时返回明确错误。

## 验证结果

```text
Loader Release 构建成功（仅保留 CefSharp 87 的 4 条 NU1903 已知高危漏洞警告）。
Verify Release 构建成功。
PacketHost boundary self-test: PASS
Settings boundary self-test: PASS
ThemeCoordinator boundary self-test: PASS
PetMorphCoordinator boundary self-test: PASS
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

浏览器仍由主窗体直接创建，`AolaBrowserPetMorphPushBridge` 使用 `_browser.GetMainFrame()`；BrowserSession 生产适配（阶段 6 批次 3）会替换该路径。真实 PPAPI Flash 的形态保存、热推送、页面刷新与新进程恢复仍需阶段 9 实机验证，PET_MORPH_SPEC 保持 `Target`。
