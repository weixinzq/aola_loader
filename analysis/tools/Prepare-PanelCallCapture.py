"""Prepend an observation to Panel_Helper without recompiling its original body."""

import argparse
import re
import subprocess
from pathlib import Path

from petfight_bridge_abc import decode_swf, iter_doabc, parse_abc


CLASS = 'mmo.play.activity.helper.Panel_Helper'
METHOD = 'loadResAndShow'


def method_text(text):
    tail = text[text.index('public static function loadResAndShow('):]
    match = re.search(r'^\s*method\s*$.*?^\s*end ; method\s*$', tail, re.M | re.S)
    return '\n'.join(line.strip() for line in match.group().splitlines())


def prepare(source, output, work, ffdec):
    work.mkdir(parents=True, exist_ok=True)

    def run(arguments, log):
        with (work / log).open('w', encoding='utf-8') as stream:
            subprocess.run([str(ffdec), '-onerror', 'abort', *map(str, arguments)],
                           stdout=stream, stderr=subprocess.STDOUT, check=True)

    # Work on a separate FWS; the official source is never overwritten.
    _, fws = decode_swf(source.read_bytes())
    original = work / 'original.fws.swf'
    original.write_bytes(fws)
    run(['-format', 'script:pcode', '-selectclass', CLASS, '-export',
         'script,symbolClass', work / 'original', original], 'export-original.log')
    script = Path('scripts') / (CLASS.replace('.', '/') + '.pcode')
    method = method_text((work / 'original' / script).read_text(encoding='utf-8-sig'))
    observation = '''aola_capture_start:
getlex QName(PackageNamespace("flash.external"),"ExternalInterface")
pushstring "aolaPanelCaptured"
getlocal1
getlocal2
callpropvoid QName(PackageNamespace(""),"call"), 3
aola_capture_end:
jump aola_capture_resume
aola_capture_catch:
pop
aola_capture_resume:
'''
    patched = method.replace('code\n', 'code\n' + observation, 1)
    patched = re.sub(r'maxstack (\d+)', lambda m: 'maxstack ' + str(max(4, int(m[1]))), patched, count=1)
    patched = patched.replace('end ; code', '''end ; code
try from aola_capture_start to aola_capture_end target aola_capture_catch type QName(PackageNamespace(""),"Error") name QName(PackageNamespace(""),"aolaCaptureError") end''', 1)
    patch = work / 'loadResAndShow.pcode'
    patch.write_text(patched + '\n', encoding='utf-8')
    target = next(item for _, _, abc in iter_doabc(fws)
                  for item in parse_abc(abc, {(CLASS, METHOD)}))
    candidate = work / 'play-panel-capture.fws.swf'
    run(['-replace', original, candidate, CLASS, patch, target['methodBodyIndex']], 'replace.log')
    run(['-format', 'script:pcode', '-selectclass', CLASS, '-export',
         'script,symbolClass', work / 'candidate', candidate], 'export-candidate.log')
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(candidate.read_bytes())
    print('Created', output, '- runtime pending')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('work', type=Path)
    parser.add_argument('--ffdec', type=Path, default=Path(r'D:\Programs\FFdec\ffdec-cli.exe'))
    args = parser.parse_args()
    prepare(args.source.resolve(), args.output.resolve(), args.work.resolve(), args.ffdec)
