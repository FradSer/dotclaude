# Task 007: `upsert` Subcommand Impl (GREEN)

**depends-on**: ["006"]

## BDD Scenario

```gherkin
Scenario: upsert inserts or updates atomically with vocab enforcement
  Given the tests from task 006 exist and currently FAIL
  When the upsert subcommand body is implemented
  Then all upsert tests PASS
  And cold start creates docs/README.md with header + table + one row
  And idempotent upsert updates in place (no duplication)
  And unknown kind/status exits 2 with no write
  And default status is wip for design/plan, active for retro
```

## Interfaces

```bash
# upsert implementation:
#   - Validate kind ∈ {design,plan,retro} → exit 2 on miss
#   - Validate status (if provided) against the controlled vocabulary → exit 2 on miss
#     * wip, active, reference are bare words
#     * implemented:<sha> must match ^implemented:[0-9a-f]{7}$
#     * superseded-by:<path> must match ^superseded-by:.+$
#     * expired:<reason> must match ^expired:.+$ (reason non-empty)
#   - Default status: wip for design/plan, active for retro
#   - If docs/README.md absent: seed header preamble + table header
#   - Parse existing rows; if path matches field 1, replace that row; else append
#   - Sort rows by path lexicographic
#   - Truncate summary to 72 chars with "…" if longer
#   - Set updated = today's ISO date (date +%Y-%m-%d) — note: date is available in script (not in workflow JS)
#   - Write to docs/README.md.tmp.$$ then mv (atomic)
```

## Files

- `lib/docs-index.sh` — implement the `upsert)` branch + a `validate_status()` helper + a `validate_kind()` helper + a `seed_header()` helper

## Steps

1. Implement `validate_kind()` and `validate_status()` with the regex/value checks above. `validate_status` returns the canonical status string or exits 2.
2. Implement `seed_header()` that writes the preamble + `| path | kind | status | summary | updated |` + separator.
3. Implement `cmd_upsert()`: validate args, default the status, load rows, replace-or-append, sort, truncate summary, write atomic.
4. Refactor `parse_rows()` into a shared helper used by list/show/upsert/set-status/rebuild.
5. Note on `date`: bash scripts CAN use `date` (the workflow-JS restriction doesn't apply to leaf scripts). Use `date +%Y-%m-%d`.

## Verification

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude/superpowers
bash tests/run-docs-index-tests.sh
# Expect: all upsert tests PASS (GREEN)
shellcheck lib/docs-index.sh
# Manual:
bash lib/docs-index.sh upsert design docs/plans/2026-07-04-X-design/ --status active --summary "test"
cat docs/README.md  # verify header + one row
```

**Covers design scenarios (verbatim titles):**
