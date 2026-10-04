# 在已有战斗候选上叠加原游戏自动战斗桥；不从官方资源重建视觉/生命周期补丁。
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$InputSwf,
    [Parameter(Mandatory)][string]$OutputSwf,
    [Parameter(Mandatory)][string]$EvidenceRoot,
    [string]$FFDecPath = 'D:\Programs\FFdec\ffdec-cli.exe',
    [switch]$ButtonOnly
)
$ErrorActionPreference = 'Stop'
$helper = Join-Path $PSScriptRoot 'petfight_bridge_abc.py'
$template = Join-Path $PSScriptRoot 'petfight\DocPetFight.bridge.template.as'
function Run-FFDec([string[]]$Arguments) {
    & $FFDecPath @Arguments
    if ($LASTEXITCODE -ne 0) { throw "FFDec failed: $LASTEXITCODE" }
}
New-Item -ItemType Directory -Force -Path $EvidenceRoot | Out-Null
$inputCopy = Join-Path $EvidenceRoot 'input.fws.swf'
Copy-Item -LiteralPath $InputSwf -Destination $inputCopy
$utf8 = [Text.UTF8Encoding]::new($false)
$current = $inputCopy
if (-not $ButtonOnly) {
    $docExport = Join-Path $EvidenceRoot 'document'
    Run-FFDec @('-onerror', 'abort', '-selectclass', 'mmo.petfightnew.DocPetFight', '-export', 'script', $docExport, $current)
    $docPath = Join-Path $docExport 'scripts\mmo\petfightnew\DocPetFight.as'
    $doc = [IO.File]::ReadAllText($docPath)
    $newTemplate = [IO.File]::ReadAllText($template)
    $first = $newTemplate.IndexOf('      // 与原按钮共享设置行为')
    $last = $newTemplate.IndexOf('      private static function onAolaBattleGetState()')
    $methods = $newTemplate.Substring($first, $last - $first)
    $doc = $doc.Replace('import flash.utils.getTimer;', "import flash.utils.getTimer;" + [Environment]::NewLine + '   import flash.utils.getDefinitionByName;')
    $doc = $doc.Replace('ExternalInterface.addCallback("aolaBattleGetState",onAolaBattleGetState);',
        'ExternalInterface.addCallback("aolaBattleGetState",onAolaBattleGetState);' + [Environment]::NewLine +
        '               ExternalInterface.addCallback("aolaBattleSetAuto",onAolaBattleSetAuto);')
    $doc = $doc.Replace('      private static function onAolaBattleGetState()', $methods + '      private static function onAolaBattleGetState()')
    [IO.File]::WriteAllText($docPath, $doc, $utf8)
    $current = Join-Path $EvidenceRoot 'document-patched.fws.swf'
    Run-FFDec @('-onerror', 'abort', '-replace', $inputCopy, $current, 'mmo.petfightnew.DocPetFight', $docPath)
}
$pcRoot = Join-Path $EvidenceRoot 'button-pcode'
$className = 'mmo.petfightnew.common.panel.skill.NewSkillPanel'
Run-FFDec @('-onerror', 'abort', '-format', 'script:pcode', '-selectclass', $className, '-export', 'script', $pcRoot, $current)
$lines = @(Get-Content -LiteralPath (Join-Path $pcRoot 'scripts\mmo\petfightnew\common\panel\skill\NewSkillPanel.pcode'))
$signature = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i].Contains('private function changeBtnState(')) { $signature = $i; break }
}
if ($signature -lt 0) { throw 'changeBtnState p-code not found' }
$begin = -1; $end = -1
for ($i = $signature; $i -lt $lines.Count; $i++) {
    if ($begin -lt 0 -and $lines[$i].Trim() -eq 'method') { $begin = $i }
    if ($begin -ge 0 -and $lines[$i].Trim() -eq 'end ; method') { $end = $i; break }
}
$fragment = ($lines[$begin..$end] | ForEach-Object { $_.Trim() }) -join [Environment]::NewLine
$code = @'
code
getlocal0
pushscope
getlex QName(PackageNamespace("mmo.petfightnew"),"DocPetFight")
getlex QName(PackageNamespace("mmo.petfightnew.common"),"FightController")
getproperty QName(PackageNamespace(""),"isAutoUseSkill")
not
callproperty QName(PackageNamespace(""),"setNativeAutoBattle"), 1
pop
returnvoid
end ; code
'@
$fragment = [regex]::Replace($fragment, '(?s)\bcode\r?\n.*?end ; code', $code)
$patch = Join-Path $EvidenceRoot 'changeBtnState.pcode'
[IO.File]::WriteAllText($patch, $fragment + [Environment]::NewLine, $utf8)
$methodJson = & python $helper methods --input $current --target ($className + ':changeBtnState')
if ($LASTEXITCODE -ne 0) { throw 'method lookup failed' }
$method = @(($methodJson -join [Environment]::NewLine) | ConvertFrom-Json)[0]
Run-FFDec @('-onerror', 'abort', '-replace', $current, $OutputSwf, $className, $patch, [string]$method.methodBodyIndex)
Run-FFDec @('-onerror', 'abort', '-selectclass', ('mmo.petfightnew.DocPetFight,' + $className),
    '-export', 'script', (Join-Path $EvidenceRoot 'reread'), $OutputSwf)
& python $helper inspect --input $OutputSwf
if ($LASTEXITCODE -ne 0) { throw 'candidate inspection failed' }
