from __future__ import annotations

import asyncio
import struct
import unittest
from collections.abc import Iterable
from typing import Any
from unittest.mock import AsyncMock, patch

from aola_offline.client import AolaClient
from aola_offline.errors import (
    ConnectionFailed,
    DisconnectedError,
    SubscriptionOverflow,
)
from aola_offline.models import AccountProfile, LoginSession, Zone
from aola_offline.protocol.amf3 import encode_amf3
from aola_offline.transport import TcpTransport, WebSocketTransport, open_transport


def server_message(command: str, **payload: Any) -> bytes:
    body = b"\x01" + encode_amf3({"_cmd": command, **payload})
    return struct.pack(">I", len(body)) + body


class FakeAuthenticator:
    def __init__(self, zone: Zone) -> None:
        self.zone = zone
        self.calls = 0

    async def login(self, profile, login_url, timeout=30.0):
        self.calls += 1
        session = LoginSession(123456, "fixture-session", (self.zone,))
        return session, self.zone


class FakeTransport:
    kind = "fake"

    def __init__(
        self,
        frames: Iterable[bytes | BaseException] = (),
        *,
        fail_write: bool = False,
        write_delay: float = 0.0,
    ) -> None:
        self.frames: asyncio.Queue[bytes | BaseException] = asyncio.Queue()
        for frame in frames:
            self.frames.put_nowait(frame)
        self.fail_write = fail_write
        self.write_delay = write_delay
        self.writes: list[bytes] = []
        self.closed = False
        self.active_writes = 0
        self.max_active_writes = 0
        self.write_started = asyncio.Event()

    async def write(self, frame: bytes) -> None:
        self.active_writes += 1
        self.max_active_writes = max(self.max_active_writes, self.active_writes)
        self.write_started.set()
        try:
            if self.write_delay:
                await asyncio.sleep(self.write_delay)
            if self.fail_write:
                raise OSError("uncertain write")
            self.writes.append(frame)
        finally:
            self.active_writes -= 1

    async def read_frame(self) -> bytes:
        item = await self.frames.get()
        if isinstance(item, BaseException):
            raise item
        return item

    async def close(self) -> None:
        if self.closed:
            return
        self.closed = True
        self.frames.put_nowait(DisconnectedError("closed"))


class FakeSocket:
    def __init__(self, chunks: Iterable[bytes]) -> None:
        self.chunks = asyncio.Queue()
        for chunk in chunks:
            self.chunks.put_nowait(chunk)
        self.sent: list[bytes] = []
        self.closed = False

    async def recv(self) -> bytes:
        return await self.chunks.get()

    async def send(self, frame: bytes) -> None:
        self.sent.append(frame)

    async def close(self) -> None:
        self.closed = True


class FakeWriter:
    def __init__(self) -> None:
        self.writes: list[bytes] = []
        self.closed = False

    def write(self, data: bytes) -> None:
        self.writes.append(data)

    async def drain(self) -> None:
        await asyncio.sleep(0)

    def close(self) -> None:
        self.closed = True

    async def wait_closed(self) -> None:
        return None


class TransportTests(unittest.IsolatedAsyncioTestCase):
    async def test_auto_transport_falls_back_only_during_open(self) -> None:
        zone = Zone(1025, "Fixture", "127.0.0.1", 443, 1234, "fixture.invalid")
        tcp_result = object()
        with patch.object(
            WebSocketTransport,
            "open",
            new_callable=AsyncMock,
            side_effect=ConnectionFailed("fixture WSS failure"),
        ) as wss_open, patch.object(
            TcpTransport, "open", new_callable=AsyncMock, return_value=tcp_result
        ) as tcp_open:
            result = await open_transport(zone, "auto", 1.0)
        self.assertIs(tcp_result, result)
        wss_open.assert_awaited_once()
        tcp_open.assert_awaited_once()

    async def test_websocket_handles_fragmented_and_coalesced_protocol_frames(self) -> None:
        first = server_message("one")
        second = server_message("two")
        socket = FakeSocket((first[:2], first[2:] + second))
        transport = WebSocketTransport(socket)
        self.assertEqual(first, await transport.read_frame())
        self.assertEqual(second, await transport.read_frame())
        await transport.write(b"request")
        self.assertEqual([b"request"], socket.sent)

    async def test_tcp_handles_coalesced_frames_and_bounded_lengths(self) -> None:
        first = server_message("one")
        second = server_message("two")
        reader = asyncio.StreamReader()
        reader.feed_data(first + second)
        writer = FakeWriter()
        transport = TcpTransport(reader, writer)
        self.assertEqual(first, await transport.read_frame())
        self.assertEqual(second, await transport.read_frame())
        await transport.close()
        self.assertTrue(writer.closed)


class ClientTests(unittest.IsolatedAsyncioTestCase):
    def setUp(self) -> None:
        self.profile = AccountProfile("fixture", "account", "password", 1025)
        self.zone = Zone(1025, "Fixture", "127.0.0.1", 443, 1234, "fixture.invalid")

    async def connect(self, transport: FakeTransport) -> AolaClient:
        async def factory(zone, mode, timeout):
            self.assertEqual(self.zone, zone)
            return transport

        return await AolaClient.connect(
            self.profile,
            login_url="https://fixture.invalid/login",
            authenticator=FakeAuthenticator(self.zone),
            transport_factory=factory,
            timeout=1.0,
        )

    async def test_ready_requires_log_ok_and_uses_one_reader(self) -> None:
        transport = FakeTransport(
            (server_message("beforeReady"), server_message("logOK"))
        )
        client = await self.connect(transport)
        self.assertTrue(client.connected)
        self.assertEqual(1, len(transport.writes))
        self.assertEqual(0, struct.unpack_from(">I", transport.writes[0], 4)[0])
        self.assertIsNotNone(client._reader_task)
        self.assertFalse(hasattr(client, "profile"))
        await client.close()
        self.assertIsNone(client._state)

    async def test_login_submission_failure_never_reopens_transport(self) -> None:
        transport = FakeTransport(fail_write=True)
        factory_calls = 0

        async def factory(zone, mode, timeout):
            nonlocal factory_calls
            factory_calls += 1
            return transport

        with self.assertRaisesRegex(ConnectionFailed, "不自动切换传输重试"):
            await AolaClient.connect(
                self.profile,
                login_url="https://fixture.invalid/login",
                authenticator=FakeAuthenticator(self.zone),
                transport_factory=factory,
                timeout=0.1,
            )
        self.assertEqual(1, factory_calls)
        self.assertTrue(transport.closed)

    async def test_cancellation_during_login_write_closes_transport(self) -> None:
        transport = FakeTransport(write_delay=10.0)

        async def factory(zone, mode, timeout):
            return transport

        task = asyncio.create_task(
            AolaClient.connect(
                self.profile,
                login_url="https://fixture.invalid/login",
                authenticator=FakeAuthenticator(self.zone),
                transport_factory=factory,
                timeout=1.0,
            )
        )
        await transport.write_started.wait()
        task.cancel()
        with self.assertRaises(asyncio.CancelledError):
            await task
        self.assertTrue(transport.closed)

    async def test_subscription_filters_before_queue_and_overflow_is_explicit(self) -> None:
        transport = FakeTransport((server_message("logOK"),))
        client = await self.connect(transport)
        filtered = client.recv(lambda message: message.command == "target", max_queue=1)
        transport.frames.put_nowait(server_message("noise"))
        transport.frames.put_nowait(server_message("target", value=1))
        self.assertEqual("target", (await filtered.next(1.0)).command)

        overflow = client.recv(lambda message: message.command == "target", max_queue=1)
        transport.frames.put_nowait(server_message("target", value=2))
        transport.frames.put_nowait(server_message("target", value=3))
        await asyncio.sleep(0.05)
        with self.assertRaises(SubscriptionOverflow):
            await overflow.next(1.0)
        await client.close()

    async def test_concurrent_sends_are_serial_and_sequence_write_is_atomic(self) -> None:
        transport = FakeTransport((server_message("logOK"),), write_delay=0.01)
        client = await self.connect(transport)
        transport.writes.clear()
        transport.max_active_writes = 0
        receipts = await asyncio.gather(
            *(client.send(42, f"cmd{index}", {"index": index}) for index in range(6))
        )
        self.assertEqual(1, transport.max_active_writes)
        self.assertEqual(
            [receipt.outer_sequence for receipt in receipts],
            [struct.unpack_from(">I", frame, 4)[0] for frame in transport.writes],
        )
        self.assertEqual(6, len(set(item.outer_sequence for item in receipts)))
        await client.close()

    async def test_disconnect_notifies_subscription(self) -> None:
        transport = FakeTransport((server_message("logOK"),))
        client = await self.connect(transport)
        subscription = client.recv()
        transport.frames.put_nowait(OSError("network gone"))
        with self.assertRaises(DisconnectedError):
            await subscription.next(1.0)
        self.assertFalse(client.connected)
        await client.close()

    async def test_malformed_server_frame_fails_connection(self) -> None:
        transport = FakeTransport((server_message("logOK"),))
        client = await self.connect(transport)
        subscription = client.recv()
        transport.frames.put_nowait(b"\x00\x00\x00\x01\x01")
        with self.assertRaises(DisconnectedError):
            await subscription.next(1.0)
        self.assertFalse(client.connected)
        await client.close()

    async def test_uncertain_send_closes_without_retry(self) -> None:
        transport = FakeTransport((server_message("logOK"),))
        client = await self.connect(transport)
        transport.fail_write = True
        before = len(transport.writes)
        with self.assertRaisesRegex(DisconnectedError, "不会自动重发"):
            await client.send(42, "query", {})
        self.assertEqual(before, len(transport.writes))
        self.assertTrue(transport.closed)
        await client.close()

    async def test_cancellation_during_send_closes_uncertain_connection(self) -> None:
        transport = FakeTransport((server_message("logOK"),))
        client = await self.connect(transport)
        transport.write_delay = 10.0
        transport.write_started.clear()
        task = asyncio.create_task(client.send(42, "query", {}))
        await transport.write_started.wait()
        task.cancel()
        with self.assertRaises(asyncio.CancelledError):
            await task
        self.assertTrue(transport.closed)
        self.assertFalse(client.connected)
        self.assertIsNone(client._state)
        await client.close()


if __name__ == "__main__":
    unittest.main()
