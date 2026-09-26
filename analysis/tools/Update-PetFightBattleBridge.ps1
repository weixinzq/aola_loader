[CmdletBinding()]
param(
    [ValidateSet('Check', 'Prepare', 'Promote')]
    [string]$Mode = 'Check',
    [string]$FFDecPath = 'D:\Programs\FFdec\ffdec-cli.exe',
    [string]$EvidenceRoot,
    [string]$CandidateManifest,
    [string]$StartUrl = 'https://aola.100bt.com/play/start.xml',
    [ValidateSet('DiagnosticOnly', 'ConservativeCleanup')]
    [string]$ResourceCleanupMode = 'DiagnosticOnly'
)

$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$helperPath = Join-Path $PSScriptRoot 'petfight_bridge_abc.py'
$bridgeTemplatePath = Join-Path $PSScriptRoot 'petfight\DocPetFight.bridge.template.as'
$presentationPatchBuilder = Join-Path $PSScriptRoot 'petfight\New-PetFightPresentationPatches.ps1'
$patchDirectory = Join-Path $repoRoot 'analysis\AolaLoader\Resources\Patches'
$productionManifestPath = Join-Path $patchDirectory 'petfightnew-battle-state.current.json'
$productionCandidatePath = Join-Path $patchDirectory 'petfightnew-battle-state-current.fws.swf'
$maximumSwfBytes = 16MB
$requiredMarkers = @(
    'aolaBattleBridgeReady',
    'aolaBattleApplyOptions',
    'aolaBattleGetState',
    'aolaBattleGetDiagnostics',
    'aolaBattleDrainTraceEvents',
    'mmo.petfightnew.DocPetFight',
    'mmo.petfightnew.common.FightPanel',
    'ensureAolaBattleBridge',
    'noteInputReady',
    'noteDiagnosticPanel',
    'noteDiagnosticPanelDisposeStarted',
    'noteDiagnosticPanelDisposed',
    'noteDiagnosticStartMovie',
    'noteDiagnosticApplicationDomain',
    'noteDiagnosticPreloadStarted',
    'noteDiagnosticResourceStarted',
    'noteDiagnosticResourceEnded',
    'noteDiagnosticSkillEffectStarted',
    'noteDiagnosticSkillEffectCallback',
    'noteDiagnosticSkillEffectDisposed',
    'noteDiagnosticAttackStarted',
    'noteDiagnosticAttackEnded',
    'attackWatchdogTimeoutCount',
    'longFrame100Count',
    'skipBattlePresentation',
    'hideDamageNumbers',
    'hideHealingNumbers'
)
$forbiddenMarkers = @('skipAttackAnimation', 'skipPetAttackActions', 'skipBattleVisualDelays')

function Assert-Tool([string]$Path, [string]$Description) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "$Description not found: $Path"
    }
}

function Invoke-Checked([string]$Executable, [string[]]$Arguments, [string]$Description) {
    & $Executable @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Description failed with exit code $LASTEXITCODE."
    }
}

function Get-Sha256([string]$Path) {
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

function Get-SwfDetails([string]$Path) {
    $output = & python $helperPath inspect --input $Path
    if ($LASTEXITCODE -ne 0) { throw "SWF inspection failed: $Path" }
    return (($output -join [Environment]::NewLine) | ConvertFrom-Json)
}

function Assert-Fws([string]$Path, [string]$ExpectedHash = '') {
    $details = Get-SwfDetails $Path
    if ($details.signature -ne 'FWS' -or -not $details.lengthValid -or
        [int64]$details.fileSize -gt $maximumSwfBytes) {
        throw "Expected a bounded valid FWS file: $Path"
    }
    if ($ExpectedHash -and $details.sha256 -cne $ExpectedHash) {
        throw "FWS SHA-256 mismatch for $Path."
    }
    return $details
}

function Assert-Within([string]$Root, [string]$Path) {
    $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd('\') + '\'
    $pathFull = [IO.Path]::GetFullPath($Path)
    if (-not $pathFull.StartsWith($rootFull, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Path escapes the expected directory: $pathFull"
    }
    return $pathFull
}

function Copy-EvidenceFile([string]$Source, [string]$Destination) {
    $parent = Split-Path -Parent $Destination
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    if (Test-Path -LiteralPath $Destination) {
        if ((Get-Sha256 $Source) -cne (Get-Sha256 $Destination)) {
            throw "Refusing to overwrite different evidence: $Destination"
        }
        return
    }
    Copy-Item -LiteralPath $Source -Destination $Destination
}

function Set-GeneratedText([string]$Path, [string[]]$Value) {
    $text = ($Value -join [Environment]::NewLine) + [Environment]::NewLine
    if (Test-Path -LiteralPath $Path) {
        $existing = [IO.File]::ReadAllText($Path).Replace("`r`n", "`n").TrimEnd("`n")
        $expected = $text.Replace("`r`n", "`n").TrimEnd("`n")
        if ($existing -cne $expected) {
            throw "Refusing to overwrite different generated input: $Path"
        }
        return
    }
    [IO.File]::WriteAllText($Path, $text, [Text.UTF8Encoding]::new($false))
}

function Remove-VerifiedTemp([string]$Path) {
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    $resolved = [IO.Path]::GetFullPath($Path)
    if (-not $resolved.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove a directory outside the system temp root: $resolved"
    }
    if (Test-Path -LiteralPath $resolved) {
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}

function Get-LiveDescriptor([string]$PreserveRoot = '') {
    $tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('aola-petfight-check-' + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null
    try {
        $startPath = Join-Path $tempRoot 'start.xml'
        Invoke-WebRequest -UseBasicParsing -Uri $StartUrl -OutFile $startPath
        [xml]$startXml = [IO.File]::ReadAllText($startPath)
        $versionDataVersion = [string]$startXml.r.v
        if ($versionDataVersion -notmatch '^\d{1,32}$') {
            throw 'start.xml did not contain one valid versiondata version.'
        }

        $versionDataUrl = "https://aola.100bt.com/play/versiondata~$versionDataVersion.swf"
        $versionDataPath = Join-Path $tempRoot "versiondata~$versionDataVersion.swf"
        Invoke-WebRequest -UseBasicParsing -Uri $versionDataUrl -OutFile $versionDataPath
        $versionDataDetails = Get-SwfDetails $versionDataPath

        $versionDataExport = Join-Path $tempRoot 'versiondata-export'
        Invoke-Checked $FFDecPath @(
            '-onerror', 'abort', '-export', 'binaryData', $versionDataExport, $versionDataPath
        ) 'versiondata binary export'
        $embedded = @(Get-ChildItem -LiteralPath $versionDataExport -Recurse -File -Filter '*.bin')
        if ($embedded.Count -ne 1) {
            throw "Expected one embedded version XML, found $($embedded.Count)."
        }
        [xml]$versionXml = [IO.File]::ReadAllText($embedded[0].FullName)
        $matches = @($versionXml.version.f | Where-Object { [string]$_.n -ceq 'pet/petfightnew' })
        if ($matches.Count -ne 1) {
            throw "Expected one pet/petfightnew mapping, found $($matches.Count)."
        }
        $resourceVersion = [string]$matches[0].v
        $updateMatches = @($startXml.r.u.f | Where-Object { [string]$_.n -ceq 'pet/petfightnew' })
        if ($updateMatches.Count -gt 1) {
            throw "Expected at most one pet/petfightnew update mapping, found $($updateMatches.Count)."
        }
        if ($updateMatches.Count -eq 1) {
            $resourceVersion = [string]$updateMatches[0].v
        }
        if ($resourceVersion -notmatch '^\d{1,32}$') {
            throw 'The petfightnew mapping contains an invalid version.'
        }

        if ($PreserveRoot) {
            $sourceRoot = Join-Path $PreserveRoot 'source'
            $metadataRoot = Join-Path $PreserveRoot 'metadata'
            Copy-EvidenceFile $startPath (Join-Path $sourceRoot "start-$versionDataVersion.xml")
            Copy-EvidenceFile $versionDataPath (Join-Path $sourceRoot "versiondata~$versionDataVersion.swf")
            Copy-EvidenceFile $embedded[0].FullName (Join-Path $metadataRoot "versiondata~$versionDataVersion.xml")
        }

        return [pscustomobject]@{
            ResourceVersion = $resourceVersion
            OfficialUrl = "https://aola.100bt.com/play/pet/petfightnew~$resourceVersion.swf"
            VersionDataVersion = $versionDataVersion
            VersionDataUrl = $versionDataUrl
            VersionDataSha256 = [string]$versionDataDetails.sha256
        }
    }
    finally {
        Remove-VerifiedTemp $tempRoot
    }
}

function Get-MethodFragment([string]$Path, [string]$Signature) {
    $lines = @(Get-Content -LiteralPath $Path)
    $signatureIndexes = @()
    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($lines[$index].Contains($Signature)) { $signatureIndexes += $index }
    }
    if ($signatureIndexes.Count -ne 1) {
        throw "Expected one p-code signature '$Signature', found $($signatureIndexes.Count)."
    }
    $methodIndex = -1
    for ($index = $signatureIndexes[0]; $index -lt $lines.Count; $index++) {
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

function Add-BeforeUniqueReturn([Collections.Generic.List[string]]$Lines, [string[]]$Addition) {
    $matches = @()
    for ($index = 0; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index].Trim() -eq 'returnvoid') { $matches += $index }
    }
    if ($matches.Count -ne 1) {
        throw "Expected one returnvoid in target method, found $($matches.Count)."
    }
    $Lines.InsertRange([int]$matches[0], $Addition)
}

function Add-AfterDisposedGuard([Collections.Generic.List[string]]$Lines, [string[]]$Addition) {
    $matches = @()
    for ($index = 0; $index -le $Lines.Count - 4; $index++) {
        $branch = [regex]::Match($Lines[$index + 1].Trim(), '^iffalse (?<label>[A-Za-z0-9_]+)$')
        if ($Lines[$index].Contains('getproperty QName(PrivateNamespace(null,') -and
            $Lines[$index].Contains('"_isDisposed")') -and $branch.Success -and
            $Lines[$index + 2].Trim() -eq 'returnvoid' -and
            $Lines[$index + 3].Trim() -ceq ($branch.Groups['label'].Value + ':')) {
            $matches += $index + 4
        }
    }
    if ($matches.Count -ne 1) {
        throw "Expected one _isDisposed guard in target method, found $($matches.Count)."
    }
    $Lines.InsertRange([int]$matches[0], $Addition)
}

function Add-BeforeLastReturn([Collections.Generic.List[string]]$Lines, [string[]]$Addition) {
    $matches = @()
    for ($index = 0; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index].Trim() -eq 'returnvoid') { $matches += $index }
    }
    if ($matches.Count -lt 1) {
        throw 'Target method has no returnvoid.'
    }
    $Lines.InsertRange([int]$matches[-1], $Addition)
}

function Add-AfterInitialScope([Collections.Generic.List[string]]$Lines, [string[]]$Addition) {
    $matches = @()
    for ($index = 0; $index -lt $Lines.Count - 1; $index++) {
        if ($Lines[$index].Trim() -eq 'getlocal0' -and $Lines[$index + 1].Trim() -eq 'pushscope') {
            $matches += $index + 2
        }
    }
    if ($matches.Count -ne 1) {
        throw "Expected one initial getlocal0/pushscope sequence, found $($matches.Count)."
    }
    $Lines.InsertRange([int]$matches[0], $Addition)
}

function Add-BeforeUniqueInstruction(
    [Collections.Generic.List[string]]$Lines,
    [string]$Instruction,
    [string[]]$Addition) {
    $matches = @()
    for ($index = 0; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index].Trim() -ceq $Instruction) { $matches += $index }
    }
    if ($matches.Count -ne 1) {
        throw "Expected one instruction '$Instruction', found $($matches.Count)."
    }
    $Lines.InsertRange([int]$matches[0], $Addition)
}

function Add-AfterUniqueInstruction(
    [Collections.Generic.List[string]]$Lines,
    [string]$Instruction,
    [string[]]$Addition) {
    $matches = @()
    for ($index = 0; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index].Trim() -ceq $Instruction) { $matches += $index }
    }
    if ($matches.Count -ne 1) {
        throw "Expected one instruction '$Instruction', found $($matches.Count)."
    }
    $Lines.InsertRange([int]$matches[0] + 1, $Addition)
}

function Get-PrivatePropertyOperand([Collections.Generic.List[string]]$Lines, [string]$PropertyName) {
    $escaped = [regex]::Escape($PropertyName)
    $operands = @()
    foreach ($line in $Lines) {
        $match = [regex]::Match(
            $line.Trim(),
            '^(?:get|set|init)property (?<operand>QName\(PrivateNamespace\(.+\),"' + $escaped + '"\))$')
        if ($match.Success -and $operands -cnotcontains $match.Groups['operand'].Value) {
            $operands += $match.Groups['operand'].Value
        }
    }
    if ($operands.Count -ne 1) {
        throw "Expected one private namespace operand for '$PropertyName', found $($operands.Count)."
    }
    return $operands[0]
}

function Set-MinimumLocalCount([Collections.Generic.List[string]]$Lines, [int]$Minimum) {
    $matches = @()
    for ($index = 0; $index -lt $Lines.Count; $index++) {
        $match = [regex]::Match($Lines[$index], '^(?<indent>\s*)localcount (?<count>\d+)\s*$')
        if ($match.Success) { $matches += [pscustomobject]@{ Index = $index; Match = $match } }
    }
    if ($matches.Count -ne 1) { throw "Expected one localcount, found $($matches.Count)." }
    if ([int]$matches[0].Match.Groups['count'].Value -lt $Minimum) {
        $Lines[$matches[0].Index] = $matches[0].Match.Groups['indent'].Value + "localcount $Minimum"
    }
}

function Set-MinimumMaxStack([Collections.Generic.List[string]]$Lines, [int]$Minimum) {
    $matches = @()
    for ($index = 0; $index -lt $Lines.Count; $index++) {
        $match = [regex]::Match($Lines[$index], '^(?<indent>\s*)maxstack (?<count>\d+)\s*$')
        if ($match.Success) { $matches += [pscustomobject]@{ Index = $index; Match = $match } }
    }
    if ($matches.Count -ne 1) { throw "Expected one maxstack, found $($matches.Count)." }
    if ([int]$matches[0].Match.Groups['count'].Value -lt $Minimum) {
        $Lines[$matches[0].Index] = $matches[0].Match.Groups['indent'].Value + "maxstack $Minimum"
    }
}

function Apply-ConservativePreloadCompletion(
    [Collections.Generic.List[string]]$Lines,
    [string]$CallBackOperand,
    [string]$LoadQueueOperand,
    [string]$PreloadQueueOperand) {
    $startIndexes = @()
    for ($index = 0; $index -lt $Lines.Count - 3; $index++) {
        if ($Lines[$index].Trim() -eq 'getlocal0' -and
            $Lines[$index + 1].Trim() -ceq "getproperty $CallBackOperand" -and
            $Lines[$index + 2].Trim() -eq 'pushnull' -and
            $Lines[$index + 3].Trim().StartsWith('ifeq ')) {
            $startIndexes += $index
        }
    }
    $returns = @()
    for ($index = 0; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index].Trim() -eq 'returnvoid') { $returns += $index }
    }
    if ($startIndexes.Count -ne 1 -or $returns.Count -ne 1 -or $startIndexes[0] -ge $returns[0]) {
        throw 'PreLoadAssetsUtil.onLoadCompleted no longer matches its approved callback tail.'
    }
    Set-MinimumLocalCount $Lines 2
    $start = [int]$startIndexes[0]
    $end = [int]$returns[0]
    $Lines.RemoveRange($start, $end - $start)
    $Lines.InsertRange($start, [string[]]@(
        ' getlocal0',
        " getproperty $CallBackOperand",
        ' setlocal1',
        ' getlocal0',
        ' pushnull',
        " setproperty $CallBackOperand",
        ' getlocal0',
        ' pushnull',
        " setproperty $LoadQueueOperand",
        ' getlocal0',
        ' pushnull',
        " setproperty $PreloadQueueOperand",
        ' getlocal1',
        ' pushnull',
        ' ifeq aola_cleanup_done',
        ' getlocal1',
        ' callpropvoid QName(Namespace("http://adobe.com/AS3/2006/builtin"),"apply"), 0',
        'aola_cleanup_done:'
    ))
}

function Apply-ConservativePreloadDispose(
    [Collections.Generic.List[string]]$Lines,
    [string]$CallBackOperand) {
    $instanceInstruction = @($Lines | Where-Object {
        $_.Trim().StartsWith('findproperty QName(PrivateNamespace(null,') -and $_.Contains('"_instance")')
    })
    if ($instanceInstruction.Count -ne 1) {
        throw 'PreLoadAssetsUtil.dispose no longer has one singleton release instruction.'
    }
    Add-BeforeUniqueInstruction $Lines $instanceInstruction[0].Trim() @(
        ' getlocal0',
        ' pushnull',
        " setproperty $CallBackOperand"
    )
}

function Apply-ConservativeSkillEffectCompletion(
    [Collections.Generic.List[string]]$Lines,
    [string]$OnLoadedOperand) {
    $startIndexes = @()
    for ($index = 0; $index -lt $Lines.Count - 5; $index++) {
        if ($Lines[$index].Trim() -eq 'getlocal0' -and
            $Lines[$index + 1].Trim() -ceq "getproperty $OnLoadedOperand" -and
            $Lines[$index + 2].Trim() -eq 'pushnull' -and
            $Lines[$index + 3].Trim() -eq 'getlocal1' -and
            $Lines[$index + 4].Trim() -eq 'newarray 1' -and
            $Lines[$index + 5].Trim() -eq 'callpropvoid QName(Namespace("http://adobe.com/AS3/2006/builtin"),"apply"), 2') {
            $startIndexes += $index
        }
    }
    $returns = @()
    for ($index = 0; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index].Trim() -eq 'returnvoid') { $returns += $index }
    }
    if ($startIndexes.Count -ne 1 -or $returns.Count -ne 2 -or $startIndexes[0] -ge $returns[-1]) {
        throw 'SkillEffectLoader.applyGot no longer matches its approved callback tail.'
    }
    Set-MinimumLocalCount $Lines 3
    $start = [int]$startIndexes[0]
    $end = [int]$returns[-1]
    $Lines.RemoveRange($start, $end - $start)
    $Lines.InsertRange($start, [string[]]@(
        ' getlocal0',
        " getproperty $OnLoadedOperand",
        ' setlocal2',
        ' getlocal0',
        ' pushnull',
        " setproperty $OnLoadedOperand",
        ' getlocal2',
        ' pushnull',
        ' ifeq aola_skill_effect_done',
        ' getlocal2',
        ' pushnull',
        ' getlocal1',
        ' newarray 1',
        ' callpropvoid QName(Namespace("http://adobe.com/AS3/2006/builtin"),"apply"), 2',
        'aola_skill_effect_done:'
    ))
}

function Add-ConservativeSkillEffectDispose(
    [Collections.Generic.List[string]]$Lines,
    [string]$OnLoadedOperand,
    [string]$DomainOperand,
    [string]$IdOperand) {
    Add-BeforeUniqueReturn $Lines @(
        ' getlocal0',
        ' pushnull',
        " setproperty $OnLoadedOperand",
        ' getlocal0',
        ' pushnull',
        " setproperty $DomainOperand",
        ' getlocal0',
        ' pushbyte 0',
        " setproperty $IdOperand"
    )
}

function Normalize-Pcode([string[]]$Lines) {
    return (($Lines | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }) -join "`n")
}

function Assert-PcodeEquivalent([string[]]$Expected, [string[]]$Actual, [string]$Description) {
    $expectedLines = @($Expected | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
    $actualLines = @($Actual | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
    if ($expectedLines.Count -ne $actualLines.Count) {
        throw "$Description line count differs."
    }
    for ($index = 0; $index -lt $expectedLines.Count; $index++) {
        if ($expectedLines[$index] -ceq $actualLines[$index]) { continue }
        $expectedMatch = [regex]::Match($expectedLines[$index], '^newfunction (?<index>\d+)$')
        $actualMatch = [regex]::Match($actualLines[$index], '^newfunction (?<index>\d+)$')
        if ($expectedMatch.Success -and $actualMatch.Success -and
            [Math]::Abs([int]$expectedMatch.Groups['index'].Value - [int]$actualMatch.Groups['index'].Value) -eq 4) {
            continue
        }
        throw "$Description differs at normalized line $($index + 1): '$($expectedLines[$index])' versus '$($actualLines[$index])'."
    }
}

function Normalize-ControlFlowLines([string[]]$Lines) {
    $normalizedLines = @($Lines | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
    $labels = [Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
    foreach ($line in $normalizedLines) {
        foreach ($match in [regex]::Matches($line, '\b(?:ofs[0-9a-f]+|aola_[A-Za-z0-9_]+)\b')) {
            if (-not $labels.ContainsKey($match.Value)) {
                $labels.Add($match.Value, "<label$($labels.Count)>")
            }
        }
    }
    return @($normalizedLines | ForEach-Object {
        $line = $_
        foreach ($label in $labels.Keys) {
            $line = [regex]::Replace($line, "\b$([regex]::Escape($label))\b", $labels[$label])
        }
        $line
    })
}

function Assert-PatchedMethodEquivalent([string[]]$Expected, [string[]]$Actual, [string]$Description) {
    $expectedLines = @(Normalize-ControlFlowLines $Expected)
    $actualLines = @(Normalize-ControlFlowLines $Actual)
    if ($expectedLines.Count -ne $actualLines.Count) {
        throw "$Description line count differs."
    }
    for ($index = 0; $index -lt $expectedLines.Count; $index++) {
        if ($expectedLines[$index] -ceq $actualLines[$index]) { continue }
        $expectedMatch = [regex]::Match($expectedLines[$index], '^newfunction (?<index>\d+)$')
        $actualMatch = [regex]::Match($actualLines[$index], '^newfunction (?<index>\d+)$')
        if ($expectedMatch.Success -and $actualMatch.Success -and
            [Math]::Abs([int]$expectedMatch.Groups['index'].Value - [int]$actualMatch.Groups['index'].Value) -eq 4) {
            continue
        }
        throw "$Description differs at normalized line $($index + 1): '$($expectedLines[$index])' versus '$($actualLines[$index])'."
    }
}

function Get-PcodeWithoutMethods([string]$Path, [string[]]$Signatures) {
    $lines = [Collections.Generic.List[string]]::new([string[]](Get-Content -LiteralPath $Path))
    foreach ($signature in $Signatures) {
        $matches = @()
        for ($index = 0; $index -lt $lines.Count; $index++) {
            if ($lines[$index].Contains($signature)) { $matches += $index }
        }
        if ($matches.Count -ne 1) { throw "Target method '$signature' is not unique in $Path." }
        $endIndex = -1
        for ($index = $matches[0]; $index -lt $lines.Count; $index++) {
            if ($lines[$index].Trim() -eq 'end ; method') { $endIndex = $index; break }
        }
        if ($endIndex -lt 0) { throw "Target method '$signature' has no end marker in $Path." }
        $lines.RemoveRange([int]$matches[0], $endIndex - [int]$matches[0] + 1)
    }
    return [string[]]$lines
}

function Assert-PcodeTrees([string]$OfficialRoot, [string]$CandidateRoot) {
    $docRelative = 'scripts\mmo\petfightnew\DocPetFight.pcode'
    $approvedMethods = @{
        'scripts\mmo\petfightnew\PetFightService.pcode' = @('public function init()')
        'scripts\mmo\petfightnew\common\FightPanel.pcode' = @(
            'public function enableClick()', 'public function dispose()')
        'scripts\mmo\petfightnew\common\fightcontroller\UseSkill.pcode' = @(
            'public function handleUseSkill(', 'private function handleAnnalFeeEight(', 'private function handleMovie(',
            'private function getMuiltHitDecHpDelayFrame(', 'public function dispose()')
        'scripts\mmo\petfightnew\common\FightController.pcode' = @(
            'public function init(', 'public function startHandle(')
        'scripts\mmo\petfightnew\common\FightData.pcode' = @(
            'private function initDomain()', 'public function dispose()')
        'scripts\mmo\petfightnew\common\startmovie\StartMovie.pcode' = @(
            'public function StartMovie(', 'private function dispose()')
        'scripts\mmo\petfightnew\common\util\PreLoadAssetsUtil.pcode' = @(
            'public function loadAssets(', 'private function loadNext()', 'private function onLoadEnd(',
            'private function onLoadCompleted()', 'public function dispose()')
        'scripts\mmo\petfightnew\common\skilleffect\SkillEffectLoader.pcode' = @(
            'public function getEffect(', 'private function applyGot(', 'public function dispose()')
        'scripts\mmo\petfightnew\common\MCPetContainer.pcode' = @(
            'public function attack(', 'public function setNormal()', 'public function dispose()')
        'scripts\mmo\petfightnew\common\fightcontroller\SwitchPm.pcode' = @('private function showSwitchMc(')
        'scripts\mmo\petfightnew\common\fightcontroller\ChangePetView.pcode' = @(
            'private function onGotPet(', 'private function onPetChange(')
        'scripts\mmo\petfightnew\common\fightcontroller\BattlePmDying.pcode' = @('private function showPetDieEffect(')
        'scripts\mmo\petfightnew\common\fightcontroller\BattleNextTurn.pcode' = @('private function checkPlayMovie(')
        'scripts\mmo\petfightnew\common\SkillResultMovieHandler.pcode' = @(
            'private function showMultipleHit(', 'private function showIncMovie(', 'private function showReallyHit(',
            'private function showShieldHit(', 'private function showReallyShieldHit(', 'private function playStrongMovie(',
            'private function setNormalMovie(', 'private function playAllHitMovie(')
    }
    $officialFiles = @{}
    foreach ($file in Get-ChildItem -LiteralPath $OfficialRoot -Recurse -File -Filter '*.pcode') {
        $relative = $file.FullName.Substring([IO.Path]::GetFullPath($OfficialRoot).TrimEnd('\').Length + 1)
        $officialFiles[$relative] = $file.FullName
    }
    $candidateFiles = @{}
    foreach ($file in Get-ChildItem -LiteralPath $CandidateRoot -Recurse -File -Filter '*.pcode') {
        $relative = $file.FullName.Substring([IO.Path]::GetFullPath($CandidateRoot).TrimEnd('\').Length + 1)
        $candidateFiles[$relative] = $file.FullName
    }
    if ($officialFiles.Count -ne $candidateFiles.Count) {
        throw 'Official and candidate p-code file counts differ.'
    }
    foreach ($relative in $officialFiles.Keys) {
        if (-not $candidateFiles.ContainsKey($relative)) { throw "Candidate p-code is missing $relative." }
        if ($relative -ceq $docRelative -or $approvedMethods.ContainsKey($relative)) { continue }
        Assert-PcodeEquivalent (Get-Content -LiteralPath $officialFiles[$relative]) `
            (Get-Content -LiteralPath $candidateFiles[$relative]) `
            "Unexpected p-code difference outside the approved presentation classes: $relative"
    }

    foreach ($relative in $approvedMethods.Keys) {
        $candidateWithoutMethods = @(
            Get-PcodeWithoutMethods $candidateFiles[$relative] $approvedMethods[$relative] |
                Where-Object { $_.Trim() -cne 'import mmo.petfightnew.DocPetFight;' }
        )
        Assert-PcodeEquivalent `
            (Get-PcodeWithoutMethods $officialFiles[$relative] $approvedMethods[$relative]) `
            $candidateWithoutMethods `
            "$relative changed outside its approved methods."
    }
}

function Assert-CandidateMarkers([string]$Path) {
    $bytes = [IO.File]::ReadAllBytes($Path)
    $text = [Text.Encoding]::ASCII.GetString($bytes)
    foreach ($marker in $requiredMarkers) {
        if (-not $text.Contains($marker)) { throw "Candidate is missing marker: $marker" }
    }
    foreach ($marker in $forbiddenMarkers) {
        if ($text.Contains($marker)) { throw "Candidate contains rejected marker: $marker" }
    }
}

function Read-StrictManifest([string]$Path, [bool]$Production) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Manifest not found: $Path" }
    $arguments = @($helperPath, 'manifest', '--input', $Path)
    if ($Production) { $arguments += '--production' }
    $validatedJson = & python @arguments
    if ($LASTEXITCODE -ne 0) { throw "Manifest validation failed: $Path" }
    $expected = @(
        'schemaVersion', 'resourceVersion', 'officialUrl', 'officialZwsSha256',
        'candidateFile', 'candidateLength', 'candidateSha256', 'bridgeVersion', 'symbolClassSha256'
    )
    $document = (($validatedJson -join [Environment]::NewLine) | ConvertFrom-Json)
    $actual = @($document.PSObject.Properties.Name)
    if ($actual.Count -ne $expected.Count -or @($actual | Where-Object { $expected -notcontains $_ }).Count -ne 0) {
        throw 'Manifest fields do not match schema version 1.'
    }
    if ($document.schemaVersion -ne 1 -or $document.bridgeVersion -ne 5 -or
        [string]$document.resourceVersion -notmatch '^\d{1,32}$' -or
        [string]$document.candidateSha256 -notmatch '^[0-9a-f]{64}$' -or
        [string]$document.officialZwsSha256 -notmatch '^[0-9a-f]{64}$' -or
        [string]$document.symbolClassSha256 -notmatch '^[0-9a-f]{64}$' -or
        [int64]$document.candidateLength -lt 8 -or [int64]$document.candidateLength -gt $maximumSwfBytes) {
        throw 'Manifest values are invalid.'
    }
    $expectedUrl = "https://aola.100bt.com/play/pet/petfightnew~$($document.resourceVersion).swf"
    if ([string]$document.officialUrl -cne $expectedUrl) { throw 'Manifest officialUrl is not canonical.' }
    if ($Production -and
        [string]$document.candidateFile -cne 'petfightnew-battle-state-current.fws.swf' -and
        [string]$document.candidateFile -cne "petfightnew-battle-visual-$($document.resourceVersion).fws.swf") {
        throw 'Production manifest candidateFile is not an accepted filename.'
    }
    return $document
}

Assert-Tool $FFDecPath 'FFDec'
Assert-Tool $helperPath 'ABC/SWF helper'
Assert-Tool $bridgeTemplatePath 'DocPetFight bridge template'
Assert-Tool $presentationPatchBuilder 'battle-presentation patch builder'
if (-not (Get-Command python -ErrorAction SilentlyContinue)) { throw 'python was not found on PATH.' }

if ($Mode -eq 'Check') {
    $live = Get-LiveDescriptor
    $currentVersion = ''
    try { $currentVersion = [string](Read-StrictManifest $productionManifestPath $true).resourceVersion } catch { }
    [pscustomobject]@{
        status = if ($currentVersion -ceq $live.ResourceVersion) { 'Current' } else { 'UpdateRequired' }
        currentVersion = $currentVersion
        liveVersion = $live.ResourceVersion
        officialUrl = $live.OfficialUrl
        versionDataVersion = $live.VersionDataVersion
    } | ConvertTo-Json
    exit 0
}

if ($Mode -eq 'Prepare') {
    $live = Get-LiveDescriptor
    if (-not $EvidenceRoot) {
        $EvidenceRoot = Join-Path $repoRoot (
            'analysis\reverse-engineering\battle-bridge-{0}-{1}' -f (Get-Date -Format 'yyyyMMdd'), $live.ResourceVersion)
    }
    $EvidenceRoot = Assert-Within (Join-Path $repoRoot 'analysis\reverse-engineering') $EvidenceRoot
    foreach ($relative in @('source', 'metadata', 'decompiled\official', 'decompiled\candidate',
        'decompiled\pcode-official', 'decompiled\pcode-candidate', 'exports\official-pcode',
        'exports\patches', 'evidence', 'variants')) {
        New-Item -ItemType Directory -Force -Path (Join-Path $EvidenceRoot $relative) | Out-Null
    }
    $live = Get-LiveDescriptor $EvidenceRoot

    $downloadPath = Join-Path $EvidenceRoot ('evidence\download-' + [Guid]::NewGuid().ToString('N') + '.swf')
    Invoke-WebRequest -UseBasicParsing -Uri $live.OfficialUrl -OutFile $downloadPath
    $officialDetails = Get-SwfDetails $downloadPath
    if ($officialDetails.signature -notin @('FWS', 'CWS', 'ZWS') -or -not $officialDetails.lengthValid) {
        throw 'The downloaded official petfightnew SWF is invalid.'
    }
    $officialPath = Join-Path $EvidenceRoot "source\petfightnew~$($live.ResourceVersion).swf"
    Copy-EvidenceFile $downloadPath $officialPath
    Remove-Item -LiteralPath $downloadPath -Force

    $originalFws = Join-Path $EvidenceRoot "variants\petfightnew-$($live.ResourceVersion)-original.fws.swf"
    if (-not (Test-Path -LiteralPath $originalFws)) {
        Invoke-Checked 'python' @($helperPath, 'unpack', '--input', $officialPath, '--output', $originalFws) 'SWF unpack'
    }
    $fwsDetails = Assert-Fws $originalFws ([string]$officialDetails.fwsSha256)

    $officialDecompile = Join-Path $EvidenceRoot 'decompiled\official'
    $docPath = Join-Path $officialDecompile 'scripts\mmo\petfightnew\DocPetFight.as'
    $serviceAsPath = Join-Path $officialDecompile 'scripts\mmo\petfightnew\PetFightService.as'
    $panelAsPath = Join-Path $officialDecompile 'scripts\mmo\petfightnew\common\FightPanel.as'
    $officialSymbols = Join-Path $officialDecompile 'symbolClass\symbols.csv'
    if (-not (Test-Path -LiteralPath $docPath) -or -not (Test-Path -LiteralPath $officialSymbols)) {
        Invoke-Checked $FFDecPath @(
            '-onerror', 'ignore', '-export', 'script,symbolClass', $officialDecompile, $originalFws
        ) 'official script and SymbolClass export'
    }
    foreach ($required in @($docPath, $serviceAsPath, $panelAsPath, $officialSymbols)) {
        if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Required FFDec export is missing: $required" }
    }
    $docSource = Get-Content -LiteralPath $docPath -Raw
    $embedMatches = [regex]::Matches($docSource, 'symbol="(?<symbol>symbol\d+)"')
    if ($embedMatches.Count -ne 1 -or
        $docSource -notmatch 'public class DocPetFight extends Sprite' -or
        $docSource -match 'ExternalInterface' -or
        [regex]::Matches($docSource, '\bfunction\s+').Count -ne 2 -or
        $docSource -notmatch 'public function DocPetFight\(\)' -or
        $docSource -notmatch 'private function compileMe\(\)' -or
        $docSource -notmatch 'var\s+\w+\s*:\s*PetFightService\s*=\s*null') {
        throw 'DocPetFight no longer matches the approved trivial document-class contract.'
    }
    if ((Get-Content -LiteralPath $serviceAsPath -Raw) -notmatch 'FightData\.instance\.battleId\s*=\s*param1\.params\.br') {
        throw 'PetFightService no longer assigns the battle route ID from params.br.'
    }

    $selectedPcode = Join-Path $EvidenceRoot 'exports\official-pcode'
    $servicePcodePath = Join-Path $selectedPcode 'scripts\mmo\petfightnew\PetFightService.pcode'
    $panelPcodePath = Join-Path $selectedPcode 'scripts\mmo\petfightnew\common\FightPanel.pcode'
    $controllerPcodePath = Join-Path $selectedPcode 'scripts\mmo\petfightnew\common\FightController.pcode'
    $fightDataPcodePath = Join-Path $selectedPcode 'scripts\mmo\petfightnew\common\FightData.pcode'
    $startMoviePcodePath = Join-Path $selectedPcode 'scripts\mmo\petfightnew\common\startmovie\StartMovie.pcode'
    $preloadPcodePath = Join-Path $selectedPcode 'scripts\mmo\petfightnew\common\util\PreLoadAssetsUtil.pcode'
    $skillEffectLoaderPcodePath = Join-Path $selectedPcode 'scripts\mmo\petfightnew\common\skilleffect\SkillEffectLoader.pcode'
    $useSkillPcodePath = Join-Path $selectedPcode 'scripts\mmo\petfightnew\common\fightcontroller\UseSkill.pcode'
    $petContainerPcodePath = Join-Path $selectedPcode 'scripts\mmo\petfightnew\common\MCPetContainer.pcode'
    $selectedPcodePaths = @(
        $servicePcodePath, $panelPcodePath, $controllerPcodePath, $fightDataPcodePath,
        $startMoviePcodePath, $preloadPcodePath, $skillEffectLoaderPcodePath,
        $useSkillPcodePath, $petContainerPcodePath)
    if (@($selectedPcodePaths | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) }).Count -gt 0) {
        $selectedClasses = @(
            'mmo.petfightnew.PetFightService',
            'mmo.petfightnew.common.FightPanel',
            'mmo.petfightnew.common.FightController',
            'mmo.petfightnew.common.FightData',
            'mmo.petfightnew.common.startmovie.StartMovie',
            'mmo.petfightnew.common.util.PreLoadAssetsUtil',
            'mmo.petfightnew.common.skilleffect.SkillEffectLoader',
            'mmo.petfightnew.common.MCPetContainer',
            'mmo.petfightnew.DocPetFight',
            'mmo.petfightnew.common.fightcontroller.UseSkill',
            'mmo.petfightnew.common.fightcontroller.SwitchPm',
            'mmo.petfightnew.common.fightcontroller.ChangePetView',
            'mmo.petfightnew.common.fightcontroller.BattlePmDying',
            'mmo.petfightnew.common.fightcontroller.BattleNextTurn',
            'mmo.petfightnew.common.SkillResultMovieHandler'
        ) -join ','
        Invoke-Checked $FFDecPath @(
            '-onerror', 'abort', '-format', 'script:pcode', '-selectclass',
            $selectedClasses,
            '-export', 'script', $selectedPcode, $originalFws
        ) 'selected official p-code export'
    }

    $methodOutput = & python $helperPath methods --input $originalFws `
        --target 'mmo.petfightnew.PetFightService:init' `
        --target 'mmo.petfightnew.common.FightPanel:enableClick' `
        --target 'mmo.petfightnew.common.FightPanel:dispose' `
        --target 'mmo.petfightnew.common.FightController:init' `
        --target 'mmo.petfightnew.common.FightData:initDomain' `
        --target 'mmo.petfightnew.common.FightData:dispose' `
        --target 'mmo.petfightnew.common.startmovie.StartMovie:$iinit' `
        --target 'mmo.petfightnew.common.startmovie.StartMovie:dispose' `
        --target 'mmo.petfightnew.common.util.PreLoadAssetsUtil:loadAssets' `
        --target 'mmo.petfightnew.common.util.PreLoadAssetsUtil:loadNext' `
        --target 'mmo.petfightnew.common.util.PreLoadAssetsUtil:onLoadEnd' `
        --target 'mmo.petfightnew.common.util.PreLoadAssetsUtil:onLoadCompleted' `
        --target 'mmo.petfightnew.common.util.PreLoadAssetsUtil:dispose' `
        --target 'mmo.petfightnew.common.skilleffect.SkillEffectLoader:getEffect' `
        --target 'mmo.petfightnew.common.skilleffect.SkillEffectLoader:applyGot' `
        --target 'mmo.petfightnew.common.skilleffect.SkillEffectLoader:dispose' `
        --target 'mmo.petfightnew.common.fightcontroller.UseSkill:dispose' `
        --target 'mmo.petfightnew.common.MCPetContainer:attack' `
        --target 'mmo.petfightnew.common.MCPetContainer:setNormal' `
        --target 'mmo.petfightnew.common.MCPetContainer:dispose'
    if ($LASTEXITCODE -ne 0) { throw 'Method-body index discovery failed.' }
    $methodBodies = (($methodOutput -join [Environment]::NewLine) | ConvertFrom-Json)
    $serviceBody = @($methodBodies | Where-Object { $_.className -ceq 'mmo.petfightnew.PetFightService' })[0]
    $panelBody = @($methodBodies | Where-Object { $_.className -ceq 'mmo.petfightnew.common.FightPanel' -and $_.methodName -ceq 'enableClick' })[0]
    $panelDisposeBody = @($methodBodies | Where-Object { $_.className -ceq 'mmo.petfightnew.common.FightPanel' -and $_.methodName -ceq 'dispose' })[0]
    $controllerBody = @($methodBodies | Where-Object { $_.className -ceq 'mmo.petfightnew.common.FightController' -and $_.methodName -ceq 'init' })[0]
    $fightDataInitBody = @($methodBodies | Where-Object { $_.className -ceq 'mmo.petfightnew.common.FightData' -and $_.methodName -ceq 'initDomain' })[0]
    $fightDataDisposeBody = @($methodBodies | Where-Object { $_.className -ceq 'mmo.petfightnew.common.FightData' -and $_.methodName -ceq 'dispose' })[0]
    $startMovieConstructorBody = @($methodBodies | Where-Object { $_.className -ceq 'mmo.petfightnew.common.startmovie.StartMovie' -and $_.methodName -ceq '$iinit' })[0]
    $startMovieDisposeBody = @($methodBodies | Where-Object { $_.className -ceq 'mmo.petfightnew.common.startmovie.StartMovie' -and $_.methodName -ceq 'dispose' })[0]
    $preloadLoadAssetsBody = @($methodBodies | Where-Object { $_.className -ceq 'mmo.petfightnew.common.util.PreLoadAssetsUtil' -and $_.methodName -ceq 'loadAssets' })[0]
    $preloadLoadNextBody = @($methodBodies | Where-Object { $_.className -ceq 'mmo.petfightnew.common.util.PreLoadAssetsUtil' -and $_.methodName -ceq 'loadNext' })[0]
    $preloadLoadEndBody = @($methodBodies | Where-Object { $_.className -ceq 'mmo.petfightnew.common.util.PreLoadAssetsUtil' -and $_.methodName -ceq 'onLoadEnd' })[0]
    $preloadCompletedBody = @($methodBodies | Where-Object { $_.className -ceq 'mmo.petfightnew.common.util.PreLoadAssetsUtil' -and $_.methodName -ceq 'onLoadCompleted' })[0]
    $preloadDisposeBody = @($methodBodies | Where-Object { $_.className -ceq 'mmo.petfightnew.common.util.PreLoadAssetsUtil' -and $_.methodName -ceq 'dispose' })[0]
    $skillEffectGetBody = @($methodBodies | Where-Object { $_.className -ceq 'mmo.petfightnew.common.skilleffect.SkillEffectLoader' -and $_.methodName -ceq 'getEffect' })[0]
    $skillEffectApplyBody = @($methodBodies | Where-Object { $_.className -ceq 'mmo.petfightnew.common.skilleffect.SkillEffectLoader' -and $_.methodName -ceq 'applyGot' })[0]
    $skillEffectDisposeBody = @($methodBodies | Where-Object { $_.className -ceq 'mmo.petfightnew.common.skilleffect.SkillEffectLoader' -and $_.methodName -ceq 'dispose' })[0]
    $useSkillDisposeBody = @($methodBodies | Where-Object { $_.className -ceq 'mmo.petfightnew.common.fightcontroller.UseSkill' -and $_.methodName -ceq 'dispose' })[0]
    $petAttackBody = @($methodBodies | Where-Object { $_.className -ceq 'mmo.petfightnew.common.MCPetContainer' -and $_.methodName -ceq 'attack' })[0]
    $petSetNormalBody = @($methodBodies | Where-Object { $_.className -ceq 'mmo.petfightnew.common.MCPetContainer' -and $_.methodName -ceq 'setNormal' })[0]
    $petDisposeBody = @($methodBodies | Where-Object { $_.className -ceq 'mmo.petfightnew.common.MCPetContainer' -and $_.methodName -ceq 'dispose' })[0]

    $serviceFragment = Get-MethodFragment $servicePcodePath 'public function init()'
    Add-BeforeUniqueReturn $serviceFragment @(
        ' getlex QName(PackageNamespace("mmo.petfightnew"),"DocPetFight")',
        ' callpropvoid QName(PackageNamespace(""),"ensureAolaBattleBridge"), 0'
    )
    $panelFragment = Get-MethodFragment $panelPcodePath 'public function enableClick()'
    Add-BeforeUniqueReturn $panelFragment @(
        ' getlex QName(PackageNamespace("mmo.petfightnew"),"DocPetFight")',
        ' callpropvoid QName(PackageNamespace(""),"noteInputReady"), 0'
    )
    $panelDisposeFragment = Get-MethodFragment $panelPcodePath 'public function dispose()'
    Add-AfterDisposedGuard $panelDisposeFragment @(
        ' getlex QName(PackageNamespace("mmo.petfightnew"),"DocPetFight")',
        ' getlocal0',
        ' callpropvoid QName(PackageNamespace(""),"noteDiagnosticPanelDisposeStarted"), 1'
    )
    Add-BeforeLastReturn $panelDisposeFragment @(
        ' getlex QName(PackageNamespace("mmo.petfightnew"),"DocPetFight")',
        ' getlocal0',
        ' callpropvoid QName(PackageNamespace(""),"noteDiagnosticPanelDisposed"), 1'
    )
    $controllerFragment = Get-MethodFragment $controllerPcodePath 'public function init('
    Add-BeforeUniqueReturn $controllerFragment @(
        ' getlex QName(PackageNamespace("mmo.petfightnew"),"DocPetFight")',
        ' getlocal1',
        ' callpropvoid QName(PackageNamespace(""),"noteDiagnosticPanel"), 1'
    )
    $fightDataPcodeLines = [Collections.Generic.List[string]]::new([string[]](Get-Content -LiteralPath $fightDataPcodePath))
    $fightDomainOperand = Get-PrivatePropertyOperand $fightDataPcodeLines '_domain'
    $fightDataInitFragment = Get-MethodFragment $fightDataPcodePath 'private function initDomain()'
    Add-BeforeUniqueReturn $fightDataInitFragment @(
        ' getlex QName(PackageNamespace("mmo.petfightnew"),"DocPetFight")',
        ' getlocal0',
        " getproperty $fightDomainOperand",
        ' callpropvoid QName(PackageNamespace(""),"noteDiagnosticApplicationDomain"), 1'
    )
    $fightDataDisposeFragment = Get-MethodFragment $fightDataPcodePath 'public function dispose()'
    Add-AfterInitialScope $fightDataDisposeFragment @(
        ' getlex QName(PackageNamespace("mmo.petfightnew"),"DocPetFight")',
        ' getlocal0',
        " getproperty $fightDomainOperand",
        ' callpropvoid QName(PackageNamespace(""),"noteDiagnosticApplicationDomainReleased"), 1'
    )
    $startMovieConstructorFragment = Get-MethodFragment $startMoviePcodePath 'public function StartMovie('
    Add-BeforeUniqueReturn $startMovieConstructorFragment @(
        ' getlex QName(PackageNamespace("mmo.petfightnew"),"DocPetFight")',
        ' getlocal0',
        ' callpropvoid QName(PackageNamespace(""),"noteDiagnosticStartMovie"), 1'
    )
    $startMovieDisposeFragment = Get-MethodFragment $startMoviePcodePath 'private function dispose()'
    Add-BeforeUniqueReturn $startMovieDisposeFragment @(
        ' getlex QName(PackageNamespace("mmo.petfightnew"),"DocPetFight")',
        ' getlocal0',
        ' callpropvoid QName(PackageNamespace(""),"noteDiagnosticStartMovieDisposed"), 1'
    )
    $preloadPcodeLines = [Collections.Generic.List[string]]::new([string[]](Get-Content -LiteralPath $preloadPcodePath))
    $preloadCallBackOperand = Get-PrivatePropertyOperand $preloadPcodeLines 'callBack'
    $preloadLoadQueueOperand = Get-PrivatePropertyOperand $preloadPcodeLines 'loadQueue'
    $preloadQueueOperand = Get-PrivatePropertyOperand $preloadPcodeLines '_preloadQueue'
    $preloadLoadAssetsFragment = Get-MethodFragment $preloadPcodePath 'public function loadAssets('
    Add-AfterInitialScope $preloadLoadAssetsFragment @(
        ' getlex QName(PackageNamespace("mmo.petfightnew"),"DocPetFight")',
        ' getlocal0',
        ' callpropvoid QName(PackageNamespace(""),"noteDiagnosticPreloadStarted"), 1'
    )
    $preloadLoadNextFragment = Get-MethodFragment $preloadPcodePath 'private function loadNext()'
    Add-BeforeUniqueInstruction $preloadLoadNextFragment `
        'getlex QName(PackageNamespace("mmo.loader.scheduler"),"ResScheduler")' @(
            ' getlex QName(PackageNamespace("mmo.petfightnew"),"DocPetFight")',
            ' getlocal0',
            ' getlocal1',
            ' getlocal0',
            " getproperty $preloadLoadQueueOperand",
            ' getproperty QName(PackageNamespace(""),"length")',
            ' callpropvoid QName(PackageNamespace(""),"noteDiagnosticResourceStarted"), 3'
        )
    $preloadLoadEndFragment = Get-MethodFragment $preloadPcodePath 'private function onLoadEnd('
    Add-AfterInitialScope $preloadLoadEndFragment @(
        ' getlex QName(PackageNamespace("mmo.petfightnew"),"DocPetFight")',
        ' getlocal0',
        ' callpropvoid QName(PackageNamespace(""),"noteDiagnosticResourceEnded"), 1'
    )
    $preloadCompletedFragment = Get-MethodFragment $preloadPcodePath 'private function onLoadCompleted()'
    Add-AfterInitialScope $preloadCompletedFragment @(
        ' getlex QName(PackageNamespace("mmo.petfightnew"),"DocPetFight")',
        ' getlocal0',
        ' callpropvoid QName(PackageNamespace(""),"noteDiagnosticPreloadCompleted"), 1'
    )
    $preloadDisposeFragment = Get-MethodFragment $preloadPcodePath 'public function dispose()'
    Add-AfterInitialScope $preloadDisposeFragment @(
        ' getlex QName(PackageNamespace("mmo.petfightnew"),"DocPetFight")',
        ' getlocal0',
        ' callpropvoid QName(PackageNamespace(""),"noteDiagnosticPreloadDisposed"), 1'
    )
    if ($ResourceCleanupMode -ceq 'ConservativeCleanup') {
        Apply-ConservativePreloadCompletion `
            $preloadCompletedFragment $preloadCallBackOperand $preloadLoadQueueOperand $preloadQueueOperand
        Apply-ConservativePreloadDispose $preloadDisposeFragment $preloadCallBackOperand
    }
    $skillEffectPcodeLines = [Collections.Generic.List[string]]::new([string[]](Get-Content -LiteralPath $skillEffectLoaderPcodePath))
    $skillEffectIdOperand = Get-PrivatePropertyOperand $skillEffectPcodeLines '_id'
    $skillEffectOnLoadedOperand = Get-PrivatePropertyOperand $skillEffectPcodeLines '_onLoaded'
    $skillEffectDomainOperand = Get-PrivatePropertyOperand $skillEffectPcodeLines '_domain'
    $skillEffectDisposedOperand = Get-PrivatePropertyOperand $skillEffectPcodeLines '_isDisposed'
    $skillEffectGetFragment = Get-MethodFragment $skillEffectLoaderPcodePath 'public function getEffect('
    Add-AfterUniqueInstruction $skillEffectGetFragment "setproperty $skillEffectOnLoadedOperand" @(
        ' getlex QName(PackageNamespace("mmo.petfightnew"),"DocPetFight")',
        ' getlocal0',
        ' getlocal1',
        ' callpropvoid QName(PackageNamespace(""),"noteDiagnosticSkillEffectStarted"), 2'
    )
    $skillEffectApplyFragment = Get-MethodFragment $skillEffectLoaderPcodePath 'private function applyGot('
    Set-MinimumMaxStack $skillEffectApplyFragment 5
    Add-AfterInitialScope $skillEffectApplyFragment @(
        ' getlex QName(PackageNamespace("mmo.petfightnew"),"DocPetFight")',
        ' getlocal0',
        ' getlocal0',
        " getproperty $skillEffectIdOperand",
        ' getlocal1',
        ' pushnull',
        ' equals',
        ' not',
        ' getlocal0',
        " getproperty $skillEffectDisposedOperand",
        ' callpropvoid QName(PackageNamespace(""),"noteDiagnosticSkillEffectCallback"), 4'
    )
    $skillEffectDisposeFragment = Get-MethodFragment $skillEffectLoaderPcodePath 'public function dispose()'
    Set-MinimumMaxStack $skillEffectDisposeFragment 3
    Add-AfterInitialScope $skillEffectDisposeFragment @(
        ' getlex QName(PackageNamespace("mmo.petfightnew"),"DocPetFight")',
        ' getlocal0',
        ' getlocal0',
        " getproperty $skillEffectIdOperand",
        ' callpropvoid QName(PackageNamespace(""),"noteDiagnosticSkillEffectDisposed"), 2'
    )
    if ($ResourceCleanupMode -ceq 'ConservativeCleanup') {
        Apply-ConservativeSkillEffectCompletion $skillEffectApplyFragment $skillEffectOnLoadedOperand
        Add-ConservativeSkillEffectDispose `
            $skillEffectDisposeFragment $skillEffectOnLoadedOperand $skillEffectDomainOperand $skillEffectIdOperand
    }

    $useSkillPcodeLines = [Collections.Generic.List[string]]::new([string[]](Get-Content -LiteralPath $useSkillPcodePath))
    $useSkillLoaderOperand = Get-PrivatePropertyOperand $useSkillPcodeLines '_skillEffectLoader'
    $useSkillOnPlayReturnOperand = Get-PrivatePropertyOperand $useSkillPcodeLines 'onPlayReturn'
    $useSkillParamsOperand = Get-PrivatePropertyOperand $useSkillPcodeLines '_params'
    $useSkillDisposeFragment = Get-MethodFragment $useSkillPcodePath 'public function dispose()'
    if ($ResourceCleanupMode -ceq 'ConservativeCleanup') {
        $useSkillInstanceInstruction = @($useSkillDisposeFragment | Where-Object {
            $_.Trim().StartsWith('findproperty QName(PrivateNamespace(null,') -and $_.Contains('"_instance")')
        })
        if ($useSkillInstanceInstruction.Count -ne 1) {
            throw 'UseSkill.dispose no longer has one singleton release instruction.'
        }
        Add-BeforeUniqueInstruction $useSkillDisposeFragment $useSkillInstanceInstruction[0].Trim() @(
            ' getlocal0',
            ' pushnull',
            " setproperty $useSkillLoaderOperand",
            ' getlocal0',
            ' pushnull',
            " setproperty $useSkillOnPlayReturnOperand",
            ' getlocal0',
            ' pushnull',
            " setproperty $useSkillParamsOperand"
        )
    }

    $petContainerPcodeLines = [Collections.Generic.List[string]]::new([string[]](Get-Content -LiteralPath $petContainerPcodePath))
    $petIsAttackOperand = Get-PrivatePropertyOperand $petContainerPcodeLines '_isAttack'
    $petMovieStrategyOperand = Get-PrivatePropertyOperand $petContainerPcodeLines '_movieStrategy'
    $petOnAttackEndOperand = Get-PrivatePropertyOperand $petContainerPcodeLines 'onAttackEnd'
    $petSetVisibleOperand = Get-PrivatePropertyOperand $petContainerPcodeLines '_setPetVisible'
    $petAttackFragment = Get-MethodFragment $petContainerPcodePath 'public function attack('
    Set-MinimumMaxStack $petAttackFragment 5
    $petAttackStart = @()
    if ($ResourceCleanupMode -ceq 'ConservativeCleanup') {
        $petAttackStart += @(
            ' getlocal0',
            ' getlocal 6',
            " setproperty $petOnAttackEndOperand"
        )
    }
    $petAttackStart += @(
        ' getlex QName(PackageNamespace("mmo.petfightnew"),"DocPetFight")',
        ' getlocal0',
        ' getlocal1',
        ' getlocal0',
        " getproperty $petMovieStrategyOperand",
        ' pushnull',
        ' equals',
        ' callpropvoid QName(PackageNamespace(""),"noteDiagnosticAttackStarted"), 3'
    )
    Add-AfterUniqueInstruction $petAttackFragment "initproperty $petIsAttackOperand" ([string[]]$petAttackStart)
    $petSetNormalFragment = Get-MethodFragment $petContainerPcodePath 'public function setNormal()'
    Add-AfterInitialScope $petSetNormalFragment @(
        ' getlex QName(PackageNamespace("mmo.petfightnew"),"DocPetFight")',
        ' getlocal0',
        ' callpropvoid QName(PackageNamespace(""),"noteDiagnosticAttackEnded"), 1'
    )
    $petDisposeFragment = Get-MethodFragment $petContainerPcodePath 'public function dispose()'
    Add-AfterInitialScope $petDisposeFragment @(
        ' getlex QName(PackageNamespace("mmo.petfightnew"),"DocPetFight")',
        ' getlocal0',
        ' callpropvoid QName(PackageNamespace(""),"noteDiagnosticAttackDisposed"), 1'
    )
    if ($ResourceCleanupMode -ceq 'ConservativeCleanup') {
        Add-BeforeUniqueReturn $petDisposeFragment @(
            ' getlocal0',
            ' pushnull',
            " setproperty $petOnAttackEndOperand",
            ' getlocal0',
            ' pushnull',
            " setproperty $petSetVisibleOperand"
        )
    }
    $servicePatch = Join-Path $EvidenceRoot 'exports\patches\PetFightService.init.pcode'
    $panelPatch = Join-Path $EvidenceRoot 'exports\patches\FightPanel.enableClick.pcode'
    $panelDisposePatch = Join-Path $EvidenceRoot 'exports\patches\FightPanel.dispose.pcode'
    $controllerPatch = Join-Path $EvidenceRoot 'exports\patches\FightController.init.pcode'
    $fightDataInitPatch = Join-Path $EvidenceRoot 'exports\patches\FightData.initDomain.pcode'
    $fightDataDisposePatch = Join-Path $EvidenceRoot 'exports\patches\FightData.dispose.pcode'
    $startMovieConstructorPatch = Join-Path $EvidenceRoot 'exports\patches\StartMovie.constructor.pcode'
    $startMovieDisposePatch = Join-Path $EvidenceRoot 'exports\patches\StartMovie.dispose.pcode'
    $preloadLoadAssetsPatch = Join-Path $EvidenceRoot 'exports\patches\PreLoadAssetsUtil.loadAssets.pcode'
    $preloadLoadNextPatch = Join-Path $EvidenceRoot 'exports\patches\PreLoadAssetsUtil.loadNext.pcode'
    $preloadLoadEndPatch = Join-Path $EvidenceRoot 'exports\patches\PreLoadAssetsUtil.onLoadEnd.pcode'
    $preloadCompletedPatch = Join-Path $EvidenceRoot 'exports\patches\PreLoadAssetsUtil.onLoadCompleted.pcode'
    $preloadDisposePatch = Join-Path $EvidenceRoot 'exports\patches\PreLoadAssetsUtil.dispose.pcode'
    $skillEffectGetPatch = Join-Path $EvidenceRoot 'exports\patches\SkillEffectLoader.getEffect.pcode'
    $skillEffectApplyPatch = Join-Path $EvidenceRoot 'exports\patches\SkillEffectLoader.applyGot.pcode'
    $skillEffectDisposePatch = Join-Path $EvidenceRoot 'exports\patches\SkillEffectLoader.dispose.pcode'
    $useSkillDisposePatch = Join-Path $EvidenceRoot 'exports\patches\UseSkill.dispose.pcode'
    $petAttackPatch = Join-Path $EvidenceRoot 'exports\patches\MCPetContainer.attack.pcode'
    $petSetNormalPatch = Join-Path $EvidenceRoot 'exports\patches\MCPetContainer.setNormal.pcode'
    $petDisposePatch = Join-Path $EvidenceRoot 'exports\patches\MCPetContainer.dispose.pcode'
    $generatedDoc = Join-Path $EvidenceRoot 'exports\patches\DocPetFight.as'
    Set-GeneratedText $servicePatch ([string[]]$serviceFragment)
    Set-GeneratedText $panelPatch ([string[]]$panelFragment)
    Set-GeneratedText $panelDisposePatch ([string[]]$panelDisposeFragment)
    Set-GeneratedText $controllerPatch ([string[]]$controllerFragment)
    Set-GeneratedText $fightDataInitPatch ([string[]]$fightDataInitFragment)
    Set-GeneratedText $fightDataDisposePatch ([string[]]$fightDataDisposeFragment)
    Set-GeneratedText $startMovieConstructorPatch ([string[]]$startMovieConstructorFragment)
    Set-GeneratedText $startMovieDisposePatch ([string[]]$startMovieDisposeFragment)
    Set-GeneratedText $preloadLoadAssetsPatch ([string[]]$preloadLoadAssetsFragment)
    Set-GeneratedText $preloadLoadNextPatch ([string[]]$preloadLoadNextFragment)
    Set-GeneratedText $preloadLoadEndPatch ([string[]]$preloadLoadEndFragment)
    Set-GeneratedText $preloadCompletedPatch ([string[]]$preloadCompletedFragment)
    Set-GeneratedText $preloadDisposePatch ([string[]]$preloadDisposeFragment)
    Set-GeneratedText $skillEffectGetPatch ([string[]]$skillEffectGetFragment)
    Set-GeneratedText $skillEffectApplyPatch ([string[]]$skillEffectApplyFragment)
    Set-GeneratedText $skillEffectDisposePatch ([string[]]$skillEffectDisposeFragment)
    Set-GeneratedText $useSkillDisposePatch ([string[]]$useSkillDisposeFragment)
    Set-GeneratedText $petAttackPatch ([string[]]$petAttackFragment)
    Set-GeneratedText $petSetNormalPatch ([string[]]$petSetNormalFragment)
    Set-GeneratedText $petDisposePatch ([string[]]$petDisposeFragment)
    $template = Get-Content -LiteralPath $bridgeTemplatePath -Raw
    if ([regex]::Matches($template, '__EMBED_SYMBOL__').Count -ne 1 -or
        [regex]::Matches($template, '__CONSERVATIVE_CLEANUP_ENABLED__').Count -ne 1) {
        throw 'Bridge template placeholders are invalid.'
    }
    $cleanupEnabled = if ($ResourceCleanupMode -ceq 'ConservativeCleanup') { 'true' } else { 'false' }
    $generatedSource = $template.Replace('__EMBED_SYMBOL__', $embedMatches[0].Groups['symbol'].Value).
        Replace('__CONSERVATIVE_CLEANUP_ENABLED__', $cleanupEnabled)
    Set-GeneratedText $generatedDoc @($generatedSource.TrimEnd("`r", "`n"))

    $presentationPatchRoot = Join-Path $EvidenceRoot 'exports\presentation-patches'
    $presentationOutput = & $presentationPatchBuilder `
        -PcodeRoot $selectedPcode `
        -OriginalFws $originalFws `
        -HelperPath $helperPath `
        -OutputDirectory $presentationPatchRoot
    if ($LASTEXITCODE -ne 0) { throw 'Battle-presentation patch generation failed.' }
    $presentationPatches = @(($presentationOutput -join [Environment]::NewLine) | ConvertFrom-Json)
    if ($presentationPatches.Count -ne 18) {
        throw "Expected 18 battle-presentation method patches, found $($presentationPatches.Count)."
    }

    $candidate = Join-Path $EvidenceRoot "variants\petfightnew-battle-state-$($live.ResourceVersion).fws.swf"
    if (-not (Test-Path -LiteralPath $candidate)) {
        $stages = @(
            [pscustomobject]@{
                className = 'mmo.petfightnew.PetFightService'
                methodName = 'init'
                signature = 'public function init()'
                methodBodyIndex = [int]$serviceBody.methodBodyIndex
                fragment = $servicePatch
            },
            [pscustomobject]@{
                className = 'mmo.petfightnew.common.FightPanel'
                methodName = 'enableClick'
                signature = 'public function enableClick()'
                methodBodyIndex = [int]$panelBody.methodBodyIndex
                fragment = $panelPatch
            },
            [pscustomobject]@{
                className = 'mmo.petfightnew.common.FightController'
                methodName = 'init'
                signature = 'public function init('
                methodBodyIndex = [int]$controllerBody.methodBodyIndex
                fragment = $controllerPatch
            },
            [pscustomobject]@{
                className = 'mmo.petfightnew.common.FightPanel'
                methodName = 'dispose'
                signature = 'public function dispose()'
                methodBodyIndex = [int]$panelDisposeBody.methodBodyIndex
                fragment = $panelDisposePatch
            },
            [pscustomobject]@{
                className = 'mmo.petfightnew.common.FightData'
                methodName = 'initDomain'
                signature = 'private function initDomain()'
                methodBodyIndex = [int]$fightDataInitBody.methodBodyIndex
                fragment = $fightDataInitPatch
            },
            [pscustomobject]@{
                className = 'mmo.petfightnew.common.FightData'
                methodName = 'dispose'
                signature = 'public function dispose()'
                methodBodyIndex = [int]$fightDataDisposeBody.methodBodyIndex
                fragment = $fightDataDisposePatch
            },
            [pscustomobject]@{
                className = 'mmo.petfightnew.common.startmovie.StartMovie'
                methodName = 'StartMovie'
                signature = 'public function StartMovie('
                methodBodyIndex = [int]$startMovieConstructorBody.methodBodyIndex
                fragment = $startMovieConstructorPatch
            },
            [pscustomobject]@{
                className = 'mmo.petfightnew.common.startmovie.StartMovie'
                methodName = 'dispose'
                signature = 'private function dispose()'
                methodBodyIndex = [int]$startMovieDisposeBody.methodBodyIndex
                fragment = $startMovieDisposePatch
            },
            [pscustomobject]@{
                className = 'mmo.petfightnew.common.util.PreLoadAssetsUtil'
                methodName = 'loadAssets'
                signature = 'public function loadAssets('
                methodBodyIndex = [int]$preloadLoadAssetsBody.methodBodyIndex
                fragment = $preloadLoadAssetsPatch
            },
            [pscustomobject]@{
                className = 'mmo.petfightnew.common.util.PreLoadAssetsUtil'
                methodName = 'loadNext'
                signature = 'private function loadNext()'
                methodBodyIndex = [int]$preloadLoadNextBody.methodBodyIndex
                fragment = $preloadLoadNextPatch
            },
            [pscustomobject]@{
                className = 'mmo.petfightnew.common.util.PreLoadAssetsUtil'
                methodName = 'onLoadEnd'
                signature = 'private function onLoadEnd('
                methodBodyIndex = [int]$preloadLoadEndBody.methodBodyIndex
                fragment = $preloadLoadEndPatch
            },
            [pscustomobject]@{
                className = 'mmo.petfightnew.common.util.PreLoadAssetsUtil'
                methodName = 'onLoadCompleted'
                signature = 'private function onLoadCompleted()'
                methodBodyIndex = [int]$preloadCompletedBody.methodBodyIndex
                fragment = $preloadCompletedPatch
            },
            [pscustomobject]@{
                className = 'mmo.petfightnew.common.util.PreLoadAssetsUtil'
                methodName = 'dispose'
                signature = 'public function dispose()'
                methodBodyIndex = [int]$preloadDisposeBody.methodBodyIndex
                fragment = $preloadDisposePatch
            }
        )
        $lifecycleStages = @(
            [pscustomobject]@{
                className = 'mmo.petfightnew.common.skilleffect.SkillEffectLoader'
                methodName = 'getEffect'
                signature = 'public function getEffect('
                methodBodyIndex = [int]$skillEffectGetBody.methodBodyIndex
                fragment = $skillEffectGetPatch
            },
            [pscustomobject]@{
                className = 'mmo.petfightnew.common.skilleffect.SkillEffectLoader'
                methodName = 'applyGot'
                signature = 'private function applyGot('
                methodBodyIndex = [int]$skillEffectApplyBody.methodBodyIndex
                fragment = $skillEffectApplyPatch
            },
            [pscustomobject]@{
                className = 'mmo.petfightnew.common.skilleffect.SkillEffectLoader'
                methodName = 'dispose'
                signature = 'public function dispose()'
                methodBodyIndex = [int]$skillEffectDisposeBody.methodBodyIndex
                fragment = $skillEffectDisposePatch
            },
            [pscustomobject]@{
                className = 'mmo.petfightnew.common.MCPetContainer'
                methodName = 'attack'
                signature = 'public function attack('
                methodBodyIndex = [int]$petAttackBody.methodBodyIndex
                fragment = $petAttackPatch
            },
            [pscustomobject]@{
                className = 'mmo.petfightnew.common.MCPetContainer'
                methodName = 'setNormal'
                signature = 'public function setNormal()'
                methodBodyIndex = [int]$petSetNormalBody.methodBodyIndex
                fragment = $petSetNormalPatch
            },
            [pscustomobject]@{
                className = 'mmo.petfightnew.common.MCPetContainer'
                methodName = 'dispose'
                signature = 'public function dispose()'
                methodBodyIndex = [int]$petDisposeBody.methodBodyIndex
                fragment = $petDisposePatch
            }
        )
        if ($ResourceCleanupMode -ceq 'ConservativeCleanup') {
            $lifecycleStages += [pscustomobject]@{
                className = 'mmo.petfightnew.common.fightcontroller.UseSkill'
                methodName = 'dispose'
                signature = 'public function dispose()'
                methodBodyIndex = [int]$useSkillDisposeBody.methodBodyIndex
                fragment = $useSkillDisposePatch
            }
        }
        $stages = @($stages + $lifecycleStages + $presentationPatches)
        $currentStage = $originalFws
        for ($stageIndex = 0; $stageIndex -lt $stages.Count; $stageIndex++) {
            $stage = $stages[$stageIndex]
            $nextStage = Join-Path $EvidenceRoot ("variants\battle-presentation-stage-{0}.fws.swf" -f ($stageIndex + 1))
            if (Test-Path -LiteralPath $nextStage) {
                throw "Partial candidate output exists; use a new evidence directory: $nextStage"
            }
            Invoke-Checked $FFDecPath @(
                '-onerror', 'ignore', '-replace', $currentStage, $nextStage,
                [string]$stage.className, [string]$stage.fragment, [string]$stage.methodBodyIndex
            ) "$($stage.className).$($stage.methodName) replacement"
            $currentStage = $nextStage
        }
        Invoke-Checked $FFDecPath @(
            '-onerror', 'ignore', '-replace', $currentStage, $candidate,
            'mmo.petfightnew.DocPetFight', $generatedDoc
        ) 'DocPetFight replacement'
    }
    $candidateDetails = Assert-Fws $candidate
    Assert-CandidateMarkers $candidate

    $candidateDecompile = Join-Path $EvidenceRoot 'decompiled\candidate'
    $candidateSymbols = Join-Path $candidateDecompile 'symbolClass\symbols.csv'
    if (-not (Test-Path -LiteralPath $candidateSymbols)) {
        Invoke-Checked $FFDecPath @(
            '-onerror', 'ignore', '-export', 'script,symbolClass', $candidateDecompile, $candidate
        ) 'candidate script and SymbolClass reread'
    }
    if (-not (Test-Path -LiteralPath $candidateSymbols)) { throw 'Candidate SymbolClass export is missing.' }
    $symbolClassSha256 = Get-Sha256 $officialSymbols
    if ((Get-Sha256 $candidateSymbols) -cne $symbolClassSha256) {
        throw 'Candidate SymbolClass mapping differs from the same-version official SWF.'
    }

    $officialPcodeRoot = Join-Path $EvidenceRoot 'decompiled\pcode-official'
    $candidatePcodeRoot = Join-Path $EvidenceRoot 'decompiled\pcode-candidate'
    if (@(Get-ChildItem -LiteralPath $officialPcodeRoot -Recurse -File -Filter '*.pcode').Count -eq 0) {
        Invoke-Checked $FFDecPath @(
            '-onerror', 'abort', '-format', 'script:pcode', '-export', 'script', $officialPcodeRoot, $originalFws
        ) 'full official p-code export'
    }
    if (@(Get-ChildItem -LiteralPath $candidatePcodeRoot -Recurse -File -Filter '*.pcode').Count -eq 0) {
        Invoke-Checked $FFDecPath @(
            '-onerror', 'abort', '-format', 'script:pcode', '-export', 'script', $candidatePcodeRoot, $candidate
        ) 'full candidate p-code export'
    }
    Assert-PcodeTrees $officialPcodeRoot $candidatePcodeRoot

    $candidateService = Get-MethodFragment (Join-Path $candidatePcodeRoot 'scripts\mmo\petfightnew\PetFightService.pcode') 'public function init()'
    $candidatePanel = Get-MethodFragment (Join-Path $candidatePcodeRoot 'scripts\mmo\petfightnew\common\FightPanel.pcode') 'public function enableClick()'
    $candidatePanelDispose = Get-MethodFragment (Join-Path $candidatePcodeRoot 'scripts\mmo\petfightnew\common\FightPanel.pcode') 'public function dispose()'
    $candidateController = Get-MethodFragment (Join-Path $candidatePcodeRoot 'scripts\mmo\petfightnew\common\FightController.pcode') 'public function init('
    $candidateFightDataInit = Get-MethodFragment (Join-Path $candidatePcodeRoot 'scripts\mmo\petfightnew\common\FightData.pcode') 'private function initDomain()'
    $candidateFightDataDispose = Get-MethodFragment (Join-Path $candidatePcodeRoot 'scripts\mmo\petfightnew\common\FightData.pcode') 'public function dispose()'
    $candidateStartMovieConstructor = Get-MethodFragment (Join-Path $candidatePcodeRoot 'scripts\mmo\petfightnew\common\startmovie\StartMovie.pcode') 'public function StartMovie('
    $candidateStartMovieDispose = Get-MethodFragment (Join-Path $candidatePcodeRoot 'scripts\mmo\petfightnew\common\startmovie\StartMovie.pcode') 'private function dispose()'
    $candidatePreloadLoadAssets = Get-MethodFragment (Join-Path $candidatePcodeRoot 'scripts\mmo\petfightnew\common\util\PreLoadAssetsUtil.pcode') 'public function loadAssets('
    $candidatePreloadLoadNext = Get-MethodFragment (Join-Path $candidatePcodeRoot 'scripts\mmo\petfightnew\common\util\PreLoadAssetsUtil.pcode') 'private function loadNext()'
    $candidatePreloadLoadEnd = Get-MethodFragment (Join-Path $candidatePcodeRoot 'scripts\mmo\petfightnew\common\util\PreLoadAssetsUtil.pcode') 'private function onLoadEnd('
    $candidatePreloadCompleted = Get-MethodFragment (Join-Path $candidatePcodeRoot 'scripts\mmo\petfightnew\common\util\PreLoadAssetsUtil.pcode') 'private function onLoadCompleted()'
    $candidatePreloadDispose = Get-MethodFragment (Join-Path $candidatePcodeRoot 'scripts\mmo\petfightnew\common\util\PreLoadAssetsUtil.pcode') 'public function dispose()'
    $candidateSkillEffectGet = Get-MethodFragment (Join-Path $candidatePcodeRoot 'scripts\mmo\petfightnew\common\skilleffect\SkillEffectLoader.pcode') 'public function getEffect('
    $candidateSkillEffectApply = Get-MethodFragment (Join-Path $candidatePcodeRoot 'scripts\mmo\petfightnew\common\skilleffect\SkillEffectLoader.pcode') 'private function applyGot('
    $candidateSkillEffectDispose = Get-MethodFragment (Join-Path $candidatePcodeRoot 'scripts\mmo\petfightnew\common\skilleffect\SkillEffectLoader.pcode') 'public function dispose()'
    $candidateUseSkillDispose = Get-MethodFragment (Join-Path $candidatePcodeRoot 'scripts\mmo\petfightnew\common\fightcontroller\UseSkill.pcode') 'public function dispose()'
    $candidatePetAttack = Get-MethodFragment (Join-Path $candidatePcodeRoot 'scripts\mmo\petfightnew\common\MCPetContainer.pcode') 'public function attack('
    $candidatePetSetNormal = Get-MethodFragment (Join-Path $candidatePcodeRoot 'scripts\mmo\petfightnew\common\MCPetContainer.pcode') 'public function setNormal()'
    $candidatePetDispose = Get-MethodFragment (Join-Path $candidatePcodeRoot 'scripts\mmo\petfightnew\common\MCPetContainer.pcode') 'public function dispose()'
    Assert-PatchedMethodEquivalent ([string[]]$serviceFragment) ([string[]]$candidateService) `
        'PetFightService.init reread does not match the generated patch.'
    Assert-PatchedMethodEquivalent ([string[]]$panelFragment) ([string[]]$candidatePanel) `
        'FightPanel.enableClick reread does not match the generated patch.'
    Assert-PatchedMethodEquivalent ([string[]]$panelDisposeFragment) ([string[]]$candidatePanelDispose) `
        'FightPanel.dispose reread does not match the generated patch.'
    Assert-PatchedMethodEquivalent ([string[]]$controllerFragment) ([string[]]$candidateController) `
        'FightController.init reread does not match the generated patch.'
    Assert-PatchedMethodEquivalent ([string[]]$fightDataInitFragment) ([string[]]$candidateFightDataInit) `
        'FightData.initDomain reread does not match the generated patch.'
    Assert-PatchedMethodEquivalent ([string[]]$fightDataDisposeFragment) ([string[]]$candidateFightDataDispose) `
        'FightData.dispose reread does not match the generated patch.'
    Assert-PatchedMethodEquivalent ([string[]]$startMovieConstructorFragment) ([string[]]$candidateStartMovieConstructor) `
        'StartMovie constructor reread does not match the generated patch.'
    Assert-PatchedMethodEquivalent ([string[]]$startMovieDisposeFragment) ([string[]]$candidateStartMovieDispose) `
        'StartMovie.dispose reread does not match the generated patch.'
    Assert-PatchedMethodEquivalent ([string[]]$preloadLoadAssetsFragment) ([string[]]$candidatePreloadLoadAssets) `
        'PreLoadAssetsUtil.loadAssets reread does not match the generated patch.'
    Assert-PatchedMethodEquivalent ([string[]]$preloadLoadNextFragment) ([string[]]$candidatePreloadLoadNext) `
        'PreLoadAssetsUtil.loadNext reread does not match the generated patch.'
    Assert-PatchedMethodEquivalent ([string[]]$preloadLoadEndFragment) ([string[]]$candidatePreloadLoadEnd) `
        'PreLoadAssetsUtil.onLoadEnd reread does not match the generated patch.'
    Assert-PatchedMethodEquivalent ([string[]]$preloadCompletedFragment) ([string[]]$candidatePreloadCompleted) `
        'PreLoadAssetsUtil.onLoadCompleted reread does not match the generated patch.'
    Assert-PatchedMethodEquivalent ([string[]]$preloadDisposeFragment) ([string[]]$candidatePreloadDispose) `
        'PreLoadAssetsUtil.dispose reread does not match the generated patch.'
    Assert-PatchedMethodEquivalent ([string[]]$skillEffectGetFragment) ([string[]]$candidateSkillEffectGet) `
        'SkillEffectLoader.getEffect reread does not match the generated patch.'
    Assert-PatchedMethodEquivalent ([string[]]$skillEffectApplyFragment) ([string[]]$candidateSkillEffectApply) `
        'SkillEffectLoader.applyGot reread does not match the generated patch.'
    Assert-PatchedMethodEquivalent ([string[]]$skillEffectDisposeFragment) ([string[]]$candidateSkillEffectDispose) `
        'SkillEffectLoader.dispose reread does not match the generated patch.'
    Assert-PatchedMethodEquivalent ([string[]]$useSkillDisposeFragment) ([string[]]$candidateUseSkillDispose) `
        'UseSkill.dispose reread does not match the generated patch.'
    Assert-PatchedMethodEquivalent ([string[]]$petAttackFragment) ([string[]]$candidatePetAttack) `
        'MCPetContainer.attack reread does not match the generated patch.'
    Assert-PatchedMethodEquivalent ([string[]]$petSetNormalFragment) ([string[]]$candidatePetSetNormal) `
        'MCPetContainer.setNormal reread does not match the generated patch.'
    Assert-PatchedMethodEquivalent ([string[]]$petDisposeFragment) ([string[]]$candidatePetDispose) `
        'MCPetContainer.dispose reread does not match the generated patch.'
    foreach ($patch in $presentationPatches) {
        $relativeClass = ([string]$patch.className).Replace('.', '\') + '.pcode'
        $candidateMethod = Get-MethodFragment (Join-Path $candidatePcodeRoot ('scripts\' + $relativeClass)) ([string]$patch.signature)
        Assert-PatchedMethodEquivalent `
            (Get-Content -LiteralPath ([string]$patch.fragment)) `
            ([string[]]$candidateMethod) `
            "$($patch.className).$($patch.methodName) reread does not match the generated patch."
    }

    $candidateSha256 = [string]$candidateDetails.sha256
    $manifestPath = Join-Path $EvidenceRoot 'metadata\candidate-manifest.json'
    $manifest = [ordered]@{
        schemaVersion = 1
        resourceVersion = $live.ResourceVersion
        officialUrl = $live.OfficialUrl
        officialZwsSha256 = [string]$officialDetails.sha256
        candidateFile = "..\variants\$([IO.Path]::GetFileName($candidate))"
        candidateLength = [int64]$candidateDetails.fileSize
        candidateSha256 = $candidateSha256
        bridgeVersion = 5
        symbolClassSha256 = $symbolClassSha256
    }
    $manifest | ConvertTo-Json | Set-Content -LiteralPath $manifestPath -Encoding utf8
    $reportPath = Join-Path $EvidenceRoot 'metadata\compatibility-report.md'
    @(
        '# petfightnew battle-presentation bridge compatibility',
        '',
        "- Resource version: ``$($live.ResourceVersion)``",
        "- Official URL: ``$($live.OfficialUrl)``",
        "- Official ZWS SHA-256: ``$($officialDetails.sha256)``",
        "- Official FWS SHA-256: ``$($fwsDetails.sha256)``",
        "- Candidate SHA-256: ``$candidateSha256``",
        "- SymbolClass rows: ``$((Get-Content -LiteralPath $officialSymbols).Count)``",
        "- SymbolClass SHA-256: ``$symbolClassSha256``",
        "- PetFightService.init method body: ``$($serviceBody.methodBodyIndex)``",
        "- FightPanel.enableClick method body: ``$($panelBody.methodBodyIndex)``",
        "- FightPanel.dispose method body: ``$($panelDisposeBody.methodBodyIndex)``",
        "- FightController.init method body: ``$($controllerBody.methodBodyIndex)``",
        "- Resource cleanup mode: ``$ResourceCleanupMode``",
        "- FightData.initDomain/dispose method bodies: ``$($fightDataInitBody.methodBodyIndex)`` / ``$($fightDataDisposeBody.methodBodyIndex)``",
        "- StartMovie constructor/dispose method bodies: ``$($startMovieConstructorBody.methodBodyIndex)`` / ``$($startMovieDisposeBody.methodBodyIndex)``",
        "- PreLoadAssetsUtil method bodies: loadAssets ``$($preloadLoadAssetsBody.methodBodyIndex)``, loadNext ``$($preloadLoadNextBody.methodBodyIndex)``, onLoadEnd ``$($preloadLoadEndBody.methodBodyIndex)``, onLoadCompleted ``$($preloadCompletedBody.methodBodyIndex)``, dispose ``$($preloadDisposeBody.methodBodyIndex)``",
        "- SkillEffectLoader method bodies: getEffect ``$($skillEffectGetBody.methodBodyIndex)``, applyGot ``$($skillEffectApplyBody.methodBodyIndex)``, dispose ``$($skillEffectDisposeBody.methodBodyIndex)``",
        "- MCPetContainer method bodies: attack ``$($petAttackBody.methodBodyIndex)``, setNormal ``$($petSetNormalBody.methodBodyIndex)``, dispose ``$($petDisposeBody.methodBodyIndex)``",
        "- UseSkill.dispose method body: ``$($useSkillDisposeBody.methodBodyIndex)``",
        '- Changed scope: `DocPetFight`, the approved panel/domain/start-movie/preloader/skill-effect/attack lifecycle methods, and the existing per-turn presentation methods.',
        '- Diagnostics schema 4 adds weak skill-effect-loader and active-attack tracking to the existing lifecycle counters, 512-entry event ring, and frame-gap samples without adding a new GC call.',
        '- `DiagnosticOnly` changes observation only. `ConservativeCleanup` also clears callbacks after completion, clears the reusable skill loader domain only on disposal, releases `UseSkill` references, clears attack callbacks on pet disposal, and invokes the official `setNormal` completion path after an actual-time 15-second attack timeout.',
        '- Neither mode cancels `ResScheduler`, clears global caches, forces GC, unloads an application domain, or reloads Flash.',
        '- The presentation path preserves state settlement, message order, and terminal callbacks while bypassing per-turn movies and draining already-received events without one-frame gaps.',
        '- Multi-hit completion retains its callback path with a one-frame minimum delay while presentation skipping is enabled.',
        '- Damage and healing number suppression is limited to result-number leaf methods.',
        '- Static verification passed; real Flash runtime verification is still required.'
    ) | Set-Content -LiteralPath $reportPath -Encoding utf8

    [pscustomobject]@{
        status = 'Prepared'
        version = $live.ResourceVersion
        resourceCleanupMode = $ResourceCleanupMode
        candidate = $candidate
        candidateSha256 = $candidateSha256
        candidateManifest = $manifestPath
        compatibilityReport = $reportPath
    } | ConvertTo-Json
    exit 0
}

if (-not $CandidateManifest) { throw 'Promote requires -CandidateManifest with an explicit path.' }
$CandidateManifest = [IO.Path]::GetFullPath($CandidateManifest)
$candidateDocument = Read-StrictManifest $CandidateManifest $false
$evidenceRoot = [IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $CandidateManifest) '..'))
$candidatePath = Assert-Within $evidenceRoot (Join-Path (Split-Path -Parent $CandidateManifest) ([string]$candidateDocument.candidateFile))
if ([IO.Path]::GetFileName($candidatePath) -cne "petfightnew-battle-state-$($candidateDocument.resourceVersion).fws.swf") {
    throw 'Candidate manifest does not identify the exact versioned candidate filename.'
}
$candidateDetails = Assert-Fws $candidatePath ([string]$candidateDocument.candidateSha256)
if ([int64]$candidateDetails.fileSize -ne [int64]$candidateDocument.candidateLength) {
    throw 'Candidate length does not match its manifest.'
}
Assert-CandidateMarkers $candidatePath
$candidateSymbols = Join-Path $evidenceRoot 'decompiled\candidate\symbolClass\symbols.csv'
if (-not (Test-Path -LiteralPath $candidateSymbols) -or
    (Get-Sha256 $candidateSymbols) -cne [string]$candidateDocument.symbolClassSha256) {
    throw 'Candidate SymbolClass evidence does not match its manifest.'
}

New-Item -ItemType Directory -Force -Path $patchDirectory | Out-Null
$rollbackRoot = Join-Path $evidenceRoot ('evidence\rollback-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
New-Item -ItemType Directory -Force -Path $rollbackRoot | Out-Null
foreach ($existing in @($productionCandidatePath, $productionManifestPath)) {
    if (Test-Path -LiteralPath $existing) {
        Copy-Item -LiteralPath $existing -Destination (Join-Path $rollbackRoot ([IO.Path]::GetFileName($existing)))
    }
}

$productionDocument = [ordered]@{
    schemaVersion = 1
    resourceVersion = [string]$candidateDocument.resourceVersion
    officialUrl = [string]$candidateDocument.officialUrl
    officialZwsSha256 = [string]$candidateDocument.officialZwsSha256
    candidateFile = 'petfightnew-battle-state-current.fws.swf'
    candidateLength = [int64]$candidateDocument.candidateLength
    candidateSha256 = [string]$candidateDocument.candidateSha256
    bridgeVersion = 5
    symbolClassSha256 = [string]$candidateDocument.symbolClassSha256
}
$candidateTemp = Join-Path $patchDirectory ('.petfightnew-candidate-' + [Guid]::NewGuid().ToString('N') + '.tmp')
$manifestTemp = Join-Path $patchDirectory ('.petfightnew-manifest-' + [Guid]::NewGuid().ToString('N') + '.tmp')
$hadProductionCandidate = Test-Path -LiteralPath $productionCandidatePath
$hadProductionManifest = Test-Path -LiteralPath $productionManifestPath
try {
    Copy-Item -LiteralPath $candidatePath -Destination $candidateTemp
    $productionDocument | ConvertTo-Json | Set-Content -LiteralPath $manifestTemp -Encoding utf8
    [void](Read-StrictManifest $manifestTemp $true)
    Move-Item -LiteralPath $candidateTemp -Destination $productionCandidatePath -Force
    Move-Item -LiteralPath $manifestTemp -Destination $productionManifestPath -Force
}
catch {
    foreach ($temporary in @($candidateTemp, $manifestTemp)) {
        if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force }
    }
    $candidateBackup = Join-Path $rollbackRoot ([IO.Path]::GetFileName($productionCandidatePath))
    $manifestBackup = Join-Path $rollbackRoot ([IO.Path]::GetFileName($productionManifestPath))
    if (Test-Path -LiteralPath $candidateBackup) {
        Copy-Item -LiteralPath $candidateBackup -Destination $productionCandidatePath -Force
    }
    elseif (-not $hadProductionCandidate -and (Test-Path -LiteralPath $productionCandidatePath)) {
        Remove-Item -LiteralPath $productionCandidatePath -Force
    }
    if (Test-Path -LiteralPath $manifestBackup) {
        Copy-Item -LiteralPath $manifestBackup -Destination $productionManifestPath -Force
    }
    elseif (-not $hadProductionManifest -and (Test-Path -LiteralPath $productionManifestPath)) {
        Remove-Item -LiteralPath $productionManifestPath -Force
    }
    throw
}

[pscustomobject]@{
    status = 'Promoted'
    version = [string]$candidateDocument.resourceVersion
    productionCandidate = $productionCandidatePath
    productionManifest = $productionManifestPath
    rollbackEvidence = $rollbackRoot
} | ConvertTo-Json
