import { config } from "../config.js";
import { generateClaude } from "./claude.js";
import { generateCodex } from "./codex.js";
import { generateCursor } from "./cursor.js";
import { generateGemini } from "./gemini.js";

const platformHandlers = {
  claude: generateClaude,
  cursor: generateCursor,
  codex: generateCodex,
  gemini: generateGemini,
};

export async function generateForPlugin(promptFile, platforms) {
  const { data } = promptFile;
  const pluginId = data.plugin.id;

  if (!Array.isArray(data.commands)) {
    console.warn(`No commands defined for plugin ${pluginId}. Skipping.`);
  }

  for (const platformId of config.platformOrder) {
    const platform = platforms[platformId];
    if (!platform) {
      console.warn(`Platform ${platformId} metadata missing. Skipping.`);
      continue;
    }

    const handler = platformHandlers[platformId];
    if (handler) {
      await handler(pluginId, data, platform);
    } else {
      console.warn(`Unhandled platform ${platformId}`);
    }
  }
}
