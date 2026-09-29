# 模块目录

## 读法

这里的“对外接口”是模块对仓库内其他模块暴露的窄契约，不等同于公开 NuGet API。AolaLoader 大部分类型是 `internal`；物理目录和命名空间是当前主要边界，源码守卫补充约束。

## AppShell

- **职责**：进程级装配、主窗体、单实例、Hook 注入协调、子窗口生命周期。
- **对外接口**：`AolaCompositionRoot.MainForm`、`AolaHookController.EnsureInjected`、`IChildWindowCoordinator`。
- **输入**：可执行目录、CEF 子进程列表、各功能服务。
- **输出**：主窗口、注入请求、状态文本、子窗口显示/关闭。
- **依赖**：几乎所有宿主模块、WinForms、CefSharp、EasyHook、WMI。
- **禁止依赖**：功能算法不应反向依赖 `AolaMainForm`；注入 DLL 不应依赖 AppShell。
- **关键文件**：`Program.cs`、`AppShell/AolaCompositionRoot.cs`、`AppShell/AolaMainForm.cs`、`AppShell/AolaHookController.cs`、`AppShell/ChildWindowCoordinator.cs`。
- **细节规格**：[APP_SHELL_SPEC.md](../modules/APP_SHELL_SPEC.md)。

## BrowserHost

- **职责**：初始化 CEF/PPAPI；把 CefSharp 浏览器封装为生命周期和脚本执行接口；提供白名单页面桥操作。
- **对外接口**：`IBrowserSession`、`IPageBridge`、`PageBridgeRequest/Result`。
- **输入**：URL、脚本请求、功能状态、页面生命周期事件。
- **输出**：导航状态、脚本结果、桥调用结果。
- **依赖**：CefSharp、Newtonsoft.Json。
- **禁止依赖**：不解析游戏协议，不直接持久化业务设置，不订阅 IPC 静态事件。
- **关键文件**：`BrowserHost/AolaCefInitializer.cs`、`AolaBrowserSession.cs`、`AolaPageBridge.cs`、`BrowserHost/Contracts/`。
- **细节规格**：[BROWSER_HOST_SPEC.md](../modules/BROWSER_HOST_SPEC.md)。

## Settings

- **职责**：一个 JSON 文档内的分区读写、旧 Schema 5 迁移、原子写入；具体字段由模块 codec 所有。
- **对外接口**：`ISettingsSectionStore`、`ISettingsSectionCodec<T>`。
- **输入**：section key、模块值和 codec。
- **输出**：规范化值、默认/迁移标记、保存结果。
- **依赖**：文件系统、Newtonsoft.Json；旧迁移器目前知道 Battle 默认 section。
- **禁止依赖**：调用方不得取得并任意修改整个设置文档；Settings 不应依赖 UI 控件。
- **关键文件**：`Settings/JsonSettingsSectionStore.cs`、`AtomicSettingsWriter.cs`、`LegacySettingsMigrator.cs`。
- **细节规格**：[SETTINGS_SPEC.md](../modules/SETTINGS_SPEC.md)。

## PacketHost

- **职责**：把 Contracts 中的静态 Remoting 事件转换成可注入、可退订的宿主事件源；提供日志消费者和手工测试替身。
- **对外接口**：`IAolaPacketEventSource`。
- **输入**：`AolaPacketEvent`、`AolaHookStatus`、兼容 `AolaSendResult`。
- **输出**：宿主内事件、按需 JSONL 日志。
- **依赖**：`AolaSocketHack.Contracts`、Newtonsoft.Json、文件系统。
- **禁止依赖**：除适配器和 IPC 初始化外，宿主功能不得直接订阅 `AolaHookHostService` 静态事件。
- **关键文件**：`PacketHost/AolaHookHostAdapter.cs`、`IAolaPacketEventSource.cs`、`Consumers/AolaReceiveLogger.cs`。
- **细节规格**：[PACKET_HOST_SPEC.md](../modules/PACKET_HOST_SPEC.md)。

## ResourceInterception

- **职责**：把 CEF 请求转换成稳定上下文；按优先级评估资源规则；执行本地响应、远端探测/抓取和有界变换；失败时回退官方资源。
- **对外接口**：`IResourceInterceptionRule`、`ResourceInterceptionPlan`、`IResourceResponseTransformer`、probe/fetch 契约。
- **输入**：URL、HTTP 方法、资源类型、请求头、规则运行状态。
- **输出**：PassThrough、LocalResponse 或 RewriteRemote 计划以及 CEF handler。
- **依赖**：CefSharp、HTTP、SWF 变换器；具体 feature rules 从 Theme/PetMorph/Battle/ActiveSend 注册。
- **禁止依赖**：通用 pipeline 不应知道具体 UI 或设置格式；规则不得隐式抢占未声明路径。
- **关键文件**：`ResourceInterception/Contracts/`、`Pipeline/ResourceRulePipeline.cs`、`Cef/CefResourceRuleAdapter.cs`、`Cef/AolaResourceRequestHandler.cs`。
- **细节规格**：[RESOURCE_PIPELINE_SPEC.md](../modules/RESOURCE_PIPELINE_SPEC.md)。

## Theme

- **职责**：主题选项、设置保存和 controlbar skin 叶子 SWF 替换。
- **对外接口**：`IThemeCoordinator`、`IThemeSelectionTarget`、`ThemeLeafResourceRule`。
- **输入**：主题 ID、目标 controlbar URL、本地主题资源。
- **输出**：保存结果和可选本地 SWF 响应。
- **依赖**：Settings、ResourceInterception contracts。
- **禁止依赖**：不控制浏览器生命周期，不处理 Pet/Battle 资源。
- **关键文件**：`Features/Theme/Coordination/`、`Settings/ThemeSettings.cs`、`ResourceInterception/ThemeLeafResourceRule.cs`。
- **细节规格**：[THEME_SPEC.md](../modules/THEME_SPEC.md)。

## PetMorph

- **职责**：背包模型、海报和 live bridge 形态规则；校验、保存、资源准备与页面推送。
- **对外接口**：`IPetMorphCoordinator`、`IPetMorphRuleTarget`、`IPetMorphPushBridge`。
- **输入**：形态规则、poster catalog、目标远端资源、页面主 frame。
- **输出**：资源规则快照、经过验证的映射、页面注入结果。
- **依赖**：Settings、Browser frame adapter、ResourceInterception、HTTP probe/fetch。
- **禁止依赖**：不得复用 BattleMorph 的 fightassets 语义；UI 不应直接修改底层资源规则。
- **关键文件**：`Features/PetMorph/Coordination/`、`Features/PetMorph/ResourceInterception/`、`AppShell/Adapters/PetMorph/`。
- **细节规格**：[PET_MORPH_SPEC.md](../modules/PET_MORPH_SPEC.md)。

## ActiveSend

- **职责**：解析严格 `#send`、验证扩展 ID 映射、通过页面桥提交给 Flash 原连接并规范化提交结果。
- **对外接口**：`IAolaCommandSender`、`AolaSendRequestParser`。
- **输入**：extension ID、command、JSON object 参数、取消令牌。
- **输出**：SubmissionFailed、TimedOut、SubmittedToFlash 或明确 server result。
- **依赖**：BrowserHost `IPageBridge`、Contracts DTO、start bridge 资源规则。
- **禁止依赖**：不得建立第二连接、回放登录帧或走 Hook sidecar；未知扩展映射必须拒绝。
- **关键文件**：`Features/ActiveSend/AolaFlashCommandSender.cs`、`AolaExtensionMap.cs`、`ResourceInterception/StartBridgeResourceRule.cs`。
- **细节规格**：[ACTIVE_SEND_SPEC.md](../modules/ACTIVE_SEND_SPEC.md)。

## Battle

- **职责**：接收包到不可变读快照；配置解析；战斗页面桥状态；入口确认后定时发送序列；表现设置；模型资源替换；性能诊断。
- **对外接口**：`IBattleStateSource`、`BattleBridgeClient`、`BattlePresentationCoordinator`、`IBattleMorphRuleTarget`。
- **输入**：已解析 packet、页面桥状态、战斗设置、严格发送计划、资源清单。
- **输出**：`AolaBattleSnapshot`、战斗设置应用结果、序列状态、诊断 JSONL、匹配的 SWF 响应。
- **依赖**：PacketHost、ActiveSend、BrowserHost、Settings、ResourceInterception。
- **禁止依赖**：packet snapshot 不得伪装成 Flash 输入就绪状态；序列不得自动重试；BattleMorph 不得复用 PetMorph 规则。
- **关键文件**：`Features/Battle/State/`、`Bridge/`、`Replay/`、`Coordination/`、`Diagnostics/`、`ResourceInterception/`。
- **细节规格**：[BATTLE_SPEC.md](../modules/BATTLE_SPEC.md)。

## Lineup

- **职责**：读取阵容为独立 JSON 方案；在非战斗状态下串行恢复顺序、魂卡、魂器和晶钥，并逐步回读核对。
- **对外接口**：当前为具体 `LineupCoordinator`、`LineupPresetStore`，没有独立接口层。
- **输入**：packet event source、command sender、battle snapshot、preset JSON。
- **输出**：`LineupPreset`、进度、成功或明确停止原因。
- **依赖**：PacketHost、ActiveSend、Battle.State、Newtonsoft.Json、文件系统。
- **禁止依赖**：不得在活动战斗中执行；不得并行请求；不得在缺少明确回读时宣称恢复成功；不持久化响应正文或凭据。
- **关键文件**：`Features/Lineup/LineupCoordinator.cs`、`LineupSession.cs`、`LineupPreset.cs`、`UI/Lineup/LineupPresetsForm.cs`。
- **细节规格**：[LINEUP_SPEC.md](../modules/LINEUP_SPEC.md)。

## UI

- **职责**：WinForms 展示、输入、线程切换和子窗口交互。
- **对外接口**：各 Form；不是业务模块 API。
- **输入**：协调器、事件源、快照、用户操作。
- **输出**：功能调用、状态显示、文件选择。
- **依赖**：AppShell 公共 UI 基类和各 feature contracts/部分具体类型。
- **禁止依赖**：不应直接解析协议字节、操作 Winsock 或绕过 coordinator 写设置。
- **关键文件**：`UI/Packets/`、`UI/Battle/`、`UI/PetMorph/`、`UI/Lineup/`、`UI/Common/`。

## AolaSocketHack

- **职责**：注入网络进程、Hook Winsock、筛选候选 socket、重组帧、解析协议、脱敏并发布。
- **对外接口**：EasyHook `MainClass : IEntryPoint`；宿主只通过 Contracts IPC 接收。
- **输入**：send/recv/WSASend/WSARecv/connect/closesocket 字节与句柄。
- **输出**：`AolaPacketEvent`、`AolaHookStatus`。
- **依赖**：EasyHook、Contracts、Newtonsoft.Json。
- **禁止依赖**：不得依赖 AolaLoader UI、Settings、CefSharp；生产不得旁路发包。
- **关键文件**：`Hooking/MainClass.cs`、`WinsockHooks.cs`、`AolaSocketCaptureFilter.cs`、`Transport/AolaCaptureEngine.cs`、`Protocol/AolaProtocol.cs`。
- **细节规格**：[NETWORK_CAPTURE_SPEC.md](../modules/NETWORK_CAPTURE_SPEC.md)、[PROTOCOL_IPC_SPEC.md](../modules/PROTOCOL_IPC_SPEC.md)。

## AolaSocketHack.Contracts

- **职责**：跨 AppDomain/进程可序列化 DTO、Remoting 服务、兼容待发队列。
- **对外接口**：`AolaHookHostService`、`AolaPacketEvent`、`AolaHookStatus`、`AolaSendRequest/Result`。
- **输入/输出**：注入端发布 packet/status，宿主订阅；兼容 send queue 当前只会被注入端拒绝。
- **依赖**：仅 .NET Framework 基础库。
- **禁止依赖**：不得引用宿主或 Hook 具体实现。
- **关键文件**：`analysis/AolaSocketHack.Contracts/*.cs`。

## Verify 与维护工具

- **职责**：契约自测、源码守卫、资源清单/哈希验证、资源准备和诊断。
- **对外接口**：命令行入口和脚本参数。
- **输入**：源码、资源、测试向量和证据目录。
- **输出**：退出码、校验报告、生成的分发资源。
- **依赖**：Contracts、SocketHack；Verify 还直接链接选定宿主源码。
- **禁止依赖**：生成目录和逆向证据不得在运行时被宿主隐式读取。
- **关键文件**：`analysis/AolaSocketHack.Verify/`、`analysis/tools/`、`build.ps1`。

