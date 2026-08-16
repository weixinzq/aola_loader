# Aola Loader 架构

## 设计边界

Aola Loader 只承载旧版奥拉星的登录、发送包查看/导出、独立连接发包、接收日志、对战数据展示、末端主题 SWF 替换，以及背包模型/海报的远程资源形态替换。`analysis/loader` 是保留的独立 Python 多账号实现，不参与桌面主程序的进程内数据流。

运行栈固定为 Windows x64、.NET Framework 4.8、CefSharp 87、PPAPI Flash 和 EasyHook。它是受控的遗留兼容环境，不是通用浏览器。

当前形态变化功能只作用于背包模型和已知海报资源，不改写战斗内模型，不发送服务器状态命令，也不使用本地亚比资源作为回退。规则只保存在当前进程内存中，重启后需要重新录入。

## 项目结构

```text
analysis/
├─ AolaLoader/                  WinForms/CEF/Flash 宿主与全部桌面 UI
│  ├─ AolaMainForm             主窗口、功能入口、浏览器与注入生命周期
│  ├─ AolaDynamicRequestHandler 主题本地响应 + 形态远程 URL/响应拦截
│  ├─ AolaSwfResponseFilter    远程 FWS 缓冲、类名等长适配
│  ├─ AolaSwfBitmapScaler      已知背包模型的位图/坐标尺寸补偿
│  ├─ AolaPetMorphForm/Rule    F2 形态变化规则 UI 与内存模型
│  ├─ AolaPacketsForm          发送包查看、导出与主动发送
│  ├─ AolaReceiveLogger        接收 JSONL 日志
│  └─ AolaBattle*              对战解析、状态合并与 F3 助手
├─ AolaSocketHack/             注入载荷、Winsock Hook、协议与独立连接发送
├─ AolaSocketHack.Contracts/   宿主/注入进程共享的 IPC DTO 与服务
├─ AolaSocketHack.Verify/      PCAP 回放和主动发送验证器
├─ loader/                     保留的独立 Python 多账号加载器
├─ runtime/                    固定版本 EasyHook 与 PPAPI Flash 运行文件
├─ tools/                      分析及主题准备工具
├─ reverse-engineering/        SWF、包与运行验证证据
├─ build/                      统一编译输出
└─ obj/                        统一中间输出
```

源码文件名 `AolaDynamicRequestHandler.cs` 中的处理器类型仍名为 `AolaThemeRequestHandler`，以保持现有主窗体接线不变；它现在实际承载主题和形态变化两条资源链路。

## 运行拓扑

```text
AolaLoader.exe
├─ AolaMainForm
│  ├─ ChromiumWebBrowser ───────────────> https://aola.100bt.com
│  │  └─ AolaThemeRequestHandler
│  │     ├─ 主题链路 ───────────────────> 可选的末端 skinN.swf 本地响应
│  │     └─ 形态链路 ───────────────────> 官方模型/海报 URL + 响应适配
│  ├─ AolaPetMorphForm (F2) ────────────> 内存规则：原型/背包/海报 ID
│  ├─ AolaPacketsForm ──────────────────> 仅显示发送、Inner 明文、导出与发包
│  ├─ AolaReceiveLogger ────────────────> logs/aola-recv-*.jsonl
│  ├─ AolaBattleStateTracker
│  │  └─ AolaBattlePacketParser ────────> 2303/2304 roster + 战斗增量
│  ├─ AolaBattleAssistantForm ──────────> 敌我完整背包与最终数值
│  └─ AolaHookController
│     └─ EasyHook IPC
└─ CefSharp.BrowserSubprocess.exe --type=network.mojom
   └─ AolaSocketHack.dll
      ├─ WinsockHooks
      ├─ AolaCaptureEngine
      ├─ AolaProtocol + AMF3 Reader/Writer
      └─ AolaSidecarSender ─────────────> 独立游戏 TCP 连接
```

`AolaSocketHack.Contracts` 定义两进程共享的 DTO 和 IPC 服务。`AolaSocketHack.Verify` 使用相同协议实现回放 PCAP，并验证主动发包的编码/本地回读。

## 初始化与注入

1. `AolaMainForm` 初始化 CefSharp、磁盘缓存、PPAPI Flash 与统一浏览器请求处理器；处理器启动时只预载本地主题模板，不预载亚比模型或海报。
2. 主窗口打开 `https://aola.100bt.com/play/play.html`，并保留旧页面需要的 1×1 心跳兼容处理。
3. `AolaHookController` 周期性查找命令行含 `--type=network.mojom` 的 CefSharp 子进程。
4. EasyHook 将 `AolaSocketHack.dll` 注入该网络进程，并建立 IPC。
5. 注入端安装 `send`、`WSASend`、`recv`、`WSARecv`、`connect` 和 `closesocket` Hook。

Hook 回调只复制有界数据并写入有界队列；后台线程按 socket 重组 TCP 帧并解析。单次复制上限为 16 MiB，主机侧待发队列也保持有界，避免在网络 Hook 内执行阻塞工作。

## 抓包与显示数据流

```text
Winsock bytes
  -> 按 socket 的 TCP 重组
  -> 外层帧识别/解密
  -> AMF3 wrapper
  -> Inner swap/XOR 解密
  -> Inner AMF3 参数
  -> IPC PacketRecord
       ├─ direction == 发送 -> AolaPacketsForm
       └─ direction == 接收 -> logger + battle tracker
```

发送窗口有意过滤所有非“发送”事件。EXT 记录只公开解密后的参数和 `InnerPlainHex`，不把加密 `RawHex` 放回详情面板。登录帧在协议事件中始终脱敏。

接收方向不会出现在表格中；`AolaReceiveLogger` 将每条消息写成 UTF-8 无 BOM 的 JSONL，包含本地/UTC 时间、进程、socket、命令、AMF3 参数和接收帧 HEX。日志文件位于可执行文件旁的 `logs/` 目录，从程序开始记录到退出或 logger 释放，不以“进入战斗”为起点。

## 导出与主动发包

导出格式是严格的单行 Loader 记录：

```text
#send={"id":42,"param":{},"cmd":"CMD"}|
```

主动发包流程：

1. UI 解析粘贴或文件中的 `#send`，校验 `id`、`param` 和 `cmd`，移除用户输入的 `:ext_seq;`。
2. IPC 只传结构化请求；账号、密码、SID 和原始登录帧不会进入请求或界面。
3. 注入端从当前连接状态克隆已捕获的登录帧，连接同一游戏端点并完成独立登录。
4. 独立连接生成自己的 OuterSeq，并按 extension ID 隔离 InnerSeq。
5. 参数经 AMF3、Inner swap/XOR、外层包装/XOR 后发送。
6. 发出的帧再由相同解析器本地回读；只有能正确解码和导出的帧才报告为主动发送成功。

独立连接避免改变浏览器连接的序列状态。保存的登录字节只存在于注入进程内存，并在 socket 关闭或组件释放时清除。

## 对战助手

`AolaBattleStateTracker` 只消费接收事件。`AolaBattlePacketParser` 当前识别 `2303`、`2304`、`2401`、`2426`、`2411`、`2404` 和 `2309`：

- `2303` 开始新的 roster 快照；`2304` 提供完整背包数据。
- 如果 `2401` 在十秒内紧随兼容的 roster，tracker 保留该完整列表并进入战斗状态。
- 宠物优先按唯一 ID（UQI）合并，再按战斗槽位合并，避免把同队在场/后备数据拆成不同对象。
- `ea0` 至 `ea5` 的片段在解析层求和为攻击、防御、特攻、特防、速度等最终值；UI 不显示加法过程或变化历史。
- 后续命令更新 HP、上场状态和事件摘要；结束命令关闭当前战斗状态。

`AolaBattleAssistantForm` 分敌方/己方标签页显示所有已解析亚比，而不是只显示当前在场对象。每张卡片包含名称、HP、等级、性格、槽位和技能 PP/CD；底部摘要一行展示每只亚比的最终数值。窗口晚于战斗打开时读取 tracker 的缓存快照。当前头像提供器生成基于名称/View ID 的占位图，不参与战斗数据正确性判断。

## 浏览器资源拦截

`AolaThemeRequestHandler` 只处理 `aola.100bt.com` 下经过精确路径识别的末端 SWF。主题替换与形态变化共享 CefSharp 接入点，但资源来源、失败策略和响应处理不同。

### 主题资源替换

主题菜单选择的是本地 HTTP/SWF 响应替换，不是向服务器发送 `UiSkinStyle240927` 状态命令。

```text
Flash 请求 /play/control/controlbarskin/skinN~version.swf
  -> AolaThemeRequestHandler 校验 host/path/file name
  -> 读取 Resources/Themes 中已验证的 FWS 模板
  -> 将等长 Skin<selected> 标记适配为调用方要求的 SkinN
  -> application/x-shockwave-flash 响应
```

“默认”将选择值设为无拦截，并用绕过缓存的方式刷新页面。处理器只接受 FWS 模板，只有唯一且等长的导出类标记存在时才修改副本；原模板不被覆盖。

这个适配是必要的：游戏按 `mmo.controlv2.controlbarskin.skin.SkinN` 查找类，`skin0.swf` 与 `skin1.swf` 分别导出 `Skin0` 与 `Skin1`，直接交换二进制会破坏类名契约。反编译结果还显示控制栏处理器会缓存已经加载的 skin，因此同一进程内关闭再打开界面不保证重新发起 HTTP 请求。

### 背包模型与海报形态替换

F2“功能面板”按原型 ID 保存一条规则，背包替换 ID 和海报替换 ID 至少填写一个。启用或修改规则后，主窗口执行绕过 CEF 缓存的页面刷新。当前规则约束如下：

- 背包动态模型只接收不小于 `4400` 的 ID；原型与目标 ID 必须位数相同，以保证导出类名能够等长修改。
- 背包路径只匹配 `petmovie<ID>/petmovie<ID>_<part>~version.swf`，其中 `part` 为 `0..3`。
- 海报 UI 输入的是皮肤 ID；当前证据只建立了 `5487 -> Background733` 和 `5940 -> Background984` 两组映射。
- 同一原型只保留一条规则；面板关闭时只是隐藏窗口，规则仍存在于当前进程。
- 战斗内替换没有接线，形态规则不会修改战斗请求或对战状态数据。

背包模型的数据流：

```text
Flash 请求 petmovie<原型>/<原型>_<part>~version.swf
  -> 按原型 ID 查找已启用规则
  -> 保留 host、版本后缀和原查询，路径改为 petmovie<目标>/<目标>_<part>
  -> 添加 _aolaMorph=m-<原型>-<目标>-<part> 标记
  -> Range 0-7 预检官方目标：必须为 FWS，声明长度与总响应长度一致
  -> CEF 正常请求官方目标 SWF（可继续使用 CEF 网络/磁盘缓存）
  -> AolaSwfResponseFilter 收集完整响应并再次校验 FWS/声明长度
  -> 等长修改 PetMovie<目标> 为 PetMovie<原型>
  -> 必要时执行模型尺寸补偿
  -> 将适配后的 SWF 交给原 Flash 加载器/ApplicationDomain
```

海报链路相同，但先把皮肤 ID 映射成 `Background` 资源 ID，再重写 `petskinbackground<ID>~version.swf`，并将 `Background<目标资源>` 等长适配成 `Background<原型资源>`；海报当前不做尺寸补偿。

`_aolaMorph` 标记用于在 CefSharp 对改写 URL 再次选择处理器时重建同一计划，避免把目标请求误当成一条新规则。若预检判定目标资源不可用，第一次请求保持原 URL；若目标响应为非 2xx，则通过 `_aolaMorphFallback=1` 重新请求原始官方资源，并让该次请求绕过形态拦截。可用预检缓存十分钟，不可用结果缓存三十秒。

这里的“回退”只覆盖目标资源预检失败和 HTTP 非成功响应。若服务器返回了看似成功但类契约、FWS 长度或内部结构不符合适配前提的内容，响应过滤器会拒绝输出；当前实现不会在过滤失败后再启动第二次原资源请求，以免把未经验证的字节交给 Flash。

### 模型尺寸补偿

背包调用方会根据原型 View ID 在 SWF 外层应用额外比例。已从 `PetIconConfig` 确认：`5980/5998/5997/6007` 使用 `0.4`，`6000/5994/5995/6044` 使用 `0.3`，其他已知 ID 默认为 `1`。替换后仍按原型 ID 取比例，因此响应适配使用：

```text
内部补偿比例 = 目标 ID 的外层比例 / 原型 ID 的外层比例
```

例如 `6000 -> 6025` 的补偿比例为 `1 / 0.3`。`AolaSwfBitmapScaler` 只处理已验证的 FWS 叶子模型，支持 `DefineBitsLossless2` 格式 3/5：解压 zlib 位图、使用最近邻调整像素、同步 `MovieConfig` 坐标与 ABC 整数池中的位图尺寸，再重建标签和 SWF 声明长度。输入响应上限为 16 MiB，输出上限为 64 MiB，单个位图解压结果上限为 128 MiB；任何越界或结构歧义都会拒绝变换。

该补偿的四个 `6025` 分片已经通过 FWS 长度检查和 FFDec 重新读取；`6000 -> 6025` 的最终显示尺寸仍属于真实 Flash 运行验证项，不能仅凭静态检查视为完成。

## SWF、缓存与依赖层

分析资源时按下列层次建立证据：

1. 从网络 URL/CEF 缓存索引确认请求身份。
2. 用长度、时间、FWS/CWS/ZWS 文件头、SHA-256 和内部字符串交叉确认缓存内容；`f_00011c` 一类文件名本身没有资源语义。
3. 校验 SWF 声明长度。ZWS 使用 SWF 的 LZMA 布局，压缩长度字段应匹配偏移 17 后的压缩数据，解压主体长度加 8 应等于声明长度。
4. 使用 JPEXS FFDec CLI 导出 ActionScript 和资源，检查文档类、导出类、`SymbolClass`、实例名、资源 URL/版本拼接、方法调用链与跨 SWF 加载。
5. 检查 Flash `ApplicationDomain` 的类查找与缓存行为，以及 CEF 内存缓存、CEF 磁盘缓存和 Flash 加载器缓存的差异。

缓存影响决定验证方式：资源拦截改变后至少绕过 CEF 缓存刷新页面；若类已进入 `ApplicationDomain`、模型分片已被 Flash Loader 保留，或模块有自己的 `_skinList`，可能需要清缓存或重启整个进程。形态链路的预检缓存、CEF 内存缓存、CEF 磁盘缓存与 Flash/ApplicationDomain 缓存是四个不同层次，不能用其中一层的命中证明另一层已经更新。

## 变更与验证边界

每个用于分析的原始 SWF 都必须保留，修改产物另存并记录哈希。优先替换 `skinN.swf`、`petmovie*.swf` 和 `petskinbackground*.swf` 这类末端资源，避免修改 `materialservice.swf`、`materialdata.swf`、`controlv2.swf` 或 `interfaces.swf` 等启动/共享核心模块。当前模型尺寸修复选择修改返回的叶子模型位图，没有修改定义外层缩放规则的 `interfaces.swf`。

验证分为三层：

1. 结构层：文件头、声明/压缩/解压长度和哈希正确。
2. 静态层：FFDec 能重新读取，目标包/类/方法、`SymbolClass` 和必要实例名仍存在。
3. 运行层：先验证默认/无替换启动，再验证替换、切换、关闭重开和新进程加载。

三层不能互相替代。已有 `materialservice.swf` 修改候选能被 FFDec 回读且 C# 项目能编译，但 Flash 实际启动卡在 `1/11`；因此命令返回 0 或宿主编译成功不能证明 SWF 可加载。发生运行回归时，应保留候选、哈希、反编译输出、日志和截图作为证据，立即恢复默认路径并停止覆盖。

## 构建产物与验证器

`analysis/Directory.Build.props` 将项目产物统一写入 `analysis/build/<Project>/<Configuration>/net48/`，中间文件写入 `analysis/obj/`。主程序为：

```text
analysis/build/AolaLoader/Release/net48/AolaLoader.exe
```

主要验证入口：

```powershell
dotnet build .\analysis\AolaLoader\AolaLoader.csproj -c Release
dotnet build .\analysis\AolaSocketHack.Verify\AolaSocketHack.Verify.csproj -c Release
dotnet run --project .\analysis\AolaSocketHack.Verify\AolaSocketHack.Verify.csproj -c Release --no-build -- D:\Programs\Wireshark\tshark.exe .\analysis\loader\mt250816_full_anyserver.pcapng 2
```

PCAP 当前基线为 172 条发送帧、423 条接收帧、1 条 policy、164 条可导出、0 条解析失败，并要求登录脱敏、Inner 明文、导出格式和主动发包回读均为真。
