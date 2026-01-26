# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a **Claude Code plugin marketplace** repository containing a curated collection of plugins. Each plugin follows auto-discovery conventions—place components in `commands/`, `agents/`, `skills/`, `hooks/` directories and Claude discovers them automatically.

## Plugin Structure

```
plugin-name/
├── .claude-plugin/plugin.json  # Minimal manifest (name, description, author)
├── commands/*.md               # Slash commands
├── agents/*.md                 # Agent definitions
├── skills/skill-name/          # Skill directories
│   ├── SKILL.md               # Main skill file (required)
│   └── references/            # Detailed reference materials
└── hooks/hooks.json           # Hook configurations
```

## Git Commit Conventions

**Scopes:** git, gitflow, refactor, office, po, cc, utils, docs, ci

**Types:** feat, fix, docs, refactor, test, chore, perf

**Format:** `type(scope): lowercase message under 50 chars`

## Plugin Development Patterns

### Commands (instructions FOR Claude)

```yaml
---
description: "Short description for /help"
argument-hint: "<required> [optional]"
allowed-tools: ["Read", "Bash(git:*)"]  # NEVER bare Bash
---
```

- Write directives TO Claude, not descriptions FOR users
- Dynamic context: `` !`git status` `` (backticks required)
- Variables: `$ARGUMENTS`, `${CLAUDE_PLUGIN_ROOT}`

### Agents (autonomous subprocesses)

```yaml
---
name: agent-name
description: Use this agent when... <example>blocks required</example>
model: inherit  # or sonnet/opus/haiku
color: blue     # blue/cyan/green/yellow/magenta/red
tools: ["Read", "Grep", "Glob"]
---
You are an expert... (second person system prompt)
```

- **Must include 2-4 `<example>` blocks** with Context, user, assistant, commentary
- Structure: Role → Responsibilities → Process → Standards → Output Format

### Skills (domain knowledge)

```yaml
---
name: skill-name
description: This skill should be used when... (third person, trigger phrases)
user-invocable: true  # false for internal-only skills
---
```

- Imperative body style ("Parse the file...", not "You should...")
- Keep under 2000 words; move details to `references/`
- Reference files explicitly: "See `references/advanced.md` for details"

## Tool Invocation Rules (Critical)

| Tool Category | In Plugin Content |
|--------------|-------------------|
| File ops (Read, Write, Edit, Glob, Grep) | Describe actions directly, never "Use X tool" |
| Bash | Describe commands directly: "Run `git diff`" |
| Skill | **Always explicit**: "Load X skill using the Skill tool" |
| Task | Describe agent launch: "Launch code-reviewer agent" |

## Development References

- Best practices: `docs-claude/PLUGIN_BEST_PRACTICES.md`
- File patterns: `docs-claude/FILE_PATTERNS.md`
- Hooks guide: `docs-claude/hooks-guide.md`
