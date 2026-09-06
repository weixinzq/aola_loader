# ActiveSend

Status: Implemented; 2026-08-29 original-connection bridge has runtime evidence; later battle replay/presentation changes have separate acceptance boundaries

ContractVersion: 1  
OwnerPaths: `analysis/AolaLoader/Features/ActiveSend/**`, `analysis/AolaLoader/UI/Packets/**`

## 目标与数据流

```text
AolaPacketsForm
  -> IAolaCommandSender
  -> IPageBridge
  -> controlled JavaScript
  -> ExternalInterface aolaSendCommand
  -> ActClientSender.sendMessage
  -> SocketClient.instance.sendXtMessage
  -> Flash 当前游戏连接
```

不得建立第二条账号连接，不得复制或重放登录帧，不得向原 socket 插入自制密文。Flash 始终拥有 OuterSeq、InnerSeq、加密状态和正常消息排序。

## 输入契约

只接受按 `id`、`param`、`cmd` 顺序包含三个字段的 `#send={"id":42,"param":{},"cmd":"CMD"}|`。`param` 必须是 JSON 对象；用户提供的 `:ext_seq;` 在宿主与 Flash 两层移除。

数值扩展 ID 只按实时捕获的 `socketclient~2026073064044545.swf` 中 `mmo.framework.comm.ExtMap` 映射。证据原件 SHA-256 为 `9951ad202058c551d05bcb1e1dbc68250129c9e35db93d4083ae9068596eb0d7`。缺失的 51、80、88..98 等 ID 必须拒绝，不能猜测或按默认扩展发送。

## 结果语义

- `SubmittedToFlash`：Flash API 同步接受；不是服务器成功。
- `ServerSucceeded`：仅当 Flash 在提交调用返回前同步提供明确成功回调时成立；普通发送流程不等待该状态。
- `ServerRejected`：仅当 Flash 在提交调用返回前同步提供明确拒绝回调时成立。
- `TimedOut`：提交给 Flash 本身超时，不能确认是否进入 Flash API。
- `SubmissionFailed`：页面、启动桥、参数或扩展映射在提交前失败。

## 战斗状态回放

启用“按战斗状态逐条发送”时，校验器先完整检查整份输入，并以首次出现的
`id=15/cmd=54_22` 或已验证回合命令 `id=13/cmd=1401..1407/1410` 作为战斗边界。边界前的其他严格
`#send` 记录是普通前缀，由当前 `IAolaCommandSender` 按文本原序各提交一次；任何前缀提交失败都会在读取或进入战斗前停止，且不重试。纯前缀输入拒绝，`1408/1409` 无论位置都拒绝，战斗边界后的未知命令会使整份计划在任何发送发生前校验失败。

校验器根据战斗部分的消息形状选择两种模式：

- 新战斗模式接受可选且只出现一次、位于战斗入口前且 `eventId` 为正整数的
  `id=42/cmd=74_1`，唯一的 `id=15/cmd=54_22`，紧随入口但由 Flash 自行负责的
  `id=16/cmd=preFightLoad`，以及已验证的 `id=13` 回合命令 `1401..1407/1410`；`1408/1409` 自动战斗开关明确拒绝。入口提交后
  必须同时观察到新的 `2303/2304/2401` 身份和 `petfightnew` 的可操作状态。
- 当前战斗附着模式的战斗部分只接受已验证的 `id=13` 回合命令，不要求或发送 `54_22`；它可以带有边界前的普通前缀。runner 在前缀成功提交后读取实时桥，要求
  `active=true`、`ended=false` 和非零 `battleId`，固定当前路由 ID；若 `inputReady=false`，最多等待现有 45 秒回合超时，随后要求消息
  `turn` 与实时 `turn` 完全一致。

新战斗模式中，`petfightnew` 返回的 `battleId` 必须与 `2401.br`（允许为负数的有符号 32 位路由 ID）一致；
`2401.battleUniqueId` 必须是本次新观察到的正整数，但不得拿它与 `battleId` 比较。
`preFightLoad` 是 Flash 自行发送的 Flash-owned 消息；它只允许位于 `54_22` 后、首个回合组前，导入记录中的该行只作结构校验并在等待新战斗身份前跳过，不能作为当前战斗附着依据。
两种模式的每条回合命令都必须含严格类型和非负 `turn`。连续且 `turn` 相同的命令组成一个回合组，组间 `turn` 必须严格加一；同一 `turn` 在后续再次出现或跳号会在发送前拒绝。回合组只维护输入顺序，不等同于 Flash 操作批。runner 每次只登记并提交当前一条，随后必须观察该条发送抓包和属于当前玩家的 `2405`（`reqId == abs(battleId)`）。若随后观察到同样属于当前玩家的对应 `2411..2417/2420` 执行结果或新的 `readyEpoch`，说明当前操作批已经结束，下一条必须等待同一 `battleId` 的新操作窗口并重新严格校验实时 `turn`。若确认后 1 秒内两者都未出现，则服务器仍在等待同一次 Flash 操作产生的后续请求，runner 才继续提交下一条；该操作批可以跨输入中的相邻 turn 组。如果此时已经没有下一条输入，runner 会报告计划可能缺少同批后续消息，而不会把仅有 `2405` 误报为整批完成。部分提交失败、确认/窗口等待超时、fresh-window turn 不匹配、签名不符或额外回合操作都会立即停止，已提交消息不重试。
初始化或附着/回合等待超时、桥失败、战斗 ID/回合不匹配、战斗结束，或检测到队列外的手动操作时立即停止，不自动重发。

2026-09-01 的真实 Flash 复测确认：修正 `FightData.battleId=2401.br` 后，选中的 `74_1 -> 54_22 -> preFightLoad -> turn 0/1/2` 序列能够进入战斗并执行三个回合操作。该结论只覆盖状态识别与调度，不把 `SubmittedToFlash` 提升为服务器成功，也不替代无新增连接、无重复登录和后续正常序列完整性的独立验收。

2026-09-02 的实机抓包进一步修正了上述节奏判断：同一次 Flash 操作可能产生多条请求，服务器会对每条分别返回当前玩家的 `2405`，但只在整批请求齐备后返回 `2411/2413` 等执行结果；批内请求还可能跨相邻的导入 turn。旧实现对每条都等待新 `readyEpoch`，会在 turn 1 第一条后死等。当前实现改为“逐条 `2405` 确认 + 结果包判定批次边界”，并已覆盖无确认、同批同 turn、同批跨 turn 和批后新窗口的契约测试。2026-09-04 纯状态候选获得新进程战斗与所列回合操作的用户确认，但没有保留新的消息抓包，不能据此确认所有同批/跨 turn 边界均经服务器验收。

当前战斗附着路径已由 BattleReplay contract self-test 覆盖；尚未在真实账号中执行“已进入战斗后仅提交 id=13”的实机复测。该复测需单独确认没有补发 `54_22`/`preFightLoad`、目标技能只提交一次且后续正常战斗消息仍有效。

普通发送 UI 在取得 `SubmittedToFlash` 后立即恢复，不轮询、不等待接收结果，也不弹出模态结果框。按战斗状态发送的 runner 则按上节继续等待匹配抓包、服务器确认和状态窗口；两者不能混为一条完成语义。`SubmittedToFlash` 绝不显示为服务器成功。`ActClientSender.sendMessage(extension:String, cmd:String, params:Object, callback:Function, isNeedLock:Boolean=true):void` 的当前指令证据表明：先为 `cmd` 注册监听，再调用 `SocketClient.instance.sendXtMessage`；只有服务器回调才有资格产生服务器终态。

## SWF 承载与失败关闭

桥位于精确版本的启动资源 `start~2107300001.swf` 的独立 FWS 副本中，只替换 `mmo.checkversion.Load`，并保留版本检查、`loader.swf` 下载及 `ApplicationDomain.currentDomain` 同域 `loadBytes` 启动链。启动桥使用字符串名称和 `hasDefinition/getDefinition` 动态解析 `ActClientSender` 与 `Panel_Helper`，不得硬 import 未加载类。背包 `newpetpackage~2026082731219998.swf` 只保留形态变化桥，不再承担发包、面板或播放设置。不得修改 `play.swf`、`controlv2.swf`，也不得覆盖官方 SWF 原件。桥只暴露白名单扩展名、32 位请求 ID、受界命令和 JSON 对象；不回传响应正文。

启动桥不可用、版本变化、ExternalInterface 不可用或模板校验失败时，发送失败关闭，不回退到 IPC sidecar。旧 Hook 队列即使收到请求也只返回拒绝结果。

## 本地面板调用

Packets UI 使用“抓包 / 发包 / 打开映射面板”三个独立页面。“抓包”页只显示能够导出为严格 `#send` 的发送消息，逐条提供复选框；“选中内容加入发包”只向发包编辑器追加，不自动切页。“发包”页允许直接编辑、清空和从 UTF-8 文件导入。“打开映射面板”页接受用户输入的资源 URL/资源键字符串和 CLS 类名字符串，经 `panel.open -> aolaOpenPanel -> Panel_Helper.loadResAndShow` 调用 Flash 自身面板加载器。该操作不属于 `#send`，不发送自制协议帧，也不改变 `#send` 的严格格式。

URL/资源键与 CLS 作为普通字符串传递，不解释为 JavaScript 或 ActionScript 代码；两项均限制为 1..2048 字符。同步结果 `PanelOpenRequested` 只表示 Flash 已开始面板加载，不表示资源下载、类解析或最终渲染成功。面板自身后续发包继续由 Flash 原连接负责。

## 完成标准

Release 构建、ActiveSend self-test、PCAP replay 与 SWF 静态复读通过后，还必须用真实 Flash 验证：无新增游戏连接、无重复登录、查询命令由原连接发送并收到响应、状态命令只执行一次、后续正常游戏消息序列未损坏。最后一层未完成前不得标记真实发送已验收。
