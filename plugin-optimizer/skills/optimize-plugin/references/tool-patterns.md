# Tool Invocation Patterns

Reference guide for correct tool usage in plugin content.

## Pattern Table

| Tool | Style | Correct Format |
|------|-------|----------------|
| Read, Write, Glob, Grep, Edit | Implicit | "Find files matching...", "Read each file..." |
| Bash | Implicit | "Run `git status`" |
| Task | Implicit | "Launch `plugin-name:agent-name` agent" |
| Skill | **Explicit** | "**Load `plugin-name:skill-name` skill** using the Skill tool" |
| AskUserQuestion | **Explicit** | "Use `AskUserQuestion` tool to [action]" |
| TaskCreate | **Explicit** | "**Use TaskCreate tool** to track" |

## Qualified Names

Plugin components MUST use `plugin-name:component-name` format.

## Progressive Disclosure

Skills package domain expertise—turning general agents into knowledgeable specialists. Progressive disclosure protects context: metadata (~50 tokens) → SKILL.md (~500 tokens) → references (2000+ tokens, MUST only access when specifically needed).
