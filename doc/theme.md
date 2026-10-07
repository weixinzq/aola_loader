# 新主题界面制作流程与排障记录

整理日期：2026-10-05。案例：主题 10「遐蝶·紫夜蝶影」，以银河 `skin9.swf` 的显示结构和交互为基底。

本文记录这次实际制作、失败排查和验证过程，供下次制作主题时复用。现有主题模块说明见 [THEME_SPEC.md](modules/THEME_SPEC.md)。

## 1. 阅读前先确认工作区

2026-10-05 再次核对：当前分支为 `main`，主题 10 叶子、设计源、生成脚本与热切换接入代码来自 `abd6c3f`（更新主题界面）。随后按用户普通编译运行的反馈，将独立测试版的控制栏修复资源同步进项目，并将正常启动改为默认开启热切换；这些同步改动保留在工作区，本文 `doc/theme.md` 仍是新文件。

初次写本文时读取到的是 `ad7ee1a`，当时这些新增路径不在工作区；上述新提交与实物检查已替代该旧快照。独立测试程序仍在临时目录；其控制栏此前没有同步到普通输出，是用户自行编译看不到遐蝶的原因之一，另一个原因是旧启动开关默认关闭。现在普通构建携带相同修复资源，不再依赖临时测试入口。本文不据此推断工作区变化的操作者。

下次开始前，从仓库根目录执行只读状态检查，确认当前代码、工具和验收基线。保留已有修改，不 reset、checkout 或清理工作区。

```powershell
git status --short
git branch --show-current
Get-ChildItem .\analysis\AolaLoader\Resources\Themes
```

本轮仍可读取的证据目录：

```text
C:\Users\weixi\AppData\Local\Temp\aola-theme10-refinement-20261004\
  bridge\controlv2-theme-live.fws.swf     修复生成流程后的控制栏候选
  bridge\theme10\skin10.swf             最后一次界面微调候选
  bridge\theme10\reread\scripts\        候选 ActionScript 静态复读
  skin10-map-working.swf                 微调前保留的地图可行走版本
  verify-final.log / bridge-verify.log   静态检查结果
  loader-build.log / preview.log         构建、HTML 预览结果
  loader\TestThemeLive.cmd               独立测试入口
```

临时目录可能被系统或人工清理，不能作为长期源文件备份。反编译出的 `.as` 也不能替代原生成脚本、源图和资源对应表。后续应把已确认的设计源与生成工具保留在项目的源目录中。

## 2. 最快的制作顺序

| 阶段 | 做什么 | 进入下一阶段的依据 |
|---|---|---|
| 需求确认 | 确认人物、配色、位置、保留功能及动态效果 | 用户确认范围；缺少指定图案时先询问 |
| 原皮肤拆解 | 导出银河的类、实例、按钮四种记录和时间轴 | 得到部件表及真正的业务对象归属 |
| 设计预览 | 在 962×560 视口里展示整体、按钮状态、隐藏菜单 | 用户确认视觉；HTML 交互检查通过 |
| 叶子 SWF | 替换视觉资源、隔离类名、加入局部动效 | SWF 编译、复读及原交互契约通过 |
| 接口接入 | 菜单、设置范围、专用资源路径、桥上限、项目输出 | 相关契约检查及隔离 Release 构建通过 |
| 实机验收 | 登录、切换、点击、菜单、战斗延后及性能 | 分别记录实际结果，不用静态结果代替 |

优先复用已验证且与当前官方版本对应的热切换桥。只制作新叶子皮肤时，不要为了换图重新编译整个 `controlv2`。确实需要改变核心桥或范围时，单独生成候选，先验收默认登录和银河切换，再测试新主题。

## 3. 先把需求和交互画完整

这次最终确认的设计约束：

- 深紫夜色与银白；背景 `#171323`、面板 `#29223E`、雾紫 `#A994D1`、银白 `#EAE6F3`。
- 人物位于银河原有左下角区域，使用用户指定方向的兔耳睡衣 Q 版，保留蓝宝石入口的交互。
- 去掉底部按钮的大外框，保留原布局、功能文字和点击区域。
- 底部装饰本身作为最底边，不额外铺一条纯色背景。
- 地图入口原位使用用户提供的“冥蝶遐思”戒指，仅去掉“地图”两字，保留游戏生成的场景名。
- 玩家头像、昵称、战力、计数、红点和业务提示仍来自游戏；不能把预览里的占位信息烘焙进运行资源。
- 首充、百星入口恢复原图标和嵌套资源。
- 消息盒子、组队、场景、活动只换视觉；保留提醒、禁用条件和功能。

第一次预览就应包含：正常/悬停/按下状态、左下人物按钮、好友菜单、背包快捷入口、场景/活动入口、聊天输入及提示。不能只画一张底栏效果图，之后才发现遗漏可展开的按钮。

人物、戒指等参考图保存原件；透明素材另存文件。图片底色看起来是黑色，不代表它具有透明通道。源图去背景与 SWF 的命中几何是两个不同问题，见第 7 节。

## 4. 拆解银河：看实例和调用方，不只看图片

只读基底为 [skin9.swf](../analysis/AolaLoader/Resources/Themes/skin9.swf)。当前仍有的 T1 工具和对应表位于：

```text
analysis/reverse-engineering/theme-castorice/T1/
  map_skin9.py
  skin9-parts.csv / skin9-parts.json
  skin9-buttons.json
  export/symbolClass/symbols.csv
  render-preview.cjs
```

`map_skin9.py` 从 FFDec XML 和 SymbolClass 表计算具名放置、首帧边界及按钮状态。本轮预览坐标来自这份静态显示表，不等同于所有时间轴帧的真实运行边界。

FFDec 示例，输出放入独立证据目录，不覆盖输入：

```powershell
$ffdec = 'D:\Programs\FFdec\ffdec-cli.exe'
$themeEvidence = 'D:\game\aola-helper\analysis\reverse-engineering\theme-next'
& $ffdec -swf2xml .\analysis\AolaLoader\Resources\Themes\skin9.swf "$themeEvidence\skin9.xml"
& $ffdec -onerror abort -export script,symbolClass "$themeEvidence\export" .\analysis\AolaLoader\Resources\Themes\skin9.swf
# 定点方法排查才导出 p-code；-format 放在 -export 前面。
& $ffdec -onerror abort -format script:pcode -selectclass 'mmo.controlv2.controlbarskin.ControlBarSkinHandler' -export script "$themeEvidence\pcode" '<官方 controlv2 文件的实际路径>'
```

必须区分 `SimpleButton` 的 `Up / Over / Down / HitTest`：前三者是显示，第四种是点击定义，不能把 HitTest 当成禁用状态。本轮地图按钮资源 394 的原记录是 Up=391、Over=392、Down=391、HitTest=393。换戒指时保留 393，而不是把新图的矩形范围变成点击区。

还要保留根字段、命名实例、放置变换、时间轴帧数、文本绑定和所需类。`mcBlueGem` 的九帧、空占位按钮以及隐藏菜单都属于原结构，不能以“暂时看不到”为由删除。

以上编号是这份银河原件的拆解结果，不是所有皮肤或新版本的固定规则。

### 4.1 静态皮肤与动态服务对象的区别

| 界面部件 | 本轮确认的对象和路径 | 制作时保留什么 |
|---|---|---|
| 地图 | `Skin10.btnMap`，基底按钮 394 | HitTest、原位置、地图业务、场景名 |
| 左下人物/蓝宝石 | `mcBlueGem` / 原 `btnblue` | 原帧结构、悬停和点击，不把整个人物区域全部禁用 |
| 玩家信息 | `mcPlayerInfo.playerhead` 与 `PlayerInfo` | 真实头像加载、昵称、战力、原功能按钮 |
| 组队 | `mmo.team.teamservice.TeamButton.btnTeam` | 原实例名、三态、HitTest、原监听 |
| 场景 | `TeamButton.btnteampanel.mcscene` 下的 `btn_all`，展开后还有 `btn_create/btn_join` | 游戏原帧切换、菜单和禁用条件 |
| 活动 | `TeamButton.btnteampanel.btnactteam` | 原点击路由与业务 |
| 消息盒子 | `mmo.notifyview.ActNotifyIcon`，其中 `mcnum.txtnum` 为计数 | 原七帧状态、未读计数、默认打开页和通知气泡 |

`ControlBarSkinBase.initializeTeamPanle()` 会移除银河中的 `btnTeam` 占位，安装服务创建的 `TeamButton`。因此，只修改银河里的占位图不会完整修改运行中的组队/场景/活动。

`TeamButton` 构造时保存 `btnteampanel` 并暂时从显示树移除，悬停时再展示；场景菜单还会随帧改变子对象。其原点击处理通过 `event.target.name` 分派业务。替换按钮对象或改名可能破坏功能，即使截图仍然正常。

消息盒子由 `NotifyView` 加到 `LayerManager.getBaseTop()`，不是 Skin10 的普通子按钮。`ActNotifyIcon.refresh()` 按邮件、印象/鲜花、奖励、定时通知等改变帧和默认页，不能将它整体替换为一张没有状态的图片。

本轮微调只在主题显示时暂换这些真实对象的显示内容：保存按钮原三态，保持 HitTest；消息图保留 `mcnum`，用 `FRAME_CONSTRUCTED` 处理原帧切换。移出主题时退订并恢复。不得另写第二份点击业务或提交额外命令。

具体复用点是 `Skin10.styleExternal / styleTeamTree / styleNotify / makeState`：加入舞台时扫描已有对象，之后通过舞台 `ADDED` 和菜单子对象 `ADDED` 处理新对象。`getQualifiedClassName` 的实际比较字符串为 `mmo.team.teamservice::TeamButton`、`mmo.notifyview::ActNotifyIcon`；组队还限定在本皮肤 `mcrightdownfloatbar` 内。暂时移出的面板通过保留的 `team.btnteampanel` 引用处理，不能只扫描当前可见子树。每个按钮的原三态、每个通知子对象的原 `visible` 只保存一次，避免重复适配把已经隐藏的状态误记为原状态。

## 5. 制作叶子 SWF 与动效

本轮制作源与工具路径如下，已在 `abd6c3f` 工作区核对存在：

| 路径 | 用途 |
|---|---|
| `analysis/AolaLoader/Resources/Themes/Sources/Castorice/preview.html` | 962×560 交互效果图；场景、账号信息为占位 |
| 同目录 `build-skin10.py` | 从银河原件生成视觉资源、装饰几何和独立叶子 |
| 同目录 `render-assets.cjs` | Chrome/Playwright 将 SVG 与中文文字渲染成透明素材 |
| 同目录 `Skin10.as` | 动效、头像局部遮罩、显示期间的动态入口适配 |
| 同目录 `verify-skin10.py` | 原结构、按钮点击区、类绑定、透明地图点和生命周期检查 |
| `analysis/tools/theme_bridge_assets.py` | ABC 字符串池与 SymbolClass 的命名空间更新 |
| `analysis/tools/Prepare-ThemeLiveBridge.ps1` | 官方 controlv2 的主题桥候选与监听生命周期补丁 |
| `analysis/AolaLoader/Resources/Themes/Live/skin10.swf` | 本轮预期接入路径 |

### 5.1 类隔离和原件保留

- 不覆盖 `skin9.swf`，使用其副本和导出结果生成候选。
- 本轮导出根类为 `aola.theme.t10.mmo.controlv2.controlbarskin.skin.Skin10`。
- 内部叶子类、时间轴类和 SymbolClass 同步使用独立命名空间，包括原皮肤内嵌的类及其内部引用。
- `Skin9 → Skin10` 长度不同，不能沿用旧的等长字节替换。需要一致更新 ABC 类定义/引用和 SymbolClass；只改类名字符串或只改 SymbolClass 都不够。
- 首充/百星恢复原件时，需要保留外层按钮及其引用的嵌套图形、动画、文字；只恢复最外层 MovieClip 不一定能恢复完整视觉。

### 5.2 坐标、底边和真实头像

设计基准为游戏视口 962×560，不是 WinForms 窗口外框。将素材放回原实例的局部坐标和变换，不能直接用效果图的屏幕坐标替代局部坐标。

本轮银河根放置偏移为 `(-8.8, 480.4)`。底部空带的修正为：移除额外纯色底纹，将装饰和底部动效下移 33 像素，横向装饰底边贴到视口 y≈559.8；中央垂饰超出视口的部分裁切。人物、原按钮与文本不跟着整体下移，账号边框动效也不使用这 33 像素偏移。

圆形玩家头像使用原 `playerhead` 容器，局部缩放并设置兄弟遮罩。原头像服务会清理头像容器内的子对象，遮罩放在兄弟层可避免随清理消失；保留原头像加载和点击。预览中的“玩家头像”不是运行素材。

### 5.3 动效与监听生命周期

本轮动效为 8 秒循环、6 只蝶影、2 段流光、10 个光点和少量边框亮纹，人物静态，无声音、全屏闪烁或全屏滤镜。

- 动效容器设置 `mouseEnabled=false`、`mouseChildren=false`；原功能按钮保持可交互。
- 用 `getTimer()` 的时间差推进相位，不按帧数推进，避免 25/50/75 FPS 改变循环速度。
- `ADDED_TO_STAGE` 恢复一份局部监听；`REMOVED_FROM_STAGE` 成对退订。
- 显示祖先隐藏时冻结动画相位，持续更新上次时间，避免重新显示后跳过一大段时间。
- 主题对象缓存复用；重新显示不能多注册一份按钮/帧监听。
- 动态入口监听限定在已确认的类和本皮肤所属对象上；切出时恢复其原图，避免将遐蝶视觉遗留到银河/默认。

### 5.4 隐藏菜单必须在 Flash 中验证

2026-10-05 用户在普通仓库版本确认：图鉴、排行的子菜单完全不展开。HTML 预览中“全部／皮肤”存在并能悬停，不能证明实际 SWF 的显示监听有效；静态保留实例和 HitTest 也只说明按钮仍在。

原控制栏链为 `ControlBarSkinBase.addToStage → initPetDicTips / initRankAndRongyaoTips → ActTipsMc.init → MOUSE_OVER / MOUSE_OUT → tips.visible`。图鉴触发容器为 `mcPetDic`，菜单为其 `mcTipsPetDic`；排行触发按钮为 `btnbillboardicon`，菜单为 `mcRankAndRongyao`。原点击入口仍为 `btnPetDic`、`btnpetskinhandbook`、`btnHonor`、`btnrongyao`，不能换掉实例名或自行再提交业务。

本次在 `Skin10` 的显示生命周期中补齐这两组悬停监听，并在原处理之后更新显示。`MOUSE_OUT` 也会发生在子对象间移动，必须检查 `relatedObject` 是否仍在主按钮或菜单内部；移入菜单及其子按钮保持显示，离开整个区域才收起，禁用主按钮不展开。切出时收起、退订并清空绑定，缓存主题再显示时重新注册。装饰轮廓、地图命中和原按钮 HitTest 保留。

制作下个主题时逐一核对：主按钮悬停、移入每个子按钮、点击原功能、移出收起，以及切出后再切回。好友、背包等其他菜单也要各自沿真实调用链验证，不能仅因预览通过而登记 Flash 验收成功。本次修复的真实效果仍待用户确认。

## 6. 接入热切换接口

本轮热切换调用链：

```text
主题菜单
→ ThemeCoordinator 保存选择 / 发起推送
→ ThemeBridgeClient
→ AolaPageBridge 的 theme.apply
→ JavaScript / ExternalInterface 的 aolaThemeApply(themeId, requestId)
→ 启动桥 Load 动态查询 ControlBarSkinHandler.applyTheme
→ 加载 /play/aola-helper/theme/skinN.swf
→ 独立 ApplicationDomain 中创建并缓存 SkinN
→ aolaThemeCompleted 返回应用状态
→ 宿主更新菜单状态
```

下次新增编号 N，需要一起核对菜单、`ThemeSettingsCodec` 的合法范围（位于 `ThemeSettings.cs` 内）、专用资源规则、页面桥、`Load` 上限、核心桥支持范围、导出类名和项目输出。不能只复制一个 `skinN.swf` 就认为接入完成。

默认主题恢复账号原本的官方皮肤对象。首次官方叶子正常放行，自定义主题只走专用路径；不提交 `ControlBarSkinClient.setSkin` 或服务器主题设置命令。新对象加载/创建完成后才替换旧界面，失败保留旧主题。

同一选择不重复创建对象；快速选择以最新 requestId 为准。旧页面回调不能更新新页面状态。战斗中保存最新选择，等退出战斗且控制栏恢复显示后应用。菜单“规则已更新”与 Flash “已应用”分开显示。

旧 0～9 刷新路径与热切换是两种资源/缓存流程。本轮主题 10 只支持热切换，关闭时不开放；保存值 10 保留，但提示不可用并保持官方界面。修复验证阶段曾默认关闭、仅独立测试以 `AOLA_THEME_LIVE_BRIDGE=1` 开启；2026-10-05 已同步修复控制栏并改为普通启动默认开启。启动前显式设置 `AOLA_THEME_LIVE_BRIDGE=0` 可恢复官方控制栏与旧刷新路径。下一次同步不能只带叶子资源和菜单代码，还要同步实际测试的核心资源、启动开关与项目输出。

## 7. 重点故障：下半屏地图无法点击

### 7.1 实际排查顺序与证据

| 步骤 | 改动/观察 | 结果与解释边界 |
|---|---|---|
| 对照主题 | 银河、默认及其他主题可行走；遐蝶下半屏不可点击；不显示当前栏的其他界面可交互 | 问题收窄到遐蝶控制栏的新增显示内容 |
| 两层鼠标隔离 | 关闭皮肤根与外层容器自身 `mouseEnabled`，保留子按钮 | 编译/复读通过，用户实测仍失败 |
| 上层隔离 | 保存并关闭 `BaseControl.mouseEnabled`，移出恢复，不关闭其 `mouseChildren` | 静态通过，用户实测仍失败；不能把这一推断写成修复结论 |
| 临时 F8 对照 | 保留原按钮，仅隐藏新增装饰/动效 | 用户确认隐藏后可行走，定位到新增部分 |
| 装饰填充轮廓 | 将 bitmap 填充 Shape 的完整矩形改为非零 alpha 像素覆盖的轮廓 | 用户确认装饰显示时可以行走，是本轮已确认有效的修正 |

官方静态调用链也提供了定位依据：`LayerManager.initLayers` 创建 `BaseControl`；控制栏经 `ControlBarSkinBase.addToStage` 加入该层；行走点击监听在同级 `BaseScene`，经 `MouseControlStrategy.onMouseClickBoard` 调用 `walkTo`。不能通过改地图移动逻辑绕开控制栏遮挡。

### 7.2 为什么透明 PNG 仍可能挡住地图

装饰通过 bitmap 填充的 `Shape` 绘制，原来 Shape 的几何填充是覆盖下半屏的大矩形。PNG 留白像素虽透明，Shape 的填充几何仍覆盖这些点；本轮实际命中行为还涉及显示祖先。仅关闭装饰容器或祖先自身鼠标标志，没有通过上述实机对照。

有效修正发生在 `build-skin10.py` 的装饰 `rect_shape(..., alpha=...)` 生成阶段：

```text
逐行读取原图 alpha
→ 找出 alpha > 0 的连续像素段
→ 将每段映射到原 Shape 坐标，生成填充边线
→ 保留原 PNG、位图填充矩阵和贴底位置
→ 透明留白不再具有装饰填充几何
```

这不是删除 PNG 黑色像素、修改地图、缩小整个皮肤或把所有子按钮禁用。轮廓只用于新增的大幅装饰；原按钮仍保留 HitTest。本轮对应的定向检查为四个透明地图点不填充、三个可见装饰点仍填充；旧候选失败、新候选通过。

### 7.3 下次出现同类问题的快速定位

1. 对比默认/基底/新主题，在同一块空地测试；区分按钮不工作与地图移动被遮挡。
2. 检查新增图层的实际尺寸、变换、矩形填充与透明留白，尤其是横跨下半屏的大图。
3. 用独立临时探针记录点击目标、祖先和点下对象；只读显示结构，不读取聊天、账号或连接数据。
4. 临时隐藏新增装饰做 A/B，不隐藏原控制栏业务。若行走恢复，优先检查新增几何。
5. 修正后同时验收装饰显示时的行走、人物/客服按钮及隐藏菜单，避免以禁用交互“解决”遮挡。
6. 正式候选移除探针和 F8 操作，保留失败证据与已确认可用的前版。

## 8. 重点故障：默认登录停在 100% / 异常

本轮曾在尚未选择遐蝶时就停在加载 `100% [1/1]`，先显示 `Error #1065`，后续候选显示 `An invalid exception was thrown.`。当时默认选择仍替换启动必经的 `controlv2`，所以不能根据“默认主题”就认定核心补丁没有参与。

恢复官方 `controlv2` 放行后，用户确认可以进入游戏。这证明恢复路径有效，并不自动证明新核心候选正确。

随后定点审计发现并修正了三项静态缺陷：

| 缺陷 | 修正 |
|---|---|
| `flash.utils.getDefinitionByName` 被编译为查找 `flash` 再取 `utils` | 显式导入 `getDefinitionByName` 并直接调用，复读正确 QName |
| 两处 `getUsingSkinId` 丢失外部接口命名空间 | 在 p-code 中恢复 `mmo.interfaces.material.controlbarskin:IControlBarSkinService` 的 QName |
| 从官方原件导出监听方法，再导入已重编译候选，`newfunction` 仍使用旧编号 | 从同一重编译候选导出、定点修改并导回，保留它当前的闭包编号 |

闭包编号的实际例子：官方 `onGetUrlCompleted` 回调为 20105，重编译候选中对应原回调为 20084；旧 20105 已指向另一个函数。旧编号依然可能落在合法方法范围内，因此 FFDec 能读、方法名还在、C# 能构建，都不足以证明运行调用正确。

本轮最后生成流程检查确认 18 个辅助类的 29 处闭包引用保留，两处接口绑定恢复。这里记录的是静态结果；以后核心版本变化时不能照搬 20105/20084，应重新定位当前方法与回调。

处理原则：保留失败候选，恢复已确认能登录的官方路径；核心候选独立测试；保留原方法签名还不够，必须核对被重编译的方法体、接口绑定、闭包和初始化链。未通过默认登录前，不进入新主题验收。

## 9. 再生成与验证

以下为本轮生成命令示例。**先核对第 5 节的源文件、工具依赖和对应版本，再向独立目录生成。** `build-skin10.py` 固定面向主题 10，制作 N 时要相应调整类、命名空间、输出和接入范围，不能机械替换编号后跳过核对。

```powershell
# 从 D:\game\aola-helper 根目录运行
$env:NODE_PATH = 'C:\Users\weixi\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules'
$themeEvidence = 'D:\game\aola-helper\analysis\reverse-engineering\theme-castorice\next-candidate'
python analysis/AolaLoader/Resources/Themes/Sources/Castorice/build-skin10.py --evidence "$themeEvidence"
python analysis/AolaLoader/Resources/Themes/Sources/Castorice/verify-skin10.py --evidence "$themeEvidence"

# 仅当需要生成核心桥时使用；输入必须是对应版本的官方原件。
& analysis/tools/Prepare-ThemeLiveBridge.ps1 `
  -OfficialSwf 'D:/game/aola-helper/analysis/reverse-engineering/theme-live-20261004/source/controlv2~2026082731219998.swf' `
  -EvidenceRoot "$themeEvidence/bridge"

# 项目构建串行执行；运行程序锁住普通输出时使用隔离目录。
dotnet build analysis/AolaLoader/AolaLoader.csproj -c Release `
  -p:OutputPath="$themeEvidence/loader/" -p:AppendTargetFrameworkToOutputPath=false
dotnet build analysis/AolaSocketHack.Verify/AolaSocketHack.Verify.csproj -c Release `
  -p:OutputPath="$themeEvidence/verify/" -p:AppendTargetFrameworkToOutputPath=false
& "$themeEvidence/verify/AolaSocketHack.Verify.exe" --theme-live-contract
git diff --check
```

`--theme-live-contract` 是本轮热切换实现提供的检查入口，当前分支包含对应 verifier；从仓库根目录运行，以便检查正确的项目路径。契约通过仍不表示真实 Flash 已验收。

普通输出同步还要注意项目资源使用 `CopyToOutputDirectory=PreserveNewest`。本轮从测试目录复制控制栏时保留了旧时间戳，首次普通构建成功却仍沿用输出目录里的旧核心。随后更新该资源的写入时间并重新构建，确认仓库、普通 Release 输出与测试版的主题叶子、启动桥和控制栏资源一致。下次同步时核对实际输出，不能把“构建 0 错误”当成资源已经替换的证明；不需要增加运行时哈希或资产清单校验。

FFDec 24.1 nightly 3326 是本轮使用的工具。`AccessDeniedException` 日志锁错误曾与成功导出同时出现：查看实际输出、退出状态和后续复读，不能只凭一条日志判断成功或失败。大模块优先定点导出需要的类，不默认导出全部图片和全部源码。

静态检查应针对本次改动，重点是：

- 原具名实例、时间轴、按钮 HitTest 及其引用定义保持；需要更换的三态仍完整。
- ABC 类和 SymbolClass 一致，内部引用使用独立命名空间。
- 原头像/计数/游戏文本及指定恢复的原图仍有对应结构。
- 装饰透明地图点不填充、可见图案点仍填充；监听成对清理；没有新增音频。
- 专用 URL、合法范围、默认放行、旧模式不可用、最新选择和过期回调符合桥契约。

本轮基底的通过数字为 211 条具名放置、217 个原时间轴、81 个按钮点击契约和 29 个导出类。未来基底不同应以它自己的结构为准，不把这组数字当作通用要求，也不追加无关哈希或文件名校验。

## 10. 实机验收与本轮结论

### 10.1 最小实机验收顺序

1. 新进程默认登录；先默认 → 银河 → 默认，确认桥基线。
2. 默认 → 银河 → 新主题 → 银河 → 默认；重复选择、快速选择和重新进入游戏。
3. 上半屏/下半屏同场景空地行走，装饰始终显示；不同窗口比例下检查裁切。
4. 左下人物、客服、地图、聊天、背包、好友等一次点击只执行一次原操作；移入隐藏菜单后保持展开。
5. 组队、场景、活动及其禁用状态正常；消息未读计数/红点/通知气泡正常；切出新主题恢复原图。
6. 战斗中选择，退出战斗且控制栏显示后应用；账号原默认主题能恢复。
7. 同场景、相同 FPS 下观察至少一分钟；切出后新主题动效和监听停止，反复切换不叠加。
8. 确认没有由本地主题替换额外发出的服务器主题设置命令、重新登录或断线。

### 10.2 已知结果与未验证部分

| 证据 | 本轮结果 |
|---|---|
| 用户真实运行 | 官方 controlv2 恢复路径能进入游戏；遐蝶下半屏遮挡得到复现；F8 隐藏装饰恢复行走；非零 alpha 填充轮廓版本在装饰显示时可以行走 |
| SWF 静态 | 最后微调候选的原按钮/实例、类绑定、装饰几何和生命周期检查通过；核心闭包及接口绑定检查通过 |
| HTML 预览 | 七个悬停入口、左下人物和客服命中检查通过；占位地图及账号信息不是真实游戏 |
| Release / 契约 | 最后微调宿主隔离构建 0 错误；既有 CefSharp NU1903 两项提示在还原/构建中重复出现；本轮主题契约与空白检查通过 |
| 普通启动同步 | 默认开关和修复核心已同步到仓库工作区；普通 Release 构建与现有主题契约通过，输出的三个相关资源与测试版一致；用户后续截图确认已进入游戏并显示遐蝶，同时发现图鉴/排行悬停不展开 |
| 最后微调真实运行 | 消息盒子、组队/场景/活动、圆形真实头像、戒指地图和切回其他主题后的恢复尚未取得用户实机结果；此前行走成功不能替代这版完整验收 |

下一次制作前，先读第 1 节确认源码状态，再复用原皮肤部件表和已验证桥；制作时优先处理第 4 节的动态对象和第 7 节的装饰几何。交付时同时保留源图、源代码、生成工具、确认预览与一份已通过实机的候选，避免只剩成品 SWF 或临时测试目录。
