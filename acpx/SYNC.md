# Syncing acpx with upstream

This plugin is a **knowledge mirror** of the upstream CLI [`openclaw/acpx`](https://github.com/openclaw/acpx). The SKILL.md is a condensed, token-budgeted distillation of the upstream docs — NOT a verbatim copy. Run this checklist whenever you sync to a new upstream release.

## When to sync

- Before a release, or when asked to "update acpx to the latest version".
- Upstream tags move fast (v0.x). Check the gap: `gh api repos/openclaw/acpx/tags --jq '.[].name'` vs the version noted at the top of this file / in CHANGELOG references.

## What upstream to read (in priority order)

1. `CHANGELOG.md` — the source of truth for what changed per version. Read every release between the last-synced version and HEAD.
2. `docs/CLI.md` — definitive command grammar, global options, exit codes, env vars. The authoritative reference for SKILL.md's command/options sections.
3. `README.md` — built-in agent registry table (adapter command mappings).
4. `docs/agents.md` + `agents/README.md` — per-agent docs, aliases, special env.
5. `docs/quickstart.md`, `docs/output-formats.md`, `docs/permissions.md`, `docs/config.md` — only when a change in those areas shows up in CHANGELOG.

Do NOT clone the whole repo to read every file. Shallow clone is enough:

```bash
cd /tmp && rm -rf acpx-upstream
gh repo clone openclaw/acpx acpx-upstream -- --depth 1 -q
```

## Sync method: incremental diff, NOT wholesale replace

This is the key principle. The SKILL.md body is hand-distilled to ~380 lines / under the L2 token budget. Wholesale-replacing it from `docs/CLI.md` would blow the budget and lose the condensation work.

**Do this instead:**

1. Read the new SKILL.md (in this repo) and the upstream `CHANGELOG.md` + `docs/CLI.md`.
2. For each release between last-sync and HEAD, identify the surface area that touches the CLI user model: new commands, new global options, new agents, changed flags, changed exit codes, changed env vars.
3. Apply **only the deltas** to the relevant SKILL.md section:
   - New command → add to `## Command model` grammar + a new `### <Command>` subsection + a `## Practical workflows` example.
   - New global option → add a bullet under `## Global options`.
   - New built-in agent → add a line under `## Built-in agent registry`, in the same order as the upstream README table (alphabetical, with the mapping arrow).
   - New alias → add a `Rules:` bullet under the registry.
   - New exit code / env var → update `## Exit codes` / `## Environment variables` if those sections exist.
4. Ignore upstream changes that do not affect the CLI user model: internal runtime/embedding refactors, CI/CD, dependency bumps, adapter-internal fixes (unless they change a documented flag's behavior).
5. Keep the condensed, imperative style. Do not copy prose paragraphs from upstream verbatim — compress to bullets like the rest of the file.

## Local constraints (apply on top of upstream)

These are decisions specific to this plugin and override any upstream default.

### CRITICAL: `claude` adapter is blacklisted

This skill runs **inside Claude Code**. Invoking `acpx claude` spawns a nested Claude instance — redundant (double token spend), slower, and adds no model diversity. Therefore:

- The `claude` entry stays in `## Built-in agent registry` (it is a factual upstream mapping), BUT
- A `CRITICAL` rule under that registry forbids invoking `claude` unless the user explicitly asks for a second Claude instance by name.
- All **illustrative examples** in SKILL.md (compare, system-prompt, practical workflows, flow `--default-agent`) MUST use a non-Claude agent (`codex`, `gemini`, `qwen`, ...). Never write `acpx claude ...` in an example.
- The one exception: the `## System prompt override` section documents a mechanism that is itself Claude-only (`--system-prompt` is ignored by non-Claude adapters). It keeps the Claude form but carries an explicit exemption note pointing at the registry rule.

When you add new examples during sync, audit them: `grep -n 'claude' SKILL.md` and confirm every hit is either the registry mapping, the CRITICAL rule, the override section, or an env-var note — never a usage recommendation.

## Syncing the agent registry

The registry in SKILL.md must match the upstream `README.md` built-ins table (the `## Built-in agents and custom servers` section), including the adapter command strings (e.g. `npx -y mux@^0.27.0 acp`). If upstream bumps an adapter version range, mirror it here. Preserve the existing order/indentation style.

Aliases to keep in sync (record in `Rules:`): currently `factory-droid` / `factorydroid` → `droid`. Check `docs/agents.md` for any new aliases.

## Version bump

This plugin's version is **independent of the upstream CLI version** — it tracks doc-sync state, not the CLI feature set. Convention:

- **patch** (`0.2.0` → `0.2.1`): local constraint or doc-only fix (e.g. the claude-blacklist rule, an example fix, a typo).
- **minor** (`0.1.x` → `0.2.0`): new upstream capability documented (new command / option / agent).
- **major**: structural change to the skill or breaking reorganization.

Sync three files together after bumping:

1. `acpx/.claude-plugin/plugin.json` → `version`
2. `.claude-plugin/marketplace.json` → the `acpx` entry's `version` (and `description` if upstream wording shifted)
3. `acpx/README.md` → `**Version**:` line + Features list if capabilities changed

## Validate before committing

```bash
python3 plugin-optimizer/scripts/validate-plugin.py acpx
# exit 0 = passed; 1 = MUST violations; 2 = token budget exceeded (refactor)
```

Also self-check:

- `grep -n 'claude' acpx/skills/use-acpx/SKILL.md` — every hit is a non-recommendation (see the blacklist section above).
- `wc -l acpx/skills/use-acpx/SKILL.md` — stays roughly under 400 lines / within L2 budget.
- The three version strings above are identical.

## Checklist (copy this each sync)

- [ ] Shallow-clone upstream, read CHANGELOG between last-sync version and HEAD.
- [ ] Identify CLI-surface deltas (commands, global options, agents, aliases, exit codes, env vars).
- [ ] Apply deltas incrementally to the matching SKILL.md sections (no wholesale replace).
- [ ] Mirror the built-in agent registry against upstream README, including adapter version ranges and aliases.
- [ ] Verify NO new example uses the `claude` adapter; redirect to a non-Claude agent. `grep -n claude SKILL.md`.
- [ ] Bump plugin version (patch/minor) and sync `plugin.json` + `marketplace.json` + `README.md`.
- [ ] `validate-plugin.py acpx` → exit 0.
- [ ] Update the "Last synced" note below.

## Last synced

- **Upstream version**: v0.11.2 (2026-06-23)
- **Plugin version**: 0.2.1
- **Deltas applied**: `compare` subcommand (v0.11.0), `mux` built-in agent (v0.11.0), `--mcp-config` global option (v0.11.1), `factory-droid`/`factorydroid` alias, `authPolicy` config key, `ACPX_CLAUDE_INCLUDE_USER_SETTINGS` env var.
- **Local constraints**: `claude` adapter blacklisted (runs inside Claude Code).
