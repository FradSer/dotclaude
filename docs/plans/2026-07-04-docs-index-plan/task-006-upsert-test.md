# Task 006: `upsert` Subcommand Test (RED)

**depends-on**: ["001"]

## BDD Scenario

```gherkin
Scenario: Cold start — upsert creates docs/README.md when absent
  Given docs/README.md does not exist
  When lib/docs-index.sh upsert design docs/plans/2026-07-04-X-design/ --status active --summary "Token rotation" is invoked
  Then docs/README.md is created with a header preamble and a table header row
  And the table contains exactly one data row
  And that row's kind equals "design" and status equals "active"
  And the script exits 0

Scenario: Idempotent upsert — same path twice updates, never duplicates
  Given the index contains one row for docs/plans/2026-07-04-X-design/ with status=active
  When upsert is invoked twice with the same path and --status wip --summary "revised"
  Then the index still contains exactly one row for that path
  And that row's status equals "wip" and summary equals "revised"
  And no duplicate rows are appended

Scenario Outline: Unknown status value rejected with exit 2
  Given the index exists with at least one entry
  When upsert design docs/plans/x-design/ --status=<bad_status> is invoked
  Then the script exits 2
  And the index file is not modified
  Examples:
    | bad_status          |
    | done                |
    | complete            |
    | implemented-abc1234 |   # wrong separator
    | draft               |   # rejected variant — canonical is wip

Scenario Outline: Unknown kind value rejected with exit 2
  Given the index exists with at least one entry
  When upsert <bad_kind> docs/plans/x-design/ --status active is invoked
  Then the script exits 2
  Examples:
    | bad_kind |
    | feature  |
    | spec     |
    | type     |   # rejected variant — canonical is kind

Scenario: Default status for a new design/plan row is wip when --status omitted
  Given docs/README.md exists with a header
  When upsert design docs/plans/2026-07-04-Y-design/ --summary "no status flag" is invoked
  Then the new row's status equals "wip"

Scenario: Default status for a new retro row is active when --status omitted
  Given docs/README.md exists with a header
  When upsert retro docs/retros/retro-2026-07-04.md --summary "no status flag" is invoked
  Then the new row's status equals "active"
```

**Covers design scenarios (verbatim titles):**
- "Cold start — first design creates the index"
- "Upserting the same path twice updates the row, never duplicates"
- "Unknown status value is rejected with exit code 2"
- "Unknown kind value is rejected with exit code 2"

## Interfaces

```bash
# Consumes: lib/docs-index.sh upsert <kind> <path> [--status <status>] [--summary <summary>]
# Writes: docs/README.md (creates if absent — seed header + table)
# Exit: 0 (written); 2 (unknown kind/status); 1 (disk error)
# Atomicity: write to docs/README.md.tmp.$$ then mv
```

## Files

- `tests/test-docs-index.bats` (or `.sh`) — append `upsert` tests

## Steps

1. Write tests for: cold-start creation, idempotent update, 4 bad-status rejections (Scenario Outline), 3 bad-kind rejections, default-status for design/plan (wip), default-status for retro (active).
2. Run harness — all FAIL (stub).

## Verification

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude/superpowers
bash tests/run-docs-index-tests.sh
# Expect: upsert tests FAIL (RED)
```
