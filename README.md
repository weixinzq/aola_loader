# Aola Loader

Aola Loader 是一个面向奥拉星旧版 Flash 客户端的精简登录、抓包、分析与发包工具。公开仓库包含基础游戏登录界面、`AolaSocketHack`、IPC 契约、协议验证器，以及独立的 Python 脱机登录子项目；窗口只展示可导出的客户端“发送”消息，收发日志默认在内存暂存、点击“保留日志”后写入文件，接收消息同时供对战助手分析。

> 这是基于 CefSharp 87 和 PPAPI Flash 的遗留运行环境，只应用于受控的奥拉星站点。不要将它当作通用浏览器。

## 当前功能

- 打开 `https://aola.100bt.com/play/play.html`，并向 `CefSharp.BrowserSubprocess.exe --type=network.mojom` 注入 `AolaSocketHack.dll`。
- 抓包表格只显示可严格导出的“发送”消息，列为复选框、时间和解析后的 `#send`；可将选中记录追加到发包编辑器，不提供 HEX 详情窗格。
- 将发送消息导出为 UTF-8 无 BOM 的 Loader 格式：`#send={"id":42,"param":{},"cmd":"CMD"}|`。
- 从粘贴内容或文件载入 `#send`，经页面桥交给已登录 Flash 的正式发送 API；OuterSeq、InnerSeq、加密与正常发送顺序仍由 Flash 原连接拥有。
- “发送/接收”日志默认在内存中暂存，UTF-8 计数上限为 64 MiB，超限丢弃最早记录并计数。点击主窗口“保留日志”后，将现有缓存写入程序目录下 `logs/aola-recv-yyyyMMdd-HHmmss.jsonl`，随后持续写入；未保留即退出时不会落盘。记录由 `direction` 区分方向，包含发送 EXT 明文、接收 AMF3 JSON、`type=0` 系统字段和接收原始帧 HEX，登录发送始终脱敏。
- 通过“扩展 → 对战助手”或 `F3` 打开敌方专用窗口。“属性”查看敌方亚比的六维、HP、技能 PP/CD，“配置”按背包顺序查看装备、魂卡、魂器和晶钥图片。支持单人 PVP/PVE；图片由[独立工具准备](doc/runbooks/BATTLE_ASSISTANT_ASSETS.md)，缺图显示占位，运行时不下载或转换 SWF。
- 通过“扩展 → 游戏主题界面”选择本地主题。请求处理器只拦截 `control/controlbarskin/skinN~*.swf` 末端资源，并将模板导出类适配为调用方需要的 `SkinN`；“默认”完全关闭拦截。
- 通过“扩展 → 功能面板 → 形态变化”保存并热推送背包形态规则；模型、背景和头像走独立叶资源规则，远端 FWS/CWS/ZWS 在 16 MiB 边界内验证和转换，失败时回退官方资源。

抓包窗口另有“打开映射面板”页，经 Flash 自身 `Panel_Helper.loadResAndShow` 加载面板。发包页支持新战斗回放与当前战斗附着，使用发送抓包、当前玩家 `2405`、执行结果和只读状态桥控制节奏。战斗表现窗口保存隐藏伤害/治疗数字、跳过每回合演出和独立战斗模型规则；模型规则必须通过双方六分片预检，战斗中修改延迟到结束清理后切换。

截至 2026-09-05，本地生产清单为 `petfightnew` 资源版本 `2026090340574444`、Bridge Version 4，设置为 Battle Version 6。当前演出候选和战斗模型替换仍待真实 Flash 完整验收；9 月 4 日实机记录对应此前纯状态候选，不能替代当前候选验收。核对依据和已知文档/分发限制见 [文档核对记录](doc/DOCUMENTATION_AUDIT.md)。

主题功能是 HTTP/SWF 本地资源替换，不会发送主题切换命令，也不会修改服务器保存的账号主题。捕获的登录 SID/登录帧只允许短暂存在于注入进程内存，不进入 IPC 事件、界面、导出或日志，也不用于 ActiveSend 或 OfflineClient 登录。

## 目录

- `analysis/AolaLoader/`：WinForms/CefSharp 主程序、抓包/发包窗口、收发日志、对战助手和主题资源拦截。
- `analysis/AolaSocketHack/`：Winsock Hook、TCP 重组、Aola/AMF3 协议解析与指标；生产主动发送不从这里创建第二连接。
- `analysis/AolaSocketHack.Contracts/`：主进程与注入进程之间的 IPC 契约。
- `analysis/AolaSocketHack.Verify/`：真实 PCAP 回放与主动发包编码回读验证。
- [`analysis/AolaOfflineClient/`](analysis/AolaOfflineClient/)：Python 3.12 独立账号登录 SDK+CLI、订阅式收发与可信脚本运行器。
- `analysis/runtime/`：本地 PPAPI Flash 放置位置；EasyHook 由 NuGet 恢复。
- [`doc/architecture.md`](doc/architecture.md)：运行拓扑、数据流、缓存层与验证边界。
- [`doc/modules/`](doc/modules/)：各模块的 ContractVersion、依赖、线程、失败与缓存语义。
- [`doc/runbooks/PETFIGHTNEW_WEEKLY_UPDATE.md`](doc/runbooks/PETFIGHTNEW_WEEKLY_UPDATE.md)：战斗状态桥的版本检测、候选生成、晋级、实机验证与回滚流程。
- `task/update/`：历史重构记录；阶段 9 总验收和部分逆向证据仅保留在本地，公开检出不保证包含。当前状态以 `doc/architecture.md`、模块规格及文档核对记录为准。

## 环境要求

- Windows x64 与 .NET Framework 4.8 Developer Pack。
- OfflineClient 需要 Python 3.12，运行依赖为 `aiohttp` 与 `websockets`。
- 可访问 NuGet.org；构建会恢复 CefSharp.WinForms 87.1.132、EasyHook 2.7.7097、Newtonsoft.Json 13.0.4、SharpCompress 0.50.4 和 System.Resources.Extensions 10.0.10。
- 仓库包含当前 Loader 使用的 `analysis/runtime/pepflashplayer.dll`，构建时会复制到程序输出目录。
- PCAP 验证需要 Wireshark/TShark；仓库命令默认使用 `D:\Programs\Wireshark\tshark.exe`。
- SWF 分析建议使用 JPEXS FFDec CLI；本机已知路径为 `D:\Programs\FFdec\ffdec-cli.exe`。

CefSharp 87/Chromium 87 与 PPAPI Flash 均已停止维护。构建时 NuGet 会报告 CefSharp 的已知安全公告；成功构建不表示该遗留运行时适合浏览不受信任的网站。

## 构建

在仓库根目录运行：

```powershell
dotnet restore .\AolaLoader.sln --locked-mode
dotnet build .\AolaLoader.sln -c Release --no-restore
```

首次生成或有意更新依赖锁文件时，先执行不带 `--locked-mode` 的
`dotnet restore .\AolaLoader.sln`，检查并提交对应的 `packages.lock.json`。

主程序输出：

```text
analysis/build/AolaLoader/Release/net48/AolaLoader.exe
```

如果 `analysis/runtime/pepflashplayer.dll` 不存在，构建仍会成功并给出警告，
但程序启动时会明确报告缺少 PPAPI Flash。运行库的固定版本和完整性信息详见
[`analysis/runtime/README.md`](analysis/runtime/README.md)。

## 验证

先运行全部边界自测：

```powershell
dotnet run --project .\analysis\AolaSocketHack.Verify\AolaSocketHack.Verify.csproj `
  -c Release --no-build -- --self-test
```

仓库当前不包含旧 `analysis/loader` PCAP。维护者只有在另行持有获授权、未公开提交的真实抓包时，才可把明确的本地路径传给回放器：

```powershell
dotnet run --project .\analysis\AolaSocketHack.Verify\AolaSocketHack.Verify.csproj `
  -c Release --no-build -- `
  D:\Programs\Wireshark\tshark.exe `
  D:\local-evidence\capture.pcapng 2
```

旧固定抓包的历史基线是：

```text
exportable=164 failures=0 export_format=True login_redacted=True inner_plaintext=True active_send=True
Aola PCAP replay: PASS
```

OfflineClient 的本地测试单独运行，不需要账号或网络：

```powershell
Set-Location .\analysis\AolaOfflineClient
$env:PYTHONPATH='src'
python -B -m unittest discover -s tests -v
```

2026-09-05 本地复跑 33 项测试，32 项通过，`test_vector_sources_still_match_csharp_reference` 因 C# 参考源码哈希变化失败；需要审查源码差异后重新生成/核对黄金向量，不能直接覆盖哈希放行。该子项目尚未完成真实账号验收；单元测试、黄金向量或假传输通过都不能替代实际 `logOK` 与匹配服务器响应。具体边界见 [`analysis/AolaOfflineClient/README.md`](analysis/AolaOfflineClient/README.md)。

## SWF 资源修改约束

- 永不覆盖原始 SWF；先另存、记录长度和 SHA-256，再反编译或修改。
- 用 URL/缓存索引、长度、时间、文件头、哈希和内部字符串共同确认 CEF 缓存身份，不能只看 `f_00011c` 之类的文件名。
- 检查 FWS/CWS/ZWS 头、声明长度、导出类、`SymbolClass`、实例名、`ApplicationDomain` 和跨 SWF 依赖。
- 优先替换末端 `skinN.swf`，避免修改启动核心模块。`Skin0` 与 `Skin1` 是不同的导出类，不能直接互换。
- 先验证默认/无替换路径，再验证修改路径。FFDec 能回读或 C# 能编译不能代替真实 Flash 运行验证；已有核心模块候选静态验证通过但启动卡在 `1/11` 的回归记录。
