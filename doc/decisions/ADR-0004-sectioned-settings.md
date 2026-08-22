# ADR-0004：设置采用独立版本 Section

Status: Accepted  
Date: 2026-08-21

## 背景和问题

当前 SchemaVersion 5 DTO 同时拥有主题与形态字段。任一功能新增设置都修改共享类和统一版本，形成多人开发热点，也无法独立迁移损坏 Section。

## 决定

采用 `DocumentVersion: 1` 与 `Sections` 容器；`theme`、`petMorph`、`battle` 各自拥有 `Version`、DTO、默认值、验证和迁移。存储按 key 读取/原子保存单 Section，并尽量保留未知 Section/字段。提供一次性 SchemaVersion 5 migrator。

## 放弃的替代方案

- 继续扩展统一 DTO：冲突与版本膨胀持续存在。
- 每模块独立文件：原子性简单但配置发现、备份和未知模块协作较差。
- 迁移时丢弃未知字段：会阻止模块独立升级。

## 影响的模块

Settings、Theme、PetMorph、Battle、AppShell。

## 兼容及迁移

先完成无写入的读取/迁移验证，再迁移 Theme、PetMorph，最后建立默认 Battle Section。新格式成功原子落盘前保留旧文件；禁止长期双写。失败返回模块默认值和诊断，不覆盖旧文件。

