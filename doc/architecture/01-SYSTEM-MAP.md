# 系统地图

## 进程视图

```text
┌──────────────────────────────── AolaLoader.exe ────────────────────────────────┐
│ Program.Main                                                                  │
│   └─ AolaCompositionRoot                                                      │
│       ├─ AppShell / WinForms UI                                               │
│       ├─ CefSharp ChromiumWebBrowser ───────────────┐                         │
│       ├─ BrowserSession / PageBridge                │ ExecuteScript           │
│       ├─ Settings / Coordinators                     │                         │
│       ├─ ResourceRequestHandler / RulePipeline       │ CEF request callbacks   │
│       ├─ AolaHookController ───────── inject ────────┼──────────────┐          │
│       └─ PacketHost ◄──── .NET Remoting IPC ─────────┼───────────┐  │          │
└──────────────────────────────────────────────────────┼───────────┼──┼──────────┘
                                                       │           │  │
                      ┌────────────────────────────────▼─────┐     │  │
                      │ CEF renderer / 页面执行环境           │     │  │
                      │ HTML + JavaScript                    │     │  │
                      │   └─ object/embed → PPAPI Flash      │     │  │
                      │        ├─ patched start bridge       │     │  │
                      │        ├─ patched battle bridge      │     │  │
                      │        └─ game SocketClient          │     │  │
                      └──────────────────────────────────────┘     │  │
                                                                  │  │
                      ┌───────────────────────────────────────────▼──▼─┐
                      │ CEF network.mojom 子进程                       │
                      │   └─ AolaSocketHack.dll                        │
                      │        ├─ EasyHook Winsock hooks               │
                      │        ├─ bounded queue                        │
                      │        ├─ TCP frame / protocol / AMF3 parser   │
                      │        └─ redacted packet/status publisher ────┘
                      └────────────────────────────────────────────────┘
```

CEF 与 PPAPI 的精确子进程归属由 Chromium 运行时决定。代码只能证明宿主寻找带 `type=network.mojom` 的直接子进程并注入；不能仅凭静态代码断言 Flash 一定运行在 renderer 进程内。

## 宿主内部地图

```text
Program
  └─ CompositionRoot
      ├─ AppShell
      │   ├─ AolaMainForm
      │   ├─ AolaHookController
      │   └─ ChildWindowCoordinator
      ├─ BrowserHost
      │   ├─ AolaCefInitializer
      │   ├─ AolaBrowserSession
      │   └─ AolaPageBridge
      ├─ Settings
      │   └─ JsonSettingsSectionStore
      ├─ PacketHost
      │   ├─ AolaHookHostAdapter
      │   └─ AolaReceiveLogger
      ├─ ResourceInterception
      │   ├─ AolaResourceRequestHandler
      │   ├─ ResourceRulePipeline
      │   ├─ CefResourceRuleAdapter
      │   └─ probe / fetch / transform
      ├─ Features
      │   ├─ Theme
      │   ├─ PetMorph
      │   ├─ ActiveSend
      │   ├─ Battle
      │   │   ├─ State
      │   │   ├─ Bridge / Replay
      │   │   ├─ Presentation / Diagnostics
      │   │   └─ ResourceInterception
      │   └─ Lineup
      └─ UI
          ├─ Packets
          ├─ Battle
          ├─ PetMorph
          └─ Lineup
```

`AolaCompositionRoot` 是唯一预期的长期对象装配点。它创建共享的 packet source、page bridge、settings store 和 resource handler，再把窄接口传给各模块。

## 注入 DLL 内部地图

```text
MainClass (EasyHook IEntryPoint)
  ├─ AolaSocketCaptureFilter
  ├─ WinsockHooks
  │   ├─ send / recv
  │   ├─ WSASend / WSARecv
  │   ├─ connect
  │   └─ closesocket
  ├─ BlockingCollection<CapturedChunk> [4096]
  └─ AolaSocketHack.Parser
      └─ AolaCaptureEngine
          ├─ per-socket ConnectionState
          ├─ outgoing / incoming FrameBuffer
          ├─ AolaProtocolState
          └─ AolaProtocol → AolaPacketEvent
```

Hook 回调不做协议解析；它们只在调用原函数成功后复制有限字节并尝试入队。队列满时丢弃并计数，解析线程和连接缓冲也各自有上限。

## 构建与部署地图

```text
AolaLoader.csproj
  ├─ project ref: AolaSocketHack.Contracts
  ├─ project ref: AolaSocketHack
  ├─ packages: CefSharp / EasyHook / Newtonsoft / SharpCompress
  └─ copied content
      ├─ runtime/pepflashplayer.dll
      ├─ Resources/Patches/*.swf + manifest
      ├─ Resources/Themes/*.swf
      ├─ Resources/Data/*.json
      └─ Resources/BattleAssistant/**

AolaSocketHack.csproj
  └─ project ref: AolaSocketHack.Contracts

AolaSocketHack.Verify.csproj
  ├─ project ref: Contracts + SocketHack
  └─ links selected AolaLoader source files directly
```

验证项目的源码链接不是生产依赖方向，而是测试装配方式；它会让验证覆盖与宿主源码物理布局相互耦合，详见 [06-CONCERNS.md](06-CONCERNS.md)。

## 数据与控制方向

| 链路 | 方向 | 主要载荷 | 失败策略 |
| --- | --- | --- | --- |
| Winsock 捕获 | 网络进程 → Hook | 原始字节 | 有界丢弃并上报指标 |
| IPC 发布 | Hook → 宿主 | 已解析、登录脱敏 DTO | 消费者独立处理；不保证 UI 线程 |
| 页面桥 | 宿主 → 页面 → Flash | 白名单操作和 JSON 参数 | 页面/桥未就绪即失败 |
| 资源规则 | CEF 请求 → pipeline | URL、方法、类型、头 | 冲突、异常或验证失败时放行官方资源 |
| 设置 | coordinator ↔ `settings.json` | 模块独立 section | 读取失败使用默认；写入原子替换 |

