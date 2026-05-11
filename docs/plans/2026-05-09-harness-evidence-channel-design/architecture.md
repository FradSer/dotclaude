# harness-evidence channel — architecture

## A. lib/harness-evidence.sh interface

**File**: `superpowers/lib/harness-evidence.sh` (new, sibling to `bail-log.sh`, `post-plan-diff.sh`, `loop.sh`).

**Critical posture**: zero LLM calls inside this file. All distillation happens at retrospective Phase 1 step 8 via `utils.sh::run_haiku_merge`. The writer is a path-only NDJSON appender.

**Header conventions** (mirror `post-plan-diff.sh:1-33`):
- Sourceable + executable dual mode via `BASH_SOURCE[0] != $0` guard at tail (pattern from `bail-log.sh:66-68`, `post-plan-diff.sh:154-164`)
- No top-level `set -e` — sourcing must not perturb caller's regime
- Best-effort throughout: missing `jq` / missing `git` / unwritable `docs/retros/` — all fall through to `return 0`
- Recursion guard: `[[ "${SUPERPOWERS_SUBSESSION:-}" == "1" ]] && return 0` at the top of `emit_session_recap`
- Path resolution: call `utils.sh::repo_root` (recommended — extract `loop.sh:57-66`'s inline pattern into `utils.sh` during implementation; per `TODO-v3.md` T-001 this is the third would-be copy and meets the rule-of-three promotion bar)

### Function declarations

```
# Resolve the writable root for harness-evidence.jsonl. RECOMMENDED:
# call utils.sh::repo_root (the shared helper extracted at implementation
# time per TODO-v3.md T-001). If T-001 is not yet acted on at implementation,
# inline `git rev-parse --show-toplevel` with $PWD fallback (matches loop.sh:57-66).
# Echoes the resolved path; never errors.
_harness_evidence_root()

# Echo "<root>/docs/retros/harness-evidence.jsonl" and ensure the parent
# directory exists. mkdir -p ... 2>/dev/null || return 1. When create
# fails, caller skips the write entirely. Mirrors bail-log.sh:39-41.
_harness_evidence_path()

# Append a single NDJSON line to the channel. Best-effort, never blocks.
# IMPLEMENTATION: bare `>> "$path" 2>/dev/null || true` — NOT flock.
# Justification:
#   1. Existing siblings (bail-log.sh:61, loop.sh:112) all use bare >>.
#   2. Each emit is one O_APPEND-atomic write of a sub-PIPE_BUF row
#      (≤ ~1.2 KB on POSIX, well under 4 KiB atomicity guarantee).
#   3. utils.sh::acquire_state_lock is reserved for state-file
#      tmp+mv cycles, not append-only logs.
_harness_evidence_append <json_line>

# Emit one event=session_recap row. PATH-ONLY WRITER — no LLM call.
# Empty-session filter (REQ-002):
#   task == "" AND modified_files == [] AND pending_prompt == "" → return 0
# Composes the row from already-derived state:
#   recap_one_sentence    = state.task verbatim (vet.sh's Haiku-produced
#                           one-sentence summary; never recomputed)
#   last_assistant_tail   = transcript-tail extracted by stop-hook.sh,
#                           truncated to first 500 BYTES via "${var:0:500}"
#                           slice (matches vet.sh:75); empty when absent
#   modified_files        = state.modified_files (track-changes.sh
#                           accumulator, paths only)
# `event` field is hardcoded inside the function body. This function
# does NOT accept an --event arg. (REQ-001 + REQ-012 enforcement.)
emit_session_recap <state_file> [<last_assistant_tail>]

# CLI entry for the v3_friction event. Schema fields verbatim from v3
# retro §4 condition 2 (class / description / could_phase_0_handle /
# workaround_used) plus wrapper fields. Validates class enum against
# {between_plan, ai_dialogue, external, cross_project}. Missing required
# field or invalid enum → exit 2, write nothing.
# `event` field is hardcoded inside the function body.
# Usage:
#   bash harness-evidence.sh emit-v3-friction --class <enum>
#     --description "..." --could-phase-0-handle <true|false>
#     --workaround-used "..."
emit_v3_friction <args>

# Emit one event=file_change_summary row at plan completion. Path-only
# (no diff content, no classify pre-stored). Reader (retrospective Phase
# 1 step 8) reconstructs classify by calling post-plan-diff.sh classify
# per file as needed. Reads .modified_files from state, dedupes, emits
# {path}-only objects. Empty paths → exit 2, write nothing.
# `event` field is hardcoded inside the function body.
emit_file_change_summary <state_file> <completion_commit>

# Audit retract triggers — REQ-005 + REQ-009. Independent of retrospective.
# Reads harness-evidence.jsonl and the project's retro reports;
# emits one stderr line per fired trigger; exits 0 if none fire, 1 if any.
# Triggers checked:
#   T3 calendar:   today (or HARNESS_EVIDENCE_NOW) ≥ 2027-05-09
#   T4 read-rate:  no retro report in last 30 days contains the literal
#                  substring "harness-evidence"
# T5 (writer-reliability) does NOT exist — the writer no longer has a
# fallible LLM path.
# Allowlist invariant check (REQ-011): `jq -r .event harness-evidence.jsonl
#                                       | sort -u` is a subset of
#                                       {file_change_summary, session_recap,
#                                        v3_friction}. Non-subset → exit 2
#                                       with "allowlist violation".
# Usage:
#   bash harness-evidence.sh audit
# Output (when triggers fire, one per line, stderr):
#   harness-evidence T3 age-out reached, AskUserQuestion to confirm retract
#   harness-evidence T4 read-rate trigger, AskUserQuestion to confirm retract
#   harness-evidence allowlist violation: unexpected event(s) <list>
harness_evidence_audit
```

### CLI dispatcher (mirrors `post-plan-diff.sh:154-164`)

```
case "${1:-}" in
  emit-session-recap)        shift; emit_session_recap "$@" ;;
  emit-v3-friction)          shift; emit_v3_friction "$@" ;;
  emit-file-change-summary)  shift; emit_file_change_summary "$@" ;;
  audit)                     shift; harness_evidence_audit "$@" ;;
  *)
    echo "usage: harness-evidence.sh {emit-session-recap <state_file> [tail] | emit-v3-friction --class <enum> --description ... --could-phase-0-handle <true|false> --workaround-used ... | emit-file-change-summary <state_file> <commit> | audit}" >&2
    exit 2
    ;;
esac
```

The dispatcher exposes exactly 4 verbs. There is no `--event` argument anywhere; the `event` JSON field is hardcoded inside each emit function. Lifting the 3-event lock requires editing both the dispatcher table and the per-function literal — this two-site change is the structural choke that REQ-011/REQ-012 rely on.

### Allowlist constant (REQ-011, REQ-012)

```
# Single source of truth for the harness-evidence event allowlist.
# Adding a 4th value here REQUIRES updating both:
#   1. tests/test_harness_evidence_sh.py::HarnessEvidenceSchemaTests::
#      test_event_type_allowlist (assertEqual string-equality)
#   2. A fresh brainstorm cycle producing an explicit waiver design doc
# Do not edit this constant casually — it is the architectural lock.
HARNESS_EVIDENCE_EVENT_ALLOWLIST="file_change_summary session_recap v3_friction"
```

### Error path matrix

| Failure | Handler |
|---|---|
| `git rev-parse` non-zero | `_harness_evidence_root` falls back to `$PWD` |
| `mkdir -p docs/retros` fails (read-only fs) | `_harness_evidence_path` returns 1; emit functions check `[[ -z "$path" ]]` and `return 0` |
| Disk full / `>>` fails | `_harness_evidence_append` already has `\|\| true` |
| `jq` missing | First-line `command -v jq >/dev/null 2>&1 \|\| return 0` |
| Corrupted state file JSON | `state_read` already returns "" on failure; empty-session filter trips → `return 0` |
| Audit reads a row with unknown `event` value | `harness_evidence_audit` exits 2 with "allowlist violation: <values>" — a regression-net, since reaching this state means an out-of-band write happened |
| Audit invoked with no retros directory yet | T4 trigger does not fire (0/0 ratio undefined); allowlist check still runs against empty file (always passes) |

## B. stop-hook.sh integration patch

**Location**: `superpowers/hooks/stop-hook.sh`, between `loop_phase` return (line 55) and `vet_phase` (line 58).

**Order rationale**:
1. **Loop first** (unchanged) — `loop_phase` either `exit 0`s (mid-iteration) or returns to fall through. Evidence emit is meaningless mid-loop iteration; only end-of-session.
2. **Evidence between loop and vet** — `emit_session_recap` reads state but does not mutate it. Critically must run BEFORE `vet_phase` because `vet_phase` may `exit 0` early (need_vet not set, line 137-139) without falling through to a "post-vet" hook.
3. **Last-assistant tail extraction**: the writer accepts an optional second arg; stop-hook.sh extracts it via `extract_last_assistant_text "$TRANSCRIPT_PATH" 100` (existing helper, `utils.sh:218`) and passes it. The emit function does its own 500-byte truncate before composing the row.
4. **`emit_file_change_summary`** runs from a different code path: only when a plan completes. Call site is **inside `_loop_log_plan_completion_if_executing`** (`superpowers/lib/loop.sh:32-113`), specifically after the `jq -nc ... >> "$log_file"` line at `loop.sh:103-112` (the `plan_completed` event append). Same `completion_commit` and `modified_files_json` already in scope:
   ```
   bash "${SCRIPT_DIR}/../lib/harness-evidence.sh" emit-file-change-summary \
        "$state_file" "$completion_commit" 2>/dev/null || true
   ```
   `SCRIPT_DIR` resolves to stop-hook.sh's directory.

**Failure containment**:
- `stop-hook.sh` runs under `set -euo pipefail` (line 14). New emit call MUST be wrapped: `emit_session_recap "$STATE_FILE" "$LAST_ASSISTANT_TAIL" 2>/dev/null || true`. Unhandled non-zero would abort before `vet_phase` runs and break verification. The `|| true` guarantees the stop hook still vets when disk/git/jq fails.
- `|| true` matches `bail-log.sh:61` and `loop.sh:112` precedent.

**Latency budget (REQ-007)**: ≤ 20 ms p95 added to non-empty Stop hooks. Operations: one `state_read` (jq), one `extract_last_assistant_text` (already done if vet_phase needs it — can be hoisted), one in-memory truncate, one `jq -n` to compose the row, one `>>` append. Empty sessions skip after the first state read (≤ 2 ms). **No fork to `claude`, no network, no streaming.** This is upper-bounded by `bail-log.sh`'s measured behavior (one jq + one append) and is intentionally indistinguishable from sibling channel writes in cost.

## C. retrospective SKILL.md integration

**Phase 1 reader insertion** — between current step 7 (bail-out events, `superpowers/skills/retrospective/SKILL.md:61`) and step 8 (post-plan diff, `SKILL.md:62`).

Insert as **step 8** (renumber existing 8 → 9, 9 → 10):

> **8. Read harness-evidence channel** (covers REQ-004): If `docs/retros/harness-evidence.jsonl` exists, filter rows by `timestamp > <last evolution-log.jsonl retrospective_run.timestamp>`. Bucket by `event`:
> - `v3_friction` rows → pass through to **Phase 5a** verbatim for read-rate calibration; do NOT modify `class` / `description` / `could_phase_0_handle` / `workaround_used` fields
> - `session_recap` rows → aggregate all N rows in the window into one prompt (concatenated `recap_one_sentence` + `last_assistant_tail` per row, separated by `---`), then distill via a single `lib/utils.sh::run_haiku_merge` call. See `./references/harness-evidence.md` for the merge prompt. **One LLM call per retrospective run**, never per row.
> - `file_change_summary` rows → for any row with `completion_commit` not present in `plans-completed.jsonl` (cross-channel correlation), surface as "untracked completion" — typically means a Stop hook fired without the loop hook detecting plan completion
>
> Skip silently when the file does not exist (first-retrospective state).
>
> **Retract trigger detection** (covers REQ-005, REQ-009): Phase 1 step 8 shells out to `bash superpowers/lib/harness-evidence.sh audit` and parses the stderr output. Trigger lines are surfaced into the retro report under Phase 6 / "4.5d Retract trigger markers". When multiple triggers fire, emit one coalesced AskUserQuestion listing all reasons. **Reading and detection are the same path**; both retrospective and ad-hoc CLI use the same audit logic.
>
> The `audit` shell-out has no data dependency on the Haiku distill — implementation may run both concurrently (e.g., `audit ... &` then `wait`) since `audit` is local-only (`jq` + `grep`) and Haiku is network-bound. Defer the actual parallelization to the implementation plan only if measured audit latency exceeds ~50 ms.

**Filter logic** (mirrors step 7 bail-out — read all rows, in-process timestamp filter):
```
last_ts=$(jq -r 'select(.event=="retrospective_run") | .timestamp' \
           docs/retros/evolution-log.jsonl | tail -1)
jq -c --arg ts "$last_ts" 'select(.timestamp > $ts)' \
        docs/retros/harness-evidence.jsonl
```
Empty `last_ts` → no filter applied, read all rows. First-retrospective semantics.

**Distill model: Haiku, single call.**
- Each `session_recap` row stores raw inputs (state.task verbatim — a 1-sentence Haiku summary already — plus the last-assistant tail truncated to 500 bytes). No write-time LLM call exists.
- Phase 1 step 8 calls `run_haiku_merge` exactly once per retrospective run with all N rows concatenated.
- Token estimate: 10 rows × ~600 bytes = ~1.5K input + ~300 output. Haiku territory by a wide margin.
- Established asymmetry preserved: vet.sh and harness-evidence distill use Haiku; evaluator uses Sonnet. No Sonnet anywhere near the Stop-hook critical path.

**Failure path**: `run_haiku_merge` returns "" on any failure (utils.sh:268). Reader falls back to emitting up to 5 verbatim `recap_one_sentence` strings as a "raw evidence dump" sub-section instead of distilled prose. Phase 1 step 8 still exits 0; retrospective is not blocked.

**Distill output format**: inject under a new "4.5 Harness Evidence" sub-section in the retrospective report (Phase 6 in `SKILL.md:163-175`):
- 4.5a `session_recap` distillation: 1-paragraph Haiku merge over the window (or raw evidence dump on Haiku failure)
- 4.5b `v3_friction` list: one row per event (verbatim — class / description / workaround_used), feeds meta-retrospective gate condition 2
- 4.5c `file_change_summary` untracked-completion warnings (if any)
- 4.5d Retract trigger markers from `audit` CLI (T3 / T4 only; T5 retired)

## D. v3 retro reconciliation patches

**File**: `/Users/FradSer/Developer/FradSer/dotclaude/docs/retros/2026-05-09-v3-considered-deferred.md`

| Line | Old | New |
|---|---|---|
| 26 | `...collect friction points in \`docs/retros/v3-evidence.jsonl\` as real-data basis...` | `...collect friction points in \`docs/retros/harness-evidence.jsonl\` (event=v3_friction) as real-data basis...` |
| 61 | full paragraph specifying schema and `v3-evidence.jsonl` path | rewritten paragraph: "**`docs/retros/harness-evidence.jsonl`** in each project records concrete friction points (event=`v3_friction`) the user encountered that v3.x would have addressed — at least one per project, append-only via `lib/harness-evidence.sh emit-v3-friction`. Schema unchanged from the original v3 retro (class / description / could_phase_0_handle / workaround_used) plus standard wrapper fields (schema_version, timestamp, git_root, session_id, skill_name)." |
| 65 | "**Gate-trigger note (critical)**: condition 2 references \`v3-evidence.jsonl\` as a channel that does not exist..." | "**Gate-trigger note (historical)**: condition 2 originally referenced a `v3-evidence.jsonl` channel with no shipped writer. As of the 2026-05-09 follow-on design (`docs/plans/2026-05-09-harness-evidence-channel-design/`), the channel ships as `lib/harness-evidence.sh` writing `docs/retros/harness-evidence.jsonl`. Condition 2 is now triggerable; condition 4 (meta-retrospective skill) remains un-triggerable." |
| 67 | "...sub-agents in a fresh brainstorming session re-examine the §2 scope against the v3-evidence corpus..." | "...sub-agents in a fresh brainstorming session re-examine the §2 scope against the harness-evidence corpus (filtered to event=v3_friction)..." |
| 99 | T1 row: "...\`docs/retros/v3-evidence.jsonl\` across ≥3 projects + meta-retrospective skill emit" | T1 row: "...`docs/retros/harness-evidence.jsonl` (event=v3_friction) across ≥3 projects + meta-retrospective skill emit" |

§4 condition 2 schema body itself is preserved verbatim — `harness-evidence.sh emit-v3-friction` writes the exact same fields. Only file path string and "un-triggerable" framing change.

§7 audit trail addendum (append at end):
> - 2026-05-09: condition-2 channel designed and shipped as `harness-evidence.jsonl`. v3.x activation gate's condition 2 is now structurally satisfiable; conditions 1, 3, 4 remain open (see §7 ownership table).
> - 2026-05-10 (post round-1 evaluation pivot): design rewritten to remove Sonnet from the Stop-hook critical path. Writer is now path-only NDJSON append (≤ 20 ms p95). Distill happens at retrospective Phase 1 step 8 via one `run_haiku_merge` call per run. T5 (writer-reliability) trigger and `fallback=true` field were retired with the Sonnet removal. Audit CLI subcommand added so retract triggers fire without depending on retrospectives being run.
> - 2026-05-09 follow-on (brainstorming reform): four downstream brainstorming SKILL.md changes recorded in `docs/plans/2026-05-10-brainstorming-vocab-reform-retro.md`, not bundled into this PR.

## E. Path resolution: $PWD vs git_root

**The drift**:
- `bail-log.sh:39` — `local log_dir="${PWD}/docs/retros"` (CWD-anchored)
- `loop.sh:57-66` — `git rev-parse --show-toplevel`, falls back to `$PWD`, derives `repo_root/docs/retros` (git-anchored)

**`harness-evidence.sh` follows `loop.sh`** — git-anchored with `$PWD` fallback. Rationale:
- Retrospective reads `<repo_root>/docs/retros/*.jsonl` — git-anchored is the consumer contract
- session_recap writes can fire from any subdir; `$PWD` would scatter recaps across multiple `docs/retros/` directories if user `cd`s mid-session
- `loop.sh` has the right precedent — same hook chain (Stop), same JSONL target dir, same retrospective reader

**`bail-log.sh` divergence**: not fixed in this PR. Tracked in `superpowers/TODO-v3.md` as a single-source debt item; do not restate the rationale in multiple design docs. Header comment in `harness-evidence.sh` cites `loop.sh` as the canonical precedent and links to `TODO-v3.md` instead of carrying the divergence explanation inline.

## F. Test scaffolding

**File**: `superpowers/tests/test_harness_evidence_sh.py` (new, mirrors `test_bail_log_sh.py` shape).

Target shape: ~14 cases mapped 1:1 to bdd-specs.md scenarios. Parametrize across rows where the assertion is identical — e.g., "all 3 event types carry schema_version=1" is one parameterized case, not three.

Test classes:
- **`HarnessEvidenceWriterTests`** — covers all 3 emit verbs (Executed + Sourced merged via class-level setUp toggle)
  - `test_emit_session_recap_writes_required_fields` — REQ-001, REQ-002
  - `test_emit_session_recap_skipped_when_all_inputs_empty` — REQ-002
  - `test_emit_session_recap_truncates_last_assistant_tail_to_500_bytes` — REQ-002
  - `test_emit_v3_friction_validates_class_and_required_fields` — REQ-001 (parameterized: missing-description, invalid-class)
  - `test_emit_file_change_summary_writes_paths_only` — REQ-001, REQ-003 (parameterized: with paths, empty paths rejects)
  - `test_session_recap_recap_one_sentence_copied_from_state_task_verbatim` — REQ-002
- **`HarnessEvidenceDispatcherTests`** — covers the architectural lock
  - `test_cli_exposes_exactly_four_verbs` — REQ-001 (string equality on usage line)
  - `test_no_event_flag_accepted_anywhere` — REQ-001 + REQ-012 (passing `--event ad_hoc` exits 2)
- **`HarnessEvidenceGitRootTests`** — path resolution
  - `test_uses_git_root_not_pwd_when_in_repo` — REQ-001 path contract
  - `test_falls_back_to_pwd_when_not_in_repo`
- **`HarnessEvidenceDegradationTests`** — robustness
  - `test_silent_skip_when_jq_missing` — REQ-001 best-effort
  - `test_disk_full_does_not_corrupt_existing_lines` — REQ-008
  - `test_concurrent_writes_no_interleaving` — REQ-008 atomicity
- **`HarnessEvidenceSchemaTests`** — schema invariants
  - `test_all_events_carry_required_wrapper_fields` — REQ-001, REQ-006 (parameterized over the 3 event types)
  - `test_event_allowlist_constant_string_equality` — REQ-011, REQ-012 (asserts the bash constant matches `{file_change_summary, session_recap, v3_friction}` literally; the CI choke-point per Rationale row C)
- **`HarnessEvidenceAuditTests`** — covers REQ-009 audit subcommand
  - `test_audit_exit_zero_when_no_triggers` — REQ-009
  - `test_audit_t3_calendar` — REQ-005 (uses `HARNESS_EVIDENCE_NOW=2027-05-09T00:00:00Z`)
  - `test_audit_t4_read_rate` — REQ-005 (pre-populates 30 days of retros without the substring)
  - `test_audit_detects_allowlist_violation` — REQ-011, REQ-012 (smuggles `event="ad_hoc_capture"` in directly; audit exits 2)

**Test override env vars**:
- `HARNESS_EVIDENCE_NOW=<ISO8601>` → freezes the audit's notion of "now" for retract-trigger tests
- No `HARNESS_EVIDENCE_SKIP_SONNET` — writer no longer calls Sonnet, the override is moot

**Integration**: `tests/test_phase_integration.py` adds:
- `test_stop_hook_writes_session_recap_then_retro_consumes_it` — full Stop → Phase 1 step 8 cycle (one Haiku call merged across rows)
- `test_audit_cli_callable_outside_retrospective` — REQ-009 independent surface
- `test_triggers_coalesce_into_single_askuserquestion` — multiple triggers fire → one prompt

**Removed tests (vs. pre-pivot scaffolding)**:
- `test_silent_skip_when_claude_cli_missing` — no claude call at write time
- `test_sonnet_failure_writes_fallback_row` — no fallback path exists
- `test_t5_writer_reliability_marker` — T5 retired
- Sourced-mode duplicates merged into `HarnessEvidenceWriterTests` via parameterized setUp

**LLM-touching tests deliberately not included**:
- Haiku distill quality at read-time (subjective, not regression risk; reader degrades to raw evidence dump on Haiku failure, which is the testable invariant)
- Real `claude` CLI invocation (network dependency, flaky CI)
- `AskUserQuestion` rendering (skill-instruction layer, not lib layer)
