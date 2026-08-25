import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import { probeInvalidEcho } from "./probe.mjs";

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

const argv = process.argv.slice(2);
if (argv.length < 1) {
  console.error("usage: client.mjs <server-command...>");
  process.exit(2);
}

function childEnv() {
  // Official SDK inherits a tiny allow-list. Lisp needs CL_SOURCE_REGISTRY / ASDF.
  const env = {};
  for (const [key, value] of Object.entries(process.env)) {
    if (typeof value === "string" && !value.startsWith("()")) env[key] = value;
  }
  return env;
}

const transport = new StdioClientTransport({
  command: argv[0],
  args: argv.slice(1),
  env: childEnv(),
});

const client = new Client({ name: "mcp-parity-node", version: "0.1.0" });
client.setVersionNegotiation({ mode: "auto" });
await client.connect(transport, { timeout: 120_000 });

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
  ...(await probeInvalidEcho(client)),
};
process.stdout.write(`${JSON.stringify(rec)}\n`);
await client.close?.();
process.exit(0);
