# AppShell

Status: Implemented
ContractVersion: 1  
OwnerPaths: `analysis/AolaLoader/AppShell/**`, `analysis/AolaLoader/UI/**`

## 职责

创建和组合长期服务；承载主窗口命令入口；协调子窗口显示、复用、最小化恢复与释放；按逆序关闭组件。

## 非职责

不解析协议、不读写 JSON 细节、不拼资源 URL、不转换 SWF、不保存功能规则、不直接订阅静态 IPC 事件。

## 公开契约

- `AolaCompositionRoot`：唯一集中构造长期具体服务的对象，提供主窗体并实现确定性释放。
- `IChildWindowCoordinator`：按稳定 key 显示/复用/隐藏/恢复/关闭子窗口。
- MainWindow 只接收已构造的浏览器、PacketHost、功能协调器和窗口协调器。

## 输入与输出

输入为用户命令、窗口生命周期事件和模块状态；输出为导航、功能调用、子窗口动作及状态呈现。主窗口“保留日志”在后台调用 logger 的 `TryRetain`，成功后显示路径与缓存丢弃数量；完整日志默认关闭，点击后才开始记录。主窗口提供“抓包 / 发包”“战斗助手”和“战斗表现”入口；Packets 子窗口不随主窗口启动自动创建，点击入口后才显示，并提供“抓包 / 发包 / 打开映射面板”三页导航，发包页可切换普通发送与按战斗状态逐条发送。

主窗口的“窗口大小”菜单提供 1×、1.25×、1.5×、2×，以用户测量的页面内容 962×560 CSS 像素为基准，按当前显示器 DPI 换算浏览器区域并加上工具栏和窗口边框；超过当前屏幕工作区时等比缩小并在当前屏幕居中。允许最大化，页面始终按浏览器可用宽高的较小比例完整显示，宽高比不同时允许留白。页面缩放读取 CEF 实际 CSS 视口及当前缩放值，不假设 CEF 像素比例与 WinForms DeviceDpi 一致；页面加载、客户区尺寸及显示器 DPI 变化时重新计算，旧的异步测量结果不覆盖更新的布局。普通窗口跨屏时恢复所选比例并限制在目标屏幕工作区内。

`app.config`、Windows 10 兼容 manifest 和 `Application.EnableVisualStyles` 启用 .NET Framework 的 PerMonitorV2，替代旧 `SetProcessDPIAware`；主窗体使用 DPI 自动布局。DPI 模式作用于整个宿主。构建和尺寸检查不能证明 CefSharp 87/PPAPI Flash 在不同 DPI 显示器上的画面及点击位置均正常，仍需实机跨屏和子窗口回归。

2026-09-28：Release 构建通过；临时测量工具在 DPI 120、单显示器环境核对生产入口和主窗体，原生窗口 PerMonitorV2、四个比例档位的屏幕边界及 CEF 962×560 CSS 视口、最大化检查通过。未验证真实跨不同 DPI 显示器移动、Flash 游戏画面或服务器操作。

## 允许依赖

BrowserHost、PacketHost、Theme/PetMorph/Battle 的公开契约，以及 WinForms UI 类型。

## 禁止依赖

协议解析器、SWF 转换器、设置 JSON 实现、`AolaHookHostService` 静态事件、EasyHook 具体类型。

## 线程与生命周期

窗口操作只在 UI 线程。CompositionRoot 在 `Program.Main` 中创建，在主消息循环结束后逆序 Dispose。窗口关闭后不得继续收到事件。

## 异常及回退语义

非关键子窗口/功能失败应报告并保持主浏览器可用；启动关键服务失败则清理已创建组件并给出明确错误。

## 设置所有权

AppShell 不拥有功能设置，只调用各协调器的加载/保存入口。窗口布局设置若新增，使用独立 `appShell` Section。

## 安全约束

不得接收或展示 SID、登录帧；不把异常中的敏感数据写入 UI 或日志。

## 缓存语义

只缓存子窗口实例和最小化前可见状态；窗口关闭/Dispose 后移除引用。

## 验证入口

构造/释放替身测试；子窗口复用与关闭测试；主窗最小化/恢复；Packets UI 源码守卫验证三页导航、send-only 表格、复选追加、清空和 UTF-8 导入；源码守卫禁止主窗体引用协议、SWF 转换器和静态 IPC 事件。

## 完成标准

`Program.Main` 只做进程初始化、CompositionRoot、运行主窗体和释放；`AolaMainForm` 不再创建或协调大多数具体业务服务；构建及默认 UI 实机回归通过。

## 已知限制

`AolaBrowserSession`、`ChildWindowCoordinator` 与 `AolaCompositionRoot` 已落地：`Program.Main` 只做进程初始化、创建 CompositionRoot、运行主窗体并最终释放；长期服务由组合根构造，主窗体只接收已构造依赖。共同窗口基类位于 `UI/Common`，Packets 与战斗表现窗口复用 Cupertino 风格按钮/卡片。抓包页只显示可严格导出的发送记录，复选结果追加到独立编辑器而不自动切页；战斗表现窗口保存后尝试应用当前 Flash 桥，桥未加载时保留设置并在后续页面加载时重推。主窗体仍保留 Hook 注入轮询和 `FrameLoadEnd` 兼容探针/设置推送。阶段 9 已验证启动/登录、子窗口关闭重开、最小化恢复和新进程路径；2026-09-01 的截图与实测覆盖三页 Packets UI 和战斗状态发送入口。


## 阵容方案入口（2026-09-10）

扩展菜单增加“阵容方案”。CompositionRoot 构造 LineupCoordinator，MainWindow 将其交给由 ChildWindowCoordinator 复用的 LineupPresetsForm。窗口提供读取、JSON 保存/打开、恢复和停止，关闭时取消任务。协议流程和方案存储归 Features/Lineup，详见 [阵容方案](LINEUP_SPEC.md)。本次不运行子模块或冒烟检测，真实操作由用户验收。
