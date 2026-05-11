# harness-evidence channel — BDD specs

Channel path: `<git_root>/docs/retros/harness-evidence.jsonl`
Schema: NDJSON, `schema_version=1`, `event ∈ {v3_friction, session_recap, file_change_summary}`
Writer entry: `bash superpowers/lib/harness-evidence.sh <subcmd> [args]`
Hook coupling: Stop hook always invokes; filtering applied inside helper. **Writer is path-only — no LLM call.**
Reader entry: retrospective Phase 1 step 8 — distill rows with `timestamp > <last evolution-log.jsonl retrospective_run.timestamp>` via **one** `run_haiku_merge` call per run
Audit entry: `bash superpowers/lib/harness-evidence.sh audit` — independent of retrospective

## Requirement coverage map

| REQ | Covered by Feature |
|---|---|
| REQ-001 | Writer — session_recap event / Writer — v3_friction event / Writer — file_change_summary event / Writer — CLI dispatcher shape |
| REQ-002 | Writer — session_recap event (empty-session filter, path-only no-LLM contract) |
| REQ-003 | Writer — file_change_summary event |
| REQ-004 | Reader — retrospective Phase 1 consumption |
| REQ-005 | Retract trigger detection (T3 + T4, via audit CLI) |
| REQ-006 | Reader — schema versioning compatibility |
| REQ-007 | Writer — latency budget (no-LLM-on-hot-path scenario) |
| REQ-008 | Writer — concurrent append + disk-full + jsonl integrity |
| REQ-009 | Audit CLI — independent run path |
| REQ-010 | Pending N=1 observation (no automated scenario; verified by file existence at week 1) |
| REQ-011 | Writer — CLI dispatcher shape + Audit — allowlist invariant |
| REQ-012 | Writer — CLI dispatcher shape + Audit — allowlist invariant |

## Feature: Writer — session_recap event

Stop hook captures path-only inputs per non-empty session: the already-distilled 1-sentence task summary, the last-assistant tail (truncated to 500 bytes), and the modified-files list. No LLM call at write time.

```gherkin
Background:
  Given a git repository at "/tmp/ws/proj"
  And the Stop hook fires after a Claude session ends
  And "/tmp/ws/proj/docs/retros/" is writable
  And jq is available on PATH

# REQ-001, REQ-002
Scenario: happy path — executing-plans session with code changes
  Given the session state file has skill_name="executing-plans"
  And the session state file has task="Implement post-plan-diff classifier"
  And the session state file has modified_files=["lib/post-plan-diff.sh","tests/test_post_plan_diff_sh.py"]
  And the session state file has pending_prompt=""
  And the last-assistant transcript tail is "Done. Classifier returns feedback/evolution/unknown."
  When the Stop hook calls "harness-evidence.sh emit-session-recap"
  Then "/tmp/ws/proj/docs/retros/harness-evidence.jsonl" gains exactly one new line
  And that line parses as JSON
  And the line has event="session_recap"
  And the line has schema_version=1
  And the line has skill_name="executing-plans"
  And the line has recap_one_sentence="Implement post-plan-diff classifier"
  And the line has last_assistant_tail="Done. Classifier returns feedback/evolution/unknown."
  And the line has modified_files=["lib/post-plan-diff.sh","tests/test_post_plan_diff_sh.py"]
  And the line has no field named "recap_paragraph"
  And the line has no field named "fallback"
  And the line has timestamp matching ISO8601 UTC
  And the line has session_id of 12 hex chars
  And no claude CLI subprocess was spawned
  And the Stop hook exits 0

# REQ-002, REQ-007
Scenario: writer adds no LLM call to the Stop-hook critical path
  Given a non-empty session_recap candidate
  When the Stop hook calls "harness-evidence.sh emit-session-recap"
  Then no fork to the "claude" executable occurs
  And the writer wall-clock is below 100 ms p95 in CI

# REQ-002
Scenario: last_assistant_tail longer than 500 bytes is truncated
  Given the last-assistant transcript tail is 800 bytes of prose
  When the Stop hook calls "harness-evidence.sh emit-session-recap"
  Then the appended line has last_assistant_tail of length exactly 500
  And the truncation matches "${var:0:500}" semantics (no UTF-8 boundary repair)

# REQ-002
Scenario: empty session is silently skipped
  Given the session state file has task=""
  And the session state file has modified_files=[]
  And the session state file has pending_prompt=""
  When the Stop hook calls "harness-evidence.sh emit-session-recap"
  Then no new line is appended to "harness-evidence.jsonl"
  And the file may not exist if this is the project's first session
  And the Stop hook exits 0
  And no warning is printed to stderr

# REQ-002
Scenario: non-superpowers skill still records — collection is opportunistic
  Given the session state file has skill_name="git:commit"
  And the session state file has task="Commit refactor of utils.sh"
  And the session state file has modified_files=["superpowers/lib/utils.sh"]
  When the Stop hook calls "harness-evidence.sh emit-session-recap"
  Then exactly one new line is appended
  And the line has skill_name="git:commit"

# REQ-008
Scenario: concurrent Stop hooks append without corruption
  Given two Stop hooks fire within 50 ms
  And both produce non-empty session_recap candidates
  When both call "harness-evidence.sh emit-session-recap" in parallel
  Then "harness-evidence.jsonl" contains exactly two new lines
  And each line is independently valid JSON terminated by "\n"
  And no line is interleaved or truncated

# REQ-001
Scenario: not inside a git repository — fall back to $PWD
  Given the cwd "/tmp/scratch" has no ancestor with a ".git" directory
  When the Stop hook calls "harness-evidence.sh emit-session-recap"
  Then exactly one line is appended to "/tmp/scratch/docs/retros/harness-evidence.jsonl"
  And the Stop hook exits 0

# REQ-008
Scenario: disk full during write
  Given "/tmp/ws/proj/docs/retros/" cannot accept new bytes
  When the Stop hook calls "harness-evidence.sh emit-session-recap"
  Then the helper returns 0
  And the Stop hook exits 0
  And the existing harness-evidence.jsonl is not truncated

# REQ-001
Scenario: jq is missing from PATH
  Given jq is removed from PATH
  When the Stop hook calls "harness-evidence.sh emit-session-recap"
  Then no line is appended
  And the helper returns 0
```

## Feature: Writer — CLI dispatcher shape

The CLI dispatcher is the architectural lock for REQ-011 / REQ-012. Exactly 4 verbs; no `--event` argument anywhere.

```gherkin
# REQ-001, REQ-011, REQ-012
Scenario: CLI dispatcher exposes exactly four verbs
  When the user runs "bash harness-evidence.sh"
  Then stderr contains exactly these verb names: emit-session-recap, emit-v3-friction, emit-file-change-summary, audit
  And exit code is 2

# REQ-011, REQ-012
Scenario: passing --event to any emit verb is rejected
  When the user runs "bash harness-evidence.sh emit-session-recap --event ad_hoc /tmp/state.json"
  Then no line is appended to harness-evidence.jsonl
  And exit code is 2
  And stderr contains "unknown argument" or equivalent

# REQ-011, REQ-012
Scenario: the bash allowlist constant matches the expected set verbatim
  Given the file superpowers/lib/harness-evidence.sh is sourced
  When the test reads HARNESS_EVIDENCE_EVENT_ALLOWLIST
  Then it equals the string "file_change_summary session_recap v3_friction" by exact equality
```

## Feature: Writer — v3_friction event

Direct CLI invocation by user or sub-agent when they hit a friction class the v3 retro §4 condition 2 schema named.

```gherkin
# REQ-001
Scenario: emit a complete v3_friction row
  Given user identifies a friction in class "between_plan"
  When user runs:
    """
    bash superpowers/lib/harness-evidence.sh emit-v3-friction \
      --class between_plan \
      --description "Lost a tangent insight between plan A end and plan B start" \
      --could-phase-0-handle false \
      --workaround-used "Wrote it in a scratch note that I never reread"
    """
  Then exactly one new line is appended to harness-evidence.jsonl
  And the line has event="v3_friction"
  And the line has schema_version=1
  And the line has class="between_plan"
  And the line has description="Lost a tangent insight between plan A end and plan B start"
  And the line has could_phase_0_handle=false
  And the line has workaround_used="Wrote it in a scratch note that I never reread"
  And the line has timestamp matching ISO8601 UTC
  And the helper exits 0

# REQ-001
Scenario: missing required field rejects with non-zero exit
  When user runs "harness-evidence.sh emit-v3-friction --class between_plan"
  And user omits --description
  Then no line is appended
  And stderr contains "missing required field: description"
  And the helper exits with code 2

# REQ-001
Scenario: invalid class enum rejects
  When user runs:
    """
    harness-evidence.sh emit-v3-friction --class typo_class \
      --description "x" --could-phase-0-handle false --workaround-used "x"
    """
  Then no line is appended
  And stderr contains "invalid class: typo_class (allowed: between_plan|ai_dialogue|external|cross_project)"
  And the helper exits with code 2
```

## Feature: Writer — file_change_summary event

Companion to plan_completed: gives reader a path-only view of files the plan touched, so retrospective can cross-reference without re-running git diff.

```gherkin
# REQ-001, REQ-003
Scenario: emit on plan completion
  Given executing-plans has just emitted a plans-completed.jsonl line
  And the plan's completion_commit is "abc1234"
  And the plan modified files ["a.py","b.py","c.md"]
  When loop.sh calls:
    """
    bash superpowers/lib/harness-evidence.sh emit-file-change-summary \
      "$state_file" abc1234
    """
  Then exactly one new line is appended
  And the line has event="file_change_summary"
  And the line has schema_version=1
  And the line has completion_commit="abc1234"
  And the line has files=[{"path":"a.py"},{"path":"b.py"},{"path":"c.md"}]
  And the line has no field named "classified"
  And the line has no field named "diff"

# REQ-003
Scenario: empty paths list is rejected
  Given the state.modified_files is []
  When the helper is invoked with completion_commit set but no paths
  Then no line is appended
  And the helper exits with code 2
  And stderr contains "file_change_summary requires at least one path"
```

## Feature: Reader — retrospective Phase 1 consumption

Retrospective treats `harness-evidence.jsonl` as one of the existing Phase 0 channels (peer to `plans-completed.jsonl` and `bail-out-events.jsonl`). "Un-distilled" = `timestamp > <last evolution-log.jsonl retrospective_run.timestamp>`.

```gherkin
Background:
  Given evolution-log.jsonl records last retrospective_run.timestamp = "2026-04-01T00:00:00Z" (T0)

# REQ-004
Scenario: distill N un-distilled rows via ONE Haiku call
  Given harness-evidence.jsonl has 7 session_recap rows after T0 and 3 rows before T0
  When retrospective Phase 1 step 8 reads the channel
  Then Phase 1 processes exactly the 7 rows after T0
  And exactly one run_haiku_merge call is made over the concatenated content
  And Phase 1 includes counts per event type in the retro report
  And the distilled paragraph appears under section 4.5a of the retro report

# REQ-004
Scenario: Haiku distill fails — fall back to raw evidence dump
  Given harness-evidence.jsonl has 5 session_recap rows after T0
  And run_haiku_merge returns ""
  When retrospective Phase 1 step 8 reads the channel
  Then section 4.5a of the retro report contains up to 5 verbatim recap_one_sentence strings
  And no warning aborts the retrospective
  And Phase 1 exits 0

# REQ-004
Scenario: zero un-distilled rows
  Given harness-evidence.jsonl has 0 rows after T0
  When retrospective Phase 1 step 8 reads the channel
  Then the retro report contains the literal string "harness-evidence: 0 rows since 2026-04-01T00:00:00Z"
  And the retro report contributes a "30-day read-rate counter" data point

# REQ-004
Scenario: jsonl file does not exist
  Given "/tmp/ws/proj/docs/retros/harness-evidence.jsonl" is absent
  When retrospective Phase 1 step 8 reads the channel
  Then Phase 1 treats it as 0 rows, no warning
  And the retro report still contributes the 30-day counter "0"

# REQ-004
Scenario: jsonl contains a corrupted row
  Given harness-evidence.jsonl has 5 rows of which row 3 is the malformed text "{not closing brace"
  When retrospective Phase 1 step 8 reads the channel
  Then rows 1, 2, 4, 5 are processed normally
  And row 3 is skipped
  And a warning is printed to stderr including row number 3
  And the retro report notes "1 corrupted row skipped"
  And Phase 1 exits 0

# REQ-006
Scenario: reader tolerates unknown fields (forward compat)
  Given a row added a field "extra_signal"
  And the row has all schema_version=1 required fields
  When the current reader processes that row
  Then the row is processed normally
  And the unknown field is ignored, not echoed to the report
  And no warning is printed

# REQ-006
Scenario: reader tolerates schema_version="1.1" minor bump
  Given a row has schema_version="1.1" with additive new fields
  When the current reader processes that row
  Then the row is processed normally

# REQ-006
Scenario: reader flags unknown major schema_version
  Given a row has schema_version=2
  When the current reader processes that row
  Then the row is counted as "skipped: unknown major version"
  And the retro report flags the operator to upgrade the reader
  And Phase 1 still completes successfully on the remainder
```

## Feature: Audit CLI — independent run path

`harness-evidence.sh audit` runs anywhere — cron, CI, manual, retrospective Phase 1. Same code path; same trigger logic. Removes the "retract triggers fire only when retrospective is run" circular dependency.

```gherkin
# REQ-009
Scenario: audit exits 0 when no triggers fire and allowlist is intact
  Given today's date is 2026-05-15
  And a retro report dated 2026-05-12 in the project contains the substring "harness-evidence"
  And harness-evidence.jsonl contains only allowlisted event values
  When the operator runs "bash superpowers/lib/harness-evidence.sh audit"
  Then exit code is 0
  And stderr is empty

# REQ-005, REQ-009
Scenario: T3 calendar age-out reached
  Given today's date is 2027-05-09 (HARNESS_EVIDENCE_NOW="2027-05-09T00:00:00Z")
  When the operator runs "bash superpowers/lib/harness-evidence.sh audit"
  Then stderr contains the literal string "harness-evidence T3 age-out reached, AskUserQuestion to confirm retract"
  And exit code is 1

# REQ-005, REQ-009
Scenario: T4 read-rate trigger — 30 days of zero references
  Given the last 30 days of retro reports never contain the literal substring "harness-evidence"
  When the operator runs "bash superpowers/lib/harness-evidence.sh audit"
  Then stderr contains "harness-evidence T4 read-rate trigger, AskUserQuestion to confirm retract"
  And exit code is 1

# REQ-009
Scenario: T4 not triggered — channel was referenced last week
  Given the retro report dated 2026-05-12 contains the substring "harness-evidence"
  When the operator runs "bash superpowers/lib/harness-evidence.sh audit"
  Then stderr contains no T4 marker
  And exit code is 0

# REQ-005, REQ-009
Scenario: T3 and T4 both fire — both surfaced, single non-zero exit
  Given today is 2027-05-09 (HARNESS_EVIDENCE_NOW="2027-05-09T00:00:00Z")
  And the last 30 days of retro reports never contain "harness-evidence"
  When the operator runs "bash superpowers/lib/harness-evidence.sh audit"
  Then stderr contains both T3 and T4 markers on separate lines
  And exit code is 1
  And the retrospective Phase 1 step 8 reader, on parsing this, emits one coalesced AskUserQuestion listing both reasons

# REQ-011, REQ-012
Scenario: audit detects an out-of-band allowlist violation
  Given a row with event="ad_hoc_capture" was written directly via `>>` (bypassing the CLI dispatcher)
  When the operator runs "bash superpowers/lib/harness-evidence.sh audit"
  Then stderr contains "harness-evidence allowlist violation: unexpected event(s): ad_hoc_capture"
  And exit code is 2
```
