# mcp-parity

Interop canary: **[`mcp-protocol`](https://github.com/egao1980/mcp-protocol)** vs **FastMCP 3** (Python) and the official **Node MCP SDK v2**, both ways, over **stdio** and **Streamable HTTP**.

Lisp owns the harness and assertions. Node/Python peers are the SUT, not refresh scripts.

```
stdio
  Lisp client  →  Lisp server   (in-process, always)
  Lisp client  →  Node server   (@modelcontextprotocol/server serveStdio)
  Lisp client  →  Python server (FastMCP 3)
  Node client  →  Lisp server   (mcp-backend-stdio)
  Python client → Lisp server

Streamable HTTP
  Lisp client  →  Lisp server   (hunchentoot + make-mcp-app /mcp)
  Lisp client  →  Node server   (createMcpHandler)
  Lisp client  →  Python server (FastMCP 3 transport=http)
  Node client  →  Lisp server   (StreamableHTTPClientTransport)
  Python client → Lisp server   (FastMCP Client URL)
```

Dual-era: modern `2026-07-28` (`server/discover`) and legacy `2025-11-25` (`initialize`). A pass is a working catalog (`echo` / `memo://hi` / `greet`) **and** `echo` inputSchema rejection (`{}` / `{msg:1}` → JSON-RPC `-32602`), not a forced era.

## Run

```bash
cd peers/node && npm install
cd ../python && uv sync
export MCP_PARITY_PEERS=1
ros -e '(asdf:test-system "mcp-parity")' -q
```

Lisp↔Lisp only (stdio in-process + HTTP):

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

- Sibling-process `server/discover` probe when a legacy server dies on unknown methods
- FastMCP 3 tool `isError` vs spec `-32602` for `inputSchema` failures
- Published `mcp-backend-streamable-http:0.1.1` `make-mcp-app` maps uncaught `mcp-error` → `-32603` (HTTP fixture wraps like `serve-mcp`)
- `input_required` / Tasks / OAuth

## License

MIT
