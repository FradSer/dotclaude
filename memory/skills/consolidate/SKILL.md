---
name: consolidate
description: This skill should be used when the user asks to "consolidate memory", "tidy memory", "整理记忆", "consolidate Tier A", "consolidate Tier B", "rebuild MEMORY.md", "sync memory", "sync memories", "双向同步记忆", "push memory to repo", "pull memory from repo", "promote Tier A to Tier B", "backport Tier B to Tier A", "publish a memory", "promote a memory to public", "make this memory shareable", "发布记忆", "公开某条记忆", "move memory to repo", or wants to normalize, deduplicate, prune, rebuild, sync between layers, or publish a single fact across the private harness memory (Tier A, ~/.claude/projects/<escaped-cwd>/memory) and the repo-local memory (Tier B, docs/memory/). Runs the 5-phase consolidation pass over a layer, or the cross-layer sync/publish translation.
user-invocable: true
argument-hint: <a|b|both|sync|publish [target]>
allowed-tools: ["Read", "Write", "Glob", "Grep", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/memory-lib.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/classify.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/../superpowers/lib/docs-index.sh:*)"]
---

# Consolidate Memory

The single entry point for memory maintenance across both layers:

- **Tier A** — private harness memory (`~/.claude/projects/<escaped-cwd>/memory`), ungittracked.
- **Tier B** — repo-local memory (`docs/memory/`), git-tracked and reviewed.

The Stop hook automates Tier A consolidation on a 24h per-project debounce; this skill is the manual, foreground, no-debounce entry point. It also supersedes the former `sync` and `publish` skills — cross-layer translation is now a mode here, not a separate skill.

## When To Use

Arg `<mode>` selects the operation:

| Mode | Triggers | What it does |
|---|---|---|
| `a` (default) | "consolidate / tidy / rebuild Tier A" | 5-phase pass over Tier A only |
| `b` | "consolidate / rebuild Tier B" | 5-phase pass over Tier B only |
| `both` | "consolidate both layers" | 5-phase pass over A then B |
| `sync` | "sync / push / pull / 双向同步 memory" | Bidirectional A<->B translation, public facts only |
| `publish` | "publish / promote / make-public a memory / 发布记忆" | One-shot: flip one Tier A fact to public AND create its Tier B copy |

`sync` and `publish` accept a sub-arg: for `sync` the direction (`a-to-b` default, `b-to-a`, `both`); for `publish` the Tier A file path or `name:` slug.

## Workflow

### Phase 0 — Resolve the target(s)

Source `${CLAUDE_PLUGIN_ROOT}/lib/memory-lib.sh` and `lib/classify.sh` so `tier_a_dir`, `tier_b_dir`, `repo_root`, `read_visibility`, `set_visibility`, and `read_frontmatter_field` are available.

- Tier A: `MEM_A=$(tier_a_dir "$(pwd)")` — the private harness memory dir for this project. If empty, the project has no Tier A yet.
- Tier B: `ROOT=$(repo_root); MEM_B=$(tier_b_dir "$ROOT")` — repo-local `docs/memory/`. If empty, the repo has no Tier B layer.

If the mode is `a`/`b`/`both` and the target layer is absent, report and stop. If the mode is `sync`/`publish` and a needed layer is absent, report and skip that direction.

### Phase 1A — Consolidation pass (modes `a`, `b`, `both`)

For each resolved target dir, run the full consolidation as an in-context task (do NOT background `claude -p` — this is the manual skill, the agent IS the consolidator):

1. **Read** every `*.md` in the dir, including `MEMORY.md` (Tier A) or `docs/README.md`'s memory rows (Tier B).
2. **Normalize** — convert every relative date to absolute `YYYY-MM-DD` (today is the current date); ensure complete frontmatter. Tier A frontmatter: `name`, `description`, `metadata.type`. Tier B frontmatter: `name`, `category`, `summary`, `source`, `created`, `updated`.
3. **Deduplicate and Resolve** — merge entries appearing in multiple files (keep the most detailed); on contradiction, keep the most recent `updated` value and delete the stale one.
4. **Prune (importance-aware)** — KEEP active-project/infrastructure/preference facts and high-connectivity `[[linked]]` facts; PRUNE dormant (6+ months, no durable lesson), expired event/time-bound notes (retain only transferable insights), and pure operational snapshots older than 3 months (date-mark the survivors).
5. **Rebuild** — if files were added/removed/renamed, rebuild the index. Tier A: rewrite `MEMORY.md` as a clean one-line-per-file index under 50 lines. Tier B: run `bash ${CLAUDE_PLUGIN_ROOT}/../superpowers/lib/docs-index.sh rebuild` so `docs/README.md` re-scans `docs/memory/`.

### Phase 1B — Sync pass (mode `sync`)

Direction defaults to `a-to-b`. Resolve both layers (Phase 0); if a layer is absent, report and skip its direction.

**a-to-b (Tier A -> Tier B):** Scan every `*.md` in Tier A (excluding `MEMORY.md`). For each file, classify with `read_visibility "$file"`; skip unless it returns `public`. For each public Tier A fact:

1. Derive a Tier B filename: `docs/memory/<category>_<slug>.md`. `category` maps from Tier A `metadata.type`: `feedback`→`pitfall`, `project`→`decision`, `reference`→`preference`, `user`→`preference` (fall back to the Tier A file's topic if the mapping is unclear). `slug` is the Tier A `name:` field.
2. If a Tier B file with that name exists, this is an **update**; otherwise a **create**. See Conflict resolution below when both exist.
3. Translate the frontmatter: `name` carries over; `category` from step 1; `summary` from the Tier A `description`; `source` set to the Tier A file's origin project (the escaped cwd basename); `created`/`updated` to today.
4. Translate the body into the Tier B shape: `## Fact` (the one-sentence claim), `## Why` (from the Tier A `**Why:**` line), `## How to apply` (from `**How to apply:**`), `## Related` (from `[[links]]`, resolved to repo-relative paths where possible).
5. Write the Tier B file, then `bash ${CLAUDE_PLUGIN_ROOT}/../superpowers/lib/docs-index.sh upsert memory docs/memory/<file> --category <cat> --summary "<summary>"` so `docs/README.md` gains/updates the row.

**b-to-a (Tier B -> Tier A):** Scan every `docs/memory/*.md` in Tier B. Tier B defaults to `public`, but still run `read_visibility` (a Tier B file can be marked `redacted`). For each public Tier B fact:

1. Skip if a Tier A file with the same `name:` slug already exists and is `public` and newer-or-equal (Conflict resolution below).
2. Translate the frontmatter back: `metadata.type` from `category` (`pitfall`→`feedback`, `decision`→`project`, `preference`→`reference`); `description` from `summary`; keep `name`.
3. Translate the body into the Tier A shape: `**Why:**` from `## Why`, `**How to apply:**` from `## How to apply`, `[[links]]` from `## Related`.
4. Write the Tier A file and append a one-line pointer to `MEMORY.md` (if not already present).

**Conflict resolution** (a fact exists on both sides):

- Read the timestamp: Tier B `updated` field (`YYYY-MM-DD`); Tier A `metadata.modified` (ISO-8601, e.g. `2026-07-23T12:13:06.389Z`) — Tier A has no flat `updated` field. Use `read_frontmatter_field "$file" metadata.modified` on Tier A and `read_frontmatter_field "$file" updated` on Tier B. If Tier A has neither, treat it as older than any dated Tier B file.
- The side with the later date wins; copy its content to the loser.
- On a tie, **Tier B wins** — it is git-tracked and reviewed, Tier A is private and unreviewed.
- A `redacted` fact on either side always blocks that fact's sync, regardless of the other side's visibility.

See `references/sync-rules.md` for the full conflict-resolution rules.

### Phase 1C — Publish pass (mode `publish`)

Arg is a path or the `name:` slug of a Tier A file. Resolve `MEM_A=$(tier_a_dir "$(pwd)")`. Find the file: if the arg is a path, use it; if it's a slug, glob `$MEM_A/*.md` for one whose `name:` frontmatter matches. If not found, report and stop.

1. **Classify** — run `read_visibility "$file"`. If it returns `redacted`, REFUSE: the file is secret-bearing (name or body matches the denylist). Report that the user must manually redact the secrets first, then re-run. Do not proceed.
2. **Set visibility: public** — run `set_visibility "$file" public`. This updates the Tier A file's frontmatter in place.
3. **Create the Tier B copy** — run the same a-to-b translation as the `sync` mode for this single file: derive `docs/memory/<category>_<slug>.md`, translate frontmatter (`name`, `category`, `summary`←`description`, `source`←Tier A origin project, `created`/`updated`←today), translate body to `## Fact`/`## Why`/`## How to apply`/`## Related`, write under `$(repo_root)/docs/memory/`, then `bash ${CLAUDE_PLUGIN_ROOT}/../superpowers/lib/docs-index.sh upsert memory docs/memory/<file> --category <cat> --summary "<summary>"`.

### Phase 2 — Report

State per layer / direction: files read, files changed (path + one-line reason), facts created / updated / skipped (private or redacted), index rebuilt yes/no. For sync and publish, state conflict verdicts explicitly (which side won and why). If nothing changed, say so plainly.

## Hard Rules

- CRITICAL: Never run `git add`/`git commit`/`git status`/`git diff` for committing. When the user asks to commit Tier B changes, invoke the `/git:commit` skill via the Skill tool.
- CRITICAL: Tier A files live outside the repo and need no commit; do not attempt to `git add` them.
- CRITICAL: Never sync or publish a `redacted` fact. `read_visibility` returns `redacted` for any file whose name or body matches the secret denylist (`password`, `secret`, `token`, `apikey`, `api-key`, `privatekey`, `private-key`, `credential`); trust that, do not override. A bare `key` is not matched — key-bearing files must use a compound name or a `<!-- secret` body marker. `read_visibility` must return `public` (or `private`, which you then flip via `set_visibility`) before writing a Tier B copy — never `redacted`.
- CRITICAL: A Tier A fact with no explicit `visibility:` field defaults to `private` and is NOT synced. The user must run `consolidate publish <file>` first to set `visibility: public`.
- Tier B only: respect the existing frontmatter schema (`name/category/summary/source/created/updated`) and body shape (`## Fact`/`## Why`/`## How to apply`/`## Related`). See `references/tiers.md`.
- A file classified `redacted` by `lib/classify.sh` (secret-bearing) is never pruned for being "dormant" — it stays until manually removed.
