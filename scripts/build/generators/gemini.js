import { promises as fs } from "node:fs";
import path from "node:path";
import { config } from "../config.js";
import {
  appendAgentsDescriptionIfNeeded,
  appendUserInputHint,
  formatAgentsDescription,
  hasArgumentsPlaceholder,
  normaliseForCursor,
  removeTaskToolWarning,
  replaceArgumentsPlaceholders,
} from "../transformers/index.js";
import { buildGeminiToml } from "../writers.js";

export async function generateGemini(pluginId, data, _platform) {
  const baseDir = path.join(config.distRoot, "gemini");
  const commandsRoot = path.join(baseDir, "commands");
  await fs.mkdir(commandsRoot, { recursive: true });

  const agentsDescription = formatAgentsDescription(data.agents);

  if (Array.isArray(data.commands)) {
    for (const command of data.commands) {
      const overrides = command.platform_overrides?.gemini ?? {};
      const namespace = overrides.namespace ?? pluginId;
      const filename = overrides.filename ?? command.slug;
      const commandDir = path.join(commandsRoot, namespace);
      await fs.mkdir(commandDir, { recursive: true });
      const hasArguments = hasArgumentsPlaceholder(command.instructions);
      let prompt = removeTaskToolWarning(normaliseForCursor(command.instructions ?? "")).trim();
      prompt = replaceArgumentsPlaceholders(prompt, command.argument_hint);
      prompt = appendAgentsDescriptionIfNeeded(prompt, agentsDescription);
      prompt = appendUserInputHint(prompt, hasArguments, command.argument_hint);
      const toml = buildGeminiToml(command.summary, prompt);
      const filePath = path.join(commandDir, `${filename}.toml`);
      await fs.writeFile(filePath, toml);
    }
  }
}
