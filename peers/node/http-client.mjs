import { Client, StreamableHTTPClientTransport } from "@modelcontextprotocol/client";

function textOf(result) {
  const content = result?.content;
  if (Array.isArray(content) && content[0]?.text) return content[0].text;
  return String(result ?? "");
}

function resourceText(result) {
  const contents = result?.contents;
  if (Array.isArray(contents) && contents[0]?.text) return contents[0].text;
  return String(result ?? "");
}

function promptText(result) {
  return JSON.stringify(result?.messages ?? result ?? "");
}

const url = process.argv[2];
if (!url) {
  console.error("usage: http-client.mjs <url>");
  process.exit(2);
}

const client = new Client({ name: "mcp-parity-node", version: "0.1.0" });
client.setVersionNegotiation({ mode: "auto" });
await client.connect(new StreamableHTTPClientTransport(new URL(url)), {
  timeout: 120_000,
});

const tools = await client.listTools();
const echo = await client.callTool({ name: "echo", arguments: { msg: "pong" } });
const resource = await client.readResource({ uri: "memo://hi" });
const prompt = await client.getPrompt({ name: "greet" });

const rec = {
  era: client.getProtocolEra?.() ?? client.getNegotiatedProtocolVersion?.() ?? null,
  tools: (tools.tools ?? []).map((t) => t.name),
  echo: textOf(echo),
  resource: resourceText(resource),
  prompt: promptText(prompt),
};
process.stdout.write(`${JSON.stringify(rec)}\n`);
await client.close?.();
process.exit(0);
