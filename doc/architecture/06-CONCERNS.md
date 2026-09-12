# 架构关注点

## 优先级说明

- **高**：修改时容易跨进程、跨协议或破坏生产安全边界。
- **中**：明显增加维护/测试成本，短期仍可控。
- **低**：设计异味或残留面，当前已有保护。

本页记录风险，不代表本轮已修改或已通过运行验证。

## 1. 主窗体承担过多运行时编排（高）

`AolaMainForm` 直接持有 Chromium 控件、BrowserSession、HookController、packet source、logger、Battle tracker、多个 coordinator 和两个 timer；它还负责 WMI 进程发现、注入轮询、frame-load JavaScript、feature 状态回推和窗口菜单。

影响：页面加载、UI 生命周期、Hook 时序和 feature 恢复互相靠近，新增功能容易继续堆进主窗体。当前缓解是 CompositionRoot 集中构造、已有 coordinator 和 BrowserHost contracts。维护时优先扩展已有 coordinator/service，再让 MainForm 只触发动作和显示结果。

## 2. 资源请求处理器是多功能汇合点（高）

`AolaResourceRequestHandler` 构造七条规则，同时实现 `IThemeSelectionTarget`、`IPetMorphRuleTarget`、`IBattleMorphRuleTarget`，还负责远端 probe/fetch、catalog 和 SWF capture session。

影响：Theme、PetMorph、Battle 的改变都可能触碰同一类；路径所有权或优先级错误会跨功能影响资源。当前 pipeline 冲突即放行、规则接口和 reserved priority 能降低风险。新增资源功能必须先证明路径互斥，不能只按注册顺序“抢请求”。

## 3. 页面桥是字符串与版本耦合（高）

C# operation、内嵌 JavaScript、ExternalInterface 方法名、patched SWF 回值以及 manifest `bridgeVersion` 共同构成跨语言契约。编译器不能检查它们的一致性。

当前 Battle bridge version 为 5，manifest 对候选和 SymbolClass 有哈希约束，Verify 也有源码/契约守卫。风险仍集中在版本升级：任何一侧遗漏都会表现为 `BridgeNotInstalled`、pending 或 invalid result，而不是编译失败。

## 4. 验证项目直接链接生产源码（中）

`AolaSocketHack.Verify.csproj` 用大量 `<Compile Include="..\AolaLoader\..." Link="...">` 编译宿主源文件，而不是引用一个可复用的宿主核心程序集。

影响：

- 新依赖要手动补入 Verify 项目，容易出现“生产能编译、Verify 不能”或相反。
- Verify 编译的是选择性源码集合，不完全等于 AolaLoader 的真实装配。
- 物理移动文件会大范围修改测试工程。

这与 ADR-0001 的“先用单项目逻辑边界”一致，是已知取舍。只有当链接清单维护成本持续增长时，才考虑抽取无 UI 核心库；不要为单次功能提前拆程序集。

## 5. 遗留旁路发送面仍存在（中）

Contracts 仍包含 pending send queue；CaptureEngine 仍能返回登录帧 send context；`AolaSidecarSender` 仍在源码中。生产 `MainClass` 明确拒绝队列请求，ActiveSend 也不引用这些类型。

影响：阅读者可能误判存在两条可用发送链；未来改动可能误接遗留路径。维护文档和源码守卫应持续把它标为“兼容残留、生产禁用”。除非有新的明确架构决策，不得重新启用。

## 6. 静态 IPC 事件是全局状态（中）

`AolaHookHostService` 使用静态 events 和静态 pending send list。`AolaHookHostAdapter` 把事件扩散限制在单点，但 Contracts 本身仍是全局可变状态。

影响：重复宿主、测试隔离、订阅泄漏和异常消费者都需要额外小心。源码守卫和 adapter Dispose 是当前保护；新增消费者必须依赖 `IAolaPacketEventSource`。

## 7. 两套战斗状态容易被混用（高）

PacketHost 生成 `AolaBattleSnapshot`；patched SWF 生成 `BattleBridgeState`。前者描述服务器消息聚合，后者描述 Flash 输入窗口。它们共享“battle/state”词汇但语义不同。

影响：用 packet 到达替代 inputReady，或用 Flash battleId 替代 battleUniqueId，会破坏序列调度。新代码的变量和文档应显式使用 `packet snapshot`、`Flash bridge state`、`route id`、`unique id`，避免泛称“战斗状态”。

## 8. 运行资源与代码必须锁步（高）

start bridge、petfight bridge、newpetpackage 模板、catalog 和 BattleAssistant 资源都作为 Content 复制。资源规则可能依赖精确 URL、类名长度、候选长度和哈希。

影响：只替换 SWF、不更新 manifest/常量/验证器，或者只更新代码、不带资源，都会在运行时失败关闭。资源更新必须使用现有脚本/runbook，并保留官方基线和候选证据。

## 9. 异步回调与吞异常降低可观测性（中）

主窗体 timer、FrameLoadEnd 和资源 handler 包含 `async void`；部分 UI 恢复和事件分发会捕获并忽略异常。它们位于框架回调边界，形式上合理，但故障可能只体现为状态未更新或静默放行。

维护时不要把更多业务步骤塞进这些回调。可复用逻辑返回 `Task<Result>`，回调只调用、呈现和记录结果。

## 10. BrowserSession 的超时分类需要补生产路径验证（中）

静态阅读显示 `ExecuteScriptAsync` 用 `Task.WhenAny(evaluation, Task.Delay(timeout, linkedToken))`；delay 自然完成时，分支依据 `timeoutSource.IsCancellationRequested` 选择 Timeout/Cancelled，但该 source 没有在 timeout 时被取消。由此推断，自然超时可能被标为 Cancelled。现有 ActiveSend timeout verifier 使用手工 page bridge 结果，未覆盖真实 CefSharp evaluation 挂起路径。

这是静态推断，不是本轮运行复现。修改前应先增加生产 adapter 级可控验证或最小复现，再决定是否修正。

## 11. 生命周期所有权有重复释放路径（低）

`AolaMainForm.OnFormClosed` 与 `AolaCompositionRoot.Dispose` 都释放 `ChildWindowCoordinator`。当前 coordinator 的 Dispose 幂等，因此不会重复关闭造成明显错误，但所有权表达不唯一。

新增资源时应只让 CompositionRoot 拥有长期 service 的最终释放，Form 只停止自身 timer/退订自身事件；若整理此处，应作为独立、可验证的小任务。

## 12. 运行时未知项

- PPAPI Flash 在当前 CEF 版本下的精确进程归属和重启行为。
- 官网登录/选服页面的当前真实流程。
- 所有 feature resource rule 在当前 CDN 版本下的命中率。
- Bridge v5 在当前完整发布目录中的真实加载和长时稳定性。
- Lineup 新增代码在当前未提交工作区的完整构建与实机服务器响应。

这些未知项不应由静态架构文档替代验收。

