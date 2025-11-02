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

export async function generateCodex(pluginId, data, _platform) {
  const baseDir = path.join(config.distRoot, "codex", "prompts", pluginId);
  await fs.mkdir(baseDir, { recursive: true });

  const agentsDescription = formatAgentsDescription(data.agents);

  if (Array.isArray(data.commands)) {
    for (const command of data.commands) {
      const lines = [];
      lines.push(`# ${command.title}`);
      lines.push("");
      lines.push(`**Summary:** ${command.summary}`);
      if (command.requirements?.tools?.length) {
        lines.push("");
        lines.push(`**Tools:** ${command.requirements.tools.join(", ")}`);
      }
      lines.push("");
      lines.push("---");
      lines.push("");
      const hasArguments = hasArgumentsPlaceholder(command.instructions);
      let instructions = removeTaskToolWarning(
        normaliseForCursor(command.instructions ?? ""),
      ).trim();
      instructions = replaceArgumentsPlaceholders(instructions, command.argument_hint);
      instructions = appendAgentsDescriptionIfNeeded(instructions, agentsDescription);
      instructions = appendUserInputHint(instructions, hasArguments, command.argument_hint);
      lines.push(instructions);
      lines.push("");
      const filePath = path.join(baseDir, `${command.slug}.md`);
      await fs.writeFile(filePath, `${lines.join("\n")}`);
    }
  }
}
