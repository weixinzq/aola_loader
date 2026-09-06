"""Framed TCP and WSS transports with TLS verification enabled."""

from __future__ import annotations

import asyncio
import ssl
import struct
from typing import Any, Protocol

from .errors import ConnectionFailed, DisconnectedError, ProtocolError
from .models import TransportMode, Zone
from .protocol import MAX_FRAME_SIZE

MAX_POLICY_SIZE = 64 * 1024


class FrameTransport(Protocol):
    kind: str

    async def write(self, frame: bytes) -> None: ...

    async def read_frame(self) -> bytes: ...

    async def close(self) -> None: ...


class TcpTransport:
    kind = "tcp"

    def __init__(
        self, reader: asyncio.StreamReader, writer: asyncio.StreamWriter
    ) -> None:
        self._reader = reader
        self._writer = writer
        self._prefetched = bytearray()
        self._closed = False

    @classmethod
    async def open(cls, host: str, port: int, timeout: float) -> "TcpTransport":
        if not host or port <= 0:
            raise ConnectionFailed("区服没有可用 TCP 地址")
        try:
            reader, writer = await asyncio.wait_for(
                asyncio.open_connection(host, port), timeout=timeout
            )
        except (OSError, asyncio.TimeoutError) as exc:
            raise ConnectionFailed(f"TCP 连接失败：{type(exc).__name__}") from exc
        transport = cls(reader, writer)
        try:
            await transport._consume_policy_if_present()
        except BaseException:
            await transport.close()
            raise
        return transport

    async def _consume_policy_if_present(self) -> None:
        try:
            first = await asyncio.wait_for(self._reader.readexactly(1), timeout=0.25)
        except asyncio.TimeoutError:
            return
        except asyncio.IncompleteReadError as exc:
            raise DisconnectedError("TCP 在登录前关闭") from exc
        if first != b"<":
            self._prefetched.extend(first)
            return
        policy = bytearray(first)
        while len(policy) <= MAX_POLICY_SIZE:
            try:
                value = await asyncio.wait_for(
                    self._reader.readexactly(1), timeout=2.0
                )
            except (asyncio.TimeoutError, asyncio.IncompleteReadError) as exc:
                raise ProtocolError("Flash policy 响应未完整结束") from exc
            if value == b"\x00":
                return
            policy.extend(value)
        raise ProtocolError("Flash policy 响应超过 64 KiB")

    async def _read_exactly(self, count: int) -> bytes:
        result = bytearray()
        if self._prefetched:
            take = min(count, len(self._prefetched))
            result.extend(self._prefetched[:take])
            del self._prefetched[:take]
        if len(result) < count:
            try:
                result.extend(await self._reader.readexactly(count - len(result)))
            except asyncio.IncompleteReadError as exc:
                raise DisconnectedError("TCP 连接已关闭") from exc
        return bytes(result)

    async def write(self, frame: bytes) -> None:
        if self._closed:
            raise DisconnectedError("TCP 连接已关闭")
        try:
            self._writer.write(frame)
            await self._writer.drain()
        except (ConnectionError, OSError) as exc:
            raise DisconnectedError("TCP 写入失败") from exc

    async def read_frame(self) -> bytes:
        header = await self._read_exactly(4)
        length = struct.unpack(">I", header)[0]
        if length <= 0 or length > MAX_FRAME_SIZE:
            raise ProtocolError(f"TCP 帧长度无效：{length}")
        return header + await self._read_exactly(length)

    async def close(self) -> None:
        if self._closed:
            return
        self._closed = True
        self._writer.close()
        try:
            await self._writer.wait_closed()
        except (ConnectionError, OSError):
            pass


class WebSocketTransport:
    kind = "wss"

    def __init__(self, socket: Any) -> None:
        self._socket = socket
        self._buffer = bytearray()
        self._closed = False

    @classmethod
    async def open(cls, domain: str, port: int, timeout: float) -> "WebSocketTransport":
        if not domain or port <= 0:
            raise ConnectionFailed("区服没有可用 WSS 地址")
        try:
            import websockets

            socket = await websockets.connect(
                f"wss://{domain}:{port}",
                ssl=ssl.create_default_context(),
                origin="https://aola.100bt.com",
                ping_interval=None,
                open_timeout=timeout,
                max_size=MAX_FRAME_SIZE + 4,
            )
        except Exception as exc:
            raise ConnectionFailed(f"WSS 连接失败：{type(exc).__name__}") from exc
        return cls(socket)

    async def write(self, frame: bytes) -> None:
        if self._closed:
            raise DisconnectedError("WSS 连接已关闭")
        try:
            await self._socket.send(frame)
        except Exception as exc:
            raise DisconnectedError("WSS 写入失败") from exc

    async def _receive_chunk(self) -> None:
        try:
            chunk = await self._socket.recv()
        except Exception as exc:
            raise DisconnectedError("WSS 连接已关闭") from exc
        if not isinstance(chunk, (bytes, bytearray, memoryview)):
            raise ProtocolError("WSS 收到文本消息，预期二进制帧")
        self._buffer.extend(chunk)

    async def read_frame(self) -> bytes:
        while len(self._buffer) < 4:
            await self._receive_chunk()
        length = struct.unpack_from(">I", self._buffer, 0)[0]
        if length <= 0 or length > MAX_FRAME_SIZE:
            raise ProtocolError(f"WSS 帧长度无效：{length}")
        total = 4 + length
        while len(self._buffer) < total:
            await self._receive_chunk()
        frame = bytes(self._buffer[:total])
        del self._buffer[:total]
        return frame

    async def close(self) -> None:
        if self._closed:
            return
        self._closed = True
        try:
            await self._socket.close()
        except Exception:
            pass


async def open_transport(
    zone: Zone, mode: TransportMode = "auto", timeout: float = 15.0
) -> FrameTransport:
    if mode not in ("auto", "wss", "tcp"):
        raise ConnectionFailed(f"未知传输模式：{mode}")
    if mode == "wss":
        return await WebSocketTransport.open(zone.domain, zone.wss_port, timeout)
    if mode == "tcp":
        return await TcpTransport.open(zone.host, zone.tcp_port, timeout)
    if zone.domain and zone.wss_port > 0:
        try:
            return await WebSocketTransport.open(zone.domain, zone.wss_port, timeout)
        except ConnectionFailed:
            pass
    return await TcpTransport.open(zone.host, zone.tcp_port, timeout)
