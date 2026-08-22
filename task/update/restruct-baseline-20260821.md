# 重构阶段 0 基线（2026-08-21）

## 范围

本记录对应 `task/restruct.md` 阶段 0。工作树开始时干净；本阶段未修改运行代码、项目文件、SWF、PCAP 或运行时文件。

## 源码核对

- `AolaMainForm` 当前直接创建 CefSharp 浏览器、设置存储、Hook controller、接收 logger、战斗 tracker、资源处理器和子窗口，并直接订阅 `AolaHookHostService.StatusReceived`。
- `AolaReceiveLogger`、`AolaBattleStateTracker` 和 `AolaPacketsForm` 直接订阅静态 IPC 事件；均有退订路径，抓包窗体仍显式过滤非“发送”方向。
- `AolaThemeRequestHandler` 当前同时实现主题、背包桥接、模型/海报计划、远程探测、缓存、HTTP 回退和响应过滤器选择。
- `AolaSettingsStore` 当前读取/写入单一 SchemaVersion 5 DTO；写入 UTF-8 无 BOM，但尚未实现 Section 独立版本和临时文件原子替换。
- `Program.Main` 当前直接构造 `AolaMainForm`；CompositionRoot 尚不存在。

以上结论以 2026-08-21 工作树源码为准。详细运行/SWF 证据仍保留在 `analysis/reverse-engineering/`，没有搬入架构概览。

## 自动验证

1. `dotnet build .\analysis\AolaSocketHack.Verify\AolaSocketHack.Verify.csproj -c Release`：成功，0 警告、0 错误。
2. `dotnet build .\analysis\AolaLoader\AolaLoader.csproj -c Release`：串行重跑成功，4 个 NU1903、0 错误。警告来自 CefSharp.WinForms 87.1.132 的两个已知高危公告，在 restore/build 两阶段各报告一次。
3. PCAP replay：`sent=172 received=423 policy=1 exportable=164 failures=0 export_format=True login_redacted=True inner_plaintext=True active_send=True`，`Aola PCAP replay: PASS`。
4. 在 `analysis/loader/` 运行 `python -B -m scripts.verify`：全部检查通过。测试故意触发的 `unsupported response` traceback 属接收诊断恢复用例，最终结果为 `All tests passed`。

最初同时构建两个共享依赖的 .NET 项目时，`analysis/obj/AolaSocketHack.Contracts/...dll` 出现进程间写锁竞争。串行重跑成功，说明这不是源码回归；后续基线命令按顺序执行。

## 尚未完成的运行基线

本环境本轮未启动交互式 CefSharp/PPAPI Flash，因此没有重新实测默认启动、登录、主题、背包形态、日志保留、发包 UI 和 F3 对战窗口。已有历史证据不能替代本轮实机验证。阶段 1 的所有新模块接口因此保持 `Target`，不得标记为 `Implemented`。

## 回归保护

- 保持 send-only 表格、接收 JSONL、登录脱敏、Inner 明文、严格导出和独立连接发包语义。
- 保持默认主题不拦截和所有资源失败时的官方资源回退。
- 后续任何 PCAP 字段变化、登录材料越界、UI 线程异常或默认 Flash 启动回归都应停止扩大迁移。

