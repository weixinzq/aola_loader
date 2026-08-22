# PacketHost

Status: Implemented, runtime pending
ContractVersion: 1  
OwnerPaths: `analysis/AolaLoader/PacketHost/**`

## 职责

在宿主进程单点适配静态 IPC 服务，向消费者发布包、状态和发送结果，并提供结构化有界发送入口。

## 非职责

不解析协议、不保存登录材料、不决定 UI 过滤或日志格式、不保证 UI 线程。

## 公开契约

`IAolaPacketEventSource` 提供 `PacketReceived`、`StatusReceived`、`SendCompleted` 与 `QueueSend(AolaSendRequest)`；事件参数继续使用 `AolaSocketHack.Contracts` DTO。`AolaHookHostAdapter` 是唯一静态事件订阅者。

## 输入与输出

输入为 remoting 发布和结构化发送请求；输出为隔离分发的 DTO 事件、request id 或明确的队列错误。

## 允许依赖

`AolaSocketHack.Contracts` 与最小生命周期/诊断抽象。

## 禁止依赖

WinForms、CefSharp、Settings、战斗解析器、日志实现和敏感注入端状态。

## 线程与生命周期

事件可在任意后台线程发生。逐个调用订阅者并隔离异常；Dispose 原子退订静态事件，之后不再分发。

## 异常及回退语义

单个消费者异常不阻断其他消费者；队列满、请求非法或已释放返回明确失败，不静默丢弃主动发送。

## 设置所有权

无。

## 安全约束

契约不提供登录帧、SID、账号密码或注入端敏感缓存。保持当前登录脱敏。

## 缓存语义

不缓存包历史；发送排队仍由有界 IPC 队列拥有。

## 验证入口

`AolaSocketHack.Verify --self-test` 验证事件转发、异常隔离、Dispose 后静默、结构化发送，ReceiveLogger 的仅接收过滤、UTF-8 无 BOM、解密参数/原始帧记录和释放后停止写入，Battle tracker 的接收方向过滤、快照发布和释放后停止消费，以及 PacketsForm 使用的精确“发送”方向可见性策略。源码守卫要求三个静态事件只允许出现在 `AolaHookHostAdapter`；PCAP 回放继续验证严格导出格式和主动发送。UI marshal 保留现有 `InvokeRequired/BeginInvoke` 路径，并在真实窗口验证时复核。

## 完成标准

logger、Battle tracker、PacketsForm 和主窗状态全部迁移；除适配器/IPC 初始化外无静态事件引用；PCAP 与主动发送基线通过。

## 已知限制

阶段 4 已完成四类消费者迁移：`AolaReceiveLogger`、`AolaBattleStateTracker`、`AolaPacketsForm` 和主窗状态均使用共享 `IAolaPacketEventSource`；只有 `AolaHookHostAdapter` 直接订阅静态 IPC 事件。构建、自测、源码守卫和 PCAP/主动发送基线已通过。尚未启动真实 WinForms/Flash 会话验证后台状态更新、窗口关闭和重新打开，因此标记为 `Implemented, runtime pending`；适配器的最终创建位置仍将在 CompositionRoot 阶段收口。
