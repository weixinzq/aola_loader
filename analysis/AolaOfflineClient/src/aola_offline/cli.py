"""Command-line entry point."""

from __future__ import annotations

import argparse
import asyncio
import json
import logging
import sys
from base64 import b64encode
from collections.abc import Awaitable, Callable
from pathlib import Path
from typing import Any

from .audit import AuditLog
from .client import AolaClient
from .config import OfflineConfig, load_config
from .errors import AolaOfflineError, ConfigError
from .messages import parse_send_file, parse_send_message
from .models import AccountProfile, ReceivedMessage, SendMessage, TransportMode
from .scripting import (
    ScriptDescriptor,
    discover_scripts,
    load_script,
    run_script_for_accounts,
)

MAX_ACCOUNT_CONCURRENCY = 5


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="aola-offline")
    parser.add_argument("--config", default="accounts.json")
    parser.add_argument(
        "--transport", choices=("auto", "wss", "tcp"), default="auto"
    )
    subcommands = parser.add_subparsers(dest="command", required=True)

    subcommands.add_parser("check-config", help="校验本地账号配置，不连接网络")

    send = subcommands.add_parser("send", help="发送严格 #send 消息")
    send.add_argument("--accounts", nargs="+", required=True)
    source = send.add_mutually_exclusive_group(required=True)
    source.add_argument("--message")
    source.add_argument("--file")

    receive = subcommands.add_parser("recv", help="持续打印接收消息")
    receive.add_argument("--accounts", nargs="+", required=True)
    receive.add_argument("--command-filter")
    receive.add_argument("--timeout", type=float, default=0.0)

    run = subcommands.add_parser("run", help="运行可信本地 Python 脚本")
    run.add_argument("script")
    run.add_argument("--scripts-dir", default="scripts")
    run.add_argument("--accounts", nargs="+", required=True)
    return parser


def _confirm(summary: str) -> bool:
    print(summary)
    return input("确认启动这些独立登录连接？[y/N]：").strip().lower() == "y"


def _account_summary(profiles: tuple[AccountProfile, ...]) -> str:
    lines = ["将建立独立账号连接；同一账号不得同时登录官方客户端："]
    lines.extend(f"  - {item.label}（区服 {item.zone_index}）" for item in profiles)
    return "\n".join(lines)


def _json_value(value: Any) -> Any:
    if isinstance(value, bytes):
        return {"bytesBase64": b64encode(value).decode("ascii")}
    if isinstance(value, dict):
        return {str(key): _json_value(item) for key, item in value.items()}
    if isinstance(value, (list, tuple)):
        return [_json_value(item) for item in value]
    return value


def _print_message(label: str, message: ReceivedMessage) -> None:
    print(
        json.dumps(
            {
                "label": label,
                "receivedAt": message.received_at.isoformat(),
                "messageType": message.message_type,
                "action": message.action,
                "extensionId": message.extension_id,
                "command": message.command,
                "payload": _json_value(message.payload),
            },
            ensure_ascii=False,
            separators=(",", ":"),
        ),
        flush=True,
    )


async def _with_clients(
    profiles: tuple[AccountProfile, ...],
    config: OfflineConfig,
    transport: TransportMode,
    operation: Callable[[AccountProfile, AolaClient], Awaitable[None]],
) -> dict[str, str]:
    semaphore = asyncio.Semaphore(MAX_ACCOUNT_CONCURRENCY)
    errors: dict[str, str] = {}
    audit = AuditLog()

    async def run_one(profile: AccountProfile) -> None:
        async with semaphore:
            client: AolaClient | None = None
            try:
                client = await AolaClient.connect(
                    profile,
                    login_url=config.login_url,
                    transport_mode=transport,
                    audit=audit,
                )
                await operation(profile, client)
            except Exception as exc:
                errors[profile.label] = f"{type(exc).__name__}: {exc}"
            finally:
                if client is not None:
                    await client.close()

    await asyncio.gather(*(run_one(profile) for profile in profiles))
    return errors


async def _send_command(
    profiles: tuple[AccountProfile, ...],
    config: OfflineConfig,
    transport: TransportMode,
    messages: list[SendMessage],
) -> int:
    async def send_all(profile: AccountProfile, client: AolaClient) -> None:
        for message in messages:
            receipt = await client.send(
                message.extension_id, message.command, message.parameters
            )
            print(
                f"[{profile.label}] submitted ext={receipt.extension_id} "
                f"cmd={receipt.command} outer={receipt.outer_sequence}"
            )

    errors = await _with_clients(profiles, config, transport, send_all)
    for label, error in errors.items():
        print(f"[{label}] 失败：{error}", file=sys.stderr)
    return 1 if errors else 0


async def _recv_command(
    profiles: tuple[AccountProfile, ...],
    config: OfflineConfig,
    transport: TransportMode,
    command_filter: str | None,
    timeout: float,
) -> int:
    async def receive(profile: AccountProfile, client: AolaClient) -> None:
        predicate = (
            None
            if not command_filter
            else lambda message: message.command == command_filter
        )
        async with client.recv(predicate) as subscription:
            if timeout > 0:
                _print_message(profile.label, await subscription.next(timeout))
                return
            async for message in subscription:
                _print_message(profile.label, message)

    errors = await _with_clients(profiles, config, transport, receive)
    for label, error in errors.items():
        print(f"[{label}] 失败：{error}", file=sys.stderr)
    return 1 if errors else 0


async def _run_script_command(
    profiles: tuple[AccountProfile, ...],
    config: OfflineConfig,
    transport: TransportMode,
    descriptor: ScriptDescriptor,
) -> int:
    cancelled = asyncio.Event()
    script = load_script(descriptor.path)
    results = await run_script_for_accounts(
        script,
        profiles,
        login_url=config.login_url,
        transport_mode=transport,
        cancelled=cancelled,
        audit=AuditLog(),
    )
    failed = False
    for label in (item.label for item in profiles):
        result = results.get(label)
        if result is None:
            failed = True
            print(f"[{label}] 未完成", file=sys.stderr)
        elif result.success:
            print(f"[{label}] 脚本完成")
        else:
            failed = True
            print(f"[{label}] 脚本失败：{result.error}", file=sys.stderr)
    return 1 if failed else 0


async def _run(args: argparse.Namespace) -> int:
    config = load_config(args.config)
    if args.command == "check-config":
        print(f"配置有效：{len(config.accounts)} 个账号")
        for profile in config.accounts:
            print(f"  - {profile.label}（区服 {profile.zone_index}）")
        return 0

    profiles = config.select_accounts(args.accounts)
    if args.command == "send":
        messages = (
            [parse_send_message(args.message)]
            if args.message is not None
            else parse_send_file(args.file)
        )
    elif args.command == "run":
        scripts = discover_scripts(args.scripts_dir)
        selected = next(
            (item for item in scripts if item.module_name == args.script), None
        )
        if selected is None:
            raise ConfigError(f"找不到脚本：{args.script}")
        summary = _account_summary(profiles)
        summary += f"\n脚本：{selected.name}\n{selected.description}"
        if not _confirm(summary):
            print("已取消；未连接服务器。")
            return 2

    transport: TransportMode = args.transport
    if args.command == "send":
        return await _send_command(profiles, config, transport, messages)
    if args.command == "recv":
        return await _recv_command(
            profiles, config, transport, args.command_filter, args.timeout
        )
    return await _run_script_command(
        profiles, config, transport, selected
    )


def main(argv: list[str] | None = None) -> int:
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
    args = _parser().parse_args(argv)
    try:
        return asyncio.run(_run(args))
    except KeyboardInterrupt:
        print("已取消；正在关闭账号连接。", file=sys.stderr)
        return 130
    except AolaOfflineError as exc:
        print(f"错误：{exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
