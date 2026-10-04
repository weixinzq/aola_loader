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

导出仍使用按 `id`、`param`、`cmd` 顺序包含三个字段的 `#send={"id":42,"param":{},"cmd":"CMD"}|`。导入/编辑支持任意字段顺序、多行 JSON、BOM、空段、整行 `//` 注释、末尾省略 `|`，字符串中的 `|` 不分段；错误包含行号。支持 `#wait|` 与 `#time = 2.5|`，解析本身不发送。`param` 必须是 JSON 对象；用户提供的 `:ext_seq;` 在宿主与 Flash 两层移除。

数值扩展 ID 只按实时捕获的 `socketclient~2026073064044545.swf` 中 `mmo.framework.comm.ExtMap` 映射。证据原件 SHA-256 为 `9951ad202058c551d05bcb1e1dbc68250129c9e35db93d4083ae9068596eb0d7`。缺失的 51、80、88..98 等 ID 必须拒绝，不能猜测或按默认扩展发送。

## 结果语义

- `SubmittedToFlash`：Flash API 同步接受；不是服务器成功。
- `ServerSucceeded`：仅当 Flash 在提交调用返回前同步提供明确成功回调时成立；普通发送流程不等待该状态。
- `ServerRejected`：仅当 Flash 在提交调用返回前同步提供明确拒绝回调时成立。
- `TimedOut`：提交给 Flash 本身超时，不能确认是否进入 Flash API。
- `SubmissionFailed`：页面、启动桥、参数或扩展映射在提交前失败。

## 统一文本序列（2026-10-03）

生产 UI 使用 AolaTextSequenceRunner，旧模式复选框已移除。整份文本先解析、检查扩展映射和战斗参数，再开始提交；任何解析或预检查错误都不会部分发送。本地步骤以 Send / WaitBattleEnd / Delay 区分，不进入 Hook 待发队列。id=18 与 55_1/55_2/55_9 会话维护消息由 Flash 所有，拒绝重放。

编辑框全部步骤为一组，组数默认 1、组间休息默认 1000ms。相邻实际文本提交至少间隔 200ms，入口确认、#wait、#time 已耗费的时间计入间隔；不重复叠加。组间休息从末次提交/本地步骤完成后开始，定义下一组的间隔，不额外叠加 200ms；最后一组后不休息。失败或提交超时立即停止，不重试。

- 新入口 15/54_22 要求此前状态明确为 idle；提交后沿用 2303/2304/2401 身份与 Flash 首次 inputReady 确认。后续不逐条等待 2405、不改写输入 turn。preFightLoad 只检查并跳过，由 Flash 自行发送。
- #wait 在明确 idle 时立即继续，否则等待匹配本场 battleUniqueId 的 2403；旧结束包忽略。不自动提交 1404，不设置固定战斗时长。要开始下一场，须自然结束，或显式 1404 后 #wait。
- #time = 秒数 只暂停文本序列，抓包与 Flash 原自动战斗继续。秒数有限且非负，支持小数。
- AolaCompositionRoot 长期持有 AolaExecutionState，按 ProcessId / SocketHandle / ConnectionPlayerId 绑定接收连接，保存战斗 ID、唯一 ID、回合和 idle/entering/active/ending/unknown。它不替代展示用 BattleSnapshot。状态变化信号唤醒等待，不另开接收循环。连接切换、关闭、捕获失效或战斗身份异常停止后续步骤；观察代际号防止状态恢复后旧任务继续。
- 停止或关闭发包窗口只取消文本序列，已开启的 Flash 自动战斗保持运行；用 1409/useAiType=0 或游戏按钮关闭。

### 原游戏自动战斗

13/1409 的 useAiType=0/1 只走 battle.auto -> aolaBattleSetAuto -> DocPetFight.setNativeAutoBattle，不再通过 activeSend.submit 重复提交。原自动按钮也调用此共享设置方法：修改 isAutoUseSkill，调用 PetClient.autoUseAI；关闭时保留原关闭事件和 changeAutoUseSkillState(false)，重置原技能策略并刷新按钮。相同状态不额外点击/发包；无活动战斗或原游戏禁止切换时拒绝。

技能与替补继续由 FightPanel.autoUseSkill / handleAutoSwitchPM 及原 PetClient 负责。宿主不生成第二份 1401/1403，不承诺 Python AutoBattle 的技能/替补选择策略。桥结果仍只表示 SubmittedToFlash。Bridge Version 5 的七字段 battle.state 契约保持不变，新增独立 battle.auto 操作。

### 历史模式记录（生产 UI 不再使用）

以下描述与实机记录属于旧 BattleSequenceRunner/validator 模式。原契约检查保留作入口回归用途；旧 UI 的模式选择、严格回合分组及 1409 拒绝规则不适用于上面的统一文本执行路径。

启用“确认战斗入口后发送”时，校验器先完整检查整份输入，并以首次出现的
`id=15/cmd=54_22` 或已验证回合命令 `id=13/cmd=1401..1407/1410` 作为战斗边界。边界前的其他严格
`#send` 记录是普通前缀，由当前 `IAolaCommandSender` 按文本原序各提交一次；任何前缀提交失败都会在读取或进入战斗前停止，且不重试。纯前缀输入拒绝，`1408/1409` 无论位置都拒绝，战斗边界后的未知命令会使整份计划在任何发送发生前校验失败。

校验器根据战斗部分的消息形状选择两种模式：

- 新战斗模式接受可选且只出现一次、位于战斗入口前且 `eventId` 为正整数的
  `id=42/cmd=74_1`，唯一的 `id=15/cmd=54_22`，紧随入口但由 Flash 自行负责的
  `id=16/cmd=preFightLoad`，以及已验证的 `id=13` 回合命令 `1401..1407/1410`；`1408/1409` 自动战斗开关明确拒绝。入口提交后
  必须同时观察到新的 `2303/2304/2401` 身份和 `petfightnew` 的可操作状态。
- 当前战斗附着模式的战斗部分只接受已验证的 `id=13` 回合命令，不要求或发送 `54_22`；它可以带有边界前的普通前缀。runner 在前缀成功提交后读取实时桥，要求
  `active=true`、`ended=false` 和非零 `battleId`，固定当前路由 ID；若 `inputReady=false`，最多等待现有 45 秒回合超时，确认后按输入参数直接提交，不再要求后续消息
  `turn` 与实时 `turn` 完全一致。

新战斗模式中，`petfightnew` 返回的 `battleId` 必须与 `2401.br`（允许为负数的有符号 32 位路由 ID）一致；
`2401.battleUniqueId` 必须是本次新观察到的正整数，但不得拿它与 `battleId` 比较。
`preFightLoad` 是 Flash 自行发送的 Flash-owned 消息；它只允许位于 `54_22` 后、首个回合组前，导入记录中的该行只作结构校验并在等待新战斗身份前跳过，不能作为当前战斗附着依据。
两种模式的每条回合命令都必须含严格类型和非负 `turn`。连续且 `turn` 相同的命令组成一个回合组，组间 `turn` 必须严格加一；同一 `turn` 在后续再次出现或跳号仍会在发送前拒绝。回合组只维护输入顺序，不等同于 Flash 操作批。入口/首次附着确认后，runner 按原顺序逐条调用 `IAolaCommandSender.SendAsync`，相邻实际提交之间在上一条提交返回后等待 200ms，包括普通前缀、入口和跨 turn 组的提交；跳过的 Flash-owned 消息不增加等待。入口确认自身的等待时间另外计算，最后一条提交返回后不额外休息。后续不等待发送抓包、`2405`、`2411..2417/2420`、新 `readyEpoch` 或 `inputReady`，不按实时 `turn` 改写原参数。每条回合命令提交前只读取一次页面桥，检查战斗仍活动、未结束且 `battleId` 未变化；桥失败或部分提交失败立即停止，已提交消息不重试。逐条发送签名匹配与队列外手动操作检测不再参与该模式。
初始化或首次附着等待超时、桥失败、战斗 ID 变化、战斗结束、提交失败或取消时停止，不自动重发。新战斗入口继续要求 `2303/2304/2401` 与 Flash 首个可操作状态；现有战斗的首次附着继续等待初始输入窗口，后续不再等待窗口。

2026-09-01 的真实 Flash 复测确认：修正 `FightData.battleId=2401.br` 后，选中的 `74_1 -> 54_22 -> preFightLoad -> turn 0/1/2` 序列能够进入战斗并执行三个回合操作。该结论只覆盖状态识别与调度，不把 `SubmittedToFlash` 提升为服务器成功，也不替代无新增连接、无重复登录和后续正常序列完整性的独立验收。

2026-09-02 的实机抓包进一步修正了上述节奏判断：同一次 Flash 操作可能产生多条请求，服务器会对每条分别返回当前玩家的 `2405`，但只在整批请求齐备后返回 `2411/2413` 等执行结果；批内请求还可能跨相邻的导入 turn。旧实现对每条都等待新 `readyEpoch`，会在 turn 1 第一条后死等。当时实现改为“逐条 `2405` 确认 + 结果包判定批次边界”，并已覆盖无确认、同批同 turn、同批跨 turn 和批后新窗口的契约测试。2026-09-04 纯状态候选获得新进程战斗与所列回合操作的用户确认，但没有保留新的消息抓包，不能据此确认所有同批/跨 turn 边界均经服务器验收。 该逐条确认策略已于 2026-09-29 按用户要求替换为入口确认后固定 200ms 提交；以上实机记录属于历史策略证据，不能作为新策略的运行验收。

当前战斗附着路径已由 BattleReplay contract self-test 覆盖；尚未在真实账号中执行“已进入战斗后仅提交 id=13”的实机复测。该复测需单独确认没有补发 `54_22`/`preFightLoad`、目标技能只提交一次且后续正常战斗消息仍有效。

普通发送 UI 不轮询、不等待接收结果，也不弹出模态结果框。点击发送时解析并固定编辑器中的全部消息作为一组，按原顺序逐条提交，相邻消息之间在上一条提交返回后等待 200ms。“发送组数”默认 1，“组间休息（毫秒）”默认 1000，休息从一组最后一条提交返回后开始，结束后发送下一组，不再叠加组内的 200ms；最后一组之后不额外等待。发送期间禁用发送按钮、模式和次数/间隔设置，提供“停止”按钮；停止或关闭窗口会取消等待并停止后续提交，已经提交给 Flash 的消息无法撤回。全部组执行结束后恢复控件，不自动重试失败的单次提交；普通发送仍按输入顺序继续后续项，选择多组代表用户明确要求重复整份输入。

勾选“确认战斗入口后发送”时，组数和组间休息设置禁用且不参与执行，runner 只执行一份入口确认计划，确认后按固定 200ms 间隔提交，不逐条等待服务器确认。两者不能混为一条完成语义。`SubmittedToFlash` 绝不显示为服务器成功。`ActClientSender.sendMessage(extension:String, cmd:String, params:Object, callback:Function, isNeedLock:Boolean=true):void` 的当前指令证据表明：先为 `cmd` 注册监听，再调用 `SocketClient.instance.sendXtMessage`；只有服务器回调才有资格产生服务器终态。

## SWF 承载与失败关闭

桥位于精确版本的启动资源 `start~2107300001.swf` 的独立 FWS 副本中，只替换 `mmo.checkversion.Load`，并保留版本检查、`loader.swf` 下载及 `ApplicationDomain.currentDomain` 同域 `loadBytes` 启动链。启动桥使用字符串名称和 `hasDefinition/getDefinition` 动态解析 `ActClientSender` 与 `Panel_Helper`，不得硬 import 未加载类。背包 `newpetpackage~2026082731219998.swf` 只保留形态变化桥，不再承担发包、面板或播放设置。不得修改 `play.swf` 或覆盖官方 SWF 原件；2026-10-04 明确增加 `controlv2~2026082731219998.swf` 的独立主题热切换候选，仅允许主题桥及对象监听生命周期修改，详见 `THEME_SPEC.md`。启动桥新增独立的 `aolaThemeApply` 动态调用入口，不经主动发包路径、不提交主题设置命令。主动发送桥仍只暴露白名单扩展名、32 位请求 ID、受界命令和 JSON 对象；不回传响应正文。

启动桥不可用、版本变化、ExternalInterface 不可用或模板校验失败时，发送失败关闭，不回退到 IPC sidecar。旧 Hook 队列即使收到请求也只返回拒绝结果。

## 本地面板调用

抓包/发包窗口默认尺寸为 1280×900。顶部导航和底部状态栏使用紧凑的固定高度，发包页压缩标题、设置及操作区域的占用，消息编辑框随剩余空间伸展；窗口仍可手动调整尺寸及最大化。

Packets UI 使用“抓包 / 发包 / 打开映射面板”三个独立页面。“抓包”页只显示能够导出为严格 `#send` 的发送消息，逐条提供复选框；“选中内容加入发包”只向发包编辑器追加，不自动切页。“发包”页允许直接编辑、清空和从 UTF-8 文件导入。“打开映射面板”页接受用户输入的资源 URL/资源键字符串和 CLS 类名字符串，经 `panel.open -> aolaOpenPanel -> Panel_Helper.loadResAndShow` 调用 Flash 自身面板加载器。该操作不属于 `#send`，不发送自制协议帧，也不改变 `#send` 的导出格式。

URL/资源键与 CLS 作为普通字符串传递，不解释为 JavaScript 或 ActionScript 代码；两项均限制为 1..2048 字符。同步结果 `PanelOpenRequested` 只表示 Flash 已开始面板加载，不表示资源下载、类解析或最终渲染成功。面板自身后续发包继续由 Flash 原连接负责。

## 本次验证

2026-10-03：新增文本序列针对性契约检查，覆盖解析、200ms 与暂停计时、分组、完整预检查零提交、失败停止、自然结束/旧包过滤、断开/捕获失效、取消、多场入口及 1409 单次桥路由。自动桥候选完成 FFDec 重编译与静态复读；真实 Flash 加载、出手、替补及服务器执行尚未验收。

2026-09-29：宿主及 Verify 的 Release 构建通过，`AolaSocketHack.Verify --battle-replay-contract` 通过。针对性契约检查覆盖入口身份/首个窗口确认、无发送抓包和 `2405`/执行结果且实时 turn/epoch 不变时仍按 200ms 提交、保留输入 turn、初次附着、提交失败不重试、桥失败、战斗结束/ID 变化与取消。尚未执行新策略的真实 Flash/服务器验收。

## 完成标准

Release 构建、ActiveSend self-test、PCAP replay 与 SWF 静态复读通过后，还必须用真实 Flash 验证：无新增游戏连接、无重复登录、查询命令由原连接发送并收到响应、状态命令只执行一次、后续正常游戏消息序列未损坏。最后一层未完成前不得标记真实发送已验收。
