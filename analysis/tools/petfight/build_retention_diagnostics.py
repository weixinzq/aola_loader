"""Add weak object/reference observations to the existing local diagnostic patch."""
from pathlib import Path
import json
import re
import subprocess
import sys

REPO = Path(__file__).resolve().parents[3]
WORK = REPO / 'analysis/reverse-engineering/battle-retention-trace-20261017'
PCODE = REPO / 'analysis/reverse-engineering/battle-dispose-diagnostics-20261017/evidence/pcode/scripts'
FFDEC = Path(r'D:\Programs\FFdec\ffdec-cli.exe')
sys.path.insert(0, str(REPO / 'analysis/tools'))
from petfight_bridge_abc import decode_swf, iter_doabc, parse_abc

DOC = 'mmo.petfightnew.DocPetFight'
BASE = 'mmo.petfightnew.common.pet.PetMovieStrategyBase'
BITMAP = 'mmo.petfightnew.common.pet.BitmapPetMovieStrategy'
START = 'mmo.petfightnew.common.startmovie.StartMovie'
DOC_LEX = 'getlex QName(PackageNamespace("mmo.petfightnew"),"DocPetFight")'

def run(arguments, log):
    with (WORK / 'evidence' / log).open('w', encoding='utf-8') as output:
        subprocess.run([str(value) for value in arguments], stdout=output, stderr=subprocess.STDOUT, check=True)

def script(class_name):
    return (PCODE / (class_name.replace('.', '/') + '.pcode')).read_text(encoding='utf-8-sig')

def fragment(text, signature):
    tail = text[text.index(signature):]
    part = re.search(r'^\s*method\s*$.*?^\s*end ; method\s*$', tail, re.M | re.S).group()
    return '\n'.join(line.strip() for line in part.splitlines())

def field(text, name):
    return re.search(r'(?:getproperty|initproperty|setproperty) ([^\n]+,"' + name + r'"\))', text).group(1)

def get_field(text, name):
    return ['getlocal0', 'getproperty ' + field(text, name)]

def call(name, count, arguments):
    return '\n'.join([DOC_LEX] + arguments + ['callpropvoid QName(PackageNamespace(""),"' + name + '"), ' + str(count)])

doc = (WORK / 'source/DocPetFight.as').read_text(encoding='utf-8-sig')
methods = (REPO / 'analysis/tools/petfight/RetentionDiagnostics.methods.as').read_text(encoding='utf-8-sig')
doc = doc.replace('private static function onAolaBattleDrainTraceEvents()', methods + '\n      private static function onAolaBattleDrainTraceEvents()', 1)
doc = doc.replace('addDiagnosticTrace("dispose-diagnostic-ready","local-dispose-v2",-1,1);',
                  'addDiagnosticTrace("dispose-diagnostic-ready","local-dispose-v2",-1,1);\n               addDiagnosticTrace("retention-diagnostic-ready","local-retention-v1",-1,1);', 1)
doc = doc.replace('"released":false', '"released":false,\n            "releasedAt":-1,\n            "definitions":-1', 1)
doc = doc.replace('state.released = true;', 'state.released = true;\n         state.releasedAt = getTimer();', 1)
doc = doc.replace('         var item:Object;\n', '         recordRetentionSnapshots();\n         var item:Object;\n', 1)
doc_path = WORK / 'exports/DocPetFight.as'
doc_path.write_text(doc, encoding='utf-8')
current = WORK / 'variants/01-doc.fws.swf'
run([FFDEC, '-onerror', 'abort', '-replace', WORK / 'source/baseline.fws.swf', current, DOC, doc_path], 'replace-doc.log')

base = script(BASE)
bitmap = script(BITMAP)
start = script(START)
patches = [
    (BASE, '$iinit', 'public function PetMovieStrategyBase(', call('noteRetentionModel', 3, ['getlocal0','getlocal1','getlocal2'])),
    (BASE, 'cacheMovie', 'protected function cacheMovie(', call('noteRetentionMovie', 3, ['getlocal0','getlocal2','getlocal1'])),
]
arguments = ['getlocal0'] + get_field(base, '_disposed') + get_field(base, '_onResPrepared') + get_field(base, '_assetsLoader')
patches += [(BASE, 'dispose', 'public function dispose()', call('noteRetentionModelDisposed', 5, arguments + ['pushnull'])),
            (BITMAP, 'dispose', 'override public function dispose()', call('noteRetentionModelDisposed', 5, arguments + get_field(bitmap, '_config')))]
arguments = ['getlocal0']
for name in ['timer','frameTaskList','_mc','_mcRole','_otherRole','_fightSignInMcArr']:
    arguments += get_field(start, name)
patches.append((START, 'dispose', 'private function dispose()', call('noteRetentionStartDisposed', 7, arguments)))

for index, (class_name, method_name, signature, observation) in enumerate(patches):
    text = fragment(script(class_name), signature)
    text = text.replace('returnvoid', observation + '\nreturnvoid')
    text = re.sub(r'maxstack (\d+)', lambda m: 'maxstack ' + str(int(m[1]) + 9), text, count=1)
    patch = WORK / 'exports' / (class_name.rsplit('.',1)[-1] + '.' + method_name.replace('$','') + '.pcode')
    patch.write_text(text + '\n', encoding='utf-8')
    _, fws = decode_swf(current.read_bytes())
    target = [m for _, _, abc in iter_doabc(fws) for m in parse_abc(abc, {(class_name, method_name)})][0]
    output = WORK / 'variants' / ('%02d-patch.fws.swf' % (index + 2))
    run([FFDEC, '-onerror', 'abort', '-replace', current, output, class_name, patch, target['methodBodyIndex']], 'replace-%d.log' % index)
    current = output

candidate = WORK / 'variants/petfightnew-retention-trace.fws.swf'
candidate.write_bytes(current.read_bytes())
classes = ','.join([DOC,BASE,BITMAP,START])
run([FFDEC, '-onerror', 'abort', '-selectclass', classes, '-export', 'script', WORK / 'evidence/reread', candidate], 'reread.log')
run([FFDEC, '-onerror', 'abort', '-format', 'script:pcode', '-export', 'script', WORK / 'evidence/pcode', candidate], 'pcode.log')
print(json.dumps({'candidate':str(candidate),'marker':'local-retention-v1','runtimeValidated':False,'cleanupChanged':False}))
