#!/usr/bin/env python3
from __future__ import annotations

from fastmcp import FastMCP

mcp = FastMCP(
    "mcp-parity-python",
    instructions="stdio dual-era parity fixture",
    version="0.1.0",
)


@mcp.tool
def echo(msg: str) -> str:
    """echo msg"""
    return msg


@mcp.resource("memo://hi")
def hi() -> str:
    return "hello"


@mcp.prompt
def greet() -> str:
    return "say hi"


if __name__ == "__main__":
    mcp.run()
