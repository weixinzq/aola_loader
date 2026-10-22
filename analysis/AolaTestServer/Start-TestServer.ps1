$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
& (Join-Path $repo 'analysis\build\AolaTestServer\Release\net8.0\AolaTestServer.exe') (Join-Path $PSScriptRoot 'cache')
