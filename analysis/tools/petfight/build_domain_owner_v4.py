"""Build paired, opt-in v4 battle/loader candidates from local SWFs."""
from pathlib import Path
import json
import re
import subprocess

REPO = Path(__file__).resolve().parents[3]
WORK = REPO / 'analysis/reverse-engineering/battle-domain-owner-20261022'
FFDEC = Path(r'D:\Programs\FFdec\ffdec-cli.exe')
BATTLE = REPO / 'analysis/reverse-engineering/battle-startmovie-role-release-20261022/variants/petfightnew-startmovie-role-release.fws.swf'
LOADER = REPO / 'analysis/build/AolaLoader/Release/net48/logs/swf-capture-20260828-144231732/source/00002-loader~20260827411198170.swf'
DOC = 'mmo.petfightnew.DocPetFight'
DATA = 'mmo.petfightnew.common.FightData'
CONTROLLER = 'mmo.petfightnew.common.FightController'
DOMAIN = 'mmo.loader.scheduler.DomainLoader'
MANAGER = 'mmo.loader.scheduler.ResManager'
WATCH = 'mmo.loader.error.InspectorErrorWatch'
CONTAINER = 'mmo.loader.LoaderContainer'
START = 'mmo.petfightnew.common.startmovie.StartMovie'


def run(args, name):
    with (WORK / 'evidence' / (name + '.log')).open('w', encoding='utf-8') as log:
        subprocess.run([str(x) for x in args], stdout=log, stderr=subprocess.STDOUT, check=True)


def export(swf, classes, directory, pcode=False):
    args = [FFDEC, '-onerror', 'abort']
    if pcode:
        args += ['-format', 'script:pcode']
    run(args + ['-selectclass', ','.join(classes), '-export', 'script', directory, swf], directory.name)


def source_path(directory, cls, suffix='.as'):
    return directory / 'scripts' / (cls.replace('.', '/') + suffix)


def append_methods(text, methods):
    pos = text.rfind('   }')
    return text[:pos] + methods + '\n' + text[pos:]


def replace_once(text, old, new):
    if text.count(old) != 1:
        raise RuntimeError('Expected one source insertion point: ' + old)
    return text.replace(old, new, 1)


for directory in ['source', 'variants', 'evidence']:
    (WORK / directory).mkdir(parents=True, exist_ok=True)

base_battle = WORK / 'evidence/battle-base'
base_loader = WORK / 'evidence/loader-base'
export(BATTLE, [DOC, DATA, CONTROLLER], base_battle)
export(LOADER, [DOMAIN, MANAGER, WATCH, CONTAINER], base_loader)
export(BATTLE, [START], WORK / 'evidence/start-v3', True)
export(BATTLE, [START], WORK / 'evidence/start-as-v3')

sources = {}
for cls in [DATA, CONTROLLER]:
    original = source_path(base_battle, cls).read_text(encoding='utf-8-sig')
    method = '''
      public static function aolaExistingInstance() : FightData
      {
         return _instance;
      }

      public static function aolaDomainOwnerState() : Object
      {
         return {"instanceNull":_instance == null, "domainNull":_instance == null || _instance._domain == null};
      }
''' if cls == DATA else '''
      public static function aolaExistingInstance() : FightController
      {
         return _instance;
      }

      public static function aolaDomainOwnerState() : Object
      {
         return {"instanceNull":_instance == null, "disposed":_instance != null && _instance._isDisposed,
            "panelNull":_instance == null || _instance.fightPanel == null};
      }
'''
    sources[cls] = append_methods(original, method)

doc = source_path(base_battle, DOC).read_text(encoding='utf-8-sig')
doc = replace_once(doc, '''            controller = FightController.instance;
            panel = controller.fightPanel;
            ended = controller.whoWon != -1;
            active = panel != null && !ended;
            inputReady = active && !panel.canStart && panel.mouseEnabled && panel.mouseChildren;
            battleId = FightData.instance.battleId;
            turn = controller.turnCount;''', '''            controller = Object(FightController).aolaExistingInstance();
            var data:FightData = Object(FightData).aolaExistingInstance();
            if(controller != null && data != null)
            {
               panel = controller.fightPanel;
               ended = controller.whoWon != -1;
               active = panel != null && !ended;
               inputReady = active && !panel.canStart && panel.mouseEnabled && panel.mouseChildren;
               battleId = data.battleId;
               turn = controller.turnCount;
            }''')
doc = replace_once(doc, 'private static var _diagnosticApplicationDomainCreatedCount:int = 0;',
    'private static var _domainOwnerFrames:int = 0;\n      private static var _domainOwnerPhase:int = 0;\n      private static var _diagnosticApplicationDomainCreatedCount:int = 0;')
doc = replace_once(doc, 'addDiagnosticTrace("retention-diagnostic-ready","local-retention-v1",-1,1);',
    'addDiagnosticTrace("retention-diagnostic-ready","local-retention-v1",-1,1);\n               addDiagnosticTrace("domain-owner-ready","local-domain-owner-v4",-1,4);')
doc = replace_once(doc, 'state.releasedAt = getTimer();',
    'state.releasedAt = getTimer();\n         _domainOwnerFrames = 2;\n         _domainOwnerPhase = 1;')
doc = replace_once(doc, '         processDiagnosticAttacks(now);',
    '         processDiagnosticAttacks(now);\n         processDomainOwnerFrames();')
doc = replace_once(doc, '         _retentionSnapshotAt = now;',
    '         _retentionSnapshotAt = now;\n         recordDomainOwnerSnapshot("idle",DOMAIN_OWNER_RELEASE_ENABLED && _domainOwnerPhase == 0);')
doc = append_methods(doc, (WORK / 'source/DomainOwner.methods.as').read_text(encoding='utf-8-sig'))
sources[DOC] = doc

for cls, filename in [(DOMAIN, 'DomainLoader.methods.as'), (MANAGER, 'ResManager.methods.as'),
                      (WATCH, 'InspectorErrorWatch.methods.as'), (CONTAINER, 'LoaderContainer.methods.as')]:
    original = source_path(base_loader, cls).read_text(encoding='utf-8-sig')
    if cls == DOMAIN:
        original = replace_once(original, 'private static var AllLoaders:',
            'private static var _aolaOwners:flash.utils.Dictionary = new flash.utils.Dictionary(true);\n      private static var AllLoaders:')
        original = replace_once(original, 'this.resInfo = param1;',
            'this.resInfo = param1;\n         _aolaOwners[this] = true;')
    sources[cls] = append_methods(original, (WORK / 'source' / filename).read_text(encoding='utf-8-sig'))

outputs = {}
for group, baseline, classes in [('loader', LOADER, [MANAGER, WATCH, DOMAIN, CONTAINER]),
                                  ('battle', BATTLE, [DATA, CONTROLLER, DOC])]:
    current = baseline
    for index, cls in enumerate(classes):
        path = WORK / 'source' / (cls.rsplit('.', 1)[1] + '.as')
        path.write_text(sources[cls], encoding='utf-8')
        output = WORK / 'variants' / (group + '-' + str(index) + '.fws.swf')
        run([FFDEC, '-onerror', 'abort', '-replace', current, output, cls, path], 'replace-' + cls.rsplit('.', 1)[1])
        current = output
    final = WORK / 'variants' / ('loader-domain-owner-v4.fws.swf' if group == 'loader' else 'petfightnew-domain-owner-v4.fws.swf')
    final.write_bytes(current.read_bytes())
    outputs[group] = final
    export(final, classes, WORK / ('evidence/' + group + '-v4'))

export(outputs['battle'], [START], WORK / 'evidence/start-v4', True)
before = source_path(WORK / 'evidence/start-v3', START, '.pcode').read_text(encoding='utf-8-sig')
after = source_path(WORK / 'evidence/start-v4', START, '.pcode').read_text(encoding='utf-8-sig')
def relocated_code(text):
    return re.sub(r'newfunction \d+', 'newfunction <relocated>', text).split()


same_start = relocated_code(before) == relocated_code(after)
if not same_start:
    raise RuntimeError('v4 changed StartMovie p-code; keep the v3 cleanup intact.')
export(outputs['battle'], [START], WORK / 'evidence/start-as-v4')
same_start_source = source_path(WORK / 'evidence/start-as-v3', START).read_text(encoding='utf-8-sig').split() == source_path(WORK / 'evidence/start-as-v4', START).read_text(encoding='utf-8-sig').split()
if not same_start_source:
    raise RuntimeError('StartMovie source changed after method index relocation.')
report = {'version': 4, 'battleInput': str(BATTLE), 'loaderInput': str(LOADER),
    'candidates': {key: str(value) for key, value in outputs.items()},
    'startMoviePcodeUnchangedExceptClosureMethodIndices': same_start,
    'startMovieSourceUnchanged': same_start_source, 'runtimeValidated': False,
    'release': 'Remove completed DomainLoader references only for released battle domains and descendants; no unload or cache purge.'}
(WORK / 'evidence/report.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps(report, ensure_ascii=False))
