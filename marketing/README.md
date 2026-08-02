# Marketing Plugin

Marketing skills for AI agents (mirrored from [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) — CRO, copywriting, SEO, paid ads, ad creative, analytics, growth).

**Version**: 0.2.0
**Display Name**: Marketing

## What This Plugin Does

49 marketing sub-skills (routed via the local `marketing` router) — conversion rate optimization, copywriting, SEO (programmatic, AI, audit), paid advertising (Google/Meta/LinkedIn/TikTok ads), ad creative generation, analytics, attribution, email/SMS, churn prevention, pricing, paywalls, onboarding, referrals, public relations, influencer marketing, and more — plus a `tools/` registry of CLI wrappers and integration guides for marketing platforms (GA4, Stripe, Mailchimp, HubSpot, etc.).

## Structure

- **`skills/SKILL.md` (marketing router)** — local router that indexes all 49 mirrored marketing sub-skills; the table is regenerated from sub-skill frontmatter by `scripts/gen-marketing-index.py`.
- **`skills/` (marketing)** — 49 marketing sub-skills, each stored as `<name>/<name>.md` (denested: `SKILL.md` renamed after sync so only the router is auto-discovered). Synced from `coreyhaines31/marketingskills`.
- **`tools/`** — `REGISTRY.md`, `clis/` (zero-dependency Node CLI wrappers), `integrations/` (per-tool API guides), `composio/` (MCP integration layer). Synced with the marketing upstream.
- **Root functional files** — `CLAUDE.md`/`AGENTS.md` (agent guidance), `VERSIONS.md` (per-skill version registry), `validate-skills.sh` / `validate-skills-official.sh` (spec audit scripts). Synced with the marketing upstream.

Excluded (marketing upstream repo metadata, superseded by this marketplace's entries): `README.md`, `CONTRIBUTING.md`, `.github/`, `.gitignore`, `FUNDING.yml`, `LICENSE`.

- `scripts/sync-marketing.sh` — syncs marketing upstream (skills + tools + root files), then denests sub-skills and regenerates the router index.
- `scripts/denest-marketing-skills.py` — renames `<name>/SKILL.md` → `<name>/<name>.md` and rewrites relative links.
- `scripts/gen-marketing-index.py` — regenerates the router `SKILL.md` index table from sub-skill frontmatter.
- `skills/SYNC.md` — marketing sync metadata and strategy.

## Installation

```bash
claude plugin install marketing@frad-dotclaude
```

## Syncing from Upstream

```bash
bash marketing/scripts/sync-marketing.sh --check     # dry-run
bash marketing/scripts/sync-marketing.sh             # sync with backup
```

See `skills/SYNC.md` for upstream source, last-synced commit, and sync strategy. Mirrored content is not edited locally — editing would break sync fidelity (re-sync overwrites local edits). The only local transforms applied after sync are the denest rename (`SKILL.md` → `<name>.md`, so sub-skills are not auto-discovered) and the router index regeneration; both are scripted and re-runnable:

```bash
python3 marketing/scripts/denest-marketing-skills.py --check
python3 marketing/scripts/gen-marketing-index.py --check
```

## Validation Note

Several upstream skill bodies exceed the plugin-optimizer's 5k-token body budget (ads, ai-seo, directory-submissions, marketing-psychology). This plugin sets `strict: false` in marketplace.json so those warnings do not block installation. They are upstream content and not edited here.

## License

MIT (local plugin). Mirrored content sourced from `coreyhaines31/marketingskills` (MIT).
