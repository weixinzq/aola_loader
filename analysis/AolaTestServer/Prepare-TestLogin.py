"""Build the fixed-player login copy used only by the local test entry."""
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / 'analysis/tools'))
from petfight_bridge_abc import decode_swf, iter_doabc, parse_abc

CLASS = 'mmo.user.login.Main'
METHOD = 'getAutoLoginInfo'
ROOT = REPO / 'analysis/reverse-engineering/test-server-20261022'
SOURCE = ROOT / 'source/user/login~2026012289000603.swf'
WORK = ROOT / 'login-patch'
OUTPUT = REPO / 'analysis/AolaTestServer/cache/user/login~2026012289000603.swf'
FFDEC = Path(r'D:\Programs\FFdec\ffdec-cli.exe')
WORK.mkdir(parents=True, exist_ok=True)


def ffdec(*args):
    with (WORK / 'ffdec.log').open('a', encoding='utf-8') as log:
        subprocess.run([str(FFDEC), '-onerror', 'abort', *map(str, args)],
                       stdout=log, stderr=subprocess.STDOUT, check=True)


_, fws = decode_swf(SOURCE.read_bytes())
original = WORK / 'original.fws.swf'
original.write_bytes(fws)
ffdec('-format', 'script:pcode', '-selectclass', CLASS, '-export',
      'script,symbolClass', WORK / 'original', original)
script = WORK / 'original/scripts/mmo/user/login/Main.pcode'
text = script.read_text(encoding='utf-8-sig')
tail = text[text.index('private function getAutoLoginInfo('):]
method = re.search(r'^\s*method\s*$.*?^\s*end ; method\s*$', tail, re.M | re.S).group()
values = {
    'duoduoId': '10001', 'token': 'local-test', 'sceneName': 'chunqingmuchang',
    'charId': '0', 'nickName': '测试奥拉', 'username': '10001',
    'sessionId': 'aola-local-test-session',
}
instructions = ['getlocal0', 'pushscope']
for key, value in values.items():
    instructions.extend([f'pushstring "{key}"', f'pushstring "{value}"'])
instructions.extend([f'newobject {len(values)}', 'returnvalue'])
method = re.sub(r'code\s*\n.*?end ; code',
                'code\n' + '\n'.join(instructions) + '\nend ; code', method, count=1, flags=re.S)
method = re.sub(r'maxstack \d+', 'maxstack 16', method, count=1)
patch = WORK / 'getAutoLoginInfo.pcode'
patch.write_text(method + '\n', encoding='utf-8')
target = next(item for _, _, abc in iter_doabc(fws)
              for item in parse_abc(abc, {(CLASS, METHOD)}))
ffdec('-replace', original, OUTPUT, CLASS, patch, target['methodBodyIndex'])
ffdec('-selectclass', CLASS, '-export', 'script,symbolClass', WORK / 'candidate', OUTPUT)
ffdec('-replace', ROOT / 'source/start~2021072975243068.swf',
      REPO / 'analysis/AolaTestServer/cache/start.swf', 'mmo.checkversion.Load',
      REPO / 'analysis/AolaTestClient/Flash/Load.as')
print('已生成独立测试登录副本；原始登录资源保留。')
