# Code Checklist v2

- **Version:** v2
- **Mode:** code
- **Created:** 2026-06-02
- **Extends:** `code-v1.md` — v1 check methods retained inline; full Description / Evidence / Rework prose stays in `code-v1.md`. v2 adds 1 new item (CODE-ENV-ISO-01) fully described below. Evaluators MUST read `code-v1.md` alongside this file for v1 items.

---

## v1 Checklist Items (retained from code-v1.md)

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
Run targeted, macOS-compatible grep commands against every file created or modified by the task:
```
grep -rn 'NotImplementedError' <file-list>
grep -rn -E '^[[:space:]]+pass[[:space:]]*$' <file-list>
grep -rn -E '^[[:space:]]+\.\.\.[[:space:]]*$' <file-list>
```
Each grep is run independently. Any match from any grep constitutes a failure.

**Evidence format:**
For each match found, record:
- `file:line` -- the stub pattern found

Empty evidence list means no violations found.

**Result:** PASS if all three greps return no matches. FAIL if any grep returns a match.

`# Type: computational` -- grep for exact patterns produces deterministic result

---

## v2 New Items

### CODE-ENV-ISO-01 -- Test subprocess calls sanitize parent shell environment

**Description:** Test files that invoke bash helpers via `subprocess` (Python) or equivalent child-process mechanisms must explicitly construct a sanitized environment for the subprocess. The environment must either (a) strip all `CLAUDE_*`-prefixed variables inherited from the parent shell, or (b) construct a fresh environment from scratch containing only the variables the subprocess requires. Without this, developer shell state (e.g., `CLAUDE_CONFIG_DIR`, `CLAUDE_PROJECT_DIR`, `CLAUDE_PLUGIN_ROOT` pointing to a different checkout) leaks into the test sandbox, causing non-reproducible behavior across machines and CI environments.

**Origin:** Post-plan commit `7f8e8a0` ("refactor(sp): simplify phase 4 emission tests", 2026-05-13) added `env = {k: v for k, v in os.environ.items() if not k.startswith("CLAUDE_")}` to `test_systematic_debugging_phase4_emission.py`. No batch evaluator had flagged the pre-refactor state where tests ran with the full parent environment. The pattern is concrete, reproducible, and specific to the helper-layer test style this project uses.

**Check method:**
For each test file produced by the batch that imports `subprocess` (or equivalent):
```bash
# Step 1: identify test files using subprocess
grep -l "import subprocess" <produced-test-files> > /tmp/env_iso_candidates.txt

# Step 2: for each candidate, verify environment sanitization
while read -r f; do
  # Check if the file constructs an explicit env for subprocess calls
  if grep -q "subprocess.*env=" "$f" || grep -q "Popen.*env=" "$f"; then
    # Verify it either strips CLAUDE_ vars or builds a fresh env dict
    if ! grep -qE '(not k\.startswith\("CLAUDE_"\)|environ\s*=\s*\{|env\s*=\s*\{)' "$f"; then
      echo "FAIL: $f uses subprocess with env= but no CLAUDE_ sanitization detected"
    fi
  else
    # subprocess without explicit env — inherits full parent environment
    echo "FAIL: $f uses subprocess without explicit env parameter"
  fi
done < /tmp/env_iso_candidates.txt
```

The grep patterns identify:
- `not k.startswith("CLAUDE_")` — the strip-parent-vars idiom
- `environ = {` or `env = {` — fresh environment construction

Any `FAIL` output line means CODE-ENV-ISO-01 is FAIL. Empty output means PASS.

**Anchor constraint:** A test that sets individual env vars (`env["CLAUDE_PLUGIN_ROOT"] = "..."`) without first stripping or filtering the parent environment is FAIL — the developer's other `CLAUDE_*` vars still leak. A test that uses `env = os.environ.copy()` is FAIL — it copies everything including `CLAUDE_*` vars. Only explicit filtering or fresh construction passes.

**Evidence format:** `{file}:{line} -- subprocess call without CLAUDE_ environment sanitization`

Example: `test_example.py:45 -- subprocess.run([...], env=os.environ.copy()) inherits parent CLAUDE_ vars`

**Rework format:** "In {file}, replace the subprocess env setup with:
```python
env = {k: v for k, v in os.environ.items() if not k.startswith('CLAUDE_')}
env['CLAUDE_PLUGIN_ROOT'] = '<required-path>'  # only vars the subprocess needs
```
Then pass `env=env` to the subprocess call."

**Result:** PASS if every subprocess-using test file sanitizes its environment. FAIL on any file that inherits the parent environment unfiltered.

`# Type: computational` -- grep for subprocess usage and env-construction patterns produces deterministic result; the anchor constraint (explicit filter or fresh dict) minimizes interpretive freedom.

---

## Usage Notes

- Run all checks against the set of files created or modified by the task, not the entire repository.
- Each check is independent and produces a binary PASS/FAIL result.
- Evidence must be captured verbatim from command output, not summarized or paraphrased.
- All items in this checklist are computational checks with deterministic outcomes.
- CODE-ENV-ISO-01 applies only to test files that use subprocess or equivalent child-process mechanisms. Non-test files and test files without subprocess usage are out of scope for this item.
