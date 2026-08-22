# ADR-0003：静态 IPC 事件由宿主适配器单点订阅

Status: Accepted  
Date: 2026-08-21

## 背景和问题

Contracts 的静态事件被 logger、Battle tracker、PacketsForm 和主窗体直接订阅，依赖隐式，测试替换困难，消费者异常可影响同一发布调用链。

## 决定

保留跨进程兼容的 `AolaHookHostService`，新增 `AolaHookHostAdapter : IAolaPacketEventSource` 作为唯一静态订阅点。适配器逐订阅者隔离异常、转发结构化发送，并在 Dispose 后停止发布。UI 自行 marshal。

## 放弃的替代方案

- 直接修改 remoting 服务为实例事件：破坏注入端兼容边界。
- 引入全局事件总线：扩大抽象且不能表达现有安全边界。
- 由每个消费者继续订阅：无法替换测试或集中生命周期。

## 影响的模块

PacketHost、日志、Battle state、Packets UI、AppShell、Contracts。

## 兼容及迁移

依次迁移 logger、tracker、PacketsForm、主窗状态；各步验证退订和线程切换。全部迁移后加源码守卫，Contracts 静态 API 暂留给适配器/IPC 初始化。

