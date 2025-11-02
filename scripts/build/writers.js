import { promises as fs } from "node:fs";
import path from "node:path";
import YAML from "yaml";
import { config } from "./config.js";

export function formatTools(tools) {
  if (!tools || (Array.isArray(tools) && tools.length === 0)) return undefined;
  if (Array.isArray(tools)) {
    if (tools.length === 1) return tools[0];
    return tools.join(", ");
  }
  return tools;
}

export async function writeClaudeMarkdown(filePath, frontMatter, body) {
  const lines = ["---"];

  for (const [key, value] of Object.entries(frontMatter)) {
    if (value === undefined || value === null) continue;
    lines.push(`${key}: ${value}`);
  }

  lines.push("---");
  lines.push("");
  lines.push(body.trim());
  lines.push("");
  await fs.writeFile(filePath, lines.join("\n"));
}

export async function writeMarkdownWithFrontMatter(filePath, frontMatter, body) {
  const fm =
    frontMatter && Object.keys(frontMatter).length > 0
      ? `---\n${YAML.stringify(frontMatter)}---\n\n`
      : "";
  const content = `${fm}${body.trim()}\n`;
  await fs.writeFile(filePath, content);
}

export function buildGeminiToml(description, prompt) {
  return `description="${escapeTomlString(description)}"\nprompt = """\n${prompt}\n"""\n`;
}

function escapeTomlString(value) {
  return value.replaceAll('"', '\\"');
}

export async function writeClaudeMarketplace(promptFiles) {
  const marketplace = {
    name: "fradser-dotclaude",
    description:
      "FradSer's Claude Code plugin marketplace featuring specialized agents and workflow automation",
    owner: {
      name: "FradSer",
      url: "https://frad.me",
    },
    plugins: promptFiles.map((file) => {
      const pluginId = file.data.plugin.id;
      return {
        name: pluginId,
        source: `./dist/claude/plugins/${pluginId}`,
        description: file.data.plugin.summary,
        category: file.data.plugin.category,
      };
    }),
  };

  await fs.mkdir(path.dirname(config.claudeMarketplacePath), { recursive: true });
  await fs.writeFile(config.claudeMarketplacePath, `${JSON.stringify(marketplace, null, 2)}\n`);
}

export async function writeManifest(promptFiles, platforms) {
  const manifest = {
    generatedAt: new Date().toISOString(),
    plugins: promptFiles.map((file) => ({
      id: file.data.plugin.id,
      source: path.relative(config.repoRoot, file.path),
      commands: (file.data.commands ?? []).map((command) => command.slug),
      agents: (file.data.agents ?? []).map((agent) => agent.slug),
    })),
    platforms: config.platformOrder
      .filter((id) => platforms[id])
      .map((id) => ({
        id,
        source: path.relative(config.repoRoot, platforms[id].path),
      })),
  };

  const manifestPath = path.join(config.distRoot, "manifest.json");
  await fs.writeFile(manifestPath, JSON.stringify(manifest, null, 2));
}

export async function resetDist() {
  await fs.rm(config.distRoot, { recursive: true, force: true });
  await fs.mkdir(config.distRoot, { recursive: true });
}
