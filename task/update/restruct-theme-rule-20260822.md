# 重构阶段 3：薄 Cef 适配与 Theme 规则（2026-08-22）

## 批次范围

本批次实现本地响应所需的薄 Cef 适配器，并将 Theme 控制栏叶资源从 `AolaThemeRequestHandler` 迁移为独立规则。保留旧类型名、构造函数、`SelectedThemeId` 属性和主窗体接线；Pet package、PetMovie、Poster 及远程计划仍走旧分支。

## 实现

- `CefResourceRuleAdapter`：把 Cef `IRequest` 的 URL、方法、资源类型和请求头复制为框架无关上下文；只有 `LocalResponse` 计划关闭默认处理并返回指定 MIME 的本地内容。
- `ThemeLeafResourceRule`：优先级 800，只拥有 `aola.100bt.com:/play/control/controlbarskin/skinN~*.swf`。
- 默认 `SelectedThemeId == -1` 完全放行；只接受 GET、精确 host 和精确叶资源路径。
- 每个本地模板必须是长度一致的 FWS，且 `SkinN` 标记恰好出现三次。
- 每次请求克隆模板并执行三处同长度 `Skin<selected>` 到 `Skin<requested>` 替换；失败时放行官方资源。
- 本地计划 cache key 包含模板 SHA-256 和请求 Skin ID；未发送 `UiSkinStyle240927_1` 或其他服务器状态命令。

## 自动验证

`ResourceInterception contract self-test` 新增 Theme 覆盖：

- 默认主题不拦截；
- 精确 URL 返回本地 SWF；
- 三处类标记替换和声明长度保持；
- 输入模板、计划内容的防御性复制；
- 近似扩展名、错误 host、POST 放行；
- 标记缺失或数量不符的模板拒绝。

## SWF 静态证据

原始 `skin1.swf` 保持不变：

- SHA-256：`b577c796f18acda2298b927b8e204169fda119bded82a341ef3278c26a176087`
- FWS，大小及声明长度：`1087930`

隔离候选 `analysis/reverse-engineering/controlbarskin-analysis/skin1-as-skin0-stage3.swf`：

- 只把三处 `Skin1` 改为 `Skin0`，其余解码体差异数为 3；
- SHA-256：`88b77cc35caf4d06deff493dff02143e5f9db931bc28941c76aa64916114df65`
- FFDec 复读成功；确认 `mmo.controlv2.controlbarskin.skin.Skin0`、SymbolClass、构造方法、`btnAction` 和 `mcPlayerInfo`。
- 成功报告：`analysis/reverse-engineering/controlbarskin-analysis/evidence/run-20260822-104515-752319-72268/report.json`。

首次在候选尚未写入时运行验证器，验证器正确停止并保留失败报告 `run-20260822-103727-450141-36564`；随后经授权生成隔离候选并重新验证。任何运行时资源均未被失败尝试覆盖。

## 限制与下一步

静态验证不能证明 Flash 可加载。当前尚未完成本轮默认主题和替换主题的真实登录/页面加载、请求 URL/返回哈希、缓存绕过和新进程验证，因此不把 Theme 或 ResourceInterception 标记为 `Implemented`。

按阶段 3 顺序，必须先补齐 Theme 默认/替换实机证据，再扩展 Cef 适配器的远程计划执行并迁移 Pet package、PetMovie、Poster。
