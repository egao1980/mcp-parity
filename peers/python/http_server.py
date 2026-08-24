#!/usr/bin/env python3
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from server import mcp

if __name__ == "__main__":
    port = int(sys.argv[1] if len(sys.argv) > 1 else 0)
    if port <= 0:
        print("usage: http_server.py <port>", file=sys.stderr)
        raise SystemExit(2)
    mcp.run(transport="http", host="127.0.0.1", port=port, path="/mcp")
