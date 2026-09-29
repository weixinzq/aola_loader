# 运行链路

## 1. 启动流程

```text
Program.Main
  → 切换当前目录到 exe 目录
  → 设置 DPI aware
  → 获取全局 mutex
  ├─ 已有实例：恢复并前置已有主窗口，退出
  └─ 新实例
      → EnableVisualStyles
      → new AolaCompositionRoot
          → settings.json store + PetMorph 初始设置
          → AolaCefInitializer.Initialize
          → HookController + PacketHost + logger + BattleStateTracker
          → ResourceRequestHandler + feature rules
          → ThemeCoordinator
          → ChromiumWebBrowser(DefaultUrl)
          → PetMorphCoordinator
          → BrowserSession → PageBridge
          → Battle diagnostics/presentation
          → ActiveSend → Lineup
          → ChildWindowCoordinator → AolaMainForm
      → Application.Run(MainForm)
      → root.Dispose
      → Cef.Shutdown
```

主窗体显示后启动两个 UI timer：750 ms 轮询 CEF network 进程并确保注入；500 ms 检查待激活的战斗模型规则。它还恢复模型规则，并在主 frame 加载完成时重新推送 PetMorph 与 Battle 表现设置。

## 2. 登录流程

当前代码没有独立登录服务，登录属于网页和 Flash：

```text
ChromiumWebBrowser 打开 DefaultUrl
  → 官网页面加载 object/embed
  → PPAPI Flash 加载 start/game SWF
  → Flash 自身完成账号、选服和 SocketClient 登录
  → network.mojom 中的 Hook 观察登录发送帧
      → AolaProtocolState 记录连接身份
      → 对外 AolaPacketEvent 将登录原文替换为 <登录帧已脱敏>
```

代码可证明注入进程会在每个连接状态中暂存登录帧副本，连接关闭、空闲清理或引擎释放时清零；当前生产发送不读取它。具体账号认证页面、服务端鉴权步骤和会话有效期不在仓库源码中，属于运行时待证。

## 3. CEF → Flash 调用流程

### 页面桥控制链

```text
Feature/UI
  → IPageBridge.InvokeAsync(operation, JObject, timeout)
  → AolaPageBridge 生成受控 JavaScript
  → IBrowserSession.ExecuteScriptAsync
  → main frame EvaluateScriptAsync
  → 查找 #swfContainer 或 object/embed 中具备目标方法的 Flash 对象
  → ExternalInterface 方法
  → JSON envelope 返回宿主
```

当前白名单操作包括：

- `activeSend.submit` → `aolaSendCommand`
- `panel.open` → `aolaOpenPanel`
- `playback.apply` → `aolaSetPlayback`
- `battle.apply` → `aolaBattleApplyOptions`
- `battle.state` → `aolaBattleGetState`
- `battle.diagnostics` → `aolaBattleGetDiagnostics`
- `battle.diagnostics.events` → `aolaBattleDrainTraceEvents`
- `feature.push` → 页面内带 revision 的状态缓存

页面生命周期不是桥已安装的充分条件。Main frame ready 只表示脚本可执行；若目标 ExternalInterface 方法不存在，结果会变成 `BridgeNotInstalled`。

### 资源加载链

```text
CEF resource request
  → AolaResourceRequestHandler
  ├─ 可选 SWF capture session
  └─ CefResourceRuleAdapter
      → ResourceRulePipeline（高优先级优先）
      ├─ PassThrough：CEF 继续官方请求
      ├─ LocalResponse：内存返回本地 bytes，禁止缓存
      └─ RewriteRemote
          → probe（可用 10 分钟 / 不可用 30 秒缓存）
          → bounded fetch
          → header/content/transform validation
          ├─ 成功：内存返回变换结果
          └─ 失败：不提供 handler，继续原始请求
```

同一优先级出现多个非 PassThrough 匹配、规则异常、返回 null、改变原始 URL 身份、fallback/rewrite 递归时，pipeline 都会选择放行。

## 4. Hook 注入流程

```text
AolaMainForm 750 ms timer
  → WMI 查找当前宿主的 CefSharp.BrowserSubprocess.exe
  → CommandLine 包含 type=network.mojom
  → AolaHookController.EnsureInjected(pid, AolaSocketHack.dll)
      → RemoteHooking.Inject(..., IPC channelName)
      → 注入端 MainClass 连接 AolaHookHostService
      → 安装 send/recv/WSASend/WSARecv/connect/closesocket hooks
```

注入端主循环每 5 秒清理 30 分钟未活动状态并在指标变化、丢弃、溢出或解析停滞时上报。宿主保存已注入 PID 以避免重复注入；`Dispose` 只清除宿主记录，实际卸载依赖目标进程/注入生命周期。

## 5. 网络消息流程

```text
Winsock original call
  → 成功字节副本
  → AolaSocketCaptureFilter
      ├─ 端口 8000..8100
      ├─ Flash policy 特征
      └─ 登录帧特征 / 诊断全捕获开关
  → bounded queue [4096]
  → AolaSocketHack.Parser
  → per-socket FrameBuffer（收、发分离）
  → AolaProtocol
      ├─ 客户端帧：外层解密、登录或扩展命令
      └─ 服务端帧：system/AMF3
  → AolaPacketEvent（登录脱敏，附连接玩家 ID）
  → Remoting IPC
  → AolaHookHostAdapter
      ├─ Packets UI
      ├─ AolaReceiveLogger
      ├─ AolaBattleStateTracker
      ├─ BattleSequenceRunner（运行时短订阅）
      └─ LineupSession（一次操作一个订阅）
```

事件不保证在 UI 线程。WinForms 消费者必须自行 `Invoke/BeginInvoke`，长期消费者必须在 Dispose 退订。

## 6. 战斗消息流程

```text
接收 AolaPacketEvent
  → AolaBattlePacketParser
      → 只接受 2303/2304/2401/2426/2411/2404/2309
      → ParametersJson → battleView / b[] / pmmList[]
      → pmSView、能力、技能、配置解析
  → AolaBattlePacketUpdate
  → AolaBattleStateTracker.ApplyUpdate
      → 新战斗重置或保留最近 roster
      → 按 pmmId / uniqueId / slotId 增量合并
      → 缺省配置由 PreserveMissing 保留
  → clone AolaBattleSnapshot
  → SnapshotChanged
```

`2404` 与 `2309` 标记结束；`2401` 标记新战斗。`2303` 会先清空 snapshot，随后的 `2401` 可在参与者交集成立时带入最近 roster。

## 7. BattleSnapshot 流程

`AolaBattleSnapshot` 是宿主根据接收 packet 合成的读模型，包含：战斗/结束标记、`battleUniqueId`、当前玩家 pmmId、最后命令/时间和双方宠物状态。读取和发布都返回深拷贝，避免消费者修改 tracker 内部状态。

主要消费者：

```text
IBattleStateSource.CurrentSnapshot / SnapshotChanged
  ├─ AolaBattleAssistantForm：显示敌方属性与配置
  ├─ BattlePerformanceRecorder：把 packet 状态与 Flash diagnostics 对齐采样
  └─ LineupCoordinator：只把 HasBattle && !IsEnded 用作禁止阵容操作的门
```

它不等同于 `BattleBridgeState`。后者直接从 patched `petfightnew` 读取 `active/battleId/turn/inputReady/readyEpoch/ended`，供战斗序列首次确认、身份检查与模型规则安全激活使用。两者不得互换：

| 状态 | 来源 | 适合回答的问题 |
| --- | --- | --- |
| `AolaBattleSnapshot` | 服务器接收包的宿主聚合 | 参战者是谁、属性/配置是什么、是否看到结束包 |
| `BattleBridgeState` | Flash 内部状态桥 | 当前 turn、输入窗口是否打开、readyEpoch 是否推进 |

## 8. 战斗入口确认后定时发送

```text
严格 #send 列表
  → BattleSequenceValidator
      → SetupItems + TurnGroups
  → BattleSequenceRunner 订阅 packet
      → 可选入口消息各提交一次
      → 等待 packet 战斗身份 + Flash bridge inputReady
      → 每条 IAolaCommandSender.SendAsync 一次
      → 后续相邻提交间隔 200ms，不等待抓包/2405/执行结果/新输入窗口
      → 每条提交前检查战斗仍活动且身份未变化，保留输入 turn
      → 入口超时、取消、提交/桥失败、战斗结束或身份变化：停止，不自动重试
```

控制链仍通过 ActiveSend 进入 Flash 原连接。该 runner 的 packet 订阅只用于新战斗入口身份确认；后续操作不以收发包作为放行条件。

## 9. 阵容读取与恢复

```text
LineupCoordinator
  → 拒绝并发；拒绝活动战斗
  → new LineupSession（先订阅 packet）
  → IAolaCommandSender 提交请求
  → 匹配同 process/socket/player 的发送抓包和指定响应
  → 15 秒分阶段超时，不自动重发
  → Read：连续读取两次并比较
  → Restore：全部预检 → 串行修改 → 每步回读 → 全量最终回读
```

方案 JSON 由 UI 保存到用户选择位置，默认目录位于 `%LocalAppData%/AolaLoader/Lineups`。运行时响应正文和凭据不被 LineupSession 持久化。

## 10. 关闭流程

主窗口先停止 timer、退订 status 并释放子窗口；随后 CompositionRoot 依次释放性能记录器、子窗口协调器、页面桥、浏览器会话、浏览器、packet adapter、logger、battle tracker 和 hook controller，最后 `Program` 关闭 CEF。多个 Dispose 实现具备幂等检查，但依赖顺序仍应由 CompositionRoot 统一维护。

