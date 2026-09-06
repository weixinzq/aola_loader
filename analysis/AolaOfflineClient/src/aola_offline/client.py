"""Public client, single-reader routing and structured send/receive."""

from __future__ import annotations

import asyncio
import copy
import logging
from collections.abc import Callable, Mapping
from datetime import UTC, datetime
from typing import Any

from .audit import AuditLog
from .auth import HttpAuthenticator
from .config import DEFAULT_LOGIN_URL
from .errors import (
    ConnectionFailed,
    DisconnectedError,
    ProtocolError,
    ReceiveTimeout,
    SubscriptionOverflow,
)
from .models import (
    AccountProfile,
    ReceivedMessage,
    SendReceipt,
    TransportMode,
    Zone,
)
from .protocol import (
    ProtocolState,
    build_extension_frame,
    build_login_frame,
    parse_server_frame,
)
from .transport import FrameTransport, open_transport

logger = logging.getLogger(__name__)
MessagePredicate = Callable[[ReceivedMessage], bool]
TransportFactory = Callable[[Zone, TransportMode, float], Any]
_END = object()


class _SubscriptionState:
    def __init__(
        self, max_queue: int, predicate: MessagePredicate | None
    ) -> None:
        self.queue: asyncio.Queue[ReceivedMessage | object] = asyncio.Queue(
            maxsize=max_queue
        )
        self.predicate = predicate
        self.error: BaseException | None = None
        self.closed = False

    def fail(self, error: BaseException) -> None:
        if self.closed:
            return
        self.error = error
        while self.queue.full():
            self.queue.get_nowait()
        self.queue.put_nowait(_END)


class _MessageRouter:
    def __init__(self) -> None:
        self._states: set[_SubscriptionState] = set()
        self._terminal_error: BaseException | None = None

    def subscribe(
        self, max_queue: int, predicate: MessagePredicate | None
    ) -> _SubscriptionState:
        if max_queue <= 0:
            raise ValueError("max_queue 必须大于 0")
        state = _SubscriptionState(max_queue, predicate)
        if self._terminal_error is not None:
            state.fail(self._terminal_error)
        else:
            self._states.add(state)
        return state

    def unsubscribe(self, state: _SubscriptionState) -> None:
        self._states.discard(state)
        state.closed = True

    def publish(self, message: ReceivedMessage) -> None:
        for state in tuple(self._states):
            if state.closed:
                self._states.discard(state)
                continue
            if state.predicate is not None:
                try:
                    if not state.predicate(message):
                        continue
                except Exception as exc:
                    self._states.discard(state)
                    state.fail(exc)
                    continue
            if state.queue.full():
                self._states.discard(state)
                state.fail(SubscriptionOverflow("接收订阅队列已满"))
                continue
            state.queue.put_nowait(copy.deepcopy(message))

    def fail(self, error: BaseException) -> None:
        if self._terminal_error is not None:
            return
        self._terminal_error = error
        states = tuple(self._states)
        self._states.clear()
        for state in states:
            state.fail(error)


class MessageSubscription:
    def __init__(
        self,
        router: _MessageRouter,
        state: _SubscriptionState,
    ) -> None:
        self._router = router
        self._state = state

    async def next(self, timeout: float | None = None) -> ReceivedMessage:
        async def receive_matching() -> ReceivedMessage:
            while True:
                item = await self._state.queue.get()
                if item is _END:
                    error = self._state.error or DisconnectedError("接收订阅已关闭")
                    raise error
                assert isinstance(item, ReceivedMessage)
                return item

        try:
            if timeout is None:
                return await receive_matching()
            return await asyncio.wait_for(receive_matching(), timeout=timeout)
        except asyncio.TimeoutError as exc:
            raise ReceiveTimeout("等待接收消息超时") from exc

    def close(self) -> None:
        self._router.unsubscribe(self._state)

    async def __aenter__(self) -> "MessageSubscription":
        return self

    async def __aexit__(self, _exc_type, _exc, _traceback) -> None:
        self.close()

    def __aiter__(self) -> "MessageSubscription":
        return self

    async def __anext__(self) -> ReceivedMessage:
        try:
            return await self.next()
        except DisconnectedError as exc:
            raise StopAsyncIteration from exc


class AolaClient:
    def __init__(
        self,
        profile: AccountProfile,
        zone: Zone,
        transport: FrameTransport,
        state: ProtocolState,
        audit: AuditLog | None,
    ) -> None:
        self.label = profile.label
        self.zone = zone
        self._transport = transport
        self._state: ProtocolState | None = state
        self._audit_log = audit
        self._router = _MessageRouter()
        self._send_lock = asyncio.Lock()
        self._reader_task: asyncio.Task[None] | None = None
        self._connected = True
        self._closing = False

    @property
    def connected(self) -> bool:
        return self._connected

    @property
    def transport_kind(self) -> str:
        return self._transport.kind

    @classmethod
    async def connect(
        cls,
        profile: AccountProfile,
        *,
        login_url: str = DEFAULT_LOGIN_URL,
        transport_mode: TransportMode = "auto",
        timeout: float = 15.0,
        authenticator: HttpAuthenticator | None = None,
        transport_factory: TransportFactory = open_transport,
        audit: AuditLog | None = None,
    ) -> "AolaClient":
        authentication = authenticator or HttpAuthenticator()
        session, zone = await authentication.login(profile, login_url, timeout=30.0)
        transport = await transport_factory(zone, transport_mode, timeout)
        login_submitted = False
        try:
            login = build_login_frame(
                f"{zone.zone_index} {zone.zone_name}",
                session.user_id,
                session.session_id,
            )
            login_submitted = True
            await transport.write(login.data)
            await cls._wait_for_login_ok(transport, timeout)
        except asyncio.CancelledError:
            await transport.close()
            raise
        except Exception as exc:
            await transport.close()
            if login_submitted:
                raise ConnectionFailed(
                    "登录帧已提交但未确认 logOK；为避免重复会话，不自动切换传输重试"
                ) from exc
            raise

        client = cls(
            profile,
            zone,
            transport,
            ProtocolState(session.user_id, session.session_id),
            audit,
        )
        client._audit("connected", transport=transport.kind, zoneIndex=zone.zone_index)
        client._reader_task = asyncio.create_task(
            client._receive_loop(), name=f"aola-recv-{client.label}"
        )
        return client

    @staticmethod
    async def _wait_for_login_ok(
        transport: FrameTransport, timeout: float
    ) -> ReceivedMessage:
        loop = asyncio.get_running_loop()
        deadline = loop.time() + timeout
        while True:
            remaining = deadline - loop.time()
            if remaining <= 0:
                raise ReceiveTimeout("等待 logOK 超时")
            try:
                frame = await asyncio.wait_for(transport.read_frame(), timeout=remaining)
            except asyncio.TimeoutError as exc:
                raise ReceiveTimeout("等待 logOK 超时") from exc
            message = parse_server_frame(frame)
            if message.command == "logOK":
                return message
            if message.command == "logKO":
                raise ConnectionFailed("游戏长连接拒绝登录")

    def recv(
        self,
        predicate: MessagePredicate | None = None,
        *,
        max_queue: int = 256,
    ) -> MessageSubscription:
        return MessageSubscription(
            self._router, self._router.subscribe(max_queue, predicate)
        )

    async def send(
        self,
        extension_id: int,
        command: str,
        parameters: Mapping[str, Any],
        room_id: int = -1,
    ) -> SendReceipt:
        async with self._send_lock:
            if not self._connected:
                raise DisconnectedError("账号连接已断开")
            state = self._state
            if state is None:
                raise DisconnectedError("账号会话状态已清理")
            encoded = build_extension_frame(
                state, extension_id, command, parameters, room_id
            )
            try:
                await self._transport.write(encoded.data)
            except asyncio.CancelledError:
                await self._transport.close()
                self._connected = False
                self._state = None
                self._router.fail(
                    DisconnectedError(
                        "发送在写入期间被取消；连接已关闭且不会自动重发"
                    )
                )
                self._audit(
                    "send_cancelled",
                    extensionId=extension_id,
                    command=command,
                )
                raise
            except Exception as exc:
                await self._transport.close()
                self._connected = False
                self._state = None
                error = DisconnectedError(
                    "发送写入结果不明确；连接已关闭且不会自动重发"
                )
                self._router.fail(error)
                self._audit(
                    "send_failed",
                    extensionId=extension_id,
                    command=command,
                    errorType=type(exc).__name__,
                )
                raise error from exc
            receipt = SendReceipt(
                extension_id=extension_id,
                command=command,
                outer_sequence=encoded.outer_sequence,
                inner_sequence=encoded.inner_sequence or 0,
                submitted_at=datetime.now(UTC),
            )
            self._audit(
                "submitted",
                extensionId=extension_id,
                command=command,
                outerSequence=receipt.outer_sequence,
                innerSequence=receipt.inner_sequence,
            )
            return receipt

    async def _receive_loop(self) -> None:
        terminal: BaseException = DisconnectedError("接收循环已停止")
        try:
            while self._connected:
                frame = await self._transport.read_frame()
                try:
                    message = parse_server_frame(frame)
                except ProtocolError as exc:
                    logger.warning(
                        "server frame parse failed: %s", type(exc).__name__
                    )
                    self._audit("receive_parse_failed", errorType=type(exc).__name__)
                    raise
                self._router.publish(message)
        except asyncio.CancelledError:
            terminal = DisconnectedError("连接已由调用方关闭")
            raise
        except Exception as exc:
            terminal = DisconnectedError(f"接收连接已断开：{type(exc).__name__}")
            self._audit("disconnected", errorType=type(exc).__name__)
        finally:
            self._connected = False
            self._state = None
            self._router.fail(terminal)

    def _audit(self, event: str, **metadata: Any) -> None:
        if self._audit_log is None:
            return
        try:
            self._audit_log.write(event, label=self.label, **metadata)
        except OSError:
            logger.exception("audit log write failed")

    async def close(self) -> None:
        if self._closing:
            return
        self._closing = True
        self._connected = False
        self._state = None
        task = self._reader_task
        self._reader_task = None
        if task is not None:
            task.cancel()
        await self._transport.close()
        if task is not None:
            try:
                await task
            except asyncio.CancelledError:
                pass
        self._router.fail(DisconnectedError("连接已由调用方关闭"))
        self._audit("closed")

    async def __aenter__(self) -> "AolaClient":
        return self

    async def __aexit__(self, _exc_type, _exc, _traceback) -> None:
        await self.close()
