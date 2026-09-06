"""Frame encoding, sequence ownership and server-message decoding."""

from __future__ import annotations

import copy
import secrets
import struct
from collections.abc import Callable, Mapping
from dataclasses import dataclass
from datetime import UTC, datetime
from typing import Any

from ..errors import ProtocolError
from ..models import ReceivedMessage
from .amf3 import decode_amf3, encode_amf3
from .as3 import as3_remainder, hash_as3_string, to_int32
from .crypto import INNER_MASK, encrypt_inner, outer_xor

MAX_FRAME_SIZE = 16 * 1024 * 1024
INNER_NOT_MASK = 0xE0000003
MESSAGE_TYPE_SYSTEM = 0
MESSAGE_TYPE_EXTENSION = 1
ACTION_LOGIN = 10016
ACTION_EXTENSION_REQUEST = 10033


def _pack_utf(value: str) -> bytes:
    encoded = value.encode("utf-8")
    if len(encoded) > 0xFFFF:
        raise ProtocolError("UTF 字段超过 65535 字节")
    return struct.pack(">H", len(encoded)) + encoded


def _validate_frame_size(body: bytes) -> None:
    if not body or len(body) > MAX_FRAME_SIZE:
        raise ProtocolError(f"帧体长度无效：{len(body)}")


@dataclass(frozen=True, slots=True)
class EncodedFrame:
    data: bytes
    outer_sequence: int
    inner_sequence: int | None


class ProtocolState:
    def __init__(
        self,
        user_id: int,
        session_id: str,
        *,
        randbelow: Callable[[int], int] = secrets.randbelow,
    ) -> None:
        if user_id <= 0 or not session_id:
            raise ProtocolError("协议状态需要有效用户 ID 和会话凭据")
        self.user_id = user_id
        self._session_hash = hash_as3_string(session_id)
        self._last_outer = 0
        self._inner_sequences: dict[int, int] = {}
        self._randbelow = randbelow

    def next_outer(self) -> int:
        if self._last_outer == 0:
            value = 79
        else:
            value = (
                self._last_outer * 7
                + as3_remainder(self.user_id, 991)
                + as3_remainder(self._session_hash, 569)
            )
            if value >= 0x7FFFFFFF:
                value = as3_remainder(value, 1047483647) + 911
            value = to_int32(value)
        self._last_outer = value
        return value

    def next_inner(self, extension_id: int) -> int:
        previous = self._inner_sequences.get(extension_id)
        if previous is None:
            base = 18
        else:
            real = (previous & INNER_MASK) >> 2
            candidate = real * 2 + as3_remainder(self.user_id, 108)
            base = candidate if candidate < 123216728 else 204
        random0 = self._randbelow(65535)
        random1 = self._randbelow(65535)
        random2 = self._randbelow(4)
        temporary = to_int32((random0 << 17) + (random1 << 2) + random2)
        value = to_int32((temporary & INNER_NOT_MASK) | (base << 2))
        self._inner_sequences[extension_id] = value
        return value


def build_login_frame(zone: str, user_id: int, session_id: str) -> EncodedFrame:
    if user_id <= 0 or not session_id:
        raise ProtocolError("登录帧需要有效用户 ID 和会话凭据")
    body = (
        bytes((MESSAGE_TYPE_SYSTEM,))
        + struct.pack(">H", ACTION_LOGIN)
        + struct.pack(">i", -1)
        + _pack_utf(zone)
        + _pack_utf(str(user_id))
        + _pack_utf(session_id)
    )
    _validate_frame_size(body)
    return EncodedFrame(
        data=struct.pack(">II", len(body) + 4, 0) + body,
        outer_sequence=0,
        inner_sequence=None,
    )


def build_extension_frame(
    state: ProtocolState,
    extension_id: int,
    command: str,
    parameters: Mapping[str, Any],
    room_id: int = -1,
) -> EncodedFrame:
    if isinstance(extension_id, bool) or not 0 <= extension_id <= 0xFFFF:
        raise ProtocolError("extension_id 必须在 0..65535 范围内")
    if not isinstance(command, str) or not command.strip():
        raise ProtocolError("command 必须是非空字符串")
    if not isinstance(parameters, Mapping):
        raise ProtocolError("parameters 必须是对象")
    if isinstance(room_id, bool) or not -(1 << 31) <= room_id < (1 << 31):
        raise ProtocolError("room_id 必须是有符号 32 位整数")

    inner_sequence = state.next_inner(extension_id)
    clean_parameters = copy.deepcopy(dict(parameters))
    clean_parameters.pop(":ext_seq;", None)
    clean_parameters[":ext_seq;"] = inner_sequence
    encrypted_parameters = encrypt_inner(
        inner_sequence, encode_amf3(clean_parameters)
    )
    wrapper = encode_amf3({"data": encrypted_parameters})
    body = (
        bytes((MESSAGE_TYPE_EXTENSION,))
        + struct.pack(">H", ACTION_EXTENSION_REQUEST)
        + struct.pack(">i", room_id)
        + struct.pack(">H", extension_id)
        + _pack_utf(command)
        + wrapper
    )
    _validate_frame_size(body)
    outer_sequence = state.next_outer()
    encrypted_body = outer_xor(body, outer_sequence)
    return EncodedFrame(
        data=struct.pack(">II", len(encrypted_body) + 4, outer_sequence & 0xFFFFFFFF)
        + encrypted_body,
        outer_sequence=outer_sequence,
        inner_sequence=inner_sequence,
    )


def parse_server_frame(frame: bytes) -> ReceivedMessage:
    if len(frame) < 5:
        raise ProtocolError("服务端帧短于最小长度")
    declared = struct.unpack_from(">I", frame, 0)[0]
    if declared != len(frame) - 4:
        raise ProtocolError(
            f"服务端帧长度不匹配：declared={declared}, actual={len(frame) - 4}"
        )
    if declared <= 0 or declared > MAX_FRAME_SIZE:
        raise ProtocolError(f"服务端帧长度无效：{declared}")

    body = frame[4:]
    message_type = body[0]
    action: int | None = None
    extension_id: int | None = None
    command: str | None = None
    payload: Any
    if message_type == MESSAGE_TYPE_EXTENSION:
        payload = decode_amf3(body[1:])
        if isinstance(payload, dict):
            raw_command = payload.get("_cmd")
            if raw_command is not None:
                command = str(raw_command)
            raw_extension = payload.get("_ext_id")
            if isinstance(raw_extension, int) and not isinstance(raw_extension, bool):
                extension_id = raw_extension
    elif message_type == MESSAGE_TYPE_SYSTEM:
        if len(body) < 7:
            raise ProtocolError("SYS 服务端帧短于 action/roomId 头")
        action = struct.unpack_from(">H", body, 1)[0]
        room_id = struct.unpack_from(">i", body, 3)[0]
        payload = {"room_id": room_id, "raw": body[7:]}
    else:
        payload = {"raw": body[1:]}

    return ReceivedMessage(
        received_at=datetime.now(UTC),
        message_type=message_type,
        action=action,
        extension_id=extension_id,
        command=command,
        payload=payload,
    )

