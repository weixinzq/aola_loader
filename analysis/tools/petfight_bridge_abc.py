#!/usr/bin/env python3
"""Inspect SWFs and locate AS3 method-body indexes for the battle bridge."""

from __future__ import annotations

import argparse
import hashlib
import json
import lzma
import struct
import zlib
from dataclasses import dataclass
from pathlib import Path


class ParseError(ValueError):
    pass


MAX_SWF_BYTES = 32 * 1024 * 1024
MAX_PRODUCTION_SWF_BYTES = 16 * 1024 * 1024
MANIFEST_FIELDS = {
    "schemaVersion",
    "resourceVersion",
    "officialUrl",
    "officialZwsSha256",
    "candidateFile",
    "candidateLength",
    "candidateSha256",
    "bridgeVersion",
    "symbolClassSha256",
}


class Reader:
    def __init__(self, data: bytes) -> None:
        self.data = data
        self.offset = 0

    def take(self, count: int) -> bytes:
        end = self.offset + count
        if count < 0 or end > len(self.data):
            raise ParseError(f"truncated data at offset {self.offset}")
        value = self.data[self.offset:end]
        self.offset = end
        return value

    def u8(self) -> int:
        return self.take(1)[0]

    def u16(self) -> int:
        return struct.unpack("<H", self.take(2))[0]

    def u32(self) -> int:
        return struct.unpack("<I", self.take(4))[0]

    def u30(self) -> int:
        value = self.u32v()
        if value > 0x3FFFFFFF:
            raise ParseError("u30 exceeds 30 bits")
        return value

    def u32v(self) -> int:
        value = 0
        for shift in range(0, 35, 7):
            byte = self.u8()
            value |= (byte & 0x7F) << shift
            if not byte & 0x80:
                return value & 0xFFFFFFFF
        raise ParseError("unterminated variable integer")


@dataclass(frozen=True)
class Namespace:
    kind: int
    name_index: int


@dataclass(frozen=True)
class Multiname:
    kind: int
    namespace_index: int = 0
    name_index: int = 0


def skip_traits(reader: Reader, count: int) -> list[tuple[int, int, int]]:
    methods: list[tuple[int, int, int]] = []
    for _ in range(count):
        name_index = reader.u30()
        kind_and_attributes = reader.u8()
        kind = kind_and_attributes & 0x0F
        if kind in (0, 6):
            reader.u30()
            reader.u30()
            value_index = reader.u30()
            if value_index:
                reader.u8()
        elif kind in (1, 2, 3):
            reader.u30()
            method_index = reader.u30()
            methods.append((name_index, kind, method_index))
        elif kind == 4:
            reader.u30()
            reader.u30()
        elif kind == 5:
            reader.u30()
            reader.u30()
        else:
            raise ParseError(f"unsupported trait kind {kind}")
        if kind_and_attributes & 0x40:
            for _ in range(reader.u30()):
                reader.u30()
    return methods


def multiname_text(
    index: int,
    strings: list[str],
    namespaces: list[Namespace],
    multinames: list[Multiname],
) -> str | None:
    if index <= 0 or index >= len(multinames):
        return None
    item = multinames[index]
    if item.kind not in (0x07, 0x0D):
        return None
    if item.namespace_index <= 0 or item.namespace_index >= len(namespaces):
        return None
    namespace = namespaces[item.namespace_index]
    if item.name_index <= 0 or item.name_index >= len(strings):
        return None
    local_name = strings[item.name_index]
    namespace_name = strings[namespace.name_index] if namespace.name_index < len(strings) else ""
    return f"{namespace_name}.{local_name}" if namespace_name else local_name


def parse_abc(data: bytes, targets: set[tuple[str, str]]) -> list[dict[str, int | str]]:
    reader = Reader(data)
    reader.u16()
    reader.u16()

    for width in ("u32v", "u32v"):
        count = reader.u30()
        for _ in range(1, count):
            getattr(reader, width)()
    double_count = reader.u30()
    for _ in range(1, double_count):
        reader.take(8)

    strings = [""]
    for _ in range(1, reader.u30()):
        strings.append(reader.take(reader.u30()).decode("utf-8", errors="replace"))

    namespaces = [Namespace(0, 0)]
    for _ in range(1, reader.u30()):
        namespaces.append(Namespace(reader.u8(), reader.u30()))

    for _ in range(1, reader.u30()):
        for _ in range(reader.u30()):
            reader.u30()

    multinames = [Multiname(0)]
    for _ in range(1, reader.u30()):
        kind = reader.u8()
        if kind in (0x07, 0x0D):
            multinames.append(Multiname(kind, reader.u30(), reader.u30()))
        elif kind in (0x0F, 0x10):
            multinames.append(Multiname(kind, name_index=reader.u30()))
        elif kind in (0x11, 0x12):
            multinames.append(Multiname(kind))
        elif kind in (0x09, 0x0E):
            name_index = reader.u30()
            reader.u30()
            multinames.append(Multiname(kind, name_index=name_index))
        elif kind in (0x1B, 0x1C):
            reader.u30()
            multinames.append(Multiname(kind))
        elif kind == 0x1D:
            reader.u30()
            for _ in range(reader.u30()):
                reader.u30()
            multinames.append(Multiname(kind))
        else:
            raise ParseError(f"unsupported multiname kind 0x{kind:02x}")

    method_names: list[str] = []
    method_count = reader.u30()
    for _ in range(method_count):
        parameter_count = reader.u30()
        reader.u30()
        for _ in range(parameter_count):
            reader.u30()
        name_index = reader.u30()
        method_names.append(strings[name_index] if name_index < len(strings) else "")
        flags = reader.u8()
        if flags & 0x08:
            for _ in range(reader.u30()):
                reader.u30()
                reader.u8()
        if flags & 0x80:
            for _ in range(parameter_count):
                reader.u30()

    for _ in range(reader.u30()):
        reader.u30()
        item_count = reader.u30()
        for _ in range(item_count * 2):
            reader.u30()

    class_count = reader.u30()
    target_methods: dict[int, tuple[str, str]] = {}
    for _ in range(class_count):
        class_name_index = reader.u30()
        reader.u30()
        flags = reader.u8()
        if flags & 0x08:
            reader.u30()
        for _ in range(reader.u30()):
            reader.u30()
        reader.u30()
        traits = skip_traits(reader, reader.u30())
        class_name = multiname_text(class_name_index, strings, namespaces, multinames)
        if class_name:
            for trait_name_index, _, method_index in traits:
                trait_name = multiname_text(trait_name_index, strings, namespaces, multinames)
                method_name = trait_name.rsplit(".", 1)[-1] if trait_name else ""
                if (class_name, method_name) in targets:
                    if method_index in target_methods:
                        raise ParseError(f"duplicate target method index {method_index}")
                    target_methods[method_index] = (class_name, method_name)

    for _ in range(class_count):
        reader.u30()
        skip_traits(reader, reader.u30())

    for _ in range(reader.u30()):
        reader.u30()
        skip_traits(reader, reader.u30())

    results: list[dict[str, int | str]] = []
    body_count = reader.u30()
    for body_index in range(body_count):
        method_index = reader.u30()
        reader.u30()
        reader.u30()
        reader.u30()
        reader.u30()
        reader.take(reader.u30())
        for _ in range(reader.u30()):
            for _ in range(5):
                reader.u30()
        skip_traits(reader, reader.u30())
        target = target_methods.get(method_index)
        if target:
            results.append(
                {
                    "className": target[0],
                    "methodName": target[1],
                    "methodIndex": method_index,
                    "methodBodyIndex": body_index,
                    "methodDebugName": method_names[method_index],
                }
            )
    return results


def decode_swf(data: bytes) -> tuple[dict[str, int | str | bool], bytes]:
    if len(data) < 8:
        raise ParseError("SWF is shorter than eight bytes")
    signature = data[:3]
    if signature not in (b"FWS", b"CWS", b"ZWS"):
        raise ParseError("unsupported SWF signature")
    version = data[3]
    declared_length = struct.unpack_from("<I", data, 4)[0]
    if declared_length < 8 or declared_length > MAX_SWF_BYTES:
        raise ParseError("declared SWF length is outside the allowed range")

    details: dict[str, int | str | bool] = {
        "signature": signature.decode("ascii"),
        "version": version,
        "fileSize": len(data),
        "declaredLength": declared_length,
        "sha256": hashlib.sha256(data).hexdigest(),
    }
    if signature == b"FWS":
        body = data[8:]
    elif signature == b"CWS":
        decoder = zlib.decompressobj()
        body = decoder.decompress(data[8:], declared_length - 8 + 1)
        body += decoder.flush()
        if decoder.unused_data or decoder.unconsumed_tail:
            raise ParseError("CWS contains trailing or unconsumed compressed data")
    else:
        if len(data) < 17:
            raise ParseError("truncated ZWS header")
        compressed_length = struct.unpack_from("<I", data, 8)[0]
        payload = data[17:]
        details["compressedLength"] = compressed_length
        if compressed_length != len(payload):
            raise ParseError("ZWS compressed-length field does not match payload")
        properties = data[12]
        dictionary_size = struct.unpack_from("<I", data, 13)[0]
        lc = properties % 9
        remainder = properties // 9
        lp = remainder % 5
        pb = remainder // 5
        if lc > 8 or lp > 4 or pb > 4 or lc + lp > 4:
            raise ParseError("invalid ZWS LZMA properties")
        details["lzmaProperties"] = properties
        details["lzmaDictionarySize"] = dictionary_size
        body = lzma.decompress(
            payload,
            format=lzma.FORMAT_RAW,
            filters=[
                {
                    "id": lzma.FILTER_LZMA1,
                    "dict_size": dictionary_size,
                    "lc": lc,
                    "lp": lp,
                    "pb": pb,
                }
            ],
        )

    decoded_length = len(body) + 8
    if decoded_length != declared_length:
        raise ParseError(
            f"decoded length {decoded_length} does not match declaration {declared_length}"
        )
    fws = b"FWS" + bytes([version]) + struct.pack("<I", declared_length) + body
    details["decodedLength"] = decoded_length
    details["lengthValid"] = True
    details["fwsSha256"] = hashlib.sha256(fws).hexdigest()
    return details, fws


def iter_doabc(fws: bytes):
    if len(fws) < 12 or fws[:3] != b"FWS":
        raise ParseError("input must be an uncompressed FWS file")
    declared_length = struct.unpack_from("<I", fws, 4)[0]
    if declared_length != len(fws):
        raise ParseError("FWS declared length does not match physical length")
    bit_count = fws[8] >> 3
    rect_length = (5 + 4 * bit_count + 7) // 8
    offset = 8 + rect_length + 4
    tag_index = 0
    while offset + 2 <= len(fws):
        header = struct.unpack_from("<H", fws, offset)[0]
        offset += 2
        tag_code = header >> 6
        tag_length = header & 0x3F
        if tag_length == 0x3F:
            if offset + 4 > len(fws):
                raise ParseError("truncated long tag header")
            tag_length = struct.unpack_from("<I", fws, offset)[0]
            offset += 4
        end = offset + tag_length
        if end > len(fws):
            raise ParseError(f"truncated tag {tag_index}")
        if tag_code == 82:
            payload = fws[offset:end]
            if len(payload) < 5:
                raise ParseError("truncated DoABC tag")
            name_end = payload.find(b"\0", 4)
            if name_end < 0:
                raise ParseError("DoABC tag has no name terminator")
            yield tag_index, payload[4:name_end].decode("utf-8", errors="replace"), payload[name_end + 1 :]
        offset = end
        tag_index += 1
        if tag_code == 0:
            break


def load_manifest(path: Path, production: bool) -> dict[str, int | str]:
    def reject_duplicates(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise ParseError(f"duplicate manifest field: {key}")
            result[key] = value
        return result

    document = json.loads(path.read_text(encoding="utf-8-sig"), object_pairs_hook=reject_duplicates)
    if not isinstance(document, dict) or set(document) != MANIFEST_FIELDS:
        raise ParseError("manifest fields do not match schema version 1")
    if type(document["schemaVersion"]) is not int or document["schemaVersion"] != 1:
        raise ParseError("unsupported manifest schemaVersion")
    if type(document["bridgeVersion"]) is not int or document["bridgeVersion"] != 4:
        raise ParseError("unsupported bridgeVersion")
    if type(document["candidateLength"]) is not int or not (
        8 <= document["candidateLength"] <= MAX_PRODUCTION_SWF_BYTES
    ):
        raise ParseError("candidateLength is invalid")

    version = document["resourceVersion"]
    if not isinstance(version, str) or not version.isascii() or not version.isdigit() or len(version) > 32:
        raise ParseError("resourceVersion is invalid")
    expected_url = f"https://aola.100bt.com/play/pet/petfightnew~{version}.swf"
    if document["officialUrl"] != expected_url:
        raise ParseError("officialUrl is not canonical")
    for field in ("officialZwsSha256", "candidateSha256", "symbolClassSha256"):
        value = document[field]
        if not isinstance(value, str) or len(value) != 64 or any(
            character not in "0123456789abcdef" for character in value
        ):
            raise ParseError(f"{field} is invalid")

    expected_candidate = (
        "petfightnew-battle-state-current.fws.swf"
        if production
        else f"..\\variants\\petfightnew-battle-state-{version}.fws.swf"
    )
    if document["candidateFile"] != expected_candidate:
        raise ParseError("candidateFile is not the expected exact filename")
    return document


def main() -> int:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)
    inspect_parser = subparsers.add_parser("inspect")
    inspect_parser.add_argument("--input", required=True, type=Path)
    unpack_parser = subparsers.add_parser("unpack")
    unpack_parser.add_argument("--input", required=True, type=Path)
    unpack_parser.add_argument("--output", required=True, type=Path)
    methods_parser = subparsers.add_parser("methods")
    methods_parser.add_argument("--input", required=True, type=Path)
    methods_parser.add_argument("--target", action="append", required=True, metavar="CLASS:METHOD")
    manifest_parser = subparsers.add_parser("manifest")
    manifest_parser.add_argument("--input", required=True, type=Path)
    manifest_parser.add_argument("--production", action="store_true")
    args = parser.parse_args()

    if args.command == "manifest":
        print(json.dumps(load_manifest(args.input, args.production), ensure_ascii=False, indent=2))
        return 0

    details, fws = decode_swf(args.input.read_bytes())
    if args.command == "inspect":
        print(json.dumps(details, ensure_ascii=False, indent=2))
        return 0
    if args.command == "unpack":
        if args.output.exists():
            raise ParseError(f"refusing to overwrite {args.output}")
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_bytes(fws)
        details["output"] = str(args.output.resolve())
        print(json.dumps(details, ensure_ascii=False, indent=2))
        return 0

    targets: set[tuple[str, str]] = set()
    for raw in args.target:
        if ":" not in raw:
            parser.error(f"invalid target: {raw}")
        class_name, method_name = raw.rsplit(":", 1)
        targets.add((class_name, method_name))

    matches: list[dict[str, int | str]] = []
    for abc_index, (tag_index, abc_name, abc_data) in enumerate(iter_doabc(fws)):
        for result in parse_abc(abc_data, targets):
            result["abcIndex"] = abc_index
            result["abcTagIndex"] = tag_index
            result["abcName"] = abc_name
            matches.append(result)

    counts = {target: 0 for target in targets}
    for match in matches:
        counts[(str(match["className"]), str(match["methodName"]))] += 1
    invalid = [f"{class_name}:{method_name}" for (class_name, method_name), count in counts.items() if count != 1]
    if invalid:
        raise ParseError("expected one match for: " + ", ".join(sorted(invalid)))

    print(json.dumps(matches, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
