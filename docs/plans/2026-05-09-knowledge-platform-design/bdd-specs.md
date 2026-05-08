# BDD Specs — superpowers v3.x Knowledge Platform

**Companion to**: `_index.md` (FR/NFR/SC), `architecture.md` (data flow + schemas), `best-practices.md`.
**Status**: Draft, design-stage. No `.feature` files generated until plan approval.

This document inventories Given/When/Then scenarios for the four content sources covered by v3.x, the three hard architecture rules, the calibration self-test loop, privacy violation detection, performance / compatibility, and calibration metrics. Every scenario is self-contained — implementable as one `.feature` scenario plus one verification command.

**Requirement traceability** (REQ-TRACE-01): every scenario carries `# Covers: <ID-list>` referencing FR/NFR/SC IDs from `_index.md`. Each FR/NFR/SC ID is covered by ≥1 scenario.

Phase tags (`@phase-1`, `@phase-2`, `@phase-3`) align scenarios to `architecture.md` §4 phased rollout. Implementations honor the phase gates: a `@phase-2` scenario does NOT execute until Phase 1 retract gate passes (per Law 3).

---

## 1. Source A — between-plan code work (Phase 1)

```gherkin
Feature: Capture between-plan code work without manual ceremony

  # Covers: FR-01, FR-13
  @phase-1
  Scenario: Happy path — refactor commit between plans is auto-classified
    Given the most recent plans-completed.jsonl entry is older than 1h
    And the user makes a commit "refactor(api): extract validator"
    When the post-commit hook fires
    Then docs/retros/knowledge-events.jsonl gains one row with event="between_plan_capture", class="refactor", privacy_tier="local-only"
    And the row carries plan_context=null since no plan is active
    And read_count is initialized to 0
    Verify: jq -e 'select(.event=="between_plan_capture" and .class=="refactor")' docs/retros/knowledge-events.jsonl

  # Covers: FR-01
  @phase-1
  Scenario: Edge case — 200-commit experimental burst on a throwaway branch
    Given the user is on a branch matching pattern "exp/*"
    And the user makes 200 commits within 30 minutes
    When the post-commit hook fires for each commit
    Then knowledge-events.jsonl receives at most 1 aggregated row per 10-commit window with event="between_plan_burst"
    And the row's commit_count field equals the actual count
    Verify: test $(jq -s '[.[] | select(.event=="between_plan_burst")] | length' docs/retros/knowledge-events.jsonl) -le 20

  # Covers: FR-01
  @phase-1
  Scenario: Error condition — git hook crashes mid-write
    Given the post-commit hook is writing a knowledge_event row
    When the process is killed before flush completes
    Then on next hook invocation the partial line is detected via jq try/catch
    And a recovery row event="hook_recovery", reason="partial_write" is appended
    And the corrupted line is moved to docs/retros/.quarantine/
    Verify: test -f docs/retros/.quarantine/knowledge-events.jsonl.partial-* && jq -e 'select(.event=="hook_recovery")' docs/retros/knowledge-events.jsonl
```

---

## 2. Source B — AI dialogue deposit (Phase 2)

```gherkin
Feature: Capture user-deposited AI dialogue from other tools

  # Covers: FR-02, FR-03, FR-09
  @phase-2
  Scenario: Happy path — user deposits a Codex transcript via active capture verb
    Given Phase 1 retract gate has passed (≥1 read per Phase 1 component across N=3 projects)
    And ~/.claude/projects/<project-key>/knowledge/ directory exists
    And the user explicitly enabled v3.x dialogue capture for this project (per FR-03 default-off)
    When the user runs "/superpowers:deposit ai-log codex" with transcript text on stdin
    Then ~/.claude/projects/<project-key>/knowledge/deposits/codex-<timestamp>.md is created
    And ~/.claude/projects/<project-key>/knowledge/decisions.ndjson gains event="decision_deposited", source_tool="codex", privacy_tier="cross-session", word_count=<N>
    And no content is forwarded to local-only tier (B→local-only is architecturally blocked per FR-09)
    Verify: jq -e 'select(.event=="decision_deposited" and .privacy_tier=="cross-session")' ~/.claude/projects/<project-key>/knowledge/decisions.ndjson

  # Covers: FR-03
  @phase-2
  Scenario: Default-off — fresh project rejects deposit until opt-in
    Given the user is in a fresh project that has not run "/superpowers:knowledge enable ai-dialogue"
    When the user runs "/superpowers:deposit ai-log codex" with stdin text
    Then the skill refuses with "AI-DIALOGUE-OFF: this channel is opt-in (FR-03); run /superpowers:knowledge enable ai-dialogue first"
    And no file is written under ~/.claude/projects/<project-key>/knowledge/
    Verify: pytest tests/test_ai_dialogue_default_off.py::test_rejects_until_enabled

  # Covers: FR-10
  @phase-2
  Scenario: Edge case — user retracts a deposit after consumption (append-only)
    Given a decision_deposited event exists with id=DEC-042
    And brainstorming has already cited DEC-042 in a plan (read_count > 0)
    When the user runs "/superpowers:knowledge retract DEC-042"
    Then a tombstone event="decision_retracted", id="DEC-042" is appended (append-only, per FR-10)
    And the deposit file is moved to ~/.claude/projects/<project-key>/knowledge/.retracted/
    And the original decision_deposited row is NOT deleted (audit history survives)
    And subsequent retrospective Phase 1 readers skip DEC-042 via the tombstone check
    Verify: jq -e 'select(.event=="decision_retracted" and .id=="DEC-042")' decisions.ndjson && test ! -f ~/.claude/projects/<project-key>/knowledge/deposits/DEC-042.md

  # Covers: FR-02
  @phase-2
  Scenario: Error condition — deposit exceeds 50k tokens (token budget violation)
    Given an incoming ai-log deposit measures >50,000 tokens
    When the deposit skill validates size
    Then it refuses to write the deposit file
    And appends event="deposit_rejected", reason="token_budget_exceeded", actual_tokens=<N>
    And exits with non-zero status to surface failure to the user
    Verify: pytest tests/test_deposit_size_gate.py::test_rejects_oversize_log
```

---

## 3. Source C — cross-project pattern transfer (Phase 3)

```gherkin
Feature: Migrate patterns from project A to project B with explicit consent

  # Covers: FR-05, FR-09
  @phase-3
  Scenario: Happy path — user opts in to import a refactor pattern
    Given Phase 2 retract gate has passed
    And ~/.superpowers/kg/patterns.ndjson contains a row with pattern_id="PAT-007", privacy_tier="cross-project"
    And the user is now in project B
    When the user runs "/superpowers:knowledge import PAT-007"
    Then project B receives event="pattern_imported", source_project=<A-hash>, pattern_id="PAT-007" in docs/retros/knowledge-events.jsonl
    And the import is recorded in ~/.superpowers/kg/patterns.ndjson as the audit trail
    Verify: jq -e 'select(.event=="pattern_imported" and .pattern_id=="PAT-007")' docs/retros/knowledge-events.jsonl

  # Covers: FR-05
  @phase-3
  Scenario: Edge case — same pattern imported twice into same project
    Given project B already has a pattern_imported event for PAT-007
    When the user re-runs the import
    Then the skill appends event="pattern_import_skipped", reason="already_present"
    And no duplicate row is created
    Verify: test $(jq -s '[.[] | select(.pattern_id=="PAT-007" and .event=="pattern_imported")] | length' docs/retros/knowledge-events.jsonl) -eq 1

  # Covers: FR-09, NFR-02
  @phase-3
  Scenario: Error condition — pattern marked local-only is reached cross-project
    Given project A pattern PAT-099 carries privacy_tier="local-only" (architectural error condition — should never happen, but defense-in-depth)
    When project B requests import of PAT-099
    Then the import is refused with exit code 4 (privacy_violation)
    And ~/.claude/privacy-violations.jsonl gains event="privacy_violation", direction="local_to_cross_project"
    Verify: pytest tests/test_cross_project_privacy.py::test_local_only_blocks_cross_project_import
```

---

## 4. Source D — external citations (Phase 3)

```gherkin
Feature: Track external resources as advisory citations

  # Covers: FR-04, FR-09
  @phase-3
  Scenario: Happy path — user cites a URL in a plan
    Given Phase 3 has unlocked
    And the user is editing a plan _index.md and writes "[Source: https://arxiv.org/abs/2505.18279]"
    When the citation hook fires (or the user runs "/superpowers:knowledge cite <url>")
    Then ~/.superpowers/external/cache/<sha1>.md contains the fetched content + fetch_timestamp
    And ~/.superpowers/external/citations.ndjson gains event="external_cited", privacy_tier="external", embed_into_kg=false
    Verify: jq -e 'select(.event=="external_cited" and .embed_into_kg==false)' ~/.superpowers/external/citations.ndjson

  # Covers: FR-04
  @phase-3
  Scenario: Error condition — license not in allowlist
    Given the user attempts to cite a URL from a domain not in the per-domain allowlist (e.g., proprietary paywalled doc)
    When the citation skill validates license
    Then the skill emits "LICENSE-WARN: domain X not in allowlist; cite anyway? (y/N)"
    And on rejection, no cache file is written and event="external_cite_rejected", reason="license_not_allowlisted" is appended
    Verify: jq -e 'select(.event=="external_cite_rejected")' ~/.superpowers/external/citations.ndjson
```

---

## 5. Hard architecture rules — BDD landings

### Rule 1: Retract gate (every component carries retract triggers)

```gherkin
Feature: Components surface retract candidates when triggers fire

  # Covers: FR-13, FR-14
  @rule-1
  Scenario: Component below retract threshold continues running
    Given component "between_plan_capture" has produced 5 capture events in the last 30 days
    And read_count summed across rows is ≥3 across N=3 projects
    When the calibration sweep runs (during retrospective Phase 5a)
    Then the component remains active
    And event="retract_check", component="between_plan_capture", verdict="keep" is logged
    Verify: jq -e 'select(.event=="retract_check" and .verdict=="keep")' evolution-log.jsonl

  # Covers: FR-12, FR-14, NFR-05
  @rule-1
  Scenario: Component meets retract trigger and is surfaced for AskUserQuestion (NEVER auto-disabled per meta-retro R1)
    Given component "external_cache" has 0 read events for 60 consecutive days across N=3 projects
    When the calibration sweep runs
    Then retrospective Phase 5a surfaces "RETRACT-CANDIDATE: external_cache" via AskUserQuestion (NOT auto-disable)
    And on user "Approve disable", a harness-config.json disabled_components entry is appended
    And on user "Keep", event="retract_declined", component="external_cache" is logged
    And NFR-05 reversibility is honored: a single config entry disables the component
    Verify: jq -e 'select(.event=="retract_declined" or (.event=="retract_check" and .verdict=="surfaced"))' evolution-log.jsonl
```

### Rule 2: Privacy tier opt-in

```gherkin
Feature: Cross-tier data flow requires explicit opt-in

  # Covers: FR-11, FR-09
  @rule-2
  Scenario: User attempts to elevate a deposit from cross-session to cross-project
    Given deposit DEC-042 has privacy_tier="cross-session" (Source B native tier)
    When the user runs "/superpowers:knowledge promote DEC-042 --to cross-project"
    Then AskUserQuestion presents "Confirm tier elevation: cross-session → cross-project (sanitizer will run)"
    And on "Confirm", the sanitizer scans for absolute paths / env-vars / credentials
    And on sanitizer pass, decisions.ndjson gains event="tier_elevated", from="cross-session", to="cross-project"
    And on "Cancel" OR sanitizer fail, no mutation occurs and event="tier_elevation_declined" or "tier_elevation_blocked" is appended
    Verify: jq -e 'select(.event=="tier_elevated" and .to=="cross-project")' decisions.ndjson

  # Covers: FR-09, NFR-02
  @rule-2
  Scenario: Architectural block — B → local-only attempted
    Given a Source B (cross-session) row exists in decisions.ndjson
    When some skill or user action attempts to write the same content to docs/retros/ (local-only tier)
    Then lib/knowledge-write.sh rejects with exit code 3 (tier_demotion_blocked)
    And event="tier_demotion_blocked", source_tier="cross-session", target_tier="local-only" is logged
    Verify: pytest tests/test_tier_matrix.py::test_b_to_local_blocked
```

### Rule 3: Phase gate with calibration evidence

```gherkin
Feature: Phase advancement requires prior-phase calibration data

  # Covers: FR-12, NFR-05
  @rule-3
  Scenario: Phase 2 unlock blocked when Phase 1 read-rate insufficient
    Given Phase 1 (between_plan_capture + audit_view) has produced events but read_count == 0 across N<3 projects
    When the user runs "/superpowers:knowledge advance-phase --to phase-2"
    Then the command refuses with "PHASE-GATE-LOCKED: phase 2 requires Phase 1 read-rate ≥1 across N=3 projects (current: read=0, projects=2)"
    And event="phase_advance_refused", current_phase=1, target_phase=2, evidence_shortfall={"read_count":0,"projects":2} is logged
    Verify: jq -e 'select(.event=="phase_advance_refused" and .target_phase==2)' evolution-log.jsonl

  # Covers: FR-12
  @rule-3
  Scenario: Phase 2 unlocks after gate passes
    Given Phase 1 evidence: read_count summed ≥3 across N=3 projects
    When the user runs "/superpowers:knowledge advance-phase --to phase-2"
    Then harness-config.json removes the disabled_components entry for "v3_phase_2_deposit"
    And event="phase_advanced", from_phase=1, to_phase=2 is logged
    Verify: jq -e 'select(.event=="phase_advanced" and .to_phase==2)' evolution-log.jsonl
```

---

## 6. Meta-recursive calibration self-test

```gherkin
Feature: v3.x components self-retract when they fail to earn cost

  # Covers: FR-13, FR-14
  @meta-recursive
  Scenario: v3.x retrospective records its own zero-change run
    Given v3.x retrospective completes with 0 approved proposals and disable_test_set=false
    When Phase 6 closure writes the retrospective_run row
    Then the row's self_value.consecutive_zero_change increments by 1
    And when consecutive_zero_change reaches 2, the next retrospective surfaces "RETRACT-SELF: v3.x retrospective has produced no signal in 2 runs" via AskUserQuestion
    Verify: jq -e 'select(.event=="retrospective_run" and .self_value.consecutive_zero_change==2)' evolution-log.jsonl

  # Covers: FR-12, NFR-05
  @meta-recursive
  Scenario: A surfaced v3.x component is reinstated by user evidence
    Given component "external_cache" was surfaced as retract candidate AND user approved disable
    And the user collects 3 new citation deposits worth of evidence
    When the user runs "/superpowers:knowledge reinstate external_cache --evidence <path>"
    Then event="component_reinstated", reinstatement_method="manual_correction", component="external_cache" is appended (per evolution-protocol.md schema)
    And harness-config.json disabled_components entry for external_cache is removed
    And the component resumes accepting citations on next invocation
    Verify: jq -e 'select(.event=="component_reinstated" and .component=="external_cache")' evolution-log.jsonl
```

---

## 7. Privacy violation detection

```gherkin
Feature: Detect and halt cross-tier privacy leaks

  # Covers: NFR-02, SC-03
  @privacy
  Scenario: Sanitizer catches credential-shaped string before cross-project promotion
    Given a Source B row contains "AWS_SECRET_ACCESS_KEY=AKIA..." (per best-practices §1 threat model)
    When the user attempts cross-tier promotion to cross-project
    Then the sanitizer detects the credential pattern via regex match
    And the promotion is refused with exit code 5 (cross_contamination)
    And event="privacy_violation", reason="credential_shape_detected", offending_pattern_class="aws_key" is logged in ~/.claude/privacy-violations.jsonl
    Verify: pytest tests/test_sanitizer.py::test_blocks_aws_key

  # Covers: NFR-02, SC-03
  @privacy
  Scenario: Cross-project import contaminated with another project's absolute paths
    Given pattern PAT-007 references file paths from project A (e.g., "/Users/alice/projA/src/foo.py")
    When project B imports PAT-007 via the cross-project channel
    Then a sanitizer scans the payload for absolute paths matching foreign repo_root values
    And on detection, the import is halted with exit code 5
    And event="cross_contamination_blocked", offending_paths=[...] is logged in ~/.claude/privacy-violations.jsonl
    Verify: pytest tests/test_sanitizer.py::test_blocks_foreign_absolute_paths
```

---

## 8. Audit view (FR-15)

```gherkin
Feature: User reviews v3.x captured items in under 1 minute

  # Covers: FR-15, NFR-04, SC-05
  @phase-1 @audit
  Scenario: Happy path — audit view renders all Phase 1 captures grouped by tier
    Given the current project has 50 entries in docs/retros/knowledge-events.jsonl
    When the user runs "/superpowers:audit"
    Then output renders within 1s (NFR-04)
    And entries are grouped by privacy_tier (local-only / cross-session / cross-project / external)
    And each group shows: count, oldest timestamp, newest timestamp, top-5 by read_count
    And total reading time fits under 60s for N≤1000 entries (SC-05)
    Verify: time pytest tests/test_audit_view.py::test_renders_50_under_1s

  # Covers: FR-10, FR-15
  @audit
  Scenario: User retracts via audit view
    Given the audit view lists 50 captured items
    When the user selects entry IDX-23 and runs "/superpowers:knowledge retract IDX-23"
    Then the event="retracted", id="IDX-23" is appended to the source channel
    And the audit view on next render shows IDX-23 as "[retracted YYYY-MM-DD]"
    Verify: jq -e 'select(.event=="retracted" and .id=="IDX-23")' docs/retros/knowledge-events.jsonl
```

---

## 9. Performance & compatibility

```gherkin
Feature: v3.x respects performance budget and backward compatibility

  # Covers: NFR-01, SC-04
  @performance
  Scenario: Stop-hook latency stays within v3.x budget
    Given v3.x Phase 1 components are active in a project with 1000 captured items
    When the user fires a Stop hook (promise emitted)
    Then total Stop-hook latency does not exceed v2.8.2 baseline + 50ms p50 / 200ms p99
    And the regression is measured by a CI benchmark on the user-simulation project
    Verify: pytest tests/perf/test_stop_hook_v3x_regression.py::test_under_budget

  # Covers: NFR-03
  @backward-compat
  Scenario: v3.x reads v2.8.x channels without rewrite
    Given a project has v2.8.x-era plans-completed.jsonl entries with absolute paths and missing completion_commit
    When v3.x retrospective Phase 1 reads the file
    Then pre-v3.x rows are read with their original schema; no migration step runs
    And v3.x consumers prefer v3.x channels for new analyses, leaving stale absolute-path entries to age out
    Verify: pytest tests/test_backward_compat.py::test_v2_entries_read_unchanged

  # Covers: NFR-07
  @zero-cost-default
  Scenario: Fresh project produces zero v3.x file writes until activated
    Given a fresh project with no docs/retros/knowledge-events.jsonl and no ~/.claude/projects/<key>/knowledge/
    And the user runs a brainstorming → plan → execute → retrospective cycle without enabling v3.x channels
    When the cycle completes
    Then no v3.x files have been written (only v2.8.x baseline files exist)
    And the user observes zero overhead from v3.x being installed
    Verify: pytest tests/test_zero_cost_default.py::test_no_v3x_writes_when_unactivated

  # Covers: NFR-08
  @schema-version
  Scenario: Schema version drift tolerance
    Given knowledge-events.jsonl contains rows with schema_version=1 and schema_version=2 (post-rollout)
    When a v3.x consumer reads the channel
    Then rows with schema_version within ±1 major version are accepted
    And rows outside that range emit "SCHEMA-DRIFT-WARN: row schema=N, consumer accepts N±1" but do not crash
    Verify: pytest tests/test_schema_drift.py::test_accepts_one_major_version_drift
```

---

## 10. Calibration metrics

```gherkin
Feature: v3.x calibration metrics meet success criteria across N=3 projects

  # Covers: SC-01
  @calibration
  Scenario: SC-01 — every Phase 1 component has ≥1 read per project across N=3
    Given v3.1 has run on N=3 distinct projects
    When the SC-01 sweep aggregates read_count across knowledge-events.jsonl per project
    Then every Phase 1 component (between_plan_capture, audit_view) has read_count ≥ 1 per project
    And components below threshold are surfaced as retract candidates by the next retrospective (per FR-14)
    Verify: pytest tests/test_calibration_metrics.py::test_sc01_phase1_read_rate

  # Covers: SC-02
  @calibration
  Scenario: SC-02 — retract candidates count stays below threshold
    Given v3.1 has run on N=3 distinct projects
    When the SC-02 sweep counts components surfaced as retract candidates
    Then the count is ≤ 1 across the N=3 sample
    And if count ≥ 2, Phase 2 freezes until the cause is diagnosed and the meta-recursive calibration rule itself is re-validated
    Verify: pytest tests/test_calibration_metrics.py::test_sc02_retract_count_under_threshold

  # Covers: SC-03
  @calibration
  Scenario: SC-03 — privacy-tier violation pre-edit detection achieves 100% on 20-case corpus
    Given a curated 20-case test corpus exists at tests/fixtures/privacy_violations/
    And cases include: AWS keys, GCP credentials, absolute paths, env-var values, partial diffs against .env files
    When the v3.x sanitizer runs against each case
    Then 20/20 cases are detected and blocked
    And no false negatives (all 20 trigger privacy_violation event)
    Verify: pytest tests/test_sanitizer_corpus.py::test_20_case_corpus_full_coverage

  # Covers: NFR-06
  @test-coverage
  Scenario: Every new lib script ships with an integration test
    Given v3.x adds new lib scripts under superpowers/lib/ (e.g., knowledge-write.sh, sanitizer.sh)
    When CI runs the test suite
    Then each new lib script has at least one integration test that reproduces a realistic capture-then-read cycle
    And no lib script ships with mock-only coverage
    Verify: pytest tests/test_lib_coverage.py::test_every_lib_has_integration_test
```

---

## BDD-level decisions

### Resolved (defaults locked at design time)

- **Q-CHANNEL-SCOPE — RESOLVED**: `~/.superpowers/kg/patterns.ndjson` is global with a `project_origin` field on each row. Per-project view is reconstructable via `jq 'select(.project_origin == "<hash>")'`. No per-project file fragmentation — keeps cross-project query trivial.

### Deferred to writing-plans phase

- **Q-COOLDOWN**: should tier elevation have a 24h cooldown to prevent accidental rapid-fire promotions? Defer — only relevant if Phase 2 promote rate exceeds the Q-CONSENT-UI ≤5/week soft threshold. If reached, writing-plans phase adds a cooldown table to `lib/knowledge-write.sh` config.
- **Q-AGGREGATION-WINDOW**: §1.2 burst aggregation uses a hard-coded 10-commit window. Should be configurable per project. Defer the config plumbing (single env var or per-repo config file) to writing-plans phase; the constant in v3.0 is fine for first release.
- **Q-AUDIT-STREAMING**: for N>1000 entries, audit view streaming output vs. paged? Defer to v3.x performance benchmarking once a real project exceeds 1000 entries (none currently exists).

End of bdd-specs draft. Total: ~32 scenarios across 10 sections, full FR/NFR/SC traceability via `# Covers:` tags.

## Coverage matrix (verification)

| ID | Covered by |
|---|---|
| FR-01 | §1.1, §1.2, §1.3 |
| FR-02 | §2.1, §2.4 |
| FR-03 | §2.1, §2.2 |
| FR-04 | §4.1, §4.2 |
| FR-05 | §3.1, §3.2 |
| FR-06 | (integration anchor — exercised implicitly by §1, §5 retract_check reads v3.x channels) |
| FR-07 | (integration anchor — brainstorming Phase 1.5 reads decisions; covered by deposit consumption in §2.1) |
| FR-08 | (integration anchor — executing-plans Phase 6 appends decision-tier; covered by Source A path) |
| FR-09 | §2.1, §3.1, §3.3, §5 Rule 2 |
| FR-10 | §2.3, §8.2 |
| FR-11 | §5 Rule 2 |
| FR-12 | §5 Rule 1, §5 Rule 3, §6 reinstate |
| FR-13 | §1.1, §5 Rule 1, §6 self-test |
| FR-14 | §5 Rule 1, §6 self-test |
| FR-15 | §8.1, §8.2 |
| NFR-01 | §9.1 |
| NFR-02 | §3.3, §5 Rule 2, §7 |
| NFR-03 | §9.2 |
| NFR-04 | §8.1 |
| NFR-05 | §5 Rule 1, §5 Rule 3, §6 reinstate |
| NFR-06 | §10.4 |
| NFR-07 | §9.3 |
| NFR-08 | §9.4 |
| SC-01 | §10.1 |
| SC-02 | §10.2 |
| SC-03 | §7, §10.3 |
| SC-04 | §9.1 |
| SC-05 | §8.1 |
