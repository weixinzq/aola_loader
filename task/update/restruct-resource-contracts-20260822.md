# 重构阶段 2：ResourceInterception 契约（2026-08-22）

## 批次范围

本批次只冻结 ResourceInterception ContractVersion 1 的框架无关边界和测试替身。没有修改 `AolaThemeRequestHandler`、`AolaSwfResponseFilter`、SWF 算法、CefSharp 请求处理器或生产接线，也没有移动 Theme/PetMorph 规则。

## 实现

- `ResourceRequestContext`：保留原 URL，并提供规范化 scheme、host、path、query、method、资源类型、只读 headers、rewrite/fallback 标志和内部 plan key。
- `IResourceInterceptionRule`：稳定名称、显式优先级、路径所有权描述和纯计划评估入口。
- `ResourceInterceptionPlan`：只允许 `PassThrough`、`LocalResponse`、`RewriteRemote`，表达目标/本地内容、Content-Type、转换器、官方回退 URL、缓存/诊断 key 和响应上限。
- `IResourceResponseTransformer`、`ResourceTransformInput/Result`：只处理完整响应，成功返回防御性字节副本；拒绝结果不携带未经验证候选。
- `IRemoteResourceProbe` 与请求/结果：异步取消、完整资源身份 key、正负 TTL、大小上限、HTTP/长度和结构化拒绝。
- delegate 测试替身：规则、转换器和远程探测无需 CefSharp 即可验证。

所有 byte 数组和 header 集合均在边界复制；内部 rewrite/fallback 请求必须携带 plan key。URL 仅接受绝对 HTTP/HTTPS。契约目录不依赖 CefSharp、WinForms、PacketHost、Settings 或具体功能模块。

## 优先级冻结

- `1000..1099`：受版本/哈希约束的精确桥接和本地补丁。
- `800..899`：主题叶资源。
- `600..699`：背包、海报、战斗模型等功能叶资源。
- 其他区间未经新 ADR 不得占用。

同优先级多规则命中的“诊断并放行”将在阶段 3 的 `ResourceRulePipeline` 实现和验证，本批次不提前实现选择算法。

## 自动验证

`ResourceInterception contract self-test` 覆盖：

- URL/host/method 规范化和 header 防御性复制；
- 非 HTTP URL、缺失内部 plan key 和非法响应上限拒绝；
- 三种固定计划及本地响应字节不可变；
- 规则元数据与 delegate 测试替身；
- 完整响应输入、成功内容复制和不携带候选的结构化拒绝；
- 远程探测大小、正负 TTL、成功与非 2xx 拒绝结果。

## 待办

阶段 3 依次实现有序管线、同优先级冲突检测、薄 Cef 适配器、带 TTL 的远程探测、受界响应缓冲，并按 Theme、Pet package、PetMovie、Poster 逐条迁移。迁移每条规则时必须分别验证默认放行和替换/回退路径。

