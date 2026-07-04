# Task 008: `set-status` Subcommand Test (RED)

**depends-on**: ["007"]

## BDD Scenario

```gherkin
Scenario Outline: Allowed status transitions
  Given an entry exists with status=<from>
  When lib/docs-index.sh set-status <path> "<to>" is invoked
  Then the transition is <outcome>
  Examples:
    | from                 | to                                  | outcome  |
    | wip                  | active                              | allowed  |
    | active               | implemented:abc1234                 | allowed  |
    | active               | superseded-by:docs/plans/x-design/  | allowed  |
    | active               | expired:retro-2026-07-04:reason     | allowed  |
    | active               | wip                                 | allowed  |
    | wip                  | expired:retro-2026-07-04:reason     | allowed  |
    | implemented:abc1234  | wip                                 | allowed  |   # rework after ship
    | implemented:abc1234  | expired:retro-2026-07-04:reason     | rejected |
    | implemented:abc1234  | superseded-by:docs/plans/x-design/  | rejected |
    | expired:x            | active                              | rejected |   # no resurrection without retro
    | expired:x            | superseded-by:docs/plans/y-design/  | rejected |
    | reference            | expired:x                           | rejected |
    | reference            | superseded-by:docs/plans/y-design/  | rejected |
    | superseded-by:y      | active                              | rejected |

Scenario: Rejected transition exits 2 without modifying the index
  Given an entry with status=implemented:abc1234
  When set-status <path> "expired:retro-2026-07-04:reason" is invoked
  Then the script exits 2
  And the entry's status still equals implemented:abc1234
  And the summary column is unchanged

Scenario: set-status on an absent path exits 3
  Given the index has one row
  When set-status docs/plans/never-seen/ "active" is invoked
  Then the script exits 3
  And the index is unchanged
```

**Covers design scenarios (verbatim titles):**
- "Allowed status transitions"
- "Rejected transition exits non-zero without modifying the index"
- "executing-plans rework flips implemented back to wip"

## Interfaces

```bash
# Consumes: lib/docs-index.sh set-status <path> <new-status>
# Writes: docs/README.md (atomic)
# Exit: 0 (flipped); 2 (rejected transition OR unknown status); 3 (path not in index)
# Transition matrix enforced (see best-practices.md §Status Transitions)
```

## Files

- `tests/test-docs-index.bats` (or `.sh`) — append `set-status` tests, including the Scenario Outline as a parametric test

## Steps

1. Encode the transition matrix as test data (14 rows from the Scenario Outline).
2. Write a parametric test that, for each row, sets up an entry with `from` status, invokes `set-status <path> "<to>"`, and asserts exit code (0 for allowed, 2 for rejected).
3. Write the rejected-transition test asserting the index is byte-identical after a rejected flip.
4. Write the absent-path test asserting exit 3.

## Verification

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude/superpowers
bash tests/run-docs-index-tests.sh
# Expect: set-status tests FAIL (RED)
```
