"""Trusted local script discovery and bounded multi-account execution."""

from __future__ import annotations

import asyncio
import ast
import importlib.util
import inspect
import logging
from collections.abc import Awaitable, Callable, Mapping
from dataclasses import dataclass
from pathlib import Path
from types import ModuleType
from typing import Any

from .audit import AuditLog
from .client import AolaClient, MessagePredicate, MessageSubscription
from .errors import ScriptLoadError
from .models import AccountProfile, SendReceipt, TransportMode

logger = logging.getLogger(__name__)
MAX_ACCOUNT_CONCURRENCY = 5


@dataclass(frozen=True, slots=True)
class InteractionScript:
    module_name: str
    name: str
    description: str
    run: Callable[["ScriptContext"], Awaitable[None]]


@dataclass(frozen=True, slots=True)
class ScriptDescriptor:
    module_name: str
    name: str
    description: str
    path: Path


@dataclass(frozen=True, slots=True)
class ScriptRunResult:
    label: str
    success: bool
    error: str = ""


class ScriptContext:
    def __init__(
        self, label: str, client: AolaClient, cancelled: asyncio.Event, audit: AuditLog
    ) -> None:
        self.label = label
        self._client = client
        self._cancelled = cancelled
        self._audit = audit
        self._subscription_created = False

    @property
    def cancelled(self) -> bool:
        return self._cancelled.is_set()

    async def send(
        self,
        extension_id: int,
        command: str,
        parameters: Mapping[str, Any],
        room_id: int = -1,
    ) -> SendReceipt:
        if self.cancelled:
            raise asyncio.CancelledError
        if not self._subscription_created:
            raise RuntimeError("脚本必须先调用 context.recv() 建立订阅，再发送")
        return await self._client.send(extension_id, command, parameters, room_id)

    def recv(
        self, predicate: MessagePredicate | None = None, *, max_queue: int = 256
    ) -> MessageSubscription:
        subscription = self._client.recv(predicate, max_queue=max_queue)
        self._subscription_created = True
        return subscription

    def log(self, message: str) -> None:
        text = str(message)
        logger.info("[%s] %s", self.label, text)
        try:
            self._audit.write(
                "script_log", label=self.label, messageLength=len(text)
            )
        except OSError:
            logger.exception("audit log write failed")


def _load_module(path: Path) -> ModuleType:
    module_name = f"aola_user_script_{path.stem}"
    spec = importlib.util.spec_from_file_location(module_name, path)
    if spec is None or spec.loader is None:
        raise ScriptLoadError(f"无法加载脚本：{path}")
    module = importlib.util.module_from_spec(spec)
    try:
        spec.loader.exec_module(module)
    except Exception as exc:
        raise ScriptLoadError(f"脚本导入失败 {path.name}：{type(exc).__name__}") from exc
    return module


def inspect_script(path: str | Path) -> ScriptDescriptor:
    source = Path(path)
    if source.suffix.lower() != ".py" or source.name.startswith("_"):
        raise ScriptLoadError("脚本必须是非下划线开头的 .py 文件")
    try:
        tree = ast.parse(source.read_text(encoding="utf-8-sig"), filename=str(source))
    except (OSError, UnicodeError, SyntaxError) as exc:
        raise ScriptLoadError(
            f"无法读取脚本元数据 {source.name}：{type(exc).__name__}"
        ) from exc

    values: dict[str, str] = {}
    has_async_run = False
    for node in tree.body:
        if isinstance(node, ast.AsyncFunctionDef) and node.name == "run":
            has_async_run = True
        if not isinstance(node, (ast.Assign, ast.AnnAssign)):
            continue
        targets = node.targets if isinstance(node, ast.Assign) else [node.target]
        value = node.value
        for target in targets:
            if not isinstance(target, ast.Name) or target.id not in (
                "SCRIPT_NAME",
                "SCRIPT_DESCRIPTION",
            ):
                continue
            try:
                literal = ast.literal_eval(value)
            except (ValueError, TypeError):
                literal = None
            if isinstance(literal, str):
                values[target.id] = literal

    name = values.get("SCRIPT_NAME", "").strip()
    description = values.get("SCRIPT_DESCRIPTION", "").strip()
    if not name:
        raise ScriptLoadError(f"{source.name} 必须静态声明字符串 SCRIPT_NAME")
    if "SCRIPT_DESCRIPTION" not in values:
        raise ScriptLoadError(
            f"{source.name} 必须静态声明字符串 SCRIPT_DESCRIPTION"
        )
    if not has_async_run:
        raise ScriptLoadError(f"{source.name} 必须提供 async def run(context)")
    return ScriptDescriptor(source.stem, name, description, source.resolve())


def load_script(path: str | Path) -> InteractionScript:
    descriptor = inspect_script(path)
    source = descriptor.path
    module = _load_module(source)
    name = getattr(module, "SCRIPT_NAME", None)
    description = getattr(module, "SCRIPT_DESCRIPTION", "")
    run = getattr(module, "run", None)
    if not isinstance(name, str) or not name.strip():
        raise ScriptLoadError(f"{source.name} 必须提供 SCRIPT_NAME")
    if not isinstance(description, str):
        raise ScriptLoadError(f"{source.name} 的 SCRIPT_DESCRIPTION 必须是字符串")
    if not inspect.iscoroutinefunction(run):
        raise ScriptLoadError(f"{source.name} 必须提供 async def run(context)")
    if name.strip() != descriptor.name or description.strip() != descriptor.description:
        raise ScriptLoadError(f"{source.name} 导入后的脚本元数据与确认内容不一致")
    return InteractionScript(source.stem, name.strip(), description.strip(), run)


def discover_scripts(directory: str | Path = "scripts") -> tuple[ScriptDescriptor, ...]:
    source = Path(directory)
    if not source.exists():
        return ()
    scripts = [
        inspect_script(path)
        for path in sorted(source.glob("*.py"))
        if not path.name.startswith("_")
    ]
    names = [item.module_name for item in scripts]
    if len(names) != len(set(names)):
        raise ScriptLoadError("脚本模块名重复")
    return tuple(scripts)


async def run_script_for_accounts(
    script: InteractionScript,
    profiles: tuple[AccountProfile, ...],
    *,
    login_url: str,
    transport_mode: TransportMode,
    cancelled: asyncio.Event,
    audit: AuditLog,
    connector: Callable[..., Awaitable[AolaClient]] = AolaClient.connect,
) -> dict[str, ScriptRunResult]:
    semaphore = asyncio.Semaphore(MAX_ACCOUNT_CONCURRENCY)
    results: dict[str, ScriptRunResult] = {}

    async def run_one(profile: AccountProfile) -> None:
        async with semaphore:
            client: AolaClient | None = None
            try:
                if cancelled.is_set():
                    raise asyncio.CancelledError
                client = await connector(
                    profile,
                    login_url=login_url,
                    transport_mode=transport_mode,
                    audit=audit,
                )
                context = ScriptContext(profile.label, client, cancelled, audit)
                await script.run(context)
                results[profile.label] = ScriptRunResult(profile.label, True)
            except asyncio.CancelledError:
                results[profile.label] = ScriptRunResult(
                    profile.label, False, "任务已取消"
                )
                raise
            except Exception as exc:
                results[profile.label] = ScriptRunResult(
                    profile.label, False, f"{type(exc).__name__}: {exc}"
                )
            finally:
                if client is not None:
                    await client.close()

    tasks = [asyncio.create_task(run_one(profile)) for profile in profiles]
    try:
        await asyncio.gather(*tasks)
    except asyncio.CancelledError:
        cancelled.set()
        for task in tasks:
            task.cancel()
        await asyncio.gather(*tasks, return_exceptions=True)
        raise
    return results
