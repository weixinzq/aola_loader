# 源文件实现与传递指南

> 范围：`analysis/AolaLoader`、`analysis/AolaSocketHack`、`analysis/AolaSocketHack.Contracts` 的 121 个 C# 源文件。  
> 证据基础：2026-09-22 当前工作区的项目文件与静态源码；包含未提交修改。  
> 运行验证：本文只证明当前代码中的装配、调用、事件和数据转换路径，不证明真实 CEF、Flash、服务器或画面行为。

## 1. 如何使用本指南

每个源文件顶部新增两类注释：

- **架构角色**：该文件拥有的职责，以及明确不应承担的职责。
- **数据流**：主要输入、输出和相邻模块。

关键交接点还补充了行内注释，例如 Hook 的两层回调、队列生产/消费、TCP 分帧、协议解密、IPC 事件、日志启用窗口、资源规则选择和 section 合并。注释只解释现有行为，没有更改控制流、常量、接口或数据结构。

本页是逐文件索引；系统地图、模块边界、完整运行链和风险仍分别由 00–08 文档拥有。

## 2. 六条主要传递链

### 2.1 启动与对象装配

```text
Program.Main
  -> AolaCefInitializer.Initialize
  -> AolaCompositionRoot
       -> Settings / PacketHost / ResourceInterception
       -> BrowserHost / Feature Coordinators
       -> AolaMainForm
  -> Application.Run
  -> CompositionRoot.Dispose
  -> Cef.Shutdown
```

控制权由 `Program.Main` 交给组合根，再交给 WinForms 消息循环。长期对象只应在组合根创建；主窗体触发功能，不应重新装配基础设施。证据：`analysis/AolaLoader/Program.cs::Main`、`analysis/AolaLoader/AppShell/AolaCompositionRoot.cs::.ctor`。

### 2.2 CEF 资源请求链

```text
CEF IRequest
  -> AolaResourceRequestHandler
  -> CefResourceRuleAdapter
  -> ResourceRequestContext
  -> ResourceRulePipeline
  -> feature IResourceInterceptionRule
  -> PassThrough | LocalResponse | RewriteRemote
  -> CEF handler / response filter
```

CEF 类型只存在于 `ResourceInterception/Cef`。规则只接收框架无关请求快照并返回计划；远端获取、缓存、变换和流式响应由 pipeline/adapter 执行。证据：`CefResourceRuleAdapter.GetResourceRequestHandler`、`ResourceRulePipeline.Evaluate`。

### 2.3 网络观察链

```text
CEF network.mojom 调用 ws2_32
  -> LocalHook: SendHook / RecvHook / WSA*Hook
  -> capture result callback
  -> MainClass.TryQueue
  -> BlockingCollection<CapturedChunk>
  -> AolaSocketHack.Parser
  -> AolaCaptureEngine
  -> FrameBuffer
  -> AolaProtocol / Amf3Reader
  -> AolaPacketEvent
  -> AolaHookHostService.Publish
  -> AolaHookHostAdapter
  -> Logger / Packets UI / Battle tracker / Lineup
```

`LocalHook.Create` 的回调是原生签名匹配的 `SendHook/RecvHook`；传给 `WinsockHooks` 构造函数的 Lambda 是第二层“捕获结果回调”，最终调用 `TryQueue`。两层不能混为一谈。证据：`WinsockHooks.Install`、`WinsockHooks.Dispatch`、`MainClass.Run`、`MainClass.TryQueue`。

### 2.4 主动控制链

```text
UI / Feature
  -> IAolaCommandSender
  -> AolaFlashCommandSender
  -> IPageBridge
  -> AolaPageBridge whitelist operation
  -> IBrowserSession.ExecuteScriptAsync
  -> JavaScript / ExternalInterface
  -> patched start SWF
  -> Flash 原游戏连接
```

Hook 只观察，不承担生产发包。`AolaSidecarSender` 是历史残留，`MainClass` 会拒绝 Contracts 的待发请求。证据：`AolaFlashCommandSender.SendAsync`、`AolaPageBridge.InvokeAsync`、`MainClass.RejectLegacySendRequest`。

### 2.5 设置与资源激活链

```text
UI model
  -> Feature Coordinator
  -> Feature Codec.Normalize
  -> ISettingsSectionStore.Save
  -> JsonSettingsSectionStore 合并所属 section
  -> AtomicSettingsWriter

Coordinator
  -> Resource rule target / Page bridge
  -> 当前运行期状态
```

“保存成功”和“当前 Flash/资源已应用”是不同状态。Store 拥有文档边界，codec 拥有字段规则，coordinator 拥有保存与应用的顺序。证据：`JsonSettingsSectionStore.Save`、各 feature `*Coordinator`。

### 2.6 战斗与阵容链

```text
AolaPacketEvent
  -> AolaBattlePacketParser
  -> AolaBattleStateTracker
  -> AolaBattleSnapshot
  -> Battle UI / Performance Recorder / safety gate

patched petfight SWF
  -> BattleBridgeClient
  -> BattleBridgeState(inputReady/readyEpoch)
  -> BattleSequenceRunner
  -> IAolaCommandSender
```

`AolaBattleSnapshot` 是 packet 聚合视图；`BattleBridgeState` 是 Flash 输入窗口状态。阵容会话同样订阅 packet，但拥有自己的一次性阶段、响应匹配和退订生命周期。证据：`AolaBattleStateTracker`、`BattleBridgeClient`、`BattleSequenceRunner`、`LineupSession`。

## 3. AolaLoader 逐文件索引（103）

### 3.1 AppShell（8）

| 文件 | 拥有的实现 | 主要传递 |
| --- | --- | --- |
| `AppShell/AolaCompositionRoot.cs` | 长期对象装配与逆序释放 | 运行资源 -> 所有宿主模块 -> `AolaMainForm` |
| `AppShell/AolaMainForm.cs` | UI 外壳、CEF/Hook 时序、功能入口 | 用户/CEF 事件 -> coordinator；结果 -> UI |
| `AppShell/AolaHookController.cs` | Remoting channel 与 EasyHook 注入 | PID + DLL -> `RemoteHooking.Inject` |
| `AppShell/ChildWindowCoordinator.cs` | 子窗口复用与关闭 | key/factory -> 单实例 Form |
| `AppShell/ChildWindowCoordinatorContracts.cs` | 子窗口端口 | MainForm -> coordinator 实现 |
| `AppShell/Testing/ManualChildWindowCoordinator.cs` | 子窗口测试替身 | 测试调用 -> 调用记录 |
| `AppShell/Adapters/PetMorph/AolaBrowserPetMorphPushBridge.cs` | 形态协调器到 CEF Frame 的适配 | rules -> live bridge |
| `AppShell/Adapters/PetMorph/AolaPetMorphLiveBridge.cs` | newpetpackage 页面脚本协议 | rules JSON -> ExternalInterface result |

### 3.2 BrowserHost（8）

| 文件 | 拥有的实现 | 主要传递 |
| --- | --- | --- |
| `BrowserHost/AolaCefInitializer.cs` | CEF/PPAPI 进程级初始化 | runtime DLL/settings -> `Cef.Initialize` |
| `BrowserHost/AolaBrowserSession.cs` | CefSharp 会话适配 | frame/lifecycle/script <-> `IBrowserSession` |
| `BrowserHost/AolaPageBridge.cs` | 页面操作白名单和 envelope 校验 | feature request -> JS/Flash -> typed result |
| `BrowserHost/Contracts/BrowserScriptContracts.cs` | 脚本请求/结果 DTO | caller <-> browser adapter |
| `BrowserHost/Contracts/IBrowserSession.cs` | 浏览器会话端口 | feature/page bridge -> Cef adapter |
| `BrowserHost/Contracts/IPageBridge.cs` | 页面桥端口和失败语义 | feature -> approved operations |
| `BrowserHost/Testing/ManualBrowserSession.cs` | 浏览器测试替身 | scripted response/events -> tests |
| `BrowserHost/Testing/ManualPageBridge.cs` | 页面桥测试替身 | feature request -> recorded call/result |

### 3.3 ActiveSend（5）

| 文件 | 拥有的实现 | 主要传递 |
| --- | --- | --- |
| `Features/ActiveSend/AolaExtensionMap.cs` | 命令白名单与 extensionId | command -> extensionId |
| `Features/ActiveSend/AolaFlashCommandSender.cs` | 生产发送编排 | request -> page bridge -> progress/result |
| `Features/ActiveSend/AolaSendRequestParser.cs` | UI 输入解析 | text/JSON -> `AolaSendRequest` |
| `Features/ActiveSend/IAolaCommandSender.cs` | 发送端口与阶段 DTO | feature -> sender |
| `Features/ActiveSend/ResourceInterception/StartBridgeResourceRule.cs` | start bridge 资源所有权 | start SWF request -> local bridge/pass |

### 3.4 Battle（20）

| 文件 | 拥有的实现 | 主要传递 |
| --- | --- | --- |
| `Features/Battle/Bridge/BattleBridgeClient.cs` | battle 页面桥客户端 | settings/state request -> typed bridge result |
| `Features/Battle/Coordination/BattleMorphCoordinationContracts.cs` | 模型预检/激活端口 | morph rules -> prepared snapshot |
| `Features/Battle/Coordination/BattlePresentationCoordinator.cs` | 表现、设置与模型切换编排 | UI settings -> store/bridge/resource target |
| `Features/Battle/Data/BattleConfigurationCatalog.cs` | 战斗配置目录 | resource data -> metadata lookup |
| `Features/Battle/Diagnostics/BattleDiagnosticsClient.cs` | Flash 诊断读取 | page bridge -> diagnostics/trace |
| `Features/Battle/Diagnostics/BattlePerformanceRecorder.cs` | 性能采样与文件输出 | packet + Flash diagnostics -> logs |
| `Features/Battle/Replay/BattleSequenceValidator.cs` | 序列 JSON 静态验证 | JSON -> immutable plan |
| `Features/Battle/Replay/BattleSequenceRunner.cs` | 战斗序列状态机 | plan + packet/bridge state -> sends/updates |
| `Features/Battle/ResourceInterception/BattlePetMovieResourceRule.cs` | 战斗模型资源选择 | movie URL + active snapshot -> local/pass |
| `Features/Battle/ResourceInterception/BattlePetMovieResourceTransformer.cs` | 模型 SWF 变换 | official SWF + rule -> transformed SWF |
| `Features/Battle/ResourceInterception/BattlePetMovieVersionCatalog.cs` | pet movie 版本目录 | JSON -> petId/version |
| `Features/Battle/ResourceInterception/PetFightBattleBridgeArtifact.cs` | bridge manifest/hash/marker 验证 | manifest + SWF -> verified artifact |
| `Features/Battle/ResourceInterception/PetFightBattleBridgeResourceRule.cs` | petfightnew 资源所有权 | request -> verified bridge/pass |
| `Features/Battle/Settings/BattleSettings.cs` | battle model 与 codec | section JSON <-> settings |
| `Features/Battle/State/AolaBattleLoadoutParser.cs` | 配置字段解析 | packet fields -> loadout states |
| `Features/Battle/State/AolaBattleModels.cs` | packet-derived 战斗模型 | parser/tracker -> consumers |
| `Features/Battle/State/AolaBattlePacketParser.cs` | packet 到领域增量 | event -> update/ignore |
| `Features/Battle/State/AolaBattleStateTracker.cs` | 跨包状态聚合 | updates -> snapshot/event |
| `Features/Battle/State/IBattleStateSource.cs` | 只读战斗状态端口 | tracker -> UI/runner/recorder |
| `Features/Battle/State/Testing/ManualBattleStateSource.cs` | 战斗状态测试替身 | test snapshot -> consumers |

### 3.5 Lineup（3）

| 文件 | 拥有的实现 | 主要传递 |
| --- | --- | --- |
| `Features/Lineup/LineupCoordinator.cs` | 阵容操作门面 | UI -> preset/session/safety gate |
| `Features/Lineup/LineupPreset.cs` | 方案模型、文件存储与解析 | server data <-> preset file |
| `Features/Lineup/LineupSession.cs` | 单次读取/恢复状态机 | send -> matched packet -> verify/read-back |

### 3.6 PetMorph（11）

| 文件 | 拥有的实现 | 主要传递 |
| --- | --- | --- |
| `Features/PetMorph/AolaPetMorphRule.cs` | 运行期形态规则值对象 | settings -> rules/bridge |
| `Features/PetMorph/AolaPetPosterCatalog.cs` | 海报目录 | JSON -> petId/resource lookup |
| `Features/PetMorph/Coordination/PetMorphCoordinationContracts.cs` | coordinator/rule/push 端口 | UI -> coordinator dependencies |
| `Features/PetMorph/Coordination/PetMorphCoordinator.cs` | 规范化、预检、保存、应用 | settings -> store/rules/page |
| `Features/PetMorph/Coordination/PetMorphPushResult.cs` | live push 结果 | bridge -> coordinator/UI |
| `Features/PetMorph/Coordination/Testing/ManualPetMorphPushBridge.cs` | push 测试替身 | request -> record/result |
| `Features/PetMorph/Coordination/Testing/ManualPetMorphRuleTarget.cs` | rule target 测试替身 | rules -> record/result |
| `Features/PetMorph/ResourceInterception/PetMovieResourceRule.cs` | movie 远端重写 | URL + rules -> rewrite/pass |
| `Features/PetMorph/ResourceInterception/PetPackageLiveResourceRule.cs` | package bridge 开关 | package request -> local/pass |
| `Features/PetMorph/ResourceInterception/PetPosterResourceRule.cs` | poster 远端重写 | URL + catalog/rules -> rewrite/pass |
| `Features/PetMorph/Settings/PetMorphSettings.cs` | petMorph model 与 codec | section JSON <-> settings |

### 3.7 Theme（5）

| 文件 | 拥有的实现 | 主要传递 |
| --- | --- | --- |
| `Features/Theme/Coordination/ThemeCoordinationContracts.cs` | 主题端口与结果 | UI -> coordinator/target |
| `Features/Theme/Coordination/ThemeCoordinator.cs` | 应用与保存顺序 | themeId -> target/store |
| `Features/Theme/Coordination/Testing/ManualThemeSelectionTarget.cs` | target 测试替身 | selection -> record |
| `Features/Theme/ResourceInterception/ThemeLeafResourceRule.cs` | 主题叶子 SWF 所有权 | URL + theme -> local/pass |
| `Features/Theme/Settings/ThemeSettings.cs` | theme model 与 codec | section JSON <-> settings |

### 3.8 PacketHost（5）

| 文件 | 拥有的实现 | 主要传递 |
| --- | --- | --- |
| `PacketHost/IAolaPacketEventSource.cs` | 宿主事件端口 | adapter -> all packet consumers |
| `PacketHost/AolaHookHostAdapter.cs` | 静态 IPC 事件适配/退订 | Contracts events -> host events |
| `PacketHost/PacketEventDispatch.cs` | 订阅者异常隔离 | payload -> each handler |
| `PacketHost/Consumers/AolaReceiveLogger.cs` | 按需脱敏 JSONL | packets -> file |
| `PacketHost/Testing/ManualAolaPacketEventSource.cs` | packet 测试替身 | test payload -> consumers |

### 3.9 ResourceInterception（22）

| 文件 | 拥有的实现 | 主要传递 |
| --- | --- | --- |
| `ResourceInterception/Cef/AolaResourceRequestHandler.cs` | CEF 总入口与规则装配 | CEF callbacks -> adapter/capture |
| `ResourceInterception/Cef/AolaSwfCaptureSession.cs` | 一次性 SWF 捕获 | response -> bounded capture/file |
| `ResourceInterception/Cef/AolaSwfResponseFilter.cs` | CEF 流式变换适配 | chunks -> processor -> chunks |
| `ResourceInterception/Cef/CefResourceRuleAdapter.cs` | CEF/抽象计划双向适配 | IRequest -> context/plan -> handler |
| `ResourceInterception/Contracts/IResourceInterceptionRule.cs` | 规则策略端口 | context -> plan |
| `ResourceInterception/Contracts/RemoteResourceFetch.cs` | 远端完整获取端口 | fetch request -> bytes/result |
| `ResourceInterception/Contracts/RemoteResourceProbe.cs` | 远端轻量探测端口 | probe request -> metadata |
| `ResourceInterception/Contracts/ResourceInterceptionPlan.cs` | 规则判别结果 | feature rule -> pipeline/adapter |
| `ResourceInterception/Contracts/ResourceRequestContext.cs` | 框架无关请求快照 | CEF request -> rules |
| `ResourceInterception/Contracts/ResourceResponseTransformation.cs` | 响应变换端口 | original bytes -> transformed result |
| `ResourceInterception/Pipeline/BoundedResourceResponseProcessor.cs` | 有界聚合和输出 | chunks -> transform -> chunks |
| `ResourceInterception/Pipeline/CachingRemoteResourceProbe.cs` | probe 缓存 | request -> cache/inner probe |
| `ResourceInterception/Pipeline/HttpRemoteResourceFetcher.cs` | HTTP 完整获取 | request -> bounded response |
| `ResourceInterception/Pipeline/HttpSwfRemoteResourceProbe.cs` | SWF HTTP 探测 | request -> headers/prefix metadata |
| `ResourceInterception/Pipeline/RemoteResourcePlanExecutor.cs` | rewrite 计划执行 | plan -> fetch/transform/response |
| `ResourceInterception/Pipeline/ResourceRuleEvaluation.cs` | 评估诊断对象 | rule result/error -> pipeline result |
| `ResourceInterception/Pipeline/ResourceRulePipeline.cs` | 优先级、冲突和失败关闭 | context -> unique plan/pass |
| `ResourceInterception/Pipeline/SwfResponseHeaderValidator.cs` | SWF 响应身份验证 | headers/prefix -> accept/reject |
| `ResourceInterception/Testing/ResourceInterceptionTestDoubles.cs` | 端口测试替身 | test delegates -> pipeline |
| `ResourceInterception/Transformers/AolaSwfBitmapScaler.cs` | 位图标签缩放 | FWS -> rewritten FWS |
| `ResourceInterception/Transformers/AolaSwfClassAdapter.cs` | FWS/CWS/ZWS 格式边界 | compressed SWF <-> FWS |
| `ResourceInterception/Transformers/AolaSwfResourceTransformer.cs` | transformer 组合门面 | transform input -> result |

### 3.10 Settings（4）

| 文件 | 拥有的实现 | 主要传递 |
| --- | --- | --- |
| `Settings/ISettingsSectionStore.cs` | store/codec 契约 | feature <-> persistence |
| `Settings/JsonSettingsSectionStore.cs` | section 合并、读取和保存 | JSON document <-> feature value |
| `Settings/AtomicSettingsWriter.cs` | 原子文件替换 | JSON -> disk |
| `Settings/LegacySettingsMigrator.cs` | 旧整文档迁移 | legacy root -> current root |

### 3.11 UI（10）

| 文件 | 拥有的实现 | 主要传递 |
| --- | --- | --- |
| `UI/Common/AolaFormBase.cs` | 公共窗口视觉基础 | derived forms -> consistent UI |
| `UI/Battle/AolaBattleAssistantForm.cs` | 战斗助手与序列入口 | snapshot/runner -> controls |
| `UI/Battle/AolaBattleSettingsForm.cs` | 战斗设置编辑 | controls -> coordinator |
| `UI/Battle/AolaPetPortraitProvider.cs` | 头像加载/缓存 | petId -> Image |
| `UI/Battle/BattleLoadoutView.cs` | 阵容可视化组件 | snapshot -> cards |
| `UI/Lineup/LineupPresetsForm.cs` | 阵容方案界面 | user -> coordinator/session |
| `UI/Packets/AolaPacketsForm.cs` | packet 查看和发送入口 | events/user input -> view/sender |
| `UI/Packets/AolaPacketsModernForm.cs` | packets 视觉控件 | UI state -> drawing |
| `UI/Packets/SendPacketVisibility.cs` | 发送区域布局纯函数 | state -> visibility |
| `UI/PetMorph/AolaPetMorphForm.cs` | 形态编辑界面 | controls -> coordinator |

### 3.12 入口与程序集（2）

| 文件 | 拥有的实现 | 主要传递 |
| --- | --- | --- |
| `Program.cs` | 单实例、WinForms/CEF 进程生命周期 | startup -> composition -> shutdown |
| `Properties/AssemblyInfo.cs` | AolaLoader 程序集元数据 | build metadata only |

## 4. AolaSocketHack.Contracts 逐文件索引（5）

| 文件 | 拥有的实现 | 主要传递 |
| --- | --- | --- |
| `AolaHookHostService.cs` | Remoting 服务、静态事件、兼容队列 | Hook -> host；legacy host -> Hook |
| `AolaHookStatus.cs` | Hook 状态 DTO | metrics -> host status |
| `AolaPacketEvent.cs` | 结构化 packet DTO | protocol -> host consumers |
| `AolaSendRequest.cs` | 遗留发送请求 DTO | legacy queue -> rejection |
| `AolaSendResult.cs` | 遗留发送结果 DTO | injected side -> host event |

Contracts 必须保持小、可序列化、双端兼容。这里不应放 UI、CEF、文件系统或 feature 规则。

## 5. AolaSocketHack 逐文件索引（13）

| 文件 | 拥有的实现 | 主要传递 |
| --- | --- | --- |
| `Hooking/MainClass.cs` | 注入入口、queue、parser worker、IPC 发布 | native capture -> parser -> host |
| `Hooking/WinsockHooks.cs` | LocalHook 与快速复制 | ws2_32 -> capture callbacks |
| `Hooking/WinsockNative.cs` | native ABI/PInvoke | managed hook <-> ws2_32 |
| `Hooking/AolaSocketCaptureFilter.cs` | socket 分类 | port/probe -> capture kind |
| `Hooking/CaptureRuntimeMetrics.cs` | capture/parser 指标 | counters -> status snapshot |
| `Hooking/AolaSidecarSender.cs` | 历史旁路发送 | captured login -> separate socket；生产禁用 |
| `Transport/FrameBuffer.cs` | TCP 消息边界 | chunks -> frames |
| `Transport/AolaCaptureEngine.cs` | per-socket 状态与解析编排 | frames -> packet events |
| `Protocol/AolaProtocol.cs` | 协议/XOR/InnerSeq/AMF3 语义 | frame/state <-> packet/send frame |
| `Protocol/Amf3Reader.cs` | AMF3 解码 | bytes -> object graph |
| `Protocol/Amf3Writer.cs` | AMF3 编码 | object -> bytes |
| `Protocol/AolaSendExporter.cs` | 安全发送样本导出 | decoded packet -> JSON line |
| `Properties/AssemblyInfo.cs` | Verify 可见性元数据 | build/test metadata |

## 6. 最重要的状态所有权

| 状态 | 唯一/主要所有者 | 消费者 | 不应由谁修改 |
| --- | --- | --- | --- |
| CEF 全局初始化 | `AolaCefInitializer` / `Program` | browser control | feature modules |
| 长期对象生命周期 | `AolaCompositionRoot` | MainForm/features | feature UI 自行 new 基础设施 |
| 每 socket buffer/协议序列 | `AolaCaptureEngine.ConnectionState` | `AolaProtocol` | 宿主 UI |
| 静态 IPC 事件 | `AolaHookHostService`，由 adapter 收口 | PacketHost | feature 直接订阅 Contracts |
| packet-derived battle snapshot | `AolaBattleStateTracker` | UI/recorder/gates | Flash bridge |
| Flash input state | patched SWF + `BattleBridgeClient` | runner/coordinator | packet tracker |
| settings 根文档 | `JsonSettingsSectionStore` | feature codecs | feature 直接文件写入 |
| 各 feature 字段规则 | 对应 `*SettingsCodec` | coordinator | store 猜测业务字段 |
| 资源路径所有权 | feature `IResourceInterceptionRule` | pipeline | CEF adapter 内硬编码 feature 规则 |

## 7. 注释边界与维护规则

1. 文件头解释架构，不重复每一行语法；局部算法继续由方法名、类型和关键行内注释说明。
2. 修改数据流时，同时更新生产者、承载契约、消费者以及本页对应行。
3. 新增 C# 文件时必须写明架构角色和数据流，并归入本页相应模块。
4. 注释不能把静态可达路径写成实机已验证结果。
5. 资源哈希、动态版本和运行证据保留在 manifest/runbook，不复制到本页。

## 8. 证据状态

- **已验证（静态）**：三个生产项目共 121 个 C# 文件均有架构角色/数据流注释；上述主要调用、事件、队列和 DTO 方向可由当前源码定位。
- **已验证（构建）**：`AolaSocketHack.Contracts`、`AolaSocketHack` 和 `AolaLoader` 的 Release 编译通过；宿主使用隔离输出目录避开运行中 DLL 锁。构建仍报告 CefSharp 87.1.132 的两条 `NU1903` 高危漏洞警告。
- **推断**：目录与 namespace 是主要逻辑边界，但 AolaLoader 仍是单程序集，编译器不会强制所有描述性边界。
- **未知**：当前官网页面、CEF 子进程分配、PPAPI 实际加载、Hook 注入成功率、服务器接受与最终画面效果仍需真实运行验证。
