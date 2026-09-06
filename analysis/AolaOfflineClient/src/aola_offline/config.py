"""Strict loading for the ignored local account file."""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from .errors import ConfigError
from .models import AccountProfile

DEFAULT_LOGIN_URL = "https://login-aola.100bt.com/newLogin.jsp"


@dataclass(frozen=True, slots=True)
class OfflineConfig:
    login_url: str
    accounts: tuple[AccountProfile, ...]

    def select_accounts(self, labels: list[str]) -> tuple[AccountProfile, ...]:
        if labels == ["all"]:
            return self.accounts
        requested = set(labels)
        selected = tuple(item for item in self.accounts if item.label in requested)
        missing = requested.difference(item.label for item in selected)
        if missing:
            raise ConfigError("找不到账号标签：" + "、".join(sorted(missing)))
        return selected


def _require_text(value: Any, location: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ConfigError(f"{location} 必须是非空字符串")
    return value.strip()


def load_config(path: str | Path = "accounts.json") -> OfflineConfig:
    source = Path(path)
    try:
        raw = json.loads(source.read_text(encoding="utf-8-sig"))
    except FileNotFoundError as exc:
        raise ConfigError(
            f"找不到 {source}；请复制 accounts.example.json 并填写本地凭据"
        ) from exc
    except (OSError, json.JSONDecodeError) as exc:
        raise ConfigError(f"无法读取 {source}：{exc}") from exc

    if not isinstance(raw, dict):
        raise ConfigError("账号配置根节点必须是对象")
    login_url = _require_text(raw.get("login_url", DEFAULT_LOGIN_URL), "login_url")
    if not login_url.lower().startswith("https://"):
        raise ConfigError("login_url 必须使用 HTTPS")

    items = raw.get("accounts")
    if not isinstance(items, list) or not items:
        raise ConfigError("accounts 必须是非空数组")

    profiles: list[AccountProfile] = []
    labels: set[str] = set()
    for index, item in enumerate(items):
        location = f"accounts[{index}]"
        if not isinstance(item, dict):
            raise ConfigError(f"{location} 必须是对象")
        label = _require_text(item.get("label"), f"{location}.label")
        account = _require_text(item.get("account"), f"{location}.account")
        password = _require_text(item.get("password"), f"{location}.password")
        zone_index = item.get("zone_index")
        if isinstance(zone_index, bool) or not isinstance(zone_index, int) or zone_index <= 0:
            raise ConfigError(f"{location}.zone_index 必须是正整数")
        if label in labels:
            raise ConfigError(f"账号标签重复：{label}")
        labels.add(label)
        profiles.append(AccountProfile(label, account, password, zone_index))

    return OfflineConfig(login_url=login_url, accounts=tuple(profiles))

