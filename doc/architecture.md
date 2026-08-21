# Aola Loader 架构

## 设计边界

Aola Loader 只承载旧版奥拉星的登录、发送包查看/导出、独立连接发包、接收日志、对战数据展示、末端主题 SWF 替换，以及背包模型/海报的远程资源形态替换。`analysis/loader` 是保留的独立 Python 多账号实现，不参与桌面主程序的进程内数据流。

运行栈固定为 Windows x64、.NET Framework 4.8、CefSharp 87、PPAPI Flash 和 EasyHook。它是受控的遗留兼容环境，不是通用浏览器。

当前形态变化功能只作用于背包模型和已知海报资源，不改写战斗内模型，不发送服务器状态命令，也不使用本地亚比/海报资源作为回退。主题选择、形态规则与启用开关通过可执行文件旁的 `settings.json` 持久化，启动时自动恢复；主题变更仍需手动刷新，形态规则通过 JS↔Flash 桥接热推送并刷新当前背包，不刷新登录器、不清空全局 CEF 缓存。

## 项目结构

```text
analysis/
├─ AolaLoader/                  WinForms/CEF/Flash 宿主与全部桌面 UI
│  ├─ AolaMainForm             主窗口、功能入口、浏览器与注入生命周期
│  ├─ AolaFormBase             所有窗口基类：激活即置顶、子窗口非属主显示
│  ├─ AolaSettings             settings.json 设置持久化（主题/形态规则/启用开关）
│  ├─ AolaDynamicRequestHandler 主题本地响应 + 形态远程 URL/响应拦截
│  ├─ AolaSwfResponseFilter    远程 SWF 缓冲、校验与适配分派
│  ├─ AolaSwfClassAdapter       海报 FWS/CWS 结构化类名适配
│  ├─ AolaSwfBitmapScaler      背包模型位图/坐标尺寸补偿与透明化
│  ├─ AolaPetPosterCatalog      完整 Background 目录加载与校验
│  ├─ AolaPetMorphForm/Rule    F2 形态变化规则 UI 与内存模型
│  ├─ AolaPetMorphLiveBridge    页面内规则表、JS→Flash 刷新与版本状态
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
│  │     └─ 形态链路 ───────────────────> 中性背包桥接模块 + 官方模型/海报 URL 响应适配
│  ├─ AolaPetMorphForm (F2) ────────────> 内存规则：模型/海报 ID + 隐藏原模型
│  ├─ AolaPetMorphLiveBridge ───────────> window 映射表 + aolaMorphRefresh
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

## 窗口层级与设置持久化

### 点击置顶

所有窗口继承 `AolaFormBase`。子窗口（抓包/对战助手/功能面板）不再使用 `Show(this)` 属主关系，否则 Windows 的“被属主窗口永远位于属主之上”规则会让主窗口无法点击置顶。窗口被激活时，基类通过临时置顶（`SetWindowPos` 先 `HWND_TOPMOST` 再 `HWND_NOTOPMOST`，均带 `SWP_NOACTIVATE`）把该窗口带到普通层最上方；因此点击哪个窗口，哪个窗口就处于最上层，且不永久置顶、不抢焦点。

主窗口最小化时同步隐藏可见子窗口，还原时以 `SW_SHOWNOACTIVATE` 恢复，避免焦点被抢走，保持与原先属主窗口一致的最小化行为。

### settings.json

程序启动时读取可执行文件旁的 `settings.json`（`AolaSettingsStore`，UTF-8 无 BOM）：

```json
{
  "SchemaVersion": 5,
  "SelectedThemeId": 0,
  "PetMorphEnabled": false,
  "PetMorphLiveBridgeEnabled": true,
  "PetMorphRules": [
    {
      "Note": "poster example",
      "OriginalId": 0,
      "BackpackId": 0,
      "PosterSourceId": 5487,
      "PosterId": 5940,
      "RemoveOriginalBackground": false,
      "ReplaceBackpackIcon": false,
      "HideOriginalModel": false
    }
  ]
}
```

- `SelectedThemeId`：0 表示默认（无拦截），1..9 为本地主题模板。
- `PetMorphRules`：形态规则（备注/模型源 ID/模型目标 ID/海报源皮肤 ID/海报目标皮肤 ID/移除原背景/替换背包头像/隐藏原模型）；旧设置缺少三个布尔字段时均按 `false` 加载。
- `PetMorphLiveBridgeEnabled`：动态背包桥接的手动回退开关，默认 `true`；设为 `false` 后不拦截 `newpetpackage`，用于在实机回归时立即恢复官方模块（重启程序后生效）。
- 文件缺失、损坏或字段非法时回退默认值，不阻断启动。
- 更换主题或修改形态规则时立即保存；主题变更需手动刷新页面，形态规则变更只更新页面内映射并触发当前背包重绘。

## 初始化与注入

1. `AolaMainForm` 先加载 `settings.json`，在浏览器创建前把主题选择与形态规则应用到统一处理器，再初始化 CefSharp、磁盘缓存、PPAPI Flash 与浏览器请求处理器；处理器启动时预载本地主题模板和经验证的中性背包桥接模板，但不预载亚比模型或海报资源。
2. 主窗口打开 `https://aola.100bt.com/play/play.html`，保留旧页面需要的 1×1 心跳兼容处理，并注入 `aolaMorphResolveSkinId`、`aolaMorphShouldHideBackground`、`aolaMorphResolveIconId`、`aolaMorphBridgeReady` 与页面内三组规则状态。`flashHeartBeat` 仍只是 Flash→JS 的存活探测；形态热更新使用独立的双向 `ExternalInterface` 桥接。
3. `AolaHookController` 周期性查找命令行含 `--type=network.mojom` 的 CefSharp 子进程。
4. EasyHook 将 `AolaSocketHack.dll` 注入该网络进程，并建立 IPC。
5. 注入端安装 `send`、`WSASend`、`recv`、`WSARecv`、`connect` 和 `closesocket` Hook。

Hook 回调只复制有界数据并写入有界队列；后台线程按 socket 重组 TCP 帧并解析。单次复制上限为 16 MiB，主机侧待发队列也保持有界，避免在网络 Hook 内执行阻塞工作。

捕获快速路径在复制负载前按 socket 分类：`connect` 目标端口 `8000..8100` 直接标记为游戏连接；注入前已经建立的连接只调用一次 `getpeername` 补充端口；明确的非游戏端口直接忽略。端点查询失败的未知连接最多探测 4 KiB 登录/策略前缀，仍无法确认时转为忽略。`closesocket` 会同步移除分类，后台解析状态随后通过非阻塞控制项清理；独立发包 sidecar socket 被显式排除，避免重复发布。诊断环境变量 `AOLA_CAPTURE_ALL_SOCKETS=1` 可临时恢复全 socket 捕获后筛选，生产默认不启用。

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

接收方向不会出现在表格中；`AolaReceiveLogger` 将每条消息编码成包含本地/UTC 时间、进程、socket、命令、AMF3 参数和接收帧 HEX 的 JSONL 记录。启动后先在内存中保留最近最多 64 MiB 的接收片段；用户点击主窗口“开发者工具”旁的“保留日志”后，才在可执行文件旁的 `logs/` 目录创建 UTF-8 无 BOM 的 `aola-recv-*.jsonl`，写入已有片段并继续记录后续接收活动。未点击时退出不会创建日志文件；达到内存上限时优先丢弃较早记录，并在保留后的状态栏提示丢弃数量。

捕获队列保持 `4096` 项有界 `TryAdd`，队列满时只丢弃分析副本，不等待网络线程。注入端每五秒从非 Hook 线程聚合捕获/忽略/丢弃计数、队列高水位、解析延迟、连接数、重组缓存和协议异常；只有状态变化、发生丢弃或解析停滞时才通过 IPC 报告。每条连接的双向重组缓存合计最多 16 MiB，策略交互最多 64 KiB；越界时清空对应分析缓存并计数，不关闭或修改游戏 socket。空闲状态清理和正常关闭都会擦除缓存登录帧。

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

“默认”将选择值设为无拦截。选择主题只更新处理器状态并保存到 `settings.json`，不会自动刷新页面；刷新页面或重新进入游戏后，新的皮肤请求才会命中本地替换（状态栏会提示“刷新页面后生效”）。处理器只接受 FWS 模板，只有唯一且等长的导出类标记存在时才修改副本；原模板不被覆盖。

这个适配是必要的：游戏按 `mmo.controlv2.controlbarskin.skin.SkinN` 查找类，`skin0.swf` 与 `skin1.swf` 分别导出 `Skin0` 与 `Skin1`，直接交换二进制会破坏类名契约。

主题为何需要刷新才能生效（反编译证据见 `analysis/reverse-engineering/theme-live-reload-20260816/README.md`）：

- `ControlBarSkinHandler` 用 `_skinList` 按 ID 缓存已加载皮肤，同一进程内每个皮肤最多请求一次；`refreshUsingControlBarSkin()` 只在新 `_usingSkinId` 未缓存时才发起 `control/controlbarskin/skinN~*.swf` 请求。
- 即使清掉缓存重新请求同一 ID，AVM2 在已定义 `SkinN` 类的 ApplicationDomain 中会沿用旧类定义，新字节不会生效。
- 游戏自身的即时换肤依赖服务器命令 `UiSkinStyle240927` 改变账号“正在使用”的皮肤 ID；仓库规则禁止为本地资源替换发送该命令。
- 页面 JS 没有可用的 JS→Flash 皮肤刷新入口。因此“不刷新 + 不改账号服务器状态”的即时换肤需要补丁核心模块 `controlv2.swf`（虚拟 ID 轮换或新 ApplicationDomain + JS 触发入口），属于高风险改动，须用户明确接受后实施。

### 背包模型与海报形态替换

F2“功能面板”保存独立的模型源/目标 ID、海报源/目标皮肤 ID，以及“移除原背景”“替换背包头像”“隐藏原模型”三个标志；模型替换、模型转海报、已有海报替换、背景移除、头像替换或隐藏模型至少启用一项。规则和启用开关保存在 `settings.json` 中，重启后自动恢复。规则保存后先异步预检目标海报，再把皮肤、背景抑制和头像三组映射写入页面内存并调用当前背包模块的 `aolaMorphRefresh`，不再调用 `Reload(true)`。当前规则约束如下：

- 背包动态模型只接收不小于 `4400` 的 ID；原型与目标 ID 必须位数相同，以保证导出类名能够等长修改。
- “隐藏原模型”必须填写模型源 ID，不能同时填写模型目标 ID；当前透明模板与类名适配只支持 4 位模型 ID。
- “移除原背景”必须填写模型源 ID。`SimpleViewController` 先清理当前 `_bg`、`_packageBG` 中的 `skin*`、`commonLiZiMv` 和背景音乐，再跳过皮肤背景、全景背景、DIY 背景与前置背景动画；`isHasBg()` 同时返回 `false`，使界面按无背景布局处理。
- “替换背包头像”必须同时填写模型源和模型目标 ID；目标复用该行的模型目标。`PetSingleIconDetail` 在 `ActPetLoader` 前调用 `aolaMorphResolveIconId`，热刷新时释放旧 loader、清空容器并重新加载六个底部卡片头像。
- 背包路径只匹配 `petmovie<ID>/petmovie<ID>_<part>~version.swf`，其中 `part` 为 `0..3`。
- 海报 UI 输入的是皮肤 ID；`Resources/Data/pet-poster-catalog.json` 由 `PetSkinConfig.as` 生成，包含全部 `hasBackground=true` 条目（当前 417 条），运行时拒绝目录外 ID。
- “模型转海报”填写模型源 ID 和海报目标皮肤 ID，海报源皮肤 ID 留空；“已有海报替换”才填写海报源、目标两个皮肤 ID。
- 模型转海报只作用于精确版本 `newpetpackage~2026081331982423.swf`；版本不匹配、桥接开关关闭、模板缺失或桥接标记校验失败时保持官方模块。映射表由页面动态保存，不再受旧模板 16 个固定槽位限制。
- 同一个有效源皮肤 ID（海报源有值时取海报源，否则取模型源）只能有一个海报目标，避免运行时规则覆盖顺序不明确。
- 海报和模型使用各自的源 ID 作为规则键；面板关闭时只是隐藏窗口；规则已持久化，重启后自动恢复。
- 战斗内替换没有接线，形态规则不会修改战斗请求或对战状态数据。

`6000 -> 6047` 同时替换中央模型、移除 6000 花园背景并替换底部头像时，填写两个模型 ID，海报字段留空，同时勾选“移除原背景”和“替换背包头像”。中央模型继续走现有 `petmovie6000 -> petmovie6047` 远程资源适配；背景和头像只在背包模块内本地改变，不影响战斗或服务器状态。

将原本只以模型显示、`skin=-1` 的亚比 `5736` 改成海报皮肤 `6045` 时，规则应填写为：

```text
模型源 ID       = 5736
模型目标 ID     = 留空
海报源皮肤 ID   = 留空
海报目标皮肤 ID = 6045
隐藏原模型      = 可不勾选
```

目标 `6045` 在 `PetSkinConfig` 中映射到 `Background1041`，且 `hasBackground=true`、`showPet=false`。背包模块会因此走游戏原生的海报加载和模型隐藏逻辑；这里不改账号当前皮肤、标题、名称、通信数据或服务器状态。“隐藏原模型”仍是独立的透明模型资源功能，不是模型转海报的必要条件。

模型转海报的数据流：

```text
Flash 请求 newpetpackage~2026081331982423.swf
  -> CefSharp 始终返回已验证的同版本中性 FWS 桥接模板
  -> 页面在主 frame 建立 revision/enabled、skinMap、hiddenBackgrounds、iconMap
  -> 保存规则时按目录取得目标 Background resourceId，并预检官方 ~1210 SWF
  -> 仅把预检可用的 源皮肤 ID -> 海报目标皮肤 ID 写入页面映射
  -> JS 调用 Flash 的 aolaMorphRefresh；Flash 延迟一个 tick 派发 ON_OPEN_HAI_BAO
  -> SimpleViewController、PetBigIconDetail 与六个 PetSingleIconDetail 重新读取动态映射
  -> SimpleViewController.changeBg 以映射后的皮肤 ID 查询 PetSkinConfig
  -> PetSkinDataService 按目标 resourceId 请求官方 petskinbackground<resourceId>
  -> PetBigIconDetail 按目标 showPet 决定是否显示原模型
```

模板不把海报 SWF 伪装成 `PetMovie`，也不将目标资源打包进程序。`SimpleViewController.skinId` 与 `PetBigIconDetail.getSkinId` 通过 `aolaMorphResolveSkinId` 解析海报皮肤；背景控制器以原始 `pdi.viewId` 调用 `aolaMorphShouldHideBackground`；`PetSingleIconDetail` 以原始 `viewId` 调用 `aolaMorphResolveIconId`。JS→Flash 刷新回调先返回，再用 `setTimeout(..., 1)` 派发 `ON_OPEN_HAI_BAO`，避免 `ExternalInterface` 重入；该事件同时刷新中央视图和全部底部头像。关闭选项、删除规则或关闭总功能后，回调恢复原 ID/false 并触发同一重绘链路。

桥接证据位于 `analysis/reverse-engineering/pet-morph-live-bridge-20260820/`。原始 ZWS 的 SHA-256 为 `785089fd9749c06355a1bf2144d146e51f797283e711d62a073dfec243339915`；运行模板 `Resources/Patches/newpetpackage-morph-live.fws.swf` 的 SHA-256 为 `10ca77099996bbf8e540b636d6f7f6e83f9ea1daf6f73f4c0d3c929ecc1dc5be`，FWS 声明长度与物理长度均为 `2208280`。FFDec 已重读并确认三个原类、新增方法、布局恢复字段、桥接字符串及 `mclabelcontainer`/`petcontainer` 实例名；静态验证不能替代真实 PPAPI Flash 运行验证。

背包模型的数据流：

```text
Flash 请求 petmovie<原型>/<原型>_<part>~version.swf
  -> 按原型 ID 查找已启用规则
  -> 保留 host、版本后缀和原查询，路径改为 petmovie<目标>/<目标>_<part>
  -> 添加 _aolaMorph=m-<原型>-<目标>-<part> 标记
  -> Range 0-7 预检官方目标：必须为 FWS/CWS，声明长度与总响应长度一致
  -> CEF 正常请求官方目标 SWF（可继续使用 CEF 网络/磁盘缓存）
  -> AolaSwfResponseFilter 收集完整响应并再次校验 FWS/声明长度
  -> 等长修改 PetMovie<目标> 为 PetMovie<原型>
  -> 必要时执行模型尺寸补偿
  -> 将适配后的 SWF 交给原 Flash 加载器/ApplicationDomain
```

已有海报替换链路先通过完整目录把源、目标皮肤 ID 映射成 `Background` 资源 ID，再重写原本已经发生的 `petskinbackground<ID>~version.swf` 请求。响应过滤器交给 `AolaSwfClassAdapter` 严格解码 FWS/CWS/ZWS，再按统一的“远程输入类 → 原请求期望类”方向结构化修改 `SymbolClass` 与 ABC 字符串池中的 `Background<目标资源>` 类名，使其符合原请求的 `Background<源资源>`；ZWS 会校验压缩长度、LZMA 属性/字典和声明解压长度，适配结果统一输出为已验证 FWS。不同位数不再依赖等长替换，海报不做尺寸补偿。该链路不能让一个 `skin=-1`、从不请求海报的模型自动进入海报模式；这种情况必须使用前述模型转海报映射。

隐藏模型链路不返回 404 或空 SWF。它把四个 `petmovie<源>_<part>` 请求分别改写到服务器上的已验证 FWS 模板 `petmovie6025_<part>`，使用 `_aolaMorph=h-<源>-6025-<part>` 保留计划，等长适配全部 `PetMovie6025` 类名为 `PetMovie<源>`，随后解压每个 `DefineBitsLossless2` 格式 3/5 位图并把调色板 RGBA 或像素 ARGB 的 Alpha 清零。脚本、`MovieConfig`、`SymbolClass`、尺寸与帧结构保持不变，因此调用方仍能完成类解析和实例化，但模型位图不可见。模板预检或响应失败时恢复原始模型请求；结构校验或透明化失败时过滤器拒绝候选，避免把损坏 SWF 交给 Flash。

`_aolaMorph` 标记用于在 CefSharp 对改写 URL 再次选择处理器时重建同一计划，避免把目标请求误当成一条新规则。若预检判定目标资源不可用，第一次请求保持原 URL；若目标响应为非 2xx，则通过 `_aolaMorphFallback=1` 重新请求原始官方资源，并让该次请求绕过形态拦截。可用预检缓存十分钟，不可用结果缓存三十秒。

这里的“回退”覆盖目标资源预检失败和 HTTP 非成功响应；ZWS 或无法通过类契约/长度/结构校验的响应会被过滤器拒绝，未经验证的字节不会交给 Flash。原始 SWF 始终不覆盖；结构化适配候选与 FFDec 输出保留在独立 evidence 目录。

### 模型尺寸补偿

背包调用方会根据原型 View ID 在 SWF 外层应用额外比例。已从 `PetIconConfig` 确认：`5980/5998/5997/6007` 使用 `0.4`，`6000/5994/5995/6044` 使用 `0.3`，其他已知 ID 默认为 `1`。替换后仍按原型 ID 取比例，因此响应适配使用：

```text
内部补偿比例 = 目标 ID 的外层比例 / 原型 ID 的外层比例
```

例如 `6000 -> 6025` 的补偿比例为 `1 / 0.3`。`AolaSwfBitmapScaler` 只处理已验证的 FWS 叶子模型，支持 `DefineBitsLossless2` 格式 3/5：解压 zlib 位图、使用最近邻调整像素、同步 `MovieConfig` 坐标与 ABC 整数池中的位图尺寸，再重建标签和 SWF 声明长度。输入响应上限为 16 MiB，输出上限为 64 MiB，单个位图解压结果上限为 128 MiB；任何越界或结构歧义都会拒绝变换。

该补偿的四个 `6025` 分片已经通过 FWS 长度检查和 FFDec 重新读取；透明模型验证也覆盖四个分片。分片 0 的适配候选位于 `analysis/reverse-engineering/pet-runtime-6025-20260816/variants/petmovie6025-as-6000-hidden_0.swf`，SHA-256 为 `6ca6bcdfefaf674538c7b1f1dd047fd93fda01eabf902174c2d588a023c7d756`。FFDec 成功重新导出 15 个 `PetMovie6000_*`/Config 类和 13 张位图，13 张位图的 Alpha 范围均为 `(0,0)`；验证报告保存在 `analysis/reverse-engineering/pet-runtime-6025-20260816/evidence-hidden/verify/`。`6000 -> 6025` 的最终显示尺寸以及隐藏模型的真实背包表现仍属于 Flash 运行验证项，不能仅凭静态检查视为完成。

## SWF、缓存与依赖层

分析资源时按下列层次建立证据：

1. 从网络 URL/CEF 缓存索引确认请求身份。
2. 用长度、时间、FWS/CWS/ZWS 文件头、SHA-256 和内部字符串交叉确认缓存内容；`f_00011c` 一类文件名本身没有资源语义。
3. 校验 SWF 声明长度。ZWS 使用 SWF 的 LZMA 布局，压缩长度字段应匹配偏移 17 后的压缩数据，解压主体长度加 8 应等于声明长度。
4. 使用 JPEXS FFDec CLI 导出 ActionScript 和资源，检查文档类、导出类、`SymbolClass`、实例名、资源 URL/版本拼接、方法调用链与跨 SWF 加载。
5. 检查 Flash `ApplicationDomain` 的类查找与缓存行为，以及 CEF 内存缓存、CEF 磁盘缓存和 Flash 加载器缓存的差异。

缓存影响决定验证方式：若 SWF 类已经进入 `ApplicationDomain`，仅清 CEF 磁盘缓存不能替换该类。新的背包热更新实现因此只在首次加载 `newpetpackage~2026081331982423.swf` 时安装中性桥接；同一进程后续添加、修改、删除或关闭规则都只改页面内映射并重绘，不清 CEF 缓存、不重新定义类。升级到带桥接模板的新程序后仍需启动一次新进程，让桥接版模块首次进入 ApplicationDomain；如果状态提示桥接未就绪，清缓存本身没有意义，应重新打开程序并验证模板是否被拦截。主题皮肤仍受 `ControlBarSkinHandler._skinList` + ApplicationDomain 类定义约束，同一皮肤每会话最多加载一次（详见 `analysis/reverse-engineering/theme-live-reload-20260816/README.md`）。形态链路的十分钟/三十秒预检缓存、CEF 内存缓存、CEF 磁盘缓存、Flash Loader 缓存与 ApplicationDomain 是不同层次，不能互相混同。

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

2026-08-17 的隐藏模型改动已在正式输出路径执行 `dotnet build .\analysis\AolaLoader\AolaLoader.csproj -c Release`：构建成功，0 个错误；仍报告 4 次 `CefSharp.WinForms 87.1.132` 的 `NU1903` 已知高危漏洞警告。该构建证明宿主代码可编译，不代替上述真实 Flash 背包运行验证。

2026-08-20 的背包热更新整改执行 `dotnet build .\analysis\AolaLoader\AolaLoader.csproj -c Release --no-restore`：构建成功，0 个错误、2 个 `NU1903` 警告。桥接 SWF 通过文件头/长度检查、原始文件对比和 FFDec 重读，报告位于 `analysis/reverse-engineering/pet-morph-live-bridge-20260820/evidence/run-20260820-221509-340746-18552/`；真实 PPAPI Flash 的默认路径、首次桥接加载、已打开背包热更新、关闭规则与新进程回退仍需实机验证。
