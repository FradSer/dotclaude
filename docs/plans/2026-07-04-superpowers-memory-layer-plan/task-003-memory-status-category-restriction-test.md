# Task 003: Memory status restriction + category flag — test (RED)

**depends-on**: task-002

## Description

Extend `tests/run-docs-index-tests.sh` with test functions proving two new, code-enforced restrictions specific to `kind=memory`:

1. **Status subset**: `upsert`/`set-status` accept only `active` or a parameterized `expired:<reason>` for a `kind=memory` row — `wip`, `implemented:<sha>`, `superseded-by:<path>`, and `reference` are all rejected with exit 2, even though `validate_status()` alone would otherwise accept them.
2. **Category flag**: `upsert memory <path>` requires a new `--category <value>` flag, validated against the enum `convention|pitfall|decision|preference` — missing or invalid values (including the reserved words `type`, `kind`, and `reference`) exit 2 with no row written. The flag is rejected as a usage error when passed for any kind other than `memory` (design/plan/retro have no category concept).

These tests MUST fail against the current script (no `validate_status_for_kind`, no `--category` flag exist yet).

## Execution Context

**Task Number**: 003 of 020
**Phase**: Foundation
**Prerequisites**: task-002 merged (kind=memory accepted)

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
  Given the index exists with at least one entry
  When the memory-write step is invoked as
    `lib/docs-index.sh upsert memory docs/memory/x.md --status active --summary "..." --category=<bad_category>`
  Then the script exits with code 2
  And the script writes a diagnostic message naming the allowed category vocabulary
  And no file `docs/memory/x.md` is created
  And the `docs/README.md` index is not modified

  Examples:
    | bad_category |
    | type          |
    | kind          |
    | reference     |
    | note          |
    | fact          |
    |               |
```

**Spec Source**: `../2026-07-04-superpowers-memory-layer-design/bdd-specs.md` Scenario 19, Scenario 16

## Interfaces

**Exposes** (test functions added to `tests/run-docs-index-tests.sh`):
- `test_memory_upsert_rejects_wip_status()`
- `test_memory_upsert_rejects_implemented_status()`
- `test_memory_setstatus_rejects_superseded_by()`
- `test_memory_setstatus_rejects_reference()`
- `test_memory_setstatus_allows_expired()`
- `test_memory_upsert_requires_category_flag()` — omitted `--category` on `kind=memory` exits 2
- `test_memory_upsert_rejects_category_type()` — `--category type` exits 2
- `test_memory_upsert_rejects_category_kind()` — `--category kind` exits 2
- `test_memory_upsert_rejects_category_reference()` — `--category reference` exits 2
- `test_memory_upsert_accepts_all_four_categories()` — `convention|pitfall|decision|preference` each exit 0
- `test_design_upsert_rejects_category_flag()` — `--category` passed for `kind=design` exits 2 (usage error, category is memory-only)

**Consumes** (from `lib/docs-index.sh`, unmodified in this task — tests assert against current/expected-to-fail behavior):
- `bash "$DOCS_INDEX_SH" upsert memory <path> --status <status> --summary <s> --category <c>`
- `bash "$DOCS_INDEX_SH" set-status <path> <new-status>`

**Global Constraints respected**: status vocabulary for `kind=memory` restricted to `active|expired:<reason>`; category enum is exactly `convention|pitfall|decision|preference`.

## Files to Modify/Create

- Modify: `superpowers/tests/run-docs-index-tests.sh` — add the 11 test functions above in a new `# --- Task 003: memory status restriction + category flag tests ---` section, plus their `run_test` invocations.

## Steps

### Step 1: Verify Scenario
- Confirm Scenario 19 and Scenario 16 exist in the design's `bdd-specs.md`.

### Step 2: Implement Test (Red)
- Use `setup_tmp_repo` to seed a `kind=memory status=active` row via `make_index`, then exercise `set-status`/`upsert` against it with `assert_exit 2 ...` / `assert_exit 0 ...`.
- **Verification**: `bash superpowers/tests/run-docs-index-tests.sh` — the 11 new tests FAIL (script has no kind-aware status restriction and no `--category` flag at all, so `upsert memory ... --category X` currently exits 2 with "unknown argument '--category'" for the WRONG reason — a pre-existing usage-error path, not the new validation path; note this in the test comments so task 004's implementer knows the fix must produce the *correct* diagnostic message, not just any exit-2).

## Verification Commands

```bash
bash superpowers/tests/run-docs-index-tests.sh
```

## Success Criteria

- The 11 new tests exist, are wired into the invocation list, and FAIL for the documented reason
- Zero regressions among pre-existing tests (including task-001/002's 4 tests)
