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
import { writeMarkdownWithFrontMatter } from "../writers.js";

export async function generateCursor(pluginId, data, _platform) {
  const baseDir = path.join(config.distRoot, "cursor");
  const commandsDir = path.join(baseDir, "commands", pluginId);
  await fs.mkdir(commandsDir, { recursive: true });

  const agentsDescription = formatAgentsDescription(data.agents);

  if (Array.isArray(data.commands)) {
    for (const command of data.commands) {
      const cursorOverrides = command.platform_overrides?.cursor ?? {};
      if (!cursorOverrides.command?.palette) continue;
      const commandFrontMatter = {
        description: command.summary,
        trigger: cursorOverrides.command.palette,
      };
      const hasArguments = hasArgumentsPlaceholder(command.instructions);
      let commandBody = removeTaskToolWarning(
        normaliseForCursor(command.instructions ?? ""),
      ).trim();
      commandBody = replaceArgumentsPlaceholders(commandBody, command.argument_hint);
      commandBody = appendAgentsDescriptionIfNeeded(commandBody, agentsDescription);
      commandBody = appendUserInputHint(commandBody, hasArguments, command.argument_hint);
      const commandPath = path.join(commandsDir, `${command.slug}.md`);
      await writeMarkdownWithFrontMatter(commandPath, commandFrontMatter, commandBody);
    }
  }
}
