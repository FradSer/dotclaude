# Docs Index Convention — Design Index

## Context

The superpowers plugin (v3.5.0) has four skills that write into `docs/` — `brainstorming` (`docs/plans/*-design/`), `writing-plans` (`docs/plans/*-plan/`), `executing-plans` (mutates plan folders, flips plan → shipped on Phase 5 commit), and `retrospective` (`docs/retros/` — checklists, evolution-log, retro reports). Today there is no top-level map of what design/plan/retro artifacts exist or which are still authoritative. A skill starting work on a topic has no way to discover that a prior design on the same topic was already invalidated by a retrospective, so it may re-extend stale conclusions.

The user's three hard requirements:

1. The index is **consulted BEFORE** a skill starts work, so it knows what prior docs exist and which are stale.
2. The index **reflects that some historical docs are outdated** — especially after `/superpowers:retrospective` reflections, which may mark prior design/plan docs as expired, inapplicable, or problematic.
3. The index **must not bloat** as docs accumulate.

Current state: `docs/` contains only `docs/writing-skills/` (a stable references subdir with its own README). No top-level `docs/README.md` exists yet. `docs/plans/` and `docs/retros/` are created on demand by the skills.

## Discovery Results

- **`docs/` tree** (this checkout): only `docs/writing-skills/`. Runtime folders (`docs/plans/...`, `docs/retros/...`) are produced on demand.
- **No existing invalidation mechanism**: `grep` for `invalidates|expired|supersed` across `skills/retrospective/references/*.md` returns nothing. The retrospective skill evolves checklists; it does not mark prior design/plan docs as expired. This convention is greenfield on the invalidation axis.
- **Established lib-script conventions** (from `lib/seed-checklists.sh`, `lib/jsonl-emit.sh`, `lib/post-plan-diff.sh`, `lib/task-brief.sh`, `lib/review-package.sh`): header block with `Usage:` and `Exit codes:` sections; `set -euo pipefail` for executed-only leaf scripts; exit codes `0` success / `1` internal failure / `2` usage error / `3` "already-exists or not-found — caller treats as success"; `Bash(${CLAUDE_PLUGIN_ROOT}/lib/<script>.sh:*)` scope string in SKILL.md frontmatter.
- **Plugin precedents reused**: (1) CRITICAL do-not-defer emit pattern (retro Phase 4 evolution-log, Phase 6 closure row); (2) state-based detection over narrated-output detection; (3) `--force` override convention on bail-out checks; (4) self-rejection of proposals contradicting recalled priors; (5) "see `git show docs/retros/checklists/`" deferral pattern for detail-pushing; (6) thresholds to prevent cheap triggers (ADD 2+ plans, REMOVE 3+ reports).
- **`systematic-debugging` writes tests/fixes in code, not `docs/`** — out of scope.
- **Insertion points** exist naturally in each of the 4 in-scope skills (Initialization for consult-before; commit phase for upsert-after) — see `architecture.md` §Touchpoints.

## Glossary

Canonical labels for this design. Rejected variants are recorded so future maintainers see what was considered.

| Concept | Canonical label | Rejected variants | Why canonical |
|---|---|---|---|
| Artifact class field | `kind` | `type` | `type` collides with shell/commit vocabulary; `kind` is unambiguous |
| One-line description field | `summary` | `title`, `notes` | `summary` conveys "reminder, not substitute"; subsumes both |
| Status: in-flight draft | `wip` | `draft` | Matches plugin's existing `wip` usage in handoff/state files |
| Status: shipped | `implemented:<sha>` | flat `implemented` | Parameterized form puts the SHA in-status — fewer columns, greppable, meets success criterion S2 |
| Status: invalidated | `expired:<reason>` | flat `expired` | Parameterized form forces a reason string — auditable |
| Status: replaced by newer | `superseded-by:<path>` | (none proposed) | Parameterized form puts the successor path in-status — navigable |
| Status: evergreen reference | `reference` | (none proposed) | Sticky status for `docs/writing-skills/`-style stable refs |
| Status: current source of truth | `active` | (none proposed) | The "consult me" status |
| Read subcommand | `list` | `consult` | `list` is self-documenting; `consult` is ambiguous (read vs. advise) |
| Read-one subcommand | `show` | (none proposed) | Symmetric with `list`; matches git/docker CLI convention |
| Write subcommand | `upsert` | (none proposed) | Idempotent insert-or-update, matches the semantics exactly |
| Status-flip subcommand | `set-status` | `mark` | `set-status` is unambiguous; `mark` collides with bookmark/test vocabulary |
| Recovery subcommand | `rebuild` | (none proposed) | Re-scans filesystem truth; matches `make rebuild` convention |
| Bulk-invalidate subcommand | (rejected — no such verb) | `expire --before` | Blunt bulk expiry bypasses the explicit-trigger boundary in `best-practices.md` §Retro-Invalidation Signal Boundary |
| Folder path convention | `docs/plans/YYYY-MM-DD-<topic>-design/` | `docs/designs/<topic>` | Matches the actual plugin convention at `brainstorming/SKILL.md:97` |
| Retro-invalidation trigger | `invalidates: <path>` line in retro report | bulk `expire --before`, inference from narrative | Explicit + grep-able + cited; prevents cheap triggers from rewriting durable state |
| Table structure | single table with `kind` column | per-kind `## <Kind>` sections | Single table is denser; `kind` col disambiguates; per-kind sections add header bloat |

## Requirements

### Functional (MUST)

1. **MUST** exist as a single file at `docs/README.md`, maintained exclusively by the four named skills (brainstorming, writing-plans, executing-plans, retrospective). No human-only or hook-driven edits.
2. **MUST** be consulted by each of the four skills **before** producing any new artifact — before brainstorming opens a design folder, before writing-plans emits `_index.md`, before executing-plans spawns batch 1, before retrospective reads inputs. "Consulted" means the skill's body contains a step that runs `lib/docs-index.sh list`/`show` and uses its status fields to inform its own output.
3. **MUST** be updated **after** a skill commits its artifact, in the same turn, in the same commit-group as the artifact (CRITICAL, do-not-defer — mirrors the retro's own warning that a dropped evolution-log row silently corrupts the next run).
4. **MUST** record, per design/plan/retro artifact, at minimum: `path` (primary key), `kind`, `status` (from the taxonomy in `architecture.md` §Status Taxonomy), and a one-line `summary`.
5. **MUST** reflect staleness: at least one status value (`expired:<reason>`) means "this doc is historically present but should not be relied on as current" — covers hard requirement #2.
6. **MUST** allow retrospective to mark a prior entry as `expired:<reason>` without rewriting that prior doc's file — the index entry mutates, not the historical artifact (the skills already preserve original checklist versions unchanged by convention; same principle here).
7. **MUST** survive the absence of `git`/`jq` — the index is a skill-written markdown file, not a hook-written `.jsonl`. It must not hard-depend on `plans-completed.jsonl` or the Stop hook.
8. **MUST** enforce the controlled status vocabulary: `upsert`/`set-status` with an unknown status value exits `2` and writes nothing.

### Functional (SHOULD)

9. **SHOULD** keep each entry to a single physical line (matches the README.md tone: dense, table-driven, no prose padding).
10. **SHOULD** make the index diff-friendly: one entry per line, sorted by path, so `git diff docs/README.md` reads as an append or a single-line status flip — never a reflow.
11. **SHOULD** link each entry's path as a relative markdown link so a reader can click through.

### Non-functional

12. **MUST NOT** grow unbounded with doc count — hard ceiling of 60 index lines, with a collapse rule (see `best-practices.md` §Anti-Bloat Rules).
13. **MUST** be machine-parseable with `grep`/`awk` only (no `jq` required to read it — it's markdown, not JSON).
14. **SHOULD** be readable in under 30 seconds by a human skimming it.

## Rationale

**Shared `lib/docs-index.sh` (not per-skill inline logic).** Five touchpoints across four skills would otherwise duplicate index-read/write logic, drifting within weeks. A single leaf script — matching the established `lib/*.sh` pattern (`seed-checklists.sh`, `task-brief.sh`, `review-package.sh`) — is the proven shape for shared state in this plugin.

**Controlled-vocabulary status (not free text).** Six parameterized statuses (`wip`, `active`, `implemented:<sha>`, `superseded-by:<path>`, `expired:<reason>`, `reference`) put the SHA / successor path / reason *in the status field* — fewer columns, greppable, and the reason is mandatory (auditable). Free-text statuses would drift and lose queryability; a flat `implemented` would lose the SHA that makes an entry auditable via `git show`.

**Folder-level entries (not per-file).** A design folder is 4+ files; a plan folder adds task files and eval rounds. Per-file entries would 5–10× the line count for zero navigational value — the folder path is the click target, and the folder's own `_index.md` is the per-file table of contents. One index line = one folder.

**Explicit `invalidates: <path>` trigger (not inference or bulk expiry).** Expiry rewrites how *other* skills treat a doc on every future consult — a stronger mutation than a checklist REMOVE. Its trigger must be (a) explicit (a grep-able line in the retro report, not LLM inference from narrative), (b) authored by retrospective only (the skill that holds cross-plan evidence), and (c) cited with the retro report path. This mirrors the plugin's threshold philosophy (ADD 2+ plans, REMOVE 3+ reports) applied to the strongest mutation in the system.

**Index update before the commit, not after.** Atomicity: the index flip and the implementation changes land in the same commit, so a revert reverts both. This mirrors how `seed-checklists.sh` writes the checklist before the Phase 3/5 commit and how the evolution-log emit happens before the retro's Phase 6 close.

## Detailed Design

See the companion files:

- `architecture.md` — `lib/docs-index.sh` subcommand interface, exit codes, `docs/README.md` table format, per-skill touchpoints (consult-before + upsert-after), commit-ordering integration with executing-plans Phase 5.
- `bdd-specs.md` — Full Gherkin scenarios (cold start, consult-before with active/expired priors, executing-plans flip to `implemented:<sha>`, retrospective invalidation, compactness, reference-stickiness, idempotent upsert, controlled-vocab enforcement, malformed-index degradation, same-day folder-name collision, status-transition matrix).
- `best-practices.md` — Anti-bloat rules (granularity, summary width, 60-line ceiling + collapse rule, infrastructure-file exclusion, checklist-version collapse), status-transition rules with edge cases (resurrection, rework-after-ship, reference mutability, `superseded-by` vs `expired`), retro-invalidation signal boundary, security/performance/common-pitfalls.

## Design Documents

- [`architecture.md`](./architecture.md) — System architecture, subcommand interface, touchpoints
- [`bdd-specs.md`](./bdd-specs.md) — Gherkin behavior specifications
- [`best-practices.md`](./best-practices.md) — Anti-bloat, status transitions, invalidation boundary, pitfalls
