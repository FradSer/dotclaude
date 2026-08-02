# HyperFrames Skills Sync

**Upstream**: [heygen-com/hyperframes](https://github.com/heygen-com/hyperframes) `skills/` (main branch)
**Last sync**: 2026-08-02
**Synced commit**: 74fadf6

## Sync Strategy

Uses `git sparse-checkout` to clone the `skills/` directory **and** the root
functional files (`CLAUDE.md`, `AGENTS.md`) from upstream `main`, then mirrors
them into this directory. The skills mirror is full — including binary assets
(fonts, SVG, images) that some skills (e.g. `embedded-captions`) require at
runtime.

The root `CLAUDE.md`/`AGENTS.md` are the upstream agent guides (skill catalog,
install instructions, skill-catalog maintenance rules). They are mirrored as
**`UPSTREAM-CLAUDE.md`** / **`UPSTREAM-AGENTS.md`** (prefixed) to avoid
colliding with this plugin's local guides. Read them for the authoritative
upstream skill list and workflow descriptions.

Cross-skill references in upstream bodies use backtick-quoted skill names
(e.g. `` `hyperframes-core` ``, `` `media-use` ``) or slash-prefixed links in
the top-level router table. These are resolved by skill **name**, so they work
unchanged once the skills are mirrored here — the sync script does NOT rewrite
them. The mirrored upstream router lives at `hyperframes/hyperframes.md` (the
`hyperframes` sub-skill directory); it is kept for fidelity but is NOT the
loaded entry point — the local top-level `SKILL.md` above is.

### Sub-skill denest (required)

Upstream ships every sub-skill as `<name>/SKILL.md`. Claude Code / Cursor
auto-discover any directory containing a file named `SKILL.md`, so leaving
those nested files would register ~19 extra skills alongside the router.

After each sync, `scripts/sync-hyperframes.sh` invokes
`tools/skill-sync/denest.py` with `--hf-root` (the tree
root IS the hyperframes sub-tree, so top-level dirs are sub-skills directly):

1. Renames `<name>/SKILL.md` → `<name>/<name>.md` (e.g.
   `motion-graphics/SKILL.md` → `motion-graphics/motion-graphics.md`)
2. Rewrites relative links (`../SKILL.md` → exact path to the owning
   sub-skill's entry, e.g. `../../media-use.md` from
   `media-use/audio/references/`)

Only the local top-level router `SKILL.md` remains discoverable. `--check`
denests a temp copy of upstream before diffing so local transforms do not look
like drift.

## Version Tracking

`**Synced commit**` records the upstream `main` commit the skills were pulled
from. Re-sync whenever the HyperFrames CLI (`npx hyperframes`) updates so the
bundled skills stay aligned with the framework you actually run. The sync
script refreshes the `Last sync` and `Synced commit` fields automatically on
each run.

## Local Additions

The following files are maintained locally and are NOT overwritten by sync:

- `SKILL.md` -- Top-level router skill (local). Its Sub-skill Index is
  hand-maintained from sub-skill frontmatter; refresh it when upstream adds,
  removes, or renames a skill.
- `SYNC.md` -- This file
- `LICENSE` -- Local marketplace license note

## Plugin structure

This is a standalone `hyperframes` plugin: the skills tree lives at the plugin
root's `skills/` directory and is synced independently from
`heygen-com/hyperframes` (separate from the `marketing` plugin, which mirrors
`coreyhaines31/marketingskills`).

## Running Sync

```bash
# Check for updates (dry-run)
bash hyperframes/scripts/sync-hyperframes.sh --check

# Sync with backup
bash hyperframes/scripts/sync-hyperframes.sh

# Force sync, skip confirmation
bash hyperframes/scripts/sync-hyperframes.sh --force
```

After a sync that adds/removes/renames a sub-skill, update the Sub-skill Index
table in `SKILL.md` to match the mirrored directories.
