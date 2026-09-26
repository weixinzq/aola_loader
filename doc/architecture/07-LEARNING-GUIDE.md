# 学习指南

## 第一阶段：先建立地图

按以下顺序阅读，目标是先知道“对象在哪里创建、边界在哪里”，暂时不要钻协议细节：

1. [00-OVERVIEW.md](00-OVERVIEW.md)：确认系统解决的问题与两条主链。
2. [10-SOURCE-FILE-GUIDE.md](10-SOURCE-FILE-GUIDE.md)：按模块查任意源文件的职责、输入和输出。
3. `analysis/AolaLoader/Program.cs`：看进程入口、单实例和最终关闭。
4. `analysis/AolaLoader/AppShell/AolaCompositionRoot.cs`：看所有长期对象如何连接。
5. [01-SYSTEM-MAP.md](01-SYSTEM-MAP.md) 和 [04-DEPENDENCIES.md](04-DEPENDENCIES.md)：建立进程与依赖方向。
6. `analysis/AolaLoader/AppShell/AolaMainForm.cs`：只看构造函数、Shown、OnFormClosed、EnsureHookInjectedAsync、BrowserFrameLoadEnd。

完成标准：能够解释宿主、network.mojom、Hook DLL、页面/Flash 和服务端之间的关系。

## 第二阶段：理解观察链

1. `analysis/AolaSocketHack.Contracts/AolaPacketEvent.cs`
2. `analysis/AolaSocketHack/Hooking/MainClass.cs`
3. `analysis/AolaSocketHack/Hooking/WinsockHooks.cs`
4. `analysis/AolaSocketHack/Hooking/AolaSocketCaptureFilter.cs`
5. `analysis/AolaSocketHack/Transport/FrameBuffer.cs`
6. `analysis/AolaSocketHack/Transport/AolaCaptureEngine.cs`
7. `analysis/AolaSocketHack/Protocol/AolaProtocol.cs`
8. `analysis/AolaLoader/PacketHost/AolaHookHostAdapter.cs`

配合 [NETWORK_CAPTURE_SPEC.md](../modules/NETWORK_CAPTURE_SPEC.md) 和 [PROTOCOL_IPC_SPEC.md](../modules/PROTOCOL_IPC_SPEC.md)。

完成标准：能够从一次 `recv` 解释到一个脱敏 `AolaPacketEvent`，并说明为什么解析不在 Hook 回调执行。

## 第三阶段：理解控制链

1. `BrowserHost/Contracts/IBrowserSession.cs`
2. `BrowserHost/AolaBrowserSession.cs`
3. `BrowserHost/Contracts/IPageBridge.cs`
4. `BrowserHost/AolaPageBridge.cs`
5. `Features/ActiveSend/AolaFlashCommandSender.cs`
6. `Features/ActiveSend/ResourceInterception/StartBridgeResourceRule.cs`

配合 [ACTIVE_SEND_SPEC.md](../modules/ACTIVE_SEND_SPEC.md)。

完成标准：能区分 PageReady、BridgeInstalled、SubmittedToFlash、ServerSucceeded 四个阶段，并明确 Hook 不是生产发包器。

## 第四阶段：理解资源管线

1. `ResourceInterception/Contracts/`
2. `Pipeline/ResourceRulePipeline.cs`
3. `Cef/CefResourceRuleAdapter.cs`
4. `Pipeline/RemoteResourcePlanExecutor.cs`
5. `Cef/AolaResourceRequestHandler.cs`
6. 再选择一个 feature rule：Theme 最简单，PetMorph/Battle 更复杂。

完成标准：能说明 PassThrough、LocalResponse、RewriteRemote，优先级冲突为何放行，以及为什么 manifest 是运行时契约。

## 第五阶段：理解战斗

分两条读，不要混在一起：

### Packet snapshot

1. `Features/Battle/State/AolaBattleModels.cs`
2. `AolaBattlePacketParser.cs`
3. `AolaBattleLoadoutParser.cs`
4. `AolaBattleStateTracker.cs`
5. `UI/Battle/AolaBattleAssistantForm.cs`

### Flash bridge 与序列

1. `Features/Battle/Bridge/BattleBridgeClient.cs`
2. `Features/Battle/Replay/BattleSequenceValidator.cs`
3. `Features/Battle/Replay/BattleSequenceRunner.cs`
4. `Features/Battle/ResourceInterception/PetFightBattleBridgeArtifact.cs`
5. `Resources/Patches/petfightnew-battle-state.current.json`

完成标准：能解释 snapshot 与 bridge state 的区别，以及一条战斗消息为什么是“只提交一次、分阶段等待、失败不重试”。

## 第六阶段：理解功能组合

- Theme：最小的 settings → coordinator → resource target 示例。
- PetMorph：设置、预检、页面推送和多条资源规则的组合示例。
- BattlePresentation：设置、Flash bridge 与资源激活的组合示例。
- Lineup：packet 订阅 + ActiveSend + server read-back 的事务式工作流示例。

## 哪些先别碰

- `AolaProtocol` 的加密、AMF3、序列和登录状态，除非已有协议向量和具体命令证据。
- Winsock Hook 签名、缓冲长度和 WSA error 保存逻辑。
- petfight/start/newpetpackage 候选 SWF 及其 manifest/hash。
- BattleSequenceRunner 的 2405、执行结果、readyEpoch 和人工操作检测。
- `LegacySettingsMigrator`，除非同时理解旧 Schema 5 和各当前 codec。
- `analysis/reverse-engineering/` 中的历史产物；先确认版本和当前生产清单是否引用。

## 调试入口

| 问题 | 第一入口 | 第二证据 |
| --- | --- | --- |
| 程序起不来/Flash 缺失 | `Program.Main`、`AolaCefInitializer` | 输出目录 `runtime/pepflashplayer.dll`、`cef.log` |
| Hook 未注入 | `AolaMainForm.EnsureHookInjectedAsync` | status 事件、network.mojom 命令行 |
| 抓不到包 | `MainClass` metrics、capture filter | queue/drop/buffer/protocolErrors 状态 |
| 包解析错误 | `AolaCaptureEngine` → `AolaProtocol` | Verify 协议向量、脱敏 JSONL |
| 页面桥未就绪 | `AolaPageBridge` | MainFrame lifecycle、目标 ExternalInterface 方法 |
| 资源没有替换 | 具体 rule `Evaluate` | pipeline reason、manifest、哈希与 URL 版本 |
| 战斗助手不更新 | `AolaBattlePacketParser` | last command、ConnectionPlayerId、snapshot clone |
| 战斗序列停住 | `BattleSequenceRunner` | 方向时间戳、2405、执行结果、bridge inputReady/readyEpoch |
| 阵容操作停止 | `LineupSession.OnPacket` | process/socket/player、发送捕获与目标响应阶段 |
| 设置丢失 | module codec → `JsonSettingsSectionStore` | load result error、legacy migration、原子写入 |

## 如何验证理解

先用 `AolaSocketHack.Verify` 的契约/源码守卫建立静态信心，再按模块 runbook 做真实运行。不要把“Verify 通过”“项目构建通过”“候选哈希一致”和“真实 Flash/服务器通过”合并为一个结论。

