# Protocol 与 IPC

Status: Target  
ContractVersion: 1  
OwnerPaths: `analysis/AolaSocketHack/Protocol/**`, `analysis/AolaSocketHack/Hooking/AolaSidecarSender.cs`, `analysis/AolaSocketHack.Contracts/**`, `analysis/AolaSocketHack.Verify/**`

## 职责

解析/编码 Aola 与 AMF3、Inner 明文、严格 Loader 导出、跨进程安全 DTO、受界发送队列和独立连接主动发送。

## 非职责

不控制 UI、资源替换或设置；不把浏览器密文作为主动发送输入；不向宿主公开敏感登录状态。

## 公开契约

Contracts DTO 为 `AolaPacketEvent`、`AolaHookStatus`、`AolaSendRequest`、`AolaSendResult`；remoting 服务发布已脱敏事件、提取结构化请求和报告结果。协议算法保持纯逻辑入口供 verifier 使用。

## 输入与输出

输入为完整 TCP 帧或结构化发送请求；输出为解密 DTO、严格导出文本、独立连接字节与本地回读结果。

## 允许依赖

BCL、Contracts；Protocol 不依赖 EasyHook，sidecar 可依赖 socket 与 Protocol。

## 禁止依赖

AolaLoader UI/Settings/CefSharp；账户凭据、SID 和原始登录帧不得出现在 Contracts DTO。

## 线程与生命周期

每连接序列状态隔离；待发队列上限 256。socket 关闭/Dispose 清除登录帧和 SID。IPC 订阅由宿主 PacketHost 单点拥有。

## 异常及回退语义

畸形帧计为解析失败但不得破坏后续帧；非法导出/发送请求拒绝；主动连接失败返回结构化结果，不回退到浏览器连接。

## 设置所有权

无。

## 安全约束

登录事件必须脱敏；EXT 公开解密参数和 `InnerPlainHex`，不公开加密扩展 `RawHex`；删除用户 `:ext_seq;` 后自行生成序列。

## 缓存语义

浏览器连接和 sidecar 各有独立 OuterSeq/InnerSeq；登录克隆仅在注入进程内存中短期存在。

## 验证入口

协议单元式检查、真实 PCAP、导出格式、登录脱敏、Inner 明文、分片/粘包、主动发送编码/回读。

## 完成标准

PCAP 保持 `exportable=164 failures=0` 及全部布尔基线；依赖方向守卫通过；无敏感数据越界。

## 已知限制

当前静态事件仍位于 Contracts 兼容边界；宿主迁移前保留，不在本阶段改破坏性 IPC 契约。

