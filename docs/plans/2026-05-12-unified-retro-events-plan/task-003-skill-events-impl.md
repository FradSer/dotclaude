# Task 003: skill-events.sh Wrapper — Implementation (Green)

**depends-on**: task-003-skill-events-test

## Description

Implement `lib/skill-events.sh` so Task 003's test suite turns green. The file is sourceable + executable (same dual-mode footer as `bail-log.sh:83–85`). Public function `log_skill_event <skill> <event> <payload_jq_filter> [args...]` constructs the envelope `{event, skill, timestamp, repo_root, args_hash, payload}` where `payload` is the caller-supplied jq filter's output and writes the resulting NDJSON line to `docs/retros/skill-events.jsonl`.

Same-session dedup is implemented via `dedup_check` on the last 200 lines of the channel, keyed on `(skill, event, args_hash)`. The dedup is **always on** for this wrapper (unlike `bail-log.sh` which has no dedup) because the systematic-debugging Phase 4 step may be re-entered legitimately within one session and the calibration loop wants one row per logical fix completion, not one per re-run of the verify step.

## Execution Context

**Task Number**: 003 of 21
**Phase**: Core lib helpers
**Prerequisites**: Task 003 test ships RED tests.

## BDD Scenario

Same scenarios as Task 003 test — see `task-003-skill-events-test.md`. Primary:

```gherkin
Scenario: log_skill_event writes a fix_completed event from systematic-debugging Phase 4
  When log_skill_event systematic-debugging fix_completed '{root_cause: $rc, fix_paths: ($fp | split(","))}' --arg rc "race in cache" --arg fp "src/cache.ts,tests/cache_test.ts" is called
  Then the helper returns 0
  And docs/retros/skill-events.jsonl exists with exactly one NDJSON line
  And that line parses as an object with fields event=fix_completed, skill=systematic-debugging, timestamp (ISO-8601 UTC), repo_root, args_hash (sha1[:12]), and a nested payload carrying root_cause and fix_paths
```

**Spec Source**: `../2026-05-12-unified-retro-events-design/bdd-specs.md` §1.1, §1.2, §2.2, §6.22, §6.23

## Files to Modify/Create

- Create: `superpowers/lib/skill-events.sh`

## Steps

### Step 1: File Header
- Same shebang + comment block style as `bail-log.sh:1–34`.
- Document the schema verbatim:
  ```
  Schema per line (NDJSON):
    {"event":"<event>",
     "skill":"<skill>",
     "timestamp":"<ISO8601 UTC>",
     "repo_root":"<project root>",
     "args_hash":"<sha1[:12] of args>",
     "payload":{ ... caller-supplied ... }}
  ```
- Document dedup: same-session, tail-200, keyed on `(skill, event, args_hash)`.

### Step 2: Idempotence + Sources
- Add a top-of-file idempotence guard using the flag `_SKILL_EVENTS_LOADED` (return 0 on re-source).
- Resolve `_SKILL_EVENTS_DIR` and source `retro-events.sh` using the same `$(cd … && pwd)` pattern `bail-log.sh:40–42` uses, with `# shellcheck source=./retro-events.sh` annotation.

### Step 3: `log_skill_event` Public Signature

```bash
log_skill_event <skill> <event> <payload_jq_filter> [jq_args...]
```

- First three positional args are required; default `<skill>` to `unknown` if empty.
- After `shift 3`, the remaining `"$@"` are passed verbatim to the inner `jq -nc` invocation (callers supply `--arg`/`--argjson` pairs here).

### Step 4: Function Behavior Contract

The body composes the canonical envelope around the caller's payload filter and appends one NDJSON line. Implement following these rules — DO NOT invent new error patterns; reuse the primitives shipped in Task 002:

- Every dependency check short-circuits via `return 0` on failure (`jq_or_skip`, `repo_root_or_skip`, `timestamp_or_skip`, `ensure_log_dir` — each guarded with `|| return 0`).
- `args_hash` follows `bail-log.sh:60–68` byte-for-byte: prefer `shasum -a 1`, fall back to `sha1sum`, truncate to 12 chars, leave the variable empty when neither tool is on PATH. The hashed input is the post-`shift 3` positional args joined with newlines.
- The envelope is `{event, skill, timestamp, repo_root, args_hash, payload}` with `payload` as a NESTED OBJECT carrying the caller's filter output. The payload nesting is the design's collision-prevention mechanism — top-level keys never collide with caller-supplied payload keys.
- Empty `payload_filter` substitutes the literal `{}` so jq still produces a valid object inside the envelope.

### Step 5: Dedup Gate

- Before the append, call `dedup_check` on the `skill-events.jsonl` path with a substring that uniquely identifies `(skill, event, args_hash)` as it appears in a serialized jq-emitted line. When `dedup_check` returns 0 (match found in the tail-200 window), the function returns 0 without appending. When it returns non-zero, proceed to the append.

### Step 6: Append

- Invoke `write_jsonl` on `${root}/docs/retros/skill-events.jsonl` with the composed envelope filter and forwarded caller args. `write_jsonl` swallows malformed-filter errors silently — that satisfies the "best-effort, never blocks" contract.

### Step 7: Executed-mode Footer

- Append the same dual-mode guard `bail-log.sh:83–85` uses, calling `log_skill_event "$@"` when the file is executed directly.

### Step 10: Verification (Green)
- Run Task 003's tests; assert all pass.
- `shellcheck` on the file; expect only `SC1091`.
- Re-run Task 002 test module to confirm `BackwardCompatTests` xfailed test now passes when run in isolation (the file's existence completes the dependency chain).

## Verification Commands

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude
python3 -m pytest superpowers/tests/test_skill_events_sh.py -v 2>&1 | tail -40
shellcheck superpowers/lib/skill-events.sh || true
grep -nE "^set -" superpowers/lib/skill-events.sh   # must produce no output
```

## Success Criteria

- All tests in `test_skill_events_sh.py` pass.
- No top-level `set -e` / `set -u` / `set -o pipefail`.
- `shellcheck` reports no warnings beyond `SC1091`.
- The Executed-mode and Sourced-mode paths produce byte-equal output (modulo timestamp) for the same arguments.
