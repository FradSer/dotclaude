export function normaliseForCursor(markdown) {
  return markdown.replaceAll("!`", "`");
}

export function removeTaskToolWarning(markdown) {
  if (!markdown) return markdown;
  const pattern = /\n?\*\*IMPORTANT: You MUST use the Task tool to complete ALL tasks\.\*\*\n?/g;
  const cleaned = markdown.replace(pattern, "\n");
  return cleaned.replace(/\n{3,}/g, "\n\n");
}

export function injectTaskToolWarning(markdown) {
  const warning = "**IMPORTANT: You MUST use the Task tool to complete ALL tasks.**\n\n";
  const headingRegex = /(## Your Task\s*\n+)/i;
  if (headingRegex.test(markdown)) {
    return markdown.replace(headingRegex, (match) => `${match}${warning}`);
  }
  return `${warning}${markdown}`;
}
