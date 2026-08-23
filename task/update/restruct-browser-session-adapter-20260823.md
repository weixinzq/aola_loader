# 阶段 6 批次 3：BrowserSession CefSharp 生产适配

本批次实现 `IBrowserSession` 的 CefSharp 生产适配器 `AolaBrowserSession`，并把主窗体的地址显示、导航失败状态、刷新与导航命令迁到会话接口。

## 实现

- 新增 `BrowserHost/AolaBrowserSession.cs`：
  - 包装 `ChromiumWebBrowser`，翻译 `AddressChanged`/`FrameLoadEnd`/`LoadError` 为 `NavigationStarted`/`MainFrameReady`/`NavigationFailed` 生命周期事件；
  - `Navigate` 校验 HTTP(S) URL 后 `Load`；`Refresh` 按 `BrowserRefreshMode` 调用 `Reload()`/`Reload(true)`（CefSharp 87 的 `Reload(IWebBrowser, bool)` 扩展）；
  - `ExecuteScriptAsync` 使用主框架 `EvaluateScriptAsync`，以 `Task.WhenAny` + 链接令牌实现超时/取消，并把 CefSharp 结果映射为 `BrowserScriptResult`（成功、超时、取消、浏览器关闭、页面未就绪、执行失败）；
  - `Dispose` 解除事件、发布 `Closed`，不释放底层浏览器（由拥有者负责）。
- `AolaMainForm`：创建 `AolaBrowserSession`，生命周期事件统一由 `OnBrowserLifecycleChanged` 呈现（地址框与失败状态）；工具栏刷新、地址导航与释放改走 `IBrowserSession`；后退/前进/开发者工具仍直接使用浏览器控件；`FrameLoadEnd` 的 Flash 探针与形态推送路径保持不变。

## 验证

适配器与 CefSharp 耦合，无法纳入 `AolaSocketHack.Verify`（该程序集不引用 CefSharp）；`BrowserHostContractVerifier` 继续通过 `ManualBrowserSession` 冻结契约语义。本批次的静态验证为 Loader Release 构建（仅 CefSharp 87 NU1903 警告）与全量自测/PCAP 回归；真实页面导航、刷新与生命周期行为由阶段 9 实机验证。

```text
Loader Release 构建成功。
Verify Release 构建成功。
全部边界自测 PASS。
client_bytes=12373 server_bytes=286678
sent=172 received=423 policy=1 exportable=164 failures=0
export_format=True login_redacted=True inner_plaintext=True active_send=True
Aola PCAP replay: PASS
```

## 已知限制

`AolaBrowserSession` 尚未用于脚本执行与形态推送（`AolaBrowserPetMorphPushBridge` 仍直接取主框架）；CompositionRoot 尚未创建会话，主窗体仍持有 `ChromiumWebBrowser` 控件。真实 Flash 导航/刷新/缓存路径仍需阶段 9 实机验证，APP_SHELL_SPEC 保持 `Target`。
