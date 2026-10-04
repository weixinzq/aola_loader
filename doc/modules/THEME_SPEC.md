# Theme

Status: Implemented
ContractVersion: 2
OwnerPaths: `analysis/AolaLoader/Features/Theme/**`, `analysis/AolaLoader/Resources/Themes/**`, `analysis/tools/Prepare-ThemeLiveBridge.ps1`, `analysis/tools/theme/**`

## 职责

拥有主题选择、Theme Section、主题页面桥及控制栏/专用皮肤资源规则。保留旧的 `skinN~*.swf` 等长适配路径，供实机回退使用。

## 非职责

不创建 Cef handler、不处理 PetMorph、不清全局缓存、不发送 `UiSkinStyle240927` 或修改账号服务器状态。

## 公开契约

`IThemeCoordinator` 提供当前选择、可选项、保存、`PushCurrentAsync` 和 `ResetPage`；`ThemeBridgeClient` 通过 `IPageBridge` 调用 `theme.apply`。`ThemeSettings { Version, SelectedThemeId }` 保持 Version 1：0 恢复账号官方皮肤对象，1..10 为本地主题，10 为“遐蝶·紫夜蝶影”，仅支持热切换。保存/规则更新成功与 Flash 返回“已应用”是不同结果。

## 输入与输出

输入为选择命令和规范化资源请求；输出为状态快照、保存结果或本地 SWF 响应计划。

## 允许依赖

Settings Section、ResourceInterception、BrowserHost 页面桥契约和最小 SWF token 适配器。

## 禁止依赖

CefSharp 具体类型、PetMorph/Battle 内部实现、PacketHost 和服务器状态命令。

## 线程与生命周期

协调器串行更新不可变选择快照；UI 通知由调用方 marshal。释放后不发布状态。

## 异常及回退语义

模板缺失、非 FWS、目标 token 缺失/多义/非等长时拒绝替换并使用官方资源；保存失败明确报告，不破坏旧设置。

## 设置所有权

独占 `theme` Section，Version 1；不得修改 `petMorph` 或 `battle`。

## 安全约束

只匹配 `aola.100bt.com` 的受控 controlbar 叶子路径；原模板只读，转换副本不覆盖源。

## 缓存语义

热切换只请求 `/play/aola-helper/theme/skin1..10.swf`，官方叶子请求正常放行。候选叶子类、时间轴类及内嵌 `mmo.control` 类位于 `aola.theme.tN` 命名空间，加载到独立子域。每个主题对象只创建一次；保留官方对象以恢复默认。非活动对象的控制栏及辅助对象监听成对停用/恢复，按钮锁辅助对象每个主题只创建一次。

正常启动关闭热切换候选和专用规则，放行官方 controlv2，使用原叶子替换/刷新路径。仅进程启动前显式设置 `AOLA_THEME_LIVE_BRIDGE=1` 启用候选测试；`0` 或未设置均关闭。旧模式仍受 Flash 类缓存影响，选择后需刷新；程序不会自动刷新或重新登录。

关闭热切换时菜单不提供主题 10。已保存的 10 仍保留在 Version 1 设置中，恢复时提示不可用，不推送、不重写保存值，资源保持官方放行；原 0～9 仍使用旧模板。主题 10 不参与 `SkinN` 等长字节适配。

该情形返回宿主本地 `Unavailable` 状态，菜单明确显示“遐蝶主题不可用，需热切换”；它不是新增 Flash 操作或服务器结果。

## 遐蝶主题资源与动效

独立资源为 `Resources/Themes/Live/skin10.swf`，根类 `aola.theme.t10.mmo.controlv2.controlbarskin.skin.Skin10`。源图、原银河部件表、生成及定向复读入口位于 `Resources/Themes/Sources/Castorice/`；`build-skin10.py` 从只读 `skin9.swf` 替换视觉引用，以可变长度 ABC 字符串池和 SymbolClass 更新根类/命名空间，再编译装饰类。原具名实例、布局矩阵、时间轴帧、HitTest 记录及其形状/文字定义保留。左下 `mcBlueGem.btnblue` 的九个状态帧沿用蓝宝石业务；好友/背包等隐藏入口沿用原控制栏逻辑。按钮取消大外框，人物为经用户确认的兔耳睡衣 Q 版生成素材，不宣称是官方原图抠图。

装饰容器关闭 `mouseEnabled/mouseChildren`；皮肤根容器与其 `ControlBarSkinBase` 外层仅关闭自身 `mouseEnabled`，保留子按钮及隐藏菜单的鼠标策略。遐蝶加入舞台时另保存上层 `BaseControl.mouseEnabled` 并关闭其自身命中，离开舞台时恢复原值，避免装饰通过更上层容器拦截地图点击；不修改 `BaseControl.mouseChildren` 或地图移动代码。人物按钮保留交互。6 只蝶影、2 段流光、10 个光点和短边框银光按 `getTimer` 时间差驱动 8 秒循环，人物静态，无声音/全屏滤镜。祖先隐藏时冻结相位；离开舞台退订局部帧监听，再次加入只恢复一份监听。原官方头像、计数、红点及游戏生成文本保留。由原服务动态替换的射击、组队及通知对象仍由服务拥有；主题 10 可临时更换下述对象的显示内容，不改其业务或外部 SWF。

2026-10-05 界面微调：左上角采用用户图4的切角框与圆形头像区，真实头像容器缩放并加局部圆形遮罩，昵称、战力及功能按钮仍由游戏更新。首充/百星入口恢复银河原件对应按钮和嵌套资源；地图入口 394 使用用户提供的“冥蝶遐思”戒指透明素材，不绘制“地图”文字，原点击定义与游戏生成的场景名保留。

动态入口显示适配位于 `Sources/Castorice/Skin10.as`：加入舞台时扫描已有显示对象，之后监听舞台 `ADDED`。仅对本皮肤 `mcrightdownfloatbar` 内的 `mmo.team.teamservice.TeamButton` 更换 `btnTeam`、`btnteampanel.mcscene` 内 `btn_all` 和 `btnactteam` 的三态图；原实例名、`hitTestState`、禁用策略与服务监听保留，面板新增子对象时同步样式。`mmo.notifyview.ActNotifyIcon` 使用现有兔耳睡衣 Q 版，保留 `mcnum` 和原七帧未读/默认页逻辑；`FRAME_CONSTRUCTED` 更新显示，通知气泡不改动。离开舞台退订这些显示监听并恢复原按钮状态与原通知图，缓存主题再次显示时重新适配。不新增协议提交或点击处理。

本轮 SWF 复读、原按钮/具名实例契约、装饰透明点检查、相关主题契约与隔离 Release 构建通过；HTML 预览七个悬停入口及左下人物/客服检查通过。新视觉、真实账号头像、通知计数/红点、场景/活动菜单与切回其他主题的恢复仍待 Flash 实测。独立测试入口为 `C:/Users/weixi/AppData/Local/Temp/aola-theme10-refinement-20261004/loader/TestThemeLive.cmd`，仅该测试输出装入按已修复生成流程重新生成的控制栏候选；正式热切换仍默认关闭。此前确认可行走的叶子保留在同目录上层的 `skin10-map-working.swf`，本轮没有再次登录或发送游戏消息。

按用户实机截图修正装饰下方空带：删除 Skin10 构造中额外绘制的纯色底纹，装饰及底部动效下移 33 像素，以装饰图的横向底边贴齐 962×560 视口底部；超出视口的中央垂饰部分自然裁切。账号边框动效、人物、按钮/文字及点击区域坐标不变。HTML 预览同步，横向底边测量为 y≈559.8，好友/背包悬停预览通过；SWF 编译/复读及原按钮契约通过，非 ABC 标签与修改前一致。证据位于 `C:/Users/weixi/AppData/Local/Temp/aola-theme10-bottom-align-20261004`；仅更新主题 10 和当前独立测试资源，贴底效果与前一轮地图点击修正仍待真实 Flash 验收。

## 验证入口

`AolaSocketHack.Verify --theme-live-contract`：官方叶子放行、专用路径、最新选择、过期结果、页面重建、默认恢复请求、失败状态及相关页面/启动桥契约。候选生成入口为 `analysis/tools/Prepare-ThemeLiveBridge.ps1`，官方输入与导出、p-code、候选及静态复读保存在指定 EvidenceRoot。

该流程纳入主题 10 的独立生成。单独重建主题可运行 `Sources/Castorice/build-skin10.py`，随后运行 `verify-skin10.py`；需要 Python/Pillow、Node/Playwright、Chrome 和 FFDec，具体命令见素材目录 README。启动桥本轮只将 `onAolaThemeApply` 上限操作数 9 改为 10，其他字节保留。

## 完成标准

主题逻辑离开通用 Cef 入口；默认和至少一个替换主题实机通过；设置 Section 独立保存。

## 已知限制

2026-10-04 热切换增量候选基于当前官方配置中的 `controlv2~2026082731219998.swf`，补丁只增加主题显示桥与对应对象生命周期；不调用 `ControlBarSkinClient.setSkin`。`ControlBarSkinBase` 存在两个 FFDec 无法完整反编译的方法，因此使用原 p-code 定点修改监听调用，保留原方法。启动桥通过动态定义查询调用 `ControlBarSkinHandler.applyTheme`，不提前创建未就绪模块。

调用链为菜单 → `ThemeCoordinator` → `ThemeBridgeClient` → `AolaPageBridge` → `aolaThemeApply` → 控制栏候选 → 专用资源规则 → 应用结果。状态包括 `Applied / WaitingBattleEnd / NotReady / Loading / Failed / Superseded`；主窗体每 500ms 推送未完成选择，终态不重复调用 Flash。战斗结束且显示链恢复可见后才替换，新对象完成前保持旧界面，失败尝试恢复旧对象。选择与页面重建递增 requestId；旧结果不更新当前菜单。

2026-10-04 用户实机反馈：刚登录、尚未选择遐蝶时卡在加载 100% [1/1]，默认主题菜单显示切换失败，提示 `Error #1065`。当前热切换候选在默认选择下仍替换启动必经的 controlv2；现已改为正常启动透传官方模块，失败候选和主题素材保留。用户随后确认恢复版可以进入游戏；此结果只证明官方 controlv2 路径恢复，尚未验收修复候选或主题 10。

定点 p-code 核对发现 `applyLocalTheme` 的 `flash.utils.getDefinitionByName(...)` 被编译为 `getlex Multiname("flash",...) → getproperty utils`，未直接引用 `flash.utils` 函数定义。生成源改为显式导入并调用 `getDefinitionByName`；独立修复候选静态复读确认直接 QName 调用，保存在 `analysis/reverse-engineering/theme-live-20261004/recovery/`，失败输入同时保留，未晋级生产资源。该缺陷能解释主题回调错误，不能据此宣称已解决全部加载阻塞。恢复宿主为 `analysis/.theme10-recovery-build/loader`；Release 构建及现有 `--theme-live-contract` 通过，用户已确认该恢复版可进入游戏。

修复候选的独立测试宿主位于 `C:/Users/weixi/AppData/Local/Temp/aola-theme10-candidate-20261004/loader`，仅该输出目录装入定点修复的 controlv2。双击 `TestThemeLive.cmd` 对测试进程临时启用热切换；直接启动 exe 仍为官方路径。D 盘空间不足导致首次独立输出失败，已清理本轮新建失败输出并改在 C 盘完成 Release 构建（0 错误，既有 NU1903）；未启动测试游戏。候选真实验收先确认默认登录，再默认→银河→默认，最后主题 10；已确认可登录的恢复版不覆盖。

用户随后确认该定义查询修复候选仍卡在默认加载，提示 `Error: An invalid exception was thrown.`，不能验收其热切换。方法审计显示：18 个辅助类未删除原方法签名，但监听相关方法体改变；ControlBarSkinHandler 的原有 16 个方法均经过 AS3 重编译，签名保留不等于调用语义保留。发现两项追加缺陷：构造函数和 refreshUsingControlBarSkin 的 getUsingSkinId 调用丢失官方接口命名空间；监听补丁从官方原件导出，却导入已重新编号的候选，三处被改写方法中的 newfunction 操作数仍使用旧编号。例：onGetUrlCompleted 的官方回调编号 20105 在候选中应为 20084，旧编号已指向其他函数，静态对比正确编号处的函数代码与官方原回调相同。

生成流程已恢复上述两处接口 QName，并改为从同一重编译候选导出监听 p-code，再定点导入。重新生成的核心候选位于 `C:/Users/weixi/AppData/Local/Temp/aola-theme-index-fix-20261004`；18 个辅助类的 29 处闭包引用前后一致，接口绑定、定义查询与现有主题契约通过。整套生成的主题 10 阶段首次因未设置已文档化的 NODE_PATH 失败，补齐依赖路径后单独重跑该阶段成功；主题视觉不变。本轮不改 C#，独立测试宿主沿用已构建程序，仅替换该目录的 controlv2：`C:/Users/weixi/AppData/Local/Temp/aola-theme10-index-test-20261004/loader/TestThemeLive.cmd`。恢复版和失败候选保留；新候选仍未真实登录或热切换验收。

热切换候选修复后仍需实机验收：默认→1→9→1→默认、快速选择、重进游戏、战斗延后，以及地图/背包/聊天一次点击一次操作。既有阶段 9 的刷新路径证据不能证明本次热切换运行成功。

用户随后已进入游戏并显示主题 10，反馈银河、默认及其他主题可行走，唯独遐蝶下半屏不能点击。静态核对新增装饰 Shape 的矩形范围为视口 y≈277～598，与下半屏现象一致；装饰自身虽禁用鼠标，其皮肤根与外层容器仍可命中。`Skin10.as` 已关闭这两层容器自身的鼠标命中，保留子按钮交互；原银河根构造没有额外初始化遗漏。旧叶子触发新增鼠标隔离检查失败，新候选编译及 FFDec 复读通过，211 条具名放置、217 个时间轴、81 个按钮点击契约和 29 个导出类继续匹配。证据保存在 `C:/Users/weixi/AppData/Local/Temp/aola-theme10-mouse-fix-20261004`，已更新主题 10 资源及上述独立测试入口；未修改核心控制栏候选。修正后的地图行走、隐藏菜单和其他实机验收仍待用户重启测试，不能据静态结果宣称恢复。

上述两层修正经用户实机确认仍失败，隐藏控制栏后可交互。进一步只读获取当前官方 loader/play 资源：`LayerManager.initLayers` 创建的 `BaseControl` 是默认可命中的 Sprite，`ControlBarSkinBase.addToStage` 将皮肤外层加入该层；`MouseControlStrategy.setControlItem` 只在同级 `BaseScene` 上监听 CLICK，`onMouseClickBoard` 再调用 `walkTo`，没有通过控制栏边界手动屏蔽行走。因此上一版仍遗漏共同祖先下的 `BaseControl` 层。新叶子按上述生命周期暂时关闭该层自身命中并恢复原值，连续加入不覆盖保存值；独立编译/复读、81 个原按钮契约及原策略恢复检查通过，所有非 ABC 标签与失败候选一致。证据和官方只读源码保留在 `C:/Users/weixi/AppData/Local/Temp/aola-theme10-hit-geometry-20261004`；实际地图恢复及切回银河/默认后交互仍待重启实测。

用户在 BaseControl 及贴底候选后再次确认地图仍不可点击；上文祖先层推断不足以证明实际拦截对象，不能认定故障已修复。暂不追加生产鼠标开关，独立测试程序改用临时 `theme10-hit-probe-1` 叶子：舞台捕获 MOUSE_DOWN，记录目标/祖先类名、鼠标标志、坐标及点下对象；F8 仅隐藏/恢复新增装饰作对比，切出主题退订。仅记录显示结构，不读取聊天、账号字段、连接或协议数据。诊断输出到页面右上文本与 `window.aolaThemeHitDiagnostics`，正式源码/SWF 不加入该探针；临时源码及失败候选保留在 `C:/Users/weixi/AppData/Local/Temp/aola-theme10-click-probe-20261004`。编译、原按钮契约、生命周期复读及回调 JavaScript 语法通过，真实点击结果待用户提供后再决定修正。

用户随后实测确认按 F8 后恢复行走：在原控制栏与按钮保留时，隐藏新增装饰/动效可解除拦截。装饰的 bitmap 填充原为完整矩形，包含透明的下半屏留白。`build-skin10.py` 现只为装饰生成非零 alpha 像素的填充轮廓，原 PNG、位图填充矩阵、贴底坐标及按钮均保留。新增定向检查从复读的 Shape 边线判断四处透明地图点不填充、三处可见底边点仍填充；旧资源失败，新候选通过，81 个按钮契约等继续通过。与贴底候选相比，非 ABC 标签只有装饰 Shape 2121 改变。用户在同一独立入口、`Theme10 hit probe 2 alpha contour` 装饰显示状态下确认可以行走，证明本次轮廓修正解除此前下半屏拦截。证据位于 `C:/Users/weixi/AppData/Local/Temp/aola-theme10-alpha-geometry-20261004`，通过的探针版本单独保留；正式主题叶子与测试入口已更新为无探针/F8 的干净候选。完整按钮/隐藏菜单、反复切换及性能仍未完成实机验收；此结论也不表示正式热切换开关已启用。

本次验证：`--theme-live-contract`（从仓库根目录运行）通过，包含主题、页面桥及主动发送相关契约；生产页面脚本模拟执行通过；1..9 SymbolClass/ABC 定义匹配，1/9 叶子与控制栏/启动桥 FFDec 静态复读通过，控制栏与启动桥的非 ABC 标签保持原样；三个生产项目 Release 构建通过，0 错误，宿主保留既有 CefSharp 两项 NU1903 提示。`git diff --check` 通过。没有执行真实 Flash、登录、战斗或按钮操作；输出位于隔离目录 `analysis/.theme-live-build/loader`。

主题 10 增量验证：211 条原具名放置、217 个时间轴、81 个按钮点击契约和 29 个导出类定义匹配，原空占位按钮保留、80 个可视按钮三态存在；蓝宝石九帧、装饰隔离与生命周期方法静态复读通过。扩展主题契约、生产页面脚本模拟、相关 Release 构建与 `git diff --check` 通过，0 错误；仍有上述既有 NU1903。测试宿主输出为 `analysis/.theme10-build/loader`，素材目录 README 保存再生成步骤及证据位置。尚未验证真实 Flash 装载、热切换、按钮、战斗延后或一分钟 FPS 对比；不得以这些静态/模拟结果代替实机验收。

`IThemeCoordinator`/`ThemeCoordinator` 拥有主题选项、当前快照、`ApplyToRule`/`ApplyAndSave` 与结构化结果；主窗体只转发选择，`AolaResourceRequestHandler` 通过 `IThemeSelectionTarget` 接入，`ThemeLeafResourceRule` 独立于 Cef。阶段 9 已验证默认不拦截、替换主题、刷新、窗口重开与新进程缓存路径；本地替换不发送服务器主题状态命令。
