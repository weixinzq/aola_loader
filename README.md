面向奥拉星flash登陆器。

## 环境要求

- Windows x64 与 .NET Framework 4.8 开发工具链。
- CefSharp.WinForms 87.1.132、匹配的 PPAPI Flash 和 EasyHook 2.7 系列运行文件。
- PCAP 验证需要 Wireshark/TShark；仓库命令默认使用 `D:\Programs\Wireshark\tshark.exe`。
- SWF 分析建议使用 JPEXS FFDec CLI；本机已知路径为 `D:\Programs\FFdec\ffdec-cli.exe`。

CefSharp 87/Chromium 87 与 PPAPI Flash 均已停止维护。构建时 NuGet 会报告 CefSharp 的已知安全公告；成功构建不表示该遗留运行时适合浏览不受信任的网站。

## 构建

在仓库根目录运行：

```powershell
dotnet build .\analysis\AolaLoader\AolaLoader.csproj -c Release
dotnet build .\analysis\AolaSocketHack.Verify\AolaSocketHack.Verify.csproj -c Release
```

主程序输出：

```text
analysis/build/AolaLoader/Release/net48/AolaLoader.exe
```


