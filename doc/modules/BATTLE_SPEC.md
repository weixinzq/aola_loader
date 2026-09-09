# Battle

Status: State/UI implemented; presentation/model replacement implemented with real Flash acceptance pending
ContractVersion: 1  
OwnerPaths: `analysis/AolaLoader/Features/Battle/**`, `analysis/AolaLoader/UI/Battle/**`

## 职责

State 子模块消费接收包、解析 roster/增量并发布防御性快照；UI 仅展示已确认的敌方亚比，支持单人 PVP/PVE。内部仍保留识别己方所需资料。Presentation 保存战斗表现设置，通过页面桥向精确版本的 `petfightnew` 注册选项并读取只读战斗状态，供设置窗口和战斗状态回放使用。开启跳过战斗演出后，已收到的战斗事件仍按官方队列顺序结算并写入“完整信息”，但不再在相邻队列项之间固定等待一帧；多段伤害结束回调保留一帧最小延迟。Diagnostics 在收到 2401/结束包时自动记录开局和结束，在战斗中、预加载仍进行中及结束后至少 120 秒内每 5 秒读取 Flash 内存、显示列表、资源生命周期和帧间隔统计，分别写入 `logs/performance/aola-battle-flash-*.csv` 与 `aola-battle-resource-*.jsonl`；只读采样，不新增 GC。`FightPanel`、`StartMovie`、战斗 `ApplicationDomain` 和预加载会话均使用弱键跟踪；容量 512 的环形事件队列记录资源开始/完成及不短于 50 ms 的长帧，满载时覆盖最旧事件并只增加累计丢弃计数，读取后清空。`Analyze-BattleResourceTrace.ps1` 可关联资源耗时、100 ms 长帧、采样内存变化和可选的 SWF 捕捉日志。

## 非职责

State 不依赖 WinForms/CefSharp，不过滤网络捕获，不修改协议消息；Presentation 不改变 State 包处理契约；头像不决定 roster 正确性。

## 公开契约

`IBattleStateSource` 提供 `CurrentSnapshot`、`SnapshotChanged` 和生命周期释放；快照包含战斗生命周期、双方、全部宠物、最终六维、HP 和技能 PP/CD。`BattlePresentationCoordinator` 保存并推送当前设置，并协调战斗模型六分片预检、延迟切换和启动恢复；当前诊断测试构建中，`BattleBridgeClient` 通过 `aolaBattleApplyOptions` 提交 Bridge Version 5 参数，通过 `aolaBattleGetState` 读取 `active`、`battleId`、`turn`、`inputReady`、`readyEpoch` 和 `ended`。

## 输入与输出

State 输入为 PacketHost 的接收方向 DTO，输出为防御性战斗快照和摘要。Presentation 输入为 Battle Settings Version 6，输出为保存/提交结果、模型切换状态及严格校验后的只读 Bridge Version 5 状态；不得改写协议参数或直接发包。模型切换需桥成功返回 `active=false` 且 `ended=false`；只收到战斗结束包或 `ended=true` 还不满足切换条件。只有 Flash 返回 `BattleOptionsApplied|revision` 才能显示表现设置已应用。

## 允许依赖

State 可依赖 PacketHost 契约和 Contracts DTO；UI 可依赖 State 与头像 provider；Presentation 可依赖 ResourceInterception 契约。

## 禁止依赖

State 禁止 WinForms、CefSharp、Settings JSON 和 Theme/PetMorph 实现；UI 不直接订阅静态 IPC；Presentation 不依赖协议 parser 内部状态。

## 线程与生命周期

PacketHost 事件可在后台线程；State 在锁内更新、锁外发布快照。UI marshal 到 WinForms 线程。Dispose 后退订且不再通知。

## 异常及回退语义

未知/畸形包忽略并保留最后有效快照；解析失败不清空 roster。窗口晚开读取缓存；头像失败使用占位图，不影响数据。

## 设置所有权

独占 `battle` Section，Version 6。当前字段为 `HideDamageNumbers`、`HideHealingNumbers`、`SkipBattlePresentation`、`BattleMorphEnabled` 和强类型 `MorphRules[{Note,SourceViewId,TargetViewId}]`；不得修改 Theme/PetMorph DTO。读取 Version 4 时，原 `SkipAttackAnimation=true` 单向迁移为 `SkipBattlePresentation=true`。旧版模型规则只保留可识别字段，无法识别的规则被忽略并报告，模型总开关保持关闭。

## 安全约束

只消费已脱敏 DTO；不展示登录信息或加密原始扩展。接收包不得进入发送表格。

## 缓存语义

`2303` 重置 roster；同一初始化阶段（最后消息为 `2303/2304`）且参与者匹配的 roster 可跨 `2401`，不再因超过 10 秒丢失已确认身份；按 UQI 后按槽位合并；结束命令标记结束并保留末次资料供查看。快照需防御性复制。

单人初始化中，己方身份来自当前捕获连接的 `ConnectionPlayerId`，与参与者真实 `pmmId` 比对。`2303` 可能一次包含双方，也可能只包含己方并由 `2304` 补齐对手；不按消息顺序、数组顺序或玩家编号正负推断身份。`2303/2304/2401` 的单人阵容按连接身份归属，`2411` 保留已确认归属。`br` 和 `battleId` 只是战斗路由编号。连接身份缺失时保持等待，不把未知参与者当敌方。敌方保留完整背包首次出现顺序，换宠只更新原记录及场上槽位。

2026-09-06 修正了“双方同在 2303 且没有 2304”时助手空白的问题。连接玩家编号由捕获端已有的每 socket 解析状态附加到接收 DTO，不读取或公开 SID；历史日志缺少该字段时，离线回放必须明确提供经用户确认的己方编号，不能将其硬编码进生产逻辑。更新捕获 DLL 后需完整退出并重新启动登录，使新注入代码生效。

`Loadout` 按 `equipment / soul-card / soul-artifact / crystal-key` 分类。装备 `eqp[].eq` 的第一个值为实例编号、第二个值为配置编号；`pmSView.pcp` XML 的 `soc` 为 `槽位等级:魂卡编号`（`#` 分隔），`tt` 为 `实例编号;魂器编号;词条编号:等级`（位置用 `|`、词条用 `#` 分隔），`ctk` 为 `_` 分隔的晶钥编号。所有配置保持位置和顺序。字典缺项表示本包未提供，合并时保留旧值；明确空字段为空配置；格式错误标记无法解析。不会把静态可选词条当作实际持有词条。

## 敌方双视图

顶部仅显示战斗状态、敌方数量和“属性 / 配置”切换，默认属性。未确认敌方资料时显示等待状态。属性页为单排横向卡片，保留名称、HP、等级、性格、六维及技能 PP/CD；不显示昵称、槽位、任何 ID 或协议调试字段。配置页按同一阵容顺序纵向排列，每只亚比一行，四类配置只显示图片，名称和已知详情通过悬停查看。浅灰背景、白色圆角卡片和蓝色选中态仅用于本窗口。页面整体滚动，刷新保留当前页及滚动位置。

头像按基础种族 `RaceId` 读取；图片和目录由独立工具准备到 `Resources/BattleAssistant`。运行时异步读取图片，不下载或执行 SWF 转换，关闭窗口释放图片和事件订阅。缺图使用中性占位，并按类别及编号记录到 `%LOCALAPPDATA%/AolaLoader/battle-assets-missing.txt`。工具及来源维护见 [图片准备说明](../runbooks/BATTLE_ASSISTANT_ASSETS.md)。

## 验证入口

资源事件分析使用 `analysis/tools/Analyze-BattleResourceTrace.ps1 -PerformanceCsv <aola-battle-flash.csv> -TraceJsonl <aola-battle-resource.jsonl>`。若同时传入外部进程采样文件 `-ProcessPerformanceCsv <aola-*.csv>`，脚本只关联其中 `Role=ppapi-flash` 且前后进程编号一致的样本，额外输出资源完成前后的 PPAPI 专用内存变化；不传入时该值为空。`-SwfCaptureLog` 只用于独立的冷/热缓存采集，不应在正式帧率对比组启用。

`BattleState contract self-test` 验证初始值、读取值、发布值和逐订阅者通知均为防御性深复制，覆盖全部场下宠物、最终六维、PP/CD、订阅者异常隔离、晚开读取缓存与 Dispose；同时用手动 PacketHost 验证生产 Tracker 只处理接收方向、发布结束快照并在释放后停止消费。`ActiveSend` 与 `BattleReplay` contract self-test 覆盖严格桥参数、负数 `battleId`、`br`/`battleUniqueId` 分离、`readyEpoch` 和停止条件。资源规则自测还覆盖当前战斗桥清单，以及战斗模型的精确 URL、版本目录显式值/默认 `1210`、双方朝向、六个真实 6000→6047 分片、损坏 SWF 和混合类名。2303/2304 完整 roster、2401 保留、后续更新、UQI/槽位合并和结束命令仍由现有 Tracker/解析回归覆盖。

## 完成标准

2026-09-06 本地回归：原 16 条样本的一场战斗、新 10 条样本的三场战斗均保持敌方六只；连接编号传递、连接清理后不复用身份、缺省配置保留及畸形配置状态检查通过。离线回放使用用户确认的历史日志账号，未执行新的真实游戏对战。

State/UI/Presentation 物理边界清晰，Tracker 只依赖 PacketHost，F3 与缓存行为不变，自动解析及真实战斗回归通过。

## 已知限制

ContractVersion 1 已冻结；生产 tracker 实现 `IBattleStateSource` 并只依赖 `IAolaPacketEventSource`，不直接订阅静态 IPC。`battle` Section 使用 `BattleSettings`/`BattleSettingsCodec` Version 6。当前为用户明确恢复的 `DiagnosticOnly` Bridge Version 5 测试构建，只记录生命周期，不包含保守释放补丁；先前实机曾出现首局停在战斗主体创建后的回归，因此仍需从全新进程复测，不得视为生产稳定版。该次日志显示 `StartMovie` 与预加载均已完成、Flash 舞台仍在运行，资源事件读取的页面作用域错误已修正，但不能据此认定首局回归已修复。`ConservativeCleanup` 候选另在预加载正常完成时先摘除成员回调再调用局部副本，并在 dispose 时清空该回调及局部队列，不取消 `ResScheduler` 请求、不清理全局缓存、不强制 GC、不自动重载。官方加载器没有已确认的单战斗域释放接口，且 `FightPanel.dispose` 已执行官方特殊资源清理，因此在弱引用证据证明域滞留前不增加域卸载。诊断桥未安装时 CSV 仍记录战斗边界和 `BridgeAvailable=false`，不会阻止战斗。帧间隔反映 Flash 主事件循环是否停顿，不能单独区分 GC、资源解码、ActionScript 或 GPU 渲染原因。跳过战斗演出只能加速已经到达 Flash 的事件；服务器尚未返回的结果仍必须等待。战斗模型替换只改变本地画面，不改变服务器 `raceId/viewId`、技能、属性或结果；变身、召唤物、奥义和额外特效不在范围内。该模型替换及真实单人 PVP/PVE、常用 DPI 仍需实机验收。
