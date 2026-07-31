---
name: recall
description: This skill should be used when the user asks to "recall a memory", "look up memory", "find a memory", "查记忆", "recall facts about", "what do I remember about", or wants to look up facts across both memory layers (Tier A private harness + Tier B repo-local) by a free-text query. Read-only lookup — the counterpart to consolidation and sync. Returns matches with their layer and visibility label, never writes.
user-invocable: true
argument-hint: <query>
allowed-tools: ["Read", "Grep", "Glob", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/memory-lib.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/classify.sh:*)"]
---

# Recall Memory (cross-layer lookup)

Read-only lookup across both memory layers by a free-text query. The read counterpart to `/memory:consolidate` and `/memory:sync` — this never writes. Returns each match with its layer (Tier A / Tier B) and visibility (public / private / redacted).

## When To Use

Trigger on requests to recall / look up / find a memory or facts about a topic. Arg `<query>` is free text.

## Workflow

### Phase 1 — Resolve both layers

Source `lib/memory-lib.sh` and `lib/classify.sh`.
- Tier A: `MEM_A=$(tier_a_dir "$(pwd)")` — read its `MEMORY.md` index first.
- Tier B: `MEM_B=$(tier_b_dir "$(repo_root)")` — read `docs/README.md`'s memory rows first.

### Phase 2 — Grep both layers

For each layer present, grep the `*.md` files (including the index) for the query terms (case-insensitive, OR semantics across the query's words). For each hit:
1. Identify the file and its `name:` frontmatter slug.
2. Classify with `read_visibility "$file"` to label it public / private / redacted.
3. Extract the one-line summary (Tier A `description`, Tier B `summary`).

### Phase 3 — Report

Group results by layer, then list each match: `layer | visibility | slug — summary — path`. For `redacted` matches, show only the slug and layer — do NOT print the body or the path to the secret file. If nothing matches, say so plainly.

## Hard Rules

- CRITICAL: Read-only. Never `Write`/`Edit`/`mv`/`rm` any file. This is lookup only.
- CRITICAL: For `redacted` matches, never print the file's body or its full path — only the slug. Secrets stay hidden even from recall output.
