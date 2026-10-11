param([string]$FFDecPath = 'D:\Programs\FFdec\ffdec-cli.exe')

$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
$source = Join-Path $repoRoot 'analysis\AolaLoader\Resources\Patches\petfightnew-battle-state-current.fws.swf'
$pcode = Join-Path $repoRoot 'analysis\reverse-engineering\battle-bridge-20260918-2026091780747880-pwsh\decompiled\pcode-candidate\scripts\mmo\petfightnew\common\MCPetContainer.pcode'
$backgroundPcode = Join-Path $repoRoot 'analysis\reverse-engineering\battle-bridge-20260918-2026091780747880-pwsh\decompiled\pcode-candidate\scripts\mmo\petfightnew\common\handler\BackGroundViewHandler.pcode'
$abcTool = Join-Path $repoRoot 'analysis\tools\petfight_bridge_abc.py'
$outputRoot = Join-Path $repoRoot 'analysis\AolaLoader\Resources\Patches\Build\battle-cinematics-20260924'
$fragmentRoot = Join-Path $outputRoot 'exports\patches'
$variantRoot = Join-Path $outputRoot 'variants'
$first = Join-Path $variantRoot 'petfightnew-cinematics-stage-1-v3.fws.swf'
$candidate = Join-Path $variantRoot 'petfightnew-cinematics-stage-2-v3.fws.swf'
$finalCandidate = Join-Path $variantRoot 'petfightnew-cinematics-2026091780747880-v3.fws.swf'
$expectedSourceHash = 'd95994aba59afa78357fd5664f3b95efa6d4227fc4a179df11ccd45867cf9f36'

function Get-Method([string]$signature, [string]$sourcePath = $pcode) {
	$lines = @(Get-Content -LiteralPath $sourcePath)
	$matches = @($lines | Where-Object { $_.Contains($signature) })
	if ($matches.Count -ne 1) { throw "Expected one $signature method, found $($matches.Count)." }
	$start = [array]::IndexOf($lines, $matches[0])
	while ($start -lt $lines.Count -and $lines[$start].Trim() -ne 'method') { $start++ }
	$end = $start + 1
	while ($end -lt $lines.Count -and $lines[$end].Trim() -ne 'end ; method') { $end++ }
	if ($start -ge $lines.Count -or $end -ge $lines.Count) { throw "Method body missing for $signature." }
	return ,([Collections.Generic.List[string]]::new([string[]]$lines[$start..$end]))
}

function Insert-After([Collections.Generic.List[string]]$lines, [string]$needle, [string[]]$addition) {
	$matches = @()
	for ($i = 0; $i -lt $lines.Count; $i++) {
		if ($lines[$i].Trim() -ceq $needle) { $matches += $i }
	}
	if ($matches.Count -ne 1) { throw "Expected one '$needle', found $($matches.Count)." }
	$lines.InsertRange($matches[0] + 1, $addition)
}

function Save-Fragment([Collections.Generic.List[string]]$lines, [string]$name) {
	$path = Join-Path $fragmentRoot $name
	[IO.File]::WriteAllLines($path, [string[]]$lines, [Text.UTF8Encoding]::new($false))
	return $path
}

if (-not (Test-Path -LiteralPath $FFDecPath -PathType Leaf)) { throw "FFDec missing: $FFDecPath" }
if (-not (Test-Path -LiteralPath $pcode -PathType Leaf)) { throw "P-code missing: $pcode" }
if (-not (Test-Path -LiteralPath $backgroundPcode -PathType Leaf)) { throw "P-code missing: $backgroundPcode" }
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $source).Hash.ToLowerInvariant() -cne $expectedSourceHash) {
	throw 'Current battle candidate changed; inspect it before rebuilding.'
}
$methodInfo = @(& python $abcTool methods --input $source `
	--target 'mmo.petfightnew.common.MCPetContainer:onResPrepared' `
	--target 'mmo.petfightnew.common.MCPetContainer:onStartCriEff' `
	--target 'mmo.petfightnew.common.handler.BackGroundViewHandler:setBS' | ConvertFrom-Json)
if ($LASTEXITCODE -ne 0 -or $methodInfo.Count -ne 3) { throw 'Unable to resolve exact ABC method bodies.' }
$appearBody = @($methodInfo | Where-Object methodName -eq 'onResPrepared')
$extraBody = @($methodInfo | Where-Object methodName -eq 'onStartCriEff')
$backgroundBody = @($methodInfo | Where-Object methodName -eq 'setBS')
if ($appearBody.Count -ne 1 -or $extraBody.Count -ne 1 -or $backgroundBody.Count -ne 1) { throw 'ABC method body mapping is ambiguous.' }
foreach ($path in @($first, $candidate, $finalCandidate)) {
	if (Test-Path -LiteralPath $path) { throw "Refusing to overwrite $path" }
}
New-Item -ItemType Directory -Force -Path $fragmentRoot, $variantRoot | Out-Null

$appear = Get-Method 'private function onResPrepared()'
Insert-After $appear 'callpropvoid QName(PrivateNamespace(null,"170"),"setMiracleLight"), 0' @(
	' getlex QName(PackageNamespace("mmo.petfightnew"),"DocPetFight")',
	' getproperty QName(PackageNamespace(""),"skipBattlePresentation")',
	' iffalse aola_original_appear',
	' getlocal0',
	' getlocal0',
	' getproperty QName(PackageNamespace(""),"locaId")',
	' callpropvoid QName(PrivateNamespace(null,"170"),"dispatchGotPet"), 1',
	' returnvoid',
	'aola_original_appear:')
$appearPath = Save-Fragment $appear 'MCPetContainer.onResPrepared.pcode'

$extra = Get-Method 'private function onStartCriEff()'
Insert-After $extra 'pushscope' @(
	' getlex QName(PackageNamespace("mmo.petfightnew"),"DocPetFight")',
	' getproperty QName(PackageNamespace(""),"skipBattlePresentation")',
	' iffalse aola_original_extra',
	' returnvoid',
	'aola_original_extra:')
$extraPath = Save-Fragment $extra 'MCPetContainer.onStartCriEff.pcode'

& $FFDecPath -onerror abort -replace $source $first 'mmo.petfightnew.common.MCPetContainer' $appearPath ([string]$appearBody[0].methodBodyIndex)
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $first)) { throw 'Appear guard patch failed.' }
& $FFDecPath -onerror abort -replace $first $candidate 'mmo.petfightnew.common.MCPetContainer' $extraPath ([string]$extraBody[0].methodBodyIndex)
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $candidate)) { throw 'Extra-movie guard patch failed.' }

$background = Get-Method 'public function setBS(' $backgroundPcode
$maxStack = @($background | Where-Object { $_.Trim() -ceq 'maxstack 2' })
if ($maxStack.Count -ne 1) { throw 'BackGroundViewHandler.setBS maxstack changed.' }
$background[[array]::IndexOf([string[]]$background.ToArray(), $maxStack[0])] = ' maxstack 3'
Insert-After $background 'callpropvoid QName(PrivateNamespace(null,"62"),"setSkillBackGroundIcon"), 1' @(
	' getlex QName(PackageNamespace("mmo.petfightnew"),"DocPetFight")',
	' getproperty QName(PackageNamespace(""),"skipBattlePresentation")',
	' iffalse aola_original_skill_background',
	' getlex QName(PackageNamespace("mmo.common"),"DisplayUtil")',
	' getlocal0',
	' getproperty QName(PrivateNamespace(null,"62"),"_skillBack")',
	' callpropvoid QName(PackageNamespace(""),"stopAndRemove"), 1',
	' getlocal0',
	' pushnull',
	' setproperty QName(PrivateNamespace(null,"62"),"_skillBack")',
	' getlocal0',
	' pushstring ""',
	' setproperty QName(PrivateNamespace(null,"62"),"_curBS")',
	' getlocal0',
	' getproperty QName(PrivateNamespace(null,"62"),"_layerPlatform")',
	' pushtrue',
	' setproperty QName(PackageNamespace(""),"visible")',
	' getlocal0',
	' getproperty QName(PrivateNamespace(null,"62"),"_sceneBack")',
	' iffalse aola_skill_background_done',
	' getlocal0',
	' getproperty QName(PrivateNamespace(null,"62"),"_layerBackGround")',
	' getlocal0',
	' getproperty QName(PrivateNamespace(null,"62"),"_sceneBack")',
	' pushbyte 0',
	' callpropvoid QName(PackageNamespace(""),"addChildAt"), 2',
	'aola_skill_background_done:',
	' jump ofs002b',
	'aola_original_skill_background:')
$backgroundPath = Save-Fragment $background 'BackGroundViewHandler.setBS.pcode'
& $FFDecPath -onerror abort -replace $candidate $finalCandidate 'mmo.petfightnew.common.handler.BackGroundViewHandler' $backgroundPath ([string]$backgroundBody[0].methodBodyIndex)
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $finalCandidate)) { throw 'Skill-background guard patch failed.' }
Write-Output "candidate=$finalCandidate"
Write-Output "sha256=$((Get-FileHash -Algorithm SHA256 -LiteralPath $finalCandidate).Hash.ToLowerInvariant())"
