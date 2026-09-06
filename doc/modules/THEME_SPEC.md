# Theme

Status: Implemented
ContractVersion: 1  
OwnerPaths: `analysis/AolaLoader/Features/Theme/**`, `analysis/AolaLoader/Resources/Themes/**`

## 职责

拥有主题选择、Theme Section、`skinN~*.swf` 精确规则和等长 `SkinN` 类名适配计划。

## 非职责

不创建 Cef handler、不处理 PetMorph、不清全局缓存、不发送 `UiSkinStyle240927` 或修改账号服务器状态。

## 公开契约

`IThemeCoordinator` 提供当前选择、可选项和保存/应用；`ThemeLeafResourceRule` 实现资源规则；`ThemeSettings { Version, SelectedThemeId }`。0 表示默认且完全放行，1..9 表示本地模板。

## 输入与输出

输入为选择命令和规范化资源请求；输出为状态快照、保存结果或本地 SWF 响应计划。

## 允许依赖

Settings Section 契约、ResourceInterception 契约和最小 SWF token 适配器。

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

可缓存已验证模板字节；同进程主题类受 Flash loader/ApplicationDomain 缓存影响，选择变化仍可能需要页面刷新或新进程。

## 验证入口

默认完全放行、每个 SkinN 唯一等长 token、相似 URL 放行、坏模板回退、设置恢复、刷新/新进程实机路径。

## 完成标准

主题逻辑离开通用 Cef 入口；默认和至少一个替换主题实机通过；设置 Section 独立保存。

## 已知限制

`IThemeCoordinator`/`ThemeCoordinator` 拥有主题选项、当前快照、`ApplyToRule`/`ApplyAndSave` 与结构化结果；主窗体只转发选择，`AolaResourceRequestHandler` 通过 `IThemeSelectionTarget` 接入，`ThemeLeafResourceRule` 独立于 Cef。阶段 9 已验证默认不拦截、替换主题、刷新、窗口重开与新进程缓存路径；本地替换不发送服务器主题状态命令。
