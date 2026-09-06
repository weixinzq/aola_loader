"""Offline official-image preparation. Runtime has no dependency on this tool."""
import argparse
import csv
import hashlib
import json
import math
import re
import shutil
import subprocess
import sys
from pathlib import Path
from PIL import Image


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + '.tmp')
    temporary.write_text(json.dumps(value, ensure_ascii=False, indent=2), encoding='utf-8')
    temporary.replace(path)


def table(directory, name):
    with (directory / (name + '.csv')).open(encoding='utf-8-sig', newline='') as stream:
        return list(csv.DictReader(stream))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ['root', 'staging', 'ids', 'data', 'ffdec', 'inspector']:
        parser.add_argument('--' + name, type=Path, required=True)
    parser.add_argument('--missing-list', type=Path)
    args = parser.parse_args()
    root, staging = args.root.resolve(), args.staging.resolve()
    output = root / 'analysis/AolaLoader/Resources/BattleAssistant'
    evidence = root / 'analysis/reverse-engineering/battle-assistant-assets'
    request = json.loads(args.ids.read_text(encoding='utf-8-sig'))
    if args.missing_list:
        for line in args.missing_list.read_text(encoding='utf-8-sig').splitlines():
            if not line.strip():
                continue
            category, identifier = line.strip().split(':')
            if category not in request['requested'] or int(identifier) <= 0:
                raise ValueError('Invalid missing-image key: ' + line)
            request['requested'][category] = sorted(set(request['requested'][category]) | {int(identifier)})
    versions = {entry['name']: str(entry['version']) for entry in json.loads((staging / 'manifests/effective-index.json').read_text(encoding='utf-8-sig'))}
    data = args.data
    equipment = {int(row['id']): row for row in table(data, 'equipment')}
    predecessors = {}
    for row in equipment.values():
        next_id = int(row['level_up_id'])
        if next_id > 0:
            predecessors.setdefault(next_id, []).append(int(row['id']))
    catalog = {}
    artifacts = {row['id']: row for row in table(data, 'soul_artifact_entries')}
    for category, filename, description in [('equipment', 'equipment', 'description'), ('soul-card', 'soul_cards', None), ('soul-artifact', 'soul_artifacts', 'catalog_description')]:
        for row in table(data, filename):
            text = row.get(description, '') if description else ''
            if category == 'soul-artifact':
                text += '\n' + artifacts.get(row['effect_id'], {}).get('description', '')
            catalog[category + ':' + row['id']] = {'name': row['name'], 'description': text}
    # Keep the static relations as reference data, never label optional buffs as actual rolls.
    catalog['_soulCardBuffs'] = table(data, 'soul_card_buffs')
    catalog['_soulCardRelations'] = table(data, 'soul_card_buff_relations')
    official = staging / 'decompiled/library/materialdata/scripts/mmo/materialdata'
    crystal = (official / 'CrystalKeyData.as').read_text(encoding='utf-8-sig')
    for match in re.finditer(r'new CrystalKey\((\d+),("(?:[^"\\]|\\.)*"),("(?:[^"\\]|\\.)*")\)', crystal):
        catalog['crystal-key:' + match[1]] = {'name': json.loads(match[2]), 'description': json.loads(match[3])}
    tote = (official / 'ToteValueSource.as').read_text(encoding='utf-8-sig')
    for match in re.finditer(r'new ToteValueData\((\d+),("(?:[^"\\]|\\.)*")', tote):
        catalog['tote-entry:' + match[1]] = {'name': json.loads(match[2]), 'description': ''}
    write_json(output / 'catalog.json', catalog)
    previous = {(x['category'], x['id']): x for x in request.get('assets', [])}
    results, missing, failures = [], [], []

    def run(command, log):
        result = subprocess.run([str(x) for x in command], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=180)
        log.write_bytes(result.stdout)
        if result.returncode:
            raise RuntimeError('Command failed; see ' + str(log))
        return result.stdout

    for category, identifiers in request['requested'].items():
        for identifier in sorted(set(identifiers)):
            key = category + ':' + str(identifier)
            target = output / category / (str(identifier) + '.png')
            try:
                if category == 'pet':
                    # PetIconContainer and PetIconLoaderBase normalize extended race ids.
                    portrait_id = identifier % 10000
                    if portrait_id < 4400:
                        # PetIconLoader_Static_Old.getClsName(FIGHT): dedicated _F sprite.
                        resource, classname = f'peticon/peticon{portrait_id}', f'mmo.pet.peticon{portrait_id}_F'
                    else:
                        resource = f'peticon/icon/type0/peticon{portrait_id}/peticon{portrait_id}'
                        classname = f'mmo.peticon.icon.type0.PetIcon{portrait_id}'
                elif category == 'equipment':
                    base = identifier
                    visited = set()
                    while base in predecessors:
                        if base in visited or len(predecessors[base]) != 1:
                            raise ValueError('Ambiguous equipment predecessor')
                        visited.add(base)
                        base = predecessors[base][0]
                    row = equipment.get(base)
                    if row is None:
                        raise ValueError('Equipment absent from official table')
                    if int(row['view_id']) != -1:
                        resource, classname = f'petcard/view{base}', f'mmo.petcard.view{base}'
                    else:
                        resource, classname = 'petcard/type' + row['type'], 'mmo.petcard.CardView' + row['type'] + '_' + row['color']
                elif category == 'soul-card':
                    resource, classname = f'hk/view/hkview_{identifier}', f'mmo.hk.HKView_{identifier}_S'
                elif category == 'soul-artifact':
                    resource, classname = f'totebag/view/toteview_{identifier}', f'mmo.tote.ToteView_{identifier}'
                elif category == 'crystal-key':
                    resource, classname = f'crystalkey/itemview/crystalkeyview_{identifier}', f'mmo.crystalkey.CrystalKeyView_{identifier}'
                else:
                    raise ValueError('Unconfirmed category')
                # VersManager.getVersion: an SWF absent from versionMap uses 1210.
                version = versions.get(resource, '1210')
                url = 'https://aola.100bt.com/play/' + resource + '~' + version + '.swf'
                existing = previous.get((category, identifier))
                if target.exists() and existing and existing.get('url') == url:
                    with Image.open(target) as image:
                        image.verify()
                    if hashlib.sha256(target.read_bytes()).hexdigest() == existing.get('imageSha256'):
                        results.append(existing)
                        print(key + ': cached', flush=True)
                        continue
                work = evidence / 'exports' / category / str(identifier) / version
                work.mkdir(parents=True, exist_ok=True)
                source = work / 'source.swf'
                if not source.exists():
                    local = staging / 'resources' / (resource + '~' + version + '.swf')
                    if local.exists():
                        shutil.copyfile(local, source)
                    else:
                        downloaded = work / 'download.swf'
                        run(['curl.exe', '--fail', '--location', '--silent', '--show-error', '--connect-timeout', '15', '--max-time', '120', url, '--output', downloaded], work / 'download.log')
                        downloaded.replace(source)
                inspection = json.loads(run([sys.executable, args.inspector, '--json', source], work / 'inspection.json'))[0]
                if not inspection['valid']:
                    raise ValueError('Invalid original SWF')
                decoded = work / 'decompiled'
                if not (decoded / 'symbolClass/symbols.csv').exists():
                    run([args.ffdec, '-export', 'script,symbolClass', decoded, source], work / 'decompile.log')
                symbols = dict((name, ident) for ident, name in csv.reader((decoded / 'symbolClass/symbols.csv').open(encoding='utf-8-sig'), delimiter=';'))
                if classname not in symbols:
                    raise ValueError('Expected export class absent: ' + classname)
                exported = work / 'images'
                crop = None
                if category == 'pet' and portrait_id >= 4400:
                    config_class = classname + 'Config_config'
                    if config_class not in symbols:
                        raise ValueError('Portrait crop configuration class absent')
                    if not exported.exists():
                        run([args.ffdec, '-format', 'image:png', '-export', 'image,binaryData', exported, source], work / 'image-export.log')
                    image_path = exported / 'images' / (symbols[classname] + '_' + classname + '.png')
                    config = json.loads((exported / 'binaryData' / (symbols[config_class] + '_' + config_class + '.bin')).read_text(encoding='utf-8-sig'))
                    with Image.open(image_path) as image:
                        # Official FIGHT window: 60 x 60 centered on config x/y, scaleRate=1.
                        left, top = math.ceil(config['x'] - 30), math.ceil(config['y'] - 30)
                        crop = [left, top, left + 60, top + 60]
                        prepared = image.convert('RGBA').crop(crop)
                else:
                    if not exported.exists():
                        run([args.ffdec, '-select', '1', '-selectid', symbols[classname], '-export', 'sprite', exported, source], work / 'image-export.log')
                    candidates = list(exported.rglob('*.png'))
                    if len(candidates) != 1:
                        raise ValueError('Expected one exported symbol frame, got ' + str(len(candidates)))
                    with Image.open(candidates[0]) as image:
                        prepared = image.convert('RGBA')
                target.parent.mkdir(parents=True, exist_ok=True)
                temporary = target.with_suffix('.tmp.png')
                prepared.save(temporary)
                prepared.close()
                temporary.replace(target)
                entry = {'category': category, 'id': identifier, 'path': category + '/' + str(identifier) + '.png', 'url': url, 'version': version, 'class': classname, 'sourceSha256': inspection['sha256'], 'sourceSize': inspection['file_size'], 'imageSha256': hashlib.sha256(target.read_bytes()).hexdigest(), 'crop': crop}
                write_json(work / 'provenance.json', entry)
                results.append(entry)
                print(key + ': prepared', flush=True)
            except ValueError as error:
                missing.append({'key': key, 'reason': str(error)})
                print(key + ': needs confirmation: ' + str(error), flush=True)
            except (OSError, RuntimeError, KeyError, subprocess.TimeoutExpired) as error:
                failures.append({'key': key, 'reason': str(error)})
                print(key + ': failed: ' + str(error), flush=True)
    successful = {(x['category'], x['id']) for x in results}
    results.extend(x for pair, x in previous.items() if pair not in successful)
    request.update({'schemaVersion': 1, 'assets': results, 'missing': missing, 'failures': failures})
    write_json(root / 'analysis/AolaLoader/Resources/Data/battle-assistant-assets.json', request)
    write_json(evidence / 'report.json', {'successful': len(successful), 'missing': missing, 'failures': failures})
    print(f'Prepared/cached: {len(successful)}; missing: {len(missing)}; failed: {len(failures)}', flush=True)
    return 1 if missing or failures else 0


if __name__ == '__main__':
    raise SystemExit(main())
