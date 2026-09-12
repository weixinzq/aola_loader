# 项目架构总览

## 文档状态

本文描述 2026-09-11 当前工作区（包含尚未提交的改动）的静态架构。依据是解决方案、项目文件、C# 源码、运行资源清单和现有模块规格；本轮没有构建、测试、联网、启动 CEF 或真实 Flash，因此进程分配、服务端接受结果和画面效果不属于本轮已验证结论。

阅读时使用以下证据等级：

- **代码可证**：能够定位到当前源码、项目文件或资源清单。
- **设计约束**：由接口、源码守卫、现有 ADR 或模块规格明确规定。
- **运行时待证**：静态代码支持该解释，但仍需要真实进程、网络或 Flash 运行验证。

## 项目解决什么问题

AolaLoader 是一个面向旧版奥拉星 Flash 页面的 Windows 桌面宿主。它把以下能力放进同一个可操作外壳：

1. 使用 CefSharp 承载游戏官网并加载本地 PPAPI Flash。
2. 在不创建第二条游戏连接的前提下，通过页面和 Flash 的既有连接提交受控命令。
3. 向 CEF 网络子进程注入 EasyHook DLL，旁路观察 Winsock 收发并解析为结构化消息。
4. 基于 CEF 资源请求规则，对有限、已声明所有权的 SWF 资源执行本地替换、远端改写或变换。
5. 在抓包和页面桥之上提供主题、形态替换、战斗助手、战斗表现、战斗序列和阵容方案功能。

它不是游戏服务端、通用浏览器、独立登录器或任意协议发包器。当前工作区中 `analysis/AolaOfflineClient/` 已删除，历史规格仍保留，但它不属于当前构建与运行面。

## 整体运行模型

```text
用户
  │
  ▼
AolaLoader.exe（WinForms 宿主）
  ├─ CompositionRoot：创建和释放长生命周期对象
  ├─ ChromiumWebBrowser：网页容器
  ├─ BrowserSession / PageBridge：受控页面调用
  ├─ Settings / Feature Coordinators：设置和功能编排
  ├─ ResourceInterception：CEF 请求规则管线
  └─ PacketHost：IPC 消息适配与宿主消费者
         ▲
         │ .NET Remoting IPC（DTO / status / packet）
         │
CEF network.mojom 子进程
  └─ AolaSocketHack.dll（EasyHook 注入）
       ├─ Winsock 回调：复制并有界入队
       └─ Parser 线程：TCP 重组、协议解析、脱敏和 IPC 发布

CEF 管理的页面/插件进程
  └─ PPAPI Flash
       ├─ 官方及受控替换 SWF
       ├─ ExternalInterface 桥
       └─ 游戏原有网络连接
```

系统同时存在两条方向相反但互相补充的链：

- **观察链**：游戏连接 → Winsock Hook → 协议解析 → IPC → 日志、抓包 UI、BattleSnapshot、阵容响应匹配。
- **控制链**：UI/功能模块 → `IAolaCommandSender` → `IPageBridge` → JavaScript → ExternalInterface → Flash 原连接。

Hook 不承担生产发包。`AolaSocketHack.Contracts` 中仍保留兼容待发队列，但注入端会明确拒绝，当前生产控制链只允许走页面桥。

## 关键进程与线程

| 执行单元 | 主要职责 | 生命周期所有者 |
| --- | --- | --- |
| `AolaLoader.exe` | WinForms、CEF 初始化、设置、功能编排、IPC 服务 | `Program.Main` / `AolaCompositionRoot` |
| `CefSharp.BrowserSubprocess.exe` renderer 等 | HTML/JavaScript 渲染与 Chromium 内部工作 | CEF |
| `CefSharp.BrowserSubprocess.exe --type=network.mojom` | CEF 网络栈；AolaSocketHack 的注入目标 | CEF，宿主仅轮询发现并注入 |
| PPAPI Flash 执行环境 | 游戏 SWF、ExternalInterface、原游戏 socket | Chromium/PPAPI；精确进程归属本轮未实测 |
| WinForms UI 线程 | 窗口和大部分用户操作 | `Application.Run` |
| Hook 回调线程 | 调用原 Winsock 后复制成功收发字节并尝试入队 | EasyHook/目标进程 |
| `AolaSocketHack.Parser` | 重组、解析、状态和 IPC 发布 | 注入 DLL `MainClass.Run` |

## 技术栈

- .NET Framework 4.8，SDK 风格项目，C# `latest`，目标 `win-x64`。
- WinForms 桌面 UI。
- CefSharp.WinForms 87.1.132 与 CEF 多进程模型。
- 本地 PPAPI Flash：`analysis/runtime/pepflashplayer.dll`，运行时复制到 `runtime/`。
- EasyHook 2.7.7097：跨进程注入和 Winsock Hook。
- .NET Remoting IPC：宿主服务与注入 DLL 通信。
- Newtonsoft.Json 13.0.4：设置、IPC 参数和功能数据。
- SharpCompress 0.50.4：SWF/资源处理相关能力。
- PowerShell 与 Python：构建、资源准备、清单生成和诊断工具；不属于主程序运行时。

## 当前解决方案边界

`AolaLoader.sln` 只包含四个 .NET 项目：

| 项目 | 产物 | 角色 |
| --- | --- | --- |
| `AolaLoader` | WinExe | 桌面宿主和全部应用功能 |
| `AolaSocketHack` | DLL | 注入 CEF 网络进程的捕获端 |
| `AolaSocketHack.Contracts` | DLL | 跨进程 DTO 与 Remoting 服务 |
| `AolaSocketHack.Verify` | Console Exe | 契约、自测与源码边界守卫 |

`analysis/reverse-engineering/`、`evidence/`、`task/` 和 `analysis/tools/` 是证据、维护与生成面；`unity/` 是独立实验面。它们不能被当作生产运行链的一部分。

## 从这里继续

- 进程和部署关系：[01-SYSTEM-MAP.md](01-SYSTEM-MAP.md)
- 模块职责和接口：[02-MODULES.md](02-MODULES.md)
- 启动、Hook、战斗与快照链路：[03-RUNTIME-FLOWS.md](03-RUNTIME-FLOWS.md)
- 依赖方向：[04-DEPENDENCIES.md](04-DEPENDENCIES.md)
- 必须守住的边界：[05-BOUNDARIES.md](05-BOUNDARIES.md)
- 高耦合与技术债：[06-CONCERNS.md](06-CONCERNS.md)

