# 阶段 3：Poster 叶资源规则迁移

本批次把海报背景 `petskin/background` 的目录映射、URL 选择和结构化类适配迁入 `PetPosterResourceRule`。规则使用只读目录和防御性规则快照，精确命中官方 host、GET 与资源路径后生成 16 MiB 受界远程计划；共享执行器先探测、再完整抓取和转换，任何失败均放行原始官方请求。

`AolaThemeRequestHandler` 现只负责注册 Theme、Pet package、PetMovie、Poster 四条规则并转发快照；旧远程重写、标记回流、探测缓存、响应过滤和 Poster 分支已从请求入口删除。实时海报可用性查询复用同一个 TTL 探测器。

静态复核使用 `poster-background984.swf` 原件和 `poster984-as-733.swf` 候选。候选为 FWS 18，文件大小与声明长度均为 1,175,503 字节；FFDec 成功复读 `mmo.petskin.view.Background733` 与 `SymbolClass`，与原件相比解码体长度一致且只有 9 个字节差异。证据位于 `analysis/reverse-engineering/pet-fd-replacement-20260816/evidence/verify-poster-stage3/run-20260822-113711-021220-14920/`。这仍不代表真实 Flash 可加载，运行时验证尚未完成。
