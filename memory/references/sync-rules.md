# Sync Rules — bidirectional Tier A <-> Tier B

`/memory:sync` and `/memory:publish` translate facts between the private harness memory (Tier A) and the repo-local memory (Tier B). Both schemas are stable; the translation is mechanical except for the conflict cases below.

## Frontmatter translation

| Tier A field | Tier B field | Notes |
|---|---|---|
| `name` | `name` | carries over verbatim |
| `description` | `summary` | one-line, carries over |
| `metadata.type` | `category` | see type→category map below |
| — | `source` | set to the Tier A file's origin project (escaped cwd basename) |
| — | `created` | today on first sync; preserved on update |
| — | `updated` | today on every sync |
| `visibility` | `visibility` | carries over (defaults: Tier A `private`, Tier B `public`) |

### type → category map (Tier A → Tier B)

| `metadata.type` | `category` |
|---|---|
| `feedback` | `pitfall` |
| `project` | `decision` |
| `reference` | `preference` |
| `user` | `preference` |

Reverse (Tier B → Tier A) is the inverse, with `preference` → `reference` (Tier A has no `preference` type — `reference` is the catch-all for durable, non-feedback, non-project facts).

## Body translation

Tier A body (`**Why:**` / `**How to apply:**` / `[[links]]`) ↔ Tier B body (`## Why` / `## How to apply` / `## Related`). The `## Fact` heading on the Tier B side is the one-sentence claim, derived from the Tier A `description` if no leading claim is present.

## Conflict resolution (a fact exists on both sides)

1. **Redacted blocks sync.** If `read_visibility` returns `redacted` on either side, the fact is not synced in either direction. No other rule applies.
2. **Latest date wins.** The side with the later date is the source of truth; its content is copied to the loser. Tier B's date is its `updated` field (`YYYY-MM-DD`); Tier A's date is `metadata.modified` (ISO-8601) — Tier A has no flat `updated` field. Use `read_frontmatter_field "$file" metadata.modified` for Tier A, `read_frontmatter_field "$file" updated` for Tier B. If Tier A has neither, treat it as older than any dated Tier B file.
3. **Tie → Tier B wins.** On an equal date, Tier B (git-tracked, reviewed) wins over Tier A (private, unreviewed).
4. **Private blocks outbound.** A Tier A fact with `visibility: private` (or unset) is never pushed to Tier B, even if a Tier B copy exists and is older. The user must `/memory:publish` it first.

## `source` field semantics

On Tier B, `source` records where the fact came from. For a fact promoted from Tier A, it is the Tier A file's origin project (the escaped cwd basename). For an originally-authored Tier B fact, it is the repo-relative path, commit sha, or omitted — matching the existing convention in `docs/memory/convention_req-trace-explicit-citation.md`.

## Redaction guards

`lib/classify.sh` `is_secret_filename` matches (case-insensitive) against: `password`, `secret`, `token`, `apikey`, `api-key`, `privatekey`, `private-key`, `credential`. `is_secret_body` matches an explicit `REDACTED` / `SECRET:` / `<!-- secret` marker line. Either match forces `read_visibility` to return `redacted`, which `is_syncable` rejects. This is the hard floor — no `visibility: public` field overrides a secret-bearing file.
