# Task 002: `list` Subcommand Test (RED)

**depends-on**: ["001"]

## BDD Scenario

```gherkin
Scenario: list with no filter prints all rows
  Given docs/README.md exists with a valid table containing 3 data rows
  When lib/docs-index.sh list is invoked with no filter
  Then it exits 0
  And it prints exactly 3 pipe-delimited rows to stdout
  And each row has 5 pipe-separated fields

Scenario: list --kind design filters by kind
  Given the index contains rows of kind design, plan, and retro
  When lib/docs-index.sh list --kind design is invoked
  Then it exits 0
  And it prints only rows whose kind field equals "design"

Scenario: list --status implemented matches the prefix
  Given the index contains a row with status "implemented:abc1234"
  When lib/docs-index.sh list --status implemented is invoked
  Then it exits 0
  And it prints that row (prefix match on the status value)

Scenario: list on an empty index prints nothing and exits 0
  Given docs/README.md exists with a header but zero data rows
  When lib/docs-index.sh list is invoked
  Then it exits 0
  And it prints nothing to stdout
```

## Interfaces

```bash
# Consumes: lib/docs-index.sh list [--kind <design|plan|retro>] [--status <prefix>]
# Outputs: pipe-delimited rows to stdout, one per line, NO header row
# Exit: 0 (success, even on empty result); 2 (malformed index — covered in task 012)
```

## Files

- `tests/test-docs-index.bats` (or `.sh`) — append `list` tests

## Steps

1. Add a test helper `make_index()` that writes a `docs/README.md` with a given set of rows (header preamble + table header + data rows).
2. Write 4 failing tests corresponding to the 4 scenarios above.
3. Run the harness — all 4 should FAIL (the `list` subcommand is still a stub from task 001).

## Verification

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude/superpowers
bash tests/run-docs-index-tests.sh
# Expect: 4 list-tests FAIL (RED) — stub exits 2 with "not yet implemented"
```

**Covers design scenarios (verbatim titles):**
