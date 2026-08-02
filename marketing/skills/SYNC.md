# Marketing Skills Sync

**Upstream**: [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) (main branch)
**Last sync**: 2026-08-02
**Synced commit**: 7868cb9

## Sync Strategy

Mirrors all functional content from upstream `main` to keep this plugin
**functionally identical** to upstream:

- **`skills/`** and **`tools/`** — mirrored as whole subtrees (rebuilt on each
  sync so upstream deletions take effect).
- **Root functional files** — `CLAUDE.md`, `AGENTS.md`, `VERSIONS.md`,
  `validate-skills.sh`, `validate-skills-official.sh` — copied individually.
  `CLAUDE.md`/`AGENTS.md` carry the agent guidance for using the skills and
  tools; `VERSIONS.md` is the per-skill version registry; the validate scripts
  audit skills against the Agent Skills spec.

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

### Co-habitation with the hyperframes sub-tree

`skills/hyperframes/` is a **separately-synced** sub-tree mirrored from
`heygen-com/hyperframes` (a different upstream than the marketing skills). The
marketing sync rebuilds `skills/` on each run, so it **backs up and restores**
`hyperframes/` around its own sync — run `sync-hyperframes.sh` to update the
hyperframes side independently. The two sync scripts do not disturb each
other's mirrors. HyperFrames applies the same denest locally (its own router
`SKILL.md` stays; sub-skills become `<name>/<name>.md`).

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
