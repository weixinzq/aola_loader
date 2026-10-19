"""Rebuild disposal diagnostics from the archived local baseline; no downloads."""
from pathlib import Path
import json
import re
import subprocess
import sys

REPO = Path(__file__).resolve().parents[3]
WORK = REPO / 'analysis/reverse-engineering/battle-dispose-diagnostics-20261017'
FFDEC = Path(r'D:\Programs\FFdec\ffdec-cli.exe')
sys.path.insert(0, str(REPO / 'analysis/tools'))
from petfight_bridge_abc import decode_swf, iter_doabc, parse_abc

DOC = 'mmo.petfightnew.DocPetFight'
PANEL = 'mmo.petfightnew.common.FightPanel'
CONTROLLER = 'mmo.petfightnew.common.FightController'
DOC_LEX = 'getlex QName(PackageNamespace("mmo.petfightnew"),"DocPetFight")'


def run(args, name):
    with (WORK / 'evidence' / (name + '.log')).open('w', encoding='utf-8') as log:
        subprocess.run([str(x) for x in args], stdout=log, stderr=subprocess.STDOUT, check=True)


def fragment(text):
    tail = text[text.index('public function dispose()'):]
    method = re.search(r'^\s*method\s*$.*?^\s*end ; method\s*$', tail, re.M | re.S)
    return '\n'.join(line.strip() for line in method.group().splitlines())


def stage(name):
    return DOC_LEX + '\npushstring "' + name + '"\ncallpropvoid QName(PackageNamespace(""),"noteDiagnosticDisposeStage"), 1\n'


def before_symbol(body, symbol, name):
    lines = body.splitlines()
    index = next(i for i, line in enumerate(lines) if ',"' + symbol + '")' in line)
    lines.insert(index, stage(name).rstrip())
    return '\n'.join(lines)


def before_class(body, name, phase):
    lines = body.splitlines()
    index = next(i for i, line in enumerate(lines) if line.startswith('getlex ') and ',"' + name + '")' in line)
    lines.insert(index, stage(phase).rstrip())
    return '\n'.join(lines)


def replace_method(current, output, class_name, patch, name):
    _, fws = decode_swf(current.read_bytes())
    methods = [m for _, _, abc in iter_doabc(fws) for m in parse_abc(abc, {(class_name, 'dispose')})]
    run([FFDEC, '-onerror', 'abort', '-replace', current, output, class_name,
         patch, methods[0]['methodBodyIndex']], name)


for folder in ('source', 'exports', 'variants', 'evidence'):
    (WORK / folder).mkdir(parents=True, exist_ok=True)
baseline = WORK / 'source/baseline.fws.swf'
run([FFDEC, '-onerror', 'abort', '-selectclass', DOC, '-export', 'script', WORK / 'source/as', baseline], 'baseline-doc')
run([FFDEC, '-onerror', 'abort', '-format', 'script:pcode', '-export', 'script', WORK / 'source/pcode', baseline], 'baseline-pcode')

doc = (WORK / 'source/as/scripts/mmo/petfightnew/DocPetFight.as').read_text(encoding='utf-8-sig')
doc = doc.replace('private static var _readyEpoch:int = 0;',
                  'private static var _readyEpoch:int = 0;\n\n      private static var _diagnosticDisposeStage:String = "";', 1)
doc = doc.replace('"resource":sanitizeDiagnosticResource(param2),',
                  '"resource":param1 == "dispose-error" ? param2 : sanitizeDiagnosticResource(param2),', 1)
doc = doc.replace('_aolaBattleBridgeRegistered = true;',
                  '_aolaBattleBridgeRegistered = true;\n               addDiagnosticTrace("dispose-diagnostic-ready","local-dispose-v2",-1,1);', 1)
helpers = '''      public static function noteDiagnosticDisposeStage(value:String) : void
      {
         _diagnosticDisposeStage = value;
         addDiagnosticTrace("dispose-stage",value,-1,0);
      }

      public static function noteDiagnosticDisposeError(error:Error) : void
      {
         var detail:String = _diagnosticDisposeStage + " | " + error.name + " (" + error.errorID + "): " + error.message + "\\n" + error.getStackTrace();
         detail = encodeURIComponent(detail);
         var offset:int = 0;
         while(offset < detail.length)
         {
            addDiagnosticTrace("dispose-error",detail.substr(offset,MAX_TRACE_RESOURCE_LENGTH),-1,int(offset / MAX_TRACE_RESOURCE_LENGTH));
            offset += MAX_TRACE_RESOURCE_LENGTH;
         }
         _diagnosticDisposeStage = "";
      }

'''
doc = doc.replace('      public static function noteInputReady()', helpers + '      public static function noteInputReady()', 1)
doc = doc.replace('++_diagnosticPanelDisposedCount;\n         }',
                  '++_diagnosticPanelDisposedCount;\n         }\n         _diagnosticDisposeStage = "";', 1)
doc_path = WORK / 'exports/DocPetFight.as'
doc_path.write_text(doc, encoding='utf-8')
doc_candidate = WORK / 'variants/01-doc.fws.swf'
run([FFDEC, '-onerror', 'abort', '-replace', baseline, doc_candidate, DOC, doc_path], 'replace-doc')

panel = fragment((WORK / 'source/pcode/scripts/mmo/petfightnew/common/FightPanel.pcode').read_text(encoding='utf-8-sig'))
start_call = 'callpropvoid QName(PackageNamespace(""),"noteDiagnosticPanelDisposeStarted"), 1'
panel = panel.replace(start_call, start_call + '\naola_dispose_try_start:\n' + stage('panel.ui').rstrip(), 1)
for symbol, phase in [('_backGroundView', 'panel.background'), ('petMCList', 'panel.models'),
                      ('disposeManagers', 'panel.managers'), ('FIGHT_END', 'panel.end-event'),
                      ('showHelloAction', 'panel.end-presentation'), ('getIsShowTitleHonor', 'panel.title'),
                      ('autoFight', 'panel.auto-fight'), ('handleNextFight', 'panel.next-fight'),
                      ('setHudVisible', 'panel.hud'), ('showOrHideControlBar', 'panel.control-bar'),
                      ('noteDiagnosticPanelDisposed', 'panel.complete')]:
    panel = before_symbol(panel, symbol, phase)
controller_dispose_call = '\n'.join([
    'getlex QName(PackageNamespace("mmo.petfightnew.common"),"FightController")',
    'getproperty QName(PackageNamespace(""),"instance")',
    'callpropvoid QName(PackageNamespace(""),"dispose"), 0'])
panel = panel.replace(controller_dispose_call, stage('panel.controller') + controller_dispose_call, 1)
local_count = int(re.search(r'localcount (\d+)', panel).group(1))
panel = re.sub(r'localcount \d+', 'localcount ' + str(local_count + 1), panel, count=1)
panel = re.sub(r'maxstack (\d+)', lambda m: 'maxstack ' + str(int(m.group(1)) + 2), panel, count=1)
handler = '\n'.join(['aola_dispose_try_end:', 'aola_dispose_catch:', 'setlocal ' + str(local_count),
                     'getlocal0', 'pushscope', DOC_LEX, 'getlocal ' + str(local_count),
                     'callpropvoid QName(PackageNamespace(""),"noteDiagnosticDisposeError"), 1',
                     'getlocal ' + str(local_count), 'throw'])
exception = 'try from aola_dispose_try_start to aola_dispose_try_end target aola_dispose_catch type QName(PackageNamespace(""),"Error") name QName(PackageNamespace(""),"disposeError") end'
panel = panel.replace('end ; code', handler + '\nend ; code\n' + exception, 1)
panel_path = WORK / 'exports/FightPanel.dispose.pcode'
panel_path.write_text(panel + '\n', encoding='utf-8')
panel_candidate = WORK / 'variants/02-panel.fws.swf'
replace_method(doc_candidate, panel_candidate, PANEL, panel_path, 'replace-panel')

controller = fragment((WORK / 'source/pcode/scripts/mmo/petfightnew/common/FightController.pcode').read_text(encoding='utf-8-sig'))
controller = before_class(controller, 'FightItemData', 'controller.managers')
controller = before_class(controller, 'FightData', 'controller.fight-data')
for symbol, phase in [('isInTerritoryFight', 'controller.post-data'), ('removeListeners', 'controller.listeners'),
                      ('setIsFighting', 'controller.service-state')]:
    controller = before_symbol(controller, symbol, phase)
controller = before_class(controller, 'FightEventDispatcher', 'controller.dispatcher')
controller = re.sub(r'maxstack (\d+)', lambda m: 'maxstack ' + str(int(m.group(1)) + 2), controller, count=1)
controller_path = WORK / 'exports/FightController.dispose.pcode'
controller_path.write_text(controller + '\n', encoding='utf-8')
candidate = WORK / 'variants/petfightnew-dispose-diagnostics.fws.swf'
replace_method(panel_candidate, candidate, CONTROLLER, controller_path, 'replace-controller')
run([FFDEC, '-onerror', 'abort', '-selectclass', DOC + ',' + PANEL + ',' + CONTROLLER,
     '-export', 'script', WORK / 'evidence/reread', candidate], 'candidate-reread')
run([FFDEC, '-onerror', 'abort', '-format', 'script:pcode', '-export', 'script',
     WORK / 'evidence/pcode', candidate], 'candidate-pcode')
print(json.dumps({'candidate': str(candidate), 'baseline': str(baseline),
                  'runtimeValidated': False, 'resourceCleanupChanged': False}))
