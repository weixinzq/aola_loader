# 重构阶段 3：ResourceRulePipeline 核心（2026-08-22）

## 批次范围

本批次进入阶段 3，只建立框架无关规则管线、受界响应处理、远程 SWF 探测和 TTL 缓存。旧 `AolaThemeRequestHandler` 的 Theme、Pet package、PetMovie、Poster 分支及主窗体接线保持不变；只把旧处理器的 SWF 头判断转调到共享验证器。

## 实现

- `ResourceRulePipeline`：按优先级降序、注册顺序稳定评估；首个优先级组的单一命中生效。
- 同优先级多规则命中、规则异常、空计划或 URL 身份变化均诊断并放行官方资源。
- 关闭状态、内部重写和回退请求直接放行，防止递归拦截。
- `BoundedResourceResponseProcessor`：输入和转换输出共享显式上限，拒绝空响应、非 2xx、转换异常和超限内容。
- `SwfResponseHeaderValidator`：统一 FWS/CWS/ZWS 签名、声明长度、ZWS 压缩长度和字典上限检查。
- `HttpSwfRemoteResourceProbe`：只读取 SWF 头范围，返回结构化失败，不传播登录或请求敏感数据。
- `CachingRemoteResourceProbe`：缓存键包含目标 URL、计划 cache key 和大小约束，成功/失败分别使用请求声明的 TTL。

## 自动验证

`ResourceInterception contract self-test` 新增覆盖：

- 稳定优先级、精确/近似 URL、关闭放行；
- 重写和回退递归防护；
- 同优先级冲突及非法优先级；
- 受界响应、非 2xx、转换异常；
- FWS/CWS/ZWS 头边界；
- 探测缓存命中和 TTL 到期再探测。

## SWF 原件证据

依照 `reverse-engineer-swf` 工作流，只读检查了现有资源；全部为有效 FWS、文件长度等于声明长度，未生成或覆盖任何 SWF：

| 文件 | SHA-256 |
|---|---|
| skin0 | `4a72b022ee5bfe233697d3cdd388bf9ba8c5aee72fa6e0aab027f8b3a7b6feff` |
| skin1 | `b577c796f18acda2298b927b8e204169fda119bded82a341ef3278c26a176087` |
| skin2 | `06dd8f3bd3c82c629428ecf3dfd25c8413e2279a326a96fd962996dec2cfae9a` |
| skin3 | `9f99f880d619bb1d7009ce64f74392d836fe0f7d16fb1fb502b7ed5fc13a06d2` |
| skin4 | `90c37e1514d036502775248561a8ed94f9483c88dc0fc7a1ea9f293e74d9dc70` |
| skin5 | `29d79100b6fc2f05ab13164d264d1a94808c3b1439abe148f2ffc52ebd818d94` |
| skin6 | `155fe577e7b02987ef20e073110d0313d629cf72f51c89f9b020f69202e28dec` |
| skin7 | `dac00d4e454118472cfabc1283ca202dabbd858aa7ad9d9ee393273344bff055` |
| skin8 | `9583ceac0827edbc771f2190493234cfc9c80c90c534d1a849d8dfc4434f934d` |
| skin9 | `e73c0af3f3a5f8c7c1cf312f0ecdbe29f6506d72b2e0f818044dc812ddf63df9` |
| newpetpackage-morph-live | `10ca77099996bbf8e540b636d6f7f6e83f9ea1daf6f73f4c0d3c929ecc1dc5be` |
| newpetpackage-morph-template | `a918cdf49762082ae533b3aac651e9d61585f41959f840a107254035536ad4b4` |

## 后续与限制

下一批实现薄 Cef 请求适配器，然后按 Theme、Pet package、PetMovie、Poster 顺序迁移。每条规则都必须先验证默认路径，再验证替换路径；构建、头检查或 FFDec 成功不能替代真实 Flash 加载验证。当前批次没有改变实际返回的 SWF 字节，因此不宣称任何新的替换路径已完成实机验证。
