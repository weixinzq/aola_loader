"""Aola binary protocol primitives."""

from .amf3 import Amf3Reader, Amf3Writer, decode_amf3, encode_amf3
from .codec import (
    MAX_FRAME_SIZE,
    EncodedFrame,
    ProtocolState,
    build_extension_frame,
    build_login_frame,
    parse_server_frame,
)

__all__ = [
    "Amf3Reader",
    "Amf3Writer",
    "EncodedFrame",
    "MAX_FRAME_SIZE",
    "ProtocolState",
    "build_extension_frame",
    "build_login_frame",
    "decode_amf3",
    "encode_amf3",
    "parse_server_frame",
]

