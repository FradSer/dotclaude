# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a **Claude Code plugin marketplace** (`frad-dotclaude`) containing 21 plugins across development and productivity categories. Each plugin follows auto-discovery conventions—place components in `commands/`, `agents/`, `skills/` directories and Claude discovers them automatically.

**Active plugins:** git, github, refactor, swiftui, office, lark, hyperframes, plugin-optimizer, mattpocock, superpowers, antigravity, pi, interfaces, storm, hardware, autoresearch, memory

**Non-active plugins:** acpx, code-context, utils, meeseeks-vetted

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

**Version sync:** Plugin versions in individual `plugin.json` files are authoritative. Keep `.claude-plugin/marketplace.json` entries in sync when bumping versions. `README.md` / `README.zh-CN.md` are a third sync target — their plugin listings drift silently (currently still mention removed `next-devtools`/`shadcn`), so run `/utils:update-readme` whenever you add, remove, or rename a plugin.

**`strict` field in marketplace.json:** Default is `true`. Set `"strict": false` on a plugin entry (see `office`) to relax marketplace validation for plugins that intentionally bundle non-standard content.

**Creating a New Plugin:**
1. `mkdir -p plugin-name/{.claude-plugin,skills,agents}`
2. Add `plugin.json` with name, description, author, version, keywords, license
3. Add entry to `.claude-plugin/marketplace.json` with matching version
4. Run `/utils:update-readme` to sync `README.md` and `README.zh-CN.md`
5. Validate with plugin-optimizer before committing

## Git Commit Conventions

**Scopes:** acpx, ag, as, cctx, fe, git, github, hw, hyperframes, lark, marketing, mem, office, pi, po, refactor, sd, sp, storm, swiftui, utils

**Types:** feat, fix, docs, refactor, test, chore, perf

**Format:** `type(scope): lowercase message under 50 chars`

**Commit tool:** git-agent CLI generates conventional commit messages via AI. When git-agent is unavailable, fall back to manual `git commit` with conventional format.

## Plugin Development Patterns

Reference materials for plugin development patterns live in `plugin-optimizer/skills/plugin-best-practices/` and `plugin-optimizer/examples/`. The `.research/` directory (gitignored) contains upstream Anthropic plugin references for comparison.

### Key rules
- **Commands** write directives TO Claude, not descriptions FOR users. Use `$ARGUMENTS`, `${CLAUDE_PLUGIN_ROOT}` for dynamic context. Never use bare `Bash` in `allowed-tools`.
- **Agents** must include 2-4 `<example>` blocks. Structure: Role → Responsibilities → Process → Standards → Output Format.
- **Skills** under 2000 words; move details to `references/`. Imperative body style ("Parse the file...", not "You should...").
- **Tool invocation** in plugin content: file ops → describe directly; Bash → run the command; Skill → "Load X skill using the Skill tool"; Task → "Launch explore agent".
