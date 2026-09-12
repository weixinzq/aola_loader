# 架构决策索引

当前正式 ADR 保存在 `doc/decisions/`。本目录只提供架构阅读入口，不复制正文，避免两份决策记录漂移。

| ADR | 决策 | 当前作用 |
| --- | --- | --- |
| [ADR-0001](../../decisions/ADR-0001-module-boundaries.md) | 以单项目逻辑模块建立边界 | 解释为何 AolaLoader 仍是一个宿主项目，以及何时才值得拆程序集 |
| [ADR-0002](../../decisions/ADR-0002-resource-rule-pipeline.md) | 浏览器资源使用有序规则管线 | 约束 priority、path ownership、冲突和失败放行 |
| [ADR-0003](../../decisions/ADR-0003-host-event-adapter.md) | 静态 IPC 事件由宿主适配器单点订阅 | 阻止 Contracts 静态事件向 feature/UI 扩散 |
| [ADR-0004](../../decisions/ADR-0004-sectioned-settings.md) | 设置采用独立版本 Section | 规定 store 与 feature codec 的所有权 |

## 何时新增 ADR

以下变化需要 ADR，而不是只改模块规格：

- 新增或改变进程、程序集、网络连接或信任边界。
- 改变依赖方向，例如让 Hook 引用宿主功能。
- 改变生产发送路径或重新启用 sidecar/第二连接。
- 改变资源冲突/失败默认策略。
- 改变 settings 文档所有权或拆分方式。
- 用新的长期机制替代当前页面桥、IPC 或 CEF 承载。

局部字段、UI 文案、单个规则 URL 或缺陷修复通常只更新模块规格和测试，不需要 ADR。

## ADR 最小结构

```text
# ADR-NNNN：标题

## 状态
提议 / 接受 / 废弃 / 被替代

## 背景和问题
需要长期决定的约束与证据。

## 决定
选择什么，以及明确不选择什么。

## 放弃的替代方案
列出真正考虑过的方案和原因。

## 影响的模块
依赖方向、迁移、兼容和验证要求。
```

新增后同时更新本索引；若替代旧 ADR，在新旧两份文件中互相链接，不删除历史决策。

