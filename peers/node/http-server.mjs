import { createServer } from "node:http";
import { createMcpHandler, McpServer } from "@modelcontextprotocol/server";
import * as z from "zod/v4";

function makeServer() {
  const server = new McpServer(
    { name: "mcp-parity-node", version: "0.1.0" },
    {
      instructions: "streamable-http dual-era parity fixture",
      capabilities: { tools: {}, resources: {}, prompts: {} },
    },
  );
  server.registerTool(
    "echo",
    {
      description: "echo msg",
      inputSchema: z.object({ msg: z.string() }),
    },
    async ({ msg }) => ({
      content: [{ type: "text", text: msg }],
    }),
  );
  server.registerResource(
    "hi",
    "memo://hi",
    { description: "hello memo", mimeType: "text/plain" },
    async (uri) => ({
      contents: [{ uri: String(uri), mimeType: "text/plain", text: "hello" }],
    }),
  );
  server.registerPrompt(
    "greet",
    { description: "say hi" },
    async () => ({
      messages: [{ role: "user", content: { type: "text", text: "say hi" } }],
    }),
  );
  return server;
}

const handler = createMcpHandler(makeServer, { responseMode: "json" });

function incomingToRequest(req, body) {
  const host = req.headers.host || "127.0.0.1";
  const url = `http://${host}${req.url}`;
  const headers = new Headers();
  for (const [key, value] of Object.entries(req.headers)) {
    if (value == null) continue;
    if (key === "connection" || key === "transfer-encoding" || key === "keep-alive") continue;
    if (Array.isArray(value)) value.forEach((item) => headers.append(key, item));
    else headers.set(key, value);
  }
  const method = req.method || "GET";
  const init = { method, headers };
  if (method !== "GET" && method !== "HEAD") init.body = body;
  return new Request(url, init);
}

async function writeResponse(res, response) {
  const headers = {};
  response.headers.forEach((value, key) => {
    headers[key] = value;
  });
  res.writeHead(response.status, headers);
  if (!response.body) {
    res.end();
    return;
  }
  res.end(Buffer.from(await response.arrayBuffer()));
}

const port = Number(process.argv[2] || process.env.MCP_PARITY_HTTP_PORT || 0);
const server = createServer((req, res) => {
  const chunks = [];
  req.on("data", (chunk) => chunks.push(chunk));
  req.on("end", () => {
    handler
      .fetch(incomingToRequest(req, Buffer.concat(chunks)))
      .then((response) => writeResponse(res, response))
      .catch((err) => {
        res.writeHead(500, { "content-type": "text/plain" });
        res.end(String(err?.stack || err));
      });
  });
});

server.listen(port, "127.0.0.1", () => {
  const { port: bound } = server.address();
  process.stdout.write(`MCP_HTTP_LISTEN ${bound}\n`);
});
