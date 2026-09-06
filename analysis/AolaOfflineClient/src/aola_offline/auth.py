"""HTTPS account authentication and zone-list parsing."""

from __future__ import annotations

import asyncio
import hashlib
import urllib.parse
import xml.etree.ElementTree as ET
from collections.abc import Callable

import aiohttp

from .errors import AuthenticationError
from .models import AccountProfile, LoginSession, Zone


def md5_password(password: str) -> str:
    return hashlib.md5(password.encode("utf-8")).hexdigest()


def build_login_form(account: str, password: str) -> str:
    return urllib.parse.urlencode(
        {
            "account": account,
            "password": md5_password(password),
            "logintype": "",
            "wyToken": "",
            "fromurl": "",
            "webSite": "",
            "token": "",
            "cookieId": "",
            "pi": "",
            "sessionId": "",
            "content": "",
        }
    )


def _text(root: ET.Element, name: str) -> str:
    node = root.find(name)
    if node is None:
        return ""
    return "".join(node.itertext()).strip()


def parse_login_response(xml_text: str) -> LoginSession:
    try:
        root = ET.fromstring(xml_text)
    except ET.ParseError as exc:
        raise AuthenticationError("登录服务返回了无效 XML") from exc

    code = _text(root, "c")
    if code != "ok":
        errors = {
            "freeze": "账号已被冻结",
            "error": "登录服务发生错误",
            "invalid": "用户名或密码错误",
            "busy": "登录服务繁忙",
            "maintain": "服务器维护中",
            "wait_logout": "账号仍有会话正在退出；请关闭其他客户端后稍候再试",
        }
        raise AuthenticationError(errors.get(code, f"登录失败：{code or 'unknown'}"))

    user_text = _text(root, "u")
    session_id = _text(root, "sid")
    try:
        user_id = int(user_text)
    except ValueError as exc:
        raise AuthenticationError("登录结果缺少有效用户 ID") from exc
    if user_id <= 0 or not session_id:
        raise AuthenticationError("登录结果缺少用户 ID 或会话凭据")

    servers = [item for item in _text(root, "svr").split(";") if item.strip()]
    zones: list[Zone] = []
    for raw_zone in (item for item in _text(root, "zn").split(";") if item.strip()):
        fields = raw_zone.split("/")
        if len(fields) < 2:
            continue
        name_fields = fields[0].split(" ", 1)
        try:
            zone_index = int(name_fields[0])
            server_index = int(fields[1])
            server_fields = servers[server_index].split(":")
            host = server_fields[0]
            tcp_port = int(server_fields[1])
            wss_port = int(server_fields[2])
            domain = server_fields[3]
        except (ValueError, IndexError):
            continue
        if zone_index >= 100000 or (tcp_port <= 0 and wss_port <= 0):
            continue
        zones.append(
            Zone(
                zone_index=zone_index,
                zone_name=name_fields[1] if len(name_fields) > 1 else "",
                host=host,
                wss_port=wss_port,
                tcp_port=tcp_port,
                domain=domain,
            )
        )
    if not zones:
        raise AuthenticationError("登录结果没有可用区服")
    return LoginSession(user_id=user_id, session_id=session_id, zones=tuple(zones))


def select_zone(session: LoginSession, zone_index: int) -> Zone:
    for zone in session.zones:
        if zone.zone_index == zone_index:
            return zone
    available = "、".join(str(item.zone_index) for item in session.zones[:12])
    raise AuthenticationError(
        f"登录结果中没有配置的区服 {zone_index}；当前可用区服：{available}"
    )


class HttpAuthenticator:
    def __init__(self, session_factory: Callable[..., aiohttp.ClientSession] | None = None):
        self._session_factory = session_factory or aiohttp.ClientSession

    async def login(
        self, profile: AccountProfile, login_url: str, timeout: float = 30.0
    ) -> tuple[LoginSession, Zone]:
        headers = {
            "Content-Type": "application/x-www-form-urlencoded",
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
            "Origin": "https://aola.100bt.com",
            "Referer": "https://aola.100bt.com/",
        }
        try:
            async with self._session_factory() as session:
                async with session.post(
                    login_url,
                    data=build_login_form(profile.account, profile.password),
                    headers=headers,
                    timeout=aiohttp.ClientTimeout(total=timeout),
                ) as response:
                    response.raise_for_status()
                    result = parse_login_response(await response.text())
        except AuthenticationError:
            raise
        except asyncio.TimeoutError as exc:
            raise AuthenticationError("登录请求超时") from exc
        except aiohttp.ClientError as exc:
            raise AuthenticationError(f"登录请求失败：{type(exc).__name__}") from exc
        return result, select_zone(result, profile.zone_index)
