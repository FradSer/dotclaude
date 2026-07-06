# Task 004: `show` Subcommand Test (RED)

**depends-on**: ["001"]

## BDD Scenario

```gherkin
Scenario: show on a tracked path prints the single row
  Given docs/README.md contains a row for docs/plans/2026-07-04-X-design/
  When lib/docs-index.sh show docs/plans/2026-07-04-X-design/ is invoked
  Then it exits 0
  And it prints exactly one pipe-delimited row to stdout

Scenario: show on an absent path exits 3 (not in index)
  Given docs/README.md exists with one row
  When lib/docs-index.sh show docs/plans/never-seen-design/ is invoked
  Then it exits with code 3
  And it prints nothing to stdout
  And it writes no diagnostic error to stderr (exit 3 is a soft "not tracked yet")
```

(This covers BDD Scenario 16: "Not-in-index is a recoverable 3, not a failure".)

## Interfaces

```bash
# Consumes: lib/docs-index.sh show <path>
# Outputs: single pipe-delimited row to stdout, or nothing
# Exit: 0 (found); 3 (not in index — soft); 2 (malformed index — task 012)
```

## Files

- `tests/test-docs-index.bats` (or `.sh`) — append `show` tests

## Steps

1. Write 2 failing tests for the 2 scenarios above.
2. Run harness — both FAIL (stub).

## Verification

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude/superpowers
bash tests/run-docs-index-tests.sh
# Expect: 2 show-tests FAIL (RED)
```

**Covers design scenarios (verbatim titles):**
- "show on an absent path exits 3 and the caller upserts first"
