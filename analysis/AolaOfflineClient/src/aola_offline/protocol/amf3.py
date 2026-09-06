"""Bounded AMF3 subset used by the current Aola protocol."""

from __future__ import annotations

import struct
from dataclasses import dataclass, field
from typing import Any

from ..errors import ProtocolError

UNDEFINED = 0
NULL = 1
FALSE = 2
TRUE = 3
INTEGER = 4
DOUBLE = 5
STRING = 6
ARRAY = 9
OBJECT = 10
BYTE_ARRAY = 12


def _write_u29(buffer: bytearray, value: int) -> None:
    value &= 0x3FFFFFFF
    if value < 0x80:
        buffer.append(value)
    elif value < 0x4000:
        buffer.extend((((value >> 7) & 0x7F) | 0x80, value & 0x7F))
    elif value < 0x200000:
        buffer.extend(
            (
                ((value >> 14) & 0x7F) | 0x80,
                ((value >> 7) & 0x7F) | 0x80,
                value & 0x7F,
            )
        )
    else:
        buffer.extend(
            (
                ((value >> 22) & 0x7F) | 0x80,
                ((value >> 15) & 0x7F) | 0x80,
                ((value >> 8) & 0x7F) | 0x80,
                value & 0xFF,
            )
        )


class Amf3Writer:
    def __init__(self) -> None:
        self._buffer = bytearray()
        self._strings: dict[str, int] = {}

    def to_bytes(self) -> bytes:
        return bytes(self._buffer)

    def _write_string_data(self, value: str) -> None:
        if value == "":
            _write_u29(self._buffer, 1)
            return
        reference = self._strings.get(value)
        if reference is not None:
            _write_u29(self._buffer, reference << 1)
            return
        self._strings[value] = len(self._strings)
        encoded = value.encode("utf-8")
        _write_u29(self._buffer, (len(encoded) << 1) | 1)
        self._buffer.extend(encoded)

    def write(self, value: Any) -> None:
        if value is None:
            self._buffer.append(NULL)
        elif isinstance(value, bool):
            self._buffer.append(TRUE if value else FALSE)
        elif isinstance(value, int):
            if -0x10000000 <= value <= 0x0FFFFFFF:
                self._buffer.append(INTEGER)
                _write_u29(self._buffer, value & 0x1FFFFFFF)
            else:
                self._buffer.append(DOUBLE)
                self._buffer.extend(struct.pack(">d", float(value)))
        elif isinstance(value, float):
            self._buffer.append(DOUBLE)
            self._buffer.extend(struct.pack(">d", value))
        elif isinstance(value, str):
            self._buffer.append(STRING)
            self._write_string_data(value)
        elif isinstance(value, (bytes, bytearray, memoryview)):
            data = bytes(value)
            self._buffer.append(BYTE_ARRAY)
            _write_u29(self._buffer, (len(data) << 1) | 1)
            self._buffer.extend(data)
        elif isinstance(value, (list, tuple)):
            self._buffer.append(ARRAY)
            _write_u29(self._buffer, (len(value) << 1) | 1)
            self._write_string_data("")
            for item in value:
                self.write(item)
        elif isinstance(value, dict):
            self._buffer.append(OBJECT)
            _write_u29(self._buffer, 11)  # inline, dynamic, zero sealed members
            self._write_string_data("")
            for key, item in value.items():
                if not isinstance(key, str):
                    raise ProtocolError("AMF3 对象键必须是字符串")
                self._write_string_data(key)
                self.write(item)
            self._write_string_data("")
        else:
            raise ProtocolError(f"不支持的 AMF3 类型：{type(value).__name__}")


@dataclass(slots=True)
class _Traits:
    dynamic: bool
    externalizable: bool
    properties: list[str] = field(default_factory=list)


class Amf3Reader:
    def __init__(self, data: bytes | bytearray | memoryview, offset: int = 0) -> None:
        self._data = memoryview(data)
        if offset < 0 or offset > len(self._data):
            raise ProtocolError("AMF3 起始位置越界")
        self._position = offset
        self._strings: list[str] = []
        self._objects: list[Any] = []
        self._traits: list[_Traits] = []

    @property
    def position(self) -> int:
        return self._position

    @property
    def remaining(self) -> int:
        return len(self._data) - self._position

    def _read_byte(self) -> int:
        if self._position >= len(self._data):
            raise ProtocolError("AMF3 数据意外结束")
        value = self._data[self._position]
        self._position += 1
        return int(value)

    def _read_bytes(self, count: int) -> bytes:
        if count < 0 or self._position + count > len(self._data):
            raise ProtocolError("AMF3 数据意外结束")
        value = self._data[self._position : self._position + count].tobytes()
        self._position += count
        return value

    def _read_u29(self) -> int:
        first = self._read_byte()
        if first < 0x80:
            return first
        value = (first & 0x7F) << 7
        second = self._read_byte()
        if second < 0x80:
            return value | second
        value = (value | (second & 0x7F)) << 7
        third = self._read_byte()
        if third < 0x80:
            return value | third
        value = (value | (third & 0x7F)) << 8
        return value | self._read_byte()

    @staticmethod
    def _reference(items: list[Any], index: int, kind: str) -> Any:
        try:
            return items[index]
        except IndexError as exc:
            raise ProtocolError(f"无效 AMF3 {kind} 引用：{index}") from exc

    def _read_string(self) -> str:
        reference = self._read_u29()
        if (reference & 1) == 0:
            return self._reference(self._strings, reference >> 1, "字符串")
        length = reference >> 1
        if length == 0:
            return ""
        try:
            value = self._read_bytes(length).decode("utf-8")
        except UnicodeDecodeError as exc:
            raise ProtocolError("AMF3 字符串不是有效 UTF-8") from exc
        self._strings.append(value)
        return value

    def _read_traits(self, reference: int) -> _Traits:
        if (reference & 3) == 1:
            return self._reference(self._traits, reference >> 2, "traits")
        traits = _Traits(
            dynamic=(reference & 8) != 0,
            externalizable=(reference & 4) != 0,
        )
        count = reference >> 4
        self._read_string()  # class name
        traits.properties.extend(self._read_string() for _ in range(count))
        self._traits.append(traits)
        return traits

    def _read_array(self) -> Any:
        reference = self._read_u29()
        if (reference & 1) == 0:
            return self._reference(self._objects, reference >> 1, "对象")
        count = reference >> 1
        key = self._read_string()
        if key == "":
            values: list[Any] = []
            self._objects.append(values)
            values.extend(self.read() for _ in range(count))
            return values
        values_map: dict[str, Any] = {}
        self._objects.append(values_map)
        while key:
            values_map[key] = self.read()
            key = self._read_string()
        for index in range(count):
            values_map[str(index)] = self.read()
        return values_map

    def _read_object(self) -> Any:
        reference = self._read_u29()
        if (reference & 1) == 0:
            return self._reference(self._objects, reference >> 1, "对象")
        traits = self._read_traits(reference)
        result: dict[str, Any] = {}
        object_index = len(self._objects)
        self._objects.append(result)
        if traits.externalizable:
            external = self.read()
            self._objects[object_index] = external
            return external
        for name in traits.properties:
            result[name] = self.read()
        if traits.dynamic:
            while True:
                name = self._read_string()
                if not name:
                    break
                result[name] = self.read()
        return result

    def _read_byte_array(self) -> bytes:
        reference = self._read_u29()
        if (reference & 1) == 0:
            value = self._reference(self._objects, reference >> 1, "字节数组")
            if not isinstance(value, bytes):
                raise ProtocolError("AMF3 字节数组引用类型不正确")
            return value
        value = self._read_bytes(reference >> 1)
        self._objects.append(value)
        return value

    def read(self) -> Any:
        marker = self._read_byte()
        if marker in (UNDEFINED, NULL):
            return None
        if marker == FALSE:
            return False
        if marker == TRUE:
            return True
        if marker == INTEGER:
            value = self._read_u29()
            return value - 0x20000000 if value >= 0x10000000 else value
        if marker == DOUBLE:
            return struct.unpack(">d", self._read_bytes(8))[0]
        if marker == STRING:
            return self._read_string()
        if marker == ARRAY:
            return self._read_array()
        if marker == OBJECT:
            return self._read_object()
        if marker == BYTE_ARRAY:
            return self._read_byte_array()
        raise ProtocolError(f"不支持的 AMF3 标记：{marker}")


def encode_amf3(value: Any) -> bytes:
    writer = Amf3Writer()
    writer.write(value)
    return writer.to_bytes()


def decode_amf3(data: bytes, *, require_eof: bool = True) -> Any:
    reader = Amf3Reader(data)
    value = reader.read()
    if require_eof and reader.remaining:
        raise ProtocolError(f"AMF3 对象后仍有 {reader.remaining} 字节")
    return value

