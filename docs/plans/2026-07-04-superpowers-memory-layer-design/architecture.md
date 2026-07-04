# Architecture — Superpowers Memory Layer (`kind=memory`)

## System Overview

The existing docs-index convention (`kind ∈ {design, plan, retro}`, one leaf script, four touchpoints) extends with a fourth `kind`: `memory`. Structurally this is a small extension — one new enum value threaded through a handful of existing case-statements — because most of the script was already kind-agnostic (`validate_status`, `transition_allowed`, `collapse_rows` all operate on **status strings**, never on `kind`). The genuinely new surface is:

1. A new file format, `docs/memory/<category>_<slug>.md` — one distilled fact per file, modeled directly on this assistant's own private `MEMORY.md` convention (`feedback_*.md`, `project_*.md`, `preference_*.md`-style topic files + one-line index pointers).
2. One small, genuinely new kind-aware restriction: `kind=memory` rows accept only `active | expired:<reason>` as status — everywhere else in the script, status validation stays kind-agnostic by design; memory is the one kind whose status is a strict subset, and that subset is enforced, not merely documented (see Rationale below and Glossary in `_index.md`).
3. A new `scan_folders()` loop so `rebuild` discovers memory files.
4. Five read touchpoints and five *conditional* write touchpoints, one pair per skill, each reusing that skill's own pre-existing quality-escalation threshold as the write-gate — no new thresholds invented.
5. `systematic-debugging` joins as a fifth participant — read + conditional-write only. It never gets a `docs/README.md` row of its own kind, because it produces no `docs/plans/` folder to index; its only interaction with the index is via `kind=memory`.

## Component Diagram

```
┌───────────────────────────────────────────────────────────────────────┐
│                    docs/README.md (single table)                     │
│  path | kind | status | summary | updated                             │
│  kind ∈ { design, plan, retro, memory }                                │
│  memory rows: status ∈ { active, expired:<reason> } ONLY (enforced)   │
│       ▲           ▲                ▲                                  │
│       │           │                │                                  │
│  ┌────┴───────────┴────────────────┴────┐                             │
│  │      lib/docs-index.sh (leaf script) │                             │
│  │  list | show | upsert | set-status   │                             │
│  │  rebuild (scan_folders now also      │                             │
│  │   globs docs/memory/*.md, a plain    │                             │
│  │   non-recursive glob that naturally  │                             │
│  │   skips docs/memory/archive/)        │                             │
│  └──▲────────────────▲──────────────▲───┘                             │
│     │                │              │                                 │
│  consult-before   upsert-after   invalidate-after                     │
│  + memory-read    + memory-write  (unchanged, retro-only)              │
│  (all 5 skills)   (conditional, gated by                               │
│                    each skill's OWN existing                          │
│                    threshold — 5 skills)                               │
│  ┌───────────┐   ┌───────────┐            ┌──────────┐                │
│  │ brainstm. │   │ brainstm. │            │retrospec.│                │
│  │ writ-plan │   │ writ-plan │            │(also the │                │
│  │ exec-plan │   │ exec-plan │            │ primary  │                │
│  │ retrospec │   │ retrospec │            │ writer,  │                │
│  │ sys-debug │   │ sys-debug │            │ ADD/MODIFY│               │
│  │ (read-only│   │ (write    │            │ only)    │                │
│  │  on d/p/r,│   │  gated by │            └──────────┘                │
│  │  read+write│  │  own      │                                        │
│  │  on memory)│  │  threshold)│                                       │
│  └───────────┘   └───────────┘                                        │
└───────────────────────────────────────────────────────────────────────┘
                    │
                    ▼  one fact per file (Fact / Why / How-to-Apply)
        ┌─────────────────────────────────────┐
        │ docs/memory/<category>_<slug>.md     │
        │ category: convention | pitfall |     │
        │   decision | preference               │
        │ (category NEVER surfaces in the row) │
        └─────────────────────────────────────┘
                    │
                    ▼  on expiry + index collapse (2nd-line defense)
        ┌─────────────────────────────────────┐
        │ docs/memory/archive/<category>_<slug>.md │
        │ (row dropped, file kept — recoverable) │
        └─────────────────────────────────────┘
```

`systematic-debugging` is the one participant with an asymmetric touchpoint set: it never consults `--kind design/plan/retro` (it isn't a design/plan/retro writer), but it reads `--kind memory` like the other four, and writes `--kind memory` conditionally like the other four.

## 1. File Format — `docs/memory/<category>_<slug>.md`

### Category enum

```
category ∈ { convention | pitfall | decision | preference }
```

- **`convention`** — a structural/naming/format rule the project follows going forward (e.g., "one index line per folder, not per file").
- **`pitfall`** — a recurring failure mode or gotcha, usually debugging-shaped (e.g., "`repo_root()` silently targets the parent repo when `CLAUDE_PROJECT_DIR` is unset").
- **`decision`** — a chosen-or-rejected architectural call with rationale (e.g., "Option B: a dedicated index commit, not `--amend`, because amend confuses the Stop hook").
- **`preference`** — an explicit workflow/style preference not tied to a specific defect (e.g., "auto-produce, never pause for approval").

`reference` is deliberately **not** a category value: `status=reference` already exists at the row level for evergreen docs (`docs/writing-skills/`); reusing the word as a per-file category would create a second, colliding "reference" vocabulary in the same feature. A memory fact that becomes a stable, no-longer-mutating distillation is expressed by leaving its row at `active` indefinitely, not by a `category: reference`.

### Filename convention

`docs/memory/<category>_<slug>.md` — underscore-joined category prefix, mirroring the assistant's own memory file naming exactly (`feedback_verification.md`, `project_superpowers_hooks.md`). No date prefix (unlike `docs/plans/YYYY-MM-DD-*`) — memory facts aren't chronologically scoped artifacts; they're evergreen until superseded/consolidated/expired. The prefix also makes `ls docs/memory/pitfall_*` a grep-free category filter.

### Frontmatter shape

```yaml
---
name: repo-root-fallback-wrong-project      # matches the filename stem minus category prefix; redundant-by-design, catches copy-paste drift the same way SKILL.md's own name: field does
category: pitfall                            # convention | pitfall | decision | preference — never `type`, never `kind` (reserved by the index row schema)
summary: repo_root() silently targets parent repo when CLAUDE_PROJECT_DIR unset   # <=72 chars, same truncation discipline as the index summary column; this string is what --summary copies FROM at upsert time
source: docs/retros/retro-2026-07-04-docs-index-plan.md   # repo-relative path, OR commit:<7-char-sha> (systematic-debugging: no docs/ folder to cite), OR omitted (rare)
created: 2026-07-04
updated: 2026-07-04
---
```

Six scalar fields, no arrays, no nesting — matches the flat-frontmatter discipline of this plugin's own `SKILL.md` files. **Deliberately excluded: a `status` field.** Status (`active`/`expired:<reason>`) lives only on the `docs/README.md` row, never duplicated inside the file — the same single-source-of-truth discipline the shipped design already applies to design/plan/retro (their own `_index.md`/report files never carry a duplicate status field). Duplicating it here would reproduce exactly the kind of dual-source drift the plugin's own retro reports have already caught once (stale status after first `rebuild`, per `docs/retros/retro-2026-07-04-docs-index-plan.md` signal #4).

`source`'s three-shape union (`<path>` / `commit:<sha>` / omitted) deliberately echoes the existing status vocabulary's parameterized-value pattern (`implemented:<sha>`, `superseded-by:<path>`) — same syntax, same reader mental model.

### Body shape

```markdown
# <Human-readable title, matches name>

## Fact
<1-3 sentences: the distilled, reusable fact/convention/pitfall/decision itself>

## Why
<rationale / evidence — what run(s) surfaced this, what would go wrong without it>

## How to Apply
<concrete action: which skill(s), at which phase, should change behavior because of this fact>

## Related
- [[other-category_other-slug]] — <relationship, one line>
```

`[[wiki-link]]` cross-references live in the body (0-N, human-navigable, never machine-parsed) — kept separate from the single machine-relevant `source:` provenance field in frontmatter, so the frontmatter stays flat and greppable while the body carries the reasoning. This mirrors the plugin's existing "skill writes the row, hook enriches it" separation: frontmatter is the queryable spine, body is the narrative.

**Example** (the `repo_root` fallback pitfall surfaced in `retro-2026-07-04-docs-index-plan.md`):

```markdown
---
name: repo-root-fallback-wrong-project
category: pitfall
summary: repo_root() silently targets parent repo when CLAUDE_PROJECT_DIR unset
source: docs/retros/retro-2026-07-04-docs-index-plan.md
created: 2026-07-04
updated: 2026-07-04
---

# repo_root() targets the wrong project during plugin self-development

## Fact
When developing the superpowers plugin itself (running lib/*.sh by hand from
within superpowers/), CLAUDE_PROJECT_DIR is typically unset, so repo_root
falls back to `git rev-parse --show-toplevel`, which resolves to the parent
dotclaude/ repo — not superpowers/. Any docs-index.sh call in that context
silently writes to dotclaude/docs/README.md instead of superpowers/docs/README.md.

## Why
This caused a real incident: post-implementation set-status/upsert calls
returned exit 3 ("not in index") on paths that were clearly indexed, and a
retro upsert appeared to "lose" 3 existing rows — they were never read
because the wrong file was opened. The fallback itself is correct behavior,
just surprising for a nested-repo layout.

## How to Apply
When running any lib/*.sh script by hand from inside superpowers/ (not via
a skill invocation, which pre-sets CLAUDE_PROJECT_DIR), export
CLAUDE_PROJECT_DIR="$(pwd)" first. Skills invoked normally are unaffected.

## Related
- Source design: docs/plans/2026-07-04-docs-index-design/architecture.md (Root resolution comment block)
```

## 2. `lib/docs-index.sh` Diff-Level Changes

| Function | Change | New vs. reused |
|---|---|---|
| `validate_kind()` | `design\|plan\|retro)` → `design\|plan\|retro\|memory)`; error string appends `\|memory` | 1-line edit |
| `cmd_list()` inline `--kind` check | Same case-arm addition | 1-line edit |
| `default_status_for_kind()` | `retro)` → `retro\|memory)` (both default to `active`) | 1-line edit |
| `seed_header()` | Preamble text: "One row per design/plan/retro folder" → "...folder, or memory fact file" | 1-line text edit |
| `usage()` + top-of-file comment | `<design\|plan\|retro>` → `<design\|plan\|retro\|memory>` in both doc strings | cosmetic, 2 lines |
| **`validate_status_for_kind(kind, status)`** | **New function.** For `kind=memory`, accept only a bare `active` or a parameterized `expired:<reason>`; reject `wip`, `implemented:<sha>`, `superseded-by:<path>`, `reference` with exit 2 and a diagnostic naming the memory-specific subset. For every other kind, delegate unchanged to the existing `validate_status()` (no behavior change for design/plan/retro). | **genuinely new**, small, isolated — called from `cmd_upsert()` and `cmd_set_status()` immediately after the existing `validate_status()` call |
| `validate_status()` | No change — still validates the full 6-value vocabulary in isolation; the new per-kind narrowing happens in the new wrapper above it, not inside it | fully reused |
| `transition_allowed()` | No change for design/plan/retro. For `kind=memory`, the only meaningful transition is `active → expired:<reason>` (one-way, matching the "expired is terminal" rule already shipped for other kinds) — this falls out of `validate_status_for_kind`'s restricted vocabulary without a new transition-matrix branch, since there is no other memory status to transition from/to | fully reused, no new matrix row needed |
| `cmd_upsert()` / `cmd_show()` / `cmd_set_status()` | No change beyond the one new `validate_status_for_kind` call inserted into `cmd_upsert`/`cmd_set_status` | mostly reused |
| `validate_path()` | No change — already generic for any repo-relative path | fully reused |
| `collapse_rows()` / `topic_of_path()` | No change to the collapse *mechanics* — `docs/memory/<category>_<slug>.md` paths carry no `YYYY-MM-DD-` prefix to strip, so `topic_of_path()` naturally falls back to grouping by the row's `category`-derived summary text for memory rows, same as it already does for any path without a date prefix. No special-casing required, but this fallback behavior is worth a unit test (see `bdd-specs.md` Scenario 17) since it was previously only exercised by `docs/writing-skills/`, a single fixed row | fully reused, one new test |
| `scan_folders()` | **New for-loop** (~6 lines), same shape as the existing retro-file loop: `for f in "${root}/docs/memory/"*.md; do … printf '%s\t%s\t%s\n' "${f#${root}/}" "memory" "active"; done`. Extracts `summary:` from the file's own frontmatter via `grep '^summary:' "$f"` so first-time `rebuild` doesn't seed a blank summary (memory files, unlike design/plan folders, carry a canonical one-line summary internally already). Plain, non-recursive glob (`docs/memory/*.md`, not `docs/memory/**/*.md`) — this is what makes `docs/memory/archive/` invisible to `rebuild` with zero extra logic: archived files simply aren't matched | **genuinely new**, small, isolated |

Everything else the transition matrix, controlled-vocab validator, atomic-write path, and 60-line collapse rule already do continues to apply to `kind=memory` rows verbatim.

**Reconciliation note (status enforcement is code-level, not documentation-only):** an earlier draft of this design proposed leaving the `active|expired` restriction as a documented convention only, with the script staying fully kind-agnostic on status. That was rejected during integration — the plugin's own shipped requirement #8 ("MUST enforce the controlled status vocabulary... exits 2, writes nothing") establishes code-enforced vocabulary as the norm, and a documentation-only convention would be silently violable by a future skill edit that copy-pastes a `wip`/`superseded-by` call from the design/plan touchpoints without adjusting it for `memory`. The one new `validate_status_for_kind` function closes that gap for the cost of ~10 lines.

## 3. Per-Skill Touchpoints

Each skill gains one memory-read step at its existing consult-before point, and one conditional memory-write step gated by a threshold the skill already tracks — no new counters, no new phases.

### brainstorming (`skills/brainstorming/SKILL.md`)

| Touchpoint | Insertion point | Action |
|---|---|---|
| memory-read | Initialization, step 2 (`SKILL.md:55`, already extended once for design consult) | Extend step 2 a second time: after the two design `list` calls, run `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" list --kind memory --status active`. Read the 3-5 rows whose `summary` topically overlaps the problem statement; `Read` those files in full before Phase 1 exploration. |
| memory-write (conditional) | Gate observed at Phase 2's existing "REWORK 2+ rounds" language (`SKILL.md:135`); write executed at Phase 3 Wrap-up as new step 0.5 (`SKILL.md:149`, immediately after the existing design-upsert step 0, before `git add`) | **Gate = the existing 2+ REWORK rounds trigger** (no new counter). If Phase 2 hit 2+ REWORK rounds, carry the round count and one-line rework cause into Phase 3. New step 0.5 (CRITICAL — do not defer, same marker style as step 0): write `docs/memory/<category>_<slug>.md` (`category: decision` if the rework was a scope/approach reversal, `category: pitfall` if it was a recurring evaluator-caught mistake), then `docs-index.sh upsert memory docs/memory/<path> --status active --summary "<one-line>"`. Staged into the same wrap-up commit as the design folder + design-upsert. |

### writing-plans (`skills/writing-plans/SKILL.md`)

| Touchpoint | Insertion point | Action |
|---|---|---|
| memory-read | Initialization, step 1 "Design Check" (`SKILL.md:67`, already runs `docs-index.sh show <design-path>`) | Extend step 1: also run `list --kind memory --status active`; read top matches before Phase 1 "Read Specs." |
| memory-write (conditional) | Gate observed at Phase 4's existing FAIL/rework language (`SKILL.md:204`); write executed at Phase 5 "Git Commit" as new step 0.5 (`SKILL.md:215`, immediately after the existing plan-upsert step 0) | **Gate = a Phase 4 sub-agent FAIL requiring rework, not first-pass PASS** (reuses the existing sentence verbatim, no new counter). New step 0.5: write `docs/memory/<category>_<slug>.md` (typically `category: pitfall`), then `docs-index.sh upsert memory <path> --status active --summary "<one-line>"`. |

### executing-plans (`skills/executing-plans/SKILL.md`)

| Touchpoint | Insertion point | Action |
|---|---|---|
| memory-read | Initialization, step 1 "Plan Check" (`SKILL.md:51`, already runs `docs-index.sh show <plan-path>`) | Extend step 1: also run `list --kind memory --status active`; read top matches before Phase 1 "Plan Review." |
| memory-write (conditional) | Gate = the existing "variety gap" signal in `references/intra-plan-learning.md:54` ("all checklist items PASS for a batch but the batch required 2+ rework rounds"), surfaced during Phase 4 "Verification & Feedback" (`SKILL.md:84-86`); write executed at Phase 5 "Git Commit," bundled with the existing CRITICAL post-commit index-flip block (`SKILL.md:97`) | **Gate = the variety-gap signal (2+ rework rounds, batch eventually PASSes)** — this is a distinct, precise reuse: `references/batch-execution-playbook.md:165`'s "max 2 evaluation-rework rounds before escalation" is a *different* signal (a hard execution-abort cap when a batch never reaches PASS) and is deliberately NOT repurposed here, to avoid conflating "gave up" with "eventually succeeded but the friction is a reusable lesson." At Phase 5, extend the existing CRITICAL block: alongside `set-status <plan-path> "implemented:<sha>"`, if any batch this run hit the variety-gap signal, also write `docs/memory/<category>_<slug>.md` (`category: pitfall`) and `docs-index.sh upsert memory <path> --status active --summary "<one-line>"`, folded into the same dedicated follow-up commit the block already creates. |

### systematic-debugging (`skills/systematic-debugging/SKILL.md`)

| Touchpoint | Insertion point | Action |
|---|---|---|
| frontmatter | `allowed-tools` (`SKILL.md:6`) currently lacks any docs-index tool | Add `"Bash(${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh:*)"` — the only frontmatter change needed. |
| memory-read | New step 0, prepended to Phase 1 "Root Cause Investigation" (`SKILL.md:99`), only on the non-bail-out path | Before step 1 "Read Error Messages Carefully," run `list --kind memory --status active`, filter by summary keywords matching the symptom, `Read` the top 2-3 matches. Symmetric with the bail-out check: the Bail-Out (`SKILL.md:29-55`) already skips the entire 4-phase pipeline for named-root-cause/named-fix bugs — it skips this memory-read too. |
| memory-write (conditional) | New step 6, appended immediately after existing step 5 "Architecture Questioning After 3+ Failed Fixes" (`SKILL.md:241-255`), inside Phase 4 "Implementation" — a single conditional step, not a new phase | **CRITICAL — the ONLY docs/ touchpoint in this skill.** Fires when EITHER: (a) the existing "3+ fixes → question architecture" trigger fires, OR (b) the investigation surfaced an explicit cross-cutting gotcha regardless of fix-attempt count. On fire: write `docs/memory/<category>_<slug>.md` (`category: pitfall` typically, `category: decision` if the architecture-questioning step concluded a redesign is warranted) using the Inline Plan's six-line shape (`ROOT CAUSE`/`FIX STRATEGY`/`RISKS`, `SKILL.md:277-282`) as ready-made `Fact`/`Why` material when one was recorded. Set `source: commit:<short-sha>` (this skill produces no `docs/plans/` folder). Then `docs-index.sh upsert memory <path> --status active --summary "<one-line>"`, staged into the same commit as the fix + regression test — no separate index-only commit, since this skill has no Phase 5/6 commit-splitting machinery. If the bug never reaches 3+ fixes and surfaces no cross-cutting gotcha, this step is a no-op — the vast majority of invocations write nothing. |

### retrospective (`skills/retrospective/SKILL.md`)

Retrospective is the primary/highest-volume writer — unlike the other four (rare escalation only), every applied ADD/MODIFY proposal is memory-worthy because Phase 3's own thresholds already are the evidence bar (2+ plans / 2+ false positives is precisely "durable, cross-run signal," not a one-off).

| Touchpoint | Insertion point | Action |
|---|---|---|
| memory-read | Phase 1 "Data Collection," step 1 (`SKILL.md:95`, already runs `list --kind plan --status implemented` / `list --status expired`) | Extend step 1: also run `list --kind memory --status active` to fold prior distilled facts into the Phase 2 failure-frequency/plateau analysis. |
| memory-write (conditional) | Gate = the existing Phase 3 table thresholds (`SKILL.md:119-124`: ADD = 2+ plans, MODIFY = 2+ false positives — reused verbatim). Write executed in two stages matching retrospective's own existing two-stage pattern | **Stage 1 — Phase 4 "Auto-Apply," new step 3.5** (`SKILL.md:140-141`, immediately after existing step 3 "Log evolution"): for every ADD or MODIFY proposal actually applied this run, write one paired `docs/memory/<category>_<slug>.md` (`category: convention` for a generalized structural rule, `category: pitfall` for a recurring failure mode, `category: decision` for a rejected-vs-chosen call), using the proposal's own description+rationale directly as `Fact`/`Why` content; `source:` cites the retro report path. **Stage 2 — Phase 6 "Output," new step 8** (`SKILL.md:170-172`, after the existing invalidate-after step 7): `docs-index.sh upsert memory <path> --status active --summary "<one-line>"` for each memory file written in Stage 1. |

**Deliberately excluded from the write-gate:** `REMOVE` (0 failures across 3+ reports — a retraction, not a positive fact worth distilling) and `PROMOTE` (a checklist-internal capability graduation, not a project-level insight). Keeping the write-gate to ADD/MODIFY only prevents the memory store from inheriting the checklist's "only ever grows" failure mode.

## 4. Relationship to Retrospective's Pre-Check B (Global Memory Recall)

`retrospective/SKILL.md:31-41` already recalls a different memory system — this assistant's own private, cross-project, harness-injected `~/.claude/.../memory/MEMORY.md` — as a secondary calibration signal. The two systems are complementary along three independent axes:

| Axis | Pre-Check B (existing, unchanged) | `docs/memory/` (new) |
|---|---|---|
| Storage | Private to this assistant install, outside the repo, never git-tracked | `docs/memory/*.md`, git-tracked, lives in the project repo |
| Visibility | This one assistant instance only | Any skill run by anyone with this repo checked out; readable via `git show`/`cat` like any doc |
| How consulted | Passive — injected into context at session start; retrospective scans what's already there | Active — every skill runs an explicit `docs-index.sh list --kind memory` call |
| Who writes it | This assistant, informally, across arbitrary conversations, no schema | Five specific skills, at five specific gated steps, fixed Fact/Why/How-to-Apply schema |
| Authority | Advisory only — `evolution-log.jsonl` stays authoritative on disagreement | Authoritative for what it records — as durable as an `implemented:<sha>` row |

**New integration point:** retrospective's Phase 3 may *promote* a Pre-Check-B-recalled global-memory prior into `docs/memory/<category>_<slug>.md`, when the prior is cited as supporting evidence for an approved Phase 3 proposal **and** proves project-specific and durable (not a cross-project harness-design stance — those correctly stay global-only). The memory file's `## Why` section records `Promoted from private assistant memory hook: <hook-name>, <date>` for provenance. The private hook is never deleted or "consumed" — it's mirrored into the git-tracked layer once shown to matter for this project specifically.

## Data Structures (delta)

### Index row — `kind` enum extended, no shape change

```
path:    string (repo-relative, primary key — e.g. "docs/memory/pitfall_repo-root-fallback.md")
kind:    enum {design, plan, retro, memory}      # +memory
status:  string from controlled vocabulary; for kind=memory, restricted to {active, expired:<reason>}
summary: string, <= 72 chars (unchanged)
updated: ISO date string YYYY-MM-DD (unchanged)
```

### Memory file frontmatter (new)

```
name:     string, matches filename stem minus category prefix
category: enum {convention, pitfall, decision, preference}   # file-internal only, never in the index row
summary:  string, <= 72 chars                                 # source-of-truth for --summary at upsert time
source:   string | "commit:<7-char-sha>" | omitted            # repo-relative path or fix-commit reference
created:  ISO date string YYYY-MM-DD
updated:  ISO date string YYYY-MM-DD
```

## Integration Points

- **`lib/utils.sh`** — `repo_root` resolution, unchanged, same as every other subcommand.
- **`docs/memory/archive/`** — a plain subdirectory, created on first archive (`mkdir -p`), never scanned by `rebuild` (non-recursive glob). Not a new mechanism — reuses the atomic-write + path-validation machinery already in the script.
- **`hooks/stop-state-sync.sh`** — unaffected; the memory layer is skill-written only, same as the rest of the docs-index.
- **`docs/writing-skills/`** — unaffected; remains the sole `kind=retro status=reference` seed entry; memory rows never use `status=reference`.
