# 依赖关系

## 项目级依赖

```text
AolaLoader ───────────────┬──> AolaSocketHack.Contracts
                          └──> AolaSocketHack
                                      └──> AolaSocketHack.Contracts

AolaSocketHack.Verify ────┬──> AolaSocketHack
                          ├──> AolaSocketHack.Contracts
                          └──> linked AolaLoader source files
```

`AolaLoader → AolaSocketHack` 是构建/部署依赖，方便把注入 DLL 带到输出目录；运行时应用功能不应直接调用 Hook 内部类。

## 宿主允许的主方向

```text
Program
  → AppShell composition
      → UI
      → feature coordination
          → narrow contracts
              → adapters / infrastructure

UI → Feature coordinator / state contract
Feature → BrowserHost contract | PacketHost contract | Settings contract
Feature resource rule → ResourceInterception contracts
ResourceInterception CEF adapter → pipeline contracts/implementation
PacketHost adapter → AolaSocketHack.Contracts
```

## 核心依赖矩阵

| 消费方 | 依赖目标 | 原因 | 依赖形态 |
| --- | --- | --- | --- |
| AppShell | 所有宿主模块 | 装配与窗口编排 | 具体类型 + 窄接口 |
| BrowserHost | CefSharp | 浏览器和脚本执行 | 框架适配 |
| PacketHost | Contracts | IPC DTO/事件 | 稳定跨进程契约 |
| ActiveSend | `IPageBridge` | 复用 Flash 原连接 | 接口 |
| Battle.State | `IAolaPacketEventSource` | 聚合接收包 | 接口 |
| Battle.Replay | packet source + command sender + BattleBridge | 方向证据、提交、输入就绪 | 三个窄入口 |
| Battle.Presentation | Settings + BattleBridge + morph target | 保存、页面应用、资源激活 | 接口/具体 client |
| Lineup | packet source + command sender + battle state | 请求/响应闭环和空闲门 | 三个窄入口 |
| Theme/PetMorph | Settings + resource targets | 模块设置与规则激活 | 接口 |
| Resource handler | 所有 feature resource rules | 单个 CEF RequestHandler 注册点 | 具体规则聚合 |
| Verify | Hook 项目 + linked host source | 自测和源码守卫 | 项目引用 + 源码链接 |

## 外部依赖

| 依赖 | 使用位置 | 架构约束 |
| --- | --- | --- |
| CefSharp 87.1.132 | BrowserHost、resource adapter、WinForms | CEF 初始化/关闭只能是进程级；回调线程不可假设为 UI 线程 |
| PPAPI Flash | 页面游戏运行时 | 本地 DLL 缺失时项目可编译但程序不能启动 |
| EasyHook 2.7.7097 | Hook controller、注入 DLL | x64 一致；Hook 回调必须轻量 |
| Newtonsoft.Json 13.0.4 | 设置、协议参数、页面桥、功能数据 | 跨层 JSON schema 需要显式版本/严格字段验证 |
| SharpCompress 0.50.4 | SWF 资源处理与 Verify | 不应渗透到 UI 或 packet 领域模型 |
| WMI/System.Management | 主窗体进程发现 | 失败时只能等待/提示，不能假设 network PID 固定 |
| 官网与资源 CDN | 页面、官方 SWF、远端目标资源 | 网络不可用或验证失败时资源替换应放行官方链路 |

## 资源规则优先级

pipeline 只接受保留区间 `1000..1099`、`800..899`、`600..699`。当前关键规则：

| 优先级 | 规则 | 路径所有权 |
| ---: | --- | --- |
| 1000 | ActiveSend start bridge | 特定 start SWF |
| 850 | Battle petfight bridge | 清单指定的唯一 petfightnew 版本 |
| 800 | Theme controlbar | controlbar skin 叶子资源 |
| 699 | PetMorph package live | newpetpackage 特定资源 |
| 698 | PetMorph movie | pet movie 叶子资源 |
| 697 | PetMorph poster | poster/background 叶子资源 |
| 697 | Battle pet movie | fightassets pet 六分片 |

同优先级不是自动“后注册覆盖前注册”。只要同一请求有多个有效匹配，pipeline 就返回冲突并放行原请求。因此路径所有权必须互斥。

## 禁止方向

- `AolaSocketHack` → `AolaLoader.*`、CefSharp、WinForms 或 Settings。
- feature/parser → `AolaMainForm`。
- UI → Hook 内部协议、Winsock 或 Remoting 静态事件。
- 通用 `ResourceRulePipeline` → Theme/PetMorph/Battle 具体规则。
- ActiveSend → `AolaCaptureEngine.TryGetSendContext` 或 `AolaSidecarSender`。
- 一个 settings codec → 任意改写其他模块 section。
- 生产宿主 → `analysis/reverse-engineering/`、`evidence/` 或工具输出临时目录。

## 依赖热点

1. `AolaCompositionRoot` 对具体实现的高扇出是预期的装配耦合，应集中而不能扩散。
2. `AolaResourceRequestHandler` 同时实现 Theme、PetMorph、Battle 的 target 接口，是资源功能的集中适配热点。
3. `AolaMainForm` 同时依赖 Chromium 具体控件、多个 coordinator、packet source、logger 和 Hook controller，是 UI 编排热点。
4. `AolaSocketHack.Verify.csproj` 链接大量宿主源码，是物理文件级耦合热点。

