# PetMorph

Status: Target  
ContractVersion: 1  
OwnerPaths: `analysis/AolaLoader/Features/PetMorph/**`, `analysis/AolaLoader/UI/PetMorph/**`, `analysis/AolaLoader/Resources/Patches/**`, `analysis/AolaLoader/Resources/Data/**`

## 职责

拥有形态规则、验证/规范化、PetMorph Section、页面桥状态，以及背包桥接、模型、海报、隐藏模型和头像/背景相关资源规则。

## 非职责

不修改战斗状态/战斗资源，不创建 Cef handler，不发送服务器命令，不用本地宠物/海报资产替代官方远程资源。

## 公开契约

`IPetMorphCoordinator` 提供启用状态、规则快照、校验、保存与页面推送结果；独立资源规则实现 `IResourceRule`；`PetMorphSettings { Version, Enabled, LiveBridgeEnabled, Rules }`。规则键与冲突判定必须确定。

## 输入与输出

输入为 UI 规则、PageBridge 就绪状态和规范化资源请求；输出为不可变规则/桥状态、资源转换计划和明确诊断。

## 允许依赖

Settings Section、BrowserHost PageBridge、ResourceInterception 契约、PetMorph 纯 SWF 转换器和只读 poster catalog。

## 禁止依赖

Battle state/presentation、PacketHost、AolaMainForm、CefSharp/WinForms（UI 子目录除外）及其他模块设置 DTO。

## 线程与生命周期

规则更新串行化并以快照发布；页面调用不在 Cef 回调中阻塞；ExternalInterface 回调避免重入。窗口关闭退订，协调器 Dispose 后停止推送。

## 异常及回退语义

功能关闭完全放行。目标不可用、版本不符、目录无效、模板/长度/类契约/位图转换失败均保持或恢复官方资源；绝不返回损坏/部分 SWF。

## 设置所有权

独占 `petMorph` Section，Version 1；迁移旧 PetMorph 字段并保留三个缺失布尔字段的 false 默认语义。

## 安全约束

精确 host/path/version；输入 16 MiB、输出 64 MiB、位图解压 128 MiB 等既有限制不降低；原始 SWF 与目录只读。

## 缓存语义

规则为不可变快照；探测正/负缓存由管线拥有；桥接模板须在新进程首次进入 ApplicationDomain，热更新只推页面映射。

## 验证入口

关闭/新增/修改/删除规则，冲突校验，近似 URL，模型/海报/隐藏/头像计划，探测和 HTTP 回退，SWF 静态检查及真实背包/重启路径。

## 完成标准

所有形态分支从通用处理器迁出，Section 独立，新增规则无需修改 Theme/Battle；默认与现有形态路径完成实机回归。

## 已知限制

当前形态规则、远程探测和响应适配集中在旧 handler；部分 SWF 候选仅有静态证据，真实 PPAPI Flash 验证仍待完成。

