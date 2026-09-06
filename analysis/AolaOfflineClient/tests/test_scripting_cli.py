from __future__ import annotations

import argparse
import asyncio
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import AsyncMock, patch

from aola_offline.audit import AuditLog
from aola_offline.cli import _run
from aola_offline.errors import ScriptLoadError
from aola_offline.models import AccountProfile
from aola_offline.scripting import (
    InteractionScript,
    ScriptContext,
    discover_scripts,
    load_script,
    run_script_for_accounts,
)


class FakeClient:
    def __init__(self) -> None:
        self.closed = False

    async def close(self) -> None:
        self.closed = True

    async def send(self, extension_id, command, parameters, room_id=-1):
        return (extension_id, command, parameters, room_id)

    def recv(self, predicate=None, *, max_queue=256):
        return object()


class ScriptTests(unittest.IsolatedAsyncioTestCase):
    async def test_script_must_subscribe_before_send(self) -> None:
        client = FakeClient()
        with tempfile.TemporaryDirectory() as directory:
            context = ScriptContext(
                "fixture", client, asyncio.Event(), AuditLog(directory)
            )
            with self.assertRaisesRegex(RuntimeError, "先调用 context.recv"):
                await context.send(42, "query", {})
            context.recv()
            result = await context.send(42, "query", {"value": 7})
        self.assertEqual((42, "query", {"value": 7}, -1), result)

    def test_discovery_requires_metadata_and_async_entrypoint(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory)
            marker = source / "imported.txt"
            (source / "valid.py").write_text(
                "from pathlib import Path\n"
                f"Path({str(marker)!r}).write_text('imported', encoding='utf-8')\n"
                'SCRIPT_NAME="Fixture"\nSCRIPT_DESCRIPTION="Does nothing"\n'
                "async def run(context):\n    return None\n",
                encoding="utf-8",
            )
            (source / "_private.py").write_text("raise RuntimeError()", encoding="utf-8")
            scripts = discover_scripts(source)
            self.assertEqual(("valid",), tuple(item.module_name for item in scripts))
            self.assertFalse(marker.exists())
            self.assertEqual("Fixture", load_script(source / "valid.py").name)
            self.assertTrue(marker.exists())

            (source / "bad.py").write_text(
                'SCRIPT_NAME="Bad"\ndef run(context):\n    return None\n',
                encoding="utf-8",
            )
            with self.assertRaises(ScriptLoadError):
                load_script(source / "bad.py")

    async def test_max_five_accounts_and_failure_isolation(self) -> None:
        profiles = tuple(
            AccountProfile(f"account-{index}", f"u{index}", "password", 1025)
            for index in range(8)
        )
        active = 0
        maximum = 0
        clients: list[FakeClient] = []

        async def connector(profile, **kwargs):
            nonlocal active, maximum
            client = FakeClient()
            clients.append(client)
            active += 1
            maximum = max(maximum, active)
            return client

        async def run(context):
            nonlocal active
            try:
                await asyncio.sleep(0.02)
                if context.label == "account-2":
                    raise RuntimeError("fixture failure")
            finally:
                active -= 1

        script = InteractionScript("fixture", "Fixture", "", run)
        with tempfile.TemporaryDirectory() as directory:
            results = await run_script_for_accounts(
                script,
                profiles,
                login_url="https://fixture.invalid/login",
                transport_mode="tcp",
                cancelled=asyncio.Event(),
                audit=AuditLog(directory),
                connector=connector,
            )
        self.assertLessEqual(maximum, 5)
        self.assertFalse(results["account-2"].success)
        self.assertTrue(results["account-3"].success)
        self.assertTrue(all(client.closed for client in clients))

    async def test_cancellation_closes_connected_account(self) -> None:
        profile = AccountProfile("fixture", "account", "password", 1025)
        started = asyncio.Event()
        client = FakeClient()

        async def connector(profile, **kwargs):
            return client

        async def run(context):
            started.set()
            await asyncio.Event().wait()

        script = InteractionScript("fixture", "Fixture", "", run)
        with tempfile.TemporaryDirectory() as directory:
            task = asyncio.create_task(
                run_script_for_accounts(
                    script,
                    (profile,),
                    login_url="https://fixture.invalid/login",
                    transport_mode="tcp",
                    cancelled=asyncio.Event(),
                    audit=AuditLog(directory),
                    connector=connector,
                )
            )
            await started.wait()
            task.cancel()
            with self.assertRaises(asyncio.CancelledError):
                await task
        self.assertTrue(client.closed)


class CliTests(unittest.IsolatedAsyncioTestCase):
    @staticmethod
    def write_config(directory: str) -> Path:
        path = Path(directory) / "accounts.json"
        path.write_text(
            json.dumps(
                {
                    "login_url": "https://fixture.invalid/login",
                    "accounts": [
                        {
                            "label": "fixture",
                            "account": "account-secret",
                            "password": "password-secret",
                            "zone_index": 1025,
                        }
                    ],
                }
            ),
            encoding="utf-8",
        )
        return path

    async def test_check_config_never_connects_or_confirms(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            args = argparse.Namespace(
                config=str(self.write_config(directory)),
                command="check-config",
                transport="auto",
            )
            with patch("aola_offline.cli._confirm") as confirm, patch(
                "aola_offline.cli.AolaClient.connect", new_callable=AsyncMock
            ) as connect:
                self.assertEqual(0, await _run(args))
            confirm.assert_not_called()
            connect.assert_not_awaited()

    async def test_run_shows_one_confirmation_before_any_connection(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            scripts = Path(directory) / "scripts"
            scripts.mkdir()
            (scripts / "fixture.py").write_text(
                'SCRIPT_NAME="Fixture Script"\n'
                'SCRIPT_DESCRIPTION="Fixture description"\n'
                "async def run(context):\n    return None\n",
                encoding="utf-8",
            )
            args = argparse.Namespace(
                config=str(self.write_config(directory)),
                command="run",
                transport="tcp",
                accounts=["fixture"],
                script="fixture",
                scripts_dir=str(scripts),
            )
            with patch("aola_offline.cli._confirm", return_value=False) as confirm, patch(
                "aola_offline.cli._run_script_command", new_callable=AsyncMock
            ) as run_script:
                self.assertEqual(2, await _run(args))
            confirm.assert_called_once()
            run_script.assert_not_awaited()
            summary = confirm.call_args.args[0]
            self.assertIn("fixture（区服 1025）", summary)
            self.assertIn("Fixture Script", summary)
            self.assertIn("Fixture description", summary)
            self.assertNotIn("account-secret", summary)
            self.assertNotIn("password-secret", summary)


if __name__ == "__main__":
    unittest.main()
