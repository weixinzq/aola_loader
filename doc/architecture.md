# Aola Loader 架构

## 状态与范围

本文描述截至 2026-09-05 当前工作区代码和资源清单对应的架构；阶段 9 仅为历史重构基线。文档核对不新增真实 Flash 验收，证据范围见 [文档核对记录](DOCUMENTATION_AUDIT.md)。字段、哈希、实机记录和逆向细节分别路由到模块规格、`task/` 与 `analysis/reverse-engineering/`。

## 当前顶层架构

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
│  ├─ ActiveSend        FlashCommandSender / verified extension map
│  └─ Battle            State 与 Presentation 分离
└─ UI                    Packets 三页导航 / PetMorph / Battle 助手与表现设置

CefSharp network subprocess
└─ AolaSocketHack       Hooking / Capture / Protocol / Metrics

AolaSocketHack.Contracts
└─ 跨进程 DTO、remoting 事件与已禁用的兼容待发队列

AolaOfflineClient（独立 Python 进程）
└─ HTTPS Auth -> WSS/TCP -> Protocol -> SDK/CLI -> trusted scripts
```

第一轮继续使用现有 `AolaLoader.csproj`，通过物理目录、命名空间、构造函数注入和源码守卫建立边界；没有引入 DI 框架或不必要的程序集拆分。

`AolaOfflineClient` 是同仓库的独立登录子项目，不引用 AolaLoader 或 IPC，也不作为 ActiveSend 的回退。ActiveSend 复用当前 Flash 原连接；OfflineClient 使用本地账号密码创建另一条会话。同一账号不能同时走两条登录路径。

## 允许的依赖方向

```text
UI / AppShell -> 应用模块公开契约 -> 模块实现 -> 算法或框架适配器
Battle UI -> Battle state contract -> PacketHost contract
Feature resource rule -> ResourceInterception contracts -> SWF transformer
AolaSocketHack -> Protocol + AolaSocketHack.Contracts
AolaOfflineClient SDK/CLI -> Auth + Transport + Protocol（不依赖上列 .NET 项目）
```

禁止 `AolaSocketHack -> AolaLoader UI/Settings/CefSharp`。除 `AolaHookHostAdapter` 和 IPC 初始化外，宿主代码不得直接订阅 `AolaHookHostService` 静态事件。功能模块不得取得整个可变设置文档。资源规则实际契约名为 `IResourceInterceptionRule`。

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
     ├─ 接收 -> Battle state
     └─ 发送/接收 -> JSONL logger
```

登录帧和 SID 不跨越注入进程信任边界。抓包 UI 保持 send-only 且按需打开；完整日志默认关闭，点击主窗口“保留日志”后才创建兼容命名的 `aola-recv-*.jsonl` 并从该时刻持续记录收发两个方向。开始保留或持续写入失败期间最多暂存 8 MiB（按 UTF-8 字节计数），超限丢弃最早记录并计数；日志层再次脱敏登录发送。服务端 `type=0` 按 `action + headerRoomId + action-specific payload` 解析，已知房间/用户系统消息写入结构化 `cmd/param`，未知 action 保留结构化头和剩余 payload HEX。

Packets 子窗口采用“抓包 / 发包 / 打开映射面板”三页导航：抓包页只列出可转换为严格 `#send` 的发送消息并支持复选追加；发包页提供直接编辑、UTF-8 文件导入和“按战斗状态逐条发送”；映射面板页只调用 Flash 自身面板加载入口。主窗口另提供“战斗表现”设置窗口，保存隐藏伤害数字、隐藏治疗数字、“跳过每回合战斗演出”和独立的战斗模型替换规则；战斗模型规则不复用背包/海报规则。

对战助手的数据链为 `PacketHost -> Battle.State -> 敌方属性/配置双视图`。初始化消息记录真实参与者归属，UI 只读取已确认敌方；四类配置按位置保留，缺省增量不清空。独立的 `Prepare-BattleAssistantAssets.ps1` 将官方资源转换为图片和只读目录；运行时仅加载分发目录中的 `Resources/BattleAssistant`，不依赖逆向目录、不下载或转换 SWF。资源维护见 [图片准备说明](runbooks/BATTLE_ASSISTANT_ASSETS.md)。

### 主动发送

```text
Packets UI strict #send -> IAolaCommandSender -> IPageBridge
  -> controlled JavaScript -> ExternalInterface start bridge
  -> ActClientSender -> SocketClient -> current Flash game connection
  -> SubmittedToFlash -> UI immediately resumes
```

战斗状态回放在上述发送链路外增加只读节奏控制：生产路径从 `petfightnew-battle-state.current.json` 读取唯一资源版本和稳定候选哈希，只对该版本的 `petfightnew` 生效；清单、候选、边界、哈希或桥标记任一不符即放行官方资源。状态桥在同版本 `PetFightService.init`、`FightPanel.enableClick` 和文档类中接入只读状态；当前 Version 4 另有下述白名单演出叶方法补丁。状态接口暴露战斗路由 ID、回合、可操作状态和递增的 `readyEpoch`；`readyEpoch` 在 `FightPanel.enableClick` 打开一次操作窗口时递增。校验器先完整分段为 `SetupItems + TurnGroups`：首次 `PetExtension/54_22` 或已验证的 `id=13/cmd=1401..1407/1410` 是战斗边界，边界前的严格 `#send` 普通消息经原 `IAolaCommandSender` 按序各提交一次；边界后的未知命令、`1408/1409`、重复入口、非连续 turn 或同 turn 非连续出现均在任何发送前拒绝。`TurnGroups` 只负责输入顺序和 turn 连续性，运行期操作批由服务器反馈判定：每条只提交一次并等待匹配发送抓包及当前玩家 `2405`；当前玩家对应的 `2411..2417/2420` 结果或新 `readyEpoch` 表示本批结束，此后必须等新窗口并重新校验实时 turn；确认后 1 秒仍无结果/新窗口才继续同批下一条，同批允许跨相邻 turn 组。输入若在尚无执行结果的批中结束，则停止并报告可能缺少同批消息。

状态模式仍有两条战斗路径：新战斗路径在普通前缀后提交可选的 `HolidayExtension/74_1` 和一次 `PetExtension/54_22`，跳过导入的 Flash-owned `preFightLoad`，再等待新的 `2303/2304/2401` 身份与 Flash 可操作状态；当前战斗附着路径在普通前缀后读取 `active`、`ended`、`battleId`、`turn` 和 `inputReady`，只提交已验证的 `id=13` 回合组，无需补发 `54_22` 或检测 `preFightLoad`。队列不改写战斗协议参数，也不发送 Flash 自己负责的 `preFightLoad`。Flash 的 `FightData.battleId` 来自 `2401.br`，是允许为负数的有符号 32 位路由 ID；`2401.battleUniqueId` 是另一个正整数，只用于证明新战斗身份，不能与前者比较。先前会跳过表现的 v1/v2 候选继续保留为失败证据且不进入生产路径；抓包、战斗日志、战斗助手和“完整信息/对战信息”界面保持原路径。

2026-09-01 的真实 Flash 复测已确认：修正 `br` 与 `battleUniqueId` 的身份契约后，记录序列能够进入战斗并按 `readyEpoch` 提交 turn 0、1、2 操作。该结果只验收战斗识别与逐回合调度，不替代主动发送完成标准中的连接数量、重复登录、服务器响应和后续序列完整性等独立证据。

2026-09-02 的后续实机抓包证明消息级 `readyEpoch` 门控也不正确：`FightPanel.autoUseSkill` 的一次操作会调用多个 `PetClient.useSkill`，服务器逐条返回 `2405`，但在整批齐备后才返回执行结果；实测批次既可包含同 turn 多条，也可跨相邻 turn。runner 已改为匹配 `2405.reqId == abs(battleId)` 的逐条接收门控，并用对应执行结果/新 `readyEpoch` 恢复新窗口校验。该修正已通过本地契约测试；9 月 4 日获得下述纯状态候选的用户运行确认，但缺少新的消息抓包，各同批/跨 turn 边界仍不能视为全部验收。发送抓包和 `SubmittedToFlash` 均不能代替服务器执行结果。

当前战斗附着路径已接入同一实时状态桥，并由 BattleReplay contract self-test 覆盖；真实 Flash 中“已进入战斗后仅提交 id=13”的发送仍需单独复测，不能由本次状态桥实测或 `SubmittedToFlash` 推定成功。

`petfightnew` 周更使用 `analysis/tools/Update-PetFightBattleBridge.ps1` 的 `Check`、`Prepare`、`Promote` 三阶段。`Prepare` 总是从当周官方 SWF 重新发现方法体和私有命名空间、生成状态桥及 16 个演出叶方法补丁，并比较同版本 SymbolClass/p-code；结构或锚点不唯一即失败关闭，不能把旧补丁改名复用。`Promote` 只接受明确指定的候选清单。2026-09-04 的 `2026090340574444` 纯状态候选已完成全新进程实测，用户确认登录、战斗与所列回合操作可行且未出现重复登录或掉线；该轮没有保留发包前后的 TCP 数量快照，因此“无新增连接”仍属于用户观察。随后生成并晋级的 Bridge Version 4 演出候选已完成原件、FWS、SHA-256、649 项 SymbolClass 和 FFDec p-code 重读验证，但尚未完成新的真实 Flash 演出验收。操作与回滚步骤见 [`runbooks/PETFIGHTNEW_WEEKLY_UPDATE.md`](runbooks/PETFIGHTNEW_WEEKLY_UPDATE.md)。

`SubmittedToFlash` 只表示 Flash API 已接受调用，不表示服务器成功。普通发送 UI 不等待接收验证，
不轮询服务器终态，也不弹出模态结果框；本地脚本返回、socket 写入或协议回读均不是服务器成功。
扩展 ID 只从当前客户端 `ExtMap` 证据映射，未知 ID 拒绝。OuterSeq、InnerSeq、加密与发送顺序继续完全由 Flash 原连接拥有。

Packets UI 的“打开映射面板”是独立本地调用：`panel.open -> ExternalInterface aolaOpenPanel -> Panel_Helper.loadResAndShow`。它接受资源键/URL与 CLS 两个普通字符串，不执行脚本文本，不经过 socket；面板加载完成后产生的正常请求仍由 Flash 自身代码和原连接负责。

### 脱机独立登录

```text
local accounts.json -> HTTPS password authentication -> explicit zone selection
  -> verified WSS, or TCP fallback before login submission only
  -> login frame -> logOK -> one receive loop + per-account send lock
  -> SDK subscriptions / CLI / trusted Python script
```

OfflineClient 不接触捕获的 SID 或登录帧。它只把 `logOK` 视为 ready，进服务器、初始化和动态房间由脚本负责。脚本必须先订阅再发送；`SendReceipt` 只表示本地连接写入完成，服务器成功必须由明确匹配的接收消息证明。队列溢出、断线和结果不明的写入均显式失败，且不会自动重发。

### 浏览器资源

```text
Cef request -> AolaResourceRequestHandler / Cef adapter -> ordered ResourceRulePipeline
  -> PassThrough | LocalResponse | RewriteRemote
  -> precise probe / bounded buffering / bounded FWS/CWS/ZWS decode
  -> SWF class/bitmap contract validation
  -> transformed response or explicit original-resource fallback
```

规则按优先级降序、注册次序稳定排列；最高命中优先级只有一条非 PassThrough 时采用该计划，同优先级多命中则诊断并透传。规则不直接改 URL 或创建 CefSharp handler，Cef 类型只存在于适配层。

战斗模型替换只处理 `MCPetContainer -> PetAssetsLoader -> FightResConfig -> fightassets/bitmap` 位图叶资源。启用前按带官方 `versiondata` SHA-256 的静态清单解析目标双方朝向的 `0/1/2` 六个分片；缺项遵循官方 `VersManager` 的 `1210` 默认值。六个分片必须全部下载、解压并通过配置类、动作类、朝向和分片契约转换，随后才原子安装完整快照。规则只精确响应 `GET aola.100bt.com/play/fightassets/bitmap/pet{source}/pet{source}_{face}_{part}~{version}.swf`；任一失败时整条规则不激活并继续使用官方资源。

背包依靠 `newpetpackage.aolaMorphRefresh` 主动重建显示对象，因而可热刷新。战斗模型第一版不修改 `petfightnew.swf`：状态桥成功返回 `active=false` 且 `ended=false` 时保存可切换；战斗中保存只暂存已验证快照，轮询现有只读战斗桥，等官方结束流程销毁控制器并由 `GCManager.disposeSpecialResource()` 清空 `PET_VIEW_DOMAIN` 后再切换，供下一场重新加载。桥不可用或无法确认清理时保留旧规则，重启后恢复新设置。

## 信任、缓存与失败边界

- 注入进程持有敏感登录材料；Contracts、宿主 UI、日志、导出和文档均不可信任这些材料。
- OfflineClient 的本地 `accounts.json` 含明文密码并被 Git 忽略；审计日志不得包含账号、密码、SID、登录帧或完整发送参数。可信脚本是普通 Python，不是沙箱。
- 远程资源、CEF 缓存项和修改候选都不是可信 SWF；须验证来源、头、长度、压缩、类契约和大小上限。
- CEF 内存/磁盘缓存、Flash Loader 与 ApplicationDomain 分层处理；验证方式取决于发生变化的缓存层。
- 规则关闭、未命中、探测失败或候选无效时保持/恢复官方资源。冲突必须确定性处理，不能依赖注册时机。
- 设置按 Section 原子保存；损坏 Section 回退模块默认值，未知 Section/字段尽量保留，旧文件不可因保存失败而损坏。

## 验证状态

ContractVersion 1 边界、资源管线、PacketHost、Section 设置、功能协调器、CompositionRoot、目录/命名空间和兼容路径清理均已完成。原连接主动发送替换已通过 Release 构建、自测、SWF 静态复读和 PCAP 基线；战斗状态桥已完成真实加载、战斗识别和 turn 0/1/2 逐回合发送复测。2026-08-29 启动桥记录含用户操作反馈、单连接采样和后续 TCP 元数据观察；2026-09-04 纯状态桥复测只保留用户观察，未保留连接数量快照或新的序列抓包。证据只覆盖各自候选，当前 Version 4 演出候选和当前战斗附着仍需独立验收。

OfflineClient 已有单元、C# 黄金向量、假 WSS/TCP 和调度测试；2026-09-05 本地复跑 33 项中 32 项通过，参考源码哈希检查失败，当前不能称全部测试通过。尚未进行真实账号登录。首轮实机验收必须单账号 TCP 收到 `logOK`，并只在用户提供低风险查询后验证匹配响应。含 SID 的 PCAP 只能保存在本地忽略的 `analysis/AolaOfflineClient/evidence/`。

模块状态见 [`modules/`](modules/)，跨模块理由见 [`decisions/`](decisions/)，历史最终证据位于本地 `task/update/restruct-stage9-validation-20260823.md`（当前被 Git 忽略，公开检出不保证存在）。静态验证、构建、PCAP/主动发送和真实 Flash 运行仍是不同层级；后续变更必须按受影响层级重新验证。
