# 架构边界

## 1. 进程边界

宿主与注入 DLL 只通过 `AolaSocketHack.Contracts` 通信。跨边界的数据必须是 DTO，不得把 WinForms、CefSharp、settings store 或 feature 对象传入注入进程。

注入目标由“宿主直接子进程 + `CefSharp.BrowserSubprocess.exe` + 命令行包含 `type=network.mojom`”共同识别。不能把任意同名进程当作目标。

## 2. 凭据与敏感数据边界

- 登录帧可以在注入进程的连接状态中暂存，用于协议身份和遗留兼容代码，但不得通过 `AolaPacketEvent`、日志或 UI 输出原文。
- 连接关闭、空闲清理和引擎释放必须清零登录帧副本。
- `AolaReceiveLogger` 对登录发送再次执行防御性脱敏。
- ActiveSend 不得读取或回放登录帧，不得创建第二登录或第二 socket。

## 3. 生产发送边界

唯一允许的生产链是：

```text
IAolaCommandSender → IPageBridge → JavaScript → ExternalInterface → Flash SocketClient
```

`AolaHookHostService.QueueSend`、`TakeSendRequest`、`AolaCaptureEngine.TryGetSendContext` 和 `AolaSidecarSender` 是残留兼容面，不是生产入口。注入端会将队列请求报告为失败。

“SubmittedToFlash”只证明 Flash 接受了本地调用，不等同于服务端执行成功。需要服务端语义的功能必须再匹配接收包或明确回调。

## 4. PacketHost 边界

- 宿主静态 IPC 事件只能由 `AolaHookHostAdapter` 单点订阅，源码守卫负责阻止扩散。
- feature 只依赖 `IAolaPacketEventSource`。
- 事件线程不固定；UI 自行 marshal，消费者自行退订。
- packet DTO 是事实事件，不是可变全局业务状态。

## 5. 页面桥边界

- 页面桥操作名是白名单，参数需严格校验。
- main frame ready 与 Flash bridge installed 是两种状态。
- Battle bridge version 必须在 C#、JavaScript、SWF 候选和 manifest 间一致；当前为 5。
- 页面导航会使状态变为 not-ready；feature 必须允许重新推送或返回 pending。
- 页面桥不得暴露任意脚本字符串给普通功能/UI。

## 6. 资源所有权边界

每个 `IResourceInterceptionRule` 必须声明唯一名称、保留优先级和 `PathOwnership`。规则只处理自己拥有的 URL 形状。

安全默认值是官方资源：fallback 请求、改写递归、规则异常、冲突、远端不可用、长度/头/变换失败均不应返回未经验证的候选。

资源清单是运行时契约而非说明文件。Battle bridge 当前由 manifest 同时约束官方 URL/哈希、候选文件/长度/哈希、bridgeVersion 和 SymbolClass 哈希。

## 7. 设置所有权边界

- `JsonSettingsSectionStore` 只负责文档容器、迁移和原子写入。
- Theme、PetMorph、Battle 各自 codec 负责自己的 schema、默认值、迁移和 normalize。
- 保存一个 section 时保留该 section 中 codec 未覆盖的字段以及其他 section。
- UI 通过 coordinator 保存，不直接读写完整 `settings.json`。

Lineup 方案是独立用户文件，不属于 `settings.json` section。

## 8. Battle 状态边界

- `AolaBattleSnapshot`：packet 派生的宿主视图，供助手、性能记录和“是否看到活动战斗”门控。
- `BattleBridgeState`：Flash 派生的输入状态，供 turn/inputReady/readyEpoch 调度。
- `battleUniqueId` 与 Flash `battleId` 是不同身份，不得相互比较或替代。
- 发送抓包、`2405` 确认、执行结果和新 `readyEpoch` 是不同阶段，不得合并成一个“成功”。

## 9. 线程与生命周期边界

- Hook 回调只复制和入队；解析在专用 worker。
- 每个连接的收发 buffer 和协议状态锁定在 `ConnectionState` 内。
- `AolaCompositionRoot` 创建长期对象并负责最终释放。
- 子窗口由 `ChildWindowCoordinator` 复用和关闭。
- 临时 packet 订阅（BattleSequenceRunner、LineupSession）必须在 `finally/Dispose` 退订。
- `async void` 只能存在于 UI/CEF 回调边界；内部服务应返回 `Task`。

## 10. 生产、验证与证据边界

| 区域 | 可以做什么 | 不能证明什么 |
| --- | --- | --- |
| 当前 C# / manifest | 证明依赖、分支、常量和失败策略 | 真实 CEF 进程分配、服务端接受、画面效果 |
| `AolaSocketHack.Verify` | 证明测试替身下的契约和源码守卫 | 完整生产二进制与真实网络行为 |
| `analysis/reverse-engineering` | 提供版本特定的逆向证据 | 当前生产候选一定被加载 |
| `evidence/` / runbook | 记录特定时间的实测 | 自动代表当前代码仍通过 |

`analysis/AolaOfflineClient/` 当前不存在。它的历史文档不能作为现有生产发送或登录链的组成部分。

