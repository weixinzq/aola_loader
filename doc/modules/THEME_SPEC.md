# Theme

Status: Implemented
ContractVersion: 2
OwnerPaths: `analysis/AolaLoader/Features/Theme/**`, `analysis/AolaLoader/Resources/Themes/**`, `analysis/tools/Prepare-ThemeLiveBridge.ps1`, `analysis/tools/theme/**`

## 职责

拥有主题选择、Theme Section、主题页面桥及控制栏/专用皮肤资源规则。保留旧的 `skinN~*.swf` 等长适配路径，供实机回退使用。

## 非职责

不创建 Cef handler、不处理 PetMorph、不清全局缓存、不发送 `UiSkinStyle240927` 或修改账号服务器状态。

## 公开契约

`IThemeCoordinator` 提供当前选择、可选项、保存、`PushCurrentAsync` 和 `ResetPage`；`ThemeBridgeClient` 通过 `IPageBridge` 调用 `theme.apply`。`ThemeSettings { Version, SelectedThemeId }` 保持 Version 1：0 恢复账号官方皮肤对象，1..9 为本地主题。保存/规则更新成功与 Flash 返回“已应用”是不同结果。

## 输入与输出

输入为选择命令和规范化资源请求；输出为状态快照、保存结果或本地 SWF 响应计划。

## 允许依赖

Settings Section、ResourceInterception、BrowserHost 页面桥契约和最小 SWF token 适配器。

## 禁止依赖

CefSharp 具体类型、PetMorph/Battle 内部实现、PacketHost 和服务器状态命令。

## 线程与生命周期

协调器串行更新不可变选择快照；UI 通知由调用方 marshal。释放后不发布状态。

## 异常及回退语义

模板缺失、非 FWS、目标 token 缺失/多义/非等长时拒绝替换并使用官方资源；保存失败明确报告，不破坏旧设置。

## 设置所有权

独占 `theme` Section，Version 1；不得修改 `petMorph` 或 `battle`。

## 安全约束

只匹配 `aola.100bt.com` 的受控 controlbar 叶子路径；原模板只读，转换副本不覆盖源。

## 缓存语义

热切换只请求 `/play/aola-helper/theme/skin1..9.swf`，官方叶子请求正常放行。候选叶子类、时间轴类及内嵌 `mmo.control` 类位于 `aola.theme.tN` 命名空间，加载到独立子域。每个主题对象只创建一次；保留官方对象以恢复默认。非活动对象的控制栏及辅助对象监听成对停用/恢复，按钮锁辅助对象每个主题只创建一次。

旧模式仍受 Flash 类缓存影响，选择后需刷新。进程启动前设置 `AOLA_THEME_LIVE_BRIDGE=0` 可关闭热切换候选和专用规则，继续使用原刷新路径；不会自动刷新或重新登录。

## 验证入口

`AolaSocketHack.Verify --theme-live-contract`：官方叶子放行、专用路径、最新选择、过期结果、页面重建、默认恢复请求、失败状态及相关页面/启动桥契约。候选生成入口为 `analysis/tools/Prepare-ThemeLiveBridge.ps1`，官方输入与导出、p-code、候选及静态复读保存在指定 EvidenceRoot。

## 完成标准

主题逻辑离开通用 Cef 入口；默认和至少一个替换主题实机通过；设置 Section 独立保存。

## 已知限制

2026-10-04 热切换增量候选基于当前官方配置中的 `controlv2~2026082731219998.swf`，补丁只增加主题显示桥与对应对象生命周期；不调用 `ControlBarSkinClient.setSkin`。`ControlBarSkinBase` 存在两个 FFDec 无法完整反编译的方法，因此使用原 p-code 定点修改监听调用，保留原方法。启动桥通过动态定义查询调用 `ControlBarSkinHandler.applyTheme`，不提前创建未就绪模块。

调用链为菜单 → `ThemeCoordinator` → `ThemeBridgeClient` → `AolaPageBridge` → `aolaThemeApply` → 控制栏候选 → 专用资源规则 → 应用结果。状态包括 `Applied / WaitingBattleEnd / NotReady / Loading / Failed / Superseded`；主窗体每 500ms 推送未完成选择，终态不重复调用 Flash。战斗结束且显示链恢复可见后才替换，新对象完成前保持旧界面，失败尝试恢复旧对象。选择与页面重建递增 requestId；旧结果不更新当前菜单。

热切换尚需实机验收：默认→1→9→1→默认、快速选择、重进游戏、战斗延后，以及地图/背包/聊天一次点击一次操作。既有阶段 9 的刷新路径证据不能证明本次热切换运行成功。

本次验证：`--theme-live-contract`（从仓库根目录运行）通过，包含主题、页面桥及主动发送相关契约；生产页面脚本模拟执行通过；1..9 SymbolClass/ABC 定义匹配，1/9 叶子与控制栏/启动桥 FFDec 静态复读通过，控制栏与启动桥的非 ABC 标签保持原样；三个生产项目 Release 构建通过，0 错误，宿主保留既有 CefSharp 两项 NU1903 提示。`git diff --check` 通过。没有执行真实 Flash、登录、战斗或按钮操作；输出位于隔离目录 `analysis/.theme-live-build/loader`。

`IThemeCoordinator`/`ThemeCoordinator` 拥有主题选项、当前快照、`ApplyToRule`/`ApplyAndSave` 与结构化结果；主窗体只转发选择，`AolaResourceRequestHandler` 通过 `IThemeSelectionTarget` 接入，`ThemeLeafResourceRule` 独立于 Cef。阶段 9 已验证默认不拦截、替换主题、刷新、窗口重开与新进程缓存路径；本地替换不发送服务器主题状态命令。
