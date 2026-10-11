param([string]$FFDecPath = 'D:\Programs\FFdec\ffdec-cli.exe')

$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
$source = Join-Path $repoRoot 'analysis\AolaLoader\Resources\Patches\petfightnew-battle-cinematics-2026091780747880-v3.fws.swf'
$pcode = Join-Path $repoRoot 'analysis\reverse-engineering\battle-bridge-20260918-2026091780747880-pwsh\decompiled\pcode-candidate\scripts\mmo\petfightnew\DocPetFight.pcode'
$abcTool = Join-Path $repoRoot 'analysis\tools\petfight_bridge_abc.py'
$buildRoot = Join-Path $repoRoot 'analysis\AolaLoader\Resources\Patches\Build\battle-cinematics-20260924'
$fragment = Join-Path $buildRoot 'exports\patches\DocPetFight.cinit.pcode'
$candidate = Join-Path $buildRoot 'variants\petfightnew-battle-cinematics-2026091780747880-v4.fws.swf'
$expectedSourceHash = '11145d757cf9c6b5727bfc3bd3ead7ee4d3878326e00d5f7241e8aa592f31080'

if ((Get-FileHash -Algorithm SHA256 -LiteralPath $source).Hash.ToLowerInvariant() -cne $expectedSourceHash) {
	throw 'V3 battle candidate changed; inspect it before rebuilding.'
}
if (Test-Path -LiteralPath $candidate) { throw "Refusing to overwrite $candidate" }
$methods = @(& python $abcTool methods --input $source --target 'mmo.petfightnew.DocPetFight:$cinit' | ConvertFrom-Json)
if ($LASTEXITCODE -ne 0 -or $methods.Count -ne 1) { throw 'Unable to resolve exact DocPetFight class initializer.' }
$lines = @(Get-Content -LiteralPath $pcode)
$marker = '      public static var skipBattlePresentation:Boolean = false;'
$markerIndex = [array]::IndexOf($lines, $marker)
if ($markerIndex -lt 0) { throw 'Default battle presentation field changed.' }
$start = $markerIndex + 1
while ($start -lt $lines.Count -and $lines[$start].Trim() -ne 'method') { $start++ }
$end = $start + 1
while ($end -lt $lines.Count -and $lines[$end].Trim() -ne 'end ; method') { $end++ }
if ($start -ge $lines.Count -or $end -ge $lines.Count) { throw 'Class initializer P-code not found.' }
$body = [Collections.Generic.List[string]]::new([string[]]$lines[$start..$end])
$property = '               findproperty QName(PackageNamespace(""),"skipBattlePresentation")'
$propertyIndex = [array]::IndexOf([string[]]$body.ToArray(), $property)
if ($propertyIndex -lt 0 -or $body[$propertyIndex + 1].Trim() -cne 'pushfalse' -or
	$body[$propertyIndex + 2].Trim() -cne 'setproperty QName(PackageNamespace(""),"skipBattlePresentation")') {
	throw 'Default battle presentation assignment changed.'
}
$body[$propertyIndex + 1] = '               pushtrue'
[IO.File]::WriteAllLines($fragment, [string[]]$body, [Text.UTF8Encoding]::new($false))
& $FFDecPath -onerror abort -replace $source $candidate 'mmo.petfightnew.DocPetFight' $fragment ([string]$methods[0].methodBodyIndex)
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $candidate)) { throw 'Default presentation patch failed.' }
Write-Output "candidate=$candidate"
Write-Output "sha256=$((Get-FileHash -Algorithm SHA256 -LiteralPath $candidate).Hash.ToLowerInvariant())"
