#!/usr/bin/env python3
from __future__ import annotations

import asyncio
import json
import sys

from fastmcp import Client

from probe import probe_invalid_echo


def _text(result: object) -> str:
    data = getattr(result, "data", None)
    if data is not None:
        return str(data)
    content = getattr(result, "content", None)
    if content:
        first = content[0]
        return str(getattr(first, "text", first))
    return str(result)


def _resource_text(contents: object) -> str:
    if not contents:
        return ""
    first = contents[0]
    return str(getattr(first, "text", first))


def _prompt_text(prompt: object) -> str:
    messages = getattr(prompt, "messages", prompt)
    return str(messages)


async def main() -> None:
    if len(sys.argv) < 2:
        print("usage: http_client.py <url>", file=sys.stderr)
        raise SystemExit(2)
    async with Client(sys.argv[1]) as client:
        tools = await client.list_tools()
        echo = await client.call_tool("echo", {"msg": "pong"})
        resource = await client.read_resource("memo://hi")
        prompt = await client.get_prompt("greet")
        rec = {
            "era": getattr(client, "protocol_version", None) or "legacy",
            "tools": [t.name for t in tools],
            "echo": _text(echo),
            "resource": _resource_text(resource),
            "prompt": _prompt_text(prompt),
            **(await probe_invalid_echo(client)),
        }
        print(json.dumps(rec, ensure_ascii=False), flush=True)


if __name__ == "__main__":
    asyncio.run(main())
