# Task 004-impl: skill-events.sh helper impl (Green)

**depends-on**: task-004-test, task-002-impl

## Description

Implement `superpowers/lib/skill-events.sh`, the third thin wrapper. Exposes `log_skill_event <skill> <event> <payload_jq_filter> [args...]`. Unlike the other wrappers, skill-events hashes the args (sha1[:12]) to produce a clustering key for retrospective Phase 5a. Sources `retro-events.sh` (already shipped) and produces the envelope `{event, skill, timestamp, repo_root, args_hash, payload: {...}}` byte-for-byte equivalent to `bail-log.sh`'s field set.

## Execution Context

**Task Number**: 004-impl of 15
**Phase**: Core Features (Green)
**Prerequisites**: 004-test exists and fails (Red). 002-impl shipped `retro-events.sh`.

## BDD Scenario

```gherkin
Scenario: log_skill_event writes a fix_completed event from systematic-debugging Phase 4
  Given a project directory with no docs/retros folder
  When log_skill_event systematic-debugging fix_completed '{root_cause: $rc, fix_paths: ($fp | split(","))}' --arg rc "race in cache" --arg fp "src/cache.ts,tests/cache_test.ts" is called
  Then the helper returns 0
  And docs/retros/skill-events.jsonl exists with exactly one NDJSON line
  And the line parses with fields event=fix_completed, skill=systematic-debugging, timestamp, repo_root, args_hash (sha1[:12]), payload.root_cause, payload.fix_paths
  And no top-level field name collides with payload keys

Scenario: helper invoked in Executed mode writes the same record as Sourced mode
Scenario: jq is absent from PATH
Scenario: both shasum and sha1sum are absent (args_hash empty, other fields normal)
Scenario: docs/retros is on a read-only filesystem
Scenario: repo_root resolution fails
Scenario: date command fails to emit an ISO-8601 timestamp
```

**Spec Source**: `../2026-05-12-unified-retro-events-design/bdd-specs.md` §1.1, §1.2, §2 (all).

## Files to Modify/Create

- Create: `superpowers/lib/skill-events.sh`

## Steps

### Step 1: Confirm Red
- Run `python3 -m unittest tests.test_skill_events_sh -v`. Confirm failure.

### Step 2: Implement skill-events.sh
- File structure:
  - `[[ -n "${_SKILL_EVENTS_LOADED:-}" ]] && return 0`
  - `source "$(dirname "${BASH_SOURCE[0]}")/retro-events.sh"`
  - Function signature: `log_skill_event() { local skill=$1 event=$2 payload_filter=$3; shift 3; … }` — body is the implementer's work.
  - The function must:
    - Call `jq_or_skip || return 0`
    - Resolve `repo_root` via `repo_root_or_skip` or `return 0`
    - Resolve `timestamp` via `timestamp_or_skip` or `return 0`
    - `ensure_log_dir "$repo_root/docs/retros" || return 0`
    - Compute `args_hash` — sha1[:12] of the joined positional args after `payload_filter`. Use `shasum` first, fall back to `sha1sum`. If neither exists, set `args_hash=""` (§2.2 contract).
    - Build the envelope jq program that emits `{event: $event, skill: $skill, timestamp: $timestamp, repo_root: $repo_root, args_hash: $args_hash, payload: (<payload_filter>)}`. The payload is **nested**, not merged — this differs from `evolution-log.sh` (which merges) and matches `architecture.md` §`lib/skill-events.sh`.
    - Call `write_jsonl "$repo_root/docs/retros/skill-events.jsonl" '<envelope filter>' --arg event "$event" --arg skill "$skill" --arg timestamp "$timestamp" --arg repo_root "$repo_root" --arg args_hash "$args_hash" "$@"`
  - `_SKILL_EVENTS_LOADED=1`
  - Dual-mode footer: `if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then log_skill_event "$@"; fi`
- **No top-level `set -`**.

### Step 3: Verify Test Passes (Green)
- Run `python3 -m unittest tests.test_skill_events_sh -v`. MUST PASS.
- Full suite: `python3 -m unittest discover -s tests -v`. No regressions.

### Step 4: Refactor
- `shellcheck superpowers/lib/skill-events.sh` clean.
- `grep -nE '^set -' superpowers/lib/skill-events.sh` empty.
- If the args-hashing logic ends up substantial, consider hoisting `_retro_args_hash` into `retro-events.sh` (would be a new primitive). Only do this if BOTH `skill-events.sh` and a future wrapper would consume it — for this PR, inline it in `skill-events.sh` is fine.

## Verification Commands

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude/superpowers
python3 -m unittest tests.test_skill_events_sh -v
python3 -m unittest discover -s tests -v
shellcheck lib/skill-events.sh
grep -nE '^set -' lib/skill-events.sh && echo "FAIL" || echo "OK"
```

## Success Criteria

- `superpowers/lib/skill-events.sh` exists with `log_skill_event` and dual-mode footer.
- All `tests/test_skill_events_sh.py` tests pass.
- Full suite green.
- `shellcheck` clean.
- No top-level `set -`.
