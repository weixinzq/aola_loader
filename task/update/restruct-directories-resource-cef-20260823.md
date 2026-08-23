# 阶段 7：ResourceInterception Cef 目录与命名空间迁移（2026-08-23）

本批次只把 `AolaDynamicRequestHandler.cs`（类型 `AolaThemeRequestHandler`）与 `AolaSwfResponseFilter.cs` 从项目根目录迁入 `ResourceInterception/Cef/`，命名空间改为 `AolaLoader.ResourceInterception.Cef`，并在 CompositionRoot 增加必要引用。规则注册、请求计划、远程回退、响应过滤和转换行为均未改变。

物理移动保持旧命名空间时，Loader 与 Verify 构建通过；随后调整命名空间并再次构建通过。构建继续报告 CefSharp 87.1.132 的 4 条 `NU1903` 已知高危漏洞警告。

最终验证：10 项边界自测全部 PASS；PCAP replay PASS，保持 `exportable=164`、`failures=0`、`export_format=True`、`login_redacted=True`、`inner_plaintext=True`、`active_send=True`；两个移动文件比较仅含本轮及前序批次所需命名空间引用变化；`git diff --check` PASS。真实 Flash 默认、替换、关闭重开及新进程路径仍待阶段 9。
