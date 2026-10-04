# Aola Loader 项目上下文

## 目的与非目标

Aola Loader 是受控站点上的旧版奥拉星 Flash 桌面宿主，提供登录、发送包查看/导出、通过当前 Flash 游戏会话主动发包、收发日志、主题与背包形态资源替换、战斗状态查看和战斗表现设置。重构必须保持现有行为和协议语义。当前不升级 .NET、WinForms、CefSharp、PPAPI Flash 或 EasyHook，不重写协议/AMF3/TCP 重组算法。

2026-09-30 静态核对：生产战斗清单为资源版本 `260929024751831`、Bridge Version 5；`PetFightBattleBridgeArtifact.BridgeVersion` 与清单一致。当前接入的是 `ConservativeCleanup` 候选，已完成静态验证但尚未进行真实 Flash 登录、战斗或三组 A/B。9 月 4 日实机记录对应旧资源的纯状态候选。旧失败候选不进入生产路径，清单无效时透传官方资源；9 月 5 日的[文档核对记录](doc/DOCUMENTATION_AUDIT.md)保留为历史快照。

## 技术栈与顶层模块

- Windows x64、.NET Framework 4.8、WinForms、CefSharp 87、PPAPI Flash。
- `AolaLoader`：AppShell、BrowserHost、Settings、PacketHost、ResourceInterception、Theme、PetMorph、Battle、Lineup 与 UI。
- `AolaSocketHack`：EasyHook、Winsock 捕获、TCP 重组与协议解析；生产入口拒绝遗留旁路发送请求。
- `AolaSocketHack.Contracts`：跨进程 DTO 与 remoting 边界。
- `AolaSocketHack.Verify`：PCAP 回放与主动发送回读验证。
- `analysis/AolaOfflineClient` 已不在当前工作区，不属于当前执行面；其模块页仅保留历史设计。旧 `analysis/loader` 同样不在当前工作区。

允许的依赖方向是 `UI/AppShell -> 功能契约 -> 功能实现 -> 算法或框架适配器`。CefSharp 类型停留在 BrowserHost/ResourceInterception 的 Cef 适配层，WinForms 类型停留在 AppShell/UI，EasyHook 类型停留在 SocketHack Hooking。不要创建通用 `Helpers`、`Utils` 或巨型 `Interfaces` 目录。

## 不可违反的约束

- 抓包表格只显示 `Direction == "发送"`；接收流量只进入 JSONL 日志和战斗等消费者。
- 抓包页只显示可导出的 `#send`，没有 HEX 详情窗格，且不会随主窗口启动自动打开。完整收发日志默认关闭，点击“保留日志”后才开始落盘并持续写入；开始保留或写入失败期间的有界缓存上限为 8 MiB。
- 导出仅接受严格 `#send={"id":42,"param":{},"cmd":"CMD"}|`，UTF-8 无 BOM；发送前移除用户提供的 `:ext_seq;`。
- 登录 SID/帧仅可存在于注入进程内存，socket 关闭/释放时清除；不得进入 IPC、UI、日志、导出或文档。
- ActiveSend 通过页面桥、ExternalInterface 和 `ActClientSender` 使用 Flash 原连接；OuterSeq、InnerSeq、加密与排序归 Flash 所有，不重放登录帧、不创建第二连接、不注入自制密文。`SubmittedToFlash` 仅表示调用提交。
- Hook 回调只复制有界数据并入有界队列；保留按 socket 重组和 16 MiB 复制上限，不在回调内阻塞。
- WinForms 消费者必须用既有 `InvokeRequired/BeginInvoke` 模式切回 UI 线程，并在关闭/释放时退订。
- `2303` 重置 roster；兼容的近期 roster 可跨 `2401` 保留；宠物先按 UQI、后按槽位合并；保留全部场上/场下宠物及最终六维、HP、PP/CD。

## SWF 与缓存规则摘要

原始 SWF 永不覆盖；先复制并记录大小/SHA-256。识别 FWS/CWS/ZWS，校验声明长度和压缩布局，再用 FFDec 重读并检查文档/导出类、包、方法、`SymbolClass`、实例名和 `ApplicationDomain` 契约。优先拦截 `skinN~*.swf` 等叶子资源；默认主题不拦截，`SkinN` 仅在唯一等长标记前提下适配。不要把服务器状态命令用于本地资源替换。

CEF 内存/磁盘缓存、Flash Loader 缓存和 ApplicationDomain 缓存是不同边界。静态成功或编译成功不证明 SWF 可运行；必须先测默认路径，再测替换、切换、关闭重开和必要的新进程路径。发生回归时保存证据并恢复默认路径。

## 构建与最小验证

```powershell
dotnet build .\analysis\AolaLoader\AolaLoader.csproj -c Release
dotnet build .\analysis\AolaSocketHack.Verify\AolaSocketHack.Verify.csproj -c Release
dotnet run --project .\analysis\AolaSocketHack.Verify\AolaSocketHack.Verify.csproj -c Release --no-build -- --self-test
```

PCAP 回放需要维护者另行提供获授权的本地抓包路径，命令见 README。旧固定抓包的历史基线为 `exportable=164`、`failures=0` 和全部布尔检查通过；其他抓包的条数不能套用该值。项目构建应串行执行以避免共享依赖输出竞争。CefSharp 87 的 NU1903 警告是遗留风险，成功构建不会消除它。构建、自测、协议回读和真实 Flash/服务器验收分别记录。

## 文档路由

- 总体边界与数据流：[`doc/architecture.md`](doc/architecture.md)
- 模块契约：[`doc/modules/`](doc/modules/)
- 跨模块决策：[`doc/decisions/`](doc/decisions/)
- 一次性实施说明与基线：[`task/`](task/)
- SWF/协议证据：`analysis/reverse-engineering/`、PCAP、运行日志和原始二进制。
