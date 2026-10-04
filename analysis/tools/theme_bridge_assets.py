"""Build theme leaf namespaces and targeted control-bar p-code patches."""

from pathlib import Path
import argparse
import re
import struct
import sys

sys.path.insert(0, str(Path(__file__).parent))
from petfight_bridge_abc import Reader, decode_swf


def u30(value):
    result = bytearray()
    while value >= 128:
        result.append((value & 127) | 128)
        value >>= 7
    result.append(value)
    return bytes(result)


def rename_abc(data, prefix, root_name=None):
    reader = Reader(data)
    reader.take(4)
    for width in (None, None, 8):
        count = reader.u30()
        for _ in range(1, count):
            reader.take(width) if width else reader.u32v()
    start = reader.offset
    count = reader.u30()
    values = [reader.take(reader.u30()) for _ in range(1, count)]
    end = reader.offset
    renamed = []
    for value in values:
        text = value.decode('utf-8', errors='replace')
        if root_name and text == 'Skin9':
            value = root_name.encode('utf-8')
        if (text.startswith('skin') and '_fla' in text or text == 'mmo.controlv2.controlbarskin.skin'
                or text == 'mmo.control' or text.startswith('mmo.control.')):
            value = (prefix + '.' + text).encode('utf-8')
        renamed.append(u30(len(value)) + value)
    return data[:start] + u30(count) + b''.join(renamed) + data[end:]


def theme_asset(source, target, theme, root_name=None):
    _, fws = decode_swf(source.read_bytes())
    reader = Reader(fws)
    reader.take(8)
    bits = fws[8] >> 3
    reader.take((5 + bits * 4 + 7) // 8 + 4)
    header_end = reader.offset
    tags = []
    prefix = 'aola.theme.t' + str(theme)
    while reader.offset < len(fws):
        tag = reader.u16()
        code, length = tag >> 6, tag & 63
        if length == 63:
            length = reader.u32()
        body = reader.take(length)
        if code == 82:
            split = body.index(b'\0', 4) + 1
            body = body[:split] + rename_abc(body[split:], prefix, root_name)
        elif code == 76:
            sr = Reader(body)
            count = sr.u16()
            parts = [struct.pack('<H', count)]
            for _ in range(count):
                identifier = sr.u16()
                begin = sr.offset
                while sr.u8() != 0:
                    pass
                name = body[begin:sr.offset - 1].decode('utf-8')
                if root_name and name == 'mmo.controlv2.controlbarskin.skin.Skin9':
                    name = 'mmo.controlv2.controlbarskin.skin.' + root_name
                if name.startswith('skin') or name.startswith('mmo.controlv2.controlbarskin.skin.') or name.startswith('mmo.control.'):
                    name = prefix + '.' + name
                parts.append(struct.pack('<H', identifier) + name.encode('utf-8') + b'\0')
            body = b''.join(parts)
        tags.append(struct.pack('<HI', (code << 6) | 63, len(body)) + body)
    result = fws[:header_end] + b''.join(tags)
    result = result[:4] + struct.pack('<I', len(result)) + result[8:]
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(result)


def handler_binding_patches(source, target):
    """Restore the official interface-qualified call after AS3 recompilation."""
    text = source.read_text(encoding='utf-8-sig')
    target.mkdir(parents=True, exist_ok=True)
    for signature, name in (('public function ControlBarSkinHandler(', '$iinit'),
                            ('public function refreshUsingControlBarSkin(', 'refreshUsingControlBarSkin')):
        method = text[text.index(signature):]
        method = method[re.search(r'(?m)^\s*method\s*$', method).start():]
        method = method[:re.search(r'(?m)^\s*end ; method\s*$', method).end()]
        method, count = re.subn(r'callproperty Multiname\("getUsingSkinId",[^\n]+\), 0',
            'callproperty QName(Namespace("mmo.interfaces.material.controlbarskin:IControlBarSkinService"),"getUsingSkinId"), 0', method)
        assert count == 1
        (target / (name.replace('$', '') + '.pcode')).write_text(
            '\n'.join(line.strip() for line in method.splitlines()) + '\n', encoding='utf-8')
        print(name)


def listener_patches(source, target):
    """Spill arguments into fresh locals; track paired listener registration."""
    text = source.read_text(encoding='utf-8-sig')
    target.mkdir(parents=True, exist_ok=True)
    signatures = list(re.finditer(r'(?m)^\s*(?:override\s+)?(?:public|private|protected).*?function (\w+)\(', text))
    result = []
    class_name = source.stem
    for i, signature in enumerate(signatures):
        section = text[signature.end():signatures[i + 1].start() if i + 1 < len(signatures) else len(text)]
        begin = re.search(r'(?m)^\s*method\s*$', section)
        end = re.search(r'(?m)^\s*end ; method\s*$', section)
        if not begin or not end:
            continue
        method = section[begin.start():end.end()]
        owner_scope = class_name == 'ControlBarSkinBase' and signature[1] in (class_name, 'addToStage')
        if not owner_scope and not re.search(r'callpropvoid QName\([^\n]+,"(?:add|remove)EventListener"\)', method):
            continue
        local_count = int(re.search(r'localcount (\d+)', method)[1])
        def replace(match):
            action, argc = match[1], int(match[2])
            lines = ['setlocal ' + str(local_count + j) for j in range(argc, -1, -1)]
            lines += ['getlex QName(PackageNamespace("mmo.controlv2.controlbarskin"),"ControlBarSkinHandler")', 'getlocal0']
            lines += ['getlocal ' + str(local_count + j) for j in range(argc + 1)]
            lines += ['callpropvoid QName(PackageNamespace(""),"track' + action.title() + 'Listener"), ' + str(argc + 2)]
            return '\n'.join(lines)
        method = re.sub(r'callpropvoid QName\([^\n]+,"(add|remove)EventListener"\), (\d+)', replace, method)
        if owner_scope:
            enter = '\ngetlex QName(PackageNamespace("mmo.controlv2.controlbarskin"),"ControlBarSkinHandler")\ngetlocal0\ncallpropvoid QName(PackageNamespace(""),"beginThemeOwner"), 1\n'
            leave = 'getlex QName(PackageNamespace("mmo.controlv2.controlbarskin"),"ControlBarSkinHandler")\ncallpropvoid QName(PackageNamespace(""),"endThemeOwner"), 0\n'
            if signature[1] == class_name:
                method = re.sub(r'constructsuper 0', lambda m: m[0] + enter, method, count=1)
            else:
                method = re.sub(r'(?m)^(\s*)code\s*$', lambda m: m[0] + enter, method, count=1)
                method = re.sub(r'findpropstrict QName\(PackageNamespace\("mmo.controlv2.lock"\),"ControlBarLockHelper"\)\s+getlocal0\s+getproperty ([^\n]+)\s+constructprop QName\(PackageNamespace\("mmo.controlv2.lock"\),"ControlBarLockHelper"\), 1\s+pop',
                    lambda m: 'getlex QName(PackageNamespace("mmo.controlv2.controlbarskin"),"ControlBarSkinHandler")\ngetlocal0\ngetlocal0\ngetproperty ' + m[1].strip() + '\ncallpropvoid QName(PackageNamespace(""),"initThemeLock"), 2', method)
            method = re.sub(r'(?m)^(\s*)(returnvoid|returnvalue)\s*$', lambda m: leave + m[2], method)
        method = re.sub(r'localcount \d+', 'localcount ' + str(local_count + 7), method, count=1)
        method = re.sub(r'maxstack (\d+)', lambda m: 'maxstack ' + str(int(m[1]) + 3), method, count=1)
        name = '$iinit' if signature[1] == class_name else signature[1]
        file = target / (name.replace('$', '') + '.pcode')
        file.write_text('\n'.join(line.strip() for line in method.splitlines()) + '\n', encoding='utf-8')
        result.append(name)
    print('\n'.join(result))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('mode', choices=['theme', 'listeners', 'handler-bindings'])
    parser.add_argument('source', type=Path)
    parser.add_argument('target', type=Path)
    parser.add_argument('--theme', type=int)
    parser.add_argument('--root-name')
    args = parser.parse_args()
    if args.mode == 'theme':
        theme_asset(args.source, args.target, args.theme, args.root_name)
    elif args.mode == 'handler-bindings':
        handler_binding_patches(args.source, args.target)
    else:
        listener_patches(args.source, args.target)
