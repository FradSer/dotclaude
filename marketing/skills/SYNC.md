# Marketing Skills Sync

**Upstream**: [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) (main branch)
**Last sync**: 2026-07-15
**Synced commit**: 130847d

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
auto-discovery (no router skill), so this plugin does the same — all mirrored
skills are discovered automatically; no hand-maintained index table. Cross-skill
references use backtick-quoted skill names (e.g. "see onboarding") resolved by
name, so they work unchanged after mirroring. The `tools/` tree holds CLI
wrappers some skills invoke.

### Co-habitation with the hyperframes sub-tree

`skills/hyperframes/` is a **separately-synced** sub-tree mirrored from
`heygen-com/hyperframes` (a different upstream than the marketing skills). The
marketing sync rebuilds `skills/` on each run, so it **backs up and restores**
`hyperframes/` around its own sync — run `sync-hyperframes.sh` to update the
hyperframes side independently. The two sync scripts do not disturb each
other's mirrors.

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
