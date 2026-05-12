# Task 002: retro-events.sh Shared Core — Implementation (Green)

**depends-on**: task-002-retro-events-test

## Description

Implement `lib/retro-events.sh` — the shared-core `helper` library — so every test in Task 002 turns green. The file is sourceable (no top-level `set -e`, no main function), sources `utils.sh` exactly once, and exposes six primitives: `jq_or_skip`, `timestamp_or_skip`, `ensure_log_dir`, `repo_root_or_skip`, `write_jsonl`, `dedup_check`. The file is *not* directly executable in any meaningful way — running `bash lib/retro-events.sh` defines functions and exits, with no side effect.

Symmetry with `bail-log.sh` is the load-bearing property: the same external-command guard idioms, the same `_<NAME>_DIR/$(dirname "${BASH_SOURCE[0]}")` source pattern, and the same `command -v X >/dev/null 2>&1 || return 0` short-circuits.

## Execution Context

**Task Number**: 002 of 21
**Phase**: Core lib helpers
**Prerequisites**: Task 002 test ships RED tests against the missing file. No wrappers depend on this yet — they land in Tasks 003–005.

## BDD Scenario

Same scenarios as Task 002 test — this impl turns them green. See `task-002-retro-events-test.md` for full Gherkin text; primary scenario:

```gherkin
Scenario: the three channel helpers source retro-events.sh which sources utils.sh exactly once
  Given a shell with BASH_SOURCE tracking enabled
  When observations.sh, evolution-log.sh, and skill-events.sh are sourced in the same shell session in any order
  Then utils.sh is sourced exactly once
  And _SUPERPOWERS_DEPS_CHECKED is set to 1 after the first source and is not re-evaluated on the second or third
  And no duplicate warning lines about missing deps appear on stderr
```

**Spec Source**: `../2026-05-12-unified-retro-events-design/bdd-specs.md` §1.5, §2.1, §2.3, §2.4, §2.5, §5.18

## Files to Modify/Create

- Create: `superpowers/lib/retro-events.sh`

## Steps

### Step 1: File Header
- Open with the same shebang + comment block style as `lib/bail-log.sh` lines 1–34:
  - One-paragraph purpose statement (shared primitives consumed by `observations.sh`, `evolution-log.sh`, `skill-events.sh`).
  - Explicit non-promise: "Not directly executable; no public `helper` exported to skill authors. The three wrapper helpers are the public API."
  - Contract summary mirroring `bail-log.sh:13–18`: best-effort, never blocks caller, no top-level `set -e`.

### Step 2: Source Guard + utils.sh Source
- Add a top-of-file idempotence guard using the flag name `_RETRO_EVENTS_LOADED`. When the flag is already set, return 0 immediately; otherwise set it.
- Resolve the lib directory and source `utils.sh` using the same `$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)` resolution pattern `lib/bail-log.sh:40–42` already uses. Use the local variable name `_RETRO_EVENTS_DIR`. Add a `# shellcheck source=./utils.sh` directive on the line above the source statement.

### Step 3: Define the Primitive Contract

Declare each primitive as a bash function with the signature below. The body is the implementer's work — every primitive is short (≤6 lines) and uses the same guard idioms `lib/bail-log.sh` already ships. Re-read `lib/bail-log.sh` lines 50–78 once before writing the bodies — those lines are the canonical pattern (external-command guard, repo_root call, mkdir, jq presence check, timestamp, NDJSON append, `|| true` swallow). Reproduce that style.

| Primitive | Signature | Contract (what the function delivers) |
|---|---|---|
| `jq_or_skip` | `jq_or_skip` | Returns 0 if `jq` is callable, non-zero otherwise. No stdout. |
| `timestamp_or_skip` | `timestamp_or_skip` | Prints one ISO-8601 UTC line matching `^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$` and returns 0; returns non-zero with no stdout if `date` fails. |
| `ensure_log_dir` | `ensure_log_dir <abs_path>` | Creates the directory (idempotent). Returns 0 on success, non-zero if the parent is unwritable. No stderr. |
| `repo_root_or_skip` | `repo_root_or_skip` | Prints the project root via `utils.sh::repo_root` and returns 0; returns non-zero with no stdout when the root cannot be resolved. |
| `write_jsonl` | `write_jsonl <log_file> <jq_program> [jq_args...]` | Best-effort NDJSON append. Forwards positional args to `jq -nc`; redirects to `<log_file>`. Returns 0 unconditionally, even on jq filter failure (the file is left unchanged in that case). |
| `dedup_check` | `dedup_check <log_file> <substring>` | Returns 0 when `<substring>` appears in the last 200 lines of `<log_file>` (caller should skip the write); returns non-zero when the substring is absent or the file is missing. |

### Step 4: Implement the Primitives

Following the bail-log precedent verbatim:

- Every external-command call uses the `command -v <tool> >/dev/null 2>&1` guard and short-circuits via `return 0` (or returns its exit code) so partial failures never crash the caller.
- Every filesystem write redirects stderr to `/dev/null` and trails with `|| true` (matching `bail-log.sh:78`).
- The dedup primitive must use `tail -n 200 … | grep -qF --` so the substring is treated as a literal (no regex surprises on payloads carrying jq metacharacters).

No `set -e`, no `set -u`, no `set -o pipefail` at file scope. The implementer reads the listed `bail-log.sh` line range once and applies the same idioms — do not invent novel error-handling patterns.

### Step 5: No Footer
- Unlike `bail-log.sh`, do **not** add an Executed-mode footer. The file is sourceable-only.

### Step 6: Verification (Green)
- Run Task 002's test module; every non-xfail test passes.
- `shellcheck superpowers/lib/retro-events.sh` exits 0 (or with only `SC1091` for the unverified `utils.sh` source, mirroring the suppression in `bail-log.sh`).

### Step 7: Refactor (only if Green)
- If any test failure remains, treat it as RED and iterate; do not introduce ad-hoc bypasses.
- After Green: confirm no `set -e` / `set -u` / `set -o pipefail` line at column 0 (grep guard).

## Verification Commands

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude
python3 -m pytest superpowers/tests/test_retro_events_sh.py -v 2>&1 | tail -40
# Expect: every non-xfail test PASSES. xfail count matches what Task 002 test declared (BackwardCompat).

shellcheck superpowers/lib/retro-events.sh || true   # SC1091 acceptable, no other warnings
grep -nE "^set -" superpowers/lib/retro-events.sh    # must produce no output
```

## Success Criteria

- `lib/retro-events.sh` exists and is sourceable under `set -euo pipefail`.
- All non-xfail tests in `test_retro_events_sh.py` pass.
- `shellcheck` reports no warnings except `SC1091` (utils.sh) — same baseline `bail-log.sh` carries.
- No top-level `set -e` / `set -u` / `set -o pipefail`.
