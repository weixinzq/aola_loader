# 重构阶段 2：BrowserSession 与 PageBridge 契约（2026-08-22）

## 批次范围

本批次只实现 BrowserHost ContractVersion 1 的框架无关接口、结果模型和手动测试替身。没有移动 `AolaMainForm` 的 CefSharp 初始化、`ChromiumWebBrowser`、frame 回调或 `AolaPetMorphLiveBridge`，也没有改变导航、页面脚本或 Flash 运行行为。

## 实现

- `IBrowserSession`：当前地址、关闭状态、受控 HTTP/HTTPS 导航、普通/忽略缓存刷新、页面生命周期事件和可取消脚本调用。
- `BrowserPageLifecycleEvent`：`NavigationStarted`、`MainFrameReady`、`NavigationFailed`、`Closed`，使用 UTC 时间且不泄露 Cef frame 类型。
- `BrowserScriptRequest/Result`：稳定操作名、脚本、超时和结构化成功/失败；区分页面未就绪、浏览器关闭、执行失败、超时与取消。
- `IPageBridge`：命名 `PageBridgeRequest` 和带 revision 的 `PageFeatureStatePush`。
- `PageBridgeResult`：区分桥未安装、页面未就绪、调用失败、超时、浏览器关闭与取消。
- `ManualBrowserSession`、`ManualPageBridge`：供协调器和功能模块在无 CefSharp 环境下验证。

请求参数、功能状态和返回 JSON 均在边界执行深复制。功能模块未来只依赖 `IPageBridge`；原始脚本入口属于 BrowserHost 适配实现，不应向 Theme、PetMorph 或 Battle 泄露。

## 自动验证

`BrowserHost contract self-test` 覆盖：

- HTTP/HTTPS 导航、地址状态、刷新模式；
- 页面导航、主 frame 就绪和关闭事件；
- 单个生命周期订阅者异常不阻断其他订阅者；
- 脚本结果 JSON 防御性复制和关闭后失败；
- PageBridge 参数/状态防御性复制及 revision；
- 桥未安装、页面未就绪、调用异常、超时和浏览器关闭分类；
- 非法操作名拒绝。

验证器直接链接 BrowserHost 契约和替身源码，没有新增程序集。

## 待办

阶段 6 才实现真实 `AolaBrowserSession`、PageBridge Cef 适配器和 CompositionRoot 接线。届时必须验证 Cef 线程回调、主 frame 识别、未完成调用在关闭时取消、事件退订、默认登录页，以及刷新和新进程对 CEF/Flash/ApplicationDomain 缓存的不同影响。

