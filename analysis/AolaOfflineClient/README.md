# AolaOfflineClient

`AolaOfflineClient` 是独立的 Python 3.12+ 脱机登录 SDK 与命令行工具。它使用账号密码向当前 HTTPS 登录接口认证，按配置选择区服，建立自己的 WSS/TCP 游戏连接，并提供结构化 `send`、订阅式 `recv` 和可信本地 Python 脚本入口。

它与 AolaLoader 的 ActiveSend 是两条互不替代的路径：ActiveSend 使用已经登录的 Flash 原连接；本项目会创建新的账号会话，不读取、不捕获、不重放 AolaLoader 的 SID 或登录帧，也不会在 ActiveSend 失败时作为回退。同一账号同时登录官方客户端或 AolaLoader 可能互相顶号。

## 安装

在本目录运行：

```powershell
py -3.12 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -e .
Copy-Item .\accounts.example.json .\accounts.json
```

编辑本地 `accounts.json`，为每个账号明确填写 `label`、`account`、`password` 和 `zone_index`。该文件包含明文密码并已被 Git 忽略；任何能读取磁盘或当前用户目录的程序都可能获取它。不要把它复制到仓库、日志、截图或问题报告中。

首版不支持验证码、风控挑战、外部 SID 或凭据获取。遇到这些响应会直接失败。

## CLI

先做离线配置校验；这一步不连接网络：

```powershell
aola-offline --config .\accounts.json check-config
```

发送一条严格 Loader 记录：

```powershell
aola-offline --config .\accounts.json --transport tcp send `
  --accounts 测试账号 `
  --message '#send={"id":42,"param":{},"cmd":"用户确认过的低风险查询"}|'
```

也可以使用 UTF-8 文本文件，文件内可连续放置多条 `#send={...}|`。字段必须严格按 `id`、`param`、`cmd` 排列；用户传入的 `:ext_seq;` 会被丢弃并由当前会话重新生成。命令输出的 `submitted` 只表示字节已经提交给当前连接，不表示服务器执行成功，也不会在写入结果不明确时自动重发。

```powershell
aola-offline --config .\accounts.json send --accounts 测试账号 --file .\messages.txt
```

持续接收，或只打印匹配命令：

```powershell
aola-offline --config .\accounts.json recv --accounts 测试账号
aola-offline --config .\accounts.json recv --accounts 测试账号 --command-filter queryOK
```

运行 `scripts/` 中的可信脚本：

```powershell
aola-offline --config .\accounts.json run example_receive --accounts 测试账号
aola-offline --config .\accounts.json run my_script --accounts all
```

`run` 会在建立连接前一次性展示脚本名称、说明、账号标签和区服并要求确认，运行中不逐条确认。确认前只用 AST 读取静态脚本元数据，不会导入或执行脚本顶层代码；确认后只导入所选脚本。最多五个账号并行，每账号只执行一个脚本任务；某个账号失败不会停止其他账号。按 Ctrl+C 会取消任务并关闭已建立的连接。

脚本是普通、完全可信的 Python 代码，不是安全沙箱。只运行你审阅过的本地脚本。

## SDK

先订阅，再发送，才能保证快速返回的响应不会落在订阅建立之前：

```python
import asyncio

from aola_offline import AccountProfile, AolaClient


async def main():
    profile = AccountProfile(
        label="测试账号",
        account="本地账号",
        password="本地密码",
        zone_index=1025,
    )
    client = await AolaClient.connect(profile, transport_mode="tcp")
    async with client:
        async with client.recv(
            lambda message: message.command == "queryOK"
        ) as subscription:
            receipt = await client.send(42, "低风险查询", {})
            response = await subscription.next(timeout=10)
            print(receipt.outer_sequence, response.payload)


asyncio.run(main())
```

公开类型：

- `AccountProfile`：本地账号标签、账号、密码与明确的区服索引。
- `AolaClient.connect()`：认证、建立连接并在收到 `logOK` 后返回。
- `send()`：按扩展 ID 串行生成 InnerSeq/OuterSeq 并写入；返回 `SendReceipt`。
- `recv()`：调用时立即建立订阅；支持 `next(timeout)` 和异步迭代。
- `ReceivedMessage`：接收时间、类型、命令、扩展 ID 与已解码 payload。
- `close()`：取消唯一接收循环，通知订阅者断线并清理会话引用。

订阅队列默认上限 256。匹配消息来不及消费时会抛出 `SubscriptionOverflow`，不会静默丢弃。每个账号只有一个底层读取循环和一个发送锁。

默认 `--transport auto` 先尝试验证 TLS 的 WSS；仅当登录帧尚未发送时才允许退回 TCP。登录帧一旦可能提交，连接失败或超时都不会自动切换传输，以免重复会话。

## 脚本接口

脚本必须位于 `scripts/` 顶层，并提供：

```python
SCRIPT_NAME = "示例任务"
SCRIPT_DESCRIPTION = "先订阅、发送一条已确认的查询，再等待明确响应。"


async def run(context):
    async with context.recv(
        lambda message: message.command == "queryOK"
    ) as subscription:
        await context.send(42, "低风险查询", {})
        response = await subscription.next(timeout=10)
        context.log(f"received cmd={response.command}")
```

`context` 只公开 `label`、`send`、`recv`、`cancelled` 和脱敏日志入口。业务初始化、进服务器、动态房间和复杂消息流程都由具体脚本负责；SDK 只把收到 `logOK` 视为 ready。

## 测试与验证状态

```powershell
$env:PYTHONPATH='src'
python -B -m unittest discover -s tests -v
```

测试覆盖认证响应、区服选择、AS3 运算、AMF3、加解密、登录/EXT 黄金向量、分片/粘包、订阅、发送串行化、断线、多账号隔离、脚本与确认流程。固定向量记录了当前 C# 参考实现的 SHA-256，参考源码变化时必须重新审查并生成向量。

2026-09-05 本地复跑 33 项：32 项通过，`test_vector_sources_still_match_csharp_reference` 失败。向量记录的 `AolaProtocol.cs` SHA-256 为 `997dc24d22b9e7a68ac5b008d1f828eb54201b13b53ecfe0112f017d6693cb97`，当前参考源码为 `193a453ed7fdb86aeb830346231e7168045ec958e5d8a109c60727287efa74d1`。这证明参考源码已变动，不能单凭该失败推定协议算法错误，也不能直接改哈希绕过检查；应审查差异并重新生成/核对黄金向量。本次未修改源码或向量。

当前验证仍限于静态、夹具和假传输，不能称测试全部通过；尚未使用真实账号登录。真实验收必须先用一个测试账号通过 TCP 收到 `logOK`；只有用户提供并确认低风险查询后，才能以匹配服务器响应验收发送。含 SID 的原始抓包只能放入已忽略的 `evidence/`，不得提交、导出或写入文档。
