"""Strict Loader-style #send parsing."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from .errors import ConfigError
from .models import SendMessage

PREFIX = "#send="
MAX_MESSAGE_FILE_SIZE = 16 * 1024 * 1024


def _validate(value: Any) -> SendMessage:
    if not isinstance(value, dict):
        raise ConfigError("#send 的 JSON 必须是对象")
    if list(value) != ["id", "param", "cmd"]:
        raise ConfigError("#send 字段必须严格按 id、param、cmd 排列")
    extension_id = value["id"]
    parameters = value["param"]
    command = value["cmd"]
    if isinstance(extension_id, bool) or not isinstance(extension_id, int):
        raise ConfigError("#send.id 必须是整数")
    if not 0 <= extension_id <= 0xFFFF:
        raise ConfigError("#send.id 必须在 0..65535 范围内")
    if not isinstance(parameters, dict):
        raise ConfigError("#send.param 必须是对象")
    if not isinstance(command, str) or not command.strip():
        raise ConfigError("#send.cmd 必须是非空字符串")
    return SendMessage(extension_id, command, parameters)


def parse_send_message(text: str) -> SendMessage:
    if not isinstance(text, str):
        raise ConfigError("#send 消息必须是字符串")
    stripped = text.strip()
    if not stripped.startswith(PREFIX) or not stripped.endswith("|"):
        raise ConfigError("消息必须是完整的 #send={...}|")
    raw_json = stripped[len(PREFIX) : -1]
    try:
        value = json.loads(raw_json)
    except json.JSONDecodeError as exc:
        raise ConfigError(f"#send JSON 无效：{exc.msg}") from exc
    return _validate(value)


def parse_send_stream(text: str) -> list[SendMessage]:
    decoder = json.JSONDecoder()
    position = 0
    messages: list[SendMessage] = []
    while position < len(text):
        while position < len(text) and (text[position].isspace() or text[position] == "|"):
            position += 1
        if position >= len(text):
            break
        if text.startswith("//", position):
            newline = text.find("\n", position)
            position = len(text) if newline < 0 else newline + 1
            continue
        if not text.startswith(PREFIX, position):
            raise ConfigError(f"消息流第 {position + 1} 个字符附近不是 #send")
        json_start = position + len(PREFIX)
        try:
            value, json_end = decoder.raw_decode(text, json_start)
        except json.JSONDecodeError as exc:
            raise ConfigError(f"消息流 JSON 无效：{exc.msg}") from exc
        position = json_end
        while position < len(text) and text[position].isspace():
            position += 1
        if position >= len(text) or text[position] != "|":
            raise ConfigError("消息流中的 #send 缺少结尾 |")
        position += 1
        messages.append(_validate(value))
    if not messages:
        raise ConfigError("没有找到可发送的 #send 消息")
    return messages


def parse_send_file(path: str | Path) -> list[SendMessage]:
    source = Path(path)
    try:
        size = source.stat().st_size
        if size > MAX_MESSAGE_FILE_SIZE:
            raise ConfigError("消息文件超过 16 MiB")
        return parse_send_stream(source.read_text(encoding="utf-8-sig"))
    except ConfigError:
        raise
    except OSError as exc:
        raise ConfigError(f"无法读取消息文件 {source}：{exc}") from exc

