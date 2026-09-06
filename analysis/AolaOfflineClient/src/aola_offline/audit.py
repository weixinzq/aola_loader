"""Minimal metadata-only JSONL logging."""

from __future__ import annotations

import json
from datetime import UTC, datetime
from pathlib import Path
from typing import Any


class AuditLog:
    def __init__(self, directory: str | Path = "logs") -> None:
        self._directory = Path(directory)

    def write(self, event: str, *, label: str, **metadata: Any) -> None:
        self._directory.mkdir(parents=True, exist_ok=True)
        path = self._directory / f"runtime-{datetime.now(UTC):%Y%m%d}.jsonl"
        record = {
            "timestampUtc": datetime.now(UTC).isoformat(),
            "event": event,
            "label": label,
            **metadata,
        }
        with path.open("a", encoding="utf-8", newline="\n") as stream:
            stream.write(json.dumps(record, ensure_ascii=False, separators=(",", ":")))
            stream.write("\n")

