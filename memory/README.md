# Memory Plugin

Consolidates a Claude Code project's memory — the private harness memory at `~/.claude/projects/<escaped-cwd>/memory/` and the repo-local `docs/memory/` — as one unlayered store. Auto-consolidates the private memory on Stop with a 24h per-project debounce, plus a single manual skill for the full pass.

**Version**: 0.1.1

## Installation

```bash
claude plugin install memory@frad-dotclaude
```

## Overview

A project's memory lives in two places but is one store. There is no public/private, no visibility field, no sync — the AI decides what needs consolidating, deduplicating, merging, or pruning, and where each fact belongs.

- **Private harness memory** — `~/.claude/projects/<escaped-cwd>/memory/`, loaded as session memory. Indexed by `MEMORY.md`.
- **Repo memory** — `docs/memory/` in the project's git root, git-tracked. Indexed as rows in `docs/README.md`, consumed by `reflect-skills-from-memory`.

**Everything is AI-processed**: all consolidation decisions live in the skill instructions; the plugin carries almost no code.

## How it works

- **Slash command** `/memory:consolidate` — no arguments. Consolidates the private memory and the repo memory.
- **Stop hook** `hooks/consolidate-stop.sh` — a launcher only: resolves the session cwd, debounces per project (24h), and backgrounds a headless `claude -p` that reads the same SKILL.md and runs the full pass over both the private harness memory and the repo memory. The hook contains no memory logic.

The only rule beyond "let the AI decide" is that repo memory must never carry secrets — a leaked credential is irreversible — so files whose name/body signals a secret are left as-is.

## Skill

### `/memory:consolidate`

No arguments. Reads, normalizes, deduplicates, prunes, and rebuilds the index across both locations. The AI decides where merged facts belong and which to keep.

## Files

```
memory/
├── .claude-plugin/plugin.json   # Stop hook + consolidate command
├── hooks/consolidate-stop.sh    # launcher only: cwd → debounce → background claude -p (full pass)
├── skills/consolidate/SKILL.md  # all memory logic, as AI instructions (single source of truth)
└── README.md
```
