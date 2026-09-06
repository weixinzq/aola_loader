[CmdletBinding()]
param(
    [ValidateSet('Check', 'Prepare', 'Promote')]
    [string]$Mode = 'Check',
    [string]$FFDecPath = 'D:\Programs\FFdec\ffdec-cli.exe',
    [string]$EvidenceRoot,
    [string]$CandidateManifest,
    [string]$StartUrl = 'https://aola.100bt.com/play/start.xml'
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
    'mmo.petfightnew.DocPetFight',
    'mmo.petfightnew.common.FightPanel',
    'ensureAolaBattleBridge',
    'noteInputReady',
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

function Normalize-ControlFlowLine([string]$Line) {
    $normalized = $Line.Trim()
    $normalized = [regex]::Replace($normalized, '\bofs[0-9a-f]+\b', '<label>')
    $normalized = [regex]::Replace($normalized, '\baola_[A-Za-z0-9_]+\b', '<label>')
    return $normalized
}

function Assert-PatchedMethodEquivalent([string[]]$Expected, [string[]]$Actual, [string]$Description) {
    $expectedLines = @($Expected | ForEach-Object { Normalize-ControlFlowLine $_ } | Where-Object { $_ -ne '' })
    $actualLines = @($Actual | ForEach-Object { Normalize-ControlFlowLine $_ } | Where-Object { $_ -ne '' })
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
        'scripts\mmo\petfightnew\common\FightPanel.pcode' = @('public function enableClick()')
        'scripts\mmo\petfightnew\common\fightcontroller\UseSkill.pcode' = @(
            'public function handleUseSkill(', 'private function handleAnnalFeeEight(', 'private function handleMovie(')
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
    if ($document.schemaVersion -ne 1 -or $document.bridgeVersion -ne 4 -or
        [string]$document.resourceVersion -notmatch '^\d{1,32}$' -or
        [string]$document.candidateSha256 -notmatch '^[0-9a-f]{64}$' -or
        [string]$document.officialZwsSha256 -notmatch '^[0-9a-f]{64}$' -or
        [string]$document.symbolClassSha256 -notmatch '^[0-9a-f]{64}$' -or
        [int64]$document.candidateLength -lt 8 -or [int64]$document.candidateLength -gt $maximumSwfBytes) {
        throw 'Manifest values are invalid.'
    }
    $expectedUrl = "https://aola.100bt.com/play/pet/petfightnew~$($document.resourceVersion).swf"
    if ([string]$document.officialUrl -cne $expectedUrl) { throw 'Manifest officialUrl is not canonical.' }
    if ($Production -and [string]$document.candidateFile -cne 'petfightnew-battle-state-current.fws.swf') {
        throw 'Production manifest candidateFile is not the stable filename.'
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
    if (-not (Test-Path -LiteralPath $servicePcodePath) -or -not (Test-Path -LiteralPath $panelPcodePath)) {
        $selectedClasses = @(
            'mmo.petfightnew.PetFightService',
            'mmo.petfightnew.common.FightPanel',
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
        --target 'mmo.petfightnew.common.FightPanel:enableClick'
    if ($LASTEXITCODE -ne 0) { throw 'Method-body index discovery failed.' }
    $methodBodies = (($methodOutput -join [Environment]::NewLine) | ConvertFrom-Json)
    $serviceBody = @($methodBodies | Where-Object { $_.className -ceq 'mmo.petfightnew.PetFightService' })[0]
    $panelBody = @($methodBodies | Where-Object { $_.className -ceq 'mmo.petfightnew.common.FightPanel' })[0]

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
    $servicePatch = Join-Path $EvidenceRoot 'exports\patches\PetFightService.init.pcode'
    $panelPatch = Join-Path $EvidenceRoot 'exports\patches\FightPanel.enableClick.pcode'
    $generatedDoc = Join-Path $EvidenceRoot 'exports\patches\DocPetFight.as'
    Set-GeneratedText $servicePatch ([string[]]$serviceFragment)
    Set-GeneratedText $panelPatch ([string[]]$panelFragment)
    $template = Get-Content -LiteralPath $bridgeTemplatePath -Raw
    if ([regex]::Matches($template, '__EMBED_SYMBOL__').Count -ne 1) { throw 'Bridge template placeholder is invalid.' }
    Set-GeneratedText $generatedDoc @($template.Replace('__EMBED_SYMBOL__', $embedMatches[0].Groups['symbol'].Value).TrimEnd("`r", "`n"))

    $presentationPatchRoot = Join-Path $EvidenceRoot 'exports\presentation-patches'
    $presentationOutput = & $presentationPatchBuilder `
        -PcodeRoot $selectedPcode `
        -OriginalFws $originalFws `
        -HelperPath $helperPath `
        -OutputDirectory $presentationPatchRoot
    if ($LASTEXITCODE -ne 0) { throw 'Battle-presentation patch generation failed.' }
    $presentationPatches = @(($presentationOutput -join [Environment]::NewLine) | ConvertFrom-Json)
    if ($presentationPatches.Count -ne 16) {
        throw "Expected 16 battle-presentation method patches, found $($presentationPatches.Count)."
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
            }
        ) + $presentationPatches
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
    Assert-PcodeEquivalent ([string[]]$serviceFragment) ([string[]]$candidateService) `
        'PetFightService.init reread does not match the generated patch.'
    Assert-PcodeEquivalent ([string[]]$panelFragment) ([string[]]$candidatePanel) `
        'FightPanel.enableClick reread does not match the generated patch.'
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
        bridgeVersion = 4
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
        '- Changed scope: `DocPetFight`, `PetFightService.init`, `FightPanel.enableClick`, and the 16 approved per-turn presentation methods.',
        '- The presentation path preserves state settlement and terminal callbacks while bypassing per-turn movies.',
        '- Damage and healing number suppression is limited to result-number leaf methods.',
        '- Static verification passed; real Flash runtime verification is still required.'
    ) | Set-Content -LiteralPath $reportPath -Encoding utf8

    [pscustomobject]@{
        status = 'Prepared'
        version = $live.ResourceVersion
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
    bridgeVersion = 4
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
