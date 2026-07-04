# Task 005: `show` Subcommand Impl (GREEN)

**depends-on**: ["004"]

## BDD Scenario

```gherkin
Scenario: show finds the row by path primary key
  Given the tests from task 004 exist and currently FAIL
  When the show subcommand body is implemented
  Then show on a tracked path prints that one row and exits 0
  And show on an absent path prints nothing and exits 3
```

## Interfaces

```bash
# show implementation:
#   - Read docs/README.md, parse rows (same logic as list)
#   - Find the row whose field 1 (path) equals the arg
#   - Print the row, exit 0 if found
#   - Print nothing, exit 3 if not found
#   - Path validation: reject leading "/" or ".." with exit 2 (task 013 enforces; here, just match)
```

## Files

- `lib/docs-index.sh` — implement the `show)` branch

## Steps

1. Implement `cmd_show()` reusing the row-parsing logic from `cmd_list` (refactor into a shared `parse_rows()` helper if not already).
2. Match field 1 exactly against the `<path>` arg.
3. Exit 0 + print row on match; exit 3 + print nothing on miss.

## Verification

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude/superpowers
bash tests/run-docs-index-tests.sh
# Expect: 2 show tests PASS (GREEN)
shellcheck lib/docs-index.sh
```

**Covers design scenarios (verbatim titles):**
- "show on an absent path exits 3 and the caller upserts first"
