import type { Plugin } from "@opencode-ai/plugin";
import path from "path";
import os from "os";

/**
 * Per-Agent Instructions Plugin
 *
 * Appends agent-specific instructions to the system prompt without replacing
 * the default provider prompt. Instructions are loaded from:
 *
 *   1. .opencode/agent-instructions/<agent>.instructions.md (project-level, highest priority)
 *   2. ~/.config/opencode/agent-instructions/<agent>.instructions.md (global)
 *
 * Usage:
 *   Create a file like `.opencode/agent-instructions/build.instructions.md` with your
 *   custom instructions for the build agent. These will be appended to
 *   the system prompt when that agent is active.
 */
export const AgentInstructionsPlugin: Plugin = async ({
  client,
  directory,
}) => {
  const cache = new Map<string, string | null>();

  async function loadInstructions(agent: string): Promise<string | undefined> {
    if (cache.has(agent)) {
      return cache.get(agent) ?? undefined;
    }

    const paths = [
      // Project-level (higher priority)
      path.join(
        directory,
        ".opencode",
        "agent-instructions",
        `${agent}.instructions.md`,
      ),
      // Global
      path.join(
        os.homedir(),
        ".config",
        "opencode",
        "agent-instructions",
        `${agent}.instructions.md`,
      ),
    ];

    for (const p of paths) {
      const file = Bun.file(p);
      if (await file.exists()) {
        const content = await file.text();
        cache.set(agent, content);
        return content;
      }
    }

    cache.set(agent, null);
    return undefined;
  }

  return {
    "experimental.chat.system.transform": async (input, output) => {
      if (!input.sessionID) return;

      const result = await client.session.messages({
        path: { id: input.sessionID },
      });
      if (!result.data?.length) return;

      const lastUserMsg = [...result.data]
        .reverse()
        .find((m) => m.info?.role === "user");
      if (!lastUserMsg || lastUserMsg.info.role !== "user") return;

      const agent = lastUserMsg.info.agent;
      if (!agent) return;

      const instructions = await loadInstructions(agent);
      if (instructions) {
        output.system.push(instructions);
      }
    },
  };
};
