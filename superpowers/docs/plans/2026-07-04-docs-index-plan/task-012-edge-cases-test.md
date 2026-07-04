# Task 012: Edge Cases Test (RED) — Malformed Index + Path Validation

**depends-on**: ["007"]

## BDD Scenario

```gherkin
Scenario: Consult degrades gracefully when the index is not a table
  Given docs/README.md exists but its content is free-form prose, not a pipe-delimited table
  When lib/docs-index.sh list is invoked
  Then the script exits with code 2
  And the diagnostic message states "docs/README.md is not a valid index table"
  And no upsert or set-status is attempted against the malformed file

Scenario: Path validation rejects leading slash
  Given the index exists
  When lib/docs-index.sh upsert design /etc/passwd --status active is invoked
  Then the script exits 2
  And the index is not modified

Scenario: Path validation rejects parent traversal
  Given the index exists
  When lib/docs-index.sh upsert design ../etc/passwd --status active is invoked
  Then the script exits 2
  And the index is not modified

Scenario: Malformed index recovery via rebuild
  Given docs/README.md is free-form prose
  When lib/docs-index.sh rebuild is invoked
  Then rebuild ignores the malformed content and regenerates from filesystem truth
  And the script exits 0
```

**Covers design scenarios (verbatim titles):**
- "Consult degrades gracefully when the index is not a table"

## Interfaces

```bash
# Consumes: lib/docs-index.sh list|show|upsert|set-status|rebuild (all paths run through validation)
# Path validation: reject args starting with "/" OR containing ".." → exit 2
# Malformed-index detection: if docs/README.md exists but has no table header line, exit 2 on consult commands; rebuild ignores and regenerates
```

## Files

- `tests/test-docs-index.bats` (or `.sh`) — append edge-case tests

## Steps

1. Write the 4 scenarios above as tests.
2. For the malformed-index test, write a `docs/README.md` with prose only (no `| path |` line).
3. For path-validation, assert exit 2 and that the index file's mtime/content is unchanged.
4. Run harness — all FAIL.

## Verification

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude/superpowers
bash tests/run-docs-index-tests.sh
# Expect: edge-case tests FAIL (RED)
```
