# Memory Plugin

Dual-layer memory consolidation, sync, and public/private separation for Claude Code projects. Manages the private harness memory (Tier A) and the repo-local memory (Tier B) — auto-consolidating Tier A on Stop, with manual skills to consolidate either layer, bidirectionally sync facts, promote a private fact to public, and recall across both.

**Version**: 0.1.0

## Installation

```bash
claude plugin install memory@frad-dotclaude
```

## Overview

Two memory systems coexist in a Claude Code project:

- **Tier A** — private harness memory at `~/.claude/projects/<escaped-cwd>/memory/`, loaded as session memory, consolidated on Stop with a 24h per-project debounce.
- **Tier B** — repo-local `docs/memory/`, git-tracked, indexed by `superpowers/lib/docs-index.sh` into `docs/README.md`, consumed by `reflect-skills-from-memory`.

This plugin automates Tier A consolidation and provides the manual operations the two layers were missing: consolidate, sync, publish, recall. A `visibility` field (`public` / `private` / `redacted`) gates what crosses the boundary; secret-bearing files are auto-redacted and never synced.

## Skills

### `/memory:consolidate <a|b|both>`

Runs the 5-phase consolidation pass (Read → Normalize → Dedupe/Resolve → Prune → Rebuild) over Tier A, Tier B, or both. The manual, foreground, no-debounce counterpart to the Stop hook.

### `/memory:sync <a-to-b|b-to-a|both>`

Bidirectionally syncs `visibility: public` facts between the two layers, translating frontmatter and body shape across the schemas. Private and redacted facts stay put.

### `/memory:publish <tier-a-file>`

One-shot promotion: sets `visibility: public` on a Tier A file and immediately creates its Tier B copy. Refuses on redacted (secret-bearing) files.

### `/memory:recall <query>`

Read-only lookup across both layers by free-text query. Returns matches labeled by layer and visibility; never prints the body of a redacted match.

## Hooks

### Stop — `hooks/consolidate-stop.sh`

Tier A auto-consolidation, debounced per project (24h). Resolves the session cwd from `CLAUDE_PROJECT_DIR` (falling back to the Stop payload's `cwd`), probes both space-handling escape forms, and backgrounds the 5-phase `claude -p` pass. Never breaks the turn; no memory dir → silent skip.

## References

- `references/tiers.md` — Tier A/B/C definitions, the `visibility` model, the escape convention.
- `references/sync-rules.md` — frontmatter/body translation, conflict resolution, redaction guards.
