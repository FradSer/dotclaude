# Architecture: Unified Retro-Event Helpers

## Vocabulary (canonical labels)

The following terms are normative throughout this document and downstream artifacts (plan.md, batch contracts, SKILL.md edits, tests). Synonyms are forbidden — review tooling rejects "logger", "writer", "logger function", "emitter", "log function", etc.

| Term | Meaning |
|------|---------|
| **helper** | A bash function exported by a file under `superpowers/lib/`. |
| **channel** | A single NDJSON file under `docs/retros/*.jsonl`. |
| **event** | One NDJSON line — exactly one JSON object terminated by `\n`. |
| **skill** | A user-invocable Claude Code skill (e.g. `retrospective`, `systematic-debugging`). |
| **emission point** | A specific location in a SKILL.md (or other lib file) that calls a helper. |

## System Overview

T-002 in `superpowers/TODO-v3.md` records that two retro channels (`harness-observations.jsonl`, `evolution-log.jsonl`) were claimed as "lib-shipped" but are in fact Claude-instructed manual bash blocks inside `skills/retrospective/SKILL.md`. The fix-now bar is "a third channel is being proposed". This design introduces that third channel — `skill-events.jsonl`, fed by `systematic-debugging` Phase 4 — and uses the threshold to promote all three at once into a single helper layer mirroring `lib/bail-log.sh`.

The unified object is the **helper API**, not the channel files. The four channels (`bail-out-events.jsonl`, `harness-observations.jsonl`, `evolution-log.jsonl`, `skill-events.jsonl`) keep their existing on-disk schemas and consumer contracts; the SKILL.md bash blocks are replaced with one-line helper invocations whose contract is identical to `bail-log.sh`: best-effort, never blocks the caller, silently skips on missing dependencies, and resolves the project root via `utils.sh::repo_root`. Symmetry with `bail-log.sh` is the load-bearing property of this design — every helper here exists because the same pattern has now been replicated four times across the codebase, which is exactly the bar T-002 set for promotion.

A shared core file (`lib/retro-events.sh`) holds the primitives that all four helpers (counting `bail-log.sh`) would otherwise duplicate: jq presence check, `repo_root` resolution, log-dir creation, timestamp, NDJSON append, and dedup. `bail-log.sh` is **not** retrofitted in this design — it predates the shared core and works; retrofitting is a separate v3.x cleanup. The shared core is built fresh for the three new helpers so that the next channel-promotion (T-002 successor) inherits the primitives without further refactor.

## Components

### `lib/retro-events.sh` — shared core

Public functions (used by the three sibling helpers, not by skills directly):

| Helper | Signature | Contract |
|--------|-----------|----------|
| `jq_or_skip` | `jq_or_skip` | Returns 0 if `jq` is in PATH, 1 otherwise. Callers use `jq_or_skip \|\| return 0`. |
| `timestamp_or_skip` | `timestamp_or_skip` | Prints `date -u +"%Y-%m-%dT%H:%M:%SZ"` on stdout; returns 1 if `date` fails or output empty. |
| `ensure_log_dir` | `ensure_log_dir <abs_path>` | `mkdir -p` the directory; returns 0 on success, 1 on failure (callers `\|\| return 0`). |
| `repo_root_or_skip` | `repo_root_or_skip` | Calls `utils.sh::repo_root`; prints the path on stdout; returns 1 if empty. |
| `write_jsonl` | `write_jsonl <log_file> <jq_program> [jq_args...]` | Runs `jq -nc "$jq_program" "$@"` and appends the line to `<log_file>`. All failures redirected to `/dev/null`; returns 0 unconditionally (best-effort append). |
| `dedup_check` | `dedup_check <log_file> <substring>` | Returns 0 if `<substring>` is found in `tail -n 200 <log_file>` (substring is present, caller should skip the write); returns 1 if not found OR file missing. Mirrors the pattern in `loop.sh::_loop_log_plan_completion_if_executing`. |

Internal dependencies: sources `utils.sh` exactly once via the same `_RETRO_EVENTS_DIR/$(dirname "${BASH_SOURCE[0]}")` pattern as `bail-log.sh`. Re-sourcing is idempotent because `utils.sh` guards its deps check with `_SUPERPOWERS_DEPS_CHECKED`.

Schema: this file defines no channel and writes no events — it only exports primitives. NDJSON shape is the caller's responsibility (the three sibling helpers).

Best-effort failure paths:
- `jq` missing → `jq_or_skip` returns 1; sibling helpers exit.
- `date` missing or empty → `timestamp_or_skip` returns 1; sibling helpers exit.
- `mkdir` failure → `ensure_log_dir` returns 1; sibling helpers exit.
- `repo_root` empty (no `CLAUDE_PROJECT_DIR`, no git, no `$PWD`) → `repo_root_or_skip` returns 1; sibling helpers exit.
- `shasum` and `sha1sum` both missing → callers that need an args hash produce an empty string (matches `bail-log.sh` line 64-68 behavior). This concern lives in callers, not in the core, because not every channel hashes args.

Differences from `bail-log.sh`: `bail-log.sh` is monolithic — it inlines jq presence, `repo_root`, `mkdir`, timestamp, and `jq -nc | >>` in one function. `retro-events.sh` factors those into named primitives so the three siblings each consist of "validate args + assemble jq filter + call `write_jsonl`". No new error-handling paradigm is introduced; every primitive uses the same `command -v X >/dev/null 2>&1 || return 0` / `... 2>/dev/null || true` pattern bail-log already uses.

### `lib/observations.sh`

Public function:

```
log_harness_observation <component> <outcome> <reason>
```

- `<component>` (required): one of the supported `harness-config.json` identifiers (e.g. `evaluator_per_batch`) or one of the legacy sentinel values produced by Phase 5c (`component_unsupported`, `component_unknown`).
- `<outcome>` (required): a short snake_case label (`unsupported`, `unknown`, `refused`, `cleared`). Used as the `event` field on disk.
- `<reason>` (required, may be empty string): free-text rationale, ≤200 chars recommended.

Internal dependencies: sources `retro-events.sh` (which transitively sources `utils.sh`).

Sourceable + executable dual-mode: same `if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then log_harness_observation "$@"; fi` footer as `bail-log.sh`.

Channel: `docs/retros/harness-observations.jsonl`.

Schema (per-line NDJSON, fields produced by the helper):

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `event` | string | yes | The `<outcome>` argument. |
| `component` | string | yes | The `<component>` argument. |
| `reason` | string | yes (may be `""`) | The `<reason>` argument. |
| `repo_root` | string | yes | From `repo_root_or_skip`. |
| `timestamp` | string | yes | ISO 8601 UTC from `timestamp_or_skip`. |

Best-effort failure path: any primitive in `retro-events.sh` returning 1 → helper returns 0 without writing. No partial lines, no stderr noise.

Differences from `bail-log.sh`: no `args_hash` field (the inputs are short canonical identifiers, not user prose — hashing adds no group-by signal). No `skill` field (the channel is harness-scoped, not skill-scoped — the `component` field carries the disambiguator).

Backward-compatibility caveat: existing rows in `harness-observations.jsonl` written by `executing-plans` Phase 4 and `brainstorming` Phase 2 have a richer schema (`plan`, `batch`, `task_count_in_batch`, `rework_rounds_observed`, `persistent_patterns_detected`, `notes`). Those producers are **out of scope** for this design — they keep writing their existing schema directly (or via a future richer helper). `log_harness_observation` is the **terse-row** path, used only by retrospective Phase 5c for `component_unsupported`/`component_unknown` refusals and the empty-disable cleared-state marker. Phase 1 step 6 already tolerates schema-heterogeneous rows (it filters by `component + retrospective_id`); adding terse rows alongside rich rows is the existing-behavior preserving move.

### `lib/evolution-log.sh`

Public function:

```
log_evolution_event <event_type> <payload_jq_filter> [args...]
```

- `<event_type>` (required): one of `item_added`, `item_removed`, `item_modified`, `item_promoted`, `retrospective_run`, `component_reinstated`.
- `<payload_jq_filter>` (required): a jq object expression like `'{mode: $mode, item_id: $id, ...}'` that produces the event-specific fields. The helper merges this object into the envelope `{event, timestamp, ...payload}` and writes the result.
- `[args...]` (variadic): passed through to `jq -nc` after the helper's own envelope arguments — typically `--arg`/`--argjson` pairs the caller assembles.

Internal dependencies: sources `retro-events.sh`.

Sourceable + executable dual-mode: same footer as `bail-log.sh` and `observations.sh`.

Channel: `docs/retros/evolution-log.jsonl`.

Schema (per-line NDJSON envelope; payload fields depend on `<event_type>`):

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `event` | string | yes | From `<event_type>`. |
| `timestamp` | string | yes | ISO 8601 UTC from `timestamp_or_skip`. |
| ...payload | object | varies | Whatever `<payload_jq_filter>` produces. Existing schemas (per `evolution-protocol.md` lines 80-170) MUST be preserved — the helper is a thin envelope, not a schema validator. |

Best-effort failure path: identical to `observations.sh`. If the caller passes a malformed `<payload_jq_filter>`, `jq -nc` exits non-zero, `write_jsonl` swallows the error via `2>/dev/null`, the file is unchanged.

Differences from `bail-log.sh`: takes a caller-supplied jq object filter instead of a fixed schema. This is required because the evolution log carries five distinct event shapes (`item_added` has `mode`/`item_id`/`description`/`rationale`/`driving_plans`/`checklist_version`/`retrospective_report`; `retrospective_run` has `plans_analyzed`/`report`/`proposals_*`/`disable_test`/`self_value`/`post_plan_diff`; `component_reinstated` has its own evidence sub-object). Forcing a single fixed signature would either bloat the helper or push the per-shape logic back into SKILL.md — neither matches the T-002 goal. The "thin envelope around a caller-built object" pattern is identical to how `jq -n` is already used inline in those SKILL.md bash blocks; the helper just hoists the `jq -nc`-and-append boilerplate.

### `lib/skill-events.sh`

Public function:

```
log_skill_event <skill> <event> <payload_jq_filter> [args...]
```

- `<skill>` (required): the skill identifier, e.g. `systematic-debugging`. snake_case or kebab-case as the skill name is canonically spelled.
- `<event>` (required): the event type within that skill's vocabulary, e.g. `fix_completed`.
- `<payload_jq_filter>` (required): a jq object expression — same role as in `log_evolution_event`.
- `[args...]` (variadic): passed through to `jq -nc`.

Internal dependencies: sources `retro-events.sh`.

Sourceable + executable dual-mode: same footer.

Channel: `docs/retros/skill-events.jsonl` (new in this design).

Schema (per-line NDJSON envelope; payload fields depend on `<skill, event>` pair):

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `event` | string | yes | The `<event>` argument. |
| `skill` | string | yes | The `<skill>` argument. |
| `timestamp` | string | yes | ISO 8601 UTC. |
| ...payload | object | varies | Caller-built. |

`fix_completed` payload (the only emission point this design introduces — `systematic-debugging` Phase 4):

| Payload field | Type | Required | Notes |
|---------------|------|----------|-------|
| `symptom` | string | yes | Truncated `$ARGUMENTS` (≤200 chars). The original user-reported symptom. |
| `root_cause` | string | yes | One-line root cause from Phase 1 evidence, ≤200 chars. |
| `fix_commit` | string | optional | `git rev-parse HEAD` short SHA at Phase 4 close. Empty when not in a git repo. |
| `regression_test_path` | string | yes | Repo-relative path to the test file the fix added or extended. Empty when the deliverable was non-code (rare). |
| `investigation_phase_count` | integer | yes | `1` for bail-out path, `4` for full pipeline, `>4` if any phase was re-entered (e.g. Phase 4 step 4 "Return to Phase 1"). |

Best-effort failure path: identical to siblings.

Differences from `bail-log.sh`: same caller-supplied-payload shape as `evolution-log.sh`. Distinct file from `bail-out-events.jsonl` because the schemas don't overlap (`bail-out-events` is pre-Phase-1; `skill-events` is post-Phase-4) and merging them would corrupt retrospective Phase 5a's aggregation by `(skill, event)`.

Backward-compatibility caveat: this channel is new. The retrospective Phase 1 step 2 surface-only scan (see Integration Points below) is the first consumer; it must tolerate missing file (first-run state) and degrade silently, matching how Phase 1 step 7 handles missing `bail-out-events.jsonl`.

## Data Schemas

Four channels, three of which preexist this design. All under `docs/retros/`, all append-only NDJSON. Field ordering on disk is not normative (consumers parse JSON, not text); the tables below list logical groupings.

### `bail-out-events.jsonl` (preexisting, NOT modified by this design)

Owner: `lib/bail-log.sh`.
Schema: per `bail-log.sh` lines 18-24. Kept verbatim.

### `harness-observations.jsonl` (preexisting; new terse-row producer adds rows alongside existing rich-row producers)

Owners (after this design):
- `executing-plans` SKILL.md Phase 3/4 — rich row (`plan`, `batch`, `task_count_in_batch`, `rework_rounds_observed`, `persistent_patterns_detected`, `notes`). Unchanged.
- `brainstorming` SKILL.md Phase 2 — rich row. Unchanged.
- `lib/observations.sh::log_harness_observation` — terse row (`event`, `component`, `reason`, `repo_root`, `timestamp`). New.

The rich-row schema lives in `executing-plans/references/intra-plan-learning.md` §"Harness Observations Log Schema" and is NOT duplicated here — single source of truth.

Reader contract (retrospective Phase 1 step 6): filters by `component + retrospective_id` first, then per-row JSON-parses each match. Rich rows expose `retrospective_id`; terse rows do not — terse rows are surfaced separately in the Phase 5c context table and do not flow into the promote/reinstate decision.

### `evolution-log.jsonl` (preexisting; new producer is the helper, not a new schema)

Owner (after this design): `lib/evolution-log.sh::log_evolution_event`.

Schemas (per event type — verbatim from `evolution-protocol.md` lines 85-170, reproduced here as the cross-reference for the migration's "no schema change" guarantee):

| Event | Required fields | Optional fields |
|-------|-----------------|-----------------|
| `item_added` / `item_removed` / `item_modified` / `item_promoted` | `event`, `timestamp`, `mode`, `item_id`, `description`, `rationale`, `driving_plans` (array), `checklist_version`, `retrospective_report` | — |
| `retrospective_run` | `event`, `timestamp`, `plans_analyzed` (array), `report`, `proposals_approved`, `proposals_rejected`, `disable_test` (string\|null), `self_value` (object with `proposals_total`, `disable_test_set`, `consecutive_zero_change`) | `post_plan_diff` (object) |
| `component_reinstated` | `event`, `timestamp`, `component`, `previously_disabled_in`, `reinstatement_method`, `evidence` (object), `rationale` | `follow_up` |

Backward compatibility: rows written before this design (with manual `jq -nc ... >> evolution-log.jsonl` blocks) and rows written after (via `log_evolution_event`) MUST be byte-equivalent at the JSON-value level (key order differs harmlessly because `jq -nc` re-serializes). The helper validates nothing — it is a transport, not a schema enforcer. Schema enforcement remains in the retrospective SKILL.md's caller logic (e.g. the Phase 5c refusal gate decides which event to emit; the helper just writes it).

### `skill-events.jsonl` (new in this design)

Owner: `lib/skill-events.sh::log_skill_event`.

Envelope: `{event, skill, timestamp, ...payload}`. The `(skill, event)` pair is the schema key — different `(skill, event)` pairs MAY have completely different payloads. Consumers parse defensively.

Initial `(skill, event)` populated by this design:

| `skill` | `event` | Payload required fields | Payload optional fields |
|---------|---------|-------------------------|-------------------------|
| `systematic-debugging` | `fix_completed` | `symptom`, `root_cause`, `regression_test_path`, `investigation_phase_count` | `fix_commit` |

Future skills MAY add their own `(skill, event)` pairs (e.g. `brainstorming` design-approved, `executing-plans` plan-amended) by calling `log_skill_event` with their own payload filter. No registry, no central schema file — each producing skill documents its payload in its own SKILL.md or references/. Retrospective Phase 1 step 2 is **surface-only** — it lists distinct `(skill, event)` pairs and their counts, never parses the payload.

## Integration Points

### retrospective SKILL.md Phase 5c — migrate to `log_harness_observation`

**Current state** (SKILL.md line 146): the CRITICAL refusal gate is described in prose with an inline JSON template. The bash to append the line is not literal — Claude is expected to construct the `jq -nc` invocation per-run.

**After migration**: the prose template is replaced by:

```
bash "${CLAUDE_PLUGIN_ROOT}/lib/observations.sh" \
  <component-identifier> component_unsupported "<short reason>"
```

(Diff is conceptual — the actual edit replaces the inline schema sentence and surrounding bash hint with one helper invocation. The schema lives in `observations.sh` and is documented in §Components above.)

Two additional sub-cases land in this migration:

- `component_unknown` (Phase 5c step 1, line 150): `bash ".../observations.sh" <id> component_unknown "<reason>"`.
- `cleared` marker when Phase 5c writes an empty `disabled_components[]` to close a test (Phase 5c "If no candidate is selected this run", line 159): optional — current behavior writes only to `harness-config.json`. This design does NOT add a `cleared` observation row; doing so would change the Phase 1 step 6 reader's expected row count and risks a calibration-loop regression. Deferred to a separate design.

Rationale: keeping the migration line-level reduces blast radius. The Phase 5c refusal gate is the highest-risk piece of the retrospective skill (it's the one referenced by name in `feedback_skill_level_enforcement.md` as the canonical example of "L2 CRITICAL marker must survive refactor").

### retrospective SKILL.md Phase 4 step 3 (proposal events) — migrate to `log_evolution_event`

**Current state** (SKILL.md line 104): "Append one JSON object per approved proposal to `docs/retros/evolution-log.jsonl`. See `./references/evolution-protocol.md` for schema." The actual `jq -nc ... >>` is Claude-constructed per-proposal at runtime.

**After migration**: SKILL.md line 104 changes to call:

```
bash "${CLAUDE_PLUGIN_ROOT}/lib/evolution-log.sh" \
  item_added '{mode: $mode, item_id: $id, description: $d, rationale: $r,
               driving_plans: $plans, checklist_version: $v,
               retrospective_report: $report}' \
  --arg mode "$MODE" --arg id "$ITEM_ID" --arg d "$DESC" \
  --arg r "$RATIONALE" --argjson plans "$PLANS_JSON" \
  --arg v "$VERSION" --arg report "$REPORT"
```

(Same structural change for `item_removed`, `item_modified`, `item_promoted`.)

### retrospective SKILL.md Phase 6 closure (retrospective_run + component_reinstated) — migrate to `log_evolution_event`

**Current state** (SKILL.md lines 176-191): the `retrospective_run` event is specified as a JSON literal with computed `consecutive_zero_change`. The `component_reinstated` veto event is similarly described in `evolution-protocol.md`.

**After migration**: both events are emitted via `log_evolution_event retrospective_run '{...}' --argjson ...` and `log_evolution_event component_reinstated '{...}' --argjson ...`. The `consecutive_zero_change` computation (read previous event, compute, pass as `--argjson`) stays in SKILL.md — that is calibration-loop logic, not transport.

### retrospective SKILL.md Phase 1 step 2 — new surface-only scan of `skill-events.jsonl`

**Current state**: no awareness of skill-events.

**After migration**: Phase 1 gains a new sub-step (numbered after step 7 to preserve existing numbering; final step number lands during executing-plans):

> Read `docs/retros/skill-events.jsonl` if present. Group rows by `(skill, event)`; for each group, count rows since the most recent `retrospective_run` timestamp. **Surface-only**: render the table in the Phase 6 report under "Skill Event Activity". Do NOT include these counts in RETROSPECTIVE DUE thresholds — those remain driven by `plans-completed.jsonl`. Skip silently when the file does not exist.

This step is explicitly informational. Promoting it to DUE-counting requires evidence that `fix_completed` rates correlate with retrospective value — that evidence does not yet exist, so the surface-only constraint is the safe initial state. A future retrospective MAY graduate the count via the standard Phase 3 MODIFY proposal flow.

### systematic-debugging SKILL.md Phase 4 — new emission point for `log_skill_event`

**Suggested location**: end of Phase 4 step 3 ("Verify Fix"), only on the success branch (test passes, no other tests broken, issue resolved). NOT on the failure branch (Phase 4 step 4 "If Fix Doesn't Work" loops back to Phase 1 — no `fix_completed` is emitted until a later iteration succeeds).

**Suggested invocation** (concrete shape, not literal code):

```
bash "${CLAUDE_PLUGIN_ROOT}/lib/skill-events.sh" \
  systematic-debugging fix_completed \
  '{symptom: $sym, root_cause: $rc, fix_commit: $sha,
    regression_test_path: $test, investigation_phase_count: $count}' \
  --arg sym "<truncated $ARGUMENTS>" \
  --arg rc "<one-line root cause>" \
  --arg sha "<git rev-parse HEAD short>" \
  --arg test "<repo-relative test path>" \
  --argjson count <1|4|N>
```

The emission is **best-effort** — Phase 4 success criteria (bug resolved, test passes) MUST hold regardless of whether the helper writes the line. Phase 1/2/3 explicitly do NOT emit `skill-events` lines; per-phase events would inflate the channel without a current consumer.

The bail-out path (Iron-Law-CRITICAL section, lines 19-53) also produces a `fix_completed`-eligible outcome: the user named the root cause and the fix was applied directly. The bail-out path MUST emit `fix_completed` with `investigation_phase_count = 1` — this is the only way the calibration loop sees whether bail-outs are landing successful fixes. The existing `bail-out-events.jsonl` row is independent (it records the gate firing, not the fix completion); the new `fix_completed` row records the outcome.

### `allowed-tools` field updates

Both consuming SKILL.md files need `Bash(${CLAUDE_PLUGIN_ROOT}/lib/...:*)` entries added to their `allowed-tools` arrays:

- `retrospective/SKILL.md`: add `Bash(${CLAUDE_PLUGIN_ROOT}/lib/observations.sh:*)` and `Bash(${CLAUDE_PLUGIN_ROOT}/lib/evolution-log.sh:*)`.
- `systematic-debugging/SKILL.md`: add `Bash(${CLAUDE_PLUGIN_ROOT}/lib/skill-events.sh:*)`.

`retro-events.sh` is not directly invocable by skills and does not need an `allowed-tools` entry.

## Migration Strategy

Sequential — each step's tests must pass before the next step begins.

1. **Land `lib/retro-events.sh`** with the six primitives. Standalone tests: `jq_or_skip` under jq-present and (mocked) jq-absent paths, `repo_root_or_skip` under each of the three resolution branches, `dedup_check` against a synthesized log file. No SKILL.md changes yet.

2. **Land `lib/observations.sh`** sourcing the core. Standalone tests: append a `component_unsupported` row, verify NDJSON validity via `jq -e .`. No SKILL.md changes yet.

3. **Land `lib/evolution-log.sh`** sourcing the core. Standalone tests: append one row per event type from the schema table, verify field set matches existing schema verbatim. No SKILL.md changes yet.

4. **Land `lib/skill-events.sh`** sourcing the core. Standalone tests: append a `fix_completed` row with all required payload fields, verify envelope shape.

5. **Migrate retrospective SKILL.md Phase 4 step 3** (`item_*` events) to call `log_evolution_event`. Snapshot test: run the retrospective skill against a fixture plan dir, diff the resulting `evolution-log.jsonl` against a pre-migration golden file — fields must be identical (key order differences allowed).

6. **Migrate retrospective SKILL.md Phase 6 closure** (`retrospective_run` and `component_reinstated`). Snapshot test as above. This step is split from step 5 because `retrospective_run`'s `consecutive_zero_change` computation is the riskiest single line in the migration; isolating it makes bisection trivial.

7. **Migrate retrospective SKILL.md Phase 5c refusal gate** (`component_unsupported` and `component_unknown`) to call `log_harness_observation`. Snapshot test: feed a refused identifier (e.g. `context_reset_coordinator`), verify the resulting terse row matches the new schema and the existing rich rows from `executing-plans` are untouched.

8. **Add systematic-debugging SKILL.md Phase 4 emission point**. Test: run the skill against a fixture bug, verify a `fix_completed` row lands and the bug fix itself is unaffected. Also test the bail-out path produces a `fix_completed` row with `investigation_phase_count=1`.

9. **Add retrospective SKILL.md Phase 1 step 2 surface-only scan**. Test: with `skill-events.jsonl` present and absent, verify the Phase 6 report renders the activity table or omits it cleanly.

10. **Update `allowed-tools` arrays in both SKILL.md files**.

**Backward compatibility guarantees:**

- No existing line in any of the four channels is rewritten, deleted, or migrated. Pre-migration rows continue to be readable by the unchanged Phase 1 step 5/6/7 readers.
- The new helper output is byte-comparable (modulo jq's stable key ordering) to the pre-migration manual `jq -nc` output, because the helper IS `jq -nc` plus an envelope.
- Mixed-mode logs (some rows written manually pre-migration, some via helper post-migration) MUST round-trip through every existing reader. Snapshot tests in steps 5-8 verify this.

**Rollback path:**

If any helper bug causes a write failure, the producing skill behavior degrades to "no row appended" — identical to running on a machine without `jq`, which the existing readers all handle (Phase 1 step 7 says "Skip silently when the file does not exist (first-run state)" — missing rows look the same as missing file from the reader's perspective). Calibration-loop signal is temporarily noisier (one missing data point), the skill itself never fails. This is the same "best-effort never blocks" contract `bail-log.sh` has carried in production since v2.8.0.

If a helper write succeeds but produces a malformed row, downstream readers (Phase 1 steps 5/6/7) use `jq` with `try/catch` (existing pattern, see evolution-protocol.md line 216 "uses jq with `try/catch` so a single corrupt prior line does not disable the gate"). A single bad row is tolerable; systematic bad rows are caught by the snapshot tests in steps 5-9 before the migration ships.

## Dependency Graph

```
systematic-debugging SKILL.md ──(Phase 4)──→ lib/skill-events.sh ──┐
retrospective SKILL.md ────(Phase 5c)──→ lib/observations.sh ──────┤
retrospective SKILL.md ────(Phase 4/6)─→ lib/evolution-log.sh ─────┤
                                                                    ▼
                                                       lib/retro-events.sh
                                                                    │
                                                                    ▼
                                                          lib/utils.sh::repo_root
```

No new external dependencies. The full runtime requirement set remains: `bash`, `jq`, `date`, plus `shasum` OR `sha1sum` (only consumed by `bail-log.sh`; the three new helpers do not hash). `perl` is required by `utils.sh` for transcript parsing but is not on any code path reached by the new helpers — they consume only `repo_root()` from `utils.sh`, which is `perl`-free.

## Out of Scope

The following are explicitly NOT part of this design and remain on TODO-v3 or successor designs:

- Retrofitting `bail-log.sh` to source `retro-events.sh`. Symmetry would be nice; risk of churning the most battle-tested helper in the lib for zero functional gain is not.
- Promoting the rich-row producers in `executing-plans` Phase 3/4 and `brainstorming` Phase 2 to a richer helper. Their inline `jq -nc` blocks are stable and the schemas have distinct shapes per producer; collapsing them is a separate cleanup.
- Adding a `cleared` marker row when Phase 5c closes a disable test. Discussed in §Integration Points; deferred for calibration-loop safety.
- Graduating `skill-events.jsonl` counts into RETROSPECTIVE DUE threshold logic. Requires correlational evidence not yet present.
- A `log_plan_completion` helper for `plans-completed.jsonl`. That channel is already lib-shipped (`loop.sh::_loop_log_plan_completion_if_executing`); promoting it to the shared core is a third successor-design item if a fifth channel ever appears.
