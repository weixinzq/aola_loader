param(
    [Parameter(Mandatory = $true)]
    [string]$InputXml,
    [Parameter(Mandatory = $true)]
    [string]$VersionDataVersion,
    [Parameter(Mandatory = $true)]
    [string]$OutputJson
)

$resolvedInput = [IO.Path]::GetFullPath($InputXml)
$resolvedOutput = [IO.Path]::GetFullPath($OutputJson)
if (-not (Test-Path -LiteralPath $resolvedInput -PathType Leaf)) {
    throw "Versiondata XML does not exist: $resolvedInput"
}
if ($VersionDataVersion -notmatch '^\d+$') {
    throw 'VersionDataVersion must contain digits only.'
}

[xml]$document = Get-Content -LiteralPath $resolvedInput -Raw
$entries = [ordered]@{}
foreach ($file in $document.version.f) {
    $name = [string]$file.n
    $version = [string]$file.v
    if ($name -notmatch '^fightassets/bitmap/pet\d+/pet\d+_[12]_[0-2]$') {
        continue
    }
    if ($version -notmatch '^\d+$' -or $entries.Contains($name)) {
        throw "Invalid or duplicate battle pet movie version entry: $name"
    }
    $entries[$name] = $version
}
if ($entries.Count -eq 0) {
    throw 'No complementary bitmap battle pet entries were found.'
}

$payload = [ordered]@{
    schemaVersion = 1
    versionDataVersion = $VersionDataVersion
    versionDataSha256 = (Get-FileHash -LiteralPath $resolvedInput -Algorithm SHA256).Hash.ToLowerInvariant()
    defaultVersion = '1210'
    entries = $entries
}
$parent = Split-Path -Parent $resolvedOutput
if (-not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
}
[IO.File]::WriteAllText(
    $resolvedOutput,
    ($payload | ConvertTo-Json -Depth 4),
    [Text.UTF8Encoding]::new($false))
Write-Output "entries=$($entries.Count) output=$resolvedOutput"
