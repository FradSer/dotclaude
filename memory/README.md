# Memory Plugin

Dual-layer memory consolidation, sync, and public/private separation for Claude Code projects. Manages the private harness memory (Tier A) and the repo-local memory (Tier B) — auto-consolidating Tier A on Stop, with a single manual skill to consolidate either layer, bidirectionally sync facts, or promote a private fact to public.

**Version**: 0.1.1

## Installation

```bash
claude plugin install memory@frad-dotclaude
```

## Overview

Two memory systems coexist in a Claude Code project:

- **Tier A** — private harness memory at `~/.claude/projects/<escaped-cwd>/memory/`, loaded as session memory, consolidated on Stop with a 24h per-project debounce.
- **Tier B** — repo-local `docs/memory/`, git-tracked, indexed by `superpowers/lib/docs-index.sh` into `docs/README.md`, consumed by `reflect-skills-from-memory`.

This plugin automates Tier A consolidation and provides the manual operations the two layers were missing: consolidate, sync, publish. A `visibility` field (`public` / `private` / `redacted`) gates what crosses the boundary; secret-bearing files are auto-redacted and never synced.

## Skill

### `/memory:consolidate <a|b|both|sync|publish [target]>`

The single entry point for memory maintenance across both layers. The mode selects the operation:

| Mode | What it does |
|---|---|
| `a` (default) | 5-phase consolidation pass (Read → Normalize → Dedupe/Resolve → Prune → Rebuild) over Tier A only |
| `b` | 5-phase pass over Tier B only |
| `both` | 5-phase pass over Tier A then B |
| `sync` | Bidirectional A<->B translation of `visibility: public` facts |
| `publish` | One-shot: flip one Tier A fact to public and create its Tier B copy |

`sync` takes a direction (`a-to-b` default, `b-to-a`, `both`); `publish` takes the Tier A file path or `name:` slug. Private and redacted facts stay put — never synced or published. The manual, foreground, no-debounce counterpart to the Stop hook.

## Hooks

### Stop — `hooks/consolidate-stop.sh`

Tier A auto-consolidation, debounced per project (24h). Resolves the session cwd from `CLAUDE_PROJECT_DIR` (falling back to the Stop payload's `cwd`), probes both space-handling escape forms, and backgrounds the 5-phase `claude -p` pass. Never breaks the turn; no memory dir → silent skip.

## References

- `references/tiers.md` — Tier A/B/C definitions, the `visibility` model, the escape convention.
- `references/sync-rules.md` — frontmatter/body translation, conflict resolution, redaction guards.
