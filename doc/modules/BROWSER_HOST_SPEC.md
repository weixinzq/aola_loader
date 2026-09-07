# BrowserHost

Status: Implemented
ContractVersion: 1  
OwnerPaths: `analysis/AolaLoader/BrowserHost/**`

## 职责

初始化/关闭 CefSharp，创建受控浏览器会话，提供导航、刷新、地址与 frame 生命周期，并通过 PageBridge 执行受控脚本操作。

## 非职责

不拥有 Theme/PetMorph/Battle 规则，不转换 SWF，不订阅 IPC，不解释功能设置。

## 公开契约

`IBrowserSession` 提供当前地址、导航、刷新、页面/主 frame 生命周期、关闭状态和结构化脚本执行结果；`IPageBridge` 通过 `PageBridgeRequest` 调用命名操作，通过 `PageFeatureStatePush` 推送带 revision 的结构化状态，并区分桥未安装、页面未就绪、调用失败、超时、取消和浏览器关闭。所有 JSON 值使用防御性副本。

生产 `AolaPageBridge` 只接受命名操作。主动发送使用 `activeSend.submit`：JavaScript 只向已加载 Flash 对象调用 `aolaSendCommand`，提交返回后立即删除临时请求状态，不轮询或等待服务器响应。面板打开使用独立的 `panel.open`，把结构化的 `resourceUrl` 与 `resourceClass` 字符串传给 `aolaOpenPanel`；不执行用户脚本文本。桥不传递登录帧、SID 或服务器响应正文。

## 输入与输出

输入为受控 HTTP/HTTPS 导航及结构化桥请求；输出为生命周期事件和结构化脚本结果，不向功能模块泄露 `ChromiumWebBrowser`/`IFrame`。

## 允许依赖

CefSharp 只在本模块适配实现中；ResourceInterception 的 Cef 请求入口；进程级配置。

## 禁止依赖

功能模块内部类型、PacketHost、协议解析器、设置文档实现和具体业务 Form。

## 线程与生命周期

Cef 回调按框架线程规则进入；对外事件不承诺 UI 线程。会话关闭取消未完成桥调用并释放浏览器；Cef 由进程生命周期唯一关闭。

## 异常及回退语义

非法导航拒绝；桥未就绪/超时返回结构化失败；功能桥失败不得破坏基本导航和官方页面加载。

## 设置所有权

无。缓存目录等进程配置若持久化，应归 AppShell/BrowserHost 自身 Section，而非功能 Section。

## 安全约束

仅作为受控站点宿主，不扩展为通用浏览器；脚本 API 使用命名操作和结构化参数，避免功能模块拼任意脚本或泄露敏感值。

## 缓存语义

明确区分会话状态、CEF 内存/磁盘缓存和 Flash 缓存；接口不承诺刷新能替换已进入 ApplicationDomain 的类。

WinForms `ChromiumWebBrowser` 使用默认窗口化渲染和 GPU 合成；不得为它启用 `WindowlessRenderingEnabled` 或 `SetOffScreenRenderingBestPerformanceArgs()`。如需兼容特定显卡，应以独立、可回退且经过真实 Flash 验证的设置处理，不能默认关闭 GPU。

## 验证入口

`AolaSocketHack.Verify --self-test` 当前验证导航/刷新、主 frame 生命周期、订阅者异常隔离、脚本结果、桥失败分类、状态 revision、防御性副本和关闭语义，并验证主动发送脚本不含登录/SID、未知扩展拒绝及结构化发送状态。生产适配仍需真实页面启动、桥加载、服务器回调和新进程实测。

## 完成标准

功能模块不再持有 CefSharp 类型；主窗体不再初始化 Cef；默认登录与页面生命周期实机通过。

## 已知限制

阶段 2 已实现 `IBrowserSession`、页面/脚本结果、`IPageBridge` 和手动测试替身；阶段 6 已迁入 `AolaCefInitializer` 与 `AolaBrowserSession` 生产适配器。阶段 7 将功能特定的 PetMorph Cef 推送适配器收口到 `AppShell/Adapters/PetMorph`，BrowserHost 不反向依赖具体功能。阶段 9 已验证真实默认启动/登录、导航刷新、Flash frame 回调、新进程与缓存路径。浏览器控件和兼容探针仍由 AppShell 持有，这是已记录的运行集成，不改变 BrowserHost 边界。
