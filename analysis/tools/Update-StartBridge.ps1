# 用 FFDec 从官方 start SWF 重建 start 桥，替换 mmo.checkversion.Load 为仓库内 AS3 源。
# 只生成候选并静态复读；不启动 Flash，不修改官方原始文件。
[CmdletBinding()]
param(
    [string]$SourceSwf,
    [string]$FFDecPath = 'D:\Programs\FFdec\ffdec-cli.exe',
    [string]$EvidenceRoot,
    [string]$OutputSwf
)

$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$officialRoot = Join-Path $repo 'analysis\reverse-engineering\start-bridge-20260829'
$officialZws = Join-Path $officialRoot 'source\start~2107300001.swf'
$officialFws = Join-Path $officialRoot 'variants\start-2107300001-original.fws.swf'
$loadSource = Join-Path $repo 'analysis\AolaLoader\Resources\Patches\Sources\start-2107300001\mmo\checkversion\Load.as'
if (-not $SourceSwf) { $SourceSwf = $officialZws }
if (-not $EvidenceRoot) { $EvidenceRoot = Join-Path $repo 'analysis\reverse-engineering\start-bridge-memory-20261021' }
if (-not $OutputSwf) { $OutputSwf = Join-Path $repo 'analysis\AolaLoader\Resources\Patches\start-bridge-2107300001.fws.swf' }
$SourceSwf = [IO.Path]::GetFullPath($SourceSwf)
$EvidenceRoot = [IO.Path]::GetFullPath($EvidenceRoot)
$OutputSwf = [IO.Path]::GetFullPath($OutputSwf)

function Get-SwfSignature([string]$Path) {
    $bytes = [IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -lt 8) { throw "SWF is too small: $Path" }
    return [Text.Encoding]::ASCII.GetString($bytes, 0, 3)
}

function Assert-Fws([string]$Path) {
    $bytes = [IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -lt 8) { throw "SWF is too small: $Path" }
    $signature = [Text.Encoding]::ASCII.GetString($bytes, 0, 3)
    if ($signature -cne 'FWS') { throw "Expected an uncompressed FWS file: $Path" }
    $declaredLength = [BitConverter]::ToUInt32($bytes, 4)
    if ([int64]$declaredLength -ne [int64]$bytes.Length) {
        throw "FWS declared length $declaredLength does not match file length $($bytes.Length): $Path"
    }
}

function Invoke-FFDec([string[]]$Arguments, [string]$Description) {
    & $FFDecPath @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Description failed with exit code $LASTEXITCODE." }
}

foreach ($path in @($FFDecPath, $loadSource, $SourceSwf)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Required file not found: $path" }
}
if ($OutputSwf -eq $SourceSwf -or $OutputSwf -eq $officialZws -or $OutputSwf -eq $officialFws) {
    throw "Refusing to overwrite an official source SWF: $OutputSwf"
}

# FFDec replaces into an uncompressed working copy; keep the official ZWS untouched.
$requestedSource = $SourceSwf
$buildSource = $SourceSwf
if ((Get-SwfSignature $buildSource) -eq 'ZWS') {
    if (-not (Test-Path -LiteralPath $officialFws -PathType Leaf)) {
        throw "The official ZWS input has no FWS working copy: $officialFws"
    }
    $buildSource = $officialFws
}
if ((Get-SwfSignature $buildSource) -ne 'FWS') {
    throw "The build input must be an uncompressed FWS file: $buildSource"
}
Assert-Fws $buildSource

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
$runRoot = Join-Path $EvidenceRoot ('run-' + $stamp)
if (Test-Path -LiteralPath $runRoot) { throw "Evidence run already exists: $runRoot" }
$inputRoot = Join-Path $runRoot 'input'
$variantRoot = Join-Path $runRoot 'variants'
$decompileRoot = Join-Path $runRoot 'decompiled'
$previousRoot = Join-Path $runRoot 'previous'
$outputRoot = Join-Path $runRoot 'output'
foreach ($path in @($inputRoot, $variantRoot, $decompileRoot, $previousRoot, $outputRoot)) {
    New-Item -ItemType Directory -Force -Path $path | Out-Null
}

$inputCopy = Join-Path $inputRoot 'start-input.fws.swf'
$loadCopy = Join-Path $inputRoot 'Load.as'
Copy-Item -LiteralPath $buildSource -Destination $inputCopy
Copy-Item -LiteralPath $loadSource -Destination $loadCopy
$candidate = Join-Path $variantRoot 'start-bridge.fws.swf'

$replaceArguments = @(
    '-onerror', 'abort', '-replace', $inputCopy, $candidate,
    'mmo.checkversion.Load', $loadCopy
)
Invoke-FFDec -Arguments $replaceArguments -Description 'mmo.checkversion.Load replacement'
Assert-Fws $candidate

$exportArguments = @('-onerror', 'abort', '-export', 'script,symbolClass', $decompileRoot, $candidate)
Invoke-FFDec -Arguments $exportArguments -Description 'candidate script and SymbolClass export'

$exportedLoad = Join-Path $decompileRoot 'scripts\mmo\checkversion\Load.as'
if (-not (Test-Path -LiteralPath $exportedLoad -PathType Leaf)) {
    throw "FFDec did not export mmo.checkversion.Load: $exportedLoad"
}
$exportedSource = [IO.File]::ReadAllText($exportedLoad)
if ($exportedSource.IndexOf('package mmo.checkversion', [StringComparison]::Ordinal) -lt 0) {
    throw 'The exported script is not mmo.checkversion.Load.'
}

$requiredCallbacks = @(
    'aolaSendCommand',
    'aolaOpenPanel',
    'aolaSetPlayback',
    'aolaThemeApply',
    'aolaTrimMemory',
    'aolaGetRuntimeStats'
)
foreach ($callback in $requiredCallbacks) {
    $token = 'ExternalInterface.addCallback("' + $callback + '"'
    if ($exportedSource.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
        throw "The rebuilt Load is missing callback $callback."
    }
}
$requiredTokens = @(
    'ExternalInterface.call("aolaCommandCompleted"',
    'private function onAolaTrimMemory(',
    'private function onAolaGetRuntimeStats(',
    'pauseForGCIfCollectionImminent(0.25)',
    'return "TrimApplied|"',
    'return "RuntimeStats|"'
)
foreach ($token in $requiredTokens) {
    if ($exportedSource.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
        throw "The rebuilt Load is missing token $token."
    }
}
if ($exportedSource.IndexOf('System.gc(', [StringComparison]::Ordinal) -ge 0) {
    throw 'The rebuilt Load must not call System.gc().'
}

$symbolClassPath = Join-Path $decompileRoot 'symbolClass\symbols.csv'
if (-not (Test-Path -LiteralPath $symbolClassPath -PathType Leaf)) {
    throw "FFDec did not export SymbolClass: $symbolClassPath"
}
$symbolClassSource = [IO.File]::ReadAllText($symbolClassPath)
if ($symbolClassSource.IndexOf('mmo.checkversion.Load', [StringComparison]::Ordinal) -lt 0) {
    throw 'The rebuilt SWF no longer maps mmo.checkversion.Load.'
}

$outputDirectory = Split-Path -Parent $OutputSwf
New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
$previousCopy = Join-Path $previousRoot 'start-bridge-2107300001.fws.swf'
if (Test-Path -LiteralPath $OutputSwf -PathType Leaf) {
    Copy-Item -LiteralPath $OutputSwf -Destination $previousCopy
}
Copy-Item -LiteralPath $candidate -Destination $OutputSwf -Force
Assert-Fws $OutputSwf
$outputCopy = Join-Path $outputRoot 'start-bridge-2107300001.fws.swf'
Copy-Item -LiteralPath $OutputSwf -Destination $outputCopy

$report = [ordered]@{
    schemaVersion = 1
    createdAt = (Get-Date).ToString('o')
    requestedSource = $requestedSource
    buildSource = $buildSource
    loadSource = $loadSource
    output = $OutputSwf
    ffdec = $FFDecPath
    ffdecReplace = @($FFDecPath) + $replaceArguments
    ffdecExport = @($FFDecPath) + $exportArguments
    checks = [ordered]@{
        fwsHeaderAndLength = $true
        callbacks = $requiredCallbacks
        methods = $requiredTokens
        symbolClass = 'mmo.checkversion.Load'
        systemGcAbsent = $true
    }
}
$report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $runRoot 'report.json') -Encoding utf8

[pscustomobject]@{
    status = 'Prepared'
    output = $OutputSwf
    evidence = $runRoot
} | ConvertTo-Json
