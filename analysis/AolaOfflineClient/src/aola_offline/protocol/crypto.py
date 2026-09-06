"""Outer packet XOR and inner extension encryption."""

from __future__ import annotations

import struct

INNER_MASK = 0x1FFFFFFC


def outer_xor(data: bytes, sequence: int) -> bytes:
    key = struct.pack(">I", sequence & 0xFFFFFFFF)
    return bytes(value ^ key[index & 3] for index, value in enumerate(data))


def _inner_key(sequence: int) -> tuple[int, int, int, int]:
    value = (sequence & INNER_MASK) >> 2
    return (
        (value >> 22) & 0xFF,
        (value >> 18) & 0xFF,
        (value >> 9) & 0xFF,
        (value >> 2) & 0xFF,
    )


def encrypt_inner(sequence: int, plain: bytes) -> bytes:
    result = bytearray(plain)
    key = _inner_key(sequence)
    for index in range(len(result)):
        result[index] ^= key[index & 3]
    for block in range(len(result) // 4):
        index = block * 4 + (block & 1)
        result[index], result[index + 2] = result[index + 2], result[index]
    return bytes(result)


def decrypt_inner(sequence: int, encrypted: bytes) -> bytes:
    result = bytearray(encrypted)
    for block in range(len(result) // 4 - 1, -1, -1):
        index = block * 4 + (block & 1)
        result[index], result[index + 2] = result[index + 2], result[index]
    key = _inner_key(sequence)
    for index in range(len(result)):
        result[index] ^= key[index & 3]
    return bytes(result)

