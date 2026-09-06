import { McpServer } from "@modelcontextprotocol/server";
import { serveStdio } from "@modelcontextprotocol/server/stdio";
import { registerParityCatalog } from "./catalog.mjs";

serveStdio(() => {
  const server = new McpServer(
    { name: "mcp-parity-node", version: "0.1.0" },
    {
      instructions: "stdio dual-era parity fixture",
      capabilities: { tools: {}, resources: {}, prompts: {} },
    },
  );
  registerParityCatalog(server);
  return server;
});
