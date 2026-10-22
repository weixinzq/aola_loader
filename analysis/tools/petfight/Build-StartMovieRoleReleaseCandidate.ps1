# 从 retention 候选重建 P4 step 3 候选（v3）：在 v2 基础上显式释放 _mcRole 容器。
# 只写 analysis/reverse-engineering/battle-startmovie-role-release-20261022/ 证据目录；不覆盖生产清单、生产候选、retention 或 v2 候选。
[CmdletBinding()]
param(
    [string]$InputSwf,
    [string]$PcodeFragment,
    [string]$FFDecPath = 'D:\Programs\FFdec\ffdec-cli.exe',
    [string]$EvidenceRoot,
    [string]$OutputSwf
)

$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
$retentionRoot = Join-Path $repo 'analysis\reverse-engineering\battle-retention-trace-20261017'
$productionRoot = Join-Path $repo 'analysis\AolaLoader\Resources\Patches'
$defaultEvidenceRoot = Join-Path $repo 'analysis\reverse-engineering\battle-startmovie-role-release-20261022'
$abcTool = Join-Path $repo 'analysis\tools\petfight_bridge_abc.py'
$className = 'mmo.petfightnew.common.startmovie.StartMovie'
$methodName = 'dispose'
$symbolClassName = 'mmo.petfightnew.DocPetFight'
$nullFields = @('_mc', '_mcRole', '_otherRole', '_fightSignInMcArr', '_ipts')
$forbiddenTokens = @('System.gc(', 'unloadRes', 'unloadAndStop')

if (-not $InputSwf) { $InputSwf = Join-Path $retentionRoot 'variants\petfightnew-retention-trace.fws.swf' }
if (-not $EvidenceRoot) { $EvidenceRoot = $defaultEvidenceRoot }
if (-not $PcodeFragment) { $PcodeFragment = Join-Path $defaultEvidenceRoot 'source\StartMovie.dispose.pcode' }
if (-not $OutputSwf) { $OutputSwf = Join-Path $EvidenceRoot 'variants\petfightnew-startmovie-role-release.fws.swf' }
$InputSwf = [IO.Path]::GetFullPath($InputSwf)
$PcodeFragment = [IO.Path]::GetFullPath($PcodeFragment)
$EvidenceRoot = [IO.Path]::GetFullPath($EvidenceRoot)
$OutputSwf = [IO.Path]::GetFullPath($OutputSwf)

function Assert-Fws([string]$Path) {
    $bytes = [IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -lt 8) { throw "SWF is too small: $Path" }
    if ([Text.Encoding]::ASCII.GetString($bytes, 0, 3) -cne 'FWS') {
        throw "Expected an uncompressed FWS file: $Path"
    }
    $declaredLength = [BitConverter]::ToUInt32($bytes, 4)
    if ([int64]$declaredLength -ne [int64]$bytes.Length) {
        throw "FWS declared length $declaredLength does not match file length $($bytes.Length): $Path"
    }
}

function Invoke-FFDec([string[]]$Arguments, [string]$Description, [string]$LogPath) {
    $output = & $FFDecPath @Arguments 2>&1 | Out-String
    [IO.File]::WriteAllText($LogPath, $output, [Text.UTF8Encoding]::new($false))
    if ($LASTEXITCODE -ne 0) {
        throw "$Description failed with exit code $LASTEXITCODE.`n$output"
    }
}

function Get-TrimmedLines([string[]]$Lines) {
    return @($Lines | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
}

function Find-UniqueLine([string[]]$Lines, [string]$Line) {
    $matches = @()
    for ($index = 0; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index] -ceq $Line) { $matches += $index }
    }
    if ($matches.Count -ne 1) {
        throw "Expected one '$Line', found $($matches.Count)."
    }
    return [int]$matches[0]
}

function Get-MethodBlock([string[]]$Lines, [string]$Signature) {
    $signatureIndexes = @()
    for ($index = 0; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index].Contains($Signature)) { $signatureIndexes += $index }
    }
    if ($signatureIndexes.Count -ne 1) {
        throw "Expected one p-code signature '$Signature', found $($signatureIndexes.Count)."
    }
    $methodIndex = -1
    for ($index = $signatureIndexes[0]; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index].Trim() -eq 'method') { $methodIndex = $index; break }
    }
    if ($methodIndex -lt 0) { throw "Method start not found for '$Signature'." }
    $depth = 0
    $endIndex = -1
    for ($index = $methodIndex; $index -lt $Lines.Count; $index++) {
        $trimmed = $Lines[$index].Trim()
        if ($trimmed -eq 'method') { $depth++ }
        elseif ($trimmed -eq 'end ; method') {
            $depth--
            if ($depth -eq 0) { $endIndex = $index; break }
        }
    }
    if ($endIndex -lt 0) { throw "Unterminated method body for '$Signature'." }
    return ,([string[]]$Lines[$methodIndex..$endIndex])
}

function Get-MethodLines([string]$Path, [string]$Signature) {
    return ,(Get-MethodBlock ([string[]](Get-Content -LiteralPath $Path)) $Signature)
}

function Get-LinesWithoutMethod([string[]]$Lines, [string]$Signature) {
    $signatureIndexes = @()
    for ($index = 0; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index].Contains($Signature)) { $signatureIndexes += $index }
    }
    if ($signatureIndexes.Count -ne 1) {
        throw "Expected one p-code signature '$Signature', found $($signatureIndexes.Count)."
    }
    $methodIndex = -1
    for ($index = $signatureIndexes[0]; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index].Trim() -eq 'method') { $methodIndex = $index; break }
    }
    if ($methodIndex -lt 0) { throw "Method start not found for '$Signature'." }
    $depth = 0
    $endIndex = -1
    for ($index = $methodIndex; $index -lt $Lines.Count; $index++) {
        $trimmed = $Lines[$index].Trim()
        if ($trimmed -eq 'method') { $depth++ }
        elseif ($trimmed -eq 'end ; method') {
            $depth--
            if ($depth -eq 0) { $endIndex = $index; break }
        }
    }
    if ($endIndex -lt 0) { throw "Unterminated method body for '$Signature'." }
    $remaining = @()
    for ($index = 0; $index -lt $Lines.Count; $index++) {
        if ($index -lt $methodIndex -or $index -gt $endIndex) { $remaining += $Lines[$index] }
    }
    return ,([string[]]$remaining)
}

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

function Get-Sha256([string]$Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

foreach ($path in @($FFDecPath, $PcodeFragment, $InputSwf, $abcTool)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Required file not found: $path" }
}
if (-not (Get-Command python -ErrorAction SilentlyContinue)) { throw 'python was not found on PATH.' }
foreach ($protected in @($InputSwf, $PcodeFragment)) {
    if ($OutputSwf -eq $protected) { throw "Refusing to overwrite an input file: $OutputSwf" }
}
if ($OutputSwf.StartsWith([IO.Path]::GetFullPath($productionRoot).TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to write the candidate into the production Resources/Patches directory: $OutputSwf"
}
if ($OutputSwf -eq [IO.Path]::GetFullPath((Join-Path $retentionRoot 'variants\petfightnew-retention-trace.fws.swf'))) {
    throw "Refusing to overwrite the retention candidate: $OutputSwf"
}
if ($OutputSwf -eq $InputSwf) { throw "Refusing to overwrite the input: $OutputSwf" }

# 先校验 p-code 方法体：保留 noteRetentionStartDisposed，先清 _mc 子树，再断开 _mc 和 _mcRole 容器，最后置空 5 个字段。
$rawFragmentLines = [string[]](Get-Content -LiteralPath $PcodeFragment)
$fragmentLines = Get-TrimmedLines $rawFragmentLines
$trimmedLineNumbers = @()
for ($index = 0; $index -lt $rawFragmentLines.Count; $index++) {
    if ($rawFragmentLines[$index].Trim() -ne '') { $trimmedLineNumbers += $index + 1 }
}
if ($fragmentLines.Count -lt 32 -or $fragmentLines[0] -cne 'method' -or
    $fragmentLines[$fragmentLines.Count - 1] -cne 'end ; method') {
    throw "P-code fragment is not a complete method block: $PcodeFragment"
}
$fragmentInfo = [ordered]@{}
$maxstackMatch = @($fragmentLines | Where-Object { $_ -match '^maxstack \d+$' })
$localcountMatch = @($fragmentLines | Where-Object { $_ -match '^localcount \d+$' })
if ($maxstackMatch.Count -ne 1 -or $localcountMatch.Count -ne 1) {
    throw 'P-code fragment must contain one maxstack and one localcount.'
}
$fragmentInfo.maxstack = [int]($maxstackMatch[0] -replace '^maxstack ', '')
$fragmentInfo.localcount = [int]($localcountMatch[0] -replace '^localcount ', '')
if ($fragmentInfo.maxstack -lt 2) { throw 'P-code maxstack must be at least 2 for the appended assignments.' }

$noteIndex = Find-UniqueLine $fragmentLines 'callpropvoid QName(PackageNamespace(""),"noteRetentionStartDisposed"), 7'
$returnIndex = Find-UniqueLine $fragmentLines 'returnvoid'
if ($noteIndex -ge $returnIndex) { throw 'noteRetentionStartDisposed must precede returnvoid.' }

$stopAndRemoveChildMc = @(
    'getlex QName(PackageNamespace("mmo.common"),"DisplayUtil")',
    'getlocal0',
    'getproperty QName(PrivateNamespace(null,"172"),"_mc")',
    'callpropvoid QName(PackageNamespace(""),"stopAndRemoveChild"), 1'
)
for ($index = 0; $index -lt $stopAndRemoveChildMc.Count; $index++) {
    if ($fragmentLines[$noteIndex + 1 + $index] -cne $stopAndRemoveChildMc[$index]) {
        throw "DisplayUtil.stopAndRemoveChild(this._mc) is missing immediately after noteRetentionStartDisposed."
    }
}

$stopAndRemoveMc = @(
    'getlex QName(PackageNamespace("mmo.common"),"DisplayUtil")',
    'getlocal0',
    'getproperty QName(PrivateNamespace(null,"172"),"_mc")',
    'callpropvoid QName(PackageNamespace(""),"stopAndRemove"), 1'
)
for ($index = 0; $index -lt $stopAndRemoveMc.Count; $index++) {
    if ($fragmentLines[$noteIndex + 1 + $stopAndRemoveChildMc.Count + $index] -cne $stopAndRemoveMc[$index]) {
        throw "DisplayUtil.stopAndRemove(this._mc) is missing immediately after stopAndRemoveChild."
    }
}

$stopAndRemoveChildRole = @(
    'getlex QName(PackageNamespace("mmo.common"),"DisplayUtil")',
    'getlocal0',
    'getproperty QName(PrivateNamespace(null,"172"),"_mcRole")',
    'callpropvoid QName(PackageNamespace(""),"stopAndRemoveChild"), 1'
)
$roleChildStart = $noteIndex + 1 + $stopAndRemoveChildMc.Count + $stopAndRemoveMc.Count
for ($index = 0; $index -lt $stopAndRemoveChildRole.Count; $index++) {
    if ($fragmentLines[$roleChildStart + $index] -cne $stopAndRemoveChildRole[$index]) {
        throw "DisplayUtil.stopAndRemoveChild(this._mcRole) is missing immediately after stopAndRemove(this._mc)."
    }
}

$stopAndRemoveRole = @(
    'getlex QName(PackageNamespace("mmo.common"),"DisplayUtil")',
    'getlocal0',
    'getproperty QName(PrivateNamespace(null,"172"),"_mcRole")',
    'callpropvoid QName(PackageNamespace(""),"stopAndRemove"), 1'
)
$roleStopStart = $roleChildStart + $stopAndRemoveChildRole.Count
for ($index = 0; $index -lt $stopAndRemoveRole.Count; $index++) {
    if ($fragmentLines[$roleStopStart + $index] -cne $stopAndRemoveRole[$index]) {
        throw "DisplayUtil.stopAndRemove(this._mcRole) is missing immediately after stopAndRemoveChild(_mcRole)."
    }
}

$nullAssignments = [ordered]@{}
$expectedIndex = $roleStopStart + $stopAndRemoveRole.Count
foreach ($field in $nullFields) {
    $expected = @(
        'getlocal0',
        'pushnull',
        ('setproperty QName(PrivateNamespace(null,"172"),"' + $field + '")')
    )
    for ($index = 0; $index -lt $expected.Count; $index++) {
        if ($fragmentLines[$expectedIndex + $index] -cne $expected[$index]) {
            throw "Missing null assignment for $field at the expected position."
        }
    }
    $nullAssignments[$field] = $expectedIndex
    $expectedIndex += $expected.Count
}
if ($expectedIndex -ne $returnIndex) {
    throw 'Unexpected instructions between the null assignments and returnvoid.'
}
if (($fragmentLines -join "`n").Contains('unloadAndStop') -or
    ($fragmentLines -join "`n").Contains('System.gc(') -or
    ($fragmentLines -join "`n").Contains('unloadRes')) {
    throw 'P-code fragment contains a forbidden call.'
}
$reportNullAssignmentLines = [ordered]@{}
foreach ($field in $nullFields) {
    $reportNullAssignmentLines[$field] = $trimmedLineNumbers[$nullAssignments[$field] + 2]
}
$fragmentInfo.noteRetentionLine = $trimmedLineNumbers[$noteIndex]
$fragmentInfo.stopAndRemoveChildLine = $trimmedLineNumbers[$noteIndex + 1]
$fragmentInfo.stopAndRemoveLine = $trimmedLineNumbers[$noteIndex + 1 + $stopAndRemoveChildMc.Count]
$fragmentInfo.stopAndRemoveChildRoleLine = $trimmedLineNumbers[$roleChildStart]
$fragmentInfo.stopAndRemoveRoleLine = $trimmedLineNumbers[$roleStopStart]
$fragmentInfo.nullAssignmentLines = $reportNullAssignmentLines
$fragmentInfo.returnLine = $trimmedLineNumbers[$returnIndex]

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
$runRoot = Join-Path $EvidenceRoot ('evidence\run-' + $stamp)
$inputRoot = Join-Path $runRoot 'input'
$logRoot = Join-Path $runRoot 'logs'
$pcodeBaseRoot = Join-Path $runRoot 'decompiled\pcode-base'
$pcodeCandidateRoot = Join-Path $runRoot 'decompiled\pcode-candidate'
$docBaseRoot = Join-Path $runRoot 'decompiled\doc-base'
$docCandidateRoot = Join-Path $runRoot 'decompiled\doc-candidate'
$symbolBaseRoot = Join-Path $runRoot 'decompiled\symbol-base'
$symbolCandidateRoot = Join-Path $runRoot 'decompiled\symbol-candidate'
foreach ($path in @($inputRoot, $logRoot, $pcodeBaseRoot, $pcodeCandidateRoot,
    $docBaseRoot, $docCandidateRoot, $symbolBaseRoot, $symbolCandidateRoot)) {
    New-Item -ItemType Directory -Force -Path $path | Out-Null
}

$inputCopy = Join-Path $inputRoot 'petfightnew-retention-trace.fws.swf'
$fragmentCopy = Join-Path $inputRoot 'StartMovie.dispose.pcode'
Copy-Item -LiteralPath $InputSwf -Destination $inputCopy
Copy-Item -LiteralPath $PcodeFragment -Destination $fragmentCopy
$candidate = Join-Path $runRoot 'petfightnew-startmovie-role-release.fws.swf'

$methodArguments = @('methods', '--input', $InputSwf, '--target', ($className + ':' + $methodName))
$methodOutput = & python $abcTool @methodArguments
if ($LASTEXITCODE -ne 0) { throw 'Baseline method-body index discovery failed.' }
[IO.File]::WriteAllText(
    (Join-Path $logRoot 'methods-base.json'),
    (($methodOutput -join [Environment]::NewLine) + [Environment]::NewLine),
    [Text.UTF8Encoding]::new($false))
$baseMethods = @(($methodOutput -join [Environment]::NewLine) | ConvertFrom-Json)
if ($baseMethods.Count -ne 1) {
    throw "Expected one $className.$methodName method-body index, found $($baseMethods.Count)."
}
$baseMethodBodyIndex = [int]$baseMethods[0].methodBodyIndex
$baseMethodIndex = [int]$baseMethods[0].methodIndex

$replaceArguments = @(
    '-onerror', 'abort', '-replace', $inputCopy, $candidate,
    $className, $fragmentCopy, [string]$baseMethodBodyIndex
)
Invoke-FFDec -Arguments $replaceArguments -Description "$className.$methodName replacement" `
    -LogPath (Join-Path $logRoot 'replace-dispose.log')
Assert-Fws $candidate

$pcodeBaseArguments = @(
    '-onerror', 'abort', '-format', 'script:pcode', '-selectclass', $className,
    '-export', 'script', $pcodeBaseRoot, $inputCopy
)
$pcodeCandidateArguments = @(
    '-onerror', 'abort', '-format', 'script:pcode', '-selectclass', $className,
    '-export', 'script', $pcodeCandidateRoot, $candidate
)
$docBaseArguments = @(
    '-onerror', 'abort', '-selectclass', $symbolClassName,
    '-export', 'script', $docBaseRoot, $inputCopy
)
$docCandidateArguments = @(
    '-onerror', 'abort', '-selectclass', $symbolClassName,
    '-export', 'script', $docCandidateRoot, $candidate
)
$symbolBaseArguments = @('-onerror', 'abort', '-export', 'symbolClass', $symbolBaseRoot, $inputCopy)
$symbolCandidateArguments = @('-onerror', 'abort', '-export', 'symbolClass', $symbolCandidateRoot, $candidate)

Invoke-FFDec -Arguments $pcodeBaseArguments -Description 'baseline StartMovie p-code export' `
    -LogPath (Join-Path $logRoot 'export-pcode-base.log')
Invoke-FFDec -Arguments $pcodeCandidateArguments -Description 'candidate StartMovie p-code export' `
    -LogPath (Join-Path $logRoot 'export-pcode-candidate.log')
Invoke-FFDec -Arguments $docBaseArguments -Description 'baseline DocPetFight script export' `
    -LogPath (Join-Path $logRoot 'export-doc-base.log')
Invoke-FFDec -Arguments $docCandidateArguments -Description 'candidate DocPetFight script export' `
    -LogPath (Join-Path $logRoot 'export-doc-candidate.log')
Invoke-FFDec -Arguments $symbolBaseArguments -Description 'baseline SymbolClass export' `
    -LogPath (Join-Path $logRoot 'export-symbol-base.log')
Invoke-FFDec -Arguments $symbolCandidateArguments -Description 'candidate SymbolClass export' `
    -LogPath (Join-Path $logRoot 'export-symbol-candidate.log')

$pcodeRelative = 'scripts\mmo\petfightnew\common\startmovie\StartMovie.pcode'
$pcodeBasePath = Join-Path $pcodeBaseRoot $pcodeRelative
$pcodeCandidatePath = Join-Path $pcodeCandidateRoot $pcodeRelative
if (-not (Test-Path -LiteralPath $pcodeBasePath -PathType Leaf) -or
    -not (Test-Path -LiteralPath $pcodeCandidatePath -PathType Leaf)) {
    throw 'FFDec did not export the StartMovie p-code for the baseline or candidate.'
}
$docRelative = 'scripts\mmo\petfightnew\DocPetFight.as'
$docBasePath = Join-Path $docBaseRoot $docRelative
$docCandidatePath = Join-Path $docCandidateRoot $docRelative
$symbolBasePath = Join-Path $symbolBaseRoot 'symbols.csv'
$symbolCandidatePath = Join-Path $symbolCandidateRoot 'symbols.csv'
foreach ($path in @($docBasePath, $docCandidatePath, $symbolBasePath, $symbolCandidatePath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "FFDec did not export: $path" }
}

$candidateMethodOutput = & python $abcTool methods --input $candidate --target ($className + ':' + $methodName)
if ($LASTEXITCODE -ne 0) { throw 'Candidate method-body index discovery failed.' }
[IO.File]::WriteAllText(
    (Join-Path $logRoot 'methods-candidate.json'),
    (($candidateMethodOutput -join [Environment]::NewLine) + [Environment]::NewLine),
    [Text.UTF8Encoding]::new($false))
$candidateMethods = @(($candidateMethodOutput -join [Environment]::NewLine) | ConvertFrom-Json)
if ($candidateMethods.Count -ne 1) {
    throw "Expected one candidate $className.$methodName method-body index, found $($candidateMethods.Count)."
}
if ([int]$candidateMethods[0].methodBodyIndex -ne $baseMethodBodyIndex) {
    throw "Candidate method-body index changed: base=$baseMethodBodyIndex candidate=$($candidateMethods[0].methodBodyIndex)"
}

$candidateDispose = Get-MethodLines $pcodeCandidatePath 'private function dispose()'
$candidateDisposeLines = Get-TrimmedLines $candidateDispose
$sourceFragmentLines = Get-TrimmedLines ([string[]](Get-Content -LiteralPath $fragmentCopy))
if ($candidateDisposeLines.Count -ne $sourceFragmentLines.Count) {
    throw 'Candidate dispose p-code line count differs from the generated fragment.'
}
for ($index = 0; $index -lt $sourceFragmentLines.Count; $index++) {
    if ($candidateDisposeLines[$index] -cne $sourceFragmentLines[$index]) {
        throw "Candidate dispose p-code differs from the generated fragment at line $($index + 1)."
    }
}

$candidateNoteIndex = Find-UniqueLine $candidateDisposeLines 'callpropvoid QName(PackageNamespace(""),"noteRetentionStartDisposed"), 7'
$candidateReturnIndex = Find-UniqueLine $candidateDisposeLines 'returnvoid'
$candidateRemoveChildMcIndex = -1
$candidateStopMcIndex = -1
$candidateRemoveChildRoleIndex = -1
$candidateStopRoleIndex = -1
for ($index = 0; $index -le $candidateDisposeLines.Count - 4; $index++) {
    if ($candidateDisposeLines[$index] -ceq 'getlex QName(PackageNamespace("mmo.common"),"DisplayUtil")' -and
        $candidateDisposeLines[$index + 1] -ceq 'getlocal0' -and
        $candidateDisposeLines[$index + 2] -ceq 'getproperty QName(PrivateNamespace(null,"172"),"_mc")' -and
        $candidateDisposeLines[$index + 3] -ceq 'callpropvoid QName(PackageNamespace(""),"stopAndRemoveChild"), 1') {
        if ($candidateRemoveChildMcIndex -ge 0) { throw 'Duplicate DisplayUtil.stopAndRemoveChild(this._mc) sequence.' }
        $candidateRemoveChildMcIndex = $index
    }
    if ($candidateDisposeLines[$index] -ceq 'getlex QName(PackageNamespace("mmo.common"),"DisplayUtil")' -and
        $candidateDisposeLines[$index + 1] -ceq 'getlocal0' -and
        $candidateDisposeLines[$index + 2] -ceq 'getproperty QName(PrivateNamespace(null,"172"),"_mc")' -and
        $candidateDisposeLines[$index + 3] -ceq 'callpropvoid QName(PackageNamespace(""),"stopAndRemove"), 1') {
        if ($candidateStopMcIndex -ge 0) { throw 'Duplicate DisplayUtil.stopAndRemove(this._mc) sequence.' }
        $candidateStopMcIndex = $index
    }
    if ($candidateDisposeLines[$index] -ceq 'getlex QName(PackageNamespace("mmo.common"),"DisplayUtil")' -and
        $candidateDisposeLines[$index + 1] -ceq 'getlocal0' -and
        $candidateDisposeLines[$index + 2] -ceq 'getproperty QName(PrivateNamespace(null,"172"),"_mcRole")' -and
        $candidateDisposeLines[$index + 3] -ceq 'callpropvoid QName(PackageNamespace(""),"stopAndRemoveChild"), 1') {
        if ($candidateRemoveChildRoleIndex -ge 0) { throw 'Duplicate DisplayUtil.stopAndRemoveChild(this._mcRole) sequence.' }
        $candidateRemoveChildRoleIndex = $index
    }
    if ($candidateDisposeLines[$index] -ceq 'getlex QName(PackageNamespace("mmo.common"),"DisplayUtil")' -and
        $candidateDisposeLines[$index + 1] -ceq 'getlocal0' -and
        $candidateDisposeLines[$index + 2] -ceq 'getproperty QName(PrivateNamespace(null,"172"),"_mcRole")' -and
        $candidateDisposeLines[$index + 3] -ceq 'callpropvoid QName(PackageNamespace(""),"stopAndRemove"), 1') {
        if ($candidateStopRoleIndex -ge 0) { throw 'Duplicate DisplayUtil.stopAndRemove(this._mcRole) sequence.' }
        $candidateStopRoleIndex = $index
    }
}
if ($candidateRemoveChildMcIndex -lt 0) { throw 'Candidate dispose p-code is missing DisplayUtil.stopAndRemoveChild(this._mc).' }
if ($candidateStopMcIndex -lt 0) { throw 'Candidate dispose p-code is missing DisplayUtil.stopAndRemove(this._mc).' }
if ($candidateRemoveChildRoleIndex -lt 0) { throw 'Candidate dispose p-code is missing DisplayUtil.stopAndRemoveChild(this._mcRole).' }
if ($candidateStopRoleIndex -lt 0) { throw 'Candidate dispose p-code is missing DisplayUtil.stopAndRemove(this._mcRole).' }
if ($candidateNoteIndex -ge $candidateRemoveChildMcIndex) {
    throw 'noteRetentionStartDisposed must precede DisplayUtil.stopAndRemoveChild(this._mc).'
}
if ($candidateRemoveChildMcIndex -ge $candidateStopMcIndex) {
    throw 'DisplayUtil.stopAndRemoveChild(this._mc) must precede DisplayUtil.stopAndRemove(this._mc).'
}
if ($candidateStopMcIndex -ge $candidateRemoveChildRoleIndex) {
    throw 'DisplayUtil.stopAndRemoveChild(this._mcRole) must follow DisplayUtil.stopAndRemove(this._mc).'
}
if ($candidateRemoveChildRoleIndex -ge $candidateStopRoleIndex) {
    throw 'DisplayUtil.stopAndRemoveChild(this._mcRole) must precede DisplayUtil.stopAndRemove(this._mcRole).'
}
$candidateNullLines = [ordered]@{}
$lastNullIndex = $candidateStopRoleIndex
foreach ($field in $nullFields) {
    $fieldOperand = 'setproperty QName(PrivateNamespace(null,"172"),"' + $field + '")'
    $matches = @()
    for ($index = 0; $index -le $candidateDisposeLines.Count - 3; $index++) {
        if ($candidateDisposeLines[$index] -ceq 'getlocal0' -and
            $candidateDisposeLines[$index + 1] -ceq 'pushnull' -and
            $candidateDisposeLines[$index + 2] -ceq $fieldOperand) {
            $matches += $index
        }
    }
    if ($matches.Count -ne 1) {
        throw "Expected one null assignment for $field, found $($matches.Count)."
    }
    if ($matches[0] -le $candidateStopRoleIndex -or $matches[0] -ge $candidateReturnIndex) {
        throw "Null assignment for $field is outside the expected order."
    }
    $candidateNullLines[$field] = $matches[0]
    if ($matches[0] -gt $lastNullIndex) { $lastNullIndex = $matches[0] }
}
if ($lastNullIndex -ge $candidateReturnIndex) {
    throw 'returnvoid must follow all null assignments.'
}

$basePcodeLines = [string[]](Get-Content -LiteralPath $pcodeBasePath)
$candidatePcodeLines = [string[]](Get-Content -LiteralPath $pcodeCandidatePath)
$baseOther = @(Get-TrimmedLines (Get-LinesWithoutMethod $basePcodeLines 'private function dispose()'))
$candidateOther = @(Get-TrimmedLines (Get-LinesWithoutMethod $candidatePcodeLines 'private function dispose()'))
if ($baseOther.Count -ne $candidateOther.Count) {
    throw "StartMovie p-code outside dispose changed line count: base=$($baseOther.Count) candidate=$($candidateOther.Count)."
}
for ($index = 0; $index -lt $baseOther.Count; $index++) {
    if ($baseOther[$index] -cne $candidateOther[$index]) {
        throw "StartMovie p-code outside dispose changed at line $($index + 1)."
    }
}

if ((Get-Sha256 $docBasePath) -cne (Get-Sha256 $docCandidatePath)) {
    throw 'DocPetFight script export changed; BRIDGE_VERSION/DIAGNOSTICS_VERSION may have changed.'
}
$docCandidateSource = [IO.File]::ReadAllText($docCandidatePath)
foreach ($token in @(
    'private static const BRIDGE_VERSION:int = 5;',
    'private static const DIAGNOSTICS_VERSION:int = 4;')) {
    if ($docCandidateSource.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
        throw "Candidate DocPetFight is missing: $token"
    }
}
if ((Get-Sha256 $symbolBasePath) -cne (Get-Sha256 $symbolCandidatePath)) {
    throw 'Candidate SymbolClass export differs from the baseline.'
}
$symbolSource = [IO.File]::ReadAllText($symbolCandidatePath)
if ($symbolSource.IndexOf($symbolClassName, [StringComparison]::Ordinal) -lt 0) {
    throw "The candidate SWF no longer maps $symbolClassName."
}

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
if ($forbiddenEvidence['System.gc('].candidate -ne 0 -or $forbiddenEvidence['unloadRes'].candidate -ne 0) {
    throw 'Candidate contains System.gc( or unloadRes.'
}

$outputDirectory = Split-Path -Parent $OutputSwf
New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
$previousCopy = $null
if (Test-Path -LiteralPath $OutputSwf -PathType Leaf) {
    $previousCopy = Join-Path $runRoot 'previous-petfightnew-startmovie-role-release.fws.swf'
    Copy-Item -LiteralPath $OutputSwf -Destination $previousCopy
}
Copy-Item -LiteralPath $candidate -Destination $OutputSwf -Force
Assert-Fws $OutputSwf

$outputBytes = [IO.File]::ReadAllBytes($OutputSwf)
$outputSha256 = Get-Sha256 $OutputSwf
$report = [ordered]@{
    schemaVersion = 1
    createdAt = (Get-Date).ToString('o')
    kind = 'battle-startmovie-role-release-candidate'
    bridgeVersion = 5
    diagnosticsVersion = 4
    className = $className
    methodName = $methodName
    methodIndex = $baseMethodIndex
    methodBodyIndex = $baseMethodBodyIndex
    inputSwf = $InputSwf
    pcodeFragment = $PcodeFragment
    outputSwf = $OutputSwf
    ffdec = $FFDecPath
    ffdecReplace = @($FFDecPath) + $replaceArguments
    ffdecExports = [ordered]@{
        pcodeBase = @($FFDecPath) + $pcodeBaseArguments
        pcodeCandidate = @($FFDecPath) + $pcodeCandidateArguments
        docBase = @($FFDecPath) + $docBaseArguments
        docCandidate = @($FFDecPath) + $docCandidateArguments
        symbolBase = @($FFDecPath) + $symbolBaseArguments
        symbolCandidate = @($FFDecPath) + $symbolCandidateArguments
    }
    runEvidence = $runRoot
    input = [ordered]@{
        length = $baseBytes.Length
        sha256 = Get-Sha256 $inputCopy
    }
    pcode = [ordered]@{
        maxstack = $fragmentInfo.maxstack
        localcount = $fragmentInfo.localcount
        lineNumberBase = '1-based line in source/StartMovie.dispose.pcode'
        noteRetentionLine = $fragmentInfo.noteRetentionLine
        stopAndRemoveChildLine = $fragmentInfo.stopAndRemoveChildLine
        stopAndRemoveLine = $fragmentInfo.stopAndRemoveLine
        stopAndRemoveChildRoleLine = $fragmentInfo.stopAndRemoveChildRoleLine
        stopAndRemoveRoleLine = $fragmentInfo.stopAndRemoveRoleLine
        nullAssignmentLines = $fragmentInfo.nullAssignmentLines
        returnLine = $fragmentInfo.returnLine
    }
    output = [ordered]@{
        length = $outputBytes.Length
        declaredLength = [BitConverter]::ToUInt32($outputBytes, 4)
        sha256 = $outputSha256
        fws = $true
        symbolClassContainsDocPetFight = $true
    }
    checks = [ordered]@{
        fwsHeaderAndLength = $true
        symbolClass = $symbolClassName
        symbolClassUnchanged = $true
        methodBodyIndexStable = $true
        startMoviePcodePresent = $true
        disposePcode = [ordered]@{
            exactMatchToFragment = $true
            noteRetentionBeforeCleanup = $true
            stopAndRemoveChildThisMc = $true
            stopAndRemoveChildBeforeStopAndRemove = $true
            stopAndRemoveThisMc = $true
            stopAndRemoveChildThisMcRole = $true
            stopAndRemoveChildRoleBeforeStopAndRemoveRole = $true
            stopAndRemoveThisMcRole = $true
            nullAssignments = @($nullFields)
            otherStartMovieMethodsUnchanged = $true
        }
        docPetFightUnchanged = $true
        bridgeVersion = 5
        diagnosticsVersion = 4
        forbiddenTokens = $forbiddenEvidence
        systemGcAbsent = ($forbiddenEvidence['System.gc('].candidate -eq 0)
        unloadResAbsent = ($forbiddenEvidence['unloadRes'].candidate -eq 0)
        unloadAndStopUnchanged = $true
    }
    notes = @(
        'v3 只替换 StartMovie.dispose 的方法体（FFDec -replace 指定 methodBodyIndex），不改变方法索引和类结构。',
        '在 v2 的 stopAndRemove(this._mc) 之后追加 stopAndRemoveChild(this._mcRole) 和 stopAndRemove(this._mcRole)，显式断开 role 容器及其内部 role。',
        '生产 StartMovie.dispose.pcode 未修改；证据目录 source/StartMovie.dispose.pcode 是本次替换用的候选方法体。',
        '生产清单 petfightnew-battle-state.current.json、生产候选、retention 候选与 v2 候选均未修改。',
        '静态检查不能证明 Flash 运行时行为；真实 A/B 仍需按 README 的步骤完成。'
    )
}
if ($previousCopy) { $report['previousOutput'] = $previousCopy }
$reportPath = Join-Path $EvidenceRoot 'evidence\report.json'
$report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $reportPath -Encoding utf8

[pscustomobject]@{
    status = 'Prepared'
    output = $OutputSwf
    length = $outputBytes.Length
    sha256 = $outputSha256
    methodBodyIndex = $baseMethodBodyIndex
    report = $reportPath
    evidence = $runRoot
} | ConvertTo-Json
