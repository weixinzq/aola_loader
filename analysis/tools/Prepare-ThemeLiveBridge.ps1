[CmdletBinding()]
param(
    [string]$OfficialSwf,
    [string]$EvidenceRoot,
    [string]$FFDecPath = 'D:\Programs\FFdec\ffdec-cli.exe'
)
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$utf8 = New-Object Text.UTF8Encoding($false)
function FF([string[]]$Arguments) {
    & $FFDecPath @Arguments
    if ($LASTEXITCODE -ne 0) { throw 'FFDec failed' }
}
$OfficialSwf = [IO.Path]::GetFullPath($OfficialSwf)
$EvidenceRoot = [IO.Path]::GetFullPath($EvidenceRoot)
New-Item -ItemType Directory -Path $EvidenceRoot -Force | Out-Null
$class = 'mmo.controlv2.controlbarskin.ControlBarSkinHandler'
$base = 'mmo.controlv2.controlbarskin.ControlBarSkinBase'
FF @('-onerror','abort','-selectclass',$class,'-export','script',(Join-Path $EvidenceRoot 'export'),$OfficialSwf)
$handlerPath = Join-Path $EvidenceRoot 'export\scripts\mmo\controlv2\controlbarskin\ControlBarSkinHandler.as'
$handler = [IO.File]::ReadAllText($handlerPath)
$handler = $handler.Replace('import flash.display.MovieClip;', "import flash.display.MovieClip;`n   import flash.utils.getDefinitionByName;")
$handler = $handler.Replace('private function getCurrentSkin()', 'private function getNativeSkin()')
$handler = $handler.Replace('this.getCurrentSkin().addToStage();', 'setThemeListeners(this.getCurrentSkin(),true); this.getCurrentSkin().addToStage();')
$handler = $handler.Replace('this.removeFromStage();', 'setThemeListeners(this.getCurrentSkin(),false); this.removeFromStage();')
$handler = $handler.Replace('self._skinList.push({', 'var nativeSkin:ControlBarSkinBase = new ControlBarSkinBase(self._usingSkinId,param1); if(self._aolaThemeId != 0) setThemeListeners(nativeSkin,false); self._skinList.push({')
$handler = $handler.Replace('"skin":new ControlBarSkinBase(self._usingSkinId,param1)', '"skin":nativeSkin')
$methods = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'theme\ControlBarTheme.methods.as'))
$methods += "`n      private function getCurrentSkin() : ControlBarSkinBase { return _aolaThemeId == 0 ? getNativeSkin() : _aolaThemes[String(_aolaThemeId)]; }`n"
$last = $handler.LastIndexOf('   }')
$handler = $handler.Insert($last, $methods)
[IO.File]::WriteAllText($handlerPath,$handler,$utf8)
$current = Join-Path $EvidenceRoot 'handler.fws.swf'
FF @('-onerror','abort','-replace',$OfficialSwf,$current,$class,$handlerPath)

# FFDec does not retain the external interface namespace when compiling this handler.
FF @('-onerror','abort','-format','script:pcode','-selectclass',$class,'-export','script',(Join-Path $EvidenceRoot 'handler-pcode'),$current)
$bindingRoot = Join-Path $EvidenceRoot 'handler-bindings'
$bindingMethods = @(& python (Join-Path $PSScriptRoot 'theme_bridge_assets.py') handler-bindings `
    (Join-Path $EvidenceRoot 'handler-pcode\scripts\mmo\controlv2\controlbarskin\ControlBarSkinHandler.pcode') $bindingRoot)
if ($LASTEXITCODE -ne 0) { throw 'Handler binding restoration failed' }
$bindingLookup = @('methods','--input',$current)
foreach ($name in $bindingMethods) { $bindingLookup += @('--target',($class + ':' + $name)) }
$bindingJson = & python (Join-Path $PSScriptRoot 'petfight_bridge_abc.py') @bindingLookup
if ($LASTEXITCODE -ne 0) { throw 'Handler binding method lookup failed' }
$bindingArguments = New-Object Collections.Generic.List[string]
foreach ($method in (($bindingJson -join "`n") | ConvertFrom-Json)) {
    $bindingArguments.Add($class)
    $bindingArguments.Add((Join-Path $bindingRoot ($method.methodName.Replace('$','') + '.pcode')))
    $bindingArguments.Add([string]$method.methodBodyIndex)
}
$bindingArgsFile = Join-Path $EvidenceRoot 'handler-binding-args.txt'
[IO.File]::WriteAllLines($bindingArgsFile,$bindingArguments,$utf8)
$bound = Join-Path $EvidenceRoot 'handler-bound.swf'
FF @('-onerror','abort','-replace',$current,$bound,$bindingArgsFile)
$current = $bound

# Preserve original methods: change listener call sites in the skin-owned object tree only.
$listenerClasses = @($base,
    'mmo.controlv2.HistoryPanelV2','mmo.controlv2.ActionPanel','mmo.controlv2.ChatControlHandler',
    'mmo.controlv2.ControlBarBtnTipsHelper','mmo.controlv2.TalkBar','mmo.controlv2.EmotePanel',
    'mmo.controlv2.BlueIcon','mmo.controlv2.RestGameTime','mmo.controlv2.RmbShoppingIcon',
    'mmo.controlv2.player.PlayerInfo','mmo.controlv2.pause.PauseBtnMC','mmo.controlv2.pet.PetIcon',
    'mmo.controlv2.phrase.PhrasePanel','mmo.controlv2.lock.ControlBarLockHelper',
    'mmo.controlv2.buddybubble.BuddyBubbleTip','mmo.controlv2.galaxyfleet.GalaxyFleetTip',
    'mmo.controlv2.squadbubble.SquadBubbleTip')
# Recompilation reindexes methods and closures. Export from that same candidate,
# so imported newfunction operands keep pointing to the original callbacks.
FF @('-onerror','abort','-format','script:pcode','-selectclass',($listenerClasses -join ','),'-export','script',(Join-Path $EvidenceRoot 'pcode'),$current)
$argsFile = Join-Path $EvidenceRoot 'replace-args.txt'
$arguments = New-Object Collections.Generic.List[string]
foreach ($listenerClass in $listenerClasses) {
    $pcode = Join-Path $EvidenceRoot ('pcode\scripts\' + $listenerClass.Replace('.', '\') + '.pcode')
    $patchRoot = Join-Path $EvidenceRoot ('listener-patches\' + $listenerClass)
    $methodNames = @(& python (Join-Path $PSScriptRoot 'theme_bridge_assets.py') listeners $pcode $patchRoot | Where-Object { $_ })
    if ($LASTEXITCODE -ne 0) { throw 'Listener patch generation failed' }
    $lookup = @('methods','--input',$current)
    foreach ($name in $methodNames) { $lookup += @('--target',($listenerClass + ':' + $name)) }
    if ($methodNames.Count -eq 0) { continue }
    $json = & python (Join-Path $PSScriptRoot 'petfight_bridge_abc.py') @lookup
    if ($LASTEXITCODE -ne 0) { throw 'Listener method lookup failed' }
    foreach ($method in (($json -join "`n") | ConvertFrom-Json)) {
        $arguments.Add($listenerClass)
        $arguments.Add((Join-Path $patchRoot ($method.methodName.Replace('$','') + '.pcode')))
        $arguments.Add([string]$method.methodBodyIndex)
    }
}
[IO.File]::WriteAllLines($argsFile,$arguments,$utf8)
$compiled = Join-Path $EvidenceRoot 'controlv2-theme-live.swf'
FF @('-onerror','abort','-replace',$current,$compiled,$argsFile)
$output = Join-Path $EvidenceRoot 'controlv2-theme-live.fws.swf'
& python (Join-Path $PSScriptRoot 'petfight_bridge_abc.py') unpack --input $compiled --output $output
if ($LASTEXITCODE -ne 0) { throw 'Candidate decompression failed' }
FF @('-onerror','abort','-selectclass',(($listenerClasses + $class) -join ','),'-export','script',(Join-Path $EvidenceRoot 'reread'),$output)
& python (Join-Path $PSScriptRoot 'petfight_bridge_abc.py') inspect --input $output
if ($LASTEXITCODE -ne 0) { throw 'Candidate inspection failed' }

$liveRoot = Join-Path $EvidenceRoot 'themes'
foreach ($id in 1..9) {
    & python (Join-Path $PSScriptRoot 'theme_bridge_assets.py') theme `
        (Join-Path $repo "analysis\AolaLoader\Resources\Themes\skin$id.swf") `
        (Join-Path $liveRoot "skin$id.swf") --theme $id
    if ($LASTEXITCODE -ne 0) { throw "Theme $id namespace generation failed" }
}
# Theme 10 has its own variable-length class mapping and visual/animation source.
& python (Join-Path $repo 'analysis\AolaLoader\Resources\Themes\Sources\Castorice\build-skin10.py') `
    --ffdec $FFDecPath --evidence (Join-Path $EvidenceRoot 'theme10')
if ($LASTEXITCODE -ne 0) { throw 'Theme 10 candidate generation failed' }
Copy-Item -LiteralPath (Join-Path $EvidenceRoot 'theme10\skin10.swf') -Destination (Join-Path $liveRoot 'skin10.swf')
