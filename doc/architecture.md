# Aola Loader 架构

## 状态与范围

本文区分源码证明的 **Current** 与尚待迁移验证的 **Target**。字段、哈希、实机记录和逆向细节分别路由到模块规格、`task/` 与 `analysis/reverse-engineering/`。

## Current：当前顶层架构

```text
AolaLoader.exe / WinForms UI
  AolaMainForm
    -> ChromiumWebBrowser + CefSharp 初始化
    -> AolaThemeRequestHandler（主题、形态、探测、回退、转换）
    -> AolaSettingsStore（单一 SchemaVersion 5 文档）
    -> AolaHookController
    -> AolaReceiveLogger / AolaBattleStateTracker / 子窗口
    -> AolaHookHostService 静态事件

CefSharp network subprocess
  -> AolaSocketHack.dll
     -> Winsock Hooks -> TCP 重组 -> Aola/AMF3 协议
     -> AolaSidecarSender（独立游戏连接）

AolaSocketHack.Contracts
  -> 跨进程 DTO、静态宿主事件和有界待发队列
```

当前源码的主要耦合点是：主窗体承担组合与业务协调；`AolaThemeRequestHandler` 同时拥有多类资源规则；日志、战斗 Tracker、抓包窗体和主窗体直接订阅静态 IPC 事件；主题和形态共享一个可变设置对象。现有行为细节见各模块规格的“已知限制”。

## Target：目标顶层架构

```text
AolaLoader.exe
├─ AppShell             CompositionRoot / MainWindow / ChildWindowCoordinator
├─ BrowserHost          BrowserSession / PageBridge
├─ Settings             SectionedSettingsStore / LegacySettingsMigrator
├─ PacketHost           HookHostAdapter
├─ ResourceInterception CefRequestAdapter / RulePipeline / Probe / SWF transforms
├─ Features
│  ├─ Theme
│  ├─ PetMorph
│  └─ Battle            State 与 Presentation 分离
└─ UI                    Packets / PetMorph / Battle

CefSharp network subprocess
└─ AolaSocketHack       Hooking / Capture / Protocol / SidecarSend / Metrics

AolaSocketHack.Contracts
└─ 仅跨进程 DTO 与 remoting 边界
```

第一轮仍使用现有 `AolaLoader.csproj`。先用目录和契约建立边界，再逐模块迁移；不同时进行程序集拆分、全量命名空间迁移和行为重写。

## 允许的依赖方向

```text
UI / AppShell -> 应用模块公开契约 -> 模块实现 -> 算法或框架适配器
Battle UI -> Battle state contract -> PacketHost contract
Feature resource rule -> ResourceInterception contracts -> SWF transformer
AolaSocketHack -> Protocol + AolaSocketHack.Contracts
```

禁止 `AolaSocketHack -> AolaLoader UI/Settings/CefSharp`。除 `AolaHookHostAdapter` 和 IPC 初始化外，宿主代码最终不得直接订阅 `AolaHookHostService` 静态事件。功能模块不得取得整个可变设置文档。

## 进程、线程与生命周期

- `Program.Main` 负责进程初始化、单实例、创建 CompositionRoot、运行主窗体和最终释放；CefSharp 在进程级初始化/关闭。
- Winsock Hook 回调只做有界复制和非阻塞入队；解析、重组、指标和 IPC 发布位于注入进程后台线程。
- PacketHost 不承诺事件发生于 UI 线程。WinForms 消费者自行 marshal，并在关闭或 Dispose 时退订。
- CompositionRoot 创建长期对象并按逆序释放；ChildWindowCoordinator 负责子窗口复用、隐藏、恢复和释放。

## 主要数据流

### 捕获、日志与战斗

```text
Winsock bytes -> socket TCP reassembly -> protocol/AMF3 decode
  -> redacted Contracts DTO -> HookHostAdapter
     ├─ 发送 -> Packets UI / strict export
     └─ 接收 -> JSONL logger + Battle state
```

登录帧和 SID 不跨越注入进程信任边界。抓包 UI 保持 send-only；接收原始帧只按日志契约保存。

### 主动发送

```text
UI structured request -> PacketHost -> bounded IPC queue
  -> injected sidecar connection -> own login/sequence/encryption
  -> local decode/readback -> structured result
```

该路径不使用浏览器连接的密文或序列状态。

### 浏览器资源

```text
Cef request -> CefRequestAdapter -> ordered ResourceRulePipeline
  -> PassThrough | LocalResponse | RemoteTransform
  -> precise probe / bounded buffering / SWF contract validation
  -> transformed response or explicit original-resource fallback
```

规则以稳定顺序注册；首个非 PassThrough 计划获胜。规则不直接改 URL 或创建 CefSharp handler，Cef 类型只存在于适配层。

## 信任、缓存与失败边界

- 注入进程持有敏感登录材料；Contracts、宿主 UI、日志、导出和文档均不可信任这些材料。
- 远程资源、CEF 缓存项和修改候选都不是可信 SWF；须验证来源、头、长度、压缩、类契约和大小上限。
- CEF 内存/磁盘缓存、Flash Loader 与 ApplicationDomain 分层处理；验证方式取决于发生变化的缓存层。
- 规则关闭、未命中、探测失败或候选无效时保持/恢复官方资源。冲突必须确定性处理，不能依赖注册时机。
- 设置按 Section 原子保存；损坏 Section 回退模块默认值，未知 Section/字段尽量保留，旧文件不可因保存失败而损坏。

## 迁移与验证策略

接口先冻结为 ContractVersion 1，再按资源管线、PacketHost、Section 设置、功能协调器、CompositionRoot 的顺序迁移。每批保持可构建、可验证、可回退；所有消费者迁移后才删除兼容路径。

模块状态见 [`modules/`](modules/)，跨模块理由见 [`decisions/`](decisions/)，当前阶段基线见 [`../task/update/restruct-baseline-20260821.md`](../task/update/restruct-baseline-20260821.md)。静态验证、构建、PCAP/主动发送和真实 Flash 运行是不同层级；只有所需实机路径完成后，模块规格才能从 `Target` 更新为 `Implemented`。
