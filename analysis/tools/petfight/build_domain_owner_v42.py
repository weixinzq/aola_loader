"""Convert the tested v4.1 CWS loader into the FWS required by the host rule."""
from pathlib import Path
import json
import zlib

REPO = Path(__file__).resolve().parents[3]
SOURCE = REPO / 'analysis/reverse-engineering/battle-domain-owner-v41-20261022/variants'
WORK = REPO / 'analysis/reverse-engineering/battle-domain-owner-v42-20261022'
loader_input = SOURCE / 'loader-domain-owner-v41.fws.swf'
battle_input = SOURCE / 'petfightnew-domain-owner-v41.fws.swf'
loader_output = WORK / 'variants/loader-domain-owner-v42.fws.swf'
battle_output = WORK / 'variants/petfightnew-domain-owner-v42.fws.swf'

for folder in ['variants', 'evidence']:
    (WORK / folder).mkdir(parents=True, exist_ok=True)

# v4.1's known loader input is CWS; retain its version/declared length and decompress the body.
compressed = loader_input.read_bytes()
loader_output.write_bytes(b'FWS' + compressed[3:8] + zlib.decompress(compressed[8:]))
battle_output.write_bytes(battle_input.read_bytes())
report = {'packagingVersion': 42, 'flashProbeVersion': 41,
    'loaderInput': str(loader_input), 'battleInput': str(battle_input),
    'loaderOutput': str(loader_output), 'battleOutput': str(battle_output),
    'change': 'CWS to FWS only; no ABC or battle behavior change.',
    'gameRuntimeValidated': False}
(WORK / 'evidence/report.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps(report, ensure_ascii=False))
