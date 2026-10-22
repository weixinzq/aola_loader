$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
Start-Process -FilePath (Join-Path $repo 'analysis\build\AolaTestClient\Release\net48\AolaTestClient.exe')
