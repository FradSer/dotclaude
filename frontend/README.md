# Frontend Plugin

**Version**: 0.6.0

Frontend **design integration layer** — the original, locally-authored content that grounds design work in the project's `DESIGN.md` token source of truth. v0.6.0 slimmed the plugin down from 9 skills to its integration layer; upstream-mirror skills were unbundled so users install them directly from their upstream repos.

## v0.6.0 Migration — deleted mirror skills

The following skills were removed as upstream mirrors. Install each upstream repo directly to get them back:

| Deleted skill | Upstream repo |
|---|---|
| `impeccable` | [pbakaus/impeccable](https://github.com/pbakaus/impeccable) |
| `shadcn` | [shadcn-ui/ui](https://github.com/shadcn-ui/ui) |
| `react-best-practices` | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) |
| `web-design-guidelines` | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) |
| `supabase` | [supabase/agent-skills](https://github.com/supabase/agent-skills) |
| `supabase-postgres-best-practices` | [supabase/agent-skills](https://github.com/supabase/agent-skills) |

The `frontend-anti-patterns` agent lost its `impeccable` `detect.mjs` computed detector and now runs manual checks only — install `pbakaus/impeccable` upstream to restore the detector. The `design-md-first` hook's token-authority ladder was slimmed from 4 steps to design-md + anti-patterns.

## Skills (3)

### Design System Source of Truth

| Skill | Source | Sync Script |
|---|---|---|
| design-md | [google-labs-code/design.md](https://github.com/google-labs-code/design.md) | `sync-design-md.sh` |

### Design Vocabulary & Runtime

| Skill | Source | Sync Script |
|---|---|---|
| articulate | [index.how/to/articulate](https://index.how/to/articulate) | local (manual) |
| next-devtools-guide | local | -- |

## Agents (2)

| Agent | Purpose |
|---|---|
| frontend-expert | Coordinator across the surviving skills; recommends the right skill for any task |
| frontend-anti-patterns | Detects UI anti-patterns: AI slop and design quality issues (manual checks) |

## Syncing

Only `design-md` still syncs from upstream (caches the spec; `SKILL.md` is local). Sync metadata is in `SYNC.md`.

```bash
# DESIGN.md spec (from google-labs-code/design.md)
./scripts/sync-design-md.sh

# Check for updates (dry run)
./scripts/sync-design-md.sh --check

# Cross-skill consistency + reference checks
./scripts/check-coherence.sh
./scripts/check-references.sh
```

## Hook

- **`design-md-first.sh`** (UserPromptSubmit) — when the working directory has a `DESIGN.md`, injects a token-authority ladder preamble grounding design work in `design-md` as the source of truth. Slimmed to design-md + anti-patterns in v0.6.0.

## MCP Server

- **next-devtools**: Next.js runtime diagnostics, Cache Components, documentation (7 tools + 2 prompts + 17 resources)

## License

MIT
