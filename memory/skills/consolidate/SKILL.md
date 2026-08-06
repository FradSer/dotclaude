---
name: consolidate
description: This skill should be used when the user asks to "consolidate memory", "tidy memory", "整理记忆", "consolidate memory", "rebuild MEMORY.md", "sync memory", "sync memories", "双向同步记忆", "push memory to repo", "pull memory from repo", "promote a memory to public", "publish a memory", "发布记忆", "公开某条记忆", "move memory to repo", or wants to normalize, deduplicate, prune, rebuild, or sync project memory. Consolidates the project's memory — the private harness memory (~/.claude/projects/<escaped-cwd>/memory) and the repo-local memory (docs/memory/) — as one unlayered store.
user-invocable: true
allowed-tools: ["Read", "Write", "Glob", "Grep"]
---

# Consolidate Memory

One command, no options. The project's memory lives in two places but is one unlayered store; the AI decides what needs doing and does it.

- **Private harness memory** — `~/.claude/projects/<escaped-cwd>/memory` (`/`→`-`; space handling is inconsistent, probe both `/→-`+` →-` and `/→-`+space-kept). Index: `MEMORY.md`.
- **Repo memory** — `docs/memory/` in the project's git root. Files `<category>_<slug>.md`, frontmatter `name/category/summary/source/created/updated`, body `## Fact`/`## Why`/`## How to apply`/`## Related`. Indexed as a row in `docs/README.md`.

Both entry points — the manual `/memory:consolidate` and the Stop-hook background run — do the full pass over both locations.

## Red lines

- Never `git add`/`commit`/`status`/`diff` for committing. To commit repo memory changes, use the `/git:commit` skill.
- Never write a credential (password, secret, token, api-key, …) into `docs/memory/` — repo files must not carry secrets. Files whose name/body signals a secret stay as they are.

## What to do

For each location in scope:

1. **Read** every `*.md`, including the index (`MEMORY.md`, or the `docs/memory/` rows in `docs/README.md`).
2. **Normalize** — relative dates → absolute `YYYY-MM-DD` (today: `$(date +%F)`); complete the frontmatter.
3. **Deduplicate and merge** — merge duplicates within and across locations; keep the most detailed. The AI decides where the merged fact belongs.
4. **Prune** — keep active-project/infrastructure/preference facts and highly-`[[linked]]` ones; prune dormant (6+ months, no durable lesson), expired time-bound notes (keep transferable insights), and operational snapshots older than 3 months (date-mark survivors). Never prune a secret-bearing file for dormancy.
5. **Rebuild** — if anything changed, rebuild the index: rewrite `MEMORY.md` (one line per file, under 50 lines); for repo memory, update the `docs/README.md` rows (`updated` → today, refresh `summary`, drop removed files).

## Report

State per location: files read, files changed (path + one-line reason), facts merged / pruned / skipped, index rebuilt yes/no. If nothing changed, say so.
