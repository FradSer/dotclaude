import { promises as fs } from "node:fs";
import path from "node:path";
import { config } from "../config.js";
import {
  appendAgentsDescriptionIfNeeded,
  formatAgentsDescription,
  formatCodexFrontmatter,
  getCodexFileName,
  normaliseForCursor,
  removeTaskToolWarning,
} from "../transformers/index.js";

export async function generateCodex(pluginId, data, _platform) {
  const baseDir = path.join(config.distRoot, "codex", "prompts");
  await fs.mkdir(baseDir, { recursive: true });

  const agentsDescription = formatAgentsDescription(data.agents);

  if (Array.isArray(data.commands)) {
    for (const command of data.commands) {
      const lines = [];
      lines.push(formatCodexFrontmatter(command, pluginId));
      lines.push("");
      lines.push(`# ${command.title}`);
      lines.push("");
      lines.push(`**Summary:** ${command.summary}`);
      lines.push("");

      let instructions = removeTaskToolWarning(
        normaliseForCursor(command.instructions ?? ""),
      ).trim();
      instructions = appendAgentsDescriptionIfNeeded(instructions, agentsDescription);
      lines.push(instructions);
      lines.push("");

      const fileName = getCodexFileName(pluginId, command.slug);
      const filePath = path.join(baseDir, fileName);
      await fs.writeFile(filePath, `${lines.join("\n")}`);
    }
  }
}
