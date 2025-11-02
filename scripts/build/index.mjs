import { promises as fs } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import YAML from "yaml";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, "..", "..");
const configRoot = path.join(repoRoot, "config");
const distRoot = path.join(repoRoot, "dist");
const sharedRoot = path.join(repoRoot, "prompts", "_shared");
const CLAUDE_MARKETPLACE_PATH = path.join(repoRoot, ".claude-plugin", "marketplace.json");

const PLATFORM_ORDER = ["claude", "cursor", "codex", "gemini"];

async function main() {
  const sharedFragments = await loadSharedFragments();
  const promptFiles = await readPromptFiles(sharedFragments);
  const platforms = await readPlatformMetadata();

  await resetDist();

  for (const promptFile of promptFiles) {
    await generateForPlugin(promptFile, platforms);
  }

  await writeManifest(promptFiles, platforms);
  await writeClaudeMarketplace(promptFiles);
}

async function readPromptFiles(sharedFragments) {
  const promptDir = path.join(repoRoot, "prompts");
  const entries = await safeReadDir(promptDir);
  const plugins = [];

  for (const entry of entries) {
    if (!entry.isDirectory()) continue;
    if (entry.name.startsWith("_")) continue;
    const pluginPath = path.join(promptDir, entry.name);
    const pluginMetaPath = path.join(pluginPath, "plugin.yaml");
    try {
      await fs.access(pluginMetaPath);
    } catch (error) {
      if (error.code === "ENOENT") {
        console.warn(`Skipping ${entry.name} because plugin.yaml is missing.`);
        continue;
      }
      throw error;
    }
    const pluginMetaRaw = await fs.readFile(pluginMetaPath, "utf8");
    const pluginMeta = YAML.parse(pluginMetaRaw);
    if (!pluginMeta?.plugin?.id) {
      throw new Error(`Plugin metadata missing plugin.id at ${pluginMetaPath}`);
    }

    const commands = await readYamlCollection(path.join(pluginPath, "commands"), sharedFragments);
    const agents = await readYamlCollection(path.join(pluginPath, "agents"), sharedFragments);

    plugins.push({
      path: pluginMetaPath,
      dirname: entry.name,
      data: {
        version: pluginMeta.version ?? 1,
        plugin: pluginMeta.plugin,
        commands,
        agents,
      },
    });
  }

  return plugins;
}

async function safeReadDir(directory) {
  try {
    return await fs.readdir(directory, { withFileTypes: true });
  } catch (error) {
    if (error.code === "ENOENT") {
      return [];
    }
    throw error;
  }
}

async function readYamlCollection(directory, sharedFragments) {
  const dirents = await safeReadDir(directory);
  const items = [];

  for (const dirent of dirents) {
    if (!dirent.isFile() || !dirent.name.endsWith(".yaml")) continue;
    const filePath = path.join(directory, dirent.name);
    const raw = await fs.readFile(filePath, "utf8");
    const data = YAML.parse(raw) ?? {};
    let requireTaskTool = data.require_task_tool;
    if (requireTaskTool === undefined) {
      requireTaskTool = data.platform_overrides?.claude?.require_task_tool;
    }
    if (
      data.instructions &&
      typeof data.instructions === "object" &&
      !Array.isArray(data.instructions)
    ) {
      const { markdown, requireTaskTool: extracted } = composeInstructionMarkdown(
        data.instructions,
        sharedFragments,
        requireTaskTool,
      );
      data.instructions = markdown;
      if (typeof extracted === "boolean") {
        requireTaskTool = extracted;
      }
    } else if (typeof data.instructions === "string") {
      data.instructions = expandSharedFragments(data.instructions, sharedFragments);
    }
    if (typeof data.description === "string") {
      data.description = expandSharedFragments(data.description, sharedFragments);
    }
    if (Array.isArray(data.sections)) {
      data.sections = data.sections.map((section) => {
        if (typeof section === "string") {
          return expandSharedFragments(section, sharedFragments);
        }
        if (section && typeof section.content === "string") {
          return {
            ...section,
            content: expandSharedFragments(section.content, sharedFragments),
          };
        }
        return section;
      });
    }
    if (typeof requireTaskTool === "boolean") {
      data.require_task_tool = requireTaskTool;
    } else {
      delete data.require_task_tool;
    }
    if (!data.slug && !data.title && !data.plugin) {
      console.warn(`Skipping empty or invalid YAML file: ${filePath}`);
      continue;
    }
    items.push({ ...data, __file: filePath });
  }

  items.sort((a, b) => {
    const slugA = a.slug ?? "";
    const slugB = b.slug ?? "";
    return slugA.localeCompare(slugB);
  });

  return items.map(({ __file, ...rest }) => rest);
}

async function readPlatformMetadata() {
  const platformDir = path.join(configRoot, "platforms");
  const entries = await fs.readdir(platformDir);
  const yamlFiles = entries.filter((file) => file.endsWith(".yaml"));
  const platforms = {};

  for (const file of yamlFiles) {
    const filePath = path.join(platformDir, file);
    const raw = await fs.readFile(filePath, "utf8");
    const data = YAML.parse(raw);
    if (!data?.id) {
      throw new Error(`Platform file ${file} missing id`);
    }
    platforms[data.id] = { ...data, path: filePath };
  }

  return platforms;
}

async function resetDist() {
  await fs.rm(distRoot, { recursive: true, force: true });
  await fs.mkdir(distRoot, { recursive: true });
}

async function generateForPlugin(promptFile, platforms) {
  const { data } = promptFile;
  const pluginId = data.plugin.id;

  if (!data.commands || !Array.isArray(data.commands)) {
    console.warn(`No commands defined for plugin ${pluginId}. Skipping.`);
  }

  for (const platformId of PLATFORM_ORDER) {
    const platform = platforms[platformId];
    if (!platform) {
      console.warn(`Platform ${platformId} metadata missing. Skipping.`);
      continue;
    }

    switch (platformId) {
      case "claude":
        await generateClaude(pluginId, data, platform);
        break;
      case "cursor":
        await generateCursor(pluginId, data, platform);
        break;
      case "codex":
        await generateCodex(pluginId, data, platform);
        break;
      case "gemini":
        await generateGemini(pluginId, data, platform);
        break;
      default:
        console.warn(`Unhandled platform ${platformId}`);
    }
  }
}

function _ensureArray(value) {
  if (!value) return [];
  return Array.isArray(value) ? value : [value];
}

async function generateClaude(pluginId, data, _platform) {
  const baseDir = path.join(distRoot, "claude", "plugins", pluginId);
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

async function generateCursor(pluginId, data, _platform) {
  const baseDir = path.join(distRoot, "cursor");
  const commandsDir = path.join(baseDir, "commands", pluginId);
  await fs.mkdir(commandsDir, { recursive: true });

  if (Array.isArray(data.commands)) {
    for (const command of data.commands) {
      const cursorOverrides = command.platform_overrides?.cursor ?? {};
      if (!cursorOverrides.command?.palette) continue;
      const commandFrontMatter = {
        description: command.summary,
        trigger: cursorOverrides.command.palette,
      };
      if (command.argument_hint) {
        commandFrontMatter.argumentHint = command.argument_hint;
      }
      const commandBody = removeTaskToolWarning(normaliseForCursor(command.instructions ?? ""));
      const commandPath = path.join(commandsDir, `${command.slug}.md`);
      await writeMarkdownWithFrontMatter(commandPath, commandFrontMatter, commandBody);
    }
  }
}

async function generateCodex(pluginId, data, _platform) {
  const baseDir = path.join(distRoot, "codex", "prompts", pluginId);
  await fs.mkdir(baseDir, { recursive: true });

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
      lines.push(removeTaskToolWarning(normaliseForCursor(command.instructions ?? "")).trim());
      lines.push("");
      const filePath = path.join(baseDir, `${command.slug}.md`);
      await fs.writeFile(filePath, `${lines.join("\n")}`);
    }
  }
}

async function generateGemini(pluginId, data, _platform) {
  const baseDir = path.join(distRoot, "gemini");
  const commandsRoot = path.join(baseDir, "commands");
  await fs.mkdir(commandsRoot, { recursive: true });

  if (Array.isArray(data.commands)) {
    for (const command of data.commands) {
      const overrides = command.platform_overrides?.gemini ?? {};
      const namespace = overrides.namespace ?? pluginId;
      const filename = overrides.filename ?? command.slug;
      const commandDir = path.join(commandsRoot, namespace);
      await fs.mkdir(commandDir, { recursive: true });
      const prompt = removeTaskToolWarning(normaliseForCursor(command.instructions ?? "")).trim();
      const toml = buildGeminiToml(command.summary, prompt);
      const filePath = path.join(commandDir, `${filename}.toml`);
      await fs.writeFile(filePath, toml);
    }
  }
}

function normaliseForCursor(markdown) {
  return markdown.replaceAll("!`", "`");
}

function removeTaskToolWarning(markdown) {
  if (!markdown) return markdown;
  const pattern = /\n?\*\*IMPORTANT: You MUST use the Task tool to complete ALL tasks\.\*\*\n?/g;
  const cleaned = markdown.replace(pattern, "\n");
  return cleaned.replace(/\n{3,}/g, "\n\n");
}

function injectTaskToolWarning(markdown) {
  const warning = "**IMPORTANT: You MUST use the Task tool to complete ALL tasks.**\n\n";
  const headingRegex = /(## Your Task\s*\n+)/i;
  if (headingRegex.test(markdown)) {
    return markdown.replace(headingRegex, (match) => `${match}${warning}`);
  }
  return `${warning}${markdown}`;
}

function buildGeminiToml(description, prompt) {
  return `description="${escapeTomlString(description)}"\nprompt = """\n${prompt}\n"""\n`;
}

function escapeTomlString(value) {
  return value.replaceAll('"', '\\"');
}

function formatTools(tools) {
  if (!tools || (Array.isArray(tools) && tools.length === 0)) return undefined;
  if (Array.isArray(tools)) {
    if (tools.length === 1) return tools[0];
    return tools.join(", ");
  }
  return tools;
}

async function writeClaudeMarkdown(filePath, frontMatter, body) {
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

async function writeMarkdownWithFrontMatter(filePath, frontMatter, body) {
  const fm =
    frontMatter && Object.keys(frontMatter).length > 0
      ? `---\n${YAML.stringify(frontMatter)}---\n\n`
      : "";
  const content = `${fm}${body.trim()}\n`;
  await fs.writeFile(filePath, content);
}

async function writeClaudeMarketplace(promptFiles) {
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

  await fs.mkdir(path.dirname(CLAUDE_MARKETPLACE_PATH), { recursive: true });
  await fs.writeFile(CLAUDE_MARKETPLACE_PATH, `${JSON.stringify(marketplace, null, 2)}\n`);
}

async function loadSharedFragments() {
  const fragments = {};

  async function walk(directory, prefix = "") {
    const entries = await safeReadDir(directory);
    for (const entry of entries) {
      const entryPath = path.join(directory, entry.name);
      if (entry.isDirectory()) {
        const nextPrefix = prefix ? `${prefix}/${entry.name}` : entry.name;
        await walk(entryPath, nextPrefix);
      } else if (entry.isFile() && entry.name.endsWith(".md")) {
        const keyBase = entry.name.replace(/\.md$/, "");
        const key = prefix ? `${prefix}/${keyBase}` : keyBase;
        const content = await fs.readFile(entryPath, "utf8");
        fragments[key] = content.trim();
      }
    }
  }

  const rootEntries = await safeReadDir(sharedRoot);
  if (rootEntries.length === 0) {
    return fragments;
  }

  await walk(sharedRoot);
  return fragments;
}

function expandSharedFragments(content, fragments = {}) {
  if (!content) return content;
  const pattern = /{{\s*fragment:([\w\-/]+)\s*}}/g;
  return content.replace(pattern, (_match, key) => {
    const fragment = fragments[key];
    if (!fragment) {
      console.warn(`Shared fragment not found: ${key}`);
      return "";
    }
    return `${fragment}\n`;
  });
}

function composeInstructionMarkdown(instructions, sharedFragments, existingRequireTask) {
  const sections = [];
  let requireTaskTool = existingRequireTask;
  const orderedSections = [
    ["context", "## Context"],
    ["requirements", "## Requirements"],
    ["your_task", "## Your Task"],
  ];

  for (const [key, defaultHeading] of orderedSections) {
    if (!(key in instructions)) continue;
    const section = normalizeInstructionSection(instructions[key], defaultHeading, sharedFragments);
    if (section) {
      sections.push(`${section.heading}\n\n${section.body}`);
    }
    if (
      key === "your_task" &&
      instructions[key] &&
      typeof instructions[key] === "object" &&
      Object.hasOwn(instructions[key], "require_task_tool")
    ) {
      requireTaskTool = instructions[key].require_task_tool;
    }
  }

  const extraKeys = Object.keys(instructions).filter(
    (key) => !orderedSections.some(([expected]) => expected === key),
  );

  for (const key of extraKeys) {
    const heading = `## ${toTitleCaseFromKey(key)}`;
    const section = normalizeInstructionSection(instructions[key], heading, sharedFragments);
    if (section) {
      sections.push(`${section.heading}\n\n${section.body}`);
    }
  }

  const markdown = sections.length > 0 ? `${sections.join("\n\n")}\n` : "";
  return { markdown, requireTaskTool };
}

function normalizeInstructionSection(value, defaultHeading, sharedFragments) {
  if (value === undefined || value === null) return null;
  let heading = defaultHeading;
  let body = "";

  if (typeof value === "string") {
    body = value;
  } else if (typeof value === "object") {
    heading = value.heading ?? defaultHeading;
    if (Array.isArray(value.fragments) && value.fragments.length > 0) {
      const markers = value.fragments.map((fragment) => `{{ fragment:${fragment} }}`).join("\n");
      body = value.body ? `${markers}\n${value.body}` : markers;
    } else if (Array.isArray(value.lines) && value.lines.length > 0) {
      const lines = value.lines.join("\n");
      body = value.body ? `${value.body}\n${lines}` : lines;
    } else {
      body = value.body ?? value.content ?? "";
    }
  } else {
    return null;
  }

  const expanded = expandSharedFragments(body, sharedFragments).trim();
  if (!expanded) return null;
  return { heading, body: expanded };
}

function toTitleCaseFromKey(key) {
  return key.replace(/[_-]+/g, " ").replace(/\b\w/g, (char) => char.toUpperCase());
}

async function writeManifest(promptFiles, platforms) {
  const manifest = {
    generatedAt: new Date().toISOString(),
    plugins: promptFiles.map((file) => ({
      id: file.data.plugin.id,
      source: path.relative(repoRoot, file.path),
      commands: (file.data.commands ?? []).map((command) => command.slug),
      agents: (file.data.agents ?? []).map((agent) => agent.slug),
    })),
    platforms: PLATFORM_ORDER.filter((id) => platforms[id]).map((id) => ({
      id,
      source: path.relative(repoRoot, platforms[id].path),
    })),
  };

  const manifestPath = path.join(distRoot, "manifest.json");
  await fs.writeFile(manifestPath, JSON.stringify(manifest, null, 2));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
