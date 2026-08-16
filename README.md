# Aola Loader

Aola Loader 是一个面向奥拉星旧版 Flash 客户端的精简登录、抓包、分析与发包工具。公开仓库包含基础游戏登录界面、`AolaSocketHack`、IPC 契约和协议验证器；窗口只展示客户端“发送”消息，接收消息写入日志并供对战助手分析。

> 这是基于 CefSharp 87 和 PPAPI Flash 的遗留运行环境，只应用于受控的奥拉星站点。不要将它当作通用浏览器。

## 当前功能

- 打开 `https://aola.100bt.com/play/play.html`，并向 `CefSharp.BrowserSubprocess.exe --type=network.mojom` 注入 `AolaSocketHack.dll`。
- 抓包表格只显示“发送”消息；EXT 详情显示解密后的参数 JSON 和 Inner AMF3 明文 HEX，不显示加密原始帧。
- 将发送消息导出为 UTF-8 无 BOM 的 Loader 格式：`#send={"id":42,"param":{},"cmd":"CMD"}|`。
- 从粘贴内容或文件载入 `#send`，经独立游戏连接重新生成 OuterSeq、InnerSeq 和密文后发送；不会重放浏览器连接的密文字节。
- 将全部“接收”消息实时写入程序目录下的 `logs/aola-recv-yyyyMMdd-HHmmss.jsonl`，保留 AMF3 JSON 与接收帧 HEX，但不在抓包表格显示。
- 通过“扩展 → 对战助手”或 `F3` 打开战斗窗口。助手解析 `2303/2304` 完整背包与后续战斗命令，显示敌我全部亚比的最终六维、HP 和技能 PP/CD，并缓存当前快照。
- 通过“扩展 → 游戏主题界面”选择本地主题。请求处理器只拦截 `control/controlbarskin/skinN~*.swf` 末端资源，并将模板导出类适配为调用方需要的 `SkinN`；“默认”完全关闭拦截。

主题功能是 HTTP/SWF 本地资源替换，不会发送主题切换命令，也不会修改服务器保存的账号主题。捕获的登录 SID/登录帧只在注入进程内存中短暂用于建立独立连接，不进入 IPC 事件、界面、导出或日志。

## 目录

- `analysis/AolaLoader/`：WinForms/CefSharp 主程序、抓包/发包窗口、接收日志、对战助手和主题资源拦截。
- `analysis/AolaSocketHack/`：Winsock Hook、TCP 重组、Aola/AMF3 协议与独立连接发包器。
- `analysis/AolaSocketHack.Contracts/`：主进程与注入进程之间的 IPC 契约。
- `analysis/AolaSocketHack.Verify/`：真实 PCAP 回放与主动发包编码回读验证。
- `analysis/runtime/`：本地 PPAPI Flash 放置位置；EasyHook 由 NuGet 恢复。
- [`doc/architecture.md`](doc/architecture.md)：运行拓扑、数据流、缓存层与验证边界。

## 环境要求

- Windows x64 与 .NET Framework 4.8 Developer Pack。
- 可访问 NuGet.org；构建会恢复 CefSharp.WinForms 87.1.132、EasyHook 2.7.7097 和 Newtonsoft.Json 13.0.4。
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

维护者可以使用本地保留、未公开提交的真实 PCAP 回放协议基线：

```powershell
dotnet run --project .\analysis\AolaSocketHack.Verify\AolaSocketHack.Verify.csproj `
  -c Release --no-build -- `
  D:\Programs\Wireshark\tshark.exe `
  .\analysis\loader\mt250816_full_anyserver.pcapng 2
```

当前基线应包含：

```text
exportable=164 failures=0 export_format=True login_redacted=True inner_plaintext=True active_send=True
Aola PCAP replay: PASS
```

## SWF 资源修改约束

- 永不覆盖原始 SWF；先另存、记录长度和 SHA-256，再反编译或修改。
- 用 URL/缓存索引、长度、时间、文件头、哈希和内部字符串共同确认 CEF 缓存身份，不能只看 `f_00011c` 之类的文件名。
- 检查 FWS/CWS/ZWS 头、声明长度、导出类、`SymbolClass`、实例名、`ApplicationDomain` 和跨 SWF 依赖。
- 优先替换末端 `skinN.swf`，避免修改启动核心模块。`Skin0` 与 `Skin1` 是不同的导出类，不能直接互换。
- 先验证默认/无替换路径，再验证修改路径。FFDec 能回读或 C# 能编译不能代替真实 Flash 运行验证；已有核心模块候选静态验证通过但启动卡在 `1/11` 的回归记录。
