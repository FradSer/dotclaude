# Architecture — Docs Index Convention

## System Overview

A single shared leaf script `lib/docs-index.sh` maintains a single markdown file `docs/README.md` as a pipe-delimited table. Four skills interact with it at two standardized touchpoints each (consult-before, upsert-after); retrospective adds a third (invalidate-after). No hooks, no JSON, no per-skill duplication.

```
┌─────────────────────────────────────────────────────────────┐
│                    docs/README.md (single table)            │
│  path | kind | status | summary | updated                  │
│       ▲           ▲                ▲                         │
│       │           │                │                         │
│  ┌────┴───────────┴────────────────┴────┐                   │
│  │      lib/docs-index.sh (leaf script) │                   │
│  │  list | show | upsert | set-status   │                   │
│  │  rebuild                              │                   │
│  └──▲────────────────▲──────────────▲───┘                   │
│     │                │              │                         │
│  consult-before   upsert-after   invalidate-after            │
│     │                │              │                         │
│  ┌───┴───┐       ┌────┴────┐    ┌────┴─────┐                 │
│  │ 4 sks │       │ 4 skills │    │retrospec.│                │
│  └───────┘       └──────────┘    └──────────┘                │
└─────────────────────────────────────────────────────────────┘
```

## Components

### 1. `lib/docs-index.sh`

Executed-only leaf script, `set -euo pipefail`, mirrors `lib/seed-checklists.sh` and `lib/task-brief.sh`. Sources `lib/utils.sh` for `repo_root`. Writes via temp-file-then-atomic-`mv` (POSIX rename) to defend against concurrent sub-agent/main-agent writes — the existing `lib/*.sh` scripts don't lock because they write append-only `.jsonl`; `docs/README.md` is a single shared mutable file, so atomic rename is the right call.

#### Subcommand interface

```
Usage:
  docs-index.sh <subcommand> [args...]

Subcommands:
  list [--kind design|plan|retro] [--status <status-prefix>]
        Print all index rows as pipe-delimited lines to stdout.
        Filters are optional. Empty result prints nothing, exits 0.
        <status-prefix> matches the status value's prefix (e.g.
        "implemented" matches "implemented:abc1234"; "expired" matches
        "expired:retro-2026-07-04:reason").

  show <path>
        Print the single pipe-delimited row for <path> (repo-relative).
        Exit 3 if the path is not in the index (caller treats as
        "not tracked yet, proceed" — upserts first).

  upsert <kind> <path> [--status <status>] [--summary <summary>]
        Insert a new row, or update the existing row for <path> in place
        (idempotent — never duplicates). Default status for a new row:
        "wip" for design/plan, "active" for retro. Creates docs/README.md
        (seed header + table) if absent. Validates <kind> and <status>
        against the controlled vocabularies; exit 2 on unknown value.

  set-status <path> <new-status>
        Flip an existing row's status. Validates <new-status> against the
        controlled vocabulary AND the transition matrix (see
        best-practices.md §Status Transitions). Exit 3 if <path> not in
        the index (caller upserts first, then re-tries). Exit 2 on a
        rejected transition or unknown status.

  rebuild
        Re-scan docs/plans/*-design/, docs/plans/*-plan/, docs/retros/retro-*.md
        and regenerate the index from filesystem truth. Recovery path when
        the index is stale or hand-edited. Preserves existing status values
        for paths still present; drops rows whose paths no longer exist.
        Prints row count to stderr. Exits 0.
```

#### Controlled vocabularies (enforced by the script)

- `kind` enum: `design | plan | retro`
- `status` enum (parameterized values allowed where shown):
  - `wip`
  - `active`
  - `implemented:<short-sha>` (7-char hex)
  - `superseded-by:<repo-relative-path>`
  - `expired:<reason>` (reason MUST cite a retro report path)
  - `reference`

Any other value → exit 2, diagnostic to stderr naming the allowed vocabulary, no write.

#### Exit codes (mirrors `seed-checklists.sh:20-24`)

```
0 — row written / row found / bulk op succeeded
1 — internal failure (disk error, README.md not writable, utils.sh::repo_root empty)
2 — usage error (missing args, unknown subcommand, unknown --kind/--status value,
    rejected status transition, malformed index table on consult)
3 — "not in index" (show / set-status on an absent path) — callers treat as
    "not tracked yet, proceed" and upsert first. Symmetric to seed-checklists.sh
    where 3 = already-exists-is-success.
```

Caller prose (in each SKILL.md): *"Exit code handling: 0 = written/found, 3 = not in index (upsert first then proceed), 1/2 = real failure (abort or surface the error — do not improvise)."*

### 2. `docs/README.md` table format

Single pipe-delimited table, one data row per folder, sorted by `path` lexicographic (so newest-date-first plans naturally sort to top, matching the `ls -1d ... | sort | tail -1` resolution rule at `writing-plans/SKILL.md:61` and `executing-plans/SKILL.md:45`).

**Columns** (left-to-right, 5 columns — compact):

| Column | Max width | Notes |
|---|---|---|
| `path` | 60 chars | Repo-relative folder path, as a markdown link |
| `kind` | 6 chars | `design` / `plan` / `retro` |
| `status` | 40 chars | From the controlled vocabulary (parameterized values can be long) |
| `summary` | 72 chars | One-line reminder, truncated with `…` |
| `updated` | 10 chars | ISO date `YYYY-MM-DD` |

**Header preamble** (above the table): one-line purpose + "Last rebuild: <date>" so a human opening the file sees the index's nature immediately. The script seeds this on `upsert`/`rebuild` when the file is absent.

Example:
```
# Docs Index

Map of design/plan/retro artifacts under docs/. Maintained by the superpowers
skills — do not hand-edit. Last rebuild: 2026-07-04.

| path | kind | status | summary | updated |
|---|---|---|---|---|
| docs/plans/2026-07-01-auth-design/ | design | superseded-by:docs/plans/2026-07-04-auth-design/ | BDD spec for session refresh; superseded by token-rotation redesign | 2026-07-04 |
| docs/plans/2026-07-04-auth-design/ | design | active | Token rotation + refresh-sliding; BDD spec ready for planning | 2026-07-04 |
| docs/plans/2026-07-04-auth-plan/ | plan | implemented:a1b2c3d | 7 tasks, 2 batches, evaluator PASS all rounds | 2026-07-04 |
| docs/plans/2026-06-12-legacy-cache-design/ | design | expired:retro-2026-06-12-stale.md | Per retro-2026-06-12, approach invalidated by cache-stampede incident | 2026-06-12 |
| docs/writing-skills/ | retro | reference | Evergreen skill-authoring references (Anthropic best practices, persuasion, testing) | 2026-07-03 |
```

(`docs/writing-skills/` is seeded with `kind=retro status=reference` on first `rebuild` — it's the one non-design/plan/retro-folder entry, treated as a stable reference. See `best-practices.md` §Reference Entries.)

## Per-Skill Touchpoints

Each in-scope skill gains two standard touchpoints (consult-before, upsert-after); retrospective gains a third (invalidate-after). Each skill's `allowed-tools` frontmatter gains `"Bash(${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh:*)"`.

### brainstorming (`skills/brainstorming/SKILL.md`)

| Touchpoint | Insertion point | Action |
|---|---|---|
| consult-before | Initialization, step 2 ("Read project context") — extend to "Read project context AND consult the docs index" | Run `docs-index.sh list --kind design --status active` and `list --status expired` to discover prior active/expired designs on the topic. Treat `expired:` conclusions as non-authoritative. |
| upsert-after | Phase 3: Wrap-up, new step 0 (before step 1's `git add`) | Run `docs-index.sh upsert design <new-design-path> --status wip --summary "<one-line>"`. If a prior active design on the same topic exists and is being replaced, run `set-status <prior-path> "superseded-by:<new-path>"` first. The existing chained `git add && git-agent commit` then stages `docs/README.md` atomically with the design folder. |

### writing-plans (`skills/writing-plans/SKILL.md`)

| Touchpoint | Insertion point | Action |
|---|---|---|
| consult-before | Initialization, step 1 ("Design Check") — after verifying `_index.md`/`bdd-specs.md` exist | Run `docs-index.sh show <design-path>`. Refuse if status is `expired:` (the design's conclusions are invalidated — mirror the JUST-01 refusal pattern at `SKILL.md:40-52`). |
| upsert-after | Phase 5: Git Commit, new step 0 (before step 1's `git add`) | Run `docs-index.sh upsert plan <new-plan-path> --status wip --summary "<one-line>"`. The existing chained commit captures `docs/README.md` alongside the plan folder. |

### executing-plans (`skills/executing-plans/SKILL.md`)

| Touchpoint | Insertion point | Action |
|---|---|---|
| consult-before | Initialization, step 1 ("Plan Check") — after verifying `_index.md` has an "Execution Plan" section | Run `docs-index.sh show <plan-path>`. Refuse if status is `expired:`. If status is `implemented:<old-sha>` (rework after ship), flip to `wip` before spawning batch 1 (see `best-practices.md` §Rework After Ship). |
| upsert-after (flip → implemented) | Phase 5: Git Commit, new step 0 (before step 1's `git-agent commit`) | Run `docs-index.sh set-status <plan-path> "implemented:<short-sha>"` where `<short-sha>` is `$(git rev-parse --short HEAD)` of the about-to-be-created commit. **Ordering**: run `set-status` BEFORE the commit so the index flip and the implementation changes land in the same commit (atomicity — a revert reverts both). The SHA is captured pre-commit via a staged-tree hash or the message-construction step; if the SHA is only known post-commit, run `set-status` immediately after the commit in the same turn and amend — see §Commit-Ordering below. |

### retrospective (`skills/retrospective/SKILL.md`)

| Touchpoint | Insertion point | Action |
|---|---|---|
| consult-before | Phase 1: Data Collection, step 1 ("Resolve inputs") | Run `docs-index.sh list --kind plan --status implemented` to scope plans for analysis (complements the existing `plans-completed.jsonl` read). Also `list --status expired` to surface prior expirations as calibration input. |
| upsert-after | Phase 6: Output, new step 6 (after step 5's summary) | Run `docs-index.sh upsert retro <retro-report-path> --status active --summary "<one-line>"`. |
| invalidate-after | Phase 6: Output, new step 7 (after the upsert) | For each `invalidates: <path>` line in the retro report, run `docs-index.sh set-status <path> "expired:retro-<date>:<reason>"`. See `best-practices.md` §Retro-Invalidation Signal Boundary. |

## Commit-Ordering Integration (executing-plans Phase 5)

**Recommendation: the `set-status` call happens in the same turn as, and stages into, the Phase 5 commit.**

Two viable orderings:

**Option A (preferred): pre-commit `set-status`, post-commit SHA backfill.**
1. Run `set-status <plan-path> "implemented:pending"` — but `pending` is not in the controlled vocabulary. So instead:
2. Stage all implementation changes + the design/plan folders.
3. Create the commit via `git-agent commit` (this assigns the SHA).
4. Immediately (same turn) run `set-status <plan-path> "implemented:<short-sha>"` with `$(git rev-parse --short HEAD)`.
5. `git-agent commit --amend` (or a follow-up `--intent "update docs index"` commit) to capture the README.md flip.

**Option B (simpler): post-commit `set-status` + dedicated index commit.**
1. Create the implementation commit via `git-agent commit`.
2. Run `set-status <plan-path> "implemented:<short-sha>"`.
3. `git-agent commit --no-stage --intent "mark <plan> implemented in docs index"` — a small follow-up commit.

**Decision: Option B.** Rationale: (1) avoids `--amend` (which rewrites history and confuses the Stop hook's `completion_commit` detection); (2) the SHA is genuinely unknowable pre-commit, so Option A's "pending" placeholder violates the controlled-vocabulary MUST; (3) a dedicated tiny index commit is greppable and honest — `git log --oneline docs/README.md` reads as a clear audit trail. This matches the plugin's existing "skill writes the row, hook enriches it" split (the Stop hook backfills `plans-completed.jsonl` post-commit; here the skill backfills the index post-commit).

The brainstorming and writing-plans upsert-after touchpoints do NOT have this chicken-and-egg problem — they upsert with `status=wip` *before* the commit, and the `wip`→`active`/`implemented` flip happens later (brainstorming: the design is `active` once the evaluator PASSes, flipped in the same Phase 3 commit; writing-plans: `wip` until executing-plans flips it). Actually — reconsider: brainstorming's design is complete and PASSed at Phase 3, so it should upsert directly as `active` (not `wip`). writing-plans' plan is complete at Phase 5, so it should upsert directly as `active` (waiting for executing-plans to flip to `implemented`). The `wip` status is reserved for a design/plan that is committed mid-pipeline (rare; e.g., a brainstorming run that hit `/goal` time-budget and committed a partial design). Default upsert status for a completed artifact is `active`.

**Refined upsert-after defaults:**
- brainstorming Phase 3: `upsert design <path> --status active` (design is complete, evaluator PASSed)
- writing-plans Phase 5: `upsert plan <path> --status active` (plan is complete, ready for execution)
- executing-plans Phase 5: `set-status <plan-path> "implemented:<sha>"` (plan shipped)
- retrospective Phase 6: `upsert retro <path> --status active` (retro report complete)

## Data Structures

### Index row (in-memory representation)

```
path:    string (repo-relative, primary key, e.g. "docs/plans/2026-07-04-auth-design/")
kind:    enum {design, plan, retro}
status:  string from controlled vocabulary (parameterized values carry :<arg>)
summary: string, <= 72 chars
updated: ISO date string YYYY-MM-DD
```

### Retro-invalidation line (in retro report)

```
invalidates: <repo-relative-path-of-prior-doc>
```

One line per invalidated doc; multiple lines allowed for batch invalidation. The retrospective skill's Phase 6 step 7 greps these lines from its own just-written report and calls `set-status` for each. The path MUST already exist in the index (no speculative expiry) — if absent, the skill logs a warning and skips.

## Integration Points

- **`lib/utils.sh`** — `repo_root` resolution (same as `jsonl-emit.sh:38`, `review-package.sh:39`).
- **`hooks/stop-state-sync.sh`** — unchanged. The index is skill-written, not hook-written. The Stop hook continues to backfill `docs/retros/plans-completed.jsonl` independently. The two channels are complementary: the `.jsonl` is the machine audit trail; `docs/README.md` is the human-skimmable map.
- **`lib/jsonl-emit.sh`** — optional future enhancement (out of scope v1): have `upsert`/`set-status` also append a row to `docs/retros/docs-index.jsonl` via the existing channel pattern, so the index has an append-only audit trail. Not required for v1.
- **plugin-optimizer `validate-plugin.py`** — unaffected. `docs/README.md` is not a skill file; no frontmatter to validate.
- **`docs/writing-skills/`** — seeded as `kind=retro status=reference` on first `rebuild`/`upsert`. Its own `docs/writing-skills/README.md` remains the per-file reference; the top-level index just points at the folder.
