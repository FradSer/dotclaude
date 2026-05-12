# Unified Retrospective Event Helpers — Design Index

**Status**: DESIGN-IN-PROGRESS — brainstorming output, awaits round-1 evaluation.

**Target version**: superpowers v2.9.0 (one PR).

**Scope discipline**: this design produces three lib `helper` files behind one shared core,
migrates two `retrospective` `emission point`s, and adds one new `emission point` in
`systematic-debugging`. It does NOT redesign the existing `channel` schemas, the
`retrospective` Phase 1 reader logic, or any consumer of `plans-completed.jsonl` /
`bail-out-events.jsonl`.

## Context

The superpowers plugin currently writes four NDJSON `channel`s under `docs/retros/`. Each
`channel` records `event`s that the `retrospective` Phase 1 reader (and other downstream
consumers) ingest to calibrate the harness. The four `channel`s and their write-path
origins are split unevenly between shipped `helper` code and Claude-instructed inline
`bash` blocks in SKILL.md:

| `channel` | Written by | Write mechanism |
|---|---|---|
| `plans-completed.jsonl` | `lib/loop.sh` (Stop hook) | `helper` function in shipped lib |
| `bail-out-events.jsonl` | `lib/bail-log.sh` (sourced or executed from SKILL.md) | `helper` function in shipped lib |
| `harness-observations.jsonl` | `retrospective` Phase 5c (and consuming `skill`s when components are disabled) | Claude-instructed inline `bash` block in SKILL.md |
| `evolution-log.jsonl` | `retrospective` Phase 4 + Phase 6 | Claude-instructed inline `bash` block in SKILL.md |

Two of the four `channel`s (`harness-observations.jsonl`, `evolution-log.jsonl`) are still
written by SKILL.md instructing Claude to construct a `jq -nc … >> file` invocation at
runtime. The other two (`plans-completed.jsonl`, `bail-out-events.jsonl`) already route
through a single `helper` function and have parity tests. The split — same `event`-log
shape, different write surface — is itself an inconsistency that v3 retro
`superpowers/TODO-v3.md` T-002 flagged as known debt awaiting a "third channel" forcing
function. The boilerplate is now duplicated across two `skill`s on different code paths,
each of which has independently drifted in small ways (different `jq` argument ordering,
different `mkdir -p` guards) that a `helper` would normalise.

Separately, `systematic-debugging` is the only user-invocable `skill` that produces no
`retrospective`-visible signal of a *successful* outcome. It emits via `bail-log` only on
its bail-out gate (and on `--force` overrides), never on a Phase 4 fix completion. The
`retrospective` therefore has no usage data for the most-invoked debugging path: the user
reports a bug, Claude runs the four phases, ships a fix and a regression test, and the
entire arc is invisible to the calibration loop. The `retrospective` Phase 5a
("Usage-Driven Recommendations") cannot weigh whether `systematic-debugging` earns its
cost — it sees only the bail rate, which by construction is the inverse of the success
rate it should be measuring.

The trigger for this design is the convergence of two things in the same PR window:

1. `systematic-debugging` needs an `emission point` for `fix_completed` — a *new*
   `channel`-shaped need that, if shipped independently, would mean a third
   Claude-instructed inline `bash` block in a third SKILL.md.
2. The two manual-write `channel`s still match T-002's fix-now bar.

Promoting the two manual-write `channel`s in isolation would be add-bias (the rule-of-two
isn't a strong forcing function — both could plausibly keep working as inline blocks).
Adding `systematic-debugging`'s emission as a third inline block independently would
replicate the boilerplate a third time. But promoting the two existing `channel`s
*while also* adding `systematic-debugging`'s first emission lets one PR satisfy three
independent goals through one shared `helper` core, and reaches rule-of-three —
T-002's stated fix-now bar.

Constraint: the four `channel` files on disk cannot be unified at the file layer. The
`retrospective` Phase 1 reader walks each `channel` with `channel`-specific aggregation
logic:

- Phase 5c reads `harness-observations.jsonl` keyed by `disabled_components[]` entries.
- Phase 5a aggregates `bail-out-events.jsonl` by `(skill, event)` and distinct `args_hash`
  values per `skill`.
- Phase 1 step 5 walks `evolution-log.jsonl` for `item_added|item_removed|item_modified|item_promoted`
  keyed by `item_id`.
- Pre-Check A reads `plans-completed.jsonl` for the most recent `plan_completed` event by
  `hours_since_completion`.
- Pre-Check B reads `evolution-log.jsonl` for the most recent `retrospective_run` event to
  extract `consecutive_zero_change`.

Unifying the file layout would force a parallel rewrite of every reader — large blast
radius, zero functional gain. The unification is therefore strictly at the
**write-API layer**: one shared core (`lib/retro-events.sh`) with three thin wrapper
`helper`s, each producing the existing on-disk schema byte-for-byte.

## Discovery Results

### Existing `channel` inventory (write side)

| `channel` file | Current `emission point` source | Current consumer(s) |
|---|---|---|
| `docs/retros/plans-completed.jsonl` | `lib/loop.sh` (Stop hook, after plan completion detection) | `executing-plans` (retrospective-due reminder), `retrospective` Pre-Check A (most-recent `plan_completed`), `retrospective` Phase 1 step 1 (`--across-all` auto-scope) |
| `docs/retros/bail-out-events.jsonl` | `lib/bail-log.sh` (sourced or executed from SKILL.md by `brainstorming`, `writing-plans`, `executing-plans`, `systematic-debugging`) | `retrospective` Phase 1 step 7, Phase 5a `bail-threshold` candidate detection |
| `docs/retros/harness-observations.jsonl` | `retrospective` Phase 5c (manual `bash` block in SKILL.md) and consuming `skill`s when a component is disabled in `harness-config.json` | `retrospective` Phase 1 step 6 (judges prior disable test) |
| `docs/retros/evolution-log.jsonl` | `retrospective` Phase 4 (per approved proposal) and Phase 6 (`retrospective_run` closure event) — both manual `bash` blocks in SKILL.md | `retrospective` Pre-Check B (`consecutive_zero_change`), Phase 1 step 5 (historical proposals keyed by `item_id`), Phase 6 calibration loop closure |

### Existing `lib/` files — the precedent set

- **`lib/utils.sh`** — shared helpers (`repo_root`, state I/O, tag extraction). Sourced by
  other lib scripts. Emits a stderr warning on missing deps; has no top-level `set -e`
  so sourcing does not perturb the caller's error-handling regime.
- **`lib/bail-log.sh`** — single-`channel` `helper`; sourceable and executable. Declares
  the contract this design extends:
  - "never blocks caller",
  - "missing `jq` / unwritable `repo_root` / missing `docs/retros` all silently skip",
  - "no top-level `set -e`",
  - "args_hash is salt-free first-12-chars sha1, empty when neither shasum nor sha1sum
    is in PATH".
  The 86-line file is the canonical `helper` template for this design.
- **`lib/loop.sh`** — Stop-hook orchestrator; writes to `plans-completed.jsonl` through
  inline logic that has not yet been refactored to use a shared `event`-write primitive.
  Out of scope for this design (BC3 prohibits touching it).
- **`lib/post-plan-diff.sh`** — classifies post-plan commits as `feedback` vs `evolution`.
  Pure compute, no `channel` writes. Consumed by `retrospective` Phase 1 step 8 and
  Pre-Check A. Not relevant to this design except as a precedent for sourceable +
  executable shell `helper` style.
- **`lib/seed-checklists.sh`** — one-shot checklist seeder. Does not emit `event`s; ships
  v1 templates for the three modes. Not relevant beyond style precedent.

### Existing test patterns

- **`tests/test_bail_log_sh.py`** — the mirror template for this design. Tests three
  modes:
  - **Executed** (`bash <script> <args>` round-trip into an NDJSON line — the SKILL.md
    invocation path),
  - **Sourced** (`source` under `set -euo pipefail` and call the function — verifies
    sourcing does not perturb the caller's error-handling regime),
  - **Degradation** (missing `jq` / unwritable `docs/retros` / empty args / unresolvable
    timestamp all return 0 and produce no log).
  Each new `helper` in this design ships a parallel test file under `tests/` with the
  same three-mode shape.
- **`tests/test_post_plan_diff_sh.py`** — pure-compute test pattern; not directly
  applicable to event-emitting `helper`s but confirms the project tests shell `helper`s
  in Python rather than `bats`. The new tests inherit this convention.
- **`tests/test_phase_integration.py`** — end-to-end test pattern across `helper`
  boundaries. This design adds **migration parity** tests here (a separate concern from
  per-`helper` unit tests — see Detailed Design step 4).
- **`tests/conftest.py`** — shared fixtures (tmpdir + isolated `CLAUDE_PROJECT_DIR`).
  Reused as-is by the new test files.

### T-002 reference (verbatim fix-now bar)

`superpowers/TODO-v3.md` §T-002 declares the fix-now bar:

> **Fix-now bar**: a third manual-write channel is proposed (so the same boilerplate
> would otherwise be replicated four times). At that point promote all to lib helpers
> in one sweep.

The third `channel` is the new `systematic-debugging` `fix_completed` `event`, which
adds a third skill needing the same boilerplate (boilerplate-replication-count would
hit four if shipped inline). The bar fires; this design discharges T-002. The fix-now
bar's empirical rationale ("boilerplate replicated four times across three SKILL.md
files") is what removes this from the add-bias category — the alternative is concrete
duplication, not hypothetical future cleanliness.

### Contract constraints inherited from `bail-log.sh`

The new `helper`s must preserve every property already shipped on `bail-log.sh`:

1. **Dual-mode**: each `helper` file is both sourceable (function exposed) and
   executable (direct `bash <script>` invocation with positional args forwards to the
   function).
2. **Best-effort**: missing `jq`, missing `shasum`/`sha1sum`, unwritable `repo_root`,
   unresolvable timestamp all return `0` and produce no `channel` write. No stderr
   noise. The caller never observes a failure.
3. **No top-level `set -e`**: sourcing must not perturb the caller's error-handling
   regime, especially under `set -euo pipefail` callers like the test harness.
4. **`repo_root` resolution**: routes through `utils.sh::repo_root`
   (`CLAUDE_PROJECT_DIR` → `git rev-parse --show-toplevel` → `PWD`). This is the T-001
   fix the new `helper`s must inherit by sourcing `utils.sh`. Without it, nested-cwd
   invocations from a sub-agent would write to the wrong `docs/retros/` directory.

## Glossary

Vocabulary reconciled before design — used consistently across this design folder. The
reject list is binding: the rejected synonyms must not appear in `_index.md`,
`architecture.md`, `bdd-specs.md`, or `best-practices.md`.

| Canonical label | Definition |
|---|---|
| **helper** | A function defined in a `lib/*.sh` file (e.g. `bail_log`, `log_skill_event`). Always shell-side. Always sourceable and executable. |
| **channel** | One NDJSON file under `docs/retros/` (`plans-completed.jsonl`, `bail-out-events.jsonl`, `harness-observations.jsonl`, `evolution-log.jsonl`, `skill-events.jsonl`). One `channel` per file; one file per `channel`. |
| **event** | One line in a `channel`. NDJSON object. Has at minimum `event` (kind string), `timestamp`, plus `channel`-specific fields. |
| **skill** | A user-invocable superpowers `skill` (`brainstorming`, `writing-plans`, `executing-plans`, `retrospective`, `systematic-debugging`). |
| **emission point** | A specific code location that invokes a `helper`. Not the `helper` itself, not the `channel`. Examples: "the `retrospective` Phase 5c refusal branch", "the `systematic-debugging` Phase 4 fix verification step". |
| **migration parity** | The property that, for each migrated `emission point`, the bytes written by the new `helper` are byte-for-byte equivalent to the bytes written by the pre-migration inline `bash` block (modulo `timestamp` and other intrinsically variable fields). Verified by a dedicated parity test. |

**Rejected synonyms** (do not use anywhere in this design folder):

| Rejected | Reason |
|---|---|
| `logger` | Implies stderr / stdout / framework `logging`; this is filesystem append, no log levels. |
| `writer` | Overlaps "file writer" in plan-execution language; ambiguous with `Write` tool. |
| `appender` | log4j connotation; readers misread as Java-isms. |
| `emitter` | Overlaps event-emitter (pub/sub) connotation; these `helper`s do not subscribe. The verb "emit" is reserved for the *action* a `helper` performs at an `emission point`; the noun for the function itself is `helper`. |
| `sink` | Reversed direction; `channel`s are append-only files, not stream sinks. |
| `tracker` | Already taken by `hooks/track-changes.sh` (Edit/Write file tracking); collision would be confusing. |

## Requirements

### Functional

- **F1.** A `helper` `log_skill_event` exists in `lib/skill-events.sh` accepting
  (`skill`, `event`, `payload_jq_filter`, `args`) and appending one NDJSON line to
  `docs/retros/skill-events.jsonl`. *Verifiable*: call the `helper` with fixture inputs;
  assert the file contains a parseable JSON line with the expected fields. See
  `./architecture.md` for the exact signature and payload schema.
- **F2.** A `helper` `log_harness_observation` exists in `lib/observations.sh` writing to
  `docs/retros/harness-observations.jsonl`. The output schema is **byte-for-byte
  equivalent** to what `retrospective` SKILL.md Phase 5c currently writes via inline
  `bash`. *Verifiable*: the migration parity test (see Detailed Design step 4) passes
  for each of the four existing event kinds (`component_disabled`,
  `component_unsupported`, `component_unknown`, `disable_outcome`).
- **F3.** A `helper` `log_evolution_event` exists in `lib/evolution-log.sh` writing to
  `docs/retros/evolution-log.jsonl`. The output schema is byte-for-byte equivalent to
  the existing event shapes (`item_added`, `item_removed`, `item_modified`,
  `item_promoted`, `retrospective_run`, `component_reinstated`). *Verifiable*: parity
  tests cover each event kind.
- **F4.** All three wrapper `helper`s share a single core `helper` library
  `lib/retro-events.sh` that provides the common primitives (`repo_root` resolution,
  `docs/retros/` mkdir, `jq` availability check, ISO 8601 UTC timestamp, NDJSON
  append). *Verifiable*: `grep`-able primitive function names appear only in
  `retro-events.sh`; the three wrappers source it; no duplicate `mkdir -p docs/retros`
  or `command -v jq` lines remain across the three wrappers.
- **F5.** `systematic-debugging` SKILL.md gains a new `emission point` at the end of
  Phase 4 calling `log_skill_event systematic-debugging fix_completed …`. Fired when
  Phase 4 step 3 ("Verify Fix") confirms test passes and the issue resolved. Not fired
  on the bail-out branch (already covered by `bail_log`) and not fired when Phase 4
  step 4 detects fix failure (so the calibration loop sees only confirmed-good
  outcomes). *Verifiable*: BDD scenario `bdd-specs.md` §"Phase 4 successful completion
  emits fix_completed".
- **F6.** `retrospective` Phase 1 reads `docs/retros/skill-events.jsonl` if present and
  surfaces aggregated counts per `(skill, event)` in the retrospective report (Phase 6
  output, new "Skill activity" subsection). The counts do **not** enter the DUE-reminder
  count (which remains owned by `plans-completed.jsonl`) nor the EVO proposal-threshold
  logic. *Verifiable*: BDD scenario `bdd-specs.md` §"Phase 1 surfaces skill-events
  without affecting DUE".

### Non-functional

- **NF1.** Every `helper` file is both sourceable (function exposed when `source`d, no
  side effects beyond function definition) and executable (`bash <file> <args>` forwards
  to the function). *Verifiable*: each test file has an Executed mode and a Sourced
  mode (mirror of `test_bail_log_sh.py`).
- **NF2.** Missing `jq`, missing `shasum`/`sha1sum`, missing `docs/retros/` write
  permission, unresolvable `repo_root`, unresolvable timestamp → the `helper` returns
  `0` and writes nothing. No stderr noise. *Verifiable*: degradation tests per
  `helper` mirror `test_bail_log_sh.py` degradation cases (six degradation cases per
  `helper`, all asserting exit-0 plus zero-byte log file).
- **NF3.** None of the new `lib/*.sh` files has a top-level `set -e`, `set -u`, or
  `set -o pipefail`. Sourcing must not alter the caller's error-handling regime,
  especially under `set -euo pipefail` callers like the test harness.
  *Verifiable*: shellcheck plus a grep assertion in a test (no `^set -` at column 0).
- **NF4.** Dedup pattern, where used, mirrors `plans-completed.jsonl`:
  `tail -n 200 <file> | grep -qF <key>` before append. Applies only to `event`s that
  are explicitly de-duplicated (currently: `plan_completed` only; new `helper`s
  default to **no dedup** unless the wrapper explicitly opts in). *Verifiable*: the
  only file invoking the dedup primitive in this PR is `loop.sh` (unchanged); no
  wrapper added by this design opts in.

### Backward compatibility

- **BC1.** Existing rows in `docs/retros/plans-completed.jsonl`,
  `docs/retros/bail-out-events.jsonl`, `docs/retros/harness-observations.jsonl`,
  `docs/retros/evolution-log.jsonl` are not rewritten, reformatted, or deleted.
  *Verifiable*: the migration patch touches SKILL.md `emission point`s and lib code
  only; no `find` invocation rewrites jsonl files; PR diff contains zero touched
  lines under `docs/retros/*.jsonl`.
- **BC2.** `retrospective` Phase 1 (data collection), Phase 5 (harness health),
  Pre-Check A (INSUFFICIENT-POST-PLAN), Pre-Check B (LOW-YIELD) consume the same
  fields at the same positions after migration. *Verifiable*: parity tests confirm
  output shape; `retrospective` SKILL.md downstream-reader sections are unchanged
  except for the new Phase 1 surface of `skill-events.jsonl` (an additive read, not
  a modification to existing readers).
- **BC3.** `docs/retros/plans-completed.jsonl` and `docs/retros/bail-out-events.jsonl`
  are not refactored by this design. They already route through shipped `helper`s and
  are out of scope. Future work may consolidate them through `retro-events.sh`; not
  in this PR. *Verifiable*: `lib/loop.sh` and `lib/bail-log.sh` are unchanged in
  this PR (except possibly an `# uses lib/retro-events.sh` cross-reference comment,
  with no behavior change).

## Rationale

**Why four files (`retro-events.sh` + three wrappers) rather than one consolidated
`lib/retro-events.sh` with all three `helper`s inside.** The single-file alternative
is shorter on initial diff but loses three properties that `bail-log.sh`'s precedent
ships. First, "one file per concern" matches the existing `lib/` convention —
`bail-log.sh`, `loop.sh`, `post-plan-diff.sh`, `seed-checklists.sh` each own exactly
one verb, and the next reader of `lib/` should not need to learn that one file is
special-cased to hold three concerns. Second, the test surface stays clean: one test
file per wrapper (`test_skill_events_sh.py`, `test_observations_sh.py`,
`test_evolution_log_sh.py`) mirrors `test_bail_log_sh.py` exactly; folding the
wrappers into one file would force one test file with three classes and unclear
failure attribution when a parity test fails. Third, future work to add or retract a
`channel` has a blast radius of one file rather than one section inside a
four-section file — and git history would show "this `helper` was added on date X"
rather than a series of incremental section diffs. The core primitives genuinely
shared across all three (timestamp, mkdir, jq check, NDJSON append) extract cleanly
into `retro-events.sh` and are roughly 30–50 lines; the cost of one extra file pays
for itself the first time a fifth `channel` is considered.

**Why emit `fix_completed` only at Phase 4 and not at every phase of
`systematic-debugging`.** The Iron Law (NO FIXES WITHOUT ROOT CAUSE INVESTIGATION
FIRST) rules out emitting at Phase 1 — Phase 1 is by definition the *prevention* of
fixes, and emitting on its completion would be measuring nothing externally
observable (it would fire on every invocation that passed the bail-out, which is
already captured by the absence of a `bail_out` event). Phase 2 and Phase 3 are
transient internal states; the Phase 2 → 3 transition can flip multiple times within
one session as hypotheses fail and are reformed (Phase 3 step 4: "If not confirmed:
form new hypothesis"). Emitting on every flip would generate a per-conversation
noise signal that `retrospective` Phase 5a cannot calibrate against. The only stable,
externally-observable outcome of the four-phase pipeline is Phase 4 step 3 ("Verify
Fix" passes). Emitting any other phase would generate signal noise; emitting only
this one phase makes the `event` rate directly comparable to the bail rate from
`bail-out-events.jsonl`, which is what `retrospective` Phase 5a needs.

The same logic decides what payload `fix_completed` carries. The regression test
path (proves the deliverable shape — "fix + test", not "fix alone") and the file
count (proxy for blast radius) are both observable invariants that calibrate
"single-file" vs "multi-component" bug distributions. It does not carry the root
cause one-liner or fix diff summary; those are conversational artifacts, not
`retrospective` inputs, and storing them would create a privacy-tier question this
design has no mandate to resolve.

**Why not also add `design_completed` / `plan_completed` `emission point`s in
`brainstorming` and `writing-plans`.** Those two `skill`s already produce their own
deliverable folders (`docs/plans/<date>-<topic>/_index.md`, `bdd-specs.md`,
`architecture.md`, `best-practices.md`) that are filesystem-observable. The
`retrospective` walks those folders directly in Phase 1 step 1–2 to scope inputs.
Adding a `skill_event` for "design completed" or "plan completed" would duplicate
signal already captured by the folder's existence, with no consumer that needs the
duplicated form. Add-bias guard: the rule-of-three test fires only when three
`emission point`s genuinely need the same shape; here, only `systematic-debugging`
has the signal gap (no folder, no other observable artifact). Add the two design /
plan `emission point`s when a real consumer demands them, not preemptively.

**Why the file layer is not unified.** Consumers downstream of each `channel` are
deeply coupled to that `channel`'s schema and aggregation key:

- `retrospective` Phase 1 step 5 (`evolution-log` keyed by `item_id`),
- Phase 1 step 6 (`harness-observations` keyed by `disabled_components[]` entry),
- Phase 1 step 7 (`bail-out-events` aggregated by `(skill, event)` and `args_hash`
  distinctness),
- Pre-Check A (most recent `plan_completed` by `hours_since_completion`),
- Pre-Check B (most recent `retrospective_run` for `consecutive_zero_change`).

Each reader opens one specific file with one specific aggregation logic. Merging
the four files into one would require either filtering by `event` kind in every
reader (slower, more brittle) or maintaining indices alongside the merged file (a
new mechanism that itself can fail and would need its own retract trigger). The
unification is at the *write API* — the only layer where the boilerplate genuinely
duplicates — and stops there.

## Detailed Design

This section provides the cross-cutting view. Per-`helper` contracts, schemas, and
the migration parity matrix live in `./architecture.md`; Gherkin scenarios live in
`./bdd-specs.md`; safety and quality constraints live in `./best-practices.md`.

### Overall shape

- **Four new `lib/*.sh` files**:
  - `retro-events.sh` (shared core, ~50 lines) — primitives only, no callers besides
    the three wrappers.
  - `skill-events.sh` (wrapper, ~30 lines) — exposes `log_skill_event`.
  - `observations.sh` (wrapper, ~30 lines) — exposes `log_harness_observation`.
  - `evolution-log.sh` (wrapper, ~30 lines) — exposes `log_evolution_event`.

  All four are sourceable and executable. All three wrappers source `retro-events.sh`
  for the NDJSON-append primitive; `retro-events.sh` itself sources `utils.sh` for
  `repo_root`.

- **One new `emission point`**: end of `systematic-debugging` Phase 4 step 3 ("Verify
  Fix" — the success branch only). The bail-out branch and the Phase 4 step 4
  failure branch are unchanged.

- **Two migrated `emission point`s** (both inside `retrospective` SKILL.md):
  - **Phase 5c** — currently a multi-line inline `bash` block constructing
    `jq -nc … >> docs/retros/harness-observations.jsonl` for the four observation
    `event` kinds. Migrates to `bash "${CLAUDE_PLUGIN_ROOT}/lib/observations.sh" …`.
    The `harness-config.json` write (a separate non-NDJSON file write inside the
    same SKILL.md section) remains inline — only the NDJSON append migrates.
  - **Phase 4 / Phase 6** — currently two inline `bash` blocks (one per approved
    proposal in Phase 4, one for the `retrospective_run` closure event in Phase 6)
    constructing `jq -nc … >> docs/retros/evolution-log.jsonl`. Both migrate to
    `bash "${CLAUDE_PLUGIN_ROOT}/lib/evolution-log.sh" …`. The
    `consecutive_zero_change` computation logic stays in SKILL.md — only the final
    NDJSON append migrates.

- **One new `retrospective` Phase 1 reader step**: reads
  `docs/retros/skill-events.jsonl` if present, aggregates counts per
  `(skill, event)`, surfaces in the Phase 6 report under a new "Skill activity"
  subsection. Does not enter the DUE counter, EVO threshold, or any other decision
  gate.

- **Four new test files** under `tests/`: `test_retro_events_sh.py`,
  `test_skill_events_sh.py`, `test_observations_sh.py`, `test_evolution_log_sh.py`.
  Each mirrors `test_bail_log_sh.py`'s three-mode shape (Executed / Sourced /
  Degradation). The first one additionally tests the shared primitives in isolation
  (timestamp format, NDJSON append, dedup primitive — when invoked directly).

### Naming overview

Aligned with `./architecture.md` (which carries the full schemas) and `./bdd-specs.md`
(which carries the per-event Gherkin scenarios):

| Layer | Name | Notes |
|---|---|---|
| Shared core lib | `lib/retro-events.sh` | Exposes primitives consumed only by wrapper `helper`s. |
| Skill-event wrapper | `lib/skill-events.sh` → `log_skill_event` → `docs/retros/skill-events.jsonl` | New `channel`. |
| Observation wrapper | `lib/observations.sh` → `log_harness_observation` → `docs/retros/harness-observations.jsonl` | Migrated `channel`. |
| Evolution wrapper | `lib/evolution-log.sh` → `log_evolution_event` → `docs/retros/evolution-log.jsonl` | Migrated `channel`. |
| New event kind (skill-events) | `fix_completed` | Emitted by `systematic-debugging` Phase 4 success branch. |
| Preserved event kinds (observations) | `component_disabled`, `component_unsupported`, `component_unknown`, `disable_outcome` | Schema unchanged; see `./architecture.md`. |
| Preserved event kinds (evolution-log) | `item_added`, `item_removed`, `item_modified`, `item_promoted`, `retrospective_run`, `component_reinstated` | Schema unchanged; see `./architecture.md`. |

### Migration order

The order below is deliberate. Steps 1–4 ship the new code without changing any
caller; the existing inline `bash` blocks keep writing the same bytes. Steps 5–6
swap the callers (the inline block disappears, replaced by the `helper` call) one
`emission point` at a time, with the parity test (step 4) gating each swap. Steps
7–8 add the new emission and the new reader, both additive. Step 9 documents the
migration in the `retrospective` references and discharges T-002.

1. **Create `lib/retro-events.sh`** with the shared primitives (mkdir, `jq` presence
   check, ISO 8601 UTC timestamp, NDJSON append, optional dedup primitive). No
   callers yet — pure additive.

2. **Create the three wrappers** (`lib/skill-events.sh`, `lib/observations.sh`,
   `lib/evolution-log.sh`). Each sources `retro-events.sh` and (transitively)
   `utils.sh`. No callers yet — pure additive.

3. **Write `helper` unit tests** (`test_retro_events_sh.py`, `test_skill_events_sh.py`,
   `test_observations_sh.py`, `test_evolution_log_sh.py`) — Executed / Sourced /
   Degradation modes per `helper`. Run; confirm green. At this point the new code
   is shipped but unused; the production write paths are still the inline `bash`
   blocks.

4. **Write migration parity tests**. For each migrated `emission point`, a test
   invokes the `helper` with the same fixture input that the inline `bash` block
   uses today and asserts byte-for-byte equality of the JSON object fields (modulo
   `timestamp`). This is the safety net — without it, the SKILL.md swap risks
   silent schema drift. The parity tests live under
   `tests/test_phase_integration.py` (or a new `tests/test_migration_parity.py`
   per `architecture.md`'s file layout).

5. **Migrate `retrospective` Phase 5c**: replace the inline `bash` block with a
   `bash "${CLAUDE_PLUGIN_ROOT}/lib/observations.sh" …` invocation. Re-run the
   parity test plus the existing `retrospective`-related integration tests. The
   `harness-config.json` write path (a separate file write, not a `channel`
   append) remains inline — only the `harness-observations.jsonl` append migrates.

6. **Migrate `retrospective` Phase 4 (per-proposal evolution append) and Phase 6
   (`retrospective_run` closure event)**: each inline `bash` block becomes a
   `bash "${CLAUDE_PLUGIN_ROOT}/lib/evolution-log.sh" …` invocation. Re-run parity
   test plus integration tests. The `consecutive_zero_change` computation logic
   stays in SKILL.md — only the final NDJSON append migrates.

7. **Add `systematic-debugging` Phase 4 `emission point`**. End of Phase 4 step 3
   (verify-fix success branch), call
   `bash "${CLAUDE_PLUGIN_ROOT}/lib/skill-events.sh" systematic-debugging fix_completed …`
   with the payload fields specified in `./architecture.md`. Add the
   `lib/skill-events.sh` path to the `skill`'s `allowed-tools` frontmatter so the
   invocation is permitted under the strict tool allowlist.

8. **Add `retrospective` Phase 1 step (read of `skill-events.jsonl`)**: read
   `docs/retros/skill-events.jsonl` if present, aggregate counts per
   `(skill, event)`, surface in the Phase 6 report under a new "Skill activity"
   subsection. The exact step position (a step 2 insert vs. an append after step 7)
   is decided in `./architecture.md`. No DUE / EVO impact — the surface is
   informational only.

9. **Documentation updates**:
   - `superpowers/skills/retrospective/references/` reflects the new write path
     (file + line citations only — no schema duplication; the `helper` script
     comments are the source of truth).
   - Append a one-line entry under `superpowers/TODO-v3.md` T-002 marking it
     discharged with a link to this design folder.
   - Update `superpowers/README.md` "Harness Calibration" section to mention the
     new `skill-events.jsonl` `channel` alongside the existing four.

The migration order's safety property: at no point are both the inline `bash`
block and the new `helper` simultaneously appending. Each `emission point` swaps
atomically in one PR commit, with the parity test as the precondition. If any
parity test fails after a swap, the revert is a single-commit rollback that
restores the inline block without touching the new lib code (the new lib code
stays shipped, just unused by the rolled-back `emission point`).

## Design Documents

- **`./architecture.md`** — Per-`helper` contracts, function signatures, payload
  schemas per `event` kind, dependency graph between the four new lib files,
  `allowed-tools` frontmatter delta per migrated `skill`, parity test file layout.

- **`./bdd-specs.md`** — Gherkin scenarios covering: F1–F6 functional requirements,
  NF1–NF4 non-functional requirements (degradation modes, sourcing safety), BC1–BC3
  backward compatibility (migration parity), and the `systematic-debugging` Phase 4
  success / fail / bail-out branches.

- **`./best-practices.md`** — Safety constraints (best-effort write contract, no
  top-level `set -e`, sourcing parity with `bail-log.sh`), performance constraints
  (one `jq` invocation per `event`, no synchronous fsync, append-only), quality
  constraints (parity-test gate before SKILL.md swap, one test file per `helper`,
  mirror of `test_bail_log_sh.py` shape).

- **`./evaluation-design-round-1.md`** — Evaluator round-1 report (generated by
  `superpowers-evaluator` after this design is submitted; placeholder until then).
