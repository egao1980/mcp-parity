#!/usr/bin/env python3
from __future__ import annotations

from typing import Any

import mcp.types
from fastmcp import FastMCP

mcp = FastMCP(
    "mcp-parity-python",
    instructions="stdio dual-era parity fixture",
    version="0.1.0",
)

_ELICIT_SCHEMA = {
    "type": "object",
    "properties": {"value": {"type": "string"}},
    "required": ["value"],
}


@mcp.tool
def echo(msg: str) -> str:
    """echo msg"""
    return msg


@mcp.tool(name="need-input")
def need_input() -> str:
    """trigger elicitation / input_required"""
    return "got-input"


@mcp.resource("memo://hi")
def hi() -> str:
    return "hello"


@mcp.prompt
def greet() -> str:
    return "say hi"


def _install_need_input_mrtr() -> None:
    """Return MRTR input_required from need-input. FastMCP 3 has no MRTR helper."""
    inner = mcp._mcp_server.request_handlers[mcp.types.CallToolRequest]

    async def handler(req: mcp.types.CallToolRequest) -> mcp.types.ServerResult:
        if req.params.name != "need-input":
            return await inner(req)
        extra: dict[str, Any] = dict(req.params.model_extra or {})
        if extra.get("inputResponses"):
            return mcp.types.ServerResult(
                mcp.types.CallToolResult(
                    content=[mcp.types.TextContent(type="text", text="got-input")]
                )
            )
        return mcp.types.ServerResult(
            mcp.types.CallToolResult.model_validate(
                {
                    "content": [],
                    "resultType": "input_required",
                    "inputRequests": {
                        "elicit": {
                            "method": "elicitation/create",
                            "params": {
                                "message": "need a value",
                                "requestedSchema": _ELICIT_SCHEMA,
                            },
                        }
                    },
                }
            )
        )

    mcp._mcp_server.request_handlers[mcp.types.CallToolRequest] = handler


_install_need_input_mrtr()


if __name__ == "__main__":
    mcp.run()
