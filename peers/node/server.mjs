import { McpServer } from "@modelcontextprotocol/server";
import { serveStdio } from "@modelcontextprotocol/server/stdio";
import * as z from "zod/v4";

serveStdio(() => {
  const server = new McpServer(
    { name: "mcp-parity-node", version: "0.1.0" },
    {
      instructions: "stdio dual-era parity fixture",
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
      messages: [
        { role: "user", content: { type: "text", text: "say hi" } },
      ],
    }),
  );
  return server;
});
