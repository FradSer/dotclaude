import YAML from "yaml";

export function formatCodexFrontmatter(command, pluginId) {
  const frontmatter = {
    description: command.summary?.trim() ?? "",
  };

  if (command.argument_hint) {
    frontmatter["argument-hint"] = command.argument_hint;
  }

  if (command.requirements?.tools?.length) {
    frontmatter["allowed-tools"] = command.requirements.tools.join(", ");
  }

  if (pluginId) {
    frontmatter.tags = [pluginId];
  }

  const yaml = YAML.stringify(frontmatter).trim();
  return `---\n${yaml}\n---`;
}

export function getCodexFileName(pluginId, slug) {
  if (!slug) {
    throw new Error("codex commands require a slug");
  }

  const base = pluginId ? `${pluginId}-${slug}` : slug;
  return `${base}.md`;
}
