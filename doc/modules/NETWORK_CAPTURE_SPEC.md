# NetworkCapture

Status: Implemented
ContractVersion: 1  
OwnerPaths: `analysis/AolaSocketHack/Hooking/**`, `analysis/AolaSocketHack/Transport/**`

## 职责

Hook Winsock、快速分类游戏 socket、有界复制入队、按 socket 重组 TCP、发布指标并在关闭时清理状态。

## 非职责

不执行 UI/磁盘/阻塞网络工作，不解释功能业务，不持久化登录材料，不处理宿主设置。

## 公开契约

内部边界由捕获项、连接清理项和重组输出构成；协议层只接收完整候选帧。诊断提供聚合计数而非逐包阻塞通知。

## 输入与输出

输入为 `send/WSASend/recv/WSARecv/connect/closesocket` 数据；输出为有方向、socket/进程上下文的完整帧及限频指标。

## 允许依赖

EasyHook 仅限 Hooking、Winsock native、线程安全有界集合和 Protocol 帧边界识别。

## 禁止依赖

AolaLoader、WinForms、CefSharp、设置、日志文件和功能模块。

## 线程与生命周期

Hook 回调只复制至多 16 MiB 并 `TryAdd` 到 4096 项队列。后台 worker 解析；`closesocket`/空闲/Dispose 清除连接与敏感状态。

## 异常及回退语义

队列/重组越界只丢分析副本并计数，不阻塞、关闭或修改游戏 socket；单连接异常不得中止其他连接。

## 设置所有权

无。`AOLA_CAPTURE_ALL_SOCKETS=1` 仅是诊断开关，不进入持久设置。

## 安全约束

登录帧只能交给注入端受控发送状态；不得随捕获 DTO 发布。独立 sidecar socket 必须排除。

## 缓存语义

每连接双向重组缓存合计最多 16 MiB，策略探测最多 64 KiB；缓存按 socket 生命周期拥有并清零。

## 验证入口

碎片/粘包、多 socket、端口分类、队列满、缓存上限、关闭清理、sidecar 排除及 PCAP replay。

## 完成标准

保持当前性能/边界与全部 PCAP 字段，模块目录和依赖守卫建立，宿主重构不引入回调阻塞。

## 已知限制

捕获实现与独立项目边界已完成审计。阶段 9 已在真实登录、抓包、日志、独立发包和战斗中验证运行路径；PCAP 继续覆盖碎片/粘包、分类、边界、清理和 sidecar 排除。
