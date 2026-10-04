"""Extend only the existing onAolaThemeApply method's upper bound, preserving other code."""
from pathlib import Path
import argparse
import json
import re
import subprocess
import sys

HERE=Path(__file__).resolve().parent
REPO=HERE.parents[5]
sys.path.insert(0,str(REPO/'analysis/tools'))
from petfight_bridge_abc import decode_swf
parser=argparse.ArgumentParser()
parser.add_argument('--source',type=Path,required=True,help='Current theme-9 startup bridge, or its retained pre-change copy.')
parser.add_argument('--ffdec',default='D:/Programs/FFdec/ffdec-cli.exe')
parser.add_argument('--evidence',type=Path,default=REPO/'analysis/reverse-engineering/theme-castorice/T2/start')
args=parser.parse_args()
root=args.evidence.resolve();root.mkdir(parents=True,exist_ok=True)
original=args.source.resolve()
before=root/'start-before.swf';before.write_bytes(original.read_bytes())
subprocess.run([args.ffdec,'-onerror','abort','-format','script:pcode','-selectclass','mmo.checkversion.Load',
    '-export','script',str(root/'pcode'),str(before)],check=True)
text=(root/'pcode/scripts/mmo/checkversion/Load.pcode').read_text(encoding='utf-8-sig')
section=text.split('function onAolaThemeApply(',1)[1]
method=re.search(r'(?m)^\s*method\s*$[\s\S]*?^\s*end ; method\s*$',section)[0]
method=method.replace('pushbyte 9','pushbyte 10')
(root/'theme-range.pcode').write_text(method,encoding='utf-8')
lookup=subprocess.check_output([sys.executable,str(REPO/'analysis/tools/petfight_bridge_abc.py'),
    'methods','--input',str(before),'--target','mmo.checkversion.Load:onAolaThemeApply'],text=True,encoding='utf-8')
index=json.loads(lookup)[0]['methodBodyIndex']
candidate=root/'start-theme10.swf'
subprocess.run([args.ffdec,'-onerror','abort','-replace',str(before),str(candidate),'mmo.checkversion.Load',
    str(root/'theme-range.pcode'),str(index)],check=True)
# FFDec's p-code importer also normalizes a body trait. Use it to locate the
# requested pushbyte operand, then preserve every other byte of the current bridge.
_,original_fws=decode_swf(before.read_bytes())
_,compiled_fws=decode_swf(candidate.read_bytes())
offset=next(i for i,(old,new) in enumerate(zip(original_fws,compiled_fws)) if old==9 and new==10)
result=bytearray(original_fws);result[offset]=10
candidate.write_bytes(result)
print(candidate)
