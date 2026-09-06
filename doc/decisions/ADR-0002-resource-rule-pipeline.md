# ADR-0002：浏览器资源使用有序规则管线

Status: Accepted  
Date: 2026-08-21

## 背景和问题

当前 `AolaThemeRequestHandler` 同时包含 Cef 接入、主题、背包桥、模型/海报、远程探测、缓存、回退和转换。新增资源功能会修改同一热点文件，冲突与规则优先级不透明。

## 决定

引入框架无关 `IResourceInterceptionRule` 和有序 `ResourceRulePipeline`。规则只返回 `PassThrough`、`LocalResponse` 或 `RewriteRemote` 计划；按优先级降序选择首个唯一命中计划；同优先级多命中诊断并放行。CefRequestAdapter 独占请求修改、handler/response 创建和回调生命周期。

## 放弃的替代方案

- 每个功能安装独立 Cef handler：CefSharp 入口只有一个，组合和优先级仍隐式。
- 延续单体 if/else：继续制造共享热点。
- 让规则直接改 Cef 请求：会泄露框架类型并难以纯逻辑验证。

## 影响的模块

ResourceInterception、Theme、PetMorph，以及未来 Battle Presentation。

## 兼容及迁移

按 Theme、Pet package、PetMovie、Poster 顺序逐条迁移；每条同时验证关闭放行、精确命中、递归标记、失败回退。旧 handler 仅保留到所有分支及主窗接线迁完。

