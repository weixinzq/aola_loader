"""Build a battle-only loader-release experiment; startup resources are untouched."""
from pathlib import Path
import subprocess

REPO = Path(__file__).resolve().parents[3]
OLD = REPO / 'analysis/reverse-engineering/battle-domain-owner-20261022'
WORK = REPO / 'analysis/reverse-engineering/battle-domain-loader-release-20261022'
FFDEC = Path(r'D:\Programs\FFdec\ffdec-cli.exe')
BASE = OLD / 'variants/petfightnew-domain-owner-v4.fws.swf'
DOC = 'mmo.petfightnew.DocPetFight'
PRELOAD = 'mmo.petfightnew.common.util.PreLoadAssetsUtil'
HELPER = 'mmo.petfightnew.common.helper.LoadFileHelper'


def run(args, name):
    with (WORK / 'evidence' / (name + '.log')).open('w', encoding='utf-8') as log:
        subprocess.run([str(x) for x in args], stdout=log, stderr=subprocess.STDOUT, check=True)


def replace(text, old, new):
    if text.count(old) != 1:
        raise RuntimeError('Expected one insertion point: ' + old)
    return text.replace(old, new, 1)


for directory in ['source', 'evidence', 'variants']:
    (WORK / directory).mkdir(parents=True, exist_ok=True)

run([FFDEC, '-onerror', 'abort', '-selectclass', ','.join([PRELOAD, HELPER]), '-export', 'script',
     WORK / 'evidence/base', BASE], 'export-base')

doc = (OLD / 'source/DocPetFight.as').read_text(encoding='utf-8-sig')
doc = replace(doc, (OLD / 'source/DomainOwner.methods.as').read_text(encoding='utf-8-sig'),
              (WORK / 'source/BattleDomainLoaders.methods.as').read_text(encoding='utf-8-sig'))
doc = replace(doc, '      private static var _domainOwnerPhase:int = 0;\n', '')
doc = replace(doc, '         _domainOwnerPhase = 1;\n', '')
doc = replace(doc, '         processDomainOwnerFrames();', '         processBattleDomainLoaders();')
doc = replace(doc, '         recordDomainOwnerSnapshot("idle",DOMAIN_OWNER_RELEASE_ENABLED && _domainOwnerPhase == 0);',
              '         recordBattleDomainLoaders("idle");')
doc = replace(doc, 'addDiagnosticTrace("domain-owner-ready","local-domain-owner-v4",-1,4);',
              'addDiagnosticTrace("battle-loader-ready","local-domain-loader-release-v5",-1,5);')
doc = replace(doc, 'public static function noteDiagnosticResourceEnded(param1:Object) : void',
              'public static function noteDiagnosticResourceEnded(param1:Object, value:Object = null) : void')
doc = replace(doc, '         resource = String(state.resource);',
              '         resource = String(state.resource);\n         noteBattleResourceLoaded(value,resource);')

def original(cls):
    return (WORK / 'evidence/base/scripts' / (cls.replace('.', '/') + '.as')).read_text(encoding='utf-8-sig')


preload = original(PRELOAD)
preload = replace(preload, '         DocPetFight.noteDiagnosticResourceEnded(this);',
                  '         DocPetFight.noteDiagnosticResourceEnded(this,param1);')
preload = replace(preload, '   import mmo.petfightnew.common.FightData;',
                  '   import mmo.petfightnew.common.FightData;\n   import mmo.petfightnew.common.helper.LoadFileHelper;')
preload = replace(preload, '         ResScheduler.preLoad(this._preloadQueue,new ResDomain(FightData.instance.applicationDomain));',
                  '''         var domain:ResDomain = new ResDomain(FightData.instance.applicationDomain);
         for each(var url:String in this._preloadQueue)
         {
            LoadFileHelper.preloadSingleFile(url,domain);
         }''')
helper = original(HELPER)
helper = replace(helper, '   import mmo.loader.scheduler.ResDomain;',
                 '   import mmo.loader.scheduler.ResDomain;\n   import mmo.petfightnew.DocPetFight;')
helper = replace(helper, 'ResParams.create(url,null,domain,ResPriority.PRELOAD,null,function():*',
                 '''ResParams.create(url,function(values:Array):void
         {
            DocPetFight.noteBattleResourceLoaded(values[0],url);
         },domain,ResPriority.PRELOAD,[""],function():*''')

current = BASE
for cls, text in [(DOC, doc), (PRELOAD, preload), (HELPER, helper)]:
    source = WORK / 'source' / (cls.rsplit('.', 1)[1] + '.as')
    source.write_text(text, encoding='utf-8')
    output = WORK / 'variants' / (cls.rsplit('.', 1)[1] + '.swf')
    run([FFDEC, '-onerror', 'abort', '-replace', current, output, cls, source], 'replace-' + cls.rsplit('.', 1)[1])
    current = output

final = WORK / 'variants/petfightnew-domain-loader-release-v5.fws.swf'
final.write_bytes(current.read_bytes())
run([FFDEC, '-onerror', 'abort', '-selectclass', ','.join([DOC, PRELOAD, HELPER]), '-export', 'script',
     WORK / 'evidence/reread', final], 'reread')
print(final)
