import { acceptedContent, inputRequired } from "@modelcontextprotocol/server";
import * as z from "zod/v4";

export const ELICIT_SCHEMA = {
  type: "object",
  properties: { value: { type: "string" } },
  required: ["value"],
};

export function registerParityCatalog(server) {
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
  server.registerTool(
    "need-input",
    {
      description: "trigger elicitation / input_required",
      inputSchema: z.object({}),
    },
    async (_args, ctx) => {
      const got = acceptedContent(ctx?.mcpReq?.inputResponses, "elicit");
      if (!got) {
        return inputRequired({
          inputRequests: {
            elicit: inputRequired.elicit({
              message: "need a value",
              requestedSchema: ELICIT_SCHEMA,
            }),
          },
        });
      }
      return { content: [{ type: "text", text: "got-input" }] };
    },
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
