# Marketing Plugin

Marketing skills for AI agents (mirrored from [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) — CRO, copywriting, SEO, paid ads, ad creative, analytics, growth) plus HyperFrames HTML-based video authoring skills (mirrored from [heygen-com/hyperframes](https://github.com/heygen-com/hyperframes)).

**Version**: 0.1.0
**Display Name**: Marketing

## What This Plugin Does

Two mirrored skill sets, each from its own upstream, co-existing in one plugin:

1. **47 marketing skills** — conversion rate optimization, copywriting, SEO (programmatic, AI, audit), paid advertising (Google/Meta/LinkedIn/TikTok ads), ad creative generation, analytics, email/SMS, churn prevention, pricing, paywalls, onboarding, referrals, public relations, and more — plus a `tools/` registry of CLI wrappers and integration guides for marketing platforms (GA4, Stripe, Mailchimp, HubSpot, etc.).
2. **20 HyperFrames skills** — HTML-based video authoring and rendering (compositions, animation, keyframes, creative direction, media, CLI dev loop, plus video workflows: motion-graphics, slideshow, product-launch, pr-to-video, etc.).

## Structure

This plugin **mirrors two upstreams** into one `skills/` tree:

- **`skills/` (marketing, flat)** — 47 marketing skills, auto-discovered (upstream itself uses `"skills": "./skills"`, no router skill). Synced from `coreyhaines31/marketingskills`.
- **`skills/hyperframes/` (nested)** — HyperFrames sub-tree with a local router `SKILL.md` + 20 mirrored sub-skills + binary assets (fonts/SVG). Synced from `heygen-com/hyperframes`.
- **`tools/`** — `REGISTRY.md`, `clis/` (zero-dependency Node CLI wrappers), `integrations/` (per-tool API guides), `composio/` (MCP integration layer). Synced with the marketing upstream.
- **Root functional files** — `CLAUDE.md`/`AGENTS.md` (agent guidance), `VERSIONS.md` (per-skill version registry), `validate-skills.sh` / `validate-skills-official.sh` (spec audit scripts). Synced with the marketing upstream.

Excluded (marketing upstream repo metadata, superseded by this marketplace's entries): `README.md`, `CONTRIBUTING.md`, `.github/`, `.gitignore`, `FUNDING.yml`, `LICENSE`.

The two sync scripts do not disturb each other: `sync-marketing.sh` rebuilds `skills/` but backs up and restores the `hyperframes/` sub-tree around its own sync.

- `scripts/sync-marketing.sh` — syncs marketing upstream (skills + tools + root files).
- `scripts/sync-hyperframes.sh` — syncs the hyperframes sub-tree.
- `skills/SYNC.md` — marketing sync metadata and strategy.
- `skills/hyperframes/SYNC.md` — hyperframes sync metadata and strategy.

## Installation

```bash
claude plugin install marketing@frad-dotclaude
```

## Syncing from Upstream

```bash
# Marketing upstream (skills + tools + root files)
bash marketing/scripts/sync-marketing.sh --check     # dry-run
bash marketing/scripts/sync-marketing.sh             # sync with backup

# HyperFrames upstream (skills/hyperframes/ sub-tree)
bash marketing/scripts/sync-hyperframes.sh --check   # dry-run
bash marketing/scripts/sync-hyperframes.sh            # sync with backup
```

See the two `SYNC.md` files for upstream sources, last-synced commits, and sync strategy. Mirrored content is not edited locally — editing would break sync fidelity (re-sync overwrites local edits).

## Validation Note

Several upstream skill bodies exceed the plugin-optimizer's 5k-token body budget (ads, ai-seo, directory-submissions, marketing-psychology). This plugin sets `strict: false` in marketplace.json so those warnings do not block installation. They are upstream content and not edited here.

## License

MIT (local plugin). Mirrored content sourced from `coreyhaines31/marketingskills` (MIT) and `heygen-com/hyperframes` (Apache-2.0).
