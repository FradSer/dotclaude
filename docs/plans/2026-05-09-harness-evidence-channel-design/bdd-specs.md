# harness-evidence channel — BDD specs

Channel path: `<git_root>/docs/retros/harness-evidence.jsonl`
Schema: NDJSON, `schema_version=1`, `event ∈ {v3_friction, session_recap, file_change_summary}`
Writer entry: `bash superpowers/lib/harness-evidence.sh <subcmd> [args]`
Hook coupling: Stop hook always invokes; filtering applied inside helper
Reader entry: retrospective Phase 1 step 8 — distill rows with `timestamp > <last evolution-log.jsonl retrospective_run.timestamp>`

## Requirement coverage map

| REQ | Covered by Feature |
|---|---|
| REQ-001 | Writer — session_recap event / Writer — v3_friction event / Writer — file_change_summary event |
| REQ-002 | Writer — session_recap event (empty-session filter scenarios) |
| REQ-003 | Writer — file_change_summary event |
| REQ-004 | Reader — retrospective Phase 1 consumption |
| REQ-005 | Retract trigger detection |
| REQ-006 | Reader — schema versioning compatibility |
| REQ-007 | Writer — Sonnet latency containment (latency-budget scenario) |
| REQ-008 | Writer — concurrent append + disk-full + jsonl integrity |
| REQ-009 | Writer — Sonnet failure fallback |
| REQ-010 | Retract trigger detection (T4 read-rate) |
| REQ-011 | Retract trigger detection (T5 writer reliability) |
| REQ-012 | Schema event-type allowlist audit |

## Feature: Writer — session_recap event

Stop hook captures one paragraph per non-empty session so retrospective has prose-grained "what happened" evidence beyond `plan_completed` deltas.

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
  When the Stop hook calls "harness-evidence.sh emit-session-recap"
  Then "/tmp/ws/proj/docs/retros/harness-evidence.jsonl" gains exactly one new line
  And that line parses as JSON
  And the line has event="session_recap"
  And the line has schema_version=1
  And the line has skill_name="executing-plans"
  And the line has task="Implement post-plan-diff classifier"
  And the line has recap_paragraph of byte length between 200 and 500
  And the line has fallback=false
  And the line has timestamp matching ISO8601 UTC
  And the line has session_id of 12 hex chars
  And the Stop hook exits 0

# REQ-001, REQ-002
Scenario: happy path — brainstorming session with no file changes
  Given the session state file has skill_name="brainstorming"
  And the session state file has task="Design harness-evidence channel"
  And the session state file has modified_files=[]
  And the session state file has pending_prompt="next: write plan"
  When the Stop hook calls "harness-evidence.sh emit-session-recap"
  Then exactly one new line is appended
  And the line has event="session_recap"
  And the line has skill_name="brainstorming"
  And the line has modified_files=[]

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

# REQ-009
Scenario: Sonnet recap call fails — write fallback row using state.task
  Given Sonnet is unreachable (HARNESS_EVIDENCE_SKIP_SONNET=1)
  And vet.sh has produced state.task="Refactored utils.sh acquire_state_lock"
  When the Stop hook calls "harness-evidence.sh emit-session-recap"
  Then exactly one new line is appended
  And the line has fallback=true
  And the line has recap_paragraph="Refactored utils.sh acquire_state_lock"
  And the line has all other required fields populated normally
  And the Stop hook exits 0

# REQ-008
Scenario: concurrent Stop hooks append without corruption
  Given two Stop hooks fire within 50 ms
  And both produce non-empty session_recap candidates
  When both call "harness-evidence.sh emit-session-recap" in parallel
  Then "harness-evidence.jsonl" contains exactly two new lines
  And each line is independently valid JSON terminated by "\n"
  And no line is interleaved or truncated

# REQ-001
Scenario: not inside a git repository — silent skip
  Given the cwd "/tmp/scratch" has no ancestor with a ".git" directory
  When the Stop hook calls "harness-evidence.sh emit-session-recap"
  Then no file is created anywhere
  And a single-line warning is printed to stderr
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

# REQ-007
Scenario: Sonnet latency 8s timeout enforced
  Given Sonnet is slow (8.5s response)
  And the helper's Sonnet timeout is 8s
  When the Stop hook calls "harness-evidence.sh emit-session-recap"
  Then _run_sonnet_recap returns empty within 8.5s wall-clock
  And the row is written with fallback=true
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
Scenario: distill N un-distilled rows
  Given harness-evidence.jsonl has 7 rows after T0 and 3 rows before T0
  When retrospective Phase 1 step 8 reads the channel
  Then Phase 1 processes exactly the 7 rows after T0
  And Phase 1 includes counts per event type in the retro report
  And Phase 1 includes at least one verbatim recap_paragraph in the report

# REQ-004, REQ-010
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

## Feature: Retract trigger detection

Three triggers, all surface via AskUserQuestion in the retrospective report; never auto-disable.

```gherkin
# REQ-005
Scenario: T3 calendar age-out reached
  Given today's date is 2027-05-09 or later (HARNESS_EVIDENCE_NOW="2027-05-09T00:00:00Z")
  When retrospective Phase 1 step 8 runs
  Then the retro report contains the literal string "harness-evidence T3 age-out reached, AskUserQuestion to confirm retract"
  And the retro report block is rendered prominently as top-level

# REQ-005, REQ-010
Scenario: T4 read-rate trigger — 30 days of zero references
  Given the last 30 days of retro reports never contain the literal substring "harness-evidence"
  When retrospective Phase 1 step 8 runs
  Then the retro report contains "harness-evidence T4 read-rate trigger, AskUserQuestion to confirm retract"

# REQ-005
Scenario: T4 not triggered — channel was referenced last week
  Given the retro report dated 2026-05-12 contains the substring "harness-evidence"
  When retrospective Phase 1 step 8 runs
  Then no T4 marker is emitted

# REQ-005, REQ-011
Scenario: T5 writer reliability trigger — fallback ratio above 5%
  Given the last 30 days have 100 session_recap rows of which 6 have fallback=true
  When retrospective Phase 1 step 8 runs
  Then the retro report contains "harness-evidence T5 writer-reliability trigger, AskUserQuestion to confirm retract"

# REQ-005
Scenario: T5 not triggered — fallback ratio below 5%
  Given the last 30 days have 100 session_recap rows of which 4 have fallback=true
  When retrospective Phase 1 step 8 runs
  Then no T5 marker is emitted

# REQ-005
Scenario: T3 and T4 both fire — single coalesced AskUserQuestion
  Given today is 2027-05-09 (HARNESS_EVIDENCE_NOW="2027-05-09T00:00:00Z")
  And the last 30 days of retro reports never contain "harness-evidence"
  When retrospective Phase 1 step 8 runs
  Then both T3 and T4 markers are present in the retro report
  And Phase 6 instructs a single AskUserQuestion that lists both reasons
  And no two separate AskUserQuestion calls fire in the same retrospective run
```

## Feature: Schema event-type allowlist

Audit the channel's discipline against silent type growth (covers REQ-012).

```gherkin
# REQ-012
Scenario: 30-day audit produces only 3 distinct event values
  Given 30 days of harness-evidence.jsonl rows from a project
  When the auditor runs "jq -r .event harness-evidence.jsonl | sort -u"
  Then the output is a subset of {"file_change_summary","session_recap","v3_friction"}
  And no other event value appears

# REQ-012
Scenario: smuggled fourth event type FAILS the audit
  Given the channel contains one row with event="ad_hoc_capture"
  When the 30-day audit runs
  Then the audit FAILS with "unexpected event values: ad_hoc_capture"
```
