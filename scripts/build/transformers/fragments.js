export function expandSharedFragments(content, fragments = {}) {
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

function buildFragmentMarkers(fragments) {
  return fragments.map((fragment) => `{{ fragment:${fragment} }}`).join("\n");
}

function buildBodyFromObject(value) {
  if (Array.isArray(value.fragments) && value.fragments.length > 0) {
    const markers = buildFragmentMarkers(value.fragments);
    return value.body ? `${markers}\n${value.body}` : markers;
  }

  if (Array.isArray(value.lines) && value.lines.length > 0) {
    const lines = value.lines.join("\n");
    return value.body ? `${value.body}\n${lines}` : lines;
  }

  return value.body ?? value.content ?? "";
}

function normalizeInstructionSection(value, defaultHeading, sharedFragments) {
  if (value === undefined || value === null) {
    return null;
  }

  let heading = defaultHeading;
  let body = "";

  if (typeof value === "string") {
    body = value;
  } else if (typeof value === "object") {
    heading = value.heading ?? defaultHeading;
    body = buildBodyFromObject(value);
  } else {
    return null;
  }

  const expanded = expandSharedFragments(body, sharedFragments).trim();
  if (!expanded) {
    return null;
  }

  return { heading, body: expanded };
}

function toTitleCaseFromKey(key) {
  return key.replace(/[_-]+/g, " ").replace(/\b\w/g, (char) => char.toUpperCase());
}

export function composeInstructionMarkdown(instructions, sharedFragments, existingRequireTask) {
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
