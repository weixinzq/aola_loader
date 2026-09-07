# 文档核对记录

核对日期：2026-09-05（Asia/Shanghai）。依据是当前包含未提交改动的工作区，不代表已提交版本或远端官方最新资源；本次未联网检测版本、登录账号、发送游戏命令或重新进行 Flash 实机验收。仅修改说明文档，保留原有代码、设置、资源与历史证据。

## 范围与阅读顺序

README 和 PROJECT_CONTEXT 是入口；architecture、modules 与 runbooks 描述当前实现；ADR 保留架构决定并使用当前契约名。doc/task 是当前待办；doc/task2 是已标注的历史设计，其旧字段和步骤不再作为实施指令。task/update 是按日期保留的历史记录，不以旧侧路发送、UI 或固定抓包路径描述当前版本。

已核对 README、PROJECT_CONTEXT、doc 下原有全部 20 份文档、OfflineClient/runtime README 及 data 下两份数据说明。工具暂存技能、反编译导出和验证器自动报告不属于现行项目说明，不批量重写；本次读取的历史验收记录保持原文。

## 关键核对依据

| 文档/主题 | 当前代码或本地证据 | 结论 |
| --- | --- | --- |
| ActiveSend、Protocol/IPC、NetworkCapture | MainClass.RejectLegacySendRequest；AolaPageBridge；FlashCommandSender | 生产复用 Flash 原连接；sidecar 源码仍在但生产入口不实例化，遗留队列返回拒绝 |
| README、AppShell、PacketHost | AolaPacketsForm；AolaMainForm.BuildToolbar；AolaReceiveLogger.TryRetain/BufferLine | 抓包页只显示严格 #send 且按需打开；完整日志手动启用，过渡/故障缓存上限 8 MiB |
| ResourceInterception、ADR-0002 | ResourceRulePipeline；各叶资源规则 Priority | 契约为 IResourceInterceptionRule、RewriteRemote；按优先级降序，同级多命中透传 |
| Battle、Settings、task2 | BattleSettingsCodec.CurrentVersion；BattleBridgeClient；BattlePresentationCoordinator | 设置 Version 6，桥 Version 4；模型切换须 active=false 且 ended=false |
| 周更与回滚 | Update-PetFightBattleBridge.ps1；PetFightBattleBridgeArtifact | 当前候选包括演出补丁；所有模式检查本地依赖；旧 Version 3 与当前宿主不兼容 |
| BrowserHost、Theme、PetMorph、ADR-0001/0003/0004 | 公开契约、协调器、Section 存储与 CompositionRoot | 保持既有模块/生命周期边界；主题即时刷新未实施 |
| OfflineClient | client.py、scripting.py、pyproject.toml、tests | Python 3.12+，单接收循环，先订阅再发送；测试有一项失败，未真实登录 |
| runtime README | 本地 DLL 哈希、长度和 Authenticode | 哈希与既有说明一致，签名状态仍为 HashMismatch |
| data 说明 | organized-data/manifest.json、CSV；SWF manifest 与 sources | 保留各自生成日期的静态快照，不宣称服务器当前版本 |

资源优先级实值：Start 1000、Battle bridge 850、Theme 800、Pet package 699、PetMovie 698、BattlePetMovie 与 Poster 697。请求上下文接受 HTTP/HTTPS，Battle 规则检查 GET、host/path 和版本；清单自身 officialUrl 必须为 HTTPS，不能写成请求层已经强制 HTTPS-only。

## 生产候选与实机证据

当前清单：`analysis/AolaLoader/Resources/Patches/petfightnew-battle-state.current.json`。

- resourceVersion：2026090340574444；bridgeVersion：4。
- candidateLength：6556017；本地候选 SHA-256 与清单一致：`59da8c23f2eb228185cf4df2483d43a73ad29e374f9786ac190d4e28c56ace81`。
- 2026-09-04 实机记录对应此前纯状态候选 SHA-256：`1d98f95c7f9a36f8bae41098cc0ef856d975cc3a1a9a294aef44d3abbb55bc32`，不能拿来验收当前演出候选。
- 当前演出、战斗模型完整动作、当前战斗附着仍需独立真实验收。SubmittedToFlash 和 BattleOptionsApplied 各自只证明提交/应用接口结果，不证明服务器执行或视觉正确。

已读取本地历史证据：`analysis/reverse-engineering/start-bridge-20260829/README.md` 和 `analysis/reverse-engineering/battle-bridge-20260904-2026090340574444/evidence/runtime-validation-20260904.md`。前者有连接采样与用户操作反馈，后者明确缺少连接数量快照和新的消息序列日志；这些文件不保证出现在公开检出中。

## 本次验证结果

- `dotnet build .\\AolaLoader.sln -c Release --no-restore -m:1`：通过，0 错误，保留两项 CefSharp NU1903 警告；首次受输出文件权限限制，提升权限后通过。
- `AolaSocketHack.Verify --self-test`：16 项全部 PASS。
- OfflineClient `python -B -m unittest discover -s tests -v`：33 项，32 通过、1 失败。失败为 `test_vector_sources_still_match_csharp_reference`，原因是向量记录的 AolaProtocol.cs 哈希与当前源码不一致，需审查源码差异后重新生成/核对向量；本次未更改向量或源码。
- 未执行 PCAP 回放：当前工作区没有旧私有 PCAP；历史 exportable=164 只适用于那份固定抓包，不能要求任意抓包都相同。
- 未执行周更 Check/Prepare/Promote 或实机操作；本次仅检查本地脚本、清单、候选长度/哈希和文档路径。
- 27 份现行/配套说明的本地 Markdown 链接检查无缺失；git diff --check 通过。
- organized-data 的 13 张 CSV 均与 manifest 行数一致，均带 UTF-8 BOM；SWF 清单两份来源 XML 的 SHA-256 与历史记录一致。未复跑远程 HEAD 探测。

## 已知分发与证据限制

`analysis/tools/petfight/New-PetFightPresentationPatches.ps1` 本机存在，但当前 Git 忽略规则排除了它；周更三个模式都在入口检查该依赖，公开检出缺文件时会失败。当前宿主仅接受 Version 4，单独恢复旧 Version 3 文件会透传官方资源；恢复旧状态桥需配套旧宿主。

旧 `analysis/loader` 已不在工作区；`task/update/restruct-stage9-validation-20260823.md` 本地存在但被 Git 忽略。现行入口不再依赖这些路径提供可直接执行的默认验证命令。数据快照目录也被 Git 忽略，不属于保证发布的资产。上述分发问题仅记录，未修改 .gitignore 或发布内容。
