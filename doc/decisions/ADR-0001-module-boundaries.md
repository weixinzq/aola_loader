# ADR-0001：以单项目逻辑模块建立边界

Status: Accepted  
Date: 2026-08-21

## 背景和问题

宿主源码平铺，主窗体和处理器承担过多职责，但项目固定在 .NET Framework 4.8，存在大量 internal 类型、统一输出与遗留依赖。立即拆程序集会把边界迁移与构建迁移混在一起。

## 决定

第一轮保留 `AolaLoader.csproj`，先按 AppShell、BrowserHost、Settings、PacketHost、ResourceInterception、Features 和 UI 建立目录、契约及所有权。迁移初期可暂留 `namespace AolaLoader`，随后逐模块调整命名空间。

## 放弃的替代方案

- 全面重写：行为与遗留 Flash 风险过高。
- 立即拆分 Core/WinForms/ResourceInterception 程序集：会同时引入可见性、依赖复制和输出布局变化。
- 仅整理目录不定义契约：不能阻止依赖重新扩散。

## 影响的模块

全部宿主模块；SocketHack 和 Contracts 保持现有进程边界。

## 兼容及迁移

先冻结 ContractVersion 1，再逐批迁移且每批构建/验证。只有边界稳定、测试能阻止错误依赖时，才另行 ADR 评估程序集拆分。

