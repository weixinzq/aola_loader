# 遐蝶·紫夜蝶影 — 设计源与独立主题候选

## 当前交付与边界

用户已确认人物使用银河原有的左下区域，并确认本版整体及动效设计。T2/T3 已生成并接入 `Live/skin10.swf`、主题 10 菜单和 0～10 桥范围；T4 的静态、契约和构建检查通过。2026-10-04 用户在独立热切换入口确认修正装饰填充轮廓后，装饰显示时下半屏可以行走；完整按钮、隐藏菜单及其他切换/性能验收仍待完成。

2026-10-04 视觉修订：按用户新增示意图改为白色兔耳睡衣的 Q 版遐蝶；去掉人物相框和按钮的大外框，让银白蝶翼底栏露出。原点击区域、按钮位置和功能文字保持。新增可悬停展开的隐藏入口预览。

同日贴底修订：删除装饰下面额外绘制的纯色底纹，装饰与底部蝶群/流光/光点下移 33 像素，横向底边贴住 560 像素视口底部，中央垂饰超出视口的部分自然裁切。按钮、人物、文字及点击位置不移动，保留前一轮鼠标命中修正。`preview.html` 同步；本轮整体/底栏/好友预览及失败资源在 `C:/Users/weixi/AppData/Local/Temp/aola-theme10-bottom-align-20261004`，既有 T1 图片仍是之前阶段的证据。离屏预览与 SWF 静态检查通过，实际 Flash 贴底及地图行走仍待确认。

2026-10-05 入口微调：消息盒子使用现有 Q 版；组队/场景/活动为紫银样式；左上角按用户图4增加切角框和圆形真实头像区，保留账号信息/功能。首充、百星按钮及嵌套资源恢复原件；地图按钮原位显示“冥蝶遐思”戒指，去掉“地图”文字，场景名和点击定义保留。戒指输入为用户指定的 `C:/Users/weixi/Pictures/ChatGPT 图像 2026年10月4日 22_54_34.png`，原图与通过 imagegen 去背景的透明候选分别保存为 `mingdie-ring-reference.png`、`mingdie-ring-transparent.png`。

组队和消息盒子由其他游戏服务创建，不能仅替换银河内的占位按钮。`Skin10.as` 在显示期间临时适配实际 `TeamButton`/`ActNotifyIcon` 的图案：原按钮实例、点击区、禁用状态、业务监听和未读 `mcnum` 保留，切出时恢复原图并退订。没有修改这些服务的 SWF、原点击处理或协议提交。`build-skin10.py` 生成十份内部显示素材；四份正常状态同时输出 `preview-external-*.png`，供预览使用，运行时读取的是 SWF 内部资源。

本轮候选和已确认可行走的前版保存在 `C:/Users/weixi/AppData/Local/Temp/aola-theme10-refinement-20261004`。SWF 编译/复读、原按钮和实例契约、透明地图点、既有主题契约、Release 构建及 HTML 预览检查通过。新视觉与实际账号头像、通知提醒、场景/活动/组队、切回银河/默认后的恢复仍待实测；入口为该目录的 `loader/TestThemeLive.cmd`。控制栏候选按已修复流程重新生成，其18个辅助类的29处闭包引用及两处接口绑定检查通过，仅放入独立测试程序；正式开关仍关闭。

| 文件 | 用途 |
|---|---|
| `preview.html` | 可交互的 962×560 设计预览；可展开聊天、暂停动效、查看按钮状态 |
| `preview-overall.png` | 收起聊天时的整体效果图 |
| `preview-chat.png` | 展开聊天时的整体效果图 |
| `preview-friends-hover.png` | 好友悬停：组队、兵团、师徒，鼠标可继续移入子菜单 |
| `preview-backpack-hover.png` | 亚比背包悬停：`mcNXLS/btnNXLS` 新召唤师快捷入口 |
| `preview-blue-entry-hover.png` | 左下人物的蓝宝石按钮悬停反馈；HTML 点击只显示预览反馈 |
| `preview-button-states.png` | 正常、悬停、按下、禁用视觉约定 |
| `preview-panels.png` | 好友、图鉴、排行附属面板的视觉样式；布局细节以原 SWF 为准 |
| `preview-motion.mp4` / `preview-motion.gif` | 8 秒动效预览；人物静态、6 只活动蝶影、10 个小光点、无音轨 |
| `galaxy-parts.csv` | 244 条具名放置记录：路径、资源编号、父时间轴帧号、位置、包围盒、尺寸、点击范围、状态与引用位图 |
| `galaxy-buttons.json` | 81 个按钮定义的 Up/Over/Down/HitTest 资源与局部包围盒，含具名引用路径 |
| `castorice-chibi-reference.png` / `castorice-chibi-v2.png` | 用户给的原参考图与 imagegen 制作的透明 Q 版候选；后者不是官方原图抠图或逐像素复制 |

游戏场景、玩家头像、昵称及聊天内容均为占位，不表示实机画面。角色头像只用于左下主题装饰，不替换玩家头像。预览只检查外观；点击预览按钮不会发游戏命令。生产桥、银河原件和宿主代码未修改。

## 设计约定

- 背景 `#171323`、面板 `#29223E`、雾紫 `#A994D1`、银白 `#EAE6F3`。
- 人物在 `mcBlueGem` 原区域内：约 x=10.30、y=408.85、109×125；蓝宝石入口文字与交互保留。当前使用用户要求的 Q 版透明人物候选，静态、无相框；官方头像与全身图作为之前方案的来源保留。
- 底栏使用银白蝶翼与深紫装饰；地图、背包、聊天、图鉴、排行、商城、好友、舰队、家园等保持原位置与尺寸。
- 8 秒循环、最多 6 只活动蝶影，局部翅膀摆动、紫色流光、小光点。人物、文字、按钮不随动画移动。无声音、全屏闪烁或全屏模糊。
- 收起聊天的设计预览只展示常驻主要控制。功能许可、会员入口、首次付费及提示等动态显隐仍由原游戏决定；未把静态导出里所有隐藏面板同时显示。
- 悬停入口包含好友（组队、兵团、师徒）、背包（新召唤师）、图鉴（全部、皮肤）、排行（最高荣耀、荣誉）、舰队（战队）、家园（订单）、仓库（孵化）。预览模拟显示和收起，不调用游戏业务。菜单在原部件对应的位置展开；实际许可、组队状态及外部服务对象仍遵循 Flash 原逻辑。
- 左下人物不是纯装饰入口：视觉图鼠标透传，下方保留透明的 `btnblue` 点击层。HTML 使用银河第 1 帧按钮 623 的 HitTest 包围盒 (17.30,434.45) / 94×97，悬停亮边、按下变暗、点击显示预览反馈；不会打开或发送蓝宝石业务。相邻客服按钮保持在前，不被透明人物按钮遮挡。T2 必须保留各原帧的实际 HitTest 形状，而不是用人物整张图片矩形替代。
- 银河原件使用四种按钮记录：Up、Over、Down、HitTest。**没有独立 Disabled 记录**。预览的禁用列是降低明度的视觉约定，后续只有原业务明确禁用时才使用；不新增禁用业务。

## 银河拆解依据

只读基底：`analysis/AolaLoader/Resources/Themes/skin9.swf`。

根类 `mmo.controlv2.controlbarskin.skin.Skin9`，SymbolClass 对应 Sprite **1233**，根时间轴 1 帧。SWF 舞台为 **960×560**；本项目页面布局基准为 **962×560**。350 个位图资源、217 个 Sprite 定义、81 个按钮定义，无音频。

下表 x/y 为 **显示包围盒左上角**，不是注册点。静态放置换算包含 `ControlBarSkinBase.addToStage()` 的 (-8.8, 480.4)；聊天和历史面板使用原模块重挂到舞台后的坐标。详细注册点和父帧号在 CSV 中。

| 部件/必要实例名 | 资源编号 | x / y | 显示尺寸 | 处理 |
|---|---:|---:|---:|---|
| 底栏 Shape / 位图 | 61 / 60 | -0.05 / 451.40 | 960 / 109.55 | 换为紫夜蝶翼；原件不覆盖 |
| `mcBlueGem` / `btnblue` | 948 / 623 等 | 10.30 / 408.85 | 109 / 125 | 人物装饰替换；保留蓝宝石入口 |
| `btntalk` | 330 | 125.13 / 498.86 | 66.60 / 61.20 | 保留聊天文字与点击范围 |
| `mcPetDic.btnpetbook` | 362 | 193.70 / 498.83 | 66.60 / 61.20 | 保留图鉴入口及子菜单 |
| `btnbillboardicon` | 334 | 256.95 / 498.65 | 66.60 / 61.20 | 保留排行文字与子菜单 |
| `mcRMBShop.mcIcon.btnRmbShoppingMall` | 288 | 325.44 / 499.56 | 66.60 / 61.20 | 保留商城入口及原动态状态 |
| `btnMap` | 394 | 407.67 / 473.86 | 178.20 / 87.00 | 保留地图文字，换银白蝶翼饰边 |
| `mcBuddyList.btnBuddyList` | 213 | 588.95 / 499.40 | 66.60 / 61.20 | 保留好友及菜单 |
| `mcGalaxyFleet` | 206 | 657.82 / 499.40 | 66.60 / 61.20 | 保留舰队原业务 |
| `btnhouse` | 222 | 726.64 / 499.39 | 66.60 / 61.20 | 保留家园原业务 |
| `btnfarawayconect` | 226 | 795.55 / 499.39 | 66.60 / 61.20 | 原显示文字为“仓库”，悬停展开“孵化”；实例名保持 |
| `mcPetIcon.btnPet` | 990 | 855.45 / 466.90 | 103.20 / 93.00 | 保留亚比背包入口 |
| `mcPlayerInfo` | 1102 | -1.00 / 0.25 | 253.65 / 75.80 | 换框；头像、账号文本、状态来自游戏 |
| `btnSetSkin` | 977 | 437.14 / 499.34 | 20.40 / 20.40 | 保留主题入口 |
| `btnAction` | 448 | 548.95 / 518.24 | 20.40 / 20.40 | 保留动作按钮及动作面板 |
| `mctalkbar.btnSend` | 39 | 303.45 / 490.90 | 50.50 / 24.50 | 保留发送文本及交互 |
| `mctalkbar.txtIn` | 51 | 77.15 / 494.25 | 185.95 / 19.05 | 保留输入 TextField，不烧录成图片 |
| `pnlHistory.txtMsgHolder` | 1205 | 63.85 / 72.75 | 293.30 / 413.00 | 保留聊天输出占位；实际文本由模块生成 |

关键根实例还包括 `mcrightdownfloatbar`、`mcleftdownfloatbar`、`mcrightupfloatbar`、`mcrightdownbtn`、`mcleftdownbtn`、`mcrightupbtn`、`mcNFA`、`mcWeeklyTask`、`mcRestGameTime`、`mcPauseBtn`、`btnonlinecustomericon`、`pnlAction`、`pnlHistory`、`mctalkbar`、`mcBaiXingVip`、`mcShouChong`、`mcRedPackage`、`mcaolamasterredtips`。嵌套必要实例和按钮状态资源见 CSV/JSON，T2 不改名或删除。

### 不能仅凭静态根导出判断的部分

- `mcBlueGem` 948 有 **9 个状态帧**，`btnblue` 分别使用 623、691、754、755、756、819、882、947 等按钮。`BlueIcon.onCheckRedPointState()` 根据首次点击、首充奖励、提醒、会员状态及打开次数切帧。T2 必须覆盖全部相应人物视觉，保留原帧选择和提示，不能只换第 1 帧。
- 位图 60 是海洋底栏，没有人物；真正银河人物在 `mcBlueGem` 内。人物区域此前的“没有独立人物”判断已更正。
- CSV 的 Sprite 包围盒包含第 1 帧中的隐藏提示和菜单。比如历史面板整体并集超过视口，**不表示整个并集运行时都显示**。有多个父帧的记录同样不代表同时出现。
- `HistoryPanelV2.showHistory()` 将 `pnlHistory` 重挂到顶层，位置 (-44.8,-119.2)。`ControlBarSkinBase.onHistoryPanelShow()` 将 `mctalkbar` 放到 (24.15,484.65)，收起时移除；不能给它再加底栏偏移。
- `initializeShootPanle()` 用 `IShootService.getShootButton()` 替换 `btnShootPlace`；`initializeTeamPanle()` 用 `ITeamService.getTeamButton()` 替换 `btnTeam`。**这两处运行时对象不归 skin9 叶子资源所有**。不修改业务的前提下，它们的动态内容保持原样；预览里的射击轮廓只表示原占位区，不能宣称已替换外部服务资源。
- 初始移除 `pnlAction`，隐藏师徒、军团、队伍等菜单，后续由事件恢复。透明人物/动效装饰须与原按钮点击层分离，装饰鼠标透传不等于取消原 `btnblue` 点击层。

### 隐藏入口的原调用链

- 蓝宝石：`ControlBarSkinBase` 构造 → `new BlueIcon(mcBlueGem)` → `BlueIcon.init()` 订阅 `_view.CLICK` → 点击事件从 `btnblue` 冒泡 → `BlueIcon.onClick()` 检查 `event.target.name=="btnblue"` → 更新首次点击/首充提醒与打开次数、原 9 帧状态 → `onBlueGift()` → `LBZH_Utils.getInstance().showTabPanel(-1)`。必须保留 `mcBlueGem`、各帧的 `btnblue` 名称、冒泡层级与 HitTest，不能把它改成鼠标禁用的纯装饰。`ControlBarSkinBase.btnBlueOver()` 当前为空，不据此虚构一个悬停业务菜单；预览亮边是视觉反馈。
- 好友：`ControlBarSkinBase.initializeListeners()` 订阅 `mcBuddyList.MOUSE_OVER` → `onMouseOverBuddyList()` → `setFriendBGVisible(true)`，显示 `btnMaster`、`btnCorps`、外部 `_teamPanel` 与 `mcFriendBG`；`onStageMoveBuddy()` 在鼠标离开入口与整个菜单范围后隐藏。保留所有子对象及监听，不能只制作常驻按钮。
- 背包：`new PetIcon(mcPetIcon)` → `mcNXLS.visible=false` → `ControlBarBtnTipsHelper.init(_view,mcNXLS)` → `onShowTips/onHideTips` 控制显隐；隐藏按钮为 `mcNXLS.btnNXLS`，按钮记录 985 只有 HitTest=984，正常视觉来自父 Sprite 986。因此不能因按钮本身的 Up 为空而删除它。
- 背包隐藏入口点击：`PetIcon.onClickNXLS()` → `Panel_Helper.loadResAndShow("activityres/activity250516/newzhaohuanshi/newzhaohuanshi_code", "mmo.activity250516.newzhaohuanshi.panel.NZHS_MainPl")`。
- 图鉴、排行使用 `ActTipsMc`；家园、仓库使用 `ControlBarBtnTipsHelper`；舰队使用 `onMouseOver/onStageMoveSquad`。这些仍是原控制栏业务，不增加新网络命令。T2 沿用实例、时间轴与点击层，装饰及其根/外层容器自身鼠标透传，子按钮继续交互。

代码证据位于 `analysis/reverse-engineering/theme-live-20261004/official/scripts/mmo/controlv2/controlbarskin/ControlBarSkinBase.as`，以及 `verified4/reread/scripts/mmo/controlv2/pet/PetIcon.as`、`ControlBarBtnTipsHelper.as`。这一段是静态源码结论，不表示新主题在 Flash 中已验证。

## 素材来源

下载日期：2026-10-04。官方素材保持下载原样，没有调色、重绘或生成角色形象。

- 官方角色页：<https://hsr.hoyoverse.com/en-us/character>，条目 Castorice（遐蝶），内容 ID 155153。
- 官方内容接口：<https://sg-public-api.hoyoverse.com/content_v2_user/app/113fe6d3b4514cdd/getContentList?iChanId=242&iPage=1&iPageSize=200&sLangKey=en-us>。原响应角色条目保存在独立证据目录 `official-castorice.json`。
- `castorice-official-pc.png`：官方 `posterPC`，原文件名“遐蝶角色立绘-PC.png”，1683×1441；它包含背景，不宣称是透明人物抠图。<https://fastcdn.hoyoverse.com/content-v2/hkrpg/155153/5a1b2aadf803c47a60c908790245d72a_992221342349773998.png>
- `castorice-official-portrait.png`：官方 `avatarActivePC`，原文件名“遐蝶头像.png”，175×201；第一版预览使用，当前按用户示意图换为 Q 版候选，原图保留。<https://fastcdn.hoyoverse.com/content-v2/hkrpg/155153/74dcae39b1317c6a7add3a4b96af5076_1976654628245733728.png>
- `castorice-chibi-reference.png`：用户本轮提供的示意图 1，来源未核定为官方图；保留原文件。`castorice-chibi-v2.png` 为 imagegen 内置工具据此制作并经用户确认的透明人物素材。参考白色兔耳睡衣、紫发紫瞳、正面全身及左上蝴蝶，存在生成重绘差异。
- 用户指定角色 PV：<https://www.youtube.com/watch?v=_Bt9UA354uo>。本轮人物图片证据来自上面的官方角色页/内容接口，没有把 PV 推断内容当素材来源。
- `ornament-concept.png`：imagegen 内置工具生成并经用户确认的装饰素材（2172×724 RGBA），只参照银河底栏的低矮轮廓。非官方角色素材；原生成图保留。
- 图标、边框、按钮状态和动画轨迹以 `preview.html` 中的 SVG/CSS/时间参数为设计依据；SWF 使用下文的图形生成与 `Skin10.as` 动效源。

完整装饰生成提示见 `ornament-prompt.txt`。使用 imagegen 内置工具，银河位图 60 仅作为轮廓参考；没有把官方角色图交给生成工具重绘。
Q 版人物生成提示见 `chibi-prompt.txt`；输入为用户示意图，输出新文件，不覆盖参考图或之前的官方图。

## 证据与再生成

独立拆解目录：`analysis/reverse-engineering/theme-castorice/T1/`，包含 FFDec XML、SymbolClass、原位图、组件导出、原始日志、角色来源条目、对应表与渲染脚本。

- `map_skin9.py` 从 FFDec XML 生成具名放置表及全部按钮状态定义。只读取原 SWF 的导出结果；父帧和子时间轴第 1 帧规则在脚本中明确。
- `render-preview.cjs` 使用本机 Chrome 与已有 Playwright 渲染预览，`--animate` 导出 192 帧（24 FPS × 8 秒）；MP4/GIF 由已有 ffmpeg 编码。
- 构建产物的主题通配项只包含 SWF，不会把本目录图片和 HTML 接入运行程序。
- 已确认素材用于 T2；HTML 动效始终不属于“Flash 动效已验证”的证据。

## T1 检查（设计预览阶段）

- 浏览器离屏渲染完成，所有预览图片加载正常；人工查看整体、聊天展开及按钮状态截图。
- 本轮追加检查七个悬停入口显示、移出收起；好友菜单和背包入口继续移入子按钮时保持显示。此为 HTML 预览交互检查，不能替代 Flash 验收。
- 追加检查左下蓝宝石按钮悬停、点击预览反馈，以及与人物区域相交的客服按钮仍可命中；未执行真实蓝宝石业务。
- 整体/聊天图为 962×560；MP4 为 962×560、24 FPS、8.000 秒，只有视频流、无音轨；GIF 192 帧、总时长 8.000 秒、无限循环。
- 部件表 244 条，按钮定义 81 个。地图按钮 394 的原记录为 Up=391、Over=392、Down=391、HitTest=393，分别保留记录，不把 HitTest 当成禁用状态。
- T1 的 `git diff --check` 无空白错误，当时工作区变更只有新增 Sources 目录。
- T1 没有构建或启动宿主、登录游戏、发送命令、执行热切换或 Flash 实机验收。

## T2/T3 制作与接入

- `build-skin10.py`：从只读银河 `skin9.swf` 导出 XML，使用现有按钮表生成原位置的正常/悬停/按下素材，替换视觉引用，保留点击定义和命名实例。原件未改动。原空图形占位按钮 343 继续为空；80 个可视按钮均提供三个状态。
- `render-assets.cjs`：用 Chrome/Playwright 将本主题的 SVG/中文功能文字渲染为透明位图；Q 版源图保持不变，仅在原人物区域布局。没有用 Python 重绘或调色源图。
- `Skin10.as`：保留原根实例字段；增加鼠标不响应的底纹/动效容器和局部监听。皮肤根与其控制栏外层仅禁用自身鼠标命中；加入舞台时保存并关闭上层 BaseControl 自身命中，离开时恢复原值，子按钮及隐藏菜单继续交互。6 只蝶、2 段流光、10 光点及短边框银光按时间差循环，人物静态；隐藏暂停，离开舞台退订，再显示成对恢复。
- `theme_bridge_assets.py`：可变长度 ABC 字符串池与 SymbolClass 同步更新；导出根类为 `aola.theme.t10.mmo.controlv2.controlbarskin.skin.Skin10`，29 个导出类使用 `aola.theme.t10` 隔离。没有等长 `Skin9 → Skin10` 替换。
- 个人头像、计数/红点、原文本字段及其他业务实例保留；原服务创建的射击、组队、通知对象仍由服务拥有。本叶子临时更换组队/场景/活动及消息盒子的显示内容，离开舞台恢复；不接管服务器主题设置、控制栏业务或外部 SWF。
- 专用 URL `/play/aola-helper/theme/skin10.swf`；只在热切换模式可选。关闭热切换且保存值为 10 时提示不可用、不推送、不保存覆盖，保持官方资源放行。

### 图鉴与排行悬停菜单修正（2026-10-05）

- 用户在普通仓库版本确认，鼠标停在图鉴/排行时子菜单完全不出现；此前 HTML 预览通过不代表 Flash 交互通过。SWF 中的 `btnPetDic`（全部）、`btnpetskinhandbook`（皮肤）、`btnHonor`（最高荣耀）和 `btnrongyao`（荣誉）仍存在。
- `Skin10` 显示时将 `mcPetDic.btnpetbook` 与 `mcTipsPetDic`、`btnbillboardicon` 与 `mcRankAndRongyao` 配对，补齐悬停显示监听；图鉴同时监听原 `ActTipsMc` 使用的 `mcPetDic` 容器。监听在原处理之后更新显示，用 `relatedObject` 和 `menu.contains` 保持主按钮、菜单及其子按钮之间的移动；真正离开才收起，主按钮禁用时不展开。
- 切出主题时关闭菜单并退订，重新显示时重新注册。只改变菜单显示，不新增点击处理、不更换业务实例或点击区域，不改地图透明轮廓。静态复读检查覆盖上述配对、退订与四个原子按钮；真实悬停、移入、点击及反复切换仍需实机确认。

### 再生成命令

从仓库根目录运行（使用本机已有 Python/Pillow、Node/Playwright、Chrome 与 FFDec）：

```powershell
$env:NODE_PATH = 'C:\Users\weixi\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules'
python analysis/AolaLoader/Resources/Themes/Sources/Castorice/build-skin10.py
python analysis/AolaLoader/Resources/Themes/Sources/Castorice/verify-skin10.py
node analysis/AolaLoader/Resources/Themes/Sources/Castorice/verify-page-bridge.cjs
```

候选、逐状态替换表、透明位图、XML 和静态复读保存在 `analysis/reverse-engineering/theme-castorice/T2/`；生成器不会覆盖生产资源。完整控制栏候选流程 `analysis/tools/Prepare-ThemeLiveBridge.ps1` 也纳入本生成器。

`patch-start-range.py --source <原9上限启动桥>` 仅用于将已保留的旧候选扩展到 10；默认输出独立 `T2/start/start-theme10.swf`。可使用本轮保留的 `T2/start/start-before.swf` 再生成。FFDec 定位目标操作数后，结果保留原桥全部字节，仅一字节 9→10；不重新编译其他方法。

## T4 静态与构建结果

2026-10-04 用户实机发现刚登录默认主题就卡在 100% [1/1]，主题回调报 `Error #1065`；此时尚未请求主题 10。热切换 controlv2 候选已默认停用，正常启动使用官方模块和原 1～9 刷新路径，主题 10 的素材及候选继续保留。恢复宿主位于 `analysis/.theme10-recovery-build/loader`，用户已确认该版本可以进入游戏；主题 10 的实机验收继续依赖修复后的基础热切换验证。

仅修复定义查询的独立测试仍失败，新增静态核对确认控制栏重编译改变了方法编号，而监听补丁仍引用原编号的匿名回调；同时丢失两处主题服务接口命名空间。生成器已修复这两项问题，18 个辅助类的闭包引用和官方回调代码已核对。新的独立入口为 `C:/Users/weixi/AppData/Local/Temp/aola-theme10-index-test-20261004/loader/TestThemeLive.cmd`；素材/主题 10 视觉不改，正式路径仍关闭热切换，新候选实机验收未完成。

用户随后确认能进入游戏并显示遐蝶，但其下半屏地图点击被拦截，切回其他主题正常。装饰矩形在视口 y≈277～598；已在叶子类关闭根与外层容器自身鼠标命中，保留子按钮策略，视觉不变。新增定向复读检查在旧叶子失败，在修正候选通过，原按钮/具名实例契约继续通过；候选和失败资源保留在 `C:/Users/weixi/AppData/Local/Temp/aola-theme10-mouse-fix-20261004`。生产主题 10 和上述独立测试入口已更新，核心控制栏不变；必须退出并重启测试程序，修正后的地图行走及按钮实机结果仍待确认。

上一版两层鼠标修正实测仍失败。官方当前 loader/play 静态源码确认，控制栏的更上层 BaseControl 默认可命中，地图行走监听只位于同级 BaseScene；本次追加 BaseControl 自身命中的保存/临时关闭/移出恢复，不关闭子按钮，不改地图代码。新候选编译、定向复读和原按钮契约通过，所有非 ABC 标签不变；证据及上一版失败叶子位于 `C:/Users/weixi/AppData/Local/Temp/aola-theme10-hit-geometry-20261004`。资源更新到上述同一测试入口，实机恢复仍待用户重启确认。

用户随后确认 BaseControl/贴底版本的地图故障仍存在，上述鼠标层修改未通过真实验收。当前独立入口临时加载点击探针（页面右上 `Theme10 hit probe 1`）：捕获点击坐标、目标/祖先显示类及鼠标标志；F8 隐藏/恢复新增装饰，不关闭原按钮。记录保存在页面 `window.aolaThemeHitDiagnostics`，不读取账号/聊天/协议字段。探针源码及前版 SWF 在 `C:/Users/weixi/AppData/Local/Temp/aola-theme10-click-probe-20261004`，不写入本目录生产源或正式叶子；下一步依赖实际点击目标证据，不能把探针编译通过当故障恢复。

用户已确认 F8 隐藏新增装饰/动效后可以行走，拦截范围收窄到这两部分。新轮廓候选只改变装饰 Shape 2121：`build-skin10.py` 用原 PNG 非零 alpha 像素生成填充区域，透明留白不再是填充矩形；图片、位图矩阵、贴底位置及按钮保持。`verify-skin10.py` 复读边线的七点检查在旧资源失败、新候选通过，原按钮等契约通过，非 ABC 标签只有该 Shape 改变。用户在同一独立测试入口的 `Theme10 hit probe 2 alpha contour` 版本确认，装饰显示时可以行走。通过的探针资源、前版失败资源及干净候选保存在 `C:/Users/weixi/AppData/Local/Temp/aola-theme10-alpha-geometry-20261004`；正式叶子与同一测试入口已更新为干净候选，移除临时探针及 F8 操作。此实测只确认地图点击恢复，不替代其余按钮/切换/性能验收，也未启用正式热切换开关。

- `verify-skin10.py`：211 条具名放置、217 个原时间轴帧数、81 个按钮点击契约及其引用定义匹配；原空按钮保留，80 个可视按钮三个状态存在；29 个 SymbolClass 与 ABC 构造类匹配；蓝宝石九个帧保留；装饰鼠标隔离/局部生命周期方法存在，无音频。
- 启动桥候选与保留的当前基线等长，只有偏移 7027 的主题上限操作数 9→10；官方 SWF 原件、银河及主题 1～9 没有改动。
- `--theme-live-contract` 通过，包含主题 10、专用路径边界、保存值 10 的旧模式不可用/零推送/零改写、最新选择与过期回调，以及既有页面/主动发送契约。
- `verify-page-bridge.cjs` 执行生产页面脚本，模拟 Flash 端点：10 可用、-1/11/小数拒绝，旧/错误主题回调忽略，等待战斗/尚未就绪、失败缓存、重建页与默认恢复通过。此为模拟，不是真实 ExternalInterface。
- Loader、SocketHack、Contracts 及 Verify 串行 Release 构建通过，0 错误；宿主仍报告既有 CefSharp 两项 NU1903（还原/构建重复显示，共四条）。隔离输出 `analysis/.theme10-build/loader` 与 `verify`、`hook`，不覆盖运行中的输出。
- 真实验收仍待进行：先“默认→银河→默认”，再“默认→银河→遐蝶→银河→默认”；快速选择、重进游戏、战斗延后、隐藏入口/左下蓝宝石/客服一点击一操作、不同窗口比例及同场景 FPS 一分钟比较。没有启动游戏、登录、发送命令或记录 Flash 运行成功。
