import { composeInstructionMarkdown, expandSharedFragments } from "./transformers/index.js";

export function resolveRequireTaskTool(data) {
  if (typeof data.require_task_tool === "boolean") {
    return data.require_task_tool;
  }
  return data.platform_overrides?.claude?.require_task_tool ?? undefined;
}

export function processInstructions(data, sharedFragments, requireTaskTool) {
  const instructions = data.instructions;
  if (!instructions) {
    return requireTaskTool;
  }

  if (typeof instructions === "object" && !Array.isArray(instructions)) {
    const { markdown, requireTaskTool: extracted } = composeInstructionMarkdown(
      instructions,
      sharedFragments,
      requireTaskTool,
    );
    data.instructions = markdown;
    return typeof extracted === "boolean" ? extracted : requireTaskTool;
  }

  if (typeof instructions === "string") {
    data.instructions = expandSharedFragments(instructions, sharedFragments);
  }

  return requireTaskTool;
}

export function processDescription(data, sharedFragments) {
  if (typeof data.description === "string") {
    data.description = expandSharedFragments(data.description, sharedFragments);
  }
}

export function processSections(data, sharedFragments) {
  if (!Array.isArray(data.sections)) {
    return;
  }

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

export function applyRequireTaskTool(data, requireTaskTool) {
  if (typeof requireTaskTool === "boolean") {
    data.require_task_tool = requireTaskTool;
  } else {
    delete data.require_task_tool;
  }
}
