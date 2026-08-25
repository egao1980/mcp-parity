# mcp-parity matrix

Status: `have` · `partial` · `missing` · `skip`

Catalog: `echo` tool, `memo://hi` resource, `greet` prompt.

## stdio

| Route | Lisp→Lisp | Lisp→Node | Lisp→Python | Node→Lisp | Python→Lisp |
|-------|-----------|-----------|-------------|-----------|-------------|
| era negotiate | have | have | have | have | have |
| `echo` tool | have | have | have | have | have |
| `memo://hi` | have | have | have | have | have |
| `greet` prompt | have | have | have | have | have |
| `echo` inputSchema `-32602` | have | have | have | have | have |

## Streamable HTTP

| Route | Lisp→Lisp | Lisp→Node | Lisp→Python | Node→Lisp | Python→Lisp |
|-------|-----------|-----------|-------------|-----------|-------------|
| era negotiate | have | have | have | have | have |
| `echo` tool | have | have | have | have | have |
| `memo://hi` | have | have | have | have | have |
| `greet` prompt | have | have | have | have | have |
| `echo` inputSchema `-32602` | have | have | have | have | have |

## skipped

| Route | Lisp→Lisp | Lisp→Node | Lisp→Python | Node→Lisp | Python→Lisp |
|-------|-----------|-----------|-------------|-----------|-------------|
| `input_required` | skip | skip | skip | skip | skip |

Era may land modern (`2026-07-28`) or legacy (`2025-11-25`); both count as `have` if the catalog works.
HTTP GET SSE is optional (Lisp answers 405); Node SDK treats that as spec-ok.
`echo` inputSchema: spec is JSON-RPC `-32602`. FastMCP 3 currently returns a tool `isError` result — still counted as validation `have`.
