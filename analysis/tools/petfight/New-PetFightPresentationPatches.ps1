[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PcodeRoot,
    [Parameter(Mandatory = $true)]
    [string]$OriginalFws,
    [Parameter(Mandatory = $true)]
    [string]$HelperPath,
    [Parameter(Mandatory = $true)]
    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'

function Assert-One([object[]]$Items, [string]$Description) {
    if ($Items.Count -ne 1) {
        throw "Expected exactly one $Description, found $($Items.Count)."
    }
    return $Items[0]
}

function Get-MethodFragment([string]$Path, [string]$Signature) {
    $lines = @(Get-Content -LiteralPath $Path)
    $signatureIndexes = @()
    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($lines[$index].Contains($Signature)) { $signatureIndexes += $index }
    }
    $signatureIndex = [int](Assert-One $signatureIndexes "signature '$Signature'")
    $methodIndex = -1
    for ($index = $signatureIndex; $index -lt $lines.Count; $index++) {
        if ($lines[$index].Trim() -eq 'method') { $methodIndex = $index; break }
    }
    $endIndex = -1
    for ($index = $methodIndex + 1; $index -lt $lines.Count; $index++) {
        if ($lines[$index].Trim() -eq 'end ; method') { $endIndex = $index; break }
    }
    if ($methodIndex -lt 0 -or $endIndex -lt 0) {
        throw "Method block not found for '$Signature'."
    }
    return ,([Collections.Generic.List[string]]::new([string[]]$lines[$methodIndex..$endIndex]))
}

function Find-Line([Collections.Generic.List[string]]$Lines, [string]$Value) {
    $matches = @()
    for ($index = 0; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index].Trim() -ceq $Value) { $matches += $index }
    }
    return [int](Assert-One $matches "line '$Value'")
}

function Insert-After([Collections.Generic.List[string]]$Lines, [string]$Value, [string[]]$Addition) {
    $Lines.InsertRange((Find-Line $Lines $Value) + 1, $Addition)
}

function Insert-AfterLast([Collections.Generic.List[string]]$Lines, [string]$Value, [string[]]$Addition) {
    $matches = @()
    for ($index = 0; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index].Trim() -ceq $Value) { $matches += $index }
    }
    if ($matches.Count -lt 1) { throw "Expected at least one line '$Value'." }
    $Lines.InsertRange(([int]$matches[-1]) + 1, $Addition)
}

function Get-PrivateNamespaceId([Collections.Generic.List[string]]$Lines, [string]$Member) {
    $escapedMember = [regex]::Escape($Member)
    $ids = @($Lines | ForEach-Object {
        $match = [regex]::Match($_, 'PrivateNamespace\(null,"(?<id>\d+)"\),"' + $escapedMember + '"')
        if ($match.Success) { $match.Groups['id'].Value }
    } | Sort-Object -Unique)
    return [string](Assert-One $ids "private namespace for '$Member'")
}

function Save-Fragment([Collections.Generic.List[string]]$Lines, [string]$Name) {
    $path = Join-Path $OutputDirectory $Name
    if (Test-Path -LiteralPath $path) {
        throw "Refusing to overwrite generated patch fragment: $path"
    }
    [IO.File]::WriteAllLines($path, [string[]]$Lines, [Text.UTF8Encoding]::new($false))
    return $path
}

function New-BooleanGuard([string]$Property, [string]$ContinueLabel) {
    return @(
        ' getlex QName(PackageNamespace("mmo.petfightnew"),"DocPetFight")',
        " getproperty QName(PackageNamespace(`"`"),`"$Property`")",
        " iffalse $ContinueLabel")
}

function Get-MethodBodies([object[]]$Targets) {
    $arguments = @($HelperPath, 'methods', '--input', $OriginalFws)
    foreach ($target in $Targets) { $arguments += @('--target', [string]$target.Target) }
    $output = & python @arguments
    if ($LASTEXITCODE -ne 0) { throw 'Presentation method-body discovery failed.' }
    $found = @(($output -join [Environment]::NewLine) | ConvertFrom-Json)
    if ($found.Count -ne $Targets.Count) {
        throw "Expected $($Targets.Count) presentation methods, found $($found.Count)."
    }
    $result = @{}
    foreach ($target in $Targets) {
        $match = @($found | Where-Object {
            $_.className -ceq $target.Class -and $_.methodName -ceq $target.Method
        })
        if ($match.Count -ne 1) {
            throw "Method-body discovery was not unique for $($target.Target)."
        }
        $result[[string]$target.Target] = [int]$match[0].methodBodyIndex
    }
    return $result
}

foreach ($path in @($PcodeRoot, $OriginalFws, $HelperPath)) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Required presentation input is missing: $path" }
}
if (Test-Path -LiteralPath $OutputDirectory) {
    if (@(Get-ChildItem -LiteralPath $OutputDirectory -Force).Count -ne 0) {
        throw "Presentation patch directory must be empty: $OutputDirectory"
    }
} else {
    New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
}

$targets = @(
    [pscustomobject]@{ Class = 'mmo.petfightnew.common.fightcontroller.UseSkill'; Method = 'handleUseSkill'; Target = 'mmo.petfightnew.common.fightcontroller.UseSkill:handleUseSkill'; Signature = 'public function handleUseSkill(' },
    [pscustomobject]@{ Class = 'mmo.petfightnew.common.fightcontroller.UseSkill'; Method = 'handleAnnalFeeEight'; Target = 'mmo.petfightnew.common.fightcontroller.UseSkill:handleAnnalFeeEight'; Signature = 'private function handleAnnalFeeEight(' },
    [pscustomobject]@{ Class = 'mmo.petfightnew.common.fightcontroller.UseSkill'; Method = 'handleMovie'; Target = 'mmo.petfightnew.common.fightcontroller.UseSkill:handleMovie'; Signature = 'private function handleMovie(' },
    [pscustomobject]@{ Class = 'mmo.petfightnew.common.fightcontroller.SwitchPm'; Method = 'showSwitchMc'; Target = 'mmo.petfightnew.common.fightcontroller.SwitchPm:showSwitchMc'; Signature = 'private function showSwitchMc(' },
    [pscustomobject]@{ Class = 'mmo.petfightnew.common.fightcontroller.ChangePetView'; Method = 'onGotPet'; Target = 'mmo.petfightnew.common.fightcontroller.ChangePetView:onGotPet'; Signature = 'private function onGotPet(' },
    [pscustomobject]@{ Class = 'mmo.petfightnew.common.fightcontroller.ChangePetView'; Method = 'onPetChange'; Target = 'mmo.petfightnew.common.fightcontroller.ChangePetView:onPetChange'; Signature = 'private function onPetChange(' },
    [pscustomobject]@{ Class = 'mmo.petfightnew.common.fightcontroller.BattlePmDying'; Method = 'showPetDieEffect'; Target = 'mmo.petfightnew.common.fightcontroller.BattlePmDying:showPetDieEffect'; Signature = 'private function showPetDieEffect(' },
    [pscustomobject]@{ Class = 'mmo.petfightnew.common.fightcontroller.BattleNextTurn'; Method = 'checkPlayMovie'; Target = 'mmo.petfightnew.common.fightcontroller.BattleNextTurn:checkPlayMovie'; Signature = 'private function checkPlayMovie(' },
    [pscustomobject]@{ Class = 'mmo.petfightnew.common.SkillResultMovieHandler'; Method = 'showMultipleHit'; Target = 'mmo.petfightnew.common.SkillResultMovieHandler:showMultipleHit'; Signature = 'private function showMultipleHit(' },
    [pscustomobject]@{ Class = 'mmo.petfightnew.common.SkillResultMovieHandler'; Method = 'showIncMovie'; Target = 'mmo.petfightnew.common.SkillResultMovieHandler:showIncMovie'; Signature = 'private function showIncMovie(' },
    [pscustomobject]@{ Class = 'mmo.petfightnew.common.SkillResultMovieHandler'; Method = 'showReallyHit'; Target = 'mmo.petfightnew.common.SkillResultMovieHandler:showReallyHit'; Signature = 'private function showReallyHit(' },
    [pscustomobject]@{ Class = 'mmo.petfightnew.common.SkillResultMovieHandler'; Method = 'showShieldHit'; Target = 'mmo.petfightnew.common.SkillResultMovieHandler:showShieldHit'; Signature = 'private function showShieldHit(' },
    [pscustomobject]@{ Class = 'mmo.petfightnew.common.SkillResultMovieHandler'; Method = 'showReallyShieldHit'; Target = 'mmo.petfightnew.common.SkillResultMovieHandler:showReallyShieldHit'; Signature = 'private function showReallyShieldHit(' },
    [pscustomobject]@{ Class = 'mmo.petfightnew.common.SkillResultMovieHandler'; Method = 'playStrongMovie'; Target = 'mmo.petfightnew.common.SkillResultMovieHandler:playStrongMovie'; Signature = 'private function playStrongMovie(' },
    [pscustomobject]@{ Class = 'mmo.petfightnew.common.SkillResultMovieHandler'; Method = 'setNormalMovie'; Target = 'mmo.petfightnew.common.SkillResultMovieHandler:setNormalMovie'; Signature = 'private function setNormalMovie(' },
    [pscustomobject]@{ Class = 'mmo.petfightnew.common.SkillResultMovieHandler'; Method = 'playAllHitMovie'; Target = 'mmo.petfightnew.common.SkillResultMovieHandler:playAllHitMovie'; Signature = 'private function playAllHitMovie(' },
    [pscustomobject]@{ Class = 'mmo.petfightnew.common.fightcontroller.UseSkill'; Method = 'getMuiltHitDecHpDelayFrame'; Target = 'mmo.petfightnew.common.fightcontroller.UseSkill:getMuiltHitDecHpDelayFrame'; Signature = 'private function getMuiltHitDecHpDelayFrame(' },
    [pscustomobject]@{ Class = 'mmo.petfightnew.common.FightController'; Method = 'startHandle'; Target = 'mmo.petfightnew.common.FightController:startHandle'; Signature = 'public function startHandle(' }
)
$methodBodies = Get-MethodBodies $targets
$plan = [Collections.Generic.List[object]]::new()

function Add-Plan([object]$Target, [Collections.Generic.List[string]]$Fragment, [string]$FileName) {
    $plan.Add([pscustomobject]@{
        className = [string]$Target.Class
        methodName = [string]$Target.Method
        signature = [string]$Target.Signature
        methodBodyIndex = [int]$methodBodies[[string]$Target.Target]
        fragment = Save-Fragment $Fragment $FileName
    })
}

$useSkillPath = Join-Path $PcodeRoot 'scripts\mmo\petfightnew\common\fightcontroller\UseSkill.pcode'
$useSkillClass = [Collections.Generic.List[string]]::new([string[]](Get-Content -LiteralPath $useSkillPath))
$handleUseSkillTarget = $targets[0]
$handleUseSkill = Get-MethodFragment $useSkillPath $handleUseSkillTarget.Signature
$useSkillNamespace = Get-PrivateNamespaceId $useSkillClass 'handleDatas'
foreach ($member in @('handleMovie')) {
    if ((Get-PrivateNamespaceId $useSkillClass $member) -cne $useSkillNamespace) {
        throw "UseSkill private namespace changed for $member."
    }
}
Insert-After $handleUseSkill 'ofs0179:' ((New-BooleanGuard 'skipBattlePresentation' 'aola_original_aoyi') + @(
    ' getlocal0', ' getscopeobject 1', ' getslot 5', ' getscopeobject 1', ' getslot 1',
    " callpropvoid QName(PrivateNamespace(null,`"$useSkillNamespace`"),`"handleAoYiSkill`"), 2",
    ' returnvoid', 'aola_original_aoyi:'))
Insert-After $handleUseSkill 'ofs01a4:' ((New-BooleanGuard 'skipBattlePresentation' 'aola_original_special_skill') + @(
    ' getlocal0', ' getscopeobject 1', ' getslot 1',
    " callpropvoid QName(PrivateNamespace(null,`"$useSkillNamespace`"),`"handleDatas`"), 1",
    ' getlocal0', ' getscopeobject 1', ' getslot 1',
    " callpropvoid QName(PrivateNamespace(null,`"$useSkillNamespace`"),`"handleMovie`"), 1",
    ' returnvoid', 'aola_original_special_skill:'))
Add-Plan $handleUseSkillTarget $handleUseSkill 'UseSkill.handleUseSkill.pcode'

$annualTarget = $targets[1]
$annual = Get-MethodFragment $useSkillPath $annualTarget.Signature
$annualNamespace = Get-PrivateNamespaceId $useSkillClass 'handleDatas'
if ((Get-PrivateNamespaceId $useSkillClass 'handleMovie') -cne $annualNamespace -or $annualNamespace -cne $useSkillNamespace) {
    throw 'UseSkill annual-skill private namespace changed.'
}
Insert-After $annual 'setslot 2' ((New-BooleanGuard 'skipBattlePresentation' 'aola_original_annual_skill') + @(
    ' getlocal0', ' getlocal2',
    " callpropvoid QName(PrivateNamespace(null,`"$useSkillNamespace`"),`"handleDatas`"), 1",
    ' getlocal0', ' getlocal2',
    " callpropvoid QName(PrivateNamespace(null,`"$useSkillNamespace`"),`"handleMovie`"), 1",
    ' returnvoid', 'aola_original_annual_skill:'))
Add-Plan $annualTarget $annual 'UseSkill.handleAnnalFeeEight.pcode'

$handleMovieTarget = $targets[2]
$handleMovie = Get-MethodFragment $useSkillPath $handleMovieTarget.Signature
$movieNamespace = Get-PrivateNamespaceId $useSkillClass 'refreshInfos'
foreach ($member in @('fightPanel', 'skillBS', '_bus', '_skillParams', 'handleSkillEnd')) {
    if ((Get-PrivateNamespaceId $useSkillClass $member) -cne $movieNamespace) {
        throw "UseSkill.handleMovie private namespace changed for $member."
    }
}
Insert-After $handleMovie 'ofs01b4:' ((New-BooleanGuard 'skipBattlePresentation' 'aola_original_movie') + @(
    ' getlex QName(PackageNamespace("mmo.petfightnew.common.manager"),"FightFrameRateManager")',
    ' getproperty QName(PackageNamespace(""),"instance")',
    ' callpropvoid QName(PackageNamespace(""),"correctFrameRate"), 0',
    ' getlocal0', " callpropvoid QName(PrivateNamespace(null,`"$movieNamespace`"),`"refreshInfos`"), 0",
    ' getlocal0', " getproperty QName(PrivateNamespace(null,`"$movieNamespace`"),`"fightPanel`")",
    ' getlocal0', " getproperty QName(PrivateNamespace(null,`"$movieNamespace`"),`"skillBS`")",
    ' callpropvoid QName(PackageNamespace(""),"setBS"), 1',
    ' getlocal0', " getproperty QName(PrivateNamespace(null,`"$movieNamespace`"),`"fightPanel`")",
    ' getlocal0', " getproperty QName(PrivateNamespace(null,`"$movieNamespace`"),`"_bus`")",
    ' callpropvoid QName(PackageNamespace(""),"setBackGroundUp"), 1',
    ' getlocal0', " getproperty QName(PrivateNamespace(null,`"$movieNamespace`"),`"fightPanel`")",
    ' getlocal0', " getproperty QName(PrivateNamespace(null,`"$movieNamespace`"),`"_skillParams`")",
    ' callpropvoid QName(PackageNamespace(""),"setPetUp"), 1',
    ' getlocal0', " callpropvoid QName(PrivateNamespace(null,`"$movieNamespace`"),`"handleSkillEnd`"), 0",
    ' returnvoid', 'aola_original_movie:'))
Add-Plan $handleMovieTarget $handleMovie 'UseSkill.handleMovie.pcode'

$switchTarget = $targets[3]
$switchPath = Join-Path $PcodeRoot 'scripts\mmo\petfightnew\common\fightcontroller\SwitchPm.pcode'
$switchFragment = Get-MethodFragment $switchPath $switchTarget.Signature
$switchClass = [Collections.Generic.List[string]]::new([string[]](Get-Content -LiteralPath $switchPath))
$switchNamespace = Get-PrivateNamespaceId $switchClass 'onSwitchEnd'
Insert-AfterLast $switchFragment 'pushscope' ((New-BooleanGuard 'skipBattlePresentation' 'aola_original_switch') + @(
    ' getlocal0', ' getlocal1',
    " callpropvoid QName(PrivateNamespace(null,`"$switchNamespace`"),`"onSwitchEnd`"), 1",
    ' returnvoid', 'aola_original_switch:'))
Add-Plan $switchTarget $switchFragment 'SwitchPm.showSwitchMc.pcode'

$changePath = Join-Path $PcodeRoot 'scripts\mmo\petfightnew\common\fightcontroller\ChangePetView.pcode'
$changeClass = [Collections.Generic.List[string]]::new([string[]](Get-Content -LiteralPath $changePath))
$onPetChangeTarget = $targets[5]
$onPetChange = Get-MethodFragment $changePath $onPetChangeTarget.Signature
$changeNamespace = Get-PrivateNamespaceId $changeClass '_petContainer'
$indexAccessor = @($onPetChange | Where-Object { $_.Trim().StartsWith('setproperty MultinameL(') })
$indexAccessor = [string](Assert-One $indexAccessor 'ChangePetView petMCList index accessor')
$getIndexAccessor = $indexAccessor.Replace('setproperty MultinameL(', 'getproperty MultinameL(')
Insert-After $onPetChange 'callpropvoid QName(PackageNamespace(""),"addChildAt"), 2' ((New-BooleanGuard 'skipBattlePresentation' 'aola_original_transform_tween') + @(
    ' getlocal0', " getproperty QName(PrivateNamespace(null,`"$changeNamespace`"),`"_petContainer`")",
    ' pushbyte 1', ' setproperty QName(PackageNamespace(""),"scaleX")',
    ' getlocal0', " getproperty QName(PrivateNamespace(null,`"$changeNamespace`"),`"_petContainer`")",
    ' pushbyte 1', ' setproperty QName(PackageNamespace(""),"scaleY")',
    ' returnvoid', 'aola_original_transform_tween:'))

$onGotPetTarget = $targets[4]
$onGotPet = Get-MethodFragment $changePath $onGotPetTarget.Signature
foreach ($member in @('fightPanel', '_locaId', 'onPetChange', 'onEffectMoviePlayed')) {
    if ((Get-PrivateNamespaceId $changeClass $member) -cne $changeNamespace) {
        throw "ChangePetView private namespace changed for $member."
    }
}
Insert-After $onGotPet 'ofs0022:' ((New-BooleanGuard 'skipBattlePresentation' 'aola_original_change_view') + @(
    ' getlocal0', " getproperty QName(PrivateNamespace(null,`"$changeNamespace`"),`"fightPanel`")",
    ' getproperty QName(PackageNamespace(""),"petMCList")',
    ' getlocal0', " getproperty QName(PrivateNamespace(null,`"$changeNamespace`"),`"_locaId`")",
    $getIndexAccessor, ' setlocal2',
    ' getlocal0', ' getlocal2', ' getproperty QName(PackageNamespace(""),"parent")', ' getlocal2',
    ' callproperty QName(PackageNamespace(""),"getChildIndex"), 1', ' getlocal2',
    " callpropvoid QName(PrivateNamespace(null,`"$changeNamespace`"),`"onPetChange`"), 2",
    ' getlocal0', " callpropvoid QName(PrivateNamespace(null,`"$changeNamespace`"),`"onEffectMoviePlayed`"), 0",
    ' returnvoid', 'aola_original_change_view:'))
Add-Plan $onGotPetTarget $onGotPet 'ChangePetView.onGotPet.pcode'
Add-Plan $onPetChangeTarget $onPetChange 'ChangePetView.onPetChange.pcode'

$dyingTarget = $targets[6]
$dying = Get-MethodFragment (Join-Path $PcodeRoot 'scripts\mmo\petfightnew\common\fightcontroller\BattlePmDying.pcode') $dyingTarget.Signature
Insert-After $dying 'setslot 4' ((New-BooleanGuard 'skipBattlePresentation' 'aola_original_die_effect') + @(
    ' getscopeobject 1', ' getslot 4', ' iffalse aola_finish_die_effect',
    ' getscopeobject 1', ' getslot 4', ' callpropvoid QName(PackageNamespace(""),"disposeMouseResponder"), 0',
    ' getscopeobject 1', ' getslot 4', ' pushfalse', ' setproperty QName(PackageNamespace(""),"visible")',
    'aola_finish_die_effect:', ' getscopeobject 1', ' getslot 2', ' getglobalscope', ' call 0', ' pop',
    ' returnvoid', 'aola_original_die_effect:'))
Add-Plan $dyingTarget $dying 'BattlePmDying.showPetDieEffect.pcode'

$nextTarget = $targets[7]
$nextPath = Join-Path $PcodeRoot 'scripts\mmo\petfightnew\common\fightcontroller\BattleNextTurn.pcode'
$next = Get-MethodFragment $nextPath $nextTarget.Signature
$nextClass = [Collections.Generic.List[string]]::new([string[]](Get-Content -LiteralPath $nextPath))
$nextNamespace = Get-PrivateNamespaceId $nextClass 'handle'
Insert-AfterLast $next 'pushscope' ((New-BooleanGuard 'skipBattlePresentation' 'aola_original_next_turn_movie') + @(
    ' getlocal0', " callpropvoid QName(PrivateNamespace(null,`"$nextNamespace`"),`"handle`"), 0",
    ' returnvoid', 'aola_original_next_turn_movie:'))
Add-Plan $nextTarget $next 'BattleNextTurn.checkPlayMovie.pcode'

$resultPath = Join-Path $PcodeRoot 'scripts\mmo\petfightnew\common\SkillResultMovieHandler.pcode'
$resultClass = [Collections.Generic.List[string]]::new([string[]](Get-Content -LiteralPath $resultPath))
$multipleTarget = $targets[8]
$multiple = Get-MethodFragment $resultPath $multipleTarget.Signature
$resultNamespace = Get-PrivateNamespaceId $resultClass '_hpInc'
$multipleLabel = 'aola_original_result_' + $methodBodies[[string]$multipleTarget.Target]
Insert-AfterLast $multiple 'pushscope' @(
    ' getlocal0', " getproperty QName(PrivateNamespace(null,`"$resultNamespace`"),`"_hpInc`")", ' pushbyte 0',
    ' ifngt aola_check_multi_damage',
    ' getlex QName(PackageNamespace("mmo.petfightnew"),"DocPetFight")',
    ' getproperty QName(PackageNamespace(""),"hideHealingNumbers")', " iffalse $multipleLabel", ' returnvoid',
    'aola_check_multi_damage:',
    ' getlocal0', " getproperty QName(PrivateNamespace(null,`"$resultNamespace`"),`"_hpInc`")", ' pushbyte 0',
    " ifnlt $multipleLabel",
    ' getlex QName(PackageNamespace("mmo.petfightnew"),"DocPetFight")',
    ' getproperty QName(PackageNamespace(""),"hideDamageNumbers")', " iffalse $multipleLabel", ' returnvoid',
    ($multipleLabel + ':'))
Add-Plan $multipleTarget $multiple 'SkillResultMovieHandler.showMultipleHit.pcode'

$resultDefinitions = @(
    @($targets[9], 'hideHealingNumbers'),
    @($targets[10], 'hideDamageNumbers'),
    @($targets[11], 'hideDamageNumbers'),
    @($targets[12], 'hideDamageNumbers'),
    @($targets[13], 'hideDamageNumbers'),
    @($targets[14], 'hideDamageNumbers'),
    @($targets[15], 'hideDamageNumbers')
)
foreach ($definition in $resultDefinitions) {
    $target = $definition[0]
    $fragment = Get-MethodFragment $resultPath $target.Signature
    $label = 'aola_original_result_' + $methodBodies[[string]$target.Target]
    Insert-AfterLast $fragment 'pushscope' ((New-BooleanGuard ([string]$definition[1]) $label) + @(
        ' returnvoid', ($label + ':')))
    Add-Plan $target $fragment ("SkillResultMovieHandler.$($target.Method).pcode")
}

$multiHitDelayTarget = $targets[16]
$multiHitDelay = Get-MethodFragment $useSkillPath $multiHitDelayTarget.Signature
Insert-AfterLast $multiHitDelay 'pushscope' ((New-BooleanGuard 'skipBattlePresentation' 'aola_original_multi_hit_delay') + @(
    ' pushbyte 1', ' returnvalue', 'aola_original_multi_hit_delay:'))
Add-Plan $multiHitDelayTarget $multiHitDelay 'UseSkill.getMuiltHitDecHpDelayFrame.pcode'

$startHandleTarget = $targets[17]
$fightControllerPath = Join-Path $PcodeRoot 'scripts\mmo\petfightnew\common\FightController.pcode'
$startHandle = Get-MethodFragment $fightControllerPath $startHandleTarget.Signature
Insert-After $startHandle 'ofs001c:' ((New-BooleanGuard 'skipBattlePresentation' 'aola_original_start_handle') + @(
    ' getlocal0', ' callpropvoid QName(PackageNamespace(""),"handle"), 0',
    ' returnvoid', 'aola_original_start_handle:'))
Add-Plan $startHandleTarget $startHandle 'FightController.startHandle.pcode'

@($plan) | ConvertTo-Json -Depth 4
