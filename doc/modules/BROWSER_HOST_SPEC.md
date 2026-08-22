# BrowserHost

Status: Target  
ContractVersion: 1  
OwnerPaths: `analysis/AolaLoader/BrowserHost/**`

## 职责

初始化/关闭 CefSharp，创建受控浏览器会话，提供导航、刷新、地址与 frame 生命周期，并通过 PageBridge 执行受控脚本操作。

## 非职责

不拥有 Theme/PetMorph/Battle 规则，不转换 SWF，不订阅 IPC，不解释功能设置。

## 公开契约

`IBrowserSession` 提供当前地址、导航、刷新、页面/主 frame 就绪事件、关闭状态和脚本执行；`IPageBridge` 提供命名桥操作与结构化状态推送，并区分桥未安装、页面未就绪、失败和超时。

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

## 验证入口

导航/刷新、主 frame 就绪、桥四类失败、关闭取消、事件退订，以及默认页面启动/关闭/新进程实测。

## 完成标准

功能模块不再持有 CefSharp 类型；主窗体不再初始化 Cef；默认登录与页面生命周期实机通过。

## 已知限制

当前 Cef 初始化、浏览器控件、frame 回调和部分脚本调用仍在 `AolaMainForm`；原任务目录示例遗漏了本规格，依据核心模块 8.2 与目标模块图补齐。

