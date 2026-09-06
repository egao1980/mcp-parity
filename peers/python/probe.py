"""Parity probes: echo inputSchema and need-input / input_required."""

from __future__ import annotations

import re
from typing import Any

import mcp.types
from pydantic import Field


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


class LooseToolResult(mcp.types.Result):
    """CallToolResult plus MRTR fields. Lisp input_required has no `content`."""

    content: list[mcp.types.ContentBlock] = Field(default_factory=list)
    structuredContent: dict[str, Any] | None = None
    isError: bool = False


def _extra(result: Any) -> dict[str, Any]:
    extra = getattr(result, "model_extra", None)
    return extra if isinstance(extra, dict) else {}


def _result_type(result: Any) -> str | None:
    extra = _extra(result)
    value = extra.get("resultType") or getattr(result, "resultType", None)
    return value if isinstance(value, str) else None


def _input_requests(result: Any) -> dict[str, Any]:
    extra = _extra(result)
    raw = extra.get("inputRequests") or getattr(result, "inputRequests", None) or {}
    return raw if isinstance(raw, dict) else {}


def _fulfill(input_requests: dict[str, Any]) -> dict[str, Any]:
    out: dict[str, Any] = {}
    for key, req in input_requests.items():
        method = (req or {}).get("method") if isinstance(req, dict) else None
        if method == "sampling/createMessage":
            out[key] = {
                "role": "assistant",
                "model": "mcp-parity",
                "content": {"type": "text", "text": "ok"},
            }
        elif method == "roots/list":
            out[key] = {"roots": []}
        else:
            out[key] = {"action": "accept", "content": {"value": "ok"}}
    return out


def _tool_text(result: Any) -> str:
    content = getattr(result, "content", None) or []
    if content:
        first = content[0]
        return str(getattr(first, "text", first) or "")
    return ""


async def probe_need_input(client: Any) -> dict[str, str | None]:
    """Call need-input and fulfill a one-round input_required result."""

    async def call(**extra: Any) -> LooseToolResult:
        params = {"name": "need-input", "arguments": {}, **extra}
        return await client.session.send_request(
            mcp.types.ClientRequest(
                mcp.types.CallToolRequest(
                    params=mcp.types.CallToolRequestParams.model_validate(params)
                )
            ),
            LooseToolResult,
        )

    result = await call()
    if _result_type(result) == "input_required":
        extra = _extra(result)
        retry: dict[str, Any] = {"inputResponses": _fulfill(_input_requests(result))}
        state = extra.get("requestState") or getattr(result, "requestState", None)
        if state is not None:
            retry["requestState"] = state
        result = await call(**retry)
    return {
        "needInput": _tool_text(result),
        "needInputType": _result_type(result),
    }
