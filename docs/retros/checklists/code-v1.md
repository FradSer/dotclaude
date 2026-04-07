# Code Checklist v1

- **Version:** v1
- **Mode:** code
- **Created:** 2026-04-04

---

## Checklist Items

### CODE-VER-01 -- Verification commands exit with code 0

All verification commands specified in the task file must be executed independently
and each must exit with code 0. Commands are run directly in a fresh shell -- do not
trust exit codes reported by the generator or any aggregated summary. Each command is
invoked separately so a failure in one does not mask results from others.

**Check method:**
1. Extract every verification command from the task file.
2. Run each command independently in a clean shell (do not chain with `&&`).
3. Capture the exit code of each command.
4. A check passes only if every command returns exit code 0.

**Evidence format:**
For each verification command, record:
- `command`: the exact command text executed
- `exit_code`: the integer exit code returned
- `output_tail`: last 10 lines of combined stdout/stderr

**Result:** PASS if all exit codes are 0. FAIL if any exit code is non-zero.

`# Type: computational` -- exit code is deterministic ground truth

---

### CODE-QUAL-01 -- No TODO, FIXME, HACK, XXX, or stub patterns in produced files

All files created or modified by the task must be free of prohibited marker patterns.
These patterns indicate incomplete or deferred work that should not ship.

**Check method:**
Run grep against every file created or modified by the task:
```
grep -rn -E '(TODO|FIXME|HACK|XXX|STUB|stub\b)' <file-list>
```
The patterns are case-sensitive except for `stub` which is matched case-insensitively
via the `\b` word boundary. The full set of prohibited patterns:
- `TODO` (exact uppercase)
- `FIXME` (exact uppercase)
- `HACK` (exact uppercase)
- `XXX` (exact uppercase)
- `STUB` (exact uppercase)
- `stub` followed by a word boundary (catches `stub()`, `stub_impl`, etc.)

**Evidence format:**
For each match found, record:
- `file:line` -- the matching pattern text

Empty evidence list means no violations found.

**Result:** PASS if grep returns no matches (exit code 1). FAIL if grep returns any match (exit code 0).

`# Type: computational` -- grep for exact strings produces deterministic result

---

### CODE-QUAL-02 -- No stub implementations in produced files

All files created or modified by the task must contain real implementations, not
placeholder bodies. The following patterns indicate unfinished implementation:

- `NotImplementedError` -- Python exception used as a placeholder
- `pass` as the sole body of a function/method (a line containing only `pass` indented inside a `def`/`class`)
- `...` (ellipsis) as the sole body of a function/method

**Check method:**
Run targeted grep commands against every file created or modified by the task:
```
grep -rn 'NotImplementedError' <file-list>
grep -rn -P '^\s+pass\s*$' <file-list>
grep -rn -P '^\s+\.\.\.\s*$' <file-list>
```
Each grep is run independently. Any match from any grep constitutes a failure.

**Evidence format:**
For each match found, record:
- `file:line` -- the stub pattern found

Empty evidence list means no violations found.

**Result:** PASS if all three greps return no matches. FAIL if any grep returns a match.

`# Type: computational` -- grep for exact patterns produces deterministic result

---

## Usage Notes

- Run all checks against the set of files created or modified by the task, not the entire repository.
- Each check is independent and produces a binary PASS/FAIL result.
- Evidence must be captured verbatim from command output, not summarized or paraphrased.
- All items in this checklist are computational checks with deterministic outcomes.
