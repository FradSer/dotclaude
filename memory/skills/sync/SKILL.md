---
name: sync
description: This skill should be used when the user asks to "sync memory", "sync memories", "双向同步记忆", "push memory to repo", "pull memory from repo", "promote Tier A to Tier B", "backport Tier B to Tier A", or wants to bidirectionally synchronize facts between the private harness memory (Tier A) and the repo-local memory (Tier B). Translates frontmatter and body shape across the two schemas; only `visibility: public` facts are synced — private and redacted facts stay put.
user-invocable: true
argument-hint: <a-to-b|b-to-a|both>
allowed-tools: ["Read", "Write", "Glob", "Grep", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/memory-lib.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/classify.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/../superpowers/lib/docs-index.sh:*)"]
---

# Sync Memory (Tier A <-> Tier B)

Bidirectionally synchronize facts between the private harness memory (Tier A, `~/.claude/projects/<escaped-cwd>/memory`) and the repo-local memory (Tier B, `docs/memory/`). Only `visibility: public` facts cross the boundary; `private` and `redacted` facts never leave their layer. See `references/sync-rules.md` for the full conflict-resolution rules.

## When To Use

Trigger on requests to sync / push / pull memory between the two layers. Arg `<direction>` is `a-to-b` (default), `b-to-a`, or `both`.

## Workflow

### Phase 0 — Resolve both layers

Source `${CLAUDE_PLUGIN_ROOT}/lib/memory-lib.sh` and `lib/classify.sh`. Resolve:
- Tier A: `MEM_A=$(tier_a_dir "$(pwd)")`
- Tier B: `MEM_B=$(tier_b_dir "$(repo_root)")`

If a layer is absent, report and skip its direction.

### Phase 1 — a-to-b (Tier A -> Tier B)

Scan every `*.md` in Tier A (excluding `MEMORY.md`). For each file, classify with `read_visibility "$file"`; skip unless it returns `public`. For each public Tier A fact:

1. Derive a Tier B filename: `docs/memory/<category>_<slug>.md`. `category` maps from Tier A `metadata.type`: `feedback`→`pitfall`, `project`→`decision`, `reference`→`preference`, `user`→`preference` (fall back to the Tier A file's topic if the mapping is unclear). `slug` is the Tier A `name:` field.
2. If a Tier B file with that name exists, this is an **update**; otherwise a **create**. See Phase 3 for conflict resolution when both exist.
3. Translate the frontmatter: `name` carries over; `category` from step 1; `summary` from the Tier A `description`; `source` set to the Tier A file's origin project (the escaped cwd basename); `created`/`updated` to today.
4. Translate the body into the Tier B shape: `## Fact` (the one-sentence claim), `## Why` (from the Tier A `**Why:**` line), `## How to apply` (from `**How to apply:**`), `## Related` (from `[[links]]`, resolved to repo-relative paths where possible).
5. Write the Tier B file, then `bash ${CLAUDE_PLUGIN_ROOT}/../superpowers/lib/docs-index.sh upsert memory docs/memory/<file> --category <cat> --summary "<summary>"` so `docs/README.md` gains/updates the row.

### Phase 2 — b-to-a (Tier B -> Tier A)

Scan every `docs/memory/*.md` in Tier B. Tier B defaults to `public`, but still run `read_visibility` (a Tier B file can be marked `redacted`). For each public Tier B fact:

1. Skip if a Tier A file with the same `name:` slug already exists and is `public` and newer-or-equal (Phase 3 conflict rule).
2. Translate the frontmatter back: `metadata.type` from `category` (`pitfall`→`feedback`, `decision`→`project`, `preference`→`reference`); `description` from `summary`; keep `name`.
3. Translate the body into the Tier A shape: `**Why:**` from `## Why`, `**How to apply:**` from `## How to apply`, `[[links]]` from `## Related`.
4. Write the Tier A file and append a one-line pointer to `MEMORY.md` (if not already present).

### Phase 3 — Conflict resolution

When a fact exists on both sides:
- Read the timestamp: Tier B `updated` field (`YYYY-MM-DD`); Tier A `metadata.modified` (ISO-8601, e.g. `2026-07-23T12:13:06.389Z`) — Tier A has no flat `updated` field. Use `read_frontmatter_field "$file" metadata.modified` on Tier A and `read_frontmatter_field "$file" updated` on Tier B. If Tier A has neither, treat it as older than any dated Tier B file.
- The side with the later date wins; copy its content to the loser.
- On a tie, **Tier B wins** — it is git-tracked and reviewed, Tier A is private and unreviewed.
- A `redacted` fact on either side always blocks that fact's sync, regardless of the other side's visibility.

### Phase 4 — Report

Per direction: facts created / updated / skipped (private or redacted), with paths. State the conflict verdicts explicitly (which side won and why).

## Hard Rules

- CRITICAL: Never sync a `redacted` fact. `read_visibility` returns `redacted` for any file whose name or body matches the secret denylist (`password`, `secret`, `token`, `apikey`, `api-key`, `privatekey`, `private-key`, `credential`); trust that, do not override. A bare `key` is not matched — key-bearing files must use a compound name or a `<!-- secret` body marker.
- CRITICAL: Never run `git add`/`git commit` for committing Tier B changes — invoke `/git:commit` via the Skill tool when asked.
- A Tier A fact with no explicit `visibility:` field defaults to `private` and is NOT synced. The user must `/memory:publish` it first to set `visibility: public`.
