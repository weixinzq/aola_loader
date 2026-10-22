[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$cache = Join-Path $PSScriptRoot 'cache'
$snapshot = Join-Path $repo 'analysis\reverse-engineering\panel-call-capture-20261019\source'
$source = Join-Path $repo 'analysis\reverse-engineering\test-server-20261022\source'
New-Item -ItemType Directory -Path (Join-Path $cache 'user') -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $snapshot 'start.xml') -Destination $cache
Copy-Item -LiteralPath (Join-Path $snapshot 'versiondata~20261015557387610.swf') -Destination $cache
foreach ($name in @('config~20261015557387610.xml', 'difference~20261015557387610.xml')) {
    Copy-Item -LiteralPath (Join-Path $source $name) -Destination $cache
}
Copy-Item -LiteralPath (Join-Path $source 'start~2021072975243068.swf') -Destination (Join-Path $cache 'start.swf')
Copy-Item -LiteralPath (Join-Path $source 'user\serverslist~2026061158292062.swf') -Destination (Join-Path $cache 'user')
python (Join-Path $PSScriptRoot 'Prepare-TestLogin.py')
if ($LASTEXITCODE -ne 0) { throw '测试登录副本生成失败。' }
dotnet build (Join-Path $PSScriptRoot 'AolaTestServer.csproj') -c Release --nologo
if ($LASTEXITCODE -ne 0) { throw '测试服务端构建失败。' }
dotnet build (Join-Path $repo 'analysis\AolaTestClient\AolaTestClient.csproj') -c Release --nologo
if ($LASTEXITCODE -ne 0) { throw '独立测试客户端构建失败。' }
Write-Host '准备完成。运行 Start-TestServer.ps1 启动服务端，运行 Start-TestClient.ps1 打开独立客户端。'
