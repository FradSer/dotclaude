# harness-evidence channel — best practices

## Operational warnings

### Raw user prose is captured verbatim

`harness-evidence.jsonl` records prose a Claude session worked on, including verbatim task descriptions, last-assistant tail content, and Sonnet-generated recap paragraphs. If sessions ever process credentials, customer data, internal URLs, or any content under privacy obligations, the user **must** add `docs/retros/harness-evidence.jsonl` to `.gitignore` BEFORE the first Stop hook fires after install.

There is no after-the-fact sanitizer. The v3 retro deferred that mechanism on purpose (see `docs/retros/2026-05-09-v3-considered-deferred.md` §5 — `lib/sanitizer.sh` does not exist by design).

### `.gitignore` recommendation: commit by default, opt out per-project

Sibling channels (`bail-out-events.jsonl`, `plans-completed.jsonl`, `evolution-log.jsonl`) are committed in this repo and serve as cross-project evidence corpora. `harness-evidence.jsonl` follows the same default. Operators with sensitive workloads add it to `.gitignore` themselves. This asymmetry is documented explicitly because silently defaulting to ignored would prevent any project from collecting the data the v3 retro §4 condition 2 needs.

### `session_id` disclosure scope

`session_id` is a 12-hex within-session correlation key. It does not encode user identity, but it IS stable for one session — anyone with read access to the jsonl file can correlate multiple recap rows to the same session. Treat its disclosure scope as identical to the file's disclosure scope.

### Sonnet network dependency

The Sonnet recap call is on the Stop hook critical path. `_run_sonnet_recap` sets timeout to 8 seconds; on any non-zero exit (timeout, network, auth), `emit_session_recap` writes a row with `fallback=true` and copies `recap_paragraph` from `state.task` (vet.sh's already-produced 1-sentence Haiku recap). No retry. No extension of the timeout. T5 retract trigger fires when the 30-day `fallback=true` ratio exceeds 5%.

## Known issues (deliberately not fixed in this PR)

### `bail-log.sh` `$PWD` vs. harness-evidence `git_root` divergence

`superpowers/lib/bail-log.sh:39` writes to `${PWD}/docs/retros`. `superpowers/lib/loop.sh:57-66` and the new `superpowers/lib/harness-evidence.sh` both use `git rev-parse --show-toplevel` with `$PWD` fallback. When a Stop hook fires from a sub-directory, `bail-log.sh` writes a *new* `docs/retros/` under that sub-dir while `harness-evidence.sh` writes to the repo-root one.

YAGNI guidance: do not fix `bail-log.sh` in this PR. Fixing it requires updating `tests/test_bail_log_sh.py:62` whose contract IS PWD-anchored, plus a regression-test sweep. No empirical incident shows bail-log writing to a wrong directory in practice. Bundle the fix only when it surfaces with a real bug. Bundling unrelated fixes is the add-bias pattern v3 retro §6 flagged.

The harness-evidence header comment cites `loop.sh` as the canonical precedent and references this section.

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

Mirror `test_bail_log_sh.py` shape: five `unittest.TestCase` classes — Executed / Sourced / GitRoot / Degradation / Schema. ~22 cases total. See `architecture.md` §F for the case list with REQ-ID coverage.

**Test environment overrides**:
- `HARNESS_EVIDENCE_SKIP_SONNET=1` → `_run_sonnet_recap` returns "" without invoking claude (default in CI)
- `HARNESS_EVIDENCE_NOW=<ISO8601>` → freezes the helper's notion of "now" for retract-trigger tests

**LLM policy**: do not mock or call Sonnet in unit tests. Test the fallback path explicitly by setting `HARNESS_EVIDENCE_SKIP_SONNET=1` and asserting `fallback=true` on the resulting row. The Sonnet call wrapper is a thin shell function; quality of recap text is not a regression risk worth gating CI on.

### Integration tests — `superpowers/tests/test_phase_integration.py`

Add scenarios:
- `test_stop_hook_writes_session_recap_then_retro_consumes_it` — full Stop → Phase 1 step 8 cycle (REQ-002, REQ-004)
- `test_t3_calendar_trigger_marker` — `HARNESS_EVIDENCE_NOW="2027-05-09T00:00:00Z"` → T3 marker present in retro report (REQ-005)
- `test_t4_read_rate_marker` — pre-populate 30 days of retros without `harness-evidence` substring → T4 marker (REQ-005, REQ-010)
- `test_t5_writer_reliability_marker` — synthesize >5% `fallback=true` ratio → T5 marker (REQ-005, REQ-011)
- `test_triggers_coalesce_into_single_askuserquestion` — multiple triggers fire → one prompt (REQ-005)

### Out of scope

- Sonnet recap content quality (subjective)
- Real `claude` CLI invocation (network dependency, flaky CI)
- `AskUserQuestion` rendering (skill-instruction layer, not lib layer)
- `.gitignore` recommendation enforcement (operator decision)

## Token and growth budget

| Item | Estimate | Notes |
|---|---|---|
| `session_recap` row size | ~1.2 KB | 200-500 char paragraph + wrapper fields + modified_files paths |
| `v3_friction` row size | ~0.5 KB | description + workaround_used dominate |
| `file_change_summary` row size | ~0.3 KB + 60 B/path | path-only, scales with plan size |
| Daily volume @ N=10 sessions, 2 plans | ~13 KB/day | empty sessions skipped before write |
| 1-year volume @ N=10 | ~5 MB | well below git-friendliness threshold |
| 1-year volume @ N=50 (heavy use) | ~24 MB | tolerable; rotation not required |
| Rotation trigger (future-work, not MVP) | size > 50 MB OR age > 18 months | rotate to `harness-evidence.YYYY-MM.jsonl`, reader globs both |
| Sonnet input per call | task (~200c) + last_assistant tail (~500c) + skill_name + modified_files (~10 lines) ≈ 250 input tokens + ~200 system prompt = ~450 input | |
| Sonnet output per call | ~250 words ≈ ~350 output tokens | helper truncates upstream prose >4 KiB before write |
| Per-session cost (Sonnet 4.x rates 2026-05) | ~$0.0008 input + $0.0053 output ≈ $0.006 | N=10/day → ~$22/year/project |
| Stop-hook wall-clock added | ~600-1500 ms (Sonnet streaming) | sequential v0; backgrounded async deferred per REQ-007 |

**MVP guidance**: rotation is not implemented. At ~5 MB/year worst-case the file is fine inline in `docs/retros/` for ≥3 years. Revisit only if a project hits 50 MB or `git status` becomes noticeably slow.

## Code quality

- Match `bail-log.sh` and `post-plan-diff.sh` shell style: `set` discipline, function naming with `_` prefix for private helpers, `2>/dev/null || true` for best-effort writes
- All new functions have inline comments documenting failure handling
- jq usage stays within the patterns already in `bail-log.sh:42-58` and `post-plan-diff.sh:67-110`
- No new external dependencies (no Python helpers, no node, no curl beyond `claude --bare`)
- Header comment block (lines 1-30) documents path-anchor choice, recursion guard, and `bail-log.sh` divergence

## Common pitfalls

- **Do not call `_run_sonnet_recap` from inside `_run_sonnet_recap`** — the recursion guard `SUPERPOWERS_MERGE_SESSION=1` short-circuits this, but adding a wrapping function defeats the guard
- **Do not emit `session_recap` with `recap_paragraph` longer than 500 characters** — helper truncates; do not bypass the truncation
- **Do not pre-classify `file_change_summary` paths at write time** — reader does this on demand via `post-plan-diff.sh classify`; pre-storing freezes a classification that may evolve
- **Do not add a 4th event type** — REQ-012 30-day audit catches this; the temptation to add `ad_hoc_capture` or `external_reading` is exactly the v3 four-quadrant model the retro rejected
- **Do not write to `harness-evidence.jsonl` from anywhere except `lib/harness-evidence.sh`** — direct `>>` writes from skill bash blocks bypass schema validation
- **Do not add `harness-evidence.jsonl` reading to brainstorming Phase 1.5 (Read Harness Config — assumption test) or executing-plans Phase 6** — v3 retro forbids bundling consumers with the writer; reader scope is retrospective Phase 1 step 8 only

## Security considerations

- jsonl is written with default umask; on multi-user systems set `chmod 600` on the file or its parent dir
- `claude --bare` inherits the calling user's API auth; harness-evidence does not introduce new credential paths
- The recursion guard `SUPERPOWERS_MERGE_SESSION=1` prevents Sonnet sub-sessions from recursively invoking the Stop hook chain — verify on the install path that `task-start.sh:20`, `track-changes.sh:15`, `stop-hook.sh:17` all check the guard
- No content is fetched over the network except via `claude --bare`; no curl, no wget, no third-party dependencies

## References

- `docs/retros/2026-05-09-v3-considered-deferred.md` — design constraints, retract trigger language, add-bias warnings
- `superpowers/lib/bail-log.sh` — best-effort posture, NDJSON shape, sourceable + executable dual mode
- `superpowers/lib/post-plan-diff.sh` — git-tempo classification reused by reader
- `superpowers/lib/loop.sh:_loop_log_plan_completion_if_executing` — canonical Stop-hook-write pattern
- `superpowers/lib/utils.sh:run_haiku_merge` — sourceable LLM-call pattern, recursion guard
- `superpowers/tests/test_bail_log_sh.py` — test class shape mirrored by `test_harness_evidence_sh.py`
