---
name: consolidate
description: This skill should be used when the user asks to "consolidate memory", "tidy memory", "整理记忆", "consolidate Tier A", "consolidate Tier B", "rebuild MEMORY.md", or wants to normalize, deduplicate, prune, and rebuild either the private harness memory (Tier A, ~/.claude/projects/<escaped-cwd>/memory) or the repo-local memory (Tier B, docs/memory/). Runs the 5-phase consolidation pass (Read, Normalize, Dedupe/Resolve, Prune, Rebuild) over the chosen layer.
user-invocable: true
argument-hint: <a|b|both>
allowed-tools: ["Read", "Write", "Glob", "Grep", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/memory-lib.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/../superpowers/lib/docs-index.sh:*)"]
---

# Consolidate Memory

Run the 5-phase consolidation pass (Read → Normalize → Dedupe/Resolve → Prune → Rebuild) over the Tier A private memory, the Tier B repo-local memory, or both. The Stop hook automates Tier A on a 24h per-project debounce; this skill is the manual, foreground, no-debounce entry point for either layer.

## When To Use

Trigger on requests to consolidate / tidy / rebuild either memory layer. Arg `<tier>` is `a` (default), `b`, or `both`.

## Workflow

### Phase 0 — Resolve the target(s)

Source `${CLAUDE_PLUGIN_ROOT}/lib/memory-lib.sh` so `tier_a_dir`, `tier_b_dir`, and `repo_root` are available.

- Tier A: `MEM_A=$(tier_a_dir "$(pwd)")` — the private harness memory dir for this project. If empty, the project has no Tier A yet; report and stop for tier `a`.
- Tier B: `ROOT=$(repo_root); MEM_B=$(tier_b_dir "$ROOT")` — the repo-local `docs/memory/`. If empty, the repo has no Tier B layer; report and stop for tier `b`.

### Phase 1–5 — Consolidation pass

For each resolved target dir, run the full consolidation as an in-context task (do NOT background `claude -p` — this is the manual skill, the agent IS the consolidator):

1. **Read** every `*.md` in the dir, including `MEMORY.md` (Tier A) or `docs/README.md`'s memory rows (Tier B).
2. **Normalize** — convert every relative date to absolute `YYYY-MM-DD` (today is the current date); ensure complete frontmatter. Tier A frontmatter: `name`, `description`, `metadata.type`. Tier B frontmatter: `name`, `category`, `summary`, `source`, `created`, `updated`.
3. **Deduplicate and Resolve** — merge entries appearing in multiple files (keep the most detailed); on contradiction, keep the most recent `updated` value and delete the stale one.
4. **Prune (importance-aware)** — KEEP active-project/infrastructure/preference facts and high-connectivity `[[linked]]` facts; PRUNE dormant (6+ months, no durable lesson), expired event/time-bound notes (retain only transferable insights), and pure operational snapshots older than 3 months (date-mark the survivors).
5. **Rebuild** — if files were added/removed/renamed, rebuild the index. Tier A: rewrite `MEMORY.md` as a clean one-line-per-file index under 50 lines. Tier B: run `bash ${CLAUDE_PLUGIN_ROOT}/../superpowers/lib/docs-index.sh rebuild` so `docs/README.md` re-scans `docs/memory/`.

### Phase 6 — Report

State per layer: files read, files changed (path + one-line reason), index rebuilt yes/no. If nothing changed, say so plainly.

## Hard Rules

- CRITICAL: Never run `git add`/`git commit`/`git status`/`git diff` for committing. When the user asks to commit Tier B changes, invoke the `/git:commit` skill via the Skill tool.
- CRITICAL: Tier A files live outside the repo and need no commit; do not attempt to `git add` them.
- Tier B only: respect the existing frontmatter schema (`name/category/summary/source/created/updated`) and body shape (`## Fact`/`## Why`/`## How to apply`/`## Related`). See `references/tiers.md`.
- A file classified `redacted` by `lib/classify.sh` (secret-bearing) is never pruned for being "dormant" — it stays until manually removed.
