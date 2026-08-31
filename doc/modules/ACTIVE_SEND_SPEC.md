# ActiveSend

Status: Implemented; real Flash startup, original-connection send and post-send sequence validated 2026-08-29

ContractVersion: 1  
OwnerPaths: `analysis/AolaLoader/Features/ActiveSend/**`, `analysis/AolaLoader/UI/Packets/**`

## 目标与数据流

```text
AolaPacketsForm
  -> IAolaCommandSender
  -> IPageBridge
  -> controlled JavaScript
  -> ExternalInterface aolaSendCommand
  -> ActClientSender.sendMessage
  -> SocketClient.instance.sendXtMessage
  -> Flash 当前游戏连接
```

不得建立第二条账号连接，不得复制或重放登录帧，不得向原 socket 插入自制密文。Flash 始终拥有 OuterSeq、InnerSeq、加密状态和正常消息排序。

## 输入契约

只接受按 `id`、`param`、`cmd` 顺序包含三个字段的 `#send={"id":42,"param":{},"cmd":"CMD"}|`。`param` 必须是 JSON 对象；用户提供的 `:ext_seq;` 在宿主与 Flash 两层移除。

数值扩展 ID 只按实时捕获的 `socketclient~2026073064044545.swf` 中 `mmo.framework.comm.ExtMap` 映射。证据原件 SHA-256 为 `9951ad202058c551d05bcb1e1dbc68250129c9e35db93d4083ae9068596eb0d7`。缺失的 51、80、88..98 等 ID 必须拒绝，不能猜测或按默认扩展发送。

## 结果语义

- `SubmittedToFlash`：Flash API 同步接受；不是服务器成功。
- `ServerSucceeded`：仅当 Flash 在提交调用返回前同步提供明确成功回调时成立；普通发送流程不等待该状态。
- `ServerRejected`：仅当 Flash 在提交调用返回前同步提供明确拒绝回调时成立。
- `TimedOut`：提交给 Flash 本身超时，不能确认是否进入 Flash API。
- `SubmissionFailed`：页面、叶桥、参数或扩展映射在提交前失败。

生产 UI 在取得 `SubmittedToFlash` 后立即恢复，不轮询、不等待接收结果，也不弹出模态结果框。`SubmittedToFlash` 绝不显示为服务器成功。`ActClientSender.sendMessage(extension:String, cmd:String, params:Object, callback:Function, isNeedLock:Boolean=true):void` 的当前指令证据表明：先为 `cmd` 注册监听，再调用 `SocketClient.instance.sendXtMessage`；只有服务器回调才有资格产生服务器终态。

## SWF 承载与失败关闭

桥位于精确版本的启动资源 `start~2107300001.swf` 的独立 FWS 副本中，只替换 `mmo.checkversion.Load`，并保留版本检查、`loader.swf` 下载及 `ApplicationDomain.currentDomain` 同域 `loadBytes` 启动链。启动桥使用字符串名称和 `hasDefinition/getDefinition` 动态解析 `ActClientSender` 与 `Panel_Helper`，不得硬 import 未加载类。背包 `newpetpackage~2026082731219998.swf` 只保留形态变化桥，不再承担发包、面板或播放设置。不得修改 `play.swf`、`controlv2.swf`，也不得覆盖官方 SWF 原件。桥只暴露白名单扩展名、32 位请求 ID、受界命令和 JSON 对象；不回传响应正文。

叶模块未加载、版本变化、ExternalInterface 不可用或模板校验失败时，发送失败关闭，不回退到 IPC sidecar。旧 Hook 队列即使收到请求也只返回拒绝结果。

## 本地面板调用

Packets UI 使用“抓包 / 发包 / 打开映射面板”三个独立页面。“抓包”页只显示能够导出为严格 `#send` 的发送消息，逐条提供复选框；“选中内容加入发包”只向发包编辑器追加，不自动切页。“发包”页允许直接编辑、清空和从 UTF-8 文件导入。“打开映射面板”页接受用户输入的资源 URL/资源键字符串和 CLS 类名字符串，经 `panel.open -> aolaOpenPanel -> Panel_Helper.loadResAndShow` 调用 Flash 自身面板加载器。该操作不属于 `#send`，不发送自制协议帧，也不改变 `#send` 的严格格式。

URL/资源键与 CLS 作为普通字符串传递，不解释为 JavaScript 或 ActionScript 代码；两项均限制为 1..2048 字符。同步结果 `PanelOpenRequested` 只表示 Flash 已开始面板加载，不表示资源下载、类解析或最终渲染成功。面板自身后续发包继续由 Flash 原连接负责。

## 完成标准

Release 构建、ActiveSend self-test、PCAP replay 与 SWF 静态复读通过后，还必须用真实 Flash 验证：无新增游戏连接、无重复登录、查询命令由原连接发送并收到响应、状态命令只执行一次、后续正常游戏消息序列未损坏。最后一层未完成前不得标记真实发送已验收。
