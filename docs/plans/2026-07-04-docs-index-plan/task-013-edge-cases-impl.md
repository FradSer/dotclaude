# Task 013: Edge Cases Impl (GREEN) — Path Validation + Malformed-Index Guard

**depends-on**: ["012"]

## BDD Scenario

```gherkin
Scenario: path validation and malformed-index guards are enforced
  Given the tests from task 012 exist and currently FAIL
  When the validation logic is implemented
  Then all edge-case tests PASS
  And leading-slash and parent-traversal paths exit 2
  And a malformed index exits 2 on list/show/upsert/set-status
  And rebuild recovers from a malformed index
```

## Interfaces

```bash
# validate_path() helper:
#   - reject if path starts with "/" → exit 2
#   - reject if path contains ".." as a path segment → exit 2
#   - otherwise return 0
# assert_valid_index() helper (used by list/show/upsert/set-status):
#   - if docs/README.md exists but has no line matching "^| path |" → exit 2 with diagnostic
#   - rebuild does NOT call this (it regenerates from scratch)
```

## Files

- `lib/docs-index.sh` — add `validate_path()` and `assert_valid_index()` helpers; wire them into `cmd_list`, `cmd_show`, `cmd_upsert`, `cmd_set_status`

## Steps

1. Implement `validate_path()`: check `[[ "$path" == /* ]]` and `[[ "$path" == *../* || "$path" == */../* || "$path" == */.. ]]`; exit 2 on match.
2. Implement `assert_valid_index()`: grep for the table header line; if absent and file is non-empty, exit 2 with the diagnostic.
3. Wire `validate_path` into every command that takes a `<path>` arg (upsert, show, set-status).
4. Wire `assert_valid_index` into list/show/upsert/set-status (NOT rebuild).
5. Ensure `rebuild` does not call `assert_valid_index` (it regenerates).

## Verification

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude/superpowers
bash tests/run-docs-index-tests.sh
# Expect: all edge-case tests PASS (GREEN)
shellcheck lib/docs-index.sh
```

**Covers design scenarios (verbatim titles):**
