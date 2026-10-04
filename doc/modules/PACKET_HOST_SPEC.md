# PacketHost

Status: Implemented
ContractVersion: 1  
OwnerPaths: `analysis/AolaLoader/PacketHost/**`

## 职责

在宿主进程单点适配静态 IPC 服务，向消费者发布包和 Hook 状态；保留兼容发送 DTO 的隔离边界，但不承担生产主动发送。

## 非职责

不解析协议、不保存登录材料、不决定 UI 过滤或日志格式、不保证 UI 线程，也不建立旁路账号连接。生产主动发送属于 `Features/ActiveSend` 与 BrowserHost PageBridge；Packets UI 的本地面板打开操作同样走 PageBridge，不经过 PacketHost 或兼容发送队列。

## 公开契约

`IAolaPacketEventSource` 继续提供 `PacketReceived`、`StatusReceived` 以及兼容的 `SendCompleted`/`QueueSend`；事件参数使用 `AolaSocketHack.Contracts` DTO。`AolaHookHostAdapter` 是唯一静态事件订阅者。Packets UI 不再调用兼容发送入口。

## 输入与输出

2026-10-03：AolaHookStatus 增加可序列化的可选 ExecutionEvent / SocketHandle。ConnectionClosed 表示已观察游戏 socket 关闭；CaptureInvalid 表示队列丢失、TCP 缓冲/帧失效或 Hook 失效。通知沿原 Report -> StatusReceived 分发，不传 SID 或登录帧。执行消费者据此使观察代际失效；Hook 回调仍只入队，不阻塞执行 IPC。

输入为 remoting 发布；输出为隔离分发的 DTO 事件。遗留队列请求会在注入端明确拒绝，不创建 socket、不复制登录帧。

## 允许依赖

`AolaSocketHack.Contracts` 与最小生命周期/诊断抽象。

## 禁止依赖

WinForms、CefSharp、Settings、战斗解析器、日志实现和敏感注入端状态。

## 线程与生命周期

事件可在任意后台线程发生。逐个调用订阅者并隔离异常；Dispose 原子退订静态事件，之后不再分发。

## 异常及回退语义

单个消费者异常不阻断其他消费者；遗留队列请求明确返回“旁路发包已禁用”，不静默发送或回退。

## 设置所有权

无。

## 安全约束

契约不提供登录帧、SID、账号密码或注入端敏感缓存。保持当前登录脱敏。

## 缓存语义

适配器不缓存包历史；消费者 `AolaReceiveLogger` 默认不序列化或缓存完整收发日志。调用 `TryRetain` 后创建文件并从该时刻起持续写入；开始保留或持续写入失败期间使用最多 8 MiB 的 UTF-8 JSONL 有界缓存，超限丢弃最早记录并计数。保留失败恢复过渡缓存并返回错误；兼容 IPC 队列仅用于接收并拒绝遗留请求，不是生产发送通路。

## 验证入口

`AolaSocketHack.Verify --self-test` 验证事件转发、异常隔离、Dispose 后静默、结构化发送，ReceiveLogger 的精确收发方向过滤、启用前不记录、显式保留、UTF-8 无 BOM、双向解密参数/原始帧记录、登录发送二次脱敏和释放后停止写入；SystemMessage 契约验证 `type=0` 的 `action/headerRoomId`、`joinOK` 动态房间及未知 payload 保留。Battle tracker 仍只消费接收方向，PacketsForm 仍使用精确“发送”方向可见性策略。Packets UI 源码守卫还要求抓包表只加入 `CanExport` 且能生成严格 `#send` 的消息，保留复选追加、清空和文件导入入口，并拒绝恢复 Inner 明文详情控件。源码守卫要求三个静态事件只允许出现在 `AolaHookHostAdapter`；PCAP 回放继续验证严格导出格式和主动发送。UI marshal 保留现有 `InvokeRequired/BeginInvoke` 路径，并在真实窗口验证时复核。

## 完成标准

logger、Battle tracker、PacketsForm 和主窗状态全部迁移；除适配器/IPC 初始化外无静态事件引用；PCAP 与主动发送基线通过。

## 已知限制

四类消费者均使用共享 `IAolaPacketEventSource`；只有 `AolaHookHostAdapter` 直接订阅静态 IPC 事件，并由 CompositionRoot 统一创建/释放。兼容类名 `AolaReceiveLogger` 与文件名 `aola-recv-*.jsonl` 保持不变，点击“保留日志”后文件内容覆盖精确的“发送/接收”方向；发送表格仍位于 `UI/Packets` 且保持 send-only。阶段 8 审计确认适配器是必需的唯一 IPC 边界。原连接发送迁移后，send-only 表格、日志和战斗消费仍走本边界；主动发送改走 PageBridge。构建、自测与 PCAP 基线通过，真实原连接发送验收单独记录。
