export const CLIENT_CAPABILITIES = {
  elicitation: { form: {} },
  sampling: {},
};

export function attachInputHandlers(client) {
  client.setRequestHandler("elicitation/create", async () => ({
    action: "accept",
    content: { value: "ok" },
  }));
  client.setRequestHandler("sampling/createMessage", async () => ({
    model: "mcp-parity",
    role: "assistant",
    content: { type: "text", text: "ok" },
  }));
}

export async function probeNeedInput(client) {
  const result = await client.callTool({ name: "need-input", arguments: {} });
  const content = result?.content;
  const text =
    Array.isArray(content) && content[0]?.text ? content[0].text : String(result ?? "");
  return {
    needInput: text,
    needInputType: result?.resultType ?? null,
  };
}
