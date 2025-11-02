import { promises as fs } from "node:fs";
import path from "node:path";
import { config } from "../config.js";
import { injectTaskToolWarning } from "../transformers/index.js";
import { formatTools, writeClaudeMarkdown } from "../writers.js";

export async function generateClaude(pluginId, data, _platform) {
  const baseDir = path.join(config.distRoot, "claude", "plugins", pluginId);
  await fs.mkdir(baseDir, { recursive: true });

  if (Array.isArray(data.commands)) {
    const commandsDir = path.join(baseDir, "commands");
    await fs.mkdir(commandsDir, { recursive: true });

    for (const command of data.commands) {
      const claudeOverrides = command.platform_overrides?.claude ?? {};
      const allowedTools = claudeOverrides.allowed_tools ?? command.requirements?.tools;
      const frontMatter = {};
      if (allowedTools) {
        frontMatter["allowed-tools"] = formatTools(allowedTools);
      }
      frontMatter.description = command.summary;
      if (claudeOverrides.model) {
        frontMatter.model = claudeOverrides.model;
      }
      if (command.argument_hint) {
        frontMatter["argument-hint"] = command.argument_hint;
      }
      let body = command.instructions?.trim() ?? "";
      if (command.require_task_tool) {
        body = injectTaskToolWarning(body);
      }
      const filePath = path.join(commandsDir, `${command.slug}.md`);
      await writeClaudeMarkdown(filePath, frontMatter, body);
    }
  }

  if (Array.isArray(data.agents)) {
    const agentsDir = path.join(baseDir, "agents");
    await fs.mkdir(agentsDir, { recursive: true });

    for (const agent of data.agents) {
      const frontMatter = {
        name: agent.slug,
        description: agent.summary,
      };
      const claudeOverrides = agent.platform_overrides?.claude ?? {};
      if (claudeOverrides.model) {
        frontMatter.model = claudeOverrides.model;
      }
      if (claudeOverrides.color) {
        frontMatter.color = claudeOverrides.color;
      }
      const body = agent.instructions?.trim() ?? "";
      const filePath = path.join(agentsDir, `${agent.slug}.md`);
      await writeClaudeMarkdown(filePath, frontMatter, body);
    }
  }
}
