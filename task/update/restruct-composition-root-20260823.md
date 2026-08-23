# 阶段 6 批次 5：AolaCompositionRoot

本批次把长期服务创建从主窗体迁到 `AolaCompositionRoot`，`Program.Main` 只负责进程初始化、创建组合根、运行主窗体和最终释放。

## 实现

- 新增 `AppShell/AolaCompositionRoot.cs`：集中构造设置 store、`AolaHookController`、`AolaHookHostAdapter`、`AolaReceiveLogger`、`AolaBattleStateTracker`、`AolaThemeRequestHandler`、主题/形态协调器、`ChromiumWebBrowser`、`AolaBrowserSession` 与 `ChildWindowCoordinator`，并以依赖注入构造 `AolaMainForm`；`Dispose` 按逆序释放（子窗口 → 会话/浏览器 → PacketHost → 日志 → tracker → hook）。
- 新增 `BrowserHost/AolaCefInitializer.cs`：CefSharp/PPAPI Flash 初始化从主窗体迁入 BrowserHost。
- `AolaMainForm`：构造函数改为接收 9 个已构造依赖；删除全部 `new` 业务服务、设置读取、`InitializeCef` 与浏览器创建逻辑；`OnFormClosed` 只负责退订 UI 事件、停止计时器和关闭子窗口，长期服务由组合根在消息循环结束后释放。
- `Program.cs`：`Application.Run(root.MainForm)`，`using` 组合根确保释放，`finally` 中 `Cef.Shutdown()`。
- 新增 `MainFormCompositionGuardVerifier` 源码守卫：主窗体禁止出现长期服务/Cef 的 `new` 与初始化调用。

## 自动验证

```text
Loader Release 构建成功（仅保留 CefSharp 87 的 4 条 NU1903 已知高危漏洞警告）。
Verify Release 构建成功。
全部边界自测 PASS（含 MainForm composition guard: PASS）。
client_bytes=12373 server_bytes=286678
sent=172 received=423 policy=1 exportable=164 failures=0
export_format=True login_redacted=True inner_plaintext=True active_send=True
Aola PCAP replay: PASS
```

## 已知限制

主窗体仍持有 `ChromiumWebBrowser` 控件并处理 `FrameLoadEnd` 的 Flash 探针脚本；`AolaBrowserSession` 尚未用于脚本执行与形态推送。真实启动、登录、主题/形态、子窗口与新进程行为仍需阶段 9 实机验证，APP_SHELL_SPEC 保持 `Target`。
