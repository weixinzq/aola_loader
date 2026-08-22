# 重构阶段 3：Pet package 规则（2026-08-22）

## 批次范围

本批次把现有 Pet package live bridge 本地替换从 `AolaThemeRequestHandler` 迁移为独立规则。没有修改模板字节、支持版本、Live Bridge API、PetMorph 设置、页面注入逻辑或 PetMovie/Poster 远程分支。

## 实现

- `PetPackageLiveResourceRule`：优先级 699，只拥有 `aola.100bt.com:/play/pet/newpetpackage~2026081331982423.swf`。
- 只接受 GET、精确 host、精确路径和精确版本；查询字符串不影响资源身份。
- 模板必须是 16 MiB 内、声明长度一致的 FWS，并同时包含：
  - `aolaMorphResolveSkinId`
  - `aolaMorphRefresh`
  - `aolaMorphShouldHideBackground`
  - `aolaMorphResolveIconId`
- 模板不可用、桥接禁用、版本变化、错误 host/method 或近似扩展名时完全放行官方资源。
- 本地计划返回防御性内容，cache key 包含版本和模板 SHA-256。
- `AolaThemeRequestHandler.IsPetMorphLiveBridgeAvailable` 和海报映射探测继续通过兼容层读取规则可用性。

旧处理器中的 Pet package 正则、模板字段、模板校验、响应创建和专用本地 `ResourceRequestHandler` 已删除；Theme 与 Pet package 统一走 `CefResourceRuleAdapter`。

## 自动验证

`ResourceInterception contract self-test` 新增覆盖：

- 模板可用性和输入/输出防御性复制；
- 精确版本命中；
- 模板缺少任一 live marker 时拒绝；
- 无模板、错误版本、近似路径、POST 和错误 host 放行。

## SWF 静态证据

实际发布模板 `analysis/AolaLoader/Resources/Patches/newpetpackage-morph-live.fws.swf`：

- FWS，文件及声明长度 `2208280`；
- SHA-256 `10ca77099996bbf8e540b636d6f7f6e83f9ea1daf6f73f4c0d3c929ecc1dc5be`；
- 与保留原件 `newpetpackage~2026081331982423.swf` 比较；原件为有效 ZWS，SHA-256 `785089fd9749c06355a1bf2144d146e51f797283e711d62a073dfec243339915`；
- FFDec 复读成功；确认 `SimpleViewController`、`PetBigIconDetail`、`getAolaMorphSkinId` 及四个 live bridge 标记；
- 报告：`analysis/reverse-engineering/pet-model-to-poster-20260820/evidence/verify-live-stage3/run-20260822-105643-977038-32436/report.json`。

## 限制与下一步

本批次是现有字节与匹配范围的结构迁移，未完成真实 CefSharp + PPAPI Flash 默认/替换路径验证。尤其 `newpetpackage` 类会进入 Flash ApplicationDomain，验证替换路径需要新进程；静态复读和宿主构建不能证明可加载。

下一批实现远程计划 Cef 执行层，再迁移 PetMovie；转换、探测或 HTTP 失败必须整体恢复原 URL，不能把部分候选字节交给 Flash。
