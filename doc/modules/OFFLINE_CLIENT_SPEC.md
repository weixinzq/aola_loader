# OfflineClient 模块规格（历史）

> 状态：`analysis/AolaOfflineClient/` 已不在 2026-09-11 当前工作区，本页仅保留移除前的设计与验证边界，不属于当前可构建、可运行或已验证的执行面。

## 目的与边界

移除前的 `analysis/AolaOfflineClient/` 是 Python 3.12+ 的独立登录 SDK+CLI。它自行用账号密码认证并建立 WSS/TCP 会话，不依赖 AolaLoader、AolaSocketHack IPC 或已删除的 `analysis/loader`，也不作为 ActiveSend 失败后的回退。

ActiveSend 属于 AolaLoader 进程内路径，必须让已登录的 Flash 原连接继续拥有序号、加密与发送顺序；OfflineClient 则明确创建另一个账号会话并自行维护协议状态。OfflineClient 不读取、复用或重放捕获的 SID/登录帧。同一账号不得同时运行官方客户端和 OfflineClient。

## 公开契约

- `AccountProfile(label, account, password, zone_index)`：`zone_index` 必填。
- `AolaClient.connect(profile)`：认证、选区、连接并等待 `logOK`。
- `send(extension_id, command, params, room_id=-1)`：校验对象、替换 `:ext_seq;`、在发送锁内生成序号并写入。
- `recv(predicate=None, max_queue=256)`：立即注册订阅；匹配消息入队，满队列以 `SubscriptionOverflow` 终止订阅。
- `MessageSubscription.next(timeout)` / 异步迭代：消费唯一接收循环路由的消息。
- `close()`：取消读取、关闭传输并向所有订阅发布终止错误。

`SendReceipt` 仅证明本地写入完成。没有匹配的服务端响应时，不得描述为服务器已执行。

## 连接与状态规则

1. HTTPS 认证只接受正常账号密码成功响应；验证码、风控和外部 SID 失败关闭。
2. `auto` 在登录发送前尝试 WSS/TLS，连接建立失败才尝试 TCP。
3. 登录帧一旦可能写入，不切换传输、不自动重试。
4. 收到 `logOK` 才进入 ready；进服、初始化和动态房间由脚本处理。
5. 每账号一个底层读取循环、一个发送锁、一个脚本任务；任何结果不明的写入都会关闭该连接。
6. 帧体、策略响应与消息文件都有明确上限；协议帧体上限为 16 MiB。

## 凭据、日志与证据

本地 `accounts.json` 保存明文密码并由项目 `.gitignore` 排除；仓库只保留示例文件。账号、密码、SID、登录帧和完整发送参数不进入审计 JSONL。SDK 数据模型的凭据字段不会出现在默认 `repr`。

真实 TCP PCAP 必须保存在项目内已忽略的 `evidence/`，不得提交。首轮真实测试只允许一个测试账号；无用户确认的低风险查询时，只验收到 `logOK` 和收包，不能宣称发送已验收。

## 脚本调度

`scripts/*.py` 是可信本地 Python，不提供沙箱。脚本静态声明 `SCRIPT_NAME`、`SCRIPT_DESCRIPTION` 和 `async def run(context)`。CLI 确认前只用 AST 读取元数据，确认后才导入所选脚本；`run` 前只确认一次。最多五账号并行，账号内发送严格串行，失败按账号隔离，取消时关闭所有已连接客户端。

## 验证层级

- 单元/黄金向量：认证解析、AS3、AMF3、加密、序号、登录和 EXT 字段一致性。
- 假传输：WSS/TCP 分片粘包、WSS 前置回退、单读取循环、订阅和断线语义。
- 调度：五账号上限、失败隔离、脚本发现、一次确认和取消关闭。
- 真实运行：单账号 TCP `logOK`、先订阅后低风险查询、明确响应、后续收包和正常断开。

2026-09-05 本地复跑 33 项中 32 项通过；`test_vector_sources_still_match_csharp_reference` 因 `AolaProtocol.cs` 哈希与黄金向量元数据不同而失败。须先审查参考源码变化并重新生成/核对向量，不能只改哈希让测试通过。当前前三层不能标为全通过；即使通过也不能替代真实账号服务器验收。
