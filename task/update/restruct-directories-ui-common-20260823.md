# 阶段 7：UI Common 目录与命名空间迁移（2026-08-23）

本批次只把 `AolaFormBase.cs` 从项目根目录迁入 `UI/Common/`，命名空间改为 `AolaLoader.UI.Common`，并在 MainForm、Battle、Packets 与 PetMorph 四个派生窗体增加必要引用。置顶切换、激活回调与 Win32 `SetWindowPos` 行为未改变。

物理移动保持旧命名空间时，Loader 与 Verify 构建通过；随后调整命名空间并再次构建通过。构建继续报告 CefSharp 87.1.132 的 4 条 `NU1903` 已知高危漏洞警告。

最终验证：10 项边界自测全部 PASS；PCAP replay PASS，保持 `exportable=164`、`failures=0`、`export_format=True`、`login_redacted=True`、`inner_plaintext=True`、`active_send=True`；移动文件比较仅含预期命名空间变化；`git diff --check` PASS。窗口点击置顶、最小化恢复和关闭重开仍待阶段 9 实机回归。
