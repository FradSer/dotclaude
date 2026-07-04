# Task 011: `rebuild` Subcommand Impl (GREEN)

**depends-on**: ["010"]

## BDD Scenario

```gherkin
Scenario: rebuild scans filesystem and applies the collapse rule
  Given the tests from task 010 exist and currently FAIL
  When the rebuild subcommand body is implemented
  Then all rebuild tests PASS
  And one row per folder is generated with the right kind
  And docs/writing-skills/ is seeded as kind=retro status=reference
  And the 60-line collapse rule fires above 60 entries
  And rebuild is idempotent
```

## Interfaces

```bash
# rebuild implementation:
#   - Scan docs/plans/*-design/ → kind=design
#   - Scan docs/plans/*-plan/ → kind=plan
#   - Scan docs/retros/retro-*.md → kind=retro (one row per file)
#   - If docs/writing-skills/ exists, seed as kind=retro status=reference
#   - Default status for newly-discovered paths: wip for design/plan, active for retro
#   - Preserve existing status values from the current docs/README.md (read-then-merge)
#   - Drop rows whose paths no longer exist on disk
#   - Apply collapse rule (see best-practices.md §Anti-Bloat (c)):
#     * if row count > 60: collapse groups of >=3 implemented/expired entries sharing
#       a topic prefix into one summary line
#     * if still > 60: drop expired entries entirely
#     * never collapse active/wip/superseded-by
#   - Sort by path, write atomic, print count to stderr
```

## Files

- `lib/docs-index.sh` — implement the `rebuild)` branch + a `collapse_rows()` helper

## Steps

1. Implement `scan_folders()` that globs the four patterns and emits `<path>\t<kind>` rows.
2. Implement `merge_statuses()` that reads the existing index and preserves known statuses for still-present paths.
3. Implement `collapse_rows()` encoding the 60-line ceiling + two-stage collapse.
4. Implement `cmd_rebuild()`: scan → merge → collapse → sort → write atomic → print count.
5. Seed `docs/writing-skills/` as `reference` if it exists.

## Verification

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude/superpowers
bash tests/run-docs-index-tests.sh
# Expect: all rebuild tests PASS (GREEN)
shellcheck lib/docs-index.sh
```

**Covers design scenarios (verbatim titles):**
