# AppShell

Status: Target  
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

输入为用户命令、窗口生命周期事件和模块状态；输出为导航、功能调用、子窗口动作及状态呈现。

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

构造/释放替身测试；子窗口复用与关闭测试；主窗最小化/恢复；源码守卫禁止主窗体引用协议、SWF 转换器和静态 IPC 事件。

## 完成标准

`Program.Main` 只做进程初始化、CompositionRoot、运行主窗体和释放；`AolaMainForm` 不再创建或协调大多数具体业务服务；构建及默认 UI 实机回归通过。

## 已知限制

阶段 6 已提供 `AolaBrowserSession`（`IBrowserSession` 的 CefSharp 生产适配，包装 `ChromiumWebBrowser` 并翻译生命周期、导航、刷新与脚本执行），主窗体已用会话接口处理地址显示、导航失败状态、刷新与导航命令并释放会话。`Program.Main` 仍直接 `new AolaMainForm()`，主窗体仍是组合根；`AolaCompositionRoot`、`ChildWindowCoordinator` 与最终主窗体瘦身仍待后续批次，本契约整体继续标记为 `Target`。
