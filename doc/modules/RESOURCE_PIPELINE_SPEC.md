# ResourceInterception

Status: Target  
ContractVersion: 1  
OwnerPaths: `analysis/AolaLoader/ResourceInterception/**`

## 职责

把 Cef 请求适配为框架无关上下文，按稳定顺序评估规则，执行本地响应/远程转换、精确探测、受界缓冲、响应转换和官方资源回退。

## 非职责

不拥有 Theme/PetMorph/Battle 业务规则，不读整个设置文档，不操作 Form，不发送服务器状态命令。

## 公开契约

`IResourceRule.Evaluate(ResourceRequestContext)` 返回 `PassThrough`、`LocalResponse` 或 `RemoteTransform`；`ResourceRulePipeline` 采用首个非放行计划；`IRemoteResourceProbe`、`IResponseTransformer` 和不可变 plan/result 表达 I/O。规则不可直接修改 Cef 请求或创建 handler。

## 输入与输出

输入含规范化 scheme/host/path/query/method/headers 与 rewrite 标记；输出含计划类型、目标、MIME、缓存/回退策略和转换器。

## 允许依赖

Features 的规则注册、纯 SWF 转换器；仅 `ResourceInterception/Cef/**` 可依赖 CefSharp。

## 禁止依赖

WinForms、具体 Form、AolaMainForm、PacketHost、协议解析、可变模块设置对象。

## 线程与生命周期

规则评估无 UI 线程假设且应快速；网络探测异步/后台执行；响应缓冲上限明确，回调始终完成或释放。

## 异常及回退语义

关闭/未命中完全放行。探测失败、非 2xx、长度/压缩/类契约失败均拒绝候选并按计划恢复原 URL；转换异常不把部分字节交给 Flash。

## 设置所有权

无；只消费功能模块提供的不可变规则快照。

## 安全约束

仅精确受控 host/path；防止 rewrite 递归；限制输入/输出；原始 SWF 不覆盖，敏感参数不写日志。

## 缓存语义

探测缓存 key 包含完整资源身份和计划维度；成功/失败 TTL 分离。不得把 CEF、Flash Loader 或 ApplicationDomain 缓存混同。

## 验证入口

关闭放行、精确命中、近似 URL 放行、递归标记、探测失败、非 2xx、转换拒绝、冲突顺序与受界缓冲。

## 完成标准

Theme、PetMorph 现有分支全部成为独立规则；入口只做适配/管线执行；默认与替换 Flash 路径实测通过。

## 已知限制

当前 `AolaThemeRequestHandler` 仍聚合全部规则、探测、缓存、回退和 Cef 响应处理。

