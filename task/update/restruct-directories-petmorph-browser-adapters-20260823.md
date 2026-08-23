# 阶段 7：PetMorph 浏览器适配器目录与命名空间迁移（2026-08-23）

本批次只把 `AolaBrowserPetMorphPushBridge.cs` 与 `AolaPetMorphLiveBridge.cs` 从项目根目录迁入 `AppShell/Adapters/PetMorph/`，命名空间改为 `AolaLoader.AppShell.Adapters.PetMorph`，并在 CompositionRoot 增加必要引用。JS 内容、revision、超时/取消、frame 校验与结构化推送结果均未改变。

该位置是依赖边界选择：适配器同时依赖 CefSharp 与 PetMorph 协调契约，放在 AppShell 适配层可避免 CefSharp 进入 `Features/PetMorph`，也避免 BrowserHost 反向依赖具体功能。

物理移动保持旧命名空间时，Loader 与 Verify 构建通过；随后调整命名空间并再次构建通过。最终验证：10 项边界自测全部 PASS；PCAP replay PASS，保持 `exportable=164`、`failures=0`、`export_format=True`、`login_redacted=True`、`inner_plaintext=True`、`active_send=True`；两个移动文件比较仅含预期命名空间变化；`git diff --check` PASS。真实 PPAPI Flash 热推送仍待阶段 9。
