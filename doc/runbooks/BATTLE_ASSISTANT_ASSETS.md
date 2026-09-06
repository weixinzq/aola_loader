# 对战助手图片准备

助手仅加载输出目录中的 `Resources/BattleAssistant`，不依赖 `data`、逆向目录或 FFDec。图片按 `类别/配置编号.png` 保存；`pet` 使用基础种族编号。`catalog.json` 是随程序分发的名称和说明目录。当前请求清单覆盖所提供 PVP 样本及已记录的缺图编号，不代表全部游戏资源。

## 准备入口

维护者需要 Python 3、Pillow、curl、FFDec，以及 reverse-engineer-swf 的 `inspect_swf.py`。先阅读 `data/organized-data/README.md`，确认静态表和对应官方反编译批次。修改 `analysis/AolaLoader/Resources/Data/battle-assistant-assets.json` 的 `requested` 编号列表后运行：

```powershell
& .\analysis\tools\Prepare-BattleAssistantAssets.ps1 -StagingRoot 'D:\game\aola-update\archive\.staging\20260903-161431320-202609031788446714-feb5bf04'
```

可用 `-IdList` 指定同结构输入，`-DataDirectory` 指定整理表目录，`-FFDec` 和 `-Inspector` 指定准备工具路径。输出仍写入本项目资源目录。完成后构建 AolaLoader，将图片和目录一起复制到分发目录。

补齐运行中已经遇到的缺图，可追加 `-MissingList "$env:LOCALAPPDATA\AolaLoader\battle-assets-missing.txt"`，工具会合并并去重该清单中的编号，再准备新增图片。助手仍不在战斗时下载资源。

## 官方依据

- `PetIconConfig`、`PetIconLoader_Static_New`：基础种族编号对应 `peticon/icon/type0/peticonN/peticonN`，导出类 `mmo.peticon.icon.type0.PetIconN`。读取同包配置的 x/y，按 FIGHT 的 60×60 窗口裁切，禁止直接展示整张大图。编号低于 4400 按 `PetIconLoader_Static_Old.getClsName(FIGHT)` 使用 `peticon/peticonN` 中的专用 `mmo.pet.peticonN_F` 导出类首帧。
- 扩展种族编号按 `PetIconContainer` / `PetIconLoaderBase` 的官方规则先取 `% 10000` 决定资源编号，例如 `124891` 对应资源 `4891`；运行时缓存键仍保留原始种族编号，避免改写战斗数据。
- `PetCardViewCreator`：沿装备升级前驱找到基础配置；根据其 `viewId` 选择专属导出类或官方类型/品质图标。实例编号不参与图片查找。
- `HKViewCreator`、`ToteViewCreator`、`CrystalKeyViewCreator`：按各自配置编号和官方导出类提取第一帧。魂卡使用官方 S 尺寸。
- `VersManager.getVersion/getVerURLRequest`：优先使用批次 `effective-index.json` 的版本，SWF 不在版本表时官方缺省为 `1210`；资源根来自该批次来源清单的 `https://aola.100bt.com/play/`。
- 名称/说明来自整理表；晶钥补读 `CrystalKeyData.as`，实际魂器词条名称补读 `ToteValueSource.as`。静态魂卡词条关系保留在目录，但不假装成实时随机词条。

## 产物与异常

原始 SWF、检查结果、FFDec 日志和导出资源保留在 `analysis/reverse-engineering/battle-assistant-assets/exports`，不修改游戏或原客户端。每项记录 URL、版本、导出类、原始大小/SHA-256、图片 SHA-256 和裁切范围。优先复用批次本地资源；没有本地文件时下载已确认的官方 URL。

工具输出成功、缺失、失败清单；单项失败保留已有有效图片。发现未确认的类别、类名或裁切映射时停止该项，先向维护者核对。运行时缺图待补清单位于 `%LOCALAPPDATA%/AolaLoader/battle-assets-missing.txt`，可据此补充 `requested`。不要将抓包或逆向原件加入公开资源目录。

## 验证边界

生成成功仅证明本地图片产物通过导出和读取检查。应抽查头像和四类配置图片与名称一致，再在属性/配置页检查悬停、缩放、滚动和 DPI。可用验证器 `--battle-sample data/battele.json` 回放该 16 条连续 JSON 样本；该检查不发送流量。真实 PVP/PVE 与视觉效果必须另行验收，构建和样本回放不等于实机通过。

对旧日志 `battele_0906.json`，按用户确认的己方/敌方编号运行 `--battle-sample data/battele_0906.json 244677147 94617668`。该文件包含三场战斗、10 条记录，覆盖双方同在 `2303` 和 `2303/2304` 分开发送两种形式。新日志自带 `connectionPlayerId`，生产程序无需配置账号编号。
