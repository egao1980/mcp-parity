"""Probe echo inputSchema: missing `msg` and wrong-type `msg`."""

from __future__ import annotations

import re
from typing import Any


def rpc_code(exc: BaseException) -> int | str | None:
    for attr in ("code",):
        code = getattr(exc, attr, None)
        if isinstance(code, int):
            return code
    for attr in ("error", "rpc_error", "cause"):
        inner = getattr(exc, attr, None)
        if inner is None:
            continue
        code = getattr(inner, "code", None)
        if isinstance(code, int):
            return code
        if isinstance(inner, dict):
            code = inner.get("code")
            if isinstance(code, int):
                return code
    match = re.search(r"-32\d{3}", str(exc))
    return int(match.group(0)) if match else None


async def probe_invalid_echo(client: Any) -> dict[str, int | str | None]:
    async def one(args: dict[str, object]) -> int | str | None:
        try:
            result = await client.call_tool("echo", args)
            if getattr(result, "is_error", False) or getattr(result, "isError", False):
                return "isError"
            return None
        except Exception as exc:  # noqa: BLE001 — parity probe, any failure shape
            return rpc_code(exc)

    return {
        "invalidMissing": await one({}),
        "invalidType": await one({"msg": 1}),
    }
