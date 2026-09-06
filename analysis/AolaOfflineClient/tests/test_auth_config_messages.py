from __future__ import annotations

import hashlib
import json
import tempfile
import unittest
import asyncio
from pathlib import Path
from urllib.parse import parse_qs

from aola_offline.auth import (
    build_login_form,
    md5_password,
    parse_login_response,
    select_zone,
)
from aola_offline.audit import AuditLog
from aola_offline.config import load_config
from aola_offline.errors import AuthenticationError, ConfigError
from aola_offline.messages import parse_send_file, parse_send_message, parse_send_stream
from aola_offline.scripting import ScriptContext


LOGIN_XML = """\
<root>
  <c>ok</c><u>123456</u><sid>fixture-session</sid>
  <svr>127.0.0.1:1234:443:fixture.invalid;127.0.0.2:2345:444:fixture2.invalid</svr>
  <zn>1025 Fixture/0;100000 Hidden/0;1026 Second/1;broken</zn>
</root>
"""


class AuthenticationTests(unittest.TestCase):
    def test_password_form_hashes_but_never_includes_plaintext(self) -> None:
        form = build_login_form("fixture-account", "fixture-password")
        parsed = parse_qs(form, keep_blank_values=True)
        self.assertEqual(["fixture-account"], parsed["account"])
        self.assertEqual(
            [hashlib.md5(b"fixture-password").hexdigest()], parsed["password"]
        )
        self.assertNotIn("fixture-password", form)
        self.assertEqual(md5_password("fixture-password"), parsed["password"][0])

    def test_login_xml_and_explicit_zone_selection(self) -> None:
        session = parse_login_response(LOGIN_XML)
        self.assertEqual(123456, session.user_id)
        self.assertEqual([1025, 1026], [zone.zone_index for zone in session.zones])
        zone = select_zone(session, 1026)
        self.assertEqual("127.0.0.2", zone.host)
        self.assertEqual(444, zone.wss_port)
        with self.assertRaises(AuthenticationError):
            select_zone(session, 9999)

    def test_invalid_or_risk_response_fails_closed(self) -> None:
        for value in (
            "not xml",
            "<root><c>invalid</c></root>",
            "<root><c>captcha</c></root>",
            "<root><c>ok</c><u>1</u><sid>s</sid></root>",
        ):
            with self.subTest(value=value), self.assertRaises(AuthenticationError):
                parse_login_response(value)

        with self.assertRaisesRegex(AuthenticationError, "会话正在退出"):
            parse_login_response("<root><c>wait_logout</c></root>")


class ConfigAndMessageTests(unittest.TestCase):
    def test_config_requires_https_unique_labels_and_explicit_zone(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "accounts.json"
            path.write_text(
                json.dumps(
                    {
                        "login_url": "https://fixture.invalid/login",
                        "accounts": [
                            {
                                "label": "alpha",
                                "account": "secret-account",
                                "password": "secret-password",
                                "zone_index": 1025,
                            }
                        ],
                    }
                ),
                encoding="utf-8",
            )
            config = load_config(path)
            self.assertEqual(("alpha",), tuple(x.label for x in config.accounts))
            self.assertEqual(config.accounts, config.select_accounts(["all"]))
            self.assertNotIn("secret-account", repr(config.accounts[0]))
            self.assertNotIn("secret-password", repr(config.accounts[0]))

            path.write_text(
                '{"login_url":"http://bad","accounts":[{"label":"a",'
                '"account":"a","password":"p","zone_index":1}]}',
                encoding="utf-8",
            )
            with self.assertRaises(ConfigError):
                load_config(path)

    def test_send_parser_is_strict_and_removes_nothing_itself(self) -> None:
        message = parse_send_message(
            '#send={"id":42,"param":{"value":7,":ext_seq;":999},"cmd":"query"}|'
        )
        self.assertEqual(42, message.extension_id)
        self.assertEqual(999, message.parameters[":ext_seq;"])
        stream = parse_send_stream(
            '// fixture\n#send={"id":1,"param":{},"cmd":"a"}|\n'
            '#send={"id":2,"param":{"x":1},"cmd":"b"}|'
        )
        self.assertEqual(["a", "b"], [item.command for item in stream])
        for bad in (
            '#send={"cmd":"a","id":1,"param":{}}|',
            '#send={"id":1,"param":{},"cmd":"a"}',
            '#send={"id":true,"param":{},"cmd":"a"}|',
            '#send={"id":1,"param":[],"cmd":"a"}|',
        ):
            with self.subTest(bad=bad), self.assertRaises(ConfigError):
                parse_send_message(bad)

    def test_utf8_bom_message_file(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "messages.txt"
            path.write_text(
                '#send={"id":1,"param":{},"cmd":"fixture"}|',
                encoding="utf-8-sig",
            )
            self.assertEqual("fixture", parse_send_file(path)[0].command)

    def test_script_audit_does_not_persist_arbitrary_message_text(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            context = ScriptContext(
                "fixture", object(), asyncio.Event(), AuditLog(directory)
            )
            context.log("complete-send-parameters-should-not-be-persisted")
            text = next(Path(directory).glob("*.jsonl")).read_text(encoding="utf-8")
            self.assertNotIn("complete-send-parameters", text)
            self.assertIn('"messageLength":', text)


if __name__ == "__main__":
    unittest.main()
