# Protocol 与 IPC

Status: Implemented
ContractVersion: 1  
OwnerPaths: `analysis/AolaSocketHack/Protocol/**`, `analysis/AolaSocketHack/Hooking/AolaSidecarSender.cs`, `analysis/AolaSocketHack.Contracts/**`, `analysis/AolaSocketHack.Verify/**`

## 职责

解析/编码 Aola 与 AMF3、Inner 明文、严格 Loader 导出和跨进程安全 DTO；保留供兼容入口拒绝遗留请求的受界队列。生产主动发送归 ActiveSend/PageBridge，复用 Flash 原连接。

## 非职责

不控制 UI、资源替换或设置；不把浏览器密文作为主动发送输入；不向宿主公开敏感登录状态。

## 公开契约

Contracts DTO 为 `AolaPacketEvent`、`AolaHookStatus`、`AolaSendRequest`、`AolaSendResult`；remoting 服务发布已脱敏事件、提取结构化请求和报告结果。协议算法保持纯逻辑入口供 verifier 使用。

## 输入与输出

输入为完整 TCP 帧；输出为已脱敏解密 DTO 和严格导出文本。编码器也供 verifier 生成字节并作本地回读，不能把编码测试当作生产发送。遗留 IPC 发送请求由 `MainClass.RejectLegacySendRequest` 明确拒绝。

## 允许依赖

BCL、Contracts；Protocol 不依赖 EasyHook，sidecar 可依赖 socket 与 Protocol。

## 禁止依赖

AolaLoader UI/Settings/CefSharp；账户凭据、SID 和原始登录帧不得出现在 Contracts DTO。

## 线程与生命周期

每连接序列状态隔离；待发队列上限 256。socket 关闭/Dispose 清除登录帧和 SID。IPC 订阅由宿主 PacketHost 单点拥有。

## 异常及回退语义

畸形帧计为解析失败但不得破坏后续帧；非法导出请求拒绝；遗留发送请求返回失败，不创建旁路连接、不回放登录帧。ActiveSend 桥失败时也不回退到该队列。

## 设置所有权

无。

## 安全约束

登录事件必须脱敏；EXT DTO 公开解密参数和 `InnerPlainHex`，不公开加密扩展 `RawHex`，抓包 UI 仅显示严格 `#send`。ActiveSend 在宿主与 Flash 两层删除用户 `:ext_seq;`，由 Flash 生成真实连接序列；编码器仅维护自身测试/调用状态。

## 缓存语义

接收 `AolaPacketEvent` 增加可选 `ConnectionPlayerId`，只携带当前 socket 已识别的公开玩家编号，供战斗归属判断。未捕获身份时为 null；不包含 SID、登录帧或序列密钥。字段采用可选序列化成员兼容缺省 DTO，宿主收发日志保留 `connectionPlayerId` 供离线回放。

捕获解析状态按浏览器 socket 隔离；登录材料仅在注入进程内存中短暂保留并随连接关闭/释放清除，不能进入 IPC 或其他登录路径。遗留 sidecar 状态实现仍在源码中，但生产入口不实例化它。

## 验证入口

协议单元式检查、真实 PCAP、导出格式、登录脱敏、Inner 明文、分片/粘包、主动发送编码/回读。

## 完成标准

PCAP 保持 `exportable=164 failures=0` 及全部布尔基线；依赖方向守卫通过；无敏感数据越界。

## 已知限制

静态 remoting 事件保留在 Contracts 跨进程边界，宿主只由 `AolaHookHostAdapter` 单点订阅。`AolaSidecarSender.cs` 是未接入生产入口的遗留实现，不能因文件仍存在而恢复其登录克隆/独立连接路径。阶段 9 的独立连接发包属于历史架构；当前发送边界及 2026-08-29 原连接验收见 [ActiveSend](ACTIVE_SEND_SPEC.md)。
