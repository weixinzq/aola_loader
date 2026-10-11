"""Build uncompressed SWF templates for Aola Loader's skin resource override."""

from __future__ import annotations

import lzma
import sys
from pathlib import Path


def decode_swf(path: Path) -> tuple[int, bytes]:
    data = path.read_bytes()
    if len(data) < 8:
        raise ValueError(f"{path}: SWF is too short")
    signature = data[:3]
    version = data[3]
    declared_length = int.from_bytes(data[4:8], "little")
    if signature == b"FWS":
        body = data[8:]
    elif signature == b"ZWS":
        if len(data) < 17:
            raise ValueError(f"{path}: ZWS header is too short")
        prop = data[12]
        lc = prop % 9
        remainder = prop // 9
        lp = remainder % 5
        pb = remainder // 5
        dictionary_size = int.from_bytes(data[13:17], "little")
        body = lzma.decompress(
            data[17:],
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
    else:
        raise ValueError(f"{path}: unsupported SWF signature {signature!r}")
    if len(body) + 8 != declared_length:
        raise ValueError(
            f"{path}: decoded length {len(body) + 8} != declared {declared_length}"
        )
    return version, body


def build_theme(source: Path, destination: Path, theme_id: int) -> None:
    version, body = decode_swf(source)
    class_name = f"Skin{theme_id}".encode("ascii")
    if body.count(class_name) == 0:
        raise ValueError(f"{source}: cannot find exported class {class_name.decode()}")
    output = b"FWS" + bytes([version]) + (len(body) + 8).to_bytes(4, "little") + body
    destination.write_bytes(output)
    print(f"theme {theme_id}: {source.name} -> {destination} ({len(output)} bytes)")


def main() -> int:
    if len(sys.argv) != 12:
        print("usage: build_theme_overrides.py OUTPUT_DIR SKIN0 ... SKIN9", file=sys.stderr)
        return 2
    output_dir = Path(sys.argv[1])
    output_dir.mkdir(parents=True, exist_ok=True)
    for theme_id, source_name in enumerate(sys.argv[2:]):
        build_theme(Path(source_name), output_dir / f"skin{theme_id}.swf", theme_id)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
