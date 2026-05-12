# Unified Retro Events — Best Practices

Design-stage constraints for the four new lib helpers
(`retro-events.sh`, `observations.sh`, `evolution-log.sh`,
`skill-events.sh`) and the single new emission point in
`systematic-debugging` Phase 4.

These rules are enforced by the BDD scenarios in `bdd-specs.md` and the
TestCase structure in the testing strategy section. Vocabulary stays
aligned with the architecture sub-agent: **helper**, **channel**,
**event**, **skill**, **emission point**.

---

## Security

- **No raw shell injection through payloads.** The public API
  `log_skill_event <skill> <event> <payload_jq_filter> [args]` accepts a
  jq filter string, not raw shell. The skill author controls the filter
  literal; runtime values flow in only via `--arg` / `--argjson`. The
  helper MUST NOT call `eval` on any caller-supplied value.

- **No secrets in jsonl rows.** Payload schemas for each skill MUST be
  reviewed at design time to confirm no environment variable, no auth
  token, no PII flows through. The reviewer's rule of thumb: if the
  field is not safe to commit to `docs/retros/` in a public repo, it
  does not belong in a payload.

- **`args_hash` is sha1[:12] and is not a secret.** The hash is a
  clustering key for retrospective Phase 5a, not a credential. It is
  truncated and unsalted on purpose, matching `bail-log.sh`. Reviewers
  should still avoid making the hashed input itself sensitive — there is
  no need to defeat the hash, but cleartext args may still leak through
  related fields.

- **No active chmod.** jsonl files inherit `docs/retros/` directory
  permissions. The helper MUST NOT call `chmod` to "fix" permissions —
  read-only filesystems are a legitimate degradation path (see
  Best-effort Degradation in `bdd-specs.md`), not a problem to repair.

- **No transcript content in payloads.** The systematic-debugging
  `fix_completed` payload carries the root cause one-liner and the
  regression test path, never the test stdout, never the test stderr,
  never the fix diff. Those belong in the user-visible report, not the
  channel.

## Performance

- **Append-only, O(1) per emission.** Every helper opens the channel
  file with `>>` exactly once per call. No read-modify-write, no full
  rewrite. The append latency stays sub-millisecond and never grows
  with channel size.

- **Dedup scan is bounded.** Same-session dedup tail-scans the last
  200 lines of `skill-events.jsonl`, matching the
  `plans-completed.jsonl` precedent. The bound makes dedup O(1) in the
  size of the channel and the worst case is a missed dedup, never a
  performance cliff.

- **Long channel files do not slow new emissions.** Because writes are
  append-only and dedup is tail-bounded, a 10MB or 100MB jsonl channel
  performs identically to an empty one. Retrospective Phase 1 readers
  pay the cost of size, not Phase 4 emitters.

- **No subshell loops in the hot path.** Each helper spawns at most
  three short-lived processes per call (`jq -nc`, `date -u`, and one of
  `shasum`/`sha1sum`). No bash for-loop, no while-read, no `find`.

## Code Quality

- **No `set -e` at the top of any helper file.** Sourcing the helper
  into a `set -euo pipefail` caller must not perturb the caller. This
  mirrors `bail-log.sh` and is verified by the `Sourced` TestCase.

- **Every external command is guarded.** Each external invocation in
  the helper terminates with `|| return 0` (when the helper has nothing
  useful to write without it) or `|| true` (when partial output is
  still acceptable). `command -v <tool> >/dev/null 2>&1 || return 0`
  guards the upfront dep check.

- **Naming convention.** Functions intended for skill authors carry the
  `log_` prefix (`log_skill_event`, `log_harness_observation`,
  `log_evolution_event`). Internal helpers carry the `_retro_` prefix
  (`_retro_emit`, `_retro_resolve_channel`). The prefix communicates
  the API boundary — anything `_retro_*` can change without a
  backward-compatibility audit.

- **BASH_SOURCE guard for double-source protection.** Every channel
  helper uses the same idiom as `bail-log.sh`:
  `[[ -z "${_RETRO_EVENTS_LOADED:-}" ]] || return 0` at the top, then
  `_RETRO_EVENTS_LOADED=1` after sourcing `retro-events.sh`. The flag
  is checked once per process; the second source returns immediately
  with no side effect.

- **Single source of truth for repo resolution.** Helpers call
  `repo_root()` from `lib/utils.sh`. They do not reimplement the
  `CLAUDE_PROJECT_DIR → git → PWD` cascade. This is the same rule
  enforced on `bail-log.sh` and `loop.sh`.

- **Direct-execution branch is identical across helpers.** Every helper
  ends with the same `[[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]] && <fn> "$@"`
  guard so the Sourced-vs-Executed matrix is uniform.

## Common Pitfalls

- **Do not source `utils.sh` directly from each channel helper.** The
  shared core `retro-events.sh` sources it once; channel helpers source
  `retro-events.sh`. Sourcing `utils.sh` twice retriggers no logic
  (the `_SUPERPOWERS_DEPS_CHECKED` guard catches it) but it is a
  layering smell and reviewers will flag it.

- **Do not change the jsonl schema during migration.** The migration is
  invisible by contract: `log_harness_observation` produces a row
  byte-equivalent to the legacy bash block under deterministic
  timestamp substitution. Adding a `"schema_version": 1` field, even
  optionally, breaks parity and breaks consumers in retrospective Phase 1.
  If a future schema change is needed, it ships as a separate
  versioning design, not bundled with this migration.

- **Do not emit from systematic-debugging Phases 1, 2, or 3.** Only the
  Phase 4 terminal step (after "Verify Fix" succeeds) emits
  `fix_completed`. Adding emissions earlier confuses retrospective
  Phase 5a aggregation: a per-phase event stream is a different design
  with different consumer logic and would require a separate brainstorm.

- **Do not duplicate the bail-out event in `skill-events.jsonl`.**
  `bail-log.sh` already owns the bail-out channel. The Phase 4 emission
  in systematic-debugging fires only on the non-bail-out path. The
  bail-out path returns before reaching Phase 4.

- **Do not include test stdout, stderr, or diff text in payloads.** The
  payload is a clustering signal, not a debugging artifact. The
  failing-test reproduction lives in the regression test file referenced
  by `regression_test_path`; readers who want the detail can open the
  file. Keeping payloads small also protects against accidental secret
  leakage in test output (env-var dumps, partial stack traces).

- **Do not hardcode `skill_name` in the systematic-debugging emission.**
  The value is sourced from the session state file via the same
  `state_read` path used by `_loop_log_plan_completion_if_executing`.
  Hardcoding `"systematic-debugging"` would silently mis-attribute
  emissions from any future skill that wraps systematic-debugging as a
  sub-call (e.g., an auto-loaded helper inside `bdd` workflow).

- **Do not introduce a `payload_jq_filter` that omits required envelope
  fields.** The envelope (`event`, `skill`, `timestamp`, `repo_root`,
  `args_hash`, `payload`) is built by `retro-events.sh`. The caller's
  filter populates `payload` only. Reviewers must reject any skill
  patch that tries to write top-level fields directly — that breaks
  the envelope-vs-payload separation and lets caller bugs corrupt the
  channel-wide schema.

- **Do not use plain `Bash` in the skill's `allowed-tools`.** Every
  invocation routes through the explicit form
  `Bash(${CLAUDE_PLUGIN_ROOT}/lib/skill-events.sh:*)` (and parallel
  entries for observations and evolution-log helpers when needed).
  This matches the existing pattern for `lib/bail-log.sh` in
  `systematic-debugging`'s `allowed-tools` array.
