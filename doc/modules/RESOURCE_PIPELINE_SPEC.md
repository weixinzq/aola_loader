# ResourceInterception

Status: Implemented
ContractVersion: 1  
OwnerPaths: `analysis/AolaLoader/ResourceInterception/**`

## 职责

把 Cef 请求适配为框架无关上下文，按稳定顺序评估规则，执行本地响应/远程转换、精确探测、受界缓冲、响应转换和官方资源回退。

## 非职责

不拥有 Theme/PetMorph/Battle 业务规则，不读整个设置文档，不操作 Form，不发送服务器状态命令。

## 公开契约

`IResourceInterceptionRule.Evaluate(ResourceRequestContext)` 返回 `PassThrough`、`LocalResponse` 或 `RewriteRemote`；`ResourceRulePipeline` 采用首个非放行计划；`IRemoteResourceProbe`、`IResourceResponseTransformer` 和不可变 plan/result 表达 I/O。规则不可直接修改 Cef 请求或创建 handler。

管线允许的优先级区间为 `1000..1099`、`800..899`、`600..699`，按降序评估；当前实际值为 Start bridge 1000、Battle bridge 850、Theme 800、Pet package 699、PetMovie 698、BattlePetMovie/Poster 697。两条 697 规则拥有不同路径；若同一请求在同优先级多命中，必须诊断并放行。区间外值由构造函数拒绝。

## 输入与输出

输入含规范化 scheme/host/path/query/method/headers 与 rewrite 标记；输出含计划类型、目标、MIME、缓存/回退策略和转换器。

## 允许依赖

Features 的规则注册、纯 SWF 转换器；仅 `ResourceInterception/Cef/**` 可依赖 CefSharp。

## 禁止依赖

WinForms、具体 Form、AolaMainForm、PacketHost、协议解析、可变模块设置对象。

## 线程与生命周期

规则评估无 UI 线程假设且应快速；网络探测异步/后台执行；响应缓冲上限明确，回调始终完成或释放。

## 异常及回退语义

关闭/未命中完全放行。探测失败、非 2xx、长度/压缩/类契约失败均拒绝候选并按计划恢复原 URL；转换异常不把部分字节交给 Flash。

## 设置所有权

无；只消费功能模块提供的不可变规则快照。

## 安全约束

仅精确受控 host/path；防止 rewrite 递归；限制输入/输出；原始 SWF 不覆盖，敏感参数不写日志。

## 缓存语义

探测缓存 key 包含完整资源身份和计划维度；成功/失败 TTL 分离。不得把 CEF、Flash Loader 或 ApplicationDomain 缓存混同。

## 验证入口

`AolaSocketHack.Verify --self-test` 当前验证请求规范化/内部标记、计划不变量和防御性内容、关闭放行、优先级命中、近似 URL、重写/回退递归防护、同优先级冲突放行、规则异常回退、非 2xx、受界输入/输出、转换异常、SWF FWS/CWS/ZWS 头约束、探测 TTL、远程探测/完整抓取/转换执行，以及 Start、Battle、Theme、Pet package、PetMovie、BattlePetMovie、Poster 规则的默认放行、精确 host/path/method、版本锁、类契约和回退计划。BattlePetMovie 另用保留的 6000→6047 双方六分片验证真实 ZWS 解压、配置类、动作类、朝向和分片边界。

## 完成标准

Theme、PetMorph 现有分支全部成为独立规则；入口只做适配/管线执行；默认与替换 Flash 路径实测通过。

## 已知限制

框架无关 `ResourceRulePipeline`、受界响应处理、SWF 头验证、HTTP 探测/抓取、TTL 缓存和 Cef 适配均已实现；Start bridge、Battle bridge、Theme、Pet package、PetMovie、BattlePetMovie 与 Poster 是独立规则。Start bridge 只精确替换 `start~2107300001.swf`，提供 `aolaSendCommand`、`aolaOpenPanel` 与 `aolaSetPlayback`；Pet package 只精确替换当前 `newpetpackage~2026082731219998.swf` 并仅保留形态桥。

BattlePetMovie 使用优先级 697，只匹配 `GET aola.100bt.com/play/fightassets/bitmap/pet{source}/pet{source}_{face}_{part}~{version}.swf`，其中 `face=1/2`、`part=0/1/2` 且目录 ID 与文件 ID 必须相同。`battle-pet-movie-versions.current.json` 固定当前官方 `versiondata` 的版本和 SHA-256，缺项使用官方默认 `1210`。启用前完整抓取目标六分片并运行专用转换器；只有六个全部成功才安装不可变本地响应快照。转换只执行同位数 `Pet{target}Config_{face}`/`pet{target}_{face}_...` 到源 ID 的同长度改写；错误朝向、配置类位于错误分片、混合类名、损坏/超限 SWF 或任一下载失败时整条规则不激活。战斗中修改时保留当前快照，等官方结束清理完成后再原子切换；无法确认时等下次进程启动。

Battle bridge 的每周版本不再编译进 C# 常量。生产规则严格读取 `petfightnew-battle-state.current.json`，清单中的官方 URL 必须为规范 HTTPS URL；请求匹配检查 GET、host、path 和精确版本。上游上下文允许 HTTP/HTTPS，当前规则没有额外的 HTTPS-only 判断；清单 schema、字段集合、规范 URL、稳定文件名、目录边界、FWS 声明长度、16 MiB 上限、候选 SHA-256 或桥标记不符时一律透传。当前清单版本为 `2026090340574444`：官方 ZWS SHA-256 为 `79818d6958934a898e5fa2cc21865f8d5270d5c9634da50328475db9852ff3d7`，生产 FWS SHA-256 为 `59da8c23f2eb228185cf4df2483d43a73ad29e374f9786ac190d4e28c56ace81`，649 项同版本 SymbolClass 的导出哈希为 `38125be72fd95f30f5981b35ebc6781476807d68a93797294b6000908d8586e0`。Bridge Version 4 候选除 `DocPetFight`、`PetFightService.init` 和 `FightPanel.enableClick` 外，只允许修改 16 个列入白名单的方法：`UseSkill` 的三个结算入口、`SwitchPm.showSwitchMc`、`ChangePetView` 的两个终态入口、`BattlePmDying.showPetDieEffect`、`BattleNextTurn.checkPlayMovie`，以及 `SkillResultMovieHandler` 的八个 HP 数字叶方法。不得短路 `SkillResultMovieHandler.startMovie`，也不得修改全局画质/技能特效选项。

`analysis/tools/Update-PetFightBattleBridge.ps1` 将周更拆为 `Check`、`Prepare`、`Promote`：前两者只检测或生成带证据的候选，`Promote` 必须接收明确清单才会更新两个稳定生产文件。`Prepare` 通过 `New-PetFightPresentationPatches.ps1` 动态发现方法体编号和类私有命名空间；方法、锚点、出口或同版本契约变化时失败关闭。完整流程见 [`../runbooks/PETFIGHTNEW_WEEKLY_UPDATE.md`](../runbooks/PETFIGHTNEW_WEEKLY_UPDATE.md)。Start 与 Pet package 模板已完成 2026-08-29 的默认/替换 PPAPI Flash 双路径验证；上一纯状态候选已完成真实战斗识别和 turn 0/1/2 调度。当前演出候选已完成静态验证并晋级生产清单，但尚未完成新的真实 Flash 演出验收；失败时应恢复与宿主契约兼容的已验证候选；没有兼容候选时移除实际运行目录的清单恢复官方透传。当前宿主严格要求 Bridge Version 4，旧 Version 3 文件配当前宿主会因校验不符透传，不能恢复旧桥的状态功能；恢复旧功能需使用与 Version 3 配套的宿主版本。
