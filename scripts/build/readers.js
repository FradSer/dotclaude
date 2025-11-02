import { promises as fs } from "node:fs";
import path from "node:path";
import YAML from "yaml";
import { config, safeReadDir } from "./config.js";

export async function readPromptFiles(sharedFragments) {
  const promptDir = path.join(config.repoRoot, "prompts");
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

export async function readYamlCollection(directory, sharedFragments) {
  const {
    resolveRequireTaskTool,
    processInstructions,
    processDescription,
    processSections,
    applyRequireTaskTool,
  } = await import("./processors.js");
  const dirents = await safeReadDir(directory);
  const items = [];

  for (const dirent of dirents) {
    if (!dirent.isFile() || !dirent.name.endsWith(".yaml")) {
      continue;
    }

    const filePath = path.join(directory, dirent.name);
    let data;
    try {
      const raw = await fs.readFile(filePath, "utf8");
      data = YAML.parse(raw) ?? {};
    } catch (error) {
      console.error(`Failed to parse YAML file ${filePath}: ${error.message}`);
      continue;
    }

    let requireTaskTool = resolveRequireTaskTool(data);
    requireTaskTool = processInstructions(data, sharedFragments, requireTaskTool);
    processDescription(data, sharedFragments);
    processSections(data, sharedFragments);
    applyRequireTaskTool(data, requireTaskTool);

    if (!isValidYamlItem(data)) {
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

function isValidYamlItem(data) {
  return !!(data.slug || data.title || data.plugin);
}

export async function readPlatformMetadata() {
  const platformDir = path.join(config.configRoot, "platforms");
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

export async function loadSharedFragments() {
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

  const rootEntries = await safeReadDir(config.sharedRoot);
  if (rootEntries.length === 0) {
    return fragments;
  }

  await walk(config.sharedRoot);
  return fragments;
}
