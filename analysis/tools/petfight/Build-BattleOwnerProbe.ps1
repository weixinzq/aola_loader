# 用 FFDec 从 retention 诊断候选重建 owner probe 候选：只替换 mmo.petfightnew.DocPetFight。
# 只写 analysis/reverse-engineering/battle-owner-probe-20261021/ 证据目录；不覆盖生产清单、生产候选或 retention 候选。
[CmdletBinding()]
param(
    [string]$InputSwf,
    [string]$SourceAs,
    [string]$FFDecPath = 'D:\Programs\FFdec\ffdec-cli.exe',
    [string]$EvidenceRoot,
    [string]$OutputSwf
)

$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
$retentionRoot = Join-Path $repo 'analysis\reverse-engineering\battle-retention-trace-20261017'
$productionRoot = Join-Path $repo 'analysis\AolaLoader\Resources\Patches'
if (-not $InputSwf) { $InputSwf = Join-Path $retentionRoot 'variants\petfightnew-retention-trace.fws.swf' }
if (-not $SourceAs) { $SourceAs = Join-Path $repo 'analysis\reverse-engineering\battle-owner-probe-20261021\source\DocPetFight.as' }
if (-not $EvidenceRoot) { $EvidenceRoot = Join-Path $repo 'analysis\reverse-engineering\battle-owner-probe-20261021' }
if (-not $OutputSwf) { $OutputSwf = Join-Path $EvidenceRoot 'variants\petfightnew-owner-probe.fws.swf' }
$InputSwf = [IO.Path]::GetFullPath($InputSwf)
$SourceAs = [IO.Path]::GetFullPath($SourceAs)
$EvidenceRoot = [IO.Path]::GetFullPath($EvidenceRoot)
$OutputSwf = [IO.Path]::GetFullPath($OutputSwf)
$className = 'mmo.petfightnew.DocPetFight'

function Assert-Fws([string]$Path) {
    $bytes = [IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -lt 8) { throw "SWF is too small: $Path" }
    if ((Get-SwfSignature $Path) -cne 'FWS') { throw "Expected an uncompressed FWS file: $Path" }
    $declaredLength = [BitConverter]::ToUInt32($bytes, 4)
    if ([int64]$declaredLength -ne [int64]$bytes.Length) {
        throw "FWS declared length $declaredLength does not match file length $($bytes.Length): $Path"
    }
}

function Get-SwfSignature([string]$Path) {
    $bytes = [IO.File]::ReadAllBytes($Path)
    return [Text.Encoding]::ASCII.GetString($bytes, 0, 3)
}

function Invoke-FFDec([string[]]$Arguments, [string]$Description, [string]$LogPath) {
    $output = & $FFDecPath @Arguments 2>&1 | Out-String
    if ($LogPath) { Set-Content -LiteralPath $LogPath -Value $output -Encoding utf8 }
    if ($LASTEXITCODE -ne 0) { throw "$Description failed with exit code $LASTEXITCODE.`n$output" }
}

# 只统计 ASCII 出现次数；用于证明注入没有新增禁用调用。Latin-1 让字节与字符一一对应。
function ConvertTo-Latin1Text([byte[]]$Content) {
    return [Text.Encoding]::GetEncoding(28591).GetString($Content)
}

function Count-Ascii([string]$Text, [string]$Value) {
    $count = 0
    $index = 0
    while (($index = $Text.IndexOf($Value, $index, [StringComparison]::Ordinal)) -ge 0) {
        $count++
        $index += $Value.Length
    }
    return $count
}

$forbiddenTokens = @('System.gc(', 'unloadAndStop', 'unloadRes')
$requiredCallbackTokens = @(
    'ExternalInterface.addCallback("aolaBattleProbeRelease",onAolaBattleProbeRelease)',
    'private static function onAolaBattleProbeRelease(',
    'ExternalInterface.addCallback("aolaBattleGetDiagnostics",onAolaBattleGetDiagnostics)',
    'ExternalInterface.addCallback("aolaBattleApplyOptions",onAolaBattleApplyOptions)',
    'private static const BRIDGE_VERSION:int = 5',
    'private static const DIAGNOSTICS_VERSION:int = 4',
    'private static function applyProbeTipsRemoval(',
    'private static function applyProbeHeadFrameCleanup(',
    'private static function resolveProbeDefinition(',
    'private static function walkOwnerProbeTree(',
    'new Dictionary(true)',
    '"owner-probe-start"',
    '"owner-probe-child"'
)

foreach ($path in @($FFDecPath, $SourceAs, $InputSwf)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Required file not found: $path" }
}
foreach ($protected in @($InputSwf, $SourceAs)) {
    if ($OutputSwf -eq $protected) { throw "Refusing to overwrite an input file: $OutputSwf" }
}
if ($OutputSwf.StartsWith([IO.Path]::GetFullPath($productionRoot) + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to write the probe candidate into the production Resources/Patches directory: $OutputSwf"
}
if ($OutputSwf -eq [IO.Path]::GetFullPath((Join-Path $retentionRoot 'variants\petfightnew-retention-trace.fws.swf'))) {
    throw "Refusing to overwrite the retention candidate: $OutputSwf"
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
$runRoot = Join-Path $EvidenceRoot ('evidence\run-' + $stamp)
$inputRoot = Join-Path $runRoot 'input'
$exportRoot = Join-Path $runRoot 'decompiled'
$logRoot = Join-Path $runRoot 'logs'
foreach ($path in @($inputRoot, $exportRoot, $logRoot)) { New-Item -ItemType Directory -Force -Path $path | Out-Null }

$inputCopy = Join-Path $inputRoot 'petfightnew-retention-trace.fws.swf'
$sourceCopy = Join-Path $inputRoot 'DocPetFight.as'
Copy-Item -LiteralPath $InputSwf -Destination $inputCopy
Copy-Item -LiteralPath $SourceAs -Destination $sourceCopy
$candidate = Join-Path $runRoot 'petfightnew-owner-probe.fws.swf'

$replaceArguments = @('-onerror', 'abort', '-replace', $inputCopy, $candidate, $className, $sourceCopy)
Invoke-FFDec -Arguments $replaceArguments -Description "$className replacement" -LogPath (Join-Path $logRoot 'replace-doc.log')
Assert-Fws $candidate

$exportArguments = @('-onerror', 'abort', '-selectclass', $className, '-export', 'script', $exportRoot, $candidate)
Invoke-FFDec -Arguments $exportArguments -Description 'candidate DocPetFight script export' -LogPath (Join-Path $logRoot 'export-script.log')
$symbolArguments = @('-onerror', 'abort', '-export', 'symbolClass', $exportRoot, $candidate)
Invoke-FFDec -Arguments $symbolArguments -Description 'candidate SymbolClass export' -LogPath (Join-Path $logRoot 'export-symbolclass.log')

$exportedDoc = Join-Path $exportRoot 'scripts\mmo\petfightnew\DocPetFight.as'
if (-not (Test-Path -LiteralPath $exportedDoc -PathType Leaf)) { throw "FFDec did not export $className : $exportedDoc" }
$exportedSource = [IO.File]::ReadAllText($exportedDoc)
foreach ($token in $requiredCallbackTokens) {
    if ($exportedSource.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
        throw "The rebuilt DocPetFight is missing token: $token"
    }
}
foreach ($token in $forbiddenTokens) {
    if ($exportedSource.IndexOf($token, [StringComparison]::Ordinal) -ge 0) {
        throw "The rebuilt DocPetFight must not contain: $token"
    }
}

$symbolsPath = Join-Path $exportRoot 'symbols.csv'
if (-not (Test-Path -LiteralPath $symbolsPath -PathType Leaf)) { throw "FFDec did not export SymbolClass: $symbolsPath" }
$symbolsSource = [IO.File]::ReadAllText($symbolsPath)
if ($symbolsSource.IndexOf($className, [StringComparison]::Ordinal) -lt 0) {
    throw "The rebuilt SWF no longer maps $className."
}

# 全文件只能证明没有新增禁用调用；官方 StatusIconHandler 本来就有一次 unloadAndStop。
$baseBytes = [IO.File]::ReadAllBytes($inputCopy)
$candidateBytes = [IO.File]::ReadAllBytes($candidate)
$baseText = ConvertTo-Latin1Text $baseBytes
$candidateText = ConvertTo-Latin1Text $candidateBytes
$forbiddenEvidence = [ordered]@{}
foreach ($token in $forbiddenTokens) {
    $baseCount = Count-Ascii $baseText $token
    $candidateCount = Count-Ascii $candidateText $token
    if ($candidateCount -ne $baseCount) {
        throw "Injected code changed the '$token' occurrence count: base=$baseCount candidate=$candidateCount"
    }
    $forbiddenEvidence[$token] = [ordered]@{ base = $baseCount; candidate = $candidateCount; unchanged = $true }
}

$requiredMarkerCounts = [ordered]@{
    'aolaBattleProbeRelease' = 1
    'aolaBattleBridgeReady' = 1
    'aolaBattleApplyOptions' = 1
    'aolaBattleGetState' = 1
    'aolaBattleGetDiagnostics' = 1
    'aolaBattleDrainTraceEvents' = 1
    'mmo.petfightnew.DocPetFight' = 1
    'ensureAolaBattleBridge' = 2
    'noteInputReady' = 2
    'skipBattlePresentation' = 1
    'mmo.common.utils.tips.TipsManager' = 1
    'mmo.interfaces.material.headframe.HeadFrameFactory' = 1
    'owner-probe-ready' = 1
}
$markerEvidence = [ordered]@{}
foreach ($marker in $requiredMarkerCounts.Keys) {
    $count = Count-Ascii $candidateText $marker
    if ($count -ne $requiredMarkerCounts[$marker]) {
        throw "Candidate marker '$marker' count $count does not match the expected $($requiredMarkerCounts[$marker])."
    }
    $markerEvidence[$marker] = $count
}

$outputDirectory = Split-Path -Parent $OutputSwf
New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
$previousCopy = $null
if (Test-Path -LiteralPath $OutputSwf -PathType Leaf) {
    $previousCopy = Join-Path $runRoot 'previous-petfightnew-owner-probe.fws.swf'
    Copy-Item -LiteralPath $OutputSwf -Destination $previousCopy
}
Copy-Item -LiteralPath $candidate -Destination $OutputSwf -Force
Assert-Fws $OutputSwf

$outputBytes = [IO.File]::ReadAllBytes($OutputSwf)
$sha256 = (Get-FileHash -LiteralPath $OutputSwf -Algorithm SHA256).Hash.ToLowerInvariant()
$report = [ordered]@{
    schemaVersion = 1
    createdAt = (Get-Date).ToString('o')
    kind = 'battle-owner-probe-candidate'
    bridgeVersion = 5
    diagnosticsVersion = 4
    probeVersion = 1
    className = $className
    inputSwf = $InputSwf
    sourceAs = $SourceAs
    outputSwf = $OutputSwf
    ffdec = $FFDecPath
    ffdecReplace = @($FFDecPath) + $replaceArguments
    ffdecExportScript = @($FFDecPath) + $exportArguments
    ffdecExportSymbolClass = @($FFDecPath) + $symbolArguments
    runEvidence = $runRoot
    output = [ordered]@{
        length = $outputBytes.Length
        declaredLength = [BitConverter]::ToUInt32($outputBytes, 4)
        sha256 = $sha256
        fws = $true
        symbolClassContainsDocPetFight = $true
    }
    input = [ordered]@{
        length = $baseBytes.Length
        sha256 = (Get-FileHash -LiteralPath $InputSwf -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    checks = [ordered]@{
        fwsHeaderAndLength = $true
        symbolClass = $className
        exportedTokens = $requiredCallbackTokens
        forbiddenTokens = $forbiddenEvidence
        markerCounts = $markerEvidence
        systemGcAbsent = ($forbiddenEvidence['System.gc('].candidate -eq 0)
        unloadResAbsent = ($forbiddenEvidence['unloadRes'].candidate -eq 0)
        unloadAndStopOnlyPreexisting = $true
    }
    notes = @(
        'unloadAndStop 的 1 次出现来自官方 mmo.petfightnew.common.panel.status.StatusIconHandler，与本次注入无关；注入前后计数不变。',
        '候选只写入证据目录；生产清单 petfightnew-battle-state.current.json、生产候选与 retention 候选均未修改。',
        '静态检查不能证明 Flash 运行时行为；真实 5 场采集仍需按 README 的步骤完成。'
    )
}
$reportPath = Join-Path $EvidenceRoot 'evidence\report.json'
$report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $reportPath -Encoding utf8

[pscustomobject]@{
    status = 'Prepared'
    output = $OutputSwf
    length = $outputBytes.Length
    sha256 = $sha256
    report = $reportPath
    evidence = $runRoot
} | ConvertTo-Json
