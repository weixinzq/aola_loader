# 阶段 6 批次 6：AolaMainForm 最终瘦身收口

本批次完成阶段 6 最后一项：审计并收口主窗体职责，强化组合根源码守卫。

## 现状审计

`AolaMainForm` 现在只保留：

- 控件布局：地址栏、状态栏、菜单/工具栏、浏览器承载与最小化恢复；
- 菜单/工具栏命令与状态呈现：主题切换（转发 `IThemeCoordinator`）、形态面板与应用（转发 `IPetMorphCoordinator`）、抓包/对战助手/形态面板（转发 `IChildWindowCoordinator`）、地址导航/刷新（转发 `IBrowserSession`）、日志保留与状态文本；
- 命令转发后的结果呈现：`DescribePetMorphPush`、`OnBrowserLifecycleChanged`、`HookStatusReceived`。

主窗体不再引用协议解析、SWF 转换、poster catalog、设置 JSON 实现、`AolaHookHostService` 静态事件或 EasyHook 类型。

两项已记录的运行集成仍留在主窗体，待后续阶段评估服务化归属：

- `EnsureHookInjected`/`FindNetworkProcessId`：Hook 注入轮询（驱动“等待 CEF network.mojom 子进程”等状态）；
- `BrowserFrameLoadEnd`：Flash 兼容探针与形态热推送触发。

## 实现

`MainFormCompositionGuardVerifier` 扩展为两类检查：禁止主窗体构造长期服务/Cef 基础设施（`new AolaHookController`、`new ChromiumWebBrowser`、`new ThemeCoordinator` 等），并禁止主窗体引用协议解析、SWF 转换、poster catalog、设置 JSON 实现、`AolaHookHostService` 静态事件与 EasyHook 类型。

## 验证结果

```text
Loader Release 构建成功（仅保留 CefSharp 87 的 4 条 NU1903 已知高危漏洞警告）。
Verify Release 构建成功。
全部边界自测 PASS（含 MainForm composition guard: PASS）。
client_bytes=12373 server_bytes=286678
sent=172 received=423 policy=1 exportable=164 failures=0
export_format=True login_redacted=True inner_plaintext=True active_send=True
Aola PCAP replay: PASS
```

## 阶段 6 总结

六项批次全部完成：ThemeCoordinator、PetMorphCoordinator、AolaBrowserSession、ChildWindowCoordinator、AolaCompositionRoot、主窗体瘦身收口。下一步是阶段 7（目录与命名空间迁移），按模块逐个物理移动并保持命名空间构建后再单独调整。
