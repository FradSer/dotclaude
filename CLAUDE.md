# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a **Claude Code plugin marketplace** (`frad-dotclaude`) containing 10 plugins across development and productivity categories. Each plugin follows auto-discovery conventions—place components in `commands/`, `agents/`, `skills/` directories and Claude discovers them automatically.

**Active plugins:** git, gitflow, github, review, refactor, swiftui, claude-config, office, utils, plugin-optimizer

## Plugin Structure

```
plugin-name/
├── .claude-plugin/plugin.json  # Manifest with commands/agents/skills/hooks
├── agents/*.md                 # Agent definitions
├── skills/skill-name/          # Skill directories
│   ├── SKILL.md               # Main skill file (required)
│   └── references/            # Detailed reference materials
├── scripts/                    # Utility scripts (bash/python)
└── examples/                   # Example configurations
```

**Skill registration determines visibility.** A skill registered under `"commands"` in plugin.json becomes a user-invocable slash command (e.g., `/git:commit`). A skill registered under `"skills"` is internal-only, loaded automatically when Claude needs domain knowledge but never shown in `/help`. Example from `refactor/`:
- `"commands": ["./skills/refactor/"]` -- user runs `/refactor:refactor`
- `"skills": ["./skills/best-practices/"]` -- loaded automatically during refactoring

**Hooks** can be inline in `plugin.json`. See `git/.claude-plugin/plugin.json` for the `PreToolUse` hook pattern (runs a shell script to validate Bash tool calls before execution).

## Development Workflow

**Validation:** Run `/plugin-optimizer:optimize-plugin` before committing. Alternatively:

```bash
# All checks (structure, manifest, frontmatter, tools, tokens)
python3 plugin-optimizer/scripts/validate-plugin.py <plugin-path>

# Specific checks only
python3 plugin-optimizer/scripts/validate-plugin.py <plugin-path> --check=manifest,frontmatter

# JSON output for scripting
python3 plugin-optimizer/scripts/validate-plugin.py <plugin-path> --json

# Verbose (shows passing checks too)
python3 plugin-optimizer/scripts/validate-plugin.py <plugin-path> -v
```

Exit codes: 0 = passed, 1 = MUST violations, 2 = token budget critical.

**Branch Strategy:** develop -> main (merge commits)

**Version sync:** Plugin versions in individual `plugin.json` files are authoritative. Keep `.claude-plugin/marketplace.json` entries in sync when bumping versions.

**Creating a New Plugin:**
1. `mkdir -p plugin-name/{.claude-plugin,skills,agents}`
2. Add `plugin.json` with name, description, author, version, keywords
3. Add entry to `.claude-plugin/marketplace.json` with matching version
4. Validate with plugin-optimizer before committing

## Git Commit Conventions

**Scopes:** git, gitflow, github, refactor, review, office, swiftui, po, cc, utils, docs, ci

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

## Reference Materials

Best practices and file pattern examples live inside `plugin-optimizer/skills/plugin-best-practices/` and `plugin-optimizer/examples/`. The `.research/` directory (gitignored) contains upstream Anthropic plugin references for comparison.
