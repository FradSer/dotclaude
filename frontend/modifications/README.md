# Modifications

Structured log of local modifications to upstream-synced skills in `frontend/`.

## Why this exists

Several skills under `frontend/skills/` are synced from upstream repositories
(`vercel-labs/agent-skills`, `shadcn-ui/ui`, `supabase/agent-skills`,
`pbakaus/impeccable`). The sync scripts **wipe the skill directory and replace
it with upstream content** — any local additions are lost on sync.

This directory preserves modification intent so local changes can be re-applied
after each sync.

## Format

One file per modified skill. Each modification is a block:

```
## <verb>: <short title>
**Target**: <path relative to frontend/>
**Intent**: <what + why — one paragraph>
**Content**:
<full content to insert, replace, or create — fenced or inline as needed>
**Added**: YYYY-MM-DD
```

Verbs: `Add` (new file or section), `Edit` (modify existing), `Remove` (delete).

Content for whole new files should be the entire file body (including
frontmatter). Content for edits should be an unambiguous patch: the anchor
section + what to add/replace.

## Workflow

1. Make the local change directly in the target skill file.
2. Record the change as a block in `modifications/<skill>.md`.
3. After running a sync script, re-apply all entries in the matching
   `modifications/<skill>.md` file.

## Re-applying after sync

Sync scripts print a replay hint when they finish. To re-apply, ask the
assistant:

> Read `frontend/modifications/<skill>.md` and re-apply every entry to the
> target files.

The assistant parses each block, recreates files, and edits existing files
according to `Intent` + `Content`. If upstream has moved or renamed the anchor
section, the assistant places the modification in the new location and flags
the mismatch for human review — it does not silently skip or duplicate.

## Current modifications

- [react-best-practices.md](./react-best-practices.md) — React 19 hooks, React
  Compiler, state management, RSC + TanStack Query hybrid
- [shadcn.md](./shadcn.md) — Tailwind v4 CSS-first configuration guidance
- [impeccable.md](./impeccable.md) — no override: `SKILL.md` tracks upstream verbatim;
  documents the bundled-script-path caveat and the options to make scripts run in-plugin
