"""Generate the skin-id to Background-resource catalog from PetSkinConfig.as."""

from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path


ENTRY_RE = re.compile(
    r'''new\s+PetSkinInfo\(\s*(?P<resource>\d+)\s*,\s*"(?P<name>(?:\\.|[^"])*)"\s*,\s*[^,]+,\s*(?P<skin>\d+)\s*,\s*(?P<background>true|false)\s*,\s*(?P<show>true|false)''',
    re.DOTALL,
)


def generate(source: Path, destination: Path) -> None:
    source_bytes = source.read_bytes()
    source_text = source_bytes.decode("utf-8")
    matches = list(ENTRY_RE.finditer(source_text))
    if not matches:
        raise ValueError(f"{source}: no PetSkinInfo entries found")

    entries = []
    for match in matches:
        resource_id = int(match.group("resource"))
        skin_id = int(match.group("skin"))
        entries.append(
            {
                "skinId": skin_id,
                "resourceId": resource_id,
                "name": match.group("name"),
                "hasBackground": match.group("background") == "true",
                "showPet": match.group("show") == "true",
            }
        )

    backgrounds = [entry for entry in entries if entry["hasBackground"]]
    background_skin_ids = [entry["skinId"] for entry in backgrounds]
    background_resource_ids = [entry["resourceId"] for entry in backgrounds]
    if len(background_skin_ids) != len(set(background_skin_ids)):
        raise ValueError(f"{source}: duplicate skin id in background entries")
    if len(background_resource_ids) != len(set(background_resource_ids)):
        raise ValueError(f"{source}: duplicate resource id in background entries")
    document = {
        "schemaVersion": 1,
        "source": source.name,
        "sourceSha256": hashlib.sha256(source_bytes).hexdigest(),
        "entryCount": len(entries),
        "backgroundCount": len(backgrounds),
        "entries": backgrounds,
    }
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(
        json.dumps(document, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    print(
        f"generated {len(backgrounds)} background mappings from {len(entries)} entries "
        f"to {destination}"
    )


def main() -> int:
    if len(sys.argv) != 3:
        print(
            "usage: generate_pet_poster_catalog.py PET_SKIN_CONFIG.as OUTPUT.json",
            file=sys.stderr,
        )
        return 2
    generate(Path(sys.argv[1]), Path(sys.argv[2]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
