# Marketing Skills Sync

**Upstream**: [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) (main branch)
**Last sync**: 2026-08-02
**Synced commit**: 7868cb9

## Sync Strategy

Mirrors all functional content from upstream `main` to keep this plugin
**functionally identical** to upstream:

- **`skills/`** and **`tools/`** — mirrored as whole subtrees (rebuilt on each
  sync so upstream deletions take effect).
- **Root functional files** — `CLAUDE.md`, `AGENTS.md`, `VERSIONS.md` — copied
  individually. `CLAUDE.md`/`AGENTS.md` carry the agent guidance for using the
  skills and tools; `VERSIONS.md` is the per-skill version registry.
- **Locally maintained, NOT overwritten** — `validate-skills.sh` and
  `validate-skills-official.sh` are denest-adapted derivatives of the upstream
  spec-audit scripts. Upstream assumes every skill has `skills/<name>/SKILL.md`,
  but this mirror denests to `skills/<name>/<name>.md`, so verbatim copying those
  scripts makes them report false failures. They are kept in the repo and skipped
  by the sync (see `scripts/sync-marketing.sh` `UPSTREAM_FILES`). For real
  validation use `python3 plugin-optimizer/scripts/validate-plugin.py marketing`.

Upstream is itself a Claude Code plugin using `"skills": "./skills"`
auto-discovery and ships every skill as `<name>/SKILL.md`. Claude Code / Cursor
auto-discover any directory containing `SKILL.md`, so upstream's flat layout
would register ~49 extra skills alongside the router.

### Local router + denest (required)

After each sync this plugin applies a local transform (lark-style):

1. **Router** — `skills/SKILL.md` is a local `marketing` router (index table
   generated from sub-skill frontmatter by `tools/skill-sync/gen-index.py`).
   It is backed up before the sync rebuilds `skills/` and restored after.
2. **Denest** — `tools/skill-sync/denest.py` renames every
   `skills/<name>/SKILL.md` → `skills/<name>/<name>.md` and rewrites relative
   links (`../foo/SKILL.md` → `../foo/foo.md`, parent `../SKILL.md` → exact
   path to the owning skill's entry). Only the router `SKILL.md` remains
   discoverable. `--check` denests a temp copy of upstream before diffing so
   local transforms do not look like drift.

Cross-skill references use backtick-quoted skill names (e.g. "see onboarding")
resolved by name, so they work unchanged after mirroring. The `tools/` tree
holds CLI wrappers some skills invoke.

### Former co-habitation with the hyperframes sub-tree

Earlier revisions carried a `skills/hyperframes/` sub-tree (mirrored from
`heygen-com/hyperframes`) that the marketing sync backed up and restored around
its own run. HyperFrames is now a **standalone plugin** (`hyperframes/`, its own
marketplace entry and `scripts/sync-hyperframes.sh`); there is no
`skills/hyperframes/` here and the two syncs are independent. This note records
why older SYNC.md revisions mention that backup/restore step.

### Excluded (upstream repo metadata, replaced by local marketplace metadata)

`README.md`, `CONTRIBUTING.md`, `.github/`, `.gitignore`, `FUNDING.yml`,
`LICENSE` — these describe the upstream *repo*, not plugin function, and are
superseded by this marketplace's own entries.

## Version Tracking

`**Synced commit**` records the upstream `main` commit. Upstream tracks
per-skill versions in `VERSIONS.md` (mirrored at the plugin root); re-sync to
pull new skills or version bumps. The sync script refreshes `Last sync` and
`Synced commit` on each run.

## Validation Note

Upstream skill bodies are written for a broad audience and several exceed the
plugin-optimizer's 5k-token body budget (ads, ai-seo, directory-submissions,
marketing-psychology). This plugin sets `strict: false` in marketplace.json, so
those MUST-level warnings do not block installation. They are NOT edited here —
editing mirrored upstream content would break sync fidelity (re-sync overwrites
local edits).

## Running Sync

```bash
bash marketing/scripts/sync-marketing.sh --check   # dry-run
bash marketing/scripts/sync-marketing.sh            # sync with backup
bash marketing/scripts/sync-marketing.sh --force    # skip confirmation
```

## Re-running the Transforms

```bash
# Re-run denest only (e.g. after a partial sync)
python3 tools/skill-sync/denest.py --tree marketing/skills
python3 tools/skill-sync/denest.py --tree marketing/skills --check

# Regenerate the router index table from sub-skill frontmatter
python3 tools/skill-sync/gen-index.py --skills marketing/skills --router marketing/skills/SKILL.md --versions marketing/VERSIONS.md
python3 tools/skill-sync/gen-index.py --skills marketing/skills --router marketing/skills/SKILL.md --versions marketing/VERSIONS.md --check
```
