# Code Checklist v1

- **Version:** v1
- **Mode:** code
- **Created:** auto-seeded

## Purpose

Binary PASS/FAIL checklist for evaluating produced code artifacts at the end of a sprint batch. Computational items are deterministic; inferential (anchored) items use a deterministic narrow step plus per-hit judgment (see each item's `# Type:` line).

## Artifacts Under Evaluation

- Files created or modified by the batch (per sprint contract `Produced` list)
- Verification commands listed in each task file

---

## Checklist Items

### CODE-VER-01 -- All verification commands exit with code 0

**Description:** Every verification command listed in a task file must be executed independently in a fresh shell and exit with code 0. Do not chain commands with `&&` (a failure in one would mask later results).

**Check method:**
1. Extract every verification command from each task file produced in the batch.
2. Run each command independently in a clean shell.
3. Capture the exit code of each command.
4. PASS only if every command returns exit code 0.

**Evidence format:** For each verification command, record `command`, `exit_code`, and `output_tail` (last 10 lines of combined stdout/stderr).

**Rework format:** "Fix failing verification: {cmd} exits {code}; error: {output}"

**Result:** PASS if all exit codes are 0. FAIL if any exit code is non-zero.

`# Type: computational` -- exit code is deterministic ground truth.

---

### CODE-QUAL-01 -- No TODO/FIXME/HACK/XXX/STUB markers in produced files

**Description:** Files created or modified by the batch must be free of placeholder markers that indicate incomplete or deferred work.

**Check method:**
```bash
grep -rn -E '(TODO|FIXME|HACK|XXX|STUB|stub\b)' <produced-files>
```
Patterns are case-sensitive except `stub` which matches case-insensitively via the `\b` word boundary.

**Evidence format:** `{file}:{line} -- {match}`

**Rework format:** "Remove placeholder at {file}:{line}; implement real logic."

**Result:** PASS if grep returns no matches. FAIL on any match.

`# Type: computational` -- grep for exact strings is deterministic.

---

### CODE-QUAL-02 -- No stub implementations (NotImplementedError, pass-only, ellipsis-only bodies)

**Description:** Functions and methods in produced files must contain real implementations, not placeholder bodies.

**Check method:**
```bash
grep -rn 'NotImplementedError' <produced-files>
grep -rn -E '^[[:space:]]+pass[[:space:]]*$' <produced-files>
grep -rn -E '^[[:space:]]+\.\.\.[[:space:]]*$' <produced-files>
```
Each grep is run independently; any match from any grep is a failure.

**Evidence format:** `{file}:{line} -- {stub pattern}`

**Rework format:** "Implement real logic in {file} function {name}."

**Result:** PASS if all three greps return no matches. FAIL on any match.

`# Type: computational` -- grep for exact patterns is deterministic.

---

### CODE-TEST-LIVE-01 -- Produced tests actually run; none silently disabled or focused

**Description:** A test that exists (TEST-01) and "passes" (CODE-VER-01 exits 0) verifies nothing if it is skipped, xfail-ed, disabled, or has an empty body — a false green that lets a batch claim completion without proving behavior. A focus marker (`.only`) is equally a failure: it silently disables every sibling test in the file. This item catches the gap CODE-VER-01 cannot: a green suite that does not test.

**Check method:**
```bash
grep -rnE '@(pytest\.mark\.)?(skip|xfail)|@unittest\.(skip|expectedFailure)|@Disabled|@Ignore|\b(xit|xdescribe)\b|\b(it|test|describe)\.(skip|only)\b|\bt\.Skip\(|#\[ignore\]' <produced-test-files>
```
Run only against test files in the batch's produced/modified set. The grep narrows candidates; for each hit, judge whether it disables verification of behavior THIS batch claims to implement (FAIL) or is a justified guard with a stated reason — platform/env conditional (`skipif`, `skipUnless`) or a tracked known-bug `xfail` referencing an issue (allowed). An unconditional `skip` / `.only` / empty-body test covering in-scope behavior is always FAIL.

**Evidence format:** `{file}:{line} -- {marker} -- {disabled behavior}`

**Rework format:** "Re-enable the test at {file}:{line} so it runs and asserts; if the behavior is genuinely out of scope, delete the test rather than leaving a disabled placeholder. Justified platform/known-bug guards must carry a one-line reason."

**Result:** PASS if no produced test disables verification of in-scope behavior. FAIL on any vacuous/skipped/focused test for behavior the batch claims.

`# Type: inferential (anchored)` -- grep enumerates skip/focus markers deterministically; the evaluator confirms each is vacuous vs. a justified guard.

---

## Evaluation Protocol

1. Run all checks against the set of files created or modified by the batch, not the entire repository.
2. Each check is independent and produces a binary PASS/FAIL result.
3. Evidence must be captured verbatim from command output, not summarized or paraphrased.
4. Verdict: all items PASS = **PASS**. Any item FAIL = **REWORK** with itemized rework list.
