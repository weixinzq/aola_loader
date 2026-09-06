from __future__ import annotations

import hashlib
import json
import struct
import unittest
from pathlib import Path

from aola_offline.errors import ProtocolError
from aola_offline.protocol import (
    MAX_FRAME_SIZE,
    ProtocolState,
    build_extension_frame,
    build_login_frame,
    parse_server_frame,
)
from aola_offline.protocol.amf3 import decode_amf3, encode_amf3
from aola_offline.protocol.as3 import as3_remainder, hash_as3_string, to_int32
from aola_offline.protocol.crypto import decrypt_inner, encrypt_inner, outer_xor


ROOT = Path(__file__).resolve().parents[3]
VECTOR_PATH = Path(__file__).parent / "vectors" / "csharp_protocol_vectors.json"


class ProtocolTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.vector = json.loads(VECTOR_PATH.read_text(encoding="utf-8"))

    def test_vector_sources_still_match_csharp_reference(self) -> None:
        for path_key, hash_key in (
            ("protocol", "protocol_sha256"),
            ("amf3_writer", "amf3_writer_sha256"),
        ):
            path = ROOT / self.vector["source"][path_key]
            digest = hashlib.sha256(path.read_bytes()).hexdigest()
            self.assertEqual(self.vector["source"][hash_key], digest)

    def test_as3_signed_arithmetic_and_utf16_hash(self) -> None:
        self.assertEqual(-1, to_int32(0xFFFFFFFF))
        self.assertEqual(-1, as3_remainder(-10, 3))
        self.assertEqual(1, as3_remainder(10, -3))
        self.assertEqual(-1653894233, hash_as3_string("fixture-😀"))

    def test_csharp_outer_and_inner_sequence_vectors(self) -> None:
        identity = self.vector["identity"]
        random_values = iter(range(1, 10))
        state = ProtocolState(
            identity["user_id"],
            identity["session_id"],
            randbelow=lambda limit: next(random_values) % limit,
        )
        self.assertEqual(
            self.vector["outer_sequences"], [state.next_outer() for _ in range(3)]
        )
        self.assertEqual(
            self.vector["inner_sequences"],
            [state.next_inner(42), state.next_inner(42), state.next_inner(7)],
        )

    def test_amf3_matches_csharp_writer_and_round_trips(self) -> None:
        value = {"cmd": "fixture", "value": 18, "nested": {"ok": True}}
        encoded = encode_amf3(value)
        self.assertEqual(self.vector["amf_object_hex"], encoded.hex())
        self.assertEqual(value, decode_amf3(encoded))
        complex_value = {
            "none": None,
            "bools": [True, False],
            "negative": -268435456,
            "large": 268435456,
            "bytes": b"\x00\xff",
            "repeat": "same",
            "repeat2": "same",
        }
        self.assertEqual(complex_value, decode_amf3(encode_amf3(complex_value)))
        with self.assertRaises(ProtocolError):
            encode_amf3({"bad": {1, 2}})
        with self.assertRaises(ProtocolError):
            decode_amf3(b"\x06\x07x")

    def test_inner_crypto_matches_csharp_and_is_reversible(self) -> None:
        sequence = self.vector["inner_sequence_for_crypto"]
        plain = bytes.fromhex(self.vector["inner_plain_hex"])
        encrypted = encrypt_inner(sequence, plain)
        self.assertEqual(self.vector["inner_encrypted_hex"], encrypted.hex())
        self.assertEqual(plain, decrypt_inner(sequence, encrypted))
        self.assertEqual(plain, outer_xor(outer_xor(plain, 0x12345678), 0x12345678))

    def test_login_and_extension_frames_match_csharp_vectors(self) -> None:
        identity = self.vector["identity"]
        login = build_login_frame(
            identity["zone"], identity["user_id"], identity["session_id"]
        )
        self.assertEqual(self.vector["login_frame_hex"], login.data.hex())
        self.assertEqual(len(login.data) - 4, struct.unpack_from(">I", login.data)[0])

        extension = self.vector["extension"]
        random_values = iter((1, 2, 3))
        state = ProtocolState(
            identity["user_id"],
            identity["session_id"],
            randbelow=lambda limit: next(random_values) % limit,
        )
        encoded = build_extension_frame(
            state,
            extension["extension_id"],
            extension["command"],
            extension["parameters"],
        )
        self.assertEqual(extension["outer_sequence"], encoded.outer_sequence)
        self.assertEqual(extension["inner_sequence"], encoded.inner_sequence)
        self.assertEqual(extension["frame_hex"], encoded.data.hex())

        outer_sequence = struct.unpack_from(">I", encoded.data, 4)[0]
        body = outer_xor(encoded.data[8:], outer_sequence)
        self.assertEqual(1, body[0])
        self.assertEqual(10033, struct.unpack_from(">H", body, 1)[0])
        self.assertEqual(-1, struct.unpack_from(">i", body, 3)[0])
        self.assertEqual(42, struct.unpack_from(">H", body, 7)[0])
        command_size = struct.unpack_from(">H", body, 9)[0]
        command_end = 11 + command_size
        self.assertEqual("fixture_cmd", body[11:command_end].decode("utf-8"))
        wrapper = decode_amf3(body[command_end:])
        parameters = decode_amf3(
            decrypt_inner(extension["inner_sequence"], wrapper["data"])
        )
        self.assertEqual({"value": 7, ":ext_seq;": 75}, parameters)

    def test_server_ext_and_system_frames(self) -> None:
        body = b"\x01" + encode_amf3(
            {"_cmd": "fixtureOK", "_ext_id": 42, "value": 7}
        )
        message = parse_server_frame(struct.pack(">I", len(body)) + body)
        self.assertEqual("fixtureOK", message.command)
        self.assertEqual(42, message.extension_id)
        self.assertEqual(7, message.payload["value"])

        system_body = b"\x00" + struct.pack(">Hi", 10016, -1) + b"tail"
        system = parse_server_frame(
            struct.pack(">I", len(system_body)) + system_body
        )
        self.assertEqual(10016, system.action)
        self.assertEqual(-1, system.payload["room_id"])

    def test_malformed_and_oversized_frames_are_rejected(self) -> None:
        for frame in (b"", b"\x00\x00\x00\x02\x01", b"\x00\x00\x00\x01\x00"):
            with self.subTest(frame=frame.hex()), self.assertRaises(ProtocolError):
                parse_server_frame(frame)
        oversized_header = struct.pack(">I", MAX_FRAME_SIZE + 1) + b"\x01"
        with self.assertRaises(ProtocolError):
            parse_server_frame(oversized_header)
        with self.assertRaises(ProtocolError):
            build_extension_frame(
                ProtocolState(1, "sid"), 42, "cmd", {"blob": b"x" * MAX_FRAME_SIZE}
            )


if __name__ == "__main__":
    unittest.main()
