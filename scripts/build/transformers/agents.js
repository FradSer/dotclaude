import { normaliseForCursor, removeTaskToolWarning } from "./markdown.js";

export function appendAgentsDescriptionIfNeeded(instructions, agentsDescription) {
  if (!agentsDescription || !instructions.includes("@")) {
    return instructions;
  }
  return `${instructions}\n${agentsDescription}`;
}

export function formatAgentsDescription(agents) {
  if (!Array.isArray(agents) || agents.length === 0) {
    return "";
  }

  const lines = [];
  lines.push("\n## Available Specialized Agents\n");
  lines.push(
    "The following specialized agents are available (note: agents are only supported in Claude; use their expertise as guidance for your review):\n",
  );

  for (const agent of agents) {
    lines.push(`### @${agent.slug}`);
    if (agent.summary) {
      lines.push(`\n${agent.summary}\n`);
    }

    // Include the full instructions, but process it to remove platform-specific references
    if (agent.instructions) {
      let instructions = agent.instructions.trim();

      // Normalize for non-Claude platforms (remove Task tool references, etc.)
      instructions = removeTaskToolWarning(normaliseForCursor(instructions));

      lines.push(instructions);
      lines.push("");
    }
  }

  return lines.join("\n");
}
