# Task 009: `set-status` Subcommand Impl (GREEN)

**depends-on**: ["008"]

## BDD Scenario

```gherkin
Scenario: set-status flips per the transition matrix
  Given the tests from task 008 exist and currently FAIL
  When the set-status subcommand body is implemented
  Then all set-status tests PASS
  And allowed transitions flip the row's status and update the updated date
  And rejected transitions exit 2 and leave the index unchanged
  And set-status on an absent path exits 3
```

## Interfaces

```bash
# set-status implementation:
#   - Validate <new-status> against the controlled vocabulary (reuse validate_status) → exit 2 on miss
#   - Find the row by path; if absent exit 3
#   - Compute the from-status (current field 3) and to-status (arg)
#   - Apply the transition matrix:
#     * "from" categories for matching: bare word (wip/active/reference) OR prefix
#       (implemented:/superseded-by:/expired:)
#     * Allowed transitions per best-practices.md §Status Transitions table
#   - If rejected: exit 2, no write
#   - If allowed: update field 3 + field 5 (updated), write atomic
```

## Files

- `lib/docs-index.sh` — implement the `set-status)` branch + a `transition_allowed()` helper

## Steps

1. Implement `status_category()` that maps a status value to a category token (`wip`, `active`, `implemented`, `superseded`, `expired`, `reference`) by taking the prefix before `:`.
2. Implement `transition_allowed(from, to)` encoding the matrix: 
   - `wip` → anything allowed
   - `active` → anything allowed
   - `implemented` → only `wip` allowed (rework)
   - `superseded` → nothing allowed (terminal)
   - `expired` → nothing allowed (terminal, except retro-resurrection which is out-of-band)
   - `reference` → nothing allowed (sticky)
3. Implement `cmd_set_status()`: validate, find row, check transition, flip or reject, write atomic.

## Verification

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude/superpowers
bash tests/run-docs-index-tests.sh
# Expect: all set-status tests PASS (GREEN)
shellcheck lib/docs-index.sh
```

**Covers design scenarios (verbatim titles):**
