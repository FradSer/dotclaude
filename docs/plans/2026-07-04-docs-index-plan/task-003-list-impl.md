# Task 003: `list` Subcommand Impl (GREEN)

**depends-on**: ["002"]

## BDD Scenario

```gherkin
Scenario: list parses the pipe table and filters correctly
  Given the tests from task 002 exist and currently FAIL
  When the list subcommand body is implemented in lib/docs-index.sh
  Then all 4 list tests from task 002 PASS
  And list with no filter prints all data rows (skipping the header preamble and the table header row)
  And list --kind <k> prints only rows whose 2nd field equals <k>
  And list --status <prefix> prints only rows whose 3rd field starts with <prefix>
  And list on an empty index prints nothing and exits 0
```

## Interfaces

```bash
# list implementation:
#   - Read ${ROOT}/docs/README.md
#   - Skip lines until the table header (the line starting with "| path |")
#   - Skip the separator line (|---|---|...)
#   - For each remaining line starting with "| ", parse 5 fields split by " | "
#   - Apply --kind filter on field 2 (exact match)
#   - Apply --status filter on field 3 (prefix match — value before ":" OR whole value)
#   - Print matching rows as-is (the pipe-delimited line, trimmed)
#   - Exit 0
```

## Files

- `lib/docs-index.sh` — implement the `list)` branch of the dispatcher

## Steps

1. Implement `cmd_list()` that parses `docs/README.md` with `awk`: skip until the header row, skip the separator, then for each data row apply filters and print.
2. Parse `--kind` and `--status` flags from positional args after the subcommand.
3. Validate `--kind` value against `{design,plan,retro}` — exit 2 on unknown.
4. Do NOT validate `--status` value (it's a prefix — `implemented` matches `implemented:abc1234`; let any prefix through).
5. Handle missing `docs/README.md`: exit 0, print nothing (treat as empty index — the consult-before contract treats absent as "no prior docs").

## Verification

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude/superpowers
bash tests/run-docs-index-tests.sh
# Expect: all 4 list tests PASS (GREEN)
shellcheck lib/docs-index.sh
```

**Covers design scenarios (verbatim titles):**
