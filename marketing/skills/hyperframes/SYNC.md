# HyperFrames Skills Sync

**Upstream**: [heygen-com/hyperframes](https://github.com/heygen-com/hyperframes) `skills/` (main branch)
**Last sync**: 2026-07-15
**Synced commit**: b9be0b2

## Sync Strategy

Uses `git sparse-checkout` to clone the `skills/` directory **and** the root
functional files (`CLAUDE.md`, `AGENTS.md`) from upstream `main`, then mirrors
them into this directory. The skills mirror is full — including binary assets
(fonts, SVG, images) that some skills (e.g. `embedded-captions`) require at
runtime.

The root `CLAUDE.md`/`AGENTS.md` are the upstream agent guides (skill catalog,
install instructions, skill-catalog maintenance rules). They are mirrored as
**`UPSTREAM-CLAUDE.md`** / **`UPSTREAM-AGENTS.md`** (prefixed) to avoid
colliding with the marketing plugin root's own `CLAUDE.md` (which is the
`coreyhaines31/marketingskills` upstream guide). Read them for the authoritative
upstream skill list and workflow descriptions.

Cross-skill references in upstream bodies use backtick-quoted skill names
(e.g. `` `hyperframes-core` ``, `` `media-use` ``) or slash-prefixed links in
the top-level router table. These are resolved by skill **name**, so they work
unchanged once the skills are mirrored here — the sync script does NOT rewrite
them. The mirrored upstream router lives at `hyperframes/SKILL.md` (the
`hyperframes` sub-skill directory); it is kept for fidelity but is NOT the
loaded entry point — the local top-level `SKILL.md` above is.

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

## Co-habitation with the marketing skills

This sub-tree lives inside the `marketing` plugin's `skills/` directory, but is
synced independently from `heygen-com/hyperframes` (a different upstream than
the marketing skills, which come from `coreyhaines31/marketingskills`). The
marketing sync script (`marketing/scripts/sync-marketing.sh`) rebuilds `skills/`
on each run, so it **backs up and restores** this `hyperframes/` sub-tree around
its own sync — the two sync scripts do not disturb each other's mirrors.

## Running Sync

```bash
# Check for updates (dry-run)
bash marketing/scripts/sync-hyperframes.sh --check

# Sync with backup
bash marketing/scripts/sync-hyperframes.sh

# Force sync, skip confirmation
bash marketing/scripts/sync-hyperframes.sh --force
```

After a sync that adds/removes/renames a sub-skill, update the Sub-skill Index
table in `SKILL.md` to match the mirrored directories.
