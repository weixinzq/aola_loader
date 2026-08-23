# 阶段 6 批次 4：ChildWindowCoordinator

本批次冻结 `IChildWindowCoordinator` 契约与测试替身，实现 `ChildWindowCoordinator`，并把主窗体的三个子窗口与最小化/恢复逻辑迁到协调器。

## 实现

- 新增 `AppShell/`：
  - `ChildWindowCoordinatorContracts.cs`：`IChildWindowCoordinator`（`Show(key, factory, activate)`、`RememberAndHideVisible`、`RestoreVisibleAfterUnminimize`、`Dispose`）；
  - `ChildWindowCoordinator.cs`：按稳定 key 创建/复用子窗口，`FormClosed` 按实例引用清理，最小化时快照并隐藏可见子窗口，恢复时 `ShowWindow(SW_SHOWNOACTIVATE)` 不抢焦点，Dispose 先 `Close` 再对未释放实例 `Dispose`（兼容形态面板“用户关闭即隐藏”语义）；
  - `Testing/ManualChildWindowCoordinator.cs`：测试替身。
- `AolaMainForm`：删除 `_packetsForm`/`_battleAssistantForm`/`_petMorphForm`/`_childrenVisibleBeforeMinimize` 字段与 `RememberVisibleChild`/`ShowWindow`；抓包、对战助手、形态面板显示与最小化/恢复、关闭清理全部走 `_childWindowCoordinator`。

## 自动验证

`AolaSocketHack.Verify` 新增 `ChildWindowCoordinatorVerifier`（项目增加 `System.Windows.Forms` 引用，`Main` 标记 `[STAThread]`），覆盖：

- 同一 key 复用实例、工厂只调用一次；
- 最小化快照隐藏与恢复可见；
- 关闭后再次显示会重建；
- Dispose 释放子窗口且之后 `Show` 抛 `ObjectDisposedException`。

## 验证结果

```text
Loader Release 构建成功（仅保留 CefSharp 87 的 4 条 NU1903 已知高危漏洞警告）。
Verify Release 构建成功。
全部边界自测 PASS（含 ChildWindowCoordinator boundary self-test）。
client_bytes=12373 server_bytes=286678
sent=172 received=423 policy=1 exportable=164 failures=0
export_format=True login_redacted=True inner_plaintext=True active_send=True
Aola PCAP replay: PASS
```

## 已知限制

子窗口工厂仍由主窗体提供，窗口实例尚未由 CompositionRoot 组装；真实窗口关闭/重开、主窗最小化/恢复与新进程行为仍需阶段 9 实机验证，APP_SHELL_SPEC 保持 `Target`。
