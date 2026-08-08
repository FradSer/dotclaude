---
name: consolidate
description: This skill should be used when the user asks to "consolidate memory", "tidy memory", "rebuild MEMORY.md", or wants to normalize, deduplicate, prune, or rebuild project memory. Consolidates the project's memory as one unlayered store — the private harness memory (~/.claude/projects/<escaped-cwd>/memory) and the repo-local memory (docs/memory/).
user-invocable: true
allowed-tools: ["Read", "Write", "Glob", "Grep"]
---

# Consolidate Memory

One command, no options. The project's memory lives in two physical locations but is one unlayered store; the AI decides what needs doing and does it.

- **Private harness memory** — `~/.claude/projects/<escaped-cwd>/memory` (`/`→`-`; space handling is inconsistent, probe both `/→-`+` →-` and `/→-`+space-kept). Index: `MEMORY.md`.
- **Repo memory** — `docs/memory/` in the project's git root. Files `<category>_<slug>.md`, frontmatter `name/category/summary/source/created/updated`, body `## Fact`/`## Why`/`## How to apply`/`## Related`. Indexed as a row in `docs/README.md`.

Both entry points — the manual `/memory:consolidate` and the Stop-hook background run — do the full pass over both locations.

## CRITICAL: Memory is decision log, not operation log

Every memory file must answer two questions only:
- **Why** — why this decision or rule exists
- **How to apply** — what to do next time

Remove all operation history (version numbers, dates-as-timeline, "first we did X then we did Y"). That information lives in `git log`. Keep only the durable rationale and the actionable rules.

## CRITICAL: MEMORY.md index format

Each index line must be a single concise sentence with:
- **No version numbers** (`v0.5.3`, `v3.8.0`, `v1.1.x` — these go in git log)
- **No date ranges** (`2026-08-04`, `v3.2.0–v3.7.0` — these go in git log)
- **No timeline descriptions** ("first fix X then Y was added")
- **Only the essence** of what the memory is about and why it matters

Good: `feedback_git_commit_hook_needed.md — git PreToolUse hook intercepts git add/commit, redirects to /git:commit; allows chain + GIT_SKILL_FALLBACK=1 escape`
Bad:  `feedback_git_commit_hook_needed.md — git PreToolUse hook intercepts git add/commit; v0.5.3 command position anchoring + two exceptions + 26 regression tests; planner timeout add --free`

## Red lines

- Never `git add`/`commit`/`status`/`diff` for committing. To commit repo memory changes, use the `/git:commit` skill.
- Never write a credential (password, secret, token, api-key, …) into `docs/memory/` — repo files must not carry secrets. Files whose name/body signals a secret stay as they are.
- Never drop a file's `[[linked]]` references when rewriting — cross-links are the graph that makes memory useful. Preserve all `[[name]]` links from the original.
- Never delete a file that is referenced by `[[name]]` in another memory file, unless the reference is also removed from the referencing file.

## What to do

For each location in scope:

### 1. Read every file

Read every `*.md`, including the index (`MEMORY.md`, or the `docs/memory/` rows in `docs/README.md`).

### 2. Normalize

- Relative dates → absolute `YYYY-MM-DD` (today: `$(date +%F)`)
- Complete the frontmatter: `name`, `description`, `type` (private) or `category`/`summary`/`source`/`created`/`updated` (repo)
- `description` must be a terse hook — short enough to fit in a one-line index, specific enough to distinguish from similar files

### 3. Deduplicate and merge

Merge duplicates within and across locations; keep the most detailed. The AI decides where the merged fact belongs. Check for cross-location duplicates (same topic in private memory + repo memory) — if found, merge into the location that matches the file's category (technical pitfalls → repo memory, behavioral preferences → private memory).

### 4. Prune

Keep active-project/infrastructure/preference facts and highly-`[[linked]]` ones. Prune:
- Dormant (6+ months, no durable lesson)
- Expired time-bound notes (keep transferable insights)
- Operational snapshots older than 3 months (date-mark survivors)
- **Operation history**: version numbers, step-by-step timelines, "first we did X then Y" — these belong in `git log`

Never prune a secret-bearing file for dormancy.

### 5. Rewrite for concision

Each memory file body should be:
- **Why** — the root cause or decision rationale (1-3 paragraphs max)
- **How to apply** — the actionable rules (bullet list preferred)
- **Related** — `[[name]]` cross-links to other memory files

Strip operation history, version numbers, and play-by-play timelines. Keep only the durable lesson.

### 6. Rebuild index

If anything changed, rebuild the index:
- **Private memory**: rewrite `MEMORY.md` — one line per file, under 50 lines, no version numbers or date ranges in descriptions
- **Repo memory**: update the `docs/README.md` rows (`updated` → today, refresh `summary`, drop removed files)

## Report

State per location: files read, files changed (path + one-line reason), facts merged / pruned / skipped, index rebuilt yes/no. If nothing changed, say so.