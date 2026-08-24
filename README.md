# mcp-parity

Interop canary: **[`mcp-protocol`](https://github.com/egao1980/mcp-protocol)** vs **FastMCP 3** (Python) and the official **Node MCP SDK v2**, both ways, over **stdio**.

Lisp owns the harness and assertions. Node/Python peers are the SUT, not refresh scripts.

```
Lisp client  →  Lisp server   (in-process, always)
Lisp client  →  Node server   (@modelcontextprotocol/server serveStdio)
Lisp client  →  Python server (FastMCP 3)
Node client  →  Lisp server   (mcp-backend-stdio)
Python client → Lisp server
```

Dual-era: modern `2026-07-28` (`server/discover`) and legacy `2025-11-25` (`initialize`). A pass is a working catalog (`echo` / `memo://hi` / `greet`), not a forced era.

## Run

```bash
cd peers/node && npm install
cd ../python && uv sync
export MCP_PARITY_PEERS=1
ros -e '(asdf:test-system "mcp-parity")' -q
```

Lisp↔Lisp only:

```bash
export MCP_PARITY_PEERS=0
ros -e '(asdf:test-system "mcp-parity")' -q
```

## Matrix

See [MATRIX.md](MATRIX.md).

## Env

| Variable | Default | Meaning |
|----------|---------|---------|
| `MCP_PARITY_PEERS` | on | `0` skips Node/Python peers |

## Gaps this is meant to surface

- Streamable HTTP (Lisp × FastMCP/Node) — stdio first
- Sibling-process `server/discover` probe when a legacy server dies on unknown methods
- `input_required` / Tasks / OAuth

## License

MIT
