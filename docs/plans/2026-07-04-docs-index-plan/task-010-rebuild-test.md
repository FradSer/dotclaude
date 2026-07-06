# Task 010: `rebuild` Subcommand Test (RED)

**depends-on**: ["007"]

## BDD Scenario

```gherkin
Scenario: rebuild regenerates the index from filesystem truth
  Given docs/plans/2026-07-04-X-design/ and docs/plans/2026-07-04-Y-plan/ folders exist
  And docs/retros/retro-2026-07-04.md exists
  And docs/README.md is empty or hand-edited
  When lib/docs-index.sh rebuild is invoked
  Then docs/README.md is regenerated with one row per folder
  And design folders get kind=design, plan folders get kind=plan, retro files get kind=retro
  And existing status values for still-present paths are preserved
  And rows whose paths no longer exist are dropped
  And the script prints the row count to stderr and exits 0

Scenario: rebuild seeds docs/writing-skills/ as a reference entry
  Given docs/writing-skills/ exists
  When rebuild is invoked
  Then the index contains a row for docs/writing-skills/ with kind=retro and status=reference

Scenario: rebuild applies the collapse rule above 60 entries
  Given 65 design/plan folders exist under docs/plans/
  When rebuild is invoked
  Then docs/README.md contains at most 60 data rows
  And groups of >=3 implemented/expired entries sharing a topic prefix are collapsed into one summary line
  And active/wip/superseded-by entries are never collapsed

Scenario: rebuild is idempotent
  Given a rebuilt index
  When rebuild is invoked again
  Then docs/README.md is byte-identical to the first rebuild
```

**Covers design scenarios (verbatim titles):**
- "Index stays compact — one row per folder, no per-file enumeration"
- "Reference entry is never flipped to expired"

## Interfaces

```bash
# Consumes: lib/docs-index.sh rebuild
# Scans: docs/plans/*-design/, docs/plans/*-plan/, docs/retros/retro-*.md, docs/writing-skills/
# Writes: docs/README.md (atomic, with collapse rule applied)
# Exit: 0; prints row count to stderr
```

## Files

- `tests/test-docs-index.bats` (or `.sh`) — append `rebuild` tests; add a fixture generator that creates N folders

## Steps

1. Write a `make_folders()` test helper that creates N design/plan folders with a `_index.md` inside each (so the folder exists).
2. Write the 4 scenarios above as tests. For the 65-folder test, assert `wc -l docs/README.md` ≤ 60 + header lines.
3. Run harness — all FAIL.

## Verification

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude/superpowers
bash tests/run-docs-index-tests.sh
# Expect: rebuild tests FAIL (RED)
```
