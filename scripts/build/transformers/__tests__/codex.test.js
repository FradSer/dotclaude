import assert from "node:assert/strict";
import test from "node:test";

import { formatCodexFrontmatter, getCodexFileName } from "../codex.js";

test("formatCodexFrontmatter builds required metadata", () => {
  const frontmatter = formatCodexFrontmatter(
    {
      summary: "Create atomic conventional git commit",
      argument_hint: "[scope] [ticket]",
      requirements: {
        tools: ["Task", "Bash(git:*)"],
      },
    },
    "git",
  );

  assert.match(frontmatter, /^---/);
  assert.match(frontmatter, /description: Create atomic conventional git commit/);
  assert.match(frontmatter, /argument-hint: "\[scope\] \[ticket\]"/);
  assert.match(frontmatter, /allowed-tools: Task, Bash\(git:\*\)/);
  assert.match(frontmatter, /tags:\n {2}- git/);
  assert.match(frontmatter, /---\s*$/);
});

test("formatCodexFrontmatter omits optional fields when absent", () => {
  const frontmatter = formatCodexFrontmatter({ summary: "Run checks" }, "utils");

  assert(!frontmatter.includes("argument-hint"));
  assert(frontmatter.includes("description: Run checks"));
  assert(frontmatter.includes("tags:\n  - utils"));
});

test("getCodexFileName flattens plugin and slug", () => {
  assert.equal(getCodexFileName("git", "commit"), "git-commit.md");
  assert.equal(getCodexFileName(undefined, "general"), "general.md");
});
