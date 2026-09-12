# 维护指南

## 新功能应该放哪里

先判断功能的核心事实来源：

| 功能类型 | 放置位置 | 应依赖的入口 |
| --- | --- | --- |
| 纯 UI 展示 | `UI/<Feature>/` | feature coordinator/state contract |
| 设置和业务编排 | `Features/<Feature>/Coordination`、`Settings` | `ISettingsSectionStore`、窄 adapter |
| 页面/Flash 调用 | feature client + `IPageBridge` | 新增白名单 operation，不能暴露任意 JS |
| CEF 资源替换 | `Features/<Feature>/ResourceInterception` | `IResourceInterceptionRule` |
| packet 派生状态 | feature `State/` | `IAolaPacketEventSource` |
| 跨进程 DTO | `AolaSocketHack.Contracts` | 只放可序列化最小契约 |
| Hook/协议 | `AolaSocketHack` | 不引用宿主模块 |
| 装配 | `AolaCompositionRoot` | 只在这里 new 长期服务 |

只有 UI 入口和状态展示留在 `AolaMainForm`；可复用流程放 coordinator/service。

## 修改战斗模块

### 战斗助手或属性配置

依次检查：

1. `AolaBattlePacketParser` 是否认识目标接收命令和字段。
2. `AolaBattleLoadoutParser` 的 Missing/Empty/Known/Invalid 语义。
3. `AolaBattleStateTracker` 的重置、增量合并和 clone。
4. `AolaBattleAssistantForm` 是否只消费 snapshot。

不要用 Flash bridge state 填充 pet 属性；它没有这类数据。

### 战斗状态驱动发送

依次检查：

1. `BattleSequenceValidator` 的静态计划边界。
2. `BattleSequenceRunner` 的 packet 身份、手动操作检测和等待阶段。
3. `BattleBridgeClient` 的 turn/inputReady/readyEpoch。
4. ActiveSend 的 SubmittedToFlash 语义。

任何重试策略、2405 解释或执行结果边界都需要方向化真实抓包，不得仅凭静态猜测改动。

### 战斗表现或 petfight bridge

同时核对：

- `BattleSettings` / codec / coordinator。
- `AolaPageBridge` 中 `battle.*` schema。
- `PetFightBattleBridgeArtifact.BridgeVersion`。
- `petfightnew-battle-state.current.json` 的版本、长度和哈希。
- 现有更新脚本、Verify 和 [PETFIGHTNEW_WEEKLY_UPDATE.md](../runbooks/PETFIGHTNEW_WEEKLY_UPDATE.md)。

SWF、manifest、C# 常量和 JS schema 必须作为一个版本单元维护。

## 修改 CEF 或页面桥

1. 进程级参数放 `AolaCefInitializer`。
2. 浏览器生命周期/脚本执行适配放 `AolaBrowserSession`。
3. 功能可调用操作放 `AolaPageBridge` 白名单，并严格验证参数和返回 envelope。
4. 页面加载后的 feature 恢复由 coordinator 提供 `PushCurrent`，MainForm 只触发。
5. 区分 PageNotReady、BridgeNotInstalled、Timeout、Cancelled、InvocationFailed。

真实验证至少覆盖导航前、main frame ready、Flash bridge 尚未安装、安装后、刷新和关闭。

## 修改 Hook 或协议

1. Hook 签名和 native 调用放 `WinsockHooks/WinsockNative`。
2. socket 候选判断放 `AolaSocketCaptureFilter`。
3. 粘包/拆包和连接状态放 `FrameBuffer/AolaCaptureEngine`。
4. 报文语义放 `AolaProtocol/Amf3Reader/Writer`。
5. 跨进程字段先更新 Contracts，再更新两端。

必须保持：原函数先正确执行、WSA error 不被破坏、回调只做有界复制/入队、缓冲有上限、登录脱敏、关闭时清零敏感数据。不要在 Hook 路径接回 sidecar 发包。

## 修改资源规则

1. 写清 URL/path ownership 和版本约束。
2. 选择保留优先级，证明与同级规则互斥。
3. 返回标准 plan，不直接耦合 CEF 类型。
4. 对远端资源设置最大长度、probe/cache key、header 和 transformer 验证。
5. 所有失败路径应回到官方请求。
6. 在 `AolaResourceRequestHandler` 注册，并同步模块规格。

优先使用已有 transformer 和 probe/fetch contract，不在 feature rule 内另建一套 HTTP/缓存。

## 修改设置

1. 由 feature 定义自己的 settings model 和 codec。
2. key 使用小写开头的纯字母数字名称。
3. codec 负责 default、migrate、normalize、serialize。
4. 保存必须通过 `ISettingsSectionStore`，不覆盖未知字段或其他 section。
5. 只有旧整文档格式变化时才修改 `LegacySettingsMigrator`。

## 修改阵容模块

先看 [LINEUP_SPEC.md](../modules/LINEUP_SPEC.md)，再保持以下顺序：全部预检 → 变更一项 → 明确响应 → 回读 → 下一项 → 最终全量回读。新增命令必须加入人工操作/突变检测范围，并明确 response command 和成功字段。

阵容恢复不得在战斗中执行，不得并行，不得在 timeout 后自动重发；突变超时后只能报告“可能已生效”，再由用户决定重新读取。

## 文档同步规则

- 行为或字段变化：更新对应 `doc/modules/*_SPEC.md`。
- 跨模块依赖、进程或主链变化：更新本目录 00–08。
- 做出长期取舍：新增 ADR，并加入 `09-ADR/README.md` 索引。
- 资源版本/哈希更新：更新 manifest 和相关 runbook，不把哈希复制到多份总览。
- 实机证据：写入 runbook/evidence，架构文档只记录其能证明的边界。

## 验证梯度

按风险选择最小充分验证：

1. 文档链接与源码符号核对。
2. 对应 Verify 契约/源码守卫。
3. 相关项目构建。
4. 本地 CEF/Flash 运行。
5. 有明确授权和安全边界的真实服务器验证。

报告时分别写明执行了哪一级。构建通过不等于 Hook 已注入，静态 SWF 哈希通过不等于候选已加载，SubmittedToFlash 不等于服务端成功。

