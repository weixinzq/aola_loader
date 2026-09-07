# petfightnew 每周更新

本手册用于在官方 `petfightnew` 版本变化时重新生成 Bridge Version 4 战斗状态与演出桥。不得把旧候选改名复用，也不得覆盖官方原件。流水线只自动生成候选；晋级和真实 Flash 验证必须由维护者明确执行。

## 前置条件

- 从仓库根目录运行 PowerShell。
- Python 可从 `PATH` 调用。
- FFDec CLI 默认位于 `D:\Programs\FFdec\ffdec-cli.exe`；其他位置用 `-FFDecPath` 指定。
- 网络能访问 `https://aola.100bt.com/play/start.xml` 及其引用的官方资源。
- 开始前检查 Git 状态，确认不会覆盖未提交的用户修改。
- 核对 `analysis/tools/petfight_bridge_abc.py`、`analysis/tools/petfight/DocPetFight.bridge.template.as` 和 `analysis/tools/petfight/New-PetFightPresentationPatches.ps1` 均存在；当前脚本在进入任何模式前就检查这些文件及 FFDec/Python。
- 2026-09-05 核对发现 `New-PetFightPresentationPatches.ps1` 在本机存在但被 Git 忽略；公开检出若缺少它，Check/Prepare/Promote 都会在前置检查失败。本次只更新说明，未改变分发规则。

## 1. 检测版本

```powershell
.\analysis\tools\Update-PetFightBattleBridge.ps1 -Mode Check
```

脚本按 `start.xml → versiondata → pet/petfightnew` 解析唯一精确映射。`Current` 表示生产清单与官方映射一致；`UpdateRequired` 只表示需要制作新候选，不允许手工改版本号绕过后续验证。网络失败、重复映射或无效版本会直接失败。

## 2. 生成候选

```powershell
.\analysis\tools\Update-PetFightBattleBridge.ps1 -Mode Prepare
```

默认在 `analysis/reverse-engineering/battle-bridge-日期-资源版本/` 创建独立证据目录并保存：

- `source/`：官方压缩 SWF、`start.xml`、`versiondata` 和嵌入映射；
- `variants/`：从官方文件解压的 FWS 与版本化候选；
- `decompiled/`、`exports/`：FFDec ActionScript、p-code、SymbolClass、状态桥输入和 16 个演出方法补丁；
- `metadata/candidate-manifest.json`：候选版本、URL、长度和哈希；
- `metadata/compatibility-report.md`：方法体编号、SymbolClass 和允许差异；
- `evidence/`：额外静态验证与后续运行证据。

`Prepare` 每次从新版官方 SWF 开始，动态查找方法体编号。出现以下任一情况必须停止，不得晋级：

- `DocPetFight` 不再是已知的简单文档类，基类或 Embed 契约变化；
- `PetFightService.init` 或 `FightPanel.enableClick` 缺失、重复、包含多个 `returnvoid`；
- 任一演出目标方法、插入锚点或私有命名空间缺失/重复；
- `FightData.battleId = params.br` 的身份来源变化；
- 同版本 SymbolClass 不一致，或白名单类的指定方法以外出现 p-code 差异；
- 三个 ExternalInterface 回调、两个桥调用、三个设置标记、FWS 长度或 SHA-256 校验失败；
- 候选仍出现 `skipAttackAnimation`、`skipPetAttackActions` 或 `skipBattleVisualDelays` 历史标记。

## 3. 人工审阅

先阅读 `metadata/compatibility-report.md`，再核对以下允许修改：

1. `DocPetFight` 注册 `aolaBattleBridgeReady`、`aolaBattleApplyOptions`、`aolaBattleGetState`，保持 Bridge Version 4 状态语义并严格接收 `skipBattlePresentation`。
2. `PetFightService.init` 的唯一结束位置前调用一次 `DocPetFight.ensureAolaBattleBridge()`。
3. `FightPanel.enableClick` 完成官方输入初始化后，在唯一结束位置前调用一次 `DocPetFight.noteInputReady()`。
4. `UseSkill.handleUseSkill`、`handleAnnalFeeEight`、`handleMovie` 只增加无影片结算分支，并保留 `refreshInfos`、`setBS`、`setBackGroundUp`、`setPetUp`、`handleSkillEnd` 和官方终端回调。
5. `SwitchPm.showSwitchMc`、`ChangePetView.onGotPet/onPetChange`、`BattlePmDying.showPetDieEffect`、`BattleNextTurn.checkPlayMovie` 只增加立即终态/完成路径。
6. `SkillResultMovieHandler` 只修改八个 HP 数字叶方法；`showMultipleHit` 必须按 `_hpInc` 正负分别检查治疗/伤害开关，`startMovie` 不得被短路。

不得接受白名单以外的方法修改，也不得修改 `IGameOptionService.fightSkillEffect`、`FightData.isLowQuality`、开战入场或胜负结算路径。必要时对候选再运行独立验证：

```powershell
python C:\Users\weixi\.codex\skills\reverse-engineer-swf\scripts\verify_swf.py `
  候选完整路径 --compare 同版本官方FWS完整路径 `
  --ffdec D:\Programs\FFdec\ffdec-cli.exe `
  --expected-class DocPetFight --expected-class PetFightService --expected-class FightPanel `
  --expected-method ensureAolaBattleBridge --expected-method noteInputReady
```

## 4. 明确晋级

只把 `Prepare` 输出的确切 `candidateManifest` 路径传给 `Promote`：

```powershell
.\analysis\tools\Update-PetFightBattleBridge.ps1 -Mode Promote `
  -CandidateManifest <candidate-manifest.json完整路径>
```

`Promote` 不下载、不重新生成，也不选择“最新目录”。它重新检查证据后备份现有生产文件，并更新：

- `analysis/AolaLoader/Resources/Patches/petfightnew-battle-state-current.fws.swf`
- `analysis/AolaLoader/Resources/Patches/petfightnew-battle-state.current.json`

旧官方文件、旧候选和旧清单保留在版本证据目录中，不覆盖、不删除。

## 5. 自动验证

依次运行，避免共享输出目录竞争：

```powershell
dotnet build .\analysis\AolaLoader\AolaLoader.csproj -c Release
dotnet build .\analysis\AolaSocketHack.Verify\AolaSocketHack.Verify.csproj -c Release
dotnet run --project .\analysis\AolaSocketHack.Verify\AolaSocketHack.Verify.csproj -c Release --no-build -- --self-test
git diff --check
```

PCAP 为可选的独立验证：当前工作区不含旧 `analysis/loader` 和其中的私有抓包，也不再运行旧 `scripts.verify`。维护者持有获授权的本地抓包时，另行运行（替换示例路径和实际 stream）：

```powershell
dotnet run --project .\analysis\AolaSocketHack.Verify\AolaSocketHack.Verify.csproj -c Release --no-build -- D:\Programs\Wireshark\tshark.exe D:\local-evidence\capture.pcapng 2
```

独立 OfflineClient 测试入口见其 README；它不验证 Flash SWF 周更。历史固定 PCAP 基线为 `exportable=164`、`failures=0`、`export_format=True`、`login_redacted=True`、`inner_plaintext=True`、`active_send=True` 和 `PASS`。这些自动结果不证明真实服务器执行，也不证明 Flash 仍可正常加载。

## 6. 两轮真实 Flash 验证

每轮都完全退出 AolaLoader 和 Flash/CEF 子进程后重新启动，以排除 CEF 内存缓存、磁盘缓存和 Flash ApplicationDomain 缓存混淆。

第一轮暂不提供生产清单，让规则安全透传官方新版：

- 确认请求 URL 是当前官方版本，返回内容是官方哈希；
- 正常登录、进入战斗、手工操作、换宠、献祭增强、结束并再次进入战斗。

第二轮恢复已晋级清单并使用全新进程：

- 确认请求精确命中清单版本，返回哈希等于清单 `candidateSha256`；
- 确认桥 Ready，进入战斗后 turn 0/1/2 按真实状态逐回合各发送一次；
- 确认后续手工操作、换宠、献祭增强、战斗结束和再次进入战斗正常；
- 确认没有新增游戏 TCP 连接、重复登录或后续消息序列损坏。

`SubmittedToFlash` 只表示调用已交给 Flash，不能作为服务器成功证据。`SkipBattlePresentation` 只有在收到 `BattleOptionsApplied|revision` 后才算提交到 Flash；仍需用真实战斗证明每回合演出被跳过且状态链未损坏。

## 7. 记录或回滚

进入验证步骤前先点击主窗口“保留日志”；完整日志默认关闭，启用前的消息不会补记。把请求 URL、官方/候选哈希、进程重启、桥 Ready、回合发送、连接数量和战斗操作结果写入该版本的 `evidence/`。任一步失败时，完全退出宿主及 Flash/CEF 子进程，恢复 `Promote` 输出的 `rollbackEvidence` 中与当前宿主契约兼容的上一组稳定文件，重新构建/复制到实际运行目录后再启动。如果没有兼容候选，则从实际运行目录移除生产清单以恢复官方透传。当前宿主严格要求 Bridge Version 4；仅放回旧 Version 3 清单与 SWF 会触发透传，不能恢复 Version 3 状态功能，恢复旧功能需要配套的旧宿主版本。保留失败候选和日志，不在原证据目录上继续覆盖。
