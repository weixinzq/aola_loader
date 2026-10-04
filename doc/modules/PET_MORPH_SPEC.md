# PetMorph

Status: Implemented
ContractVersion: 1  
OwnerPaths: `analysis/AolaLoader/Features/PetMorph/**`, `analysis/AolaLoader/UI/PetMorph/**`, `analysis/AolaLoader/Resources/Patches/**`, `analysis/AolaLoader/Resources/Data/**`

## 职责

拥有形态规则、验证/规范化、PetMorph Section、页面桥状态，以及背包桥接、模型、目标皮肤语义、海报、隐藏模型和头像/背景相关资源规则。

## 非职责

不修改战斗状态/战斗资源，不创建 Cef handler，不发送服务器命令，不用本地宠物/海报资产替代官方远程资源。

## 公开契约

`IPetMorphCoordinator` 提供启用状态、规则快照、校验、保存与页面推送结果；`IPetMorphRuleTarget.GetAvailableLiveSkinMappingsAsync` 只返回通过 poster catalog 与官方背景探测的目标皮肤映射；独立资源规则实现 `IResourceInterceptionRule`；`PetMorphSettings { Version, Enabled, LiveBridgeEnabled, Rules }`。规则键与冲突判定必须确定。

## 输入与输出

输入为 UI 规则、PageBridge 就绪状态和规范化资源请求；输出为不可变规则/桥状态、目标皮肤映射、资源转换计划和明确诊断。显式 `PosterId` 优先；未填写时，满足目录与背景探测的 `BackpackId` 自动作为目标皮肤。设置结构和规则编辑界面不新增字段。

`Resources/Data/pet-poster-catalog.json` 由 `analysis/tools/generate_pet_poster_catalog.py` 从 `PetSkinConfig.as` 生成；2026-09-30 更新的源配置有 1060 项，目录只收录其中 426 项 `hasBackground=true` 的映射。

## 允许依赖

Settings Section、BrowserHost PageBridge、ResourceInterception 契约、PetMorph 纯 SWF 转换器和只读 poster catalog。

## 禁止依赖

Battle state/presentation、PacketHost、AolaMainForm、CefSharp/WinForms（UI 子目录除外）及其他模块设置 DTO。

## 线程与生命周期

规则更新串行化并以快照发布；页面调用不在 Cef 回调中阻塞；ExternalInterface 回调避免重入。窗口关闭退订，协调器 Dispose 后停止推送。

## 异常及回退语义

功能关闭完全放行。目标不可用、目录无效、模板/长度/类契约/位图转换失败均保持或恢复官方资源；绝不返回损坏/部分 SWF。目标皮肤背景使用独立的 32 MiB 探测上限，因为 5436 官方 ZWS 的响应长度为 16,791,137 字节、声明解压长度为 20,971,028 字节，不能沿用普通资源的 16 MiB 上限。有可用目标皮肤映射时，“移除原背景”只移除源语义并加载目标官方背景；目标背景不可用时不下发映射，并维持原有隐藏行为。

## 设置所有权

独占 `petMorph` Section，Version 1；迁移旧 PetMorph 字段并保留三个缺失布尔字段的 false 默认语义。

规则编辑界面不再暴露“移除原背景”和“替换背包头像”开关：模型映射固定派生为移除源背景并替换目标头像；仅隐藏模型的规则只移除源背景；纯海报规则不产生模型背景或头像操作。窗口初始及每次新增成功后保持“新增规则”模式，只有用户明确选择列表行才进入编辑模式，新增时不得按相同键静默覆盖已有规则。

## 安全约束

精确 host/path/version；输入 16 MiB、输出 64 MiB、位图解压 128 MiB 等既有限制不降低；原始 SWF 与目录只读。

## 缓存语义

规则为不可变快照；探测正/负缓存由管线拥有；桥接模板须在新进程首次进入 ApplicationDomain，热更新推送目标皮肤、背景隐藏和头像映射，并触发当前背包重新计算海报、闪耀、互动、语音、幻动和出场特效控件。

## 验证入口

关闭/新增/修改/删除规则，冲突校验，`BackpackId` 自动目标映射与显式 `PosterId` 优先级，近似 URL，模型/海报/隐藏/头像计划，探测和 HTTP 回退，SWF 静态检查及真实背包/重启路径。`newpetpackage` 只按主机及 `/play/pet/newpetpackage~<数字版本>.swf` 路径识别，任意数字版本都强制返回本地补丁；模板必须同时包含控制栏标记 `getAolaMorphControlSkinId` 和带真实种族兜底的统一视觉解析标记 `getAolaMorphVisualSkinIdByRace`。这保证模块版本号与全局版本号不一致时仍能命中，并拒绝只检查 `viewId`/`specialSkinId`、仍可能按源特殊皮肤决定互动控件的旧补丁；官方以后若改变类契约，本地补丁不会自动兼容，必须实机回归并更新补丁。

## 完成标准

所有形态分支从通用处理器迁出，Section 独立，新增规则无需修改 Theme/Battle；默认与现有形态路径完成实机回归。

## 已知限制

`IPetMorphCoordinator`/`PetMorphCoordinator` 已拥有规则应用、校验、Section 保存、资源规则更新和页面推送；`AolaResourceRequestHandler` 仅通过 `IPetMorphRuleTarget` 接入。形态面板位于 `UI/PetMorph`，领域对象位于 `Features/PetMorph`，Cef 推送适配器位于 `AppShell/Adapters/PetMorph`。背包背景、独立模型显示规则和 `PackageControlBar` 统一按 `viewId → raceId → specialSkinId` 查找形态映射：任一真实宠物身份字段命中 `OriginalId` 后，目标映射都优先于源宠物自带的 `specialSkinId`。由此闪耀、互动、语音、幻动和出场特效均读取目标皮肤元数据，而真实宠物 `pbi.id`、`raceId`、骑乘、养成和服务器操作仍使用原始数据。阶段 9 真实验证覆盖开关、保存、热推送、背景移除、头像替换、动态模型替换、窗口重开和新进程恢复；5399 与 5436 等闪耀皮肤还需分别实机确认“闪耀”按钮、手掌提示及背景互动。阶段 9 同时修复远程 PetMovie 为 ZWS 时被 FWS-only 转换器拒绝的问题；真实 6000→6044 四分片已通过运行和 FFDec 复读。
