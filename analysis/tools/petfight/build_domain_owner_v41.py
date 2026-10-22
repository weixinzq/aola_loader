"""Repair v4 probe diagnostics in separate v4.1 candidates; retain tested v4."""
from pathlib import Path
import json
import subprocess

REPO = Path(__file__).resolve().parents[3]
OLD = REPO / 'analysis/reverse-engineering/battle-domain-owner-20261022'
WORK = REPO / 'analysis/reverse-engineering/battle-domain-owner-v41-20261022'
FFDEC = Path(r'D:\Programs\FFdec\ffdec-cli.exe')
DOC = 'mmo.petfightnew.DocPetFight'
DOMAIN = 'mmo.loader.scheduler.DomainLoader'
CONTAINER = 'mmo.loader.LoaderContainer'
START = 'mmo.petfightnew.common.startmovie.StartMovie'


def run(args, name):
    with (WORK / 'evidence' / (name + '.log')).open('w', encoding='utf-8') as log:
        subprocess.run([str(x) for x in args], stdout=log, stderr=subprocess.STDOUT, check=True)


for folder in ['source', 'variants', 'evidence']:
    (WORK / folder).mkdir(parents=True, exist_ok=True)

methods = (OLD / 'source/DomainOwner.methods.as').read_text(encoding='utf-8-sig')
methods = methods.replace('private static const DOMAIN_OWNER_RELEASE_ENABLED:Boolean = true;',
    'private static const DOMAIN_OWNER_RELEASE_ENABLED:Boolean = true;\n      private static var _domainOwnerLoaderReadyLogged:Boolean = false;', 1)
methods = methods.replace('''      private static function recordDomainOwnerSnapshot(phase:String, release:Boolean) : void
      {
         try''', '''      private static function recordDomainOwnerSnapshot(phase:String, release:Boolean) : void
      {
         var step:String = "state";
         var domainId:int = 0;
         try''', 1)
methods = methods.replace('            var target:Object;', '''            step = "loader-ready";
            var loaderVersion:int = int(Object(LoaderContainer.instance).aolaDomainOwnerVersion());
            if(!_domainOwnerLoaderReadyLogged)
            {
               addDiagnosticTrace("domain-owner-loader-ready","version=" + loaderVersion,-1,loaderVersion);
               _domainOwnerLoaderReadyLogged = true;
            }
            var target:Object;''', 1)
methods = methods.replace('               childCount = 0;', '''               domainId = int(state.id);
               step = "domain-parent";
               childCount = 0;''', 1)
methods = methods.replace('''               tree = ownerTreeMatches(target as flash.system.ApplicationDomain);
               snapshot = Object(LoaderContainer.instance).aolaDomainOwnerProbe(target,release && idle);
               addDiagnosticTrace("domain-owner-domain","phase=" + phase + ";id=" + state.id +
                  ";parent=" + parentId + ";trackedChildren=" + childCount +
                  ";treeMatches=" + tree.matched + ";treeScanned=" + tree.scanned + ";treeTruncated=" + int(tree.truncated) +
                  ";idle=" + int(idle),-1,int(state.id));''', '''               addDiagnosticTrace("domain-owner-domain","phase=" + phase + ";id=" + state.id +
                  ";parent=" + parentId + ";trackedChildren=" + childCount + ";idle=" + int(idle),-1,int(state.id));
               step = "display-tree";
               tree = ownerTreeMatches(target as flash.system.ApplicationDomain);
               addDiagnosticTrace("domain-owner-tree","phase=" + phase + ";id=" + state.id +
                  ";treeMatches=" + tree.matched + ";treeScanned=" + tree.scanned + ";treeTruncated=" + int(tree.truncated),-1,int(state.id));
               step = "loader-call";
               snapshot = Object(LoaderContainer.instance).aolaDomainOwnerProbe(target,release && idle);
               step = "snapshot-fields";''', 1)
methods = methods.replace('''            addDiagnosticTrace("domain-owner-error","phase=" + phase + ";error=" + error.errorID + ";message=" + error.message,-1,4);''',
    '''            recordDomainOwnerError(phase,step,domainId,error);''', 1)
methods += '''
      private static function recordDomainOwnerError(phase:String, step:String, domainId:int, error:Error) : void
      {
         var detail:String = encodeURIComponent(error.message + "\\n" + error.getStackTrace());
         var offset:int = 0;
         var part:int = 0;
         while(offset < detail.length)
         {
            addDiagnosticTrace("domain-owner-error","phase=" + phase + ";step=" + step + ";id=" + domainId +
               ";error=" + error.errorID + ";part=" + part + ";detail=" + detail.substr(offset,320),-1,part);
            offset += 320;
            ++part;
         }
      }
'''
(WORK / 'source/DomainOwner.methods.as').write_text(methods, encoding='utf-8')
doc = (OLD / 'source/DocPetFight.as').read_text(encoding='utf-8-sig')
doc = doc.replace((OLD / 'source/DomainOwner.methods.as').read_text(encoding='utf-8-sig'), methods, 1)
doc = doc.replace('"local-domain-owner-v4",-1,4', '"local-domain-owner-v41",-1,41', 1)
(WORK / 'source/DocPetFight.as').write_text(doc, encoding='utf-8')

container = (OLD / 'source/LoaderContainer.as').read_text(encoding='utf-8-sig')
pos = container.rfind('   }')
container = container[:pos] + '''      public function aolaDomainOwnerVersion() : int
      {
         return 41;
      }
''' + container[pos:]
(WORK / 'source/LoaderContainer.as').write_text(container, encoding='utf-8')

domain = (OLD / 'source/DomainLoader.as').read_text(encoding='utf-8-sig')
old_method = (OLD / 'source/DomainLoader.methods.as').read_text(encoding='utf-8-sig')
new_method = old_method.replace('var result:Object = {"version":4,',
    'var step:String = "pending";\n         try\n         {\n         var result:Object = {"version":41,', 1)
new_method = new_method.replace('         for(var key:Object', '         step = "owners";\n         for(var key:Object', 1)
new_method = new_method.replace('            if(owner.loaders != null)', '            step = "loader-info";\n            if(owner.loaders != null)', 1)
new_method = new_method.replace('            if(owner.domainListCopy != null)', '            step = "domain-slots";\n            if(owner.domainListCopy != null)', 1)
new_method = new_method.replace('         result.watch =', '         step = "inspector-watch";\n         result.watch =', 1)
new_method = new_method.replace('''         return result;
      }''', '''         return result;
         }
         catch(error:Error)
         {
            error.message = "DomainLoader." + step + ";" + error.message;
            throw error;
         }
      }''', 1)
domain = domain.replace(old_method, new_method, 1)
(WORK / 'source/DomainLoader.as').write_text(domain, encoding='utf-8')

inputs = {'loader': OLD / 'variants/loader-domain-owner-v4.fws.swf',
          'battle': OLD / 'variants/petfightnew-domain-owner-v4.fws.swf'}
outputs = {}
for group, classes in [('loader', [DOMAIN, CONTAINER]), ('battle', [DOC])]:
    current = inputs[group]
    for i, cls in enumerate(classes):
        target = WORK / 'variants' / (group + '-' + str(i) + '.fws.swf')
        run([FFDEC, '-onerror', 'abort', '-replace', current, target, cls,
             WORK / 'source' / (cls.rsplit('.', 1)[1] + '.as')], 'replace-' + cls.rsplit('.', 1)[1])
        current = target
    final = WORK / 'variants' / (('loader' if group == 'loader' else 'petfightnew') + '-domain-owner-v41.fws.swf')
    final.write_bytes(current.read_bytes())
    outputs[group] = final
    run([FFDEC, '-onerror', 'abort', '-selectclass', ','.join(classes), '-export', 'script',
         WORK / 'evidence' / (group + '-reread'), final], group + '-reread')

for label, swf in [('v4', inputs['battle']), ('v41', outputs['battle'])]:
    run([FFDEC, '-onerror', 'abort', '-selectclass', START, '-export', 'script',
         WORK / 'evidence' / ('start-' + label), swf], 'start-' + label)
relative = Path('scripts/mmo/petfightnew/common/startmovie/StartMovie.as')
same_start = (WORK / 'evidence/start-v4' / relative).read_text(encoding='utf-8-sig').split() == (WORK / 'evidence/start-v41' / relative).read_text(encoding='utf-8-sig').split()
if not same_start:
    raise RuntimeError('StartMovie changed during v4.1 probe repair.')
report = {'version': 41, 'inputs': {k: str(v) for k,v in inputs.items()},
    'candidates': {k: str(v) for k,v in outputs.items()}, 'startMovieSourceUnchanged': same_start,
    'releaseAlgorithmChanged': False, 'ppapiRuntimeValidated': False,
    'marker': 'local-domain-owner-v41'}
(WORK / 'evidence/report.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps(report, ensure_ascii=False))
