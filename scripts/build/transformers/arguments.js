export function formatArgumentHint(argumentHint) {
  if (!argumentHint) {
    return "description";
  }

  const cleaned = argumentHint.replace(/[[\]]/g, "").trim();
  if (!cleaned) {
    return "description";
  }

  // Handle special cases for better readability
  if (cleaned === "feature-name") {
    return "feature-name";
  }

  if (cleaned.includes("|")) {
    return cleaned.includes("description of what") ? "the user input" : "option";
  }

  if (cleaned.includes("description")) {
    return "description";
  }

  // Note: Keep hyphenated words as-is (the replace operation preserves hyphens)
  return cleaned;
}

export function replaceArgumentsPlaceholders(text, argumentHint) {
  if (!text) {
    return text;
  }

  let result = text;

  // Handle special contextual replacements before generic $ARGUMENTS replacement
  if (argumentHint?.includes("feature-name")) {
    result = result.replace(/feature\s+`\$ARGUMENTS`/g, "current feature");
  }

  // Replace $ARGUMENTS with a more descriptive phrase based on argument_hint
  const description = formatArgumentHint(argumentHint);
  const placeholder = `<${description} (user may provide additional)>`;

  // Replace all occurrences of $ARGUMENTS with the placeholder
  // Handle paths like `hotfix/$ARGUMENTS` -> `hotfix/<description (user may provide additional)>`
  result = result.replace(
    /`([^/`]+)\/\$ARGUMENTS`/g,
    (_match, prefix) => `\`${prefix}/${placeholder}\``,
  );
  // Handle backtick-wrapped $ARGUMENTS -> wrapped placeholder
  result = result.replace(/`\$ARGUMENTS`/g, `\`${placeholder}\``);
  // Handle bare $ARGUMENTS -> placeholder
  result = result.replace(/\$ARGUMENTS/g, placeholder);

  return result;
}

export function appendUserInputHint(text, hasArguments, argumentHint) {
  if (!hasArguments) {
    return text;
  }

  const note = argumentHint
    ? `Use that input as <${formatArgumentHint(argumentHint)}> in the instructions above.`
    : "Use that input to interpret any placeholders in the instructions above.";

  return `${text}\n\n**Note:** The user may provide additional input after the command. ${note}`;
}

export function hasArgumentsPlaceholder(instructions) {
  return Boolean(instructions?.includes("$ARGUMENTS"));
}
