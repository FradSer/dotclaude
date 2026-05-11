# harness-evidence channel — best practices

## Operational warnings

### Raw user prose is captured verbatim

`harness-evidence.jsonl` records prose a Claude session worked on, including verbatim task descriptions, last-assistant tail content, and Sonnet-generated recap paragraphs. If sessions ever process credentials, customer data, internal URLs, or any content under privacy obligations, the user **must** add `docs/retros/harness-evidence.jsonl` to `.gitignore` BEFORE the first Stop hook fires after install.

There is no after-the-fact sanitizer. The v3 retro deferred that mechanism on purpose (see `docs/retros/2026-05-09-v3-considered-deferred.md` §5 — `lib/sanitizer.sh` does not exist by design).

### `.gitignore` recommendation: commit by default, opt out per-project

Sibling channels (`bail-out-events.jsonl`, `plans-completed.jsonl`, `evolution-log.jsonl`) are committed in this repo and serve as cross-project evidence corpora. `harness-evidence.jsonl` follows the same default. Operators with sensitive workloads add it to `.gitignore` themselves. This asymmetry is documented explicitly because silently defaulting to ignored would prevent any project from collecting the data the v3 retro §4 condition 2 needs.

### `session_id` disclosure scope

`session_id` is a 12-hex within-session correlation key. It does not encode user identity, but it IS stable for one session — anyone with read access to the jsonl file can correlate multiple recap rows to the same session. Treat its disclosure scope as identical to the file's disclosure scope.

### No LLM call on the Stop-hook critical path

The writer is path-only. Nothing in `harness-evidence.sh` forks to `claude`. The Stop-hook latency added by the channel is bounded above by one `jq -n` + one `>>` append — measured on the order of milliseconds, not the 600-1500 ms range an LLM streaming call would introduce.

Distillation happens at retrospective Phase 1 step 8 via one `run_haiku_merge` call over all rows in the un-distilled window. That code path already exists (used by `vet.sh::_vet_synthesize_final_task` for the per-session 1-sentence summary) and degrades gracefully — on Haiku failure the reader falls back to emitting up to 5 verbatim `recap_one_sentence` strings as a raw evidence dump.

If a future patch is tempted to "just call Sonnet here for richer prose", read `_index.md` §Rationale row C-v0 first. The pivot's reasoning is recorded against re-introduction.

## Known issues (deliberately not fixed in this PR)

### Cross-channel debt → `superpowers/TODO-v3.md`

Two known v3.0-target debt items affect this channel:
- `bail-log.sh` `$PWD` vs. `loop.sh` / `harness-evidence.sh` `git_root` path divergence — when a Stop hook fires from a sub-directory, the channels write to different `docs/retros/` directories.
- Manual-write channels `harness-observations.jsonl` and `evolution-log.jsonl` are still Claude-instructed writes from SKILL.md without lib helpers (per v3 retro §5 audit).

Do not restate these here. The single tracker is `superpowers/TODO-v3.md`; this section is the link, not the explanation. The harness-evidence source file header references `TODO-v3.md` directly so operators reading the code do not have to triangulate.

## Schema versioning policy

### Starting version

`schema_version=1` (integer). Every row carries it.

### Bump rules

- **Additive change** (new optional field, new tolerated wrapper): **do not bump**. Reader tolerates unknown fields per REQ-006.
- **Backward-incompatible change** (field renamed, type changed, required field added, semantics altered): bump to `schema_version=2`. Old readers MUST flag and skip rows they can't parse, never abort.
- **Adding a 4th event type**: forbidden by REQ-012. If hypothetically lifted, counts as breaking expansion → `schema_version=2` + fresh retract-trigger review.

### Reader tolerance contract

Enforced by `HarnessEvidenceSchemaTests` and `HarnessEvidenceReaderTests`:
1. Unknown fields on a known `schema_version` → ignore silently
2. Minor-bump notation (`"1.1"` if we ever switch to semver-string) → process as v1, ignore unknown fields
3. Unknown major version (`schema_version=2` reaching a v1-only reader) → count as "skipped: unknown major version", retro report flags the operator to upgrade, do not abort retrospective
4. Missing `schema_version` field entirely → treat as `1` (legacy tolerance for any pre-versioned row that slipped in)

### Migration policy

Never. Append-only. Old rows stay at their original `schema_version` forever. Readers are responsible for understanding all historical versions they encounter; writers are responsible for never decreasing the version they emit.

## Test strategy

### Unit tests — `superpowers/tests/test_harness_evidence_sh.py`

Six `unittest.TestCase` classes — Writer / Dispatcher / GitRoot / Degradation / Schema / Audit. ~14 cases total (post-pivot slim). See `architecture.md` §F for the case list with REQ-ID coverage.

**Test environment overrides**:
- `HARNESS_EVIDENCE_NOW=<ISO8601>` → freezes the audit CLI's notion of "now" for retract-trigger tests

**LLM policy**: writer makes no LLM call; no test mocks or invokes claude at write-time. Read-time Haiku distill is exercised by the Phase 1 step 8 integration test only, with `run_haiku_merge` either real (when CI has auth) or stubbed via a process-substitution `claude` shim that echoes a fixed string. Quality of the merged paragraph is not a regression target.

### Integration tests — `superpowers/tests/test_phase_integration.py`

Add scenarios:
- `test_stop_hook_writes_session_recap_then_retro_consumes_it` — full Stop → Phase 1 step 8 cycle, one Haiku call per run (REQ-002, REQ-004)
- `test_audit_cli_callable_outside_retrospective` — REQ-009 independent surface
- `test_triggers_coalesce_into_single_askuserquestion` — multiple triggers fire → one prompt (REQ-005)

### Out of scope

- Haiku distill content quality at read-time (subjective; reader degrades to raw evidence dump on failure)
- Real `claude` CLI invocation (network dependency, flaky CI)
- `AskUserQuestion` rendering (skill-instruction layer, not lib layer)
- `.gitignore` recommendation enforcement (operator decision)

## Token and growth budget

| Item | Estimate | Notes |
|---|---|---|
| `session_recap` row size | ~0.8 KB | state.task (~150c) + last_assistant_tail (500c truncated) + wrapper + modified_files paths |
| `v3_friction` row size | ~0.5 KB | description + workaround_used dominate |
| `file_change_summary` row size | ~0.3 KB + 60 B/path | path-only, scales with plan size |
| Daily volume @ N=10 sessions, 2 plans | ~10 KB/day | empty sessions skipped before write |
| 1-year volume @ N=10 | ~4 MB | well below git-friendliness threshold |
| 1-year volume @ N=50 (heavy use) | ~20 MB | tolerable; rotation not required |
| Rotation trigger (future-work, not MVP) | size > 50 MB OR age > 18 months | rotate to `harness-evidence.YYYY-MM.jsonl`, reader globs both |
| Read-time Haiku input per retrospective run | N rows × ~600B aggregated content ≈ 1.5 K input tokens at N=10 | runs at most once per retrospective |
| Read-time Haiku output per retrospective run | ~250 words ≈ 350 output tokens | |
| Per-retrospective Haiku cost (Haiku 4.5 rates) | < $0.001 per run | one call per retrospective, not per row |
| Stop-hook wall-clock added | ≤ 20 ms p95 | bare `jq -n` + `>>` append, no fork to claude |

**Pending N=1 baseline**: the table above is upper-bound estimation, not measurement. After 7 days of N=1 dogfooding (start date = implementation merge), `evaluation-data-week-1.md` in this folder records actual numbers and the SC table moves from "pending" to numeric thresholds. Per REQ-010, design is not "shipped for retract-monitoring" until that file exists.

**MVP guidance**: rotation is not implemented. At ~4 MB/year worst-case the file is fine inline in `docs/retros/` for ≥3 years. Revisit only if a project hits 50 MB or `git status` becomes noticeably slow.

## Code quality

- Match `bail-log.sh` and `post-plan-diff.sh` shell style: `set` discipline, function naming with `_` prefix for private helpers, `2>/dev/null || true` for best-effort writes
- All new functions have inline comments documenting failure handling
- jq usage stays within the patterns already in `bail-log.sh:42-58` and `post-plan-diff.sh:67-110`
- No new external dependencies (no Python helpers, no node, no curl beyond `claude --bare`)
- Header comment block (lines 1-30) documents path-anchor choice, recursion guard, and `bail-log.sh` divergence

## Common pitfalls

- **Do not introduce a write-time LLM call** — the round-1 design's Sonnet recap path was rejected. See `_index.md` §Rationale row C-v0 for the recorded reasoning before re-proposing.
- **Do not emit `last_assistant_tail` longer than 500 bytes** — writer truncates via `${var:0:500}`; do not bypass the truncation
- **Do not pre-classify `file_change_summary` paths at write time** — reader does this on demand via `post-plan-diff.sh classify`; pre-storing freezes a classification that may evolve
- **Do not add a 4th event type** — the CLI dispatcher has 3 emit verbs and each emit hardcodes its `event` field; adding a fourth requires editing the dispatcher table, the per-function literal, and the CI string-equality assertion on `HARNESS_EVIDENCE_EVENT_ALLOWLIST`. That two-site-plus-CI change is the structural choke; the temptation to add `ad_hoc_capture` or `external_reading` is the v3 four-quadrant model the retro rejected.
- **Do not write to `harness-evidence.jsonl` from anywhere except `lib/harness-evidence.sh`** — direct `>>` writes from skill bash blocks bypass the allowlist and surface as `audit` non-zero exit
- **Do not add `harness-evidence.jsonl` reading to brainstorming Phase 1.5 (Read Harness Config — assumption test) or executing-plans Phase 6** — v3 retro forbids bundling consumers with the writer; reader scope is retrospective Phase 1 step 8 + the `audit` CLI only

## Security considerations

- jsonl is written with default umask; on multi-user systems set `chmod 600` on the file or its parent dir
- Writer makes no network call; the only out-of-process invocation is `jq`
- The recursion guard `SUPERPOWERS_SUBSESSION=1` (umbrella) prevents LLM sub-sessions from recursively invoking the Stop hook chain — verify on the install path that `task-start.sh`, `track-changes.sh`, `track-spawns.sh`, `stop-hook.sh` all check the guard. `utils.sh::run_haiku_merge` exports both `SUPERPOWERS_SUBSESSION=1` and the per-purpose `SUPERPOWERS_MERGE_SESSION=1` (backward compatibility window).
- Read-time `run_haiku_merge` inherits the calling user's API auth via `claude --bare`; harness-evidence does not introduce new credential paths.

## References

- `docs/retros/2026-05-09-v3-considered-deferred.md` — design constraints, retract trigger language, add-bias warnings
- `superpowers/lib/bail-log.sh` — best-effort posture, NDJSON shape, sourceable + executable dual mode
- `superpowers/lib/post-plan-diff.sh` — git-tempo classification reused by reader
- `superpowers/lib/loop.sh:_loop_log_plan_completion_if_executing` — canonical Stop-hook-write pattern
- `superpowers/lib/utils.sh:run_haiku_merge` — sourceable LLM-call pattern, recursion guard
- `superpowers/tests/test_bail_log_sh.py` — test class shape mirrored by `test_harness_evidence_sh.py`
