# Claude Code Plugin Best Practices: The Definitive Guide

This comprehensive guide synthesizes standards, patterns, and guidelines for developing high-quality Claude Code plugins. It consolidates wisdom from file patterns, subagent design, skill development, hook configuration, and MCP integrations.

## 1. Core Philosophy

*   **Minimal Configuration**: Rely on auto-discovery. Do not manually list commands, agents, or skills in `plugin.json` unless absolutely necessary (e.g., complex directory structures).
*   **Directory Structure**: Adhere strictly to the standard layout (`commands/`, `agents/`, `skills/`, `hooks/`) in the plugin root.
*   **Tool Usage Rules**:
    *   **Implicit (File Ops)**: Do NOT explicitly call `Read`, `Write`, `Glob`, `Grep`, or `Edit` tools. Describe the action directly (e.g., "Find files matching pattern...").
    *   **Explicit (Skills)**: ALWAYS explicitly call the `Skill` tool (e.g., "**Load the [skill-name] skill**...").
    *   **Bash**: Describe the command (e.g., "Run `git status`") rather than saying "Use Bash tool".

## 2. Directory & File Organization

### Standard Layout
```text
plugin-name/
├── .claude-plugin/
│   └── plugin.json          # Minimal manifest
├── commands/                # *.md files (plural directory)
├── agents/                  # *.md files (plural directory)
├── skills/                  # (plural directory)
│   └── skill-name/          # (kebab-case)
│       ├── SKILL.md         # REQUIRED entry point (fixed name)
│       ├── references/      # Detailed documentation
│       ├── examples/        # Runnable code examples
│       └── scripts/         # Executable helpers
├── hooks/
│   └── hooks.json           # Hook configuration
└── .mcp.json                # MCP server configuration
```

### Naming Conventions
*   **Files & Directories**: Always use `kebab-case` (e.g., `code-review/`, `git-status.md`).
*   **Fixed Names**: `SKILL.md` for skill entry points, `README.md` for documentation.
*   **Portable Paths**: Always use `${CLAUDE_PLUGIN_ROOT}` for file references. Never use hardcoded absolute paths.

## 3. Agent Design (Subagents)

Agents are autonomous subprocesses specialized for specific tasks.

### Critical Requirements
1.  **Triggering Examples**: The `description` field **MUST** include 2-4 `<example>` blocks. This is critical for the router to select your agent.
2.  **System Prompts**: Use **second-person** ("You are...", "Your responsibilities...").
3.  **Output Format**: Clearly define how the agent should structure its final response.

### Frontmatter Template
```yaml
---
name: agent-name
description: Use this agent when [condition]. Examples:
  <example>
  Context: User asks to refactor a component
  user: "Refactor the Button component to use hooks"
  assistant: "I'll use the refactoring agent to update the component."
  <commentary>Triggered because user requested structural code changes</commentary>
  </example>
  <example>
  Context: User reports a bug
  user: "Fix the crash in the login flow"
  assistant: "I'll use the debugging agent to investigate."
  <commentary>Triggered for bug fixing tasks</commentary>
  </example>
model: inherit  # or haiku (fast), sonnet (standard), opus (complex)
tools: ["Read", "Edit", "Bash(git:*)"]
permissionMode: default # or acceptEdits, dontAsk
color: blue
---
```

### Best Practices
*   **Scope**:
    *   `--agents` CLI flag (Session scope, highest priority)
    *   `.claude/agents/` (Project scope)
    *   `~/.claude/agents/` (User scope)
    *   Plugin `agents/` dir (Plugin scope)
*   **Permissions**: Use `permissionMode: acceptEdits` for trusted refactoring agents to reduce friction, but default to `default` for safety.

## 4. Skill Development

Skills provide domain knowledge and reusable tools to Claude.

### Key Principles
*   **Progressive Disclosure**: Keep `SKILL.md` lean (<2000 words). Move detailed details to `references/` and code to `examples/` or `scripts/`.
*   **Trigger Descriptions**: Use **third-person** with specific keywords (e.g., "This skill should be used when the user asks to...").
*   **Context Isolation**: Use `context: fork` in frontmatter if the skill performs complex analysis that shouldn't pollute the main context.

### Structure (`skills/my-skill/SKILL.md`)
```markdown
---
name: my-skill
description: This skill should be used when [specific trigger phrases].
user-invocable: true
---

# Overview
Brief purpose.

# Instructions
1. Step one...
2. Step two...

# References
(Explicitly link to files in references/ so Claude knows they exist)
```

## 5. Command Implementation

Commands are direct instructions **FOR** Claude to execute a specific task.

### Guidelines
*   **Directives**: Write prompts as instructions to the agent ("Review this code..."), not explanations to the user.
*   **Dynamic Context**: Use `!` backticks for inline bash execution to gather context *before* the prompt is processed.
    *   ✅ Correct: `Current status: !`git status``
    *   ❌ Incorrect: `Current status: !git status`
*   **Tool Restrictions**: Use `allowed-tools` to limit capabilities (e.g., `["Read", "Bash(git:*)"]`) for security and focus.

### Example
```markdown
---
description: Create a PR for current changes
allowed-tools: ["Bash(gh:*)", "Bash(git:*)", "Read"]
---
Context:
- Status: !`git status`
- Branch: !`git branch --show-current`

Your task: Create a pull request for the current changes.
1. Check for staged changes.
2. Use `gh pr create` to submit.
```

## 6. Hooks & Safety

Hooks provide deterministic control over Claude's lifecycle events.

### Events & Configuration
*   **Key Events**:
    *   `PreToolUse`: Validate or block tool usage.
    *   `PostToolUse`: Run cleanup, formatting, or logging.
    *   `UserPromptSubmit`: Intercept user input.
*   **Blocking**: Use `exit 2` in hook scripts to BLOCK an action. Use `exit 0` to allow.
*   **Performance**: Set timeouts. Use `type: "command"` (Bash) for fast, deterministic checks. Use `type: "prompt"` (LLM) for semantic analysis.

### Security
*   **Input Validation**: Always validate and sanitize JSON inputs in hook scripts.
*   **Credentials**: Hooks run with your environment credentials—review them carefully.

## 7. Integrations (MCP)

Connect external tools, databases, and APIs via Model Context Protocol.

### Configuration
*   **File**: `.mcp.json` or `mcpServers` object in `plugin.json`.
*   **Transport**:
    *   `http`: For remote/cloud services (Recommended).
    *   `stdio`: For local scripts and system tools.
*   **Scopes**:
    *   `local`: Private, current project.
    *   `project`: Shared via repo `.mcp.json`.
    *   `user`: Global across all projects.

### Example Config
```json
{
  "github": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-github"],
    "env": {
      "GITHUB_TOKEN": "${GITHUB_TOKEN}"
    }
  }
}
```

## Checklist for Verification
1.  [ ] Does `plugin.json` exist in `.claude-plugin/`?
2.  [ ] Do agent descriptions have `<example>` blocks?
3.  [ ] Is `SKILL.md` named correctly and placed in a subdirectory?
4.  [ ] Do commands use `!` backticks for dynamic bash?
5.  [ ] Are file references using `${CLAUDE_PLUGIN_ROOT}`?
