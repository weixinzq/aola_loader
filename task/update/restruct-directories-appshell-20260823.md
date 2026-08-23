# 阶段 7：AppShell 目录与命名空间迁移（2026-08-23）

本批次只把 `AolaHookController.cs` 与 `AolaMainForm.cs` 从项目根目录迁入 `AppShell/`，命名空间改为 `AolaLoader.AppShell`，并同步 `MainFormCompositionGuardVerifier` 的源码路径。Hook 注入轮询、控件布局、菜单/工具栏命令、状态呈现、Flash 兼容探针与子窗口命令转发均未改变。

物理移动保持旧命名空间时，Loader 与 Verify 构建通过；随后调整命名空间并再次构建通过。构建继续报告 CefSharp 87.1.132 的 4 条 `NU1903` 已知高危漏洞警告。

最终验证：10 项边界自测全部 PASS，其中 `MainForm composition guard: PASS` 已从新路径读取源码；PCAP replay PASS，保持 `exportable=164`、`failures=0`、`export_format=True`、`login_redacted=True`、`inner_plaintext=True`、`active_send=True`；两个移动文件比较仅含预期命名空间及前序批次必要引用变化；`git diff --check` PASS。

阶段 7 全局审计确认：`analysis/AolaLoader` 根目录只剩入口 `Program.cs` 与不声明任何类型的旧设置注释壳 `AolaSettings.cs`；唯一保留的精确 `namespace AolaLoader;` 属于 `Program`；Verify 项目不存在指向本轮已迁移平铺文件的旧显式源码链接。`AolaSettings.cs` 留待阶段 8 在无调用证据下删除，不在目录迁移阶段夹带清理。真实启动、登录、Hook 注入和子窗口行为仍待阶段 9。
