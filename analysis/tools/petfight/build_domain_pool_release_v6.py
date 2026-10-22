"""Release the disposed FightMcPool domain and weakly observe pool lifetime."""
from pathlib import Path
import subprocess

REPO = Path(__file__).resolve().parents[3]
OLD = REPO / 'analysis/reverse-engineering/battle-domain-loader-release-20261022'
WORK = REPO / 'analysis/reverse-engineering/battle-domain-pool-release-20261022'
FFDEC = Path(r'D:\Programs\FFdec\ffdec-cli.exe')
BASE = OLD / 'variants/petfightnew-domain-loader-release-v5.fws.swf'
DOC = 'mmo.petfightnew.DocPetFight'
POOL = 'mmo.petfightnew.common.manager.FightMcPool'


def run(args, name):
    with (WORK / 'evidence' / (name + '.log')).open('w', encoding='utf-8') as log:
        subprocess.run([str(item) for item in args], stdout=log, stderr=subprocess.STDOUT, check=True)


def replace(text, old, new):
    if text.count(old) != 1:
        raise RuntimeError('Expected one insertion point: ' + old)
    return text.replace(old, new, 1)


run([FFDEC, '-onerror', 'abort', '-selectclass', POOL, '-export', 'script', WORK / 'evidence/base', BASE], 'export-base')
pool = (WORK / 'evidence/base/scripts' / (POOL.replace('.', '/') + '.as')).read_text(encoding='utf-8-sig')
pool = replace(pool, '   import flash.system.ApplicationDomain;',
               '   import flash.system.ApplicationDomain;\n   import mmo.petfightnew.DocPetFight;')
pool = replace(pool, '         this._domain = param1;',
               '         this._domain = param1;\n         DocPetFight.noteBattlePool(this,param1);')
pool = replace(pool, '         if(this.map == null)',
               '         DocPetFight.noteBattlePoolDisposed(this,this._domain);\n         this._domain = null;\n         if(this.map == null)')
pos = pool.rfind('   }')
pool = pool[:pos] + '''      public function aolaPoolDomainState() : Object
      {
         return {"domainNull":this._domain == null,"disposed":this._isDispose,"mapNull":this.map == null};
      }
''' + pool[pos:]

doc = (OLD / 'source/DocPetFight.as').read_text(encoding='utf-8-sig')
doc = replace(doc, '"local-domain-loader-release-v5",-1,5', '"local-domain-pool-release-v6",-1,6')
doc = replace(doc, '               if(state.kind == "model")', '''               if(state.kind == "battle-mc-pool" && int(state.disposedAt) >= 0)
               {
                  var poolState:Object = Object(target).aolaPoolDomainState();
                  addDiagnosticTrace("battle-pool-alive","id=" + state.id + ";domain=" + state.owner +
                     ";disposed=" + int(poolState.disposed) + ";domainNull=" + int(poolState.domainNull) +
                     ";mapNull=" + int(poolState.mapNull),now - int(state.disposedAt),int(state.id));
               }
               if(state.kind == "model")''')
pos = doc.rfind('   }')
doc = doc[:pos] + '''      public static function noteBattlePool(target:Object, domain:Object) : void
      {
         var domainState:Object = _diagnosticApplicationDomains[domain];
         watchRetention(target,"battle-mc-pool",int(domainState.id));
      }

      public static function noteBattlePoolDisposed(target:Object, domain:Object) : void
      {
         var state:Object = watchRetention(target,"battle-mc-pool");
         state.disposedAt = getTimer();
         addDiagnosticTrace("battle-pool-disposed","id=" + state.id + ";domain=" + state.owner +
            ";domainHeldAtDispose=" + int(domain != null),-1,int(state.id));
      }
''' + doc[pos:]

current = BASE
for cls, text in [(DOC, doc), (POOL, pool)]:
    source = WORK / 'source' / (cls.rsplit('.', 1)[1] + '.as')
    source.write_text(text, encoding='utf-8')
    output = WORK / 'variants' / (cls.rsplit('.', 1)[1] + '.swf')
    run([FFDEC, '-onerror', 'abort', '-replace', current, output, cls, source], 'replace-' + cls.rsplit('.', 1)[1])
    current = output
final = WORK / 'variants/petfightnew-domain-pool-release-v6.fws.swf'
final.write_bytes(current.read_bytes())
run([FFDEC, '-onerror', 'abort', '-selectclass', ','.join([DOC, POOL]), '-export', 'script', WORK / 'evidence/reread', final], 'reread')
print(final)
