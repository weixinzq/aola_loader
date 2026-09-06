"""Stable public data models."""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Literal

TransportMode = Literal["auto", "wss", "tcp"]


@dataclass(frozen=True, slots=True)
class AccountProfile:
    label: str
    account: str = field(repr=False)
    password: str = field(repr=False)
    zone_index: int


@dataclass(frozen=True, slots=True)
class Zone:
    zone_index: int
    zone_name: str
    host: str
    wss_port: int
    tcp_port: int
    domain: str


@dataclass(frozen=True, slots=True)
class LoginSession:
    user_id: int
    session_id: str = field(repr=False)
    zones: tuple[Zone, ...]


@dataclass(frozen=True, slots=True)
class ReceivedMessage:
    received_at: datetime
    message_type: int
    action: int | None
    extension_id: int | None
    command: str | None
    payload: Any


@dataclass(frozen=True, slots=True)
class SendReceipt:
    extension_id: int
    command: str
    outer_sequence: int
    inner_sequence: int
    submitted_at: datetime


@dataclass(frozen=True, slots=True)
class SendMessage:
    extension_id: int
    command: str
    parameters: dict[str, Any]
