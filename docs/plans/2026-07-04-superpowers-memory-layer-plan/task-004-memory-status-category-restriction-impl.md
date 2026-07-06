# Task 004: Memory status restriction + category flag — impl (GREEN)

**depends-on**: task-003

## Description

Add two new, small, isolated pieces to `lib/docs-index.sh`:

1. `validate_status_for_kind(kind, status)` — for `kind=memory`, accepts only `status_category(status)` ∈ `{active, expired}`; rejects everything else with exit 2 and a diagnostic naming the memory-specific subset. For every other kind, this is a no-op passthrough (delegates entirely to the existing `validate_status()`, already called elsewhere — no behavior change for design/plan/retro).
2. `validate_category(category)` — validates against `convention|pitfall|decision|preference`; exit 2 on any other value (including empty, `type`, `kind`, `reference`) with a diagnostic naming the allowed vocabulary.

Wire both into `cmd_upsert()` (new `--category` flag parsing; required + validated when `kind=memory`; rejected as a usage error when passed for any other kind) and into `cmd_set_status()` (kind-aware status restriction, applied using the row's *existing* kind, found by path lookup before the transition-matrix check).

## Execution Context

**Task Number**: 004 of 020
**Phase**: Foundation
**Prerequisites**: task-003's tests exist and FAIL

## BDD Scenario

```gherkin
Scenario Outline: kind=memory rows are restricted to active and expired statuses, enforced by the script
  Given a `kind=memory` row exists with `status=active`
  When `lib/docs-index.sh set-status <path> "<to>"` is invoked
  Then the transition is <outcome>
  Examples:
    | to                                     | outcome  |
    | expired:retro-2026-07-04:superseded     | allowed  |
    | wip                                     | rejected (exit 2) |
    | superseded-by:docs/memory/pitfall_other.md | rejected (exit 2) |
    | reference                               | rejected (exit 2) |
    | implemented:abc1234                     | rejected (exit 2) |

Scenario Outline: Malformed or missing category is rejected with exit code 2, no write
  When the memory-write step is invoked as
    `lib/docs-index.sh upsert memory docs/memory/x.md --status active --summary "..." --category=<bad_category>`
  Then the script exits with code 2
  And no file `docs/memory/x.md` is created
  And the `docs/README.md` index is not modified
```

**Spec Source**: `../2026-07-04-superpowers-memory-layer-design/bdd-specs.md` Scenario 19, Scenario 16; `architecture.md` §2 (`validate_status_for_kind` diff-table row)

## Interfaces

**Exposes** (new functions in `lib/docs-index.sh`):
- `validate_status_for_kind(kind: str, status: str) -> void` — `exit 2` on violation (memory-only restriction); returns (no output) otherwise
- `validate_category(category: str) -> str` — echoes the validated category on success; `exit 2` on violation

**Modifies** (existing functions):
- `cmd_upsert()` — add `category=""` local var; add `--category) category="${2:-}"; shift 2 ;;` to the arg-parsing `while` loop; after `kind="$(validate_kind "$kind")"`, branch: if `kind == "memory"`, require non-empty `category` (exit 2 if empty) and call `category="$(validate_category "$category")"`; if `kind != "memory"` and `category` is non-empty, exit 2 ("upsert: --category is only valid for kind=memory"). After `status` is resolved (explicit or default), call `validate_status_for_kind "$kind" "$status"`. `category` is validated but NOT appended to `new_row` — the row stays 5 fields.
- `cmd_set_status()` — move the `field_kind="$(printf '%s' "$row" | awk -F' \\| ' '{print $2}')"` extraction (currently line 448, after the `transition_allowed` check) to immediately after the row is matched (currently line 439-440), *before* the `transition_allowed` check. Immediately after that, call `validate_status_for_kind "$field_kind" "$new_status"` (exit 2 on violation) — this runs before `transition_allowed`, so a kind-restriction violation surfaces before a transition-matrix violation would even be checked.

**Consumes**: `status_category()` (unmodified, reused as-is by `validate_status_for_kind`)

**Global Constraints respected**: memory status vocabulary restricted to `active|expired:<reason>`, enforced by the script (not documentation-only); category is frontmatter-only, never a 6th row column; zero behavior change for `design|plan|retro` rows.

## Files to Modify/Create

- Modify: `superpowers/lib/docs-index.sh` — add `validate_status_for_kind()` and `validate_category()` (near `validate_status()`, ~line 199); modify `cmd_upsert()` (~lines 288-318) and `cmd_set_status()` (~lines 417-452) per Interfaces above.

## Steps

### Step 1: Verify Scenario
- Re-confirm Scenario 19 and Scenario 16 against current (pre-edit) behavior.

### Step 2: Implement Logic (Green)
- Add the two new validation functions.
- Wire `--category` into `cmd_upsert()`'s arg parser and validation flow.
- Reorder `cmd_set_status()`'s `field_kind` extraction and insert the new kind-aware check, exactly as specified in Interfaces.

### Step 3: Verify & Refactor
- Run the full suite (all `run-docs-index-tests.sh` tests through task-003, plus task-001/002).
- Confirm `design|plan|retro` rows are entirely unaffected: re-run every pre-existing status-transition test.

## Verification Commands

```bash
bash superpowers/tests/run-docs-index-tests.sh
bash superpowers/tests/test-skill-touchpoints.sh
```

## Success Criteria

- All 11 task-003 tests PASS
- Zero regressions in pre-existing tests
- `upsert memory <path> --status active --summary "x" --category pitfall` succeeds; the same command with `--category type` exits 2; `set-status <memory-path> wip` exits 2; `set-status <memory-path> "expired:r:reason"` exits 0
