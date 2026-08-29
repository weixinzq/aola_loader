# ResourceInterception

Status: Implemented
ContractVersion: 1  
OwnerPaths: `analysis/AolaLoader/ResourceInterception/**`

## 职责

把 Cef 请求适配为框架无关上下文，按稳定顺序评估规则，执行本地响应/远程转换、精确探测、受界缓冲、响应转换和官方资源回退。

## 非职责

不拥有 Theme/PetMorph/Battle 业务规则，不读整个设置文档，不操作 Form，不发送服务器状态命令。

## 公开契约

`IResourceInterceptionRule.Evaluate(ResourceRequestContext)` 返回 `PassThrough`、`LocalResponse` 或 `RewriteRemote`；`ResourceRulePipeline` 采用首个非放行计划；`IRemoteResourceProbe`、`IResourceResponseTransformer` 和不可变 plan/result 表达 I/O。规则不可直接修改 Cef 请求或创建 handler。

优先级区间冻结为：`1000..1099` 用于受版本/哈希约束的精确桥接与本地补丁，`800..899` 用于主题叶资源，`600..699` 用于背包、海报和战斗模型等功能叶资源。其他值未经 ADR 不得占用；同优先级多规则命中必须诊断并放行。

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

`AolaSocketHack.Verify --self-test` 当前验证请求规范化/内部标记、计划不变量和防御性内容、关闭放行、优先级命中、近似 URL、重写/回退递归防护、同优先级冲突放行、规则异常回退、非 2xx、受界输入/输出、转换异常、SWF FWS/CWS/ZWS 头约束、探测 TTL、远程探测/完整抓取/转换执行，以及 Theme、Pet package、PetMovie、Poster 规则的默认放行、精确 host/path/method、版本锁、类契约、标记和回退计划。

## 完成标准

Theme、PetMorph 现有分支全部成为独立规则；入口只做适配/管线执行；默认与替换 Flash 路径实测通过。

## 已知限制

框架无关 `ResourceRulePipeline`、受界响应处理、SWF 头验证、HTTP 探测/抓取、TTL 缓存和 Cef 适配均已实现；Theme、Pet package、PetMovie 与 Poster 是独立规则。Pet package 只精确替换当前 `newpetpackage~2026082731219998.swf`，模板同时保留既有形态桥并提供 `aolaSendCommand` 与本地面板入口 `aolaOpenPanel`；版本变化时放行官方资源并使桥调用失败关闭。纯算法位于 `ResourceInterception/Transformers`，Cef 入口位于 `ResourceInterception/Cef`。当前模板须通过 FWS 长度、SHA-256、FFDec 复读和 SymbolClass 静态检查，PPAPI Flash 运行验证仍单独执行。
