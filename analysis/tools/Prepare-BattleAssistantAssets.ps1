param(
    [Parameter(Mandatory=$true)][string]$StagingRoot,
    [string]$IdList,
    [string]$MissingList,
    [string]$DataDirectory,
    [string]$FFDec = 'D:\Programs\FFdec\ffdec-cli.exe',
    [string]$Inspector = "$env:USERPROFILE\.codex\skills\reverse-engineer-swf\scripts\inspect_swf.py"
)
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
if (!$IdList) { $IdList = Join-Path $projectRoot 'analysis\AolaLoader\Resources\Data\battle-assistant-assets.json' }
if (!$DataDirectory) { $DataDirectory = Join-Path $projectRoot 'data\organized-data' }
$additional = @()
if ($MissingList) { $additional = @('--missing-list', $MissingList) }
& python -X utf8 (Join-Path $PSScriptRoot 'prepare_battle_assistant_assets.py') --root $projectRoot --staging $StagingRoot --ids $IdList --data $DataDirectory --ffdec $FFDec --inspector $Inspector @additional
if ($LASTEXITCODE -ne 0) { throw "图片准备有未完成项，请查看产物报告；已有有效图片已保留。" }


