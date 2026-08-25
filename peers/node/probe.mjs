/** Probe echo inputSchema: missing `msg` and wrong-type `msg`. */

export function rpcCode(err) {
  if (err && typeof err.code === "number") return err.code;
  if (err?.cause && typeof err.cause.code === "number") return err.cause.code;
  if (err?.data && typeof err.data.code === "number") return err.data.code;
  const match = String(err?.message ?? err ?? "").match(/-32\d{3}/);
  return match ? Number(match[0]) : null;
}

export async function probeInvalidEcho(client) {
  async function one(args) {
    try {
      const result = await client.callTool({ name: "echo", arguments: args });
      if (result?.isError) return "isError";
      return null;
    } catch (err) {
      return rpcCode(err);
    }
  }
  return {
    invalidMissing: await one({}),
    invalidType: await one({ msg: 1 }),
  };
}
