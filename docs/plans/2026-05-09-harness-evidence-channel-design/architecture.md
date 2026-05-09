# harness-evidence channel — architecture

## A. lib/harness-evidence.sh interface

**File**: `superpowers/lib/harness-evidence.sh` (new, sibling to `bail-log.sh`, `post-plan-diff.sh`, `loop.sh`).

**Header conventions** (mirror `post-plan-diff.sh:1-33`):
- Sourceable + executable dual mode via `BASH_SOURCE[0] != $0` guard at tail (pattern from `bail-log.sh:66-68`, `post-plan-diff.sh:154-164`)
- No top-level `set -e` — sourcing must not perturb caller's regime
- Best-effort throughout: missing `jq` / missing `git` / missing `claude` CLI / unwritable `docs/retros/` / Sonnet timeout — all fall through to `return 0`
- Recursion guard: `[[ "${SUPERPOWERS_MERGE_SESSION:-}" == "1" ]] && return 0` at the top of `emit_session_recap` and `_run_sonnet_recap` (matches the Haiku merge pattern in `utils.sh:260`)
- Header comment must cite `loop.sh` as the canonical path-resolution precedent and document why `bail-log.sh`'s `$PWD` is not followed

### Function declarations

```
# Resolve the writable root for harness-evidence.jsonl. Prefers
# `git rev-parse --show-toplevel` (matches loop.sh:57). Falls back to
# $PWD when not in a repo so the writer still exits 0 in scratch dirs.
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

# Emit one event=session_recap row. Reads from state file, no-ops on
# empty session, calls Sonnet for the recap paragraph, appends NDJSON.
# Empty-session filter (REQ-002):
#   task == "" AND modified_files == [] AND pending_prompt == "" → return 0
# When the filter passes:
#   recap_one_sentence is read VERBATIM from state.task (vet.sh already
#     wrote that one-sentence summary via _vet_synthesize_final_task —
#     never recompute, never re-call Haiku)
#   modified_files comes from state.modified_files (track-changes.sh
#     accumulator, paths only)
#   recap_paragraph is the _run_sonnet_recap return; on empty (Sonnet
#     failed) write a row with fallback=true and recap_paragraph =
#     state.task verbatim (REQ-009)
emit_session_recap <state_file>

# CLI entry for the v3_friction event. Schema fields verbatim from v3
# retro §4 condition 2 (class / description / could_phase_0_handle /
# workaround_used) plus wrapper fields. Validates class enum against
# {between_plan, ai_dialogue, external, cross_project}. Missing required
# field or invalid enum → exit 2, write nothing.
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
emit_file_change_summary <state_file> <completion_commit>

# Sonnet caller — sourceable, mirrors run_haiku_merge (utils.sh:254-271).
# Differences:
#   model:    claude-sonnet-4-6 (NOT claude-haiku-4-5-20251001)
#   prompt:   tuned for 200-500 word recap paragraph
#   timeout:  8s (REQ-009 reliability ceiling)
# Same guards: SUPERPOWERS_MERGE_SESSION=1 export before claude --bare,
# so recursion guards in stop-hook.sh:17 / task-start.sh:20 / track-
# changes.sh:15 short-circuit the sub-session.
# Returns empty string on any failure — caller decides fallback.
# Test override: HARNESS_EVIDENCE_SKIP_SONNET=1 short-circuits the call
# (returns "" without invoking claude). Used by test_harness_evidence_sh.py
# to avoid network dependency.
_run_sonnet_recap <task> <prompt> <last_assistant>
```

### CLI dispatcher (mirrors `post-plan-diff.sh:154-164`)

```
case "${1:-}" in
  emit-session-recap)        shift; emit_session_recap "$@" ;;
  emit-v3-friction)          shift; emit_v3_friction "$@" ;;
  emit-file-change-summary)  shift; emit_file_change_summary "$@" ;;
  *)
    echo "usage: harness-evidence.sh {emit-session-recap <state_file> | emit-v3-friction --class <enum> --description ... --could-phase-0-handle <true|false> --workaround-used ... | emit-file-change-summary <state_file> <commit>}" >&2
    exit 2
    ;;
esac
```

### Error path matrix

| Failure | Handler |
|---|---|
| `git rev-parse` non-zero | `_harness_evidence_root` falls back to `$PWD` |
| `mkdir -p docs/retros` fails (read-only fs) | `_harness_evidence_path` returns 1; emit functions check `[[ -z "$path" ]]` and `return 0` |
| Disk full / `>>` fails | `_harness_evidence_append` already has `\|\| true` |
| `claude --bare` fails (Sonnet down, no auth, timeout) | `_run_sonnet_recap` returns empty; `emit_session_recap` writes row with `fallback=true` and `recap_paragraph` = `state.task` verbatim |
| `jq` missing | First-line `command -v jq >/dev/null 2>&1 \|\| return 0` |
| Corrupted state file JSON | `state_read` already returns "" on failure; empty-session filter trips → `return 0` |
| `claude --bare` not on PATH | `_run_sonnet_recap` returns empty as above |

## B. stop-hook.sh integration patch

**Location**: `superpowers/hooks/stop-hook.sh`, between `loop_phase` return (line 55) and `vet_phase` (line 58).

**Order rationale**:
1. **Loop first** (unchanged) — `loop_phase` either `exit 0`s (mid-iteration) or returns to fall through. Evidence emit is meaningless mid-loop iteration; only end-of-session.
2. **Evidence between loop and vet** — `emit_session_recap` reads state but does not mutate it (Sonnet recap is logged externally, not back to state). Critically must run BEFORE `vet_phase` because `vet_phase` may `exit 0` early (need_vet not set, line 137-139) without falling through to a "post-vet" hook.
3. **`emit_file_change_summary`** runs from a different code path: only when a plan completes. Call site is **inside `_loop_log_plan_completion_if_executing`** (`superpowers/lib/loop.sh:32-113`), specifically after the `jq -nc ... >> "$log_file"` line at `loop.sh:103-112` (the `plan_completed` event append). Same `completion_commit` and `modified_files_json` already in scope:
   ```
   bash "${SCRIPT_DIR}/../lib/harness-evidence.sh" emit-file-change-summary \
        "$state_file" "$completion_commit" 2>/dev/null || true
   ```
   `SCRIPT_DIR` resolves to stop-hook.sh's directory.

**Failure containment**:
- `stop-hook.sh` runs under `set -euo pipefail` (line 14). New emit call MUST be wrapped: `emit_session_recap "$STATE_FILE" 2>/dev/null || true`. Unhandled non-zero would abort before `vet_phase` runs and break verification. The `|| true` guarantees the stop hook still vets when Sonnet/disk/git fails.
- `|| true` matches `bail-log.sh:61` and `loop.sh:112` precedent.

**Latency budget (REQ-007)**: Sonnet adds ~600-1500 ms (streaming) per non-empty Stop. v0 ships sequential. Backgrounded async (`( emit_session_recap "$STATE_FILE" ; ) &`) introduces tail-end races between stop-hook exit and Sonnet completion; deferred until telemetry shows pain.

## C. retrospective SKILL.md integration

**Phase 1 reader insertion** — between current step 7 (bail-out events, `superpowers/skills/retrospective/SKILL.md:61`) and step 8 (post-plan diff, `SKILL.md:62`).

Insert as **step 8** (renumber existing 8 → 9, 9 → 10):

> **8. Read harness-evidence channel** (covers REQ-004): If `docs/retros/harness-evidence.jsonl` exists, filter rows by `timestamp > <last evolution-log.jsonl retrospective_run.timestamp>`. Bucket by `event`:
> - `v3_friction` rows → pass through to **Phase 5a** verbatim for read-rate calibration; do NOT modify `class` / `description` / `could_phase_0_handle` / `workaround_used` fields
> - `session_recap` rows → distill into a "What happened between plans" summary using Haiku via `lib/utils.sh::run_haiku_merge`. See `./references/harness-evidence.md` for the merge prompt
> - `file_change_summary` rows → for any row with `completion_commit` not present in `plans-completed.jsonl` (cross-channel correlation), surface as "untracked completion" — typically means a Stop hook fired without the loop hook detecting plan completion
>
> Skip silently when the file does not exist (first-retrospective state).
>
> **Retract trigger detection** (covers REQ-005):
> - T3: if today's date ≥ 2027-05-09, mark "harness-evidence T3 age-out reached, AskUserQuestion to confirm retract" prominently in the retrospective report
> - T4: if no retro report in the last 30 days contains the literal substring "harness-evidence", mark "harness-evidence T4 read-rate trigger, AskUserQuestion to confirm retract"
> - T5: if `fallback=true` row count / total `session_recap` row count > 5% over rolling 30-day window, mark "harness-evidence T5 writer-reliability trigger, AskUserQuestion to confirm retract"
> - When multiple triggers fire, emit one coalesced AskUserQuestion listing all reasons in Phase 6.

**Filter logic** (mirrors step 7 bail-out — read all rows, in-process timestamp filter):
```
last_ts=$(jq -r 'select(.event=="retrospective_run") | .timestamp' \
           docs/retros/evolution-log.jsonl | tail -1)
jq -c --arg ts "$last_ts" 'select(.timestamp > $ts)' \
        docs/retros/harness-evidence.jsonl
```
Empty `last_ts` → no filter applied, read all rows. First-retrospective semantics.

**Distill model recommendation: Haiku, not Sonnet.**
- Recap rows already each contain a 200-500 word Sonnet-produced paragraph (the expensive step happened at write time)
- Phase 1 step 8 distill is "summarize N already-summarized paragraphs into one paragraph" — Haiku territory, mirrors `vet.sh:_vet_synthesize_final_task`
- Token estimate: 5 recaps × 400 words ≈ 2.7 K input + ~200 output — Haiku is 60-100× cheaper at this volume
- Sonnet at write time + Haiku at read time mirrors existing harness asymmetry: `vet.sh` is Haiku, evaluator is Sonnet

**Distill output format**: inject under a new "4.5 Harness Evidence" sub-section in the retrospective report (Phase 6 in `SKILL.md:163-175`):
- 4.5a `session_recap` distillation: 1-paragraph summary of distilled rows in window
- 4.5b `v3_friction` list: one row per event (verbatim — class / description / workaround_used), feeds meta-retrospective gate condition 2
- 4.5c `file_change_summary` untracked-completion warnings (if any)
- 4.5d Retract trigger markers (T3 / T4 / T5)

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
> - 2026-05-09: condition-2 channel designed and shipped as `harness-evidence.jsonl`. v3.x activation gate's condition 2 is now structurally satisfiable; conditions 1, 3, 4 remain open.

## E. Path resolution: $PWD vs git_root

**The drift**:
- `bail-log.sh:39` — `local log_dir="${PWD}/docs/retros"` (CWD-anchored)
- `loop.sh:57-66` — `git rev-parse --show-toplevel`, falls back to `$PWD`, derives `repo_root/docs/retros` (git-anchored)

**`harness-evidence.sh` follows `loop.sh`** — git-anchored with `$PWD` fallback.

Rationale:
- Retrospective reads `<repo_root>/docs/retros/*.jsonl` — git-anchored is the consumer contract
- session_recap writes can fire from any subdir; `$PWD` would scatter recaps across multiple `docs/retros/` directories if user `cd`s mid-session
- `loop.sh` has the right precedent — same hook chain (Stop), same JSONL target dir, same retrospective reader

**Should `bail-log.sh` be fixed in the same patch? No (YAGNI).**
- bail-log fires from inside skill bash blocks where SKILL.md instructions run from project root; CWD ≈ git_root in practice
- `test_bail_log_sh.py:62` asserts `Path(entry["cwd"]).resolve() == self.cwd.resolve()` — current contract IS PWD-anchored
- No empirical incident shows bail-log writing to wrong dir
- The divergence is documented in this design's `best-practices.md` §Known issues

## F. Test scaffolding

**File**: `superpowers/tests/test_harness_evidence_sh.py` (new, mirrors `test_bail_log_sh.py` shape).

Test classes:
- **`HarnessEvidenceExecutedTests`** — CLI mode (mirrors `BailLogExecutedTests`)
  - `test_emit_session_recap_writes_required_fields` — REQ-001
  - `test_emit_v3_friction_writes_required_fields` — REQ-001
  - `test_emit_file_change_summary_writes_paths` — REQ-001, REQ-003
  - `test_session_recap_skipped_when_all_inputs_empty` — REQ-002
  - `test_emit_session_recap_records_non_superpowers_skill` — REQ-002
  - `test_appends_multiple_events_keeps_ndjson_integrity` — REQ-008
  - `test_v3_friction_missing_description_rejects_with_exit_2` — REQ-001
  - `test_v3_friction_invalid_class_rejects_with_exit_2` — REQ-001
  - `test_file_change_summary_empty_paths_rejects` — REQ-003
  - `test_creates_docs_retros_when_missing` — REQ-001
- **`HarnessEvidenceSourcedTests`** — sourced mode (mirrors `BailLogSourcedTests`)
  - `test_sourced_then_called_writes_entry`
  - `test_sourcing_does_not_run_main`
  - `test_sourcing_under_set_e_does_not_abort_caller`
- **`HarnessEvidenceGitRootTests`** — path resolution (no bail-log analog)
  - `test_uses_git_root_not_pwd_when_in_repo` — REQ-001 path contract
  - `test_falls_back_to_pwd_when_not_in_repo`
- **`HarnessEvidenceDegradationTests`** — robustness (mirrors `BailLogDegradationTests`)
  - `test_silent_skip_when_jq_missing` — REQ-001 best-effort
  - `test_silent_skip_when_claude_cli_missing` — REQ-009 fallback
  - `test_disk_full_does_not_corrupt_existing_lines` — REQ-008
  - `test_sonnet_failure_writes_fallback_row` — REQ-009 (uses `HARNESS_EVIDENCE_SKIP_SONNET=1`)
  - `test_concurrent_writes_no_interleaving` — REQ-008 atomicity
- **`HarnessEvidenceSchemaTests`** — schema invariants (mirrors none directly)
  - `test_all_events_carry_schema_version_1` — REQ-006
  - `test_v3_friction_field_exact_match` — REQ-001 (exact set: class / description / could_phase_0_handle / workaround_used)
  - `test_session_recap_recap_one_sentence_copied_from_state_task` — REQ-002
  - `test_event_type_allowlist` — REQ-012 (only 3 values across all rows)

**Test override env vars**:
- `HARNESS_EVIDENCE_SKIP_SONNET=1` → `_run_sonnet_recap` returns "" without invoking claude
- `HARNESS_EVIDENCE_NOW=<ISO8601>` → freezes timestamp for retract-trigger tests

**Integration**: `tests/test_phase_integration.py` adds:
- `test_stop_hook_writes_session_recap_then_retro_consumes_it` — full Stop → Phase 1 step 8 cycle
- `test_t3_calendar_trigger_marker` — `HARNESS_EVIDENCE_NOW=2027-05-09` → T3 marker present in retro report
- `test_t4_read_rate_marker` — pre-populate 30 days of retros without `harness-evidence` substring → T4 marker
- `test_t5_writer_reliability_marker` — synthesize >5% `fallback=true` ratio → T5 marker
- `test_triggers_coalesce_into_single_askuserquestion` — multiple triggers fire → one prompt

**LLM-touching tests deliberately not included**:
- Sonnet recap quality (subjective, not regression risk)
- Real claude CLI invocation (network dependency, flaky CI)
- `AskUserQuestion` rendering (skill-instruction layer, not lib layer)
