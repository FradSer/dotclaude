# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a **Claude Code plugin marketplace** (`frad-dotclaude`) containing 23 plugins across development and productivity categories (the authoritative inventory is `.claude-plugin/marketplace.json`). Each plugin follows auto-discovery conventions—place components in `commands/`, `agents/`, `skills/` directories and Claude discovers them automatically.

**Development plugins (13):** git, git-agent, swiftui, refactor, plugin-optimizer, acpx, code-context, autoresearch, antigravity, hardware, memory, pi, interfaces

**Productivity plugins (10):** github, office, generate-image, lark, marketing, hyperframes, mattpocock, superpowers, utils, storm

**Upstream mirrors (`strict: false` in marketplace.json):** office, lark, marketing, hyperframes. Their skill content is synced from upstream and gets overwritten on resync—do not hand-edit mirror SKILL.md / entry files; fix upstream or the local sync tooling instead. mattpocock, superpowers, interfaces, and acpx also ship sync tooling, so treat their content as upstream-controlled too.

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

**Skills in `skills/` are auto-discovered; never list them under `"commands"`.** Claude Code scans `skills/<name>/SKILL.md` on its own. Listing that same directory in `"commands"` registers the SKILL.md twice, doubling the component inventory and the always-on token cost. `"skills"` adds extra directories; `"commands"` is for flat `.md` command files in `commands/`.

**Visibility comes from SKILL.md frontmatter**, not the manifest key: `user-invocable: true` exposes `/plugin:skill` in `/help`, `false` keeps it internal. Both work with no `"commands"` key. Example from `refactor/`:
- `skills/refactor/SKILL.md` with `user-invocable: true` -- user runs `/refactor:refactor`
- `skills/best-practices/SKILL.md` with `user-invocable: false` -- loaded as domain knowledge only

**Hooks** can be inline in `plugin.json`. See `git-agent/.claude-plugin/plugin.json` for the `PreToolUse` hook pattern (its `hooks/validate-commit-pretool.sh` intercepts Bash `git add`/`git commit`).

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

Exit codes: 0 = passed, 1 = a MUST violation in any check (validation blocked), 2 = token budget critical (MUST refactor).

**Branch Strategy:** develop -> main (merge commits)

**Version sync:** Plugin versions in individual `plugin.json` files are authoritative. Keep `.claude-plugin/marketplace.json` entries in sync when bumping versions. `README.md` / `README.zh-CN.md` are a third sync target — their plugin listings drift silently, so run `/utils:update-readme` whenever you add, remove, or rename a plugin. Verify the intro plugin count and the badge stay at the real total.

**`strict` field in marketplace.json:** Default is `true`. Set `"strict": false` on a plugin entry (see `office`) to relax marketplace validation for plugins that intentionally bundle non-standard content.

**Creating a New Plugin:**
1. `mkdir -p plugin-name/{.claude-plugin,skills,agents}`
2. Add `plugin.json` with name, description, author, version, keywords, license
3. Add entry to `.claude-plugin/marketplace.json` with matching version
4. Run `/utils:update-readme` to sync `README.md` and `README.zh-CN.md`
5. Validate with plugin-optimizer before committing

## Git Commit Conventions

**Scopes:** the authoritative list lives in `.git-agent/config.yml` (run `git-agent init --scope` to regenerate). That file currently defines acpx, ag, as, cctx, git, gh, hw, hf, lark, mkt, mem, po, ref, sd; the shorter aliases there supersede the older full-name scope list.

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
