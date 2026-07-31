# Memory Tiers and Visibility

This plugin manages two coexisting memory layers. Each has its own location, schema, lifecycle, and default visibility. The `visibility` frontmatter field controls whether a fact may cross the private/public boundary.

## Tier A — private harness memory

- **Location:** `~/.claude/projects/<escaped-cwd>/memory/*.md`, where `<escaped-cwd>` is the session's absolute cwd with every `/` replaced by `-` (space handling is inconsistent across Claude Code versions — see `lib/memory-lib.sh` `tier_a_dir` for the dual-candidate probe).
- **Schema (frontmatter):** `name`, `description`, a nested `metadata:` block (containing `node_type`, `type` — `user` | `feedback` | `project` | `reference`, and an `originSessionId`), and optionally `visibility`. `read_frontmatter_field "$file" metadata.type` resolves the nested `type:` line.
- **Body shape:** free-form markdown with `**Why:**` and `**How to apply:**` lines and `[[slug]]` wikilinks. An index file `MEMORY.md` lists one pointer per file (target: under 50 lines).
- **Lifecycle:** private, lives outside any repo, not git-tracked. The Stop hook auto-consolidates it on a 24h per-project debounce.
- **Default visibility:** `private`.

This is the layer Claude Code itself loads as session memory, and the layer `~/.claude/consolidate-memory.sh` (the home dotfiles script this plugin's hook ports) maintains.

## Tier B — repo-local memory

- **Location:** `docs/memory/<category>_<slug>.md` in the consuming project's repo.
- **Schema (frontmatter):** `name`, `category` (`convention` | `pitfall` | `decision` | `preference`), `summary`, `source`, `created`, `updated`.
- **Body shape:** `## Fact`, `## Why`, `## How to apply`, `## Related`.
- **Index:** a row in `docs/README.md`, maintained by `superpowers/lib/docs-index.sh upsert memory <path> --category <cat> --summary "<summary>"` and `rebuild`.
- **Lifecycle:** git-tracked, reviewable, shareable across the team. Consumed by `.claude/skills/reflect-skills-from-memory`.
- **Default visibility:** `public`.

This is the layer shipped in this repo (`docs/memory/`).

## Tier C — public commons (deferred)

A remote agentbook commons (MCP over Streamable HTTP) is designed but not implemented — see `docs/plans/2026-07-06-agentbook-memory-design/architecture.md`. This plugin leaves a clean seam: the `visibility: public` + `source` fields are exactly what a future Tier C bridge would consume. Do not build the `.mcp.json` or remote recall until that design is implemented.

## The `visibility` field

An optional frontmatter field on any memory file, values:

| Value | Meaning | Syncable | Publishable |
|---|---|---|---|
| `public` | the fact may cross the private/public boundary | yes | yes |
| `private` (default Tier A) | stays in its layer | no | no |
| `redacted` | a secret-bearing file (name/body matches the denylist) | never | never |

`lib/classify.sh` `read_visibility` returns `redacted` for any file whose filename or body matches the secret denylist (`password`, `secret`, `token`, `apikey`, `api-key`, `privatekey`, `private-key`, `credential`) — regardless of the explicit field. This guards files like `frad-nas-kicad-password.md` or `substore-openclash-secrets.md` from ever leaking Tier A → Tier B. A bare `key` is intentionally NOT in the list (it would over-match); key-bearing files must be named with a full compound (`api-key`, `private-key`) or carry a `<!-- secret` body marker.

## Escape convention

Claude Code names a project's memory folder by escaping the absolute cwd: `/` → `-`. `reflect-skills-from-memory` Phase 1 uses this exact `sed 's/\//-/g'`. `lib/memory-lib.sh` `escape_path` is the single source of truth — skills and the hook source it rather than re-implementing the sed.

Space handling is inconsistent across Claude Code versions (`Home Lab` → `-Home-Lab` but `Work Research` keeps the space), so `tier_a_dir` probes both forms (`/`→`-`+space→`-`, and `/`→`-`+space-kept) and returns whichever project folder actually exists.
