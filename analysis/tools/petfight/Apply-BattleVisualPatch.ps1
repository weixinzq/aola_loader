[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$CandidatePath,
    [Parameter(Mandatory = $true)][string]$PcodeRoot,
    [Parameter(Mandatory = $true)][string]$OutputPath,
    [string]$FFDecPath = 'D:\Programs\FFdec\ffdec-cli.exe'
)

$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
$abcTool = Join-Path $repoRoot 'analysis\tools\petfight_bridge_abc.py'
$candidate = [IO.Path]::GetFullPath($CandidatePath)
$output = [IO.Path]::GetFullPath($OutputPath)
$pcodeDirectory = [IO.Path]::GetFullPath($PcodeRoot)
if (-not (Test-Path -LiteralPath $candidate -PathType Leaf) -or
    -not (Test-Path -LiteralPath $pcodeDirectory -PathType Container) -or
    -not (Test-Path -LiteralPath $FFDecPath -PathType Leaf) -or
    (Test-Path -LiteralPath $output)) {
    throw 'Candidate, p-code directory, FFDec, or output path is unavailable.'
}

$targets = @(
    'mmo.petfightnew.common.MCPetContainer:onResPrepared',
    'mmo.petfightnew.common.MCPetContainer:onStartCriEff',
    'mmo.petfightnew.DocPetFight:$cinit',
    'mmo.petfightnew.common.handler.BackGroundViewHandler:setBS',
    'mmo.petfightnew.common.handler.BackGroundViewHandler:setSceneBackGround',
    'mmo.petfightnew.common.handler.BackGroundViewHandler:changeSkillBackGround'
)
$methodArguments = @('methods', '--input', $candidate)
foreach ($target in $targets) { $methodArguments += @('--target', $target) }
$methods = @(& python $abcTool @methodArguments | ConvertFrom-Json)
if ($LASTEXITCODE -ne 0 -or $methods.Count -ne $targets.Count) {
    throw 'The expected battle methods could not be resolved in this candidate.'
}

function Get-Method([string]$relativePath, [string]$signature) {
    $lines = @(Get-Content -LiteralPath (Join-Path $pcodeDirectory $relativePath))
    $matches = @($lines | Where-Object { $_.Contains($signature) })
    if ($matches.Count -ne 1) { throw "Expected exactly one $signature method." }
    $start = [array]::IndexOf($lines, $matches[0]) + 1
    while ($start -lt $lines.Count -and $lines[$start].Trim() -ne 'method') { $start++ }
    if ($start -ge $lines.Count) { throw "Missing method body for $signature." }
    $depth = 0
    for ($end = $start; $end -lt $lines.Count; $end++) {
        if ($lines[$end].Trim() -ceq 'method') { $depth++ }
        if ($lines[$end].Trim() -ceq 'end ; method') {
            $depth--
            if ($depth -eq 0) { break }
        }
    }
    if ($end -ge $lines.Count) { throw "Unterminated method body for $signature." }
    return ,([Collections.Generic.List[string]]::new([string[]]$lines[$start..$end]))
}

function Find-Unique([Collections.Generic.List[string]]$lines, [string]$needle) {
    $matches = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -ceq $needle) { $matches += $i }
    }
    if ($matches.Count -ne 1) { throw "Expected one '$needle', found $($matches.Count)." }
    return $matches[0]
}

function Find-First([Collections.Generic.List[string]]$lines, [string]$needle) {
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -ceq $needle) { return $i }
    }
    throw "Missing '$needle'."
}

function Insert-After([Collections.Generic.List[string]]$lines, [string]$needle, [string[]]$addition) {
    $lines.InsertRange((Find-Unique $lines $needle) + 1, $addition)
}

$petPcode = 'mmo\petfightnew\common\MCPetContainer.pcode'
$backgroundPcode = 'mmo\petfightnew\common\handler\BackGroundViewHandler.pcode'
$docPcode = 'mmo\petfightnew\DocPetFight.pcode'
$patches = @()

$appear = Get-Method $petPcode 'private function onResPrepared()'
Insert-After $appear 'callpropvoid QName(PrivateNamespace(null,"170"),"setMiracleLight"), 0' @(
    ' getlex QName(PackageNamespace("mmo.petfightnew"),"DocPetFight")',
    ' getproperty QName(PackageNamespace(""),"skipBattlePresentation")',
    ' iffalse aola_original_appear',
    ' getlocal0',
    ' getlocal0',
    ' getproperty QName(PackageNamespace(""),"locaId")',
    ' callpropvoid QName(PrivateNamespace(null,"170"),"dispatchGotPet"), 1',
    ' returnvoid',
    'aola_original_appear:'
)
$patches += [pscustomobject]@{ Name='onResPrepared'; Class='mmo.petfightnew.common.MCPetContainer'; Body=$appear }

$extra = Get-Method $petPcode 'private function onStartCriEff()'
$extra.InsertRange((Find-First $extra 'pushscope') + 1, [string[]]@(
    ' getlex QName(PackageNamespace("mmo.petfightnew"),"DocPetFight")',
    ' getproperty QName(PackageNamespace(""),"skipBattlePresentation")',
    ' iffalse aola_original_extra',
    ' returnvoid',
    'aola_original_extra:'
))
$patches += [pscustomobject]@{ Name='onStartCriEff'; Class='mmo.petfightnew.common.MCPetContainer'; Body=$extra }

$doc = Get-Method $docPcode 'public static var skipBattlePresentation:Boolean = false;'
$defaultIndex = Find-Unique $doc 'findproperty QName(PackageNamespace(""),"skipBattlePresentation")'
if ($doc[$defaultIndex + 1].Trim() -cne 'pushfalse') { throw 'Battle presentation default changed.' }
$doc[$defaultIndex + 1] = ' pushtrue'
$patches += [pscustomobject]@{ Name='$cinit'; Class='mmo.petfightnew.DocPetFight'; Body=$doc }

$setBS = Get-Method $backgroundPcode 'public function setBS('
Insert-After $setBS 'callpropvoid QName(PrivateNamespace(null,"63"),"setSkillBackGroundIcon"), 1' @(
    ' getlocal0',
    ' getproperty QName(PrivateNamespace(null,"63"),"_layerPlatform")',
    ' pushtrue',
    ' setproperty QName(PackageNamespace(""),"visible")'
)
$patches += [pscustomobject]@{ Name='setBS'; Class='mmo.petfightnew.common.handler.BackGroundViewHandler'; Body=$setBS }

$scene = Get-Method $backgroundPcode 'public function setSceneBackGround()'
$scene[(Find-Unique $scene 'localcount 2')] = ' localcount 3'
Insert-After $scene 'ofs0044:' @(
    ' findpropstrict QName(PackageNamespace("flash.display"),"Loader")',
    ' constructprop QName(PackageNamespace("flash.display"),"Loader"), 0',
    ' coerce QName(PackageNamespace("flash.display"),"Loader")',
    ' setlocal2',
    ' getlocal0',
    ' getproperty QName(PrivateNamespace(null,"63"),"_layerBackGround")',
    ' getlocal2',
    ' callpropvoid QName(PackageNamespace(""),"addChild"), 1',
    ' getlocal2',
    ' findpropstrict QName(PackageNamespace("flash.net"),"URLRequest")',
    ' pushstring "https://aola.100bt.com/play/petfightbackground/aola-custom.jpg"',
    ' constructprop QName(PackageNamespace("flash.net"),"URLRequest"), 1',
    ' callpropvoid QName(PackageNamespace(""),"load"), 1'
)
$patches += [pscustomobject]@{ Name='setSceneBackGround'; Class='mmo.petfightnew.common.handler.BackGroundViewHandler'; Body=$scene }

$skill = Get-Method $backgroundPcode 'private function changeSkillBackGround('
$skill.Insert((Find-First $skill 'pushscope') + 1, ' returnvoid')
$patches += [pscustomobject]@{ Name='changeSkillBackGround'; Class='mmo.petfightnew.common.handler.BackGroundViewHandler'; Body=$skill }

$outputDirectory = Split-Path -Parent $output
New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
$previous = $candidate
for ($i = 0; $i -lt $patches.Count; $i++) {
    $patch = $patches[$i]
    $match = @($methods | Where-Object { $_.methodName -ceq $patch.Name })
    if ($match.Count -ne 1) { throw "Ambiguous method index for $($patch.Name)." }
    $fragment = Join-Path $outputDirectory ("battle-visual-" + $patch.Name.TrimStart('$') + '.pcode')
    [IO.File]::WriteAllLines($fragment, [string[]]$patch.Body, [Text.UTF8Encoding]::new($false))
    $next = if ($i -eq $patches.Count - 1) { $output } else {
        Join-Path $outputDirectory ("battle-visual-stage-" + ($i + 1) + '.fws.swf')
    }
    if (Test-Path -LiteralPath $next) { throw "Refusing to overwrite $next" }
    & $FFDecPath -onerror abort -replace $previous $next $patch.Class $fragment ([string]$match[0].methodBodyIndex) | Out-Null
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $next)) {
        throw "SWF patch failed at $($patch.Name)."
    }
    $previous = $next
}
Write-Output "Battle visual candidate: $output"
