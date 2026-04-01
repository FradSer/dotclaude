# Harness Design Optimizations -- Requirements Document

**Date**: 2026-03-31 (revised 2026-04-01)
**Plugin**: superpowers v2.1.0
**Approach**: Layered Integration (no breaking changes)
**Source**: Anthropic blog "Harness Design for Long-Running Apps"

---

## 1. Requirements Matrix

### REQ-001: Independent Evaluator Agent

| Field | Value |
|---|---|
| **Priority** | P0 (must-have) |
| **Description** | Introduce a standalone Evaluator agent, architecturally separated from the generator (Implementer). The Evaluator reviews completed work with a skeptical lens rather than relying on the generator to self-assess. The Evaluator is spawned via the Agent tool (sub-agent, not teammate) to ensure conversation context isolation. |
| **Rationale** | Blog: "Naive self-evaluation fails. Agents grade themselves too generously." and "Tuning a standalone evaluator to be skeptical is far more tractable than making a generator critical." The current system has no independent evaluator -- verification in Phase 4 is performed by the same orchestrator that directed execution, and the existing Reviewer role (`reviewer-role.md`) is optional and lens-scoped (Security, Performance, etc.) rather than a systematic quality gate. |
| **Architecture** | The Evaluator is an **agent** (defined in `superpowers/agents/evaluator.md`), not a skill. It is spawned as a sub-agent via the Agent tool, which naturally isolates its conversation context from the generator. The agent prompt instructs it to read rubrics and calibration examples on-demand from `executing-plans/references/` using the Read tool -- these are NOT embedded in the agent definition. |
| **Prompt Calibration** | The evaluator agent definition MUST include 2-3 few-shot calibration examples (one PASS, one REWORK, one FAIL) demonstrating expected scoring behavior. Additional calibration examples live in `references/evaluation-rubrics.md` under a "Calibration Examples" section. Blog: "Read the evaluator's logs, find examples where its judgment diverged from mine, and update the QA's prompt to solve for those issues." |
| **Success Criteria** | (1) Evaluator is a distinct agent definition in `superpowers/agents/evaluator.md` with restricted tools: `["Read", "Grep", "Glob", "Bash(test:*)", "Bash(npm:*)", "Bash(pnpm:*)"]` -- no Write/Edit. (2) Evaluator is spawned as a sub-agent (not teammate), ensuring no shared conversation context with the generator. (3) When enabled, Evaluator produces a structured evaluation report (format defined in REQ-006) before any task is marked `completed`. (4) Evaluator prompt includes few-shot calibration examples for scoring consistency. |
| **Dependencies** | REQ-006 (file-based communication for report exchange). |

---

### REQ-002: Sprint Contract Negotiation

| Field | Value |
|---|---|
| **Priority** | P0 (must-have) |
| **Description** | Before each batch begins execution, the Evaluator reviews acceptance criteria from that batch's task files and produces a "sprint contract" -- a concrete, testable checklist that defines done for that specific batch. This replaces the implicit done criteria currently embedded in task YAML. |
| **Rationale** | Blog: "Sprint contracts bridge the gap between user stories and testable implementation." Currently, acceptance criteria live in task files as BDD scenarios and verification commands, but there is no explicit step where an independent party confirms they are sufficient and unambiguous before work starts. |
| **Timing** | Sprint contracts are generated **per-batch, as step 0 of Phase 3's batch loop** -- not as a separate "Phase 2.5." Each batch iteration: (0) Sprint Contract -> (1) Choose Mode -> (2) Execute -> (3) Verify -> (4) Evaluate. |
| **Red-Green Pair Handling** | Sprint contracts MUST distinguish Red-Green pairs: test task's "done" = "tests written and failing for the right reason (Red state)"; impl task's "done" = "all tests pass (Green state, exit code 0)." |
| **Success Criteria** | (1) A `sprint-contract-batch-{N}.md` file is produced per batch before execution begins (format defined in REQ-006). (2) The contract lists each task with its testable acceptance criteria. (3) Ambiguous criteria are flagged and resolved (via user question or refinement) before execution. Maximum 2 negotiation rounds; unresolved items escalate to user as "user-accepted risk." (4) Phase 3 batch execution does not start until the contract file exists for that batch. |
| **Dependencies** | REQ-001 (Evaluator agent produces the contract). |

---

### REQ-003: Graded Evaluation Criteria

| Field | Value |
|---|---|
| **Priority** | P1 (should-have) |
| **Description** | Replace the current binary pass/fail verification gate with a 1-5 graded scoring system. Define per-dimension rubrics with concrete score-level descriptions and configurable thresholds for pass/rework/fail. Dimension weights vary by task type. |
| **Rationale** | Blog: "Grading criteria made subjective quality measurable." The current system uses a hard binary gate (exit code 0 = pass, non-zero = fail) with up to 2 retries. This misses nuanced quality issues -- a task can pass verification commands yet have poor structure, missing edge cases, or subtle deviations from the spec. |
| **Dimensions** | Correctness, Completeness, Code Quality, Test Coverage, Spec Compliance. |
| **Type-Aware Weighting** | Not all dimensions apply equally to all task types: (1) `test` tasks: weight Spec Compliance and Completeness highest; Code Quality secondary. (2) `impl` tasks: weight Correctness and Code Quality highest; Test Coverage secondary. (3) `config`/`setup` tasks: only Correctness and Completeness apply; skip Code Quality, Test Coverage, Spec Compliance. (4) `refactor` tasks: weight Code Quality highest; Correctness must remain unchanged. |
| **Score Calibration** | Each score level (1-5) MUST have a concrete example per dimension in `references/evaluation-rubrics.md`. Example: Correctness 3 = "Logic is correct for the primary path but misses an edge case documented in the BDD scenario." Without concrete examples, scoring is inconsistent across rounds. |
| **Strategic Pivoting** | When a task receives scores of 2 or below on 2+ dimensions across 2 evaluation rounds, the generator SHOULD consider rearchitecting the approach rather than iterating on the same direction. The evaluation report includes a "pivot recommended" flag when this condition is met. Blog: "The generator made a strategic decision after each evaluation: refine if trending well, or pivot if the approach wasn't working." |
| **Success Criteria** | (1) Evaluation reports include per-dimension scores (1-5) for each task, with weights adjusted by task type. (2) Configurable thresholds: default pass >= 4 on all applicable dimensions, rework if any dimension is 2-3, fail if any dimension is 1. (3) Thresholds are adjustable via configuration precedence (see Section 2.4). (4) Existing binary verification gate remains as a prerequisite -- graded evaluation is an additional layer, not a replacement for exit-code checks. (5) Rubrics file contains concrete score-level examples for calibration. |
| **Dependencies** | REQ-001 (Evaluator produces the grades). REQ-006 (grades written to evaluation files). |

---

### REQ-004: Handoff Documentation for Long Plans

| Field | Value |
|---|---|
| **Priority** | P2 (nice-to-have) |
| **Description** | For plans with 16+ tasks, produce structured handoff summaries at configurable boundaries (default: every 3 batches). Handoff summaries capture cumulative state as documentation artifacts for progress tracking and debugging. |
| **Rationale** | Long plans accumulate significant execution state across batches. Structured summaries provide an audit trail and enable recovery if a session is interrupted. Note: Claude Code's built-in context compaction already handles context window management -- handoff documents complement this by providing human-readable progress snapshots, not by "resetting" context (which is not possible within Claude Code's session model). The Superpower Loop's per-iteration prompt re-injection (stop-hook.sh:174-179) already provides a form of context refresh for the orchestrator. |
| **Scope Limitation** | This requirement produces documentation artifacts only. It does NOT reset, compress, or modify Claude Code's conversation context -- that is managed automatically by the platform. |
| **Success Criteria** | (1) A `handoff-summary-{N}.md` file is produced at each boundary containing: completed tasks with evaluation scores, remaining tasks with dependency state, key architectural decisions, file ownership map, and accumulated blockers. (2) No task state is lost -- TaskList remains authoritative. (3) Boundary is configurable (default: every 3 batches or every 15 tasks, whichever comes first). (4) Handoff files follow the format defined in REQ-006. |
| **Dependencies** | None (standalone). Benefits from REQ-006 file patterns. |

---

### REQ-005: Evaluation Intensity Configuration

| Field | Value |
|---|---|
| **Priority** | P2 (nice-to-have) |
| **Description** | Allow users to configure evaluation intensity via three presets that control when the Evaluator runs. Reliable runtime model detection is not available in Claude Code, so this is a manual configuration. |
| **Rationale** | Blog: "On Opus 4.6, sprints were removed entirely. Evaluator moved to single end-of-run pass." and "The evaluator is cost-effective when the task sits at the boundary of the model's solo capability." Over-evaluating wastes tokens; under-evaluating risks quality. Different users and models benefit from different evaluation frequencies. |
| **Presets** | (1) `thorough`: Evaluator runs per-task. Best for lower-capability models or high-stakes work. (2) `standard` (default): Evaluator runs per-batch. Balanced cost/quality. (3) `light`: Evaluator runs once at end-of-plan. Best for high-capability models or simple plans. |
| **No Auto-Detection** | Runtime model detection is not possible in Claude Code (no `$CLAUDE_MODEL` env var; agent frontmatter `model: inherit` does not reveal the actual model). Preset selection is manual via configuration precedence (see Section 2.4). |
| **Success Criteria** | (1) Three presets exist with clear evaluation frequency semantics. (2) Default is `standard` (per-batch). (3) Preset can be overridden via skill argument, plan metadata, or plugin defaults. (4) Sprint contracts adapt: `light` mode produces a simplified summary contract for the entire plan rather than per-batch contracts. (5) In all modes, the evaluator still reviews all tasks -- the difference is frequency, not scope. |
| **Dependencies** | REQ-001 (Evaluator must exist). |

---

### REQ-006: File-Based Evaluator-Generator Communication

| Field | Value |
|---|---|
| **Priority** | P0 (must-have) |
| **Description** | All communication between the Evaluator and Generator occurs through structured files in the plan directory -- never through direct message passing or shared conversation context. This requirement defines both naming conventions AND file content formats. |
| **Rationale** | Blog: "Agents communicated by writing/reading files, not by direct message passing." File-based communication enforces context separation and creates an auditable trail. |
| **Naming Conventions** | `sprint-contract-batch-{N}.md`, `evaluation-round-{N}-batch-{M}.md`, `handoff-summary-{N}.md`. Files live in the plan directory alongside task files. |
| **Sprint Contract Format** | `## Batch {N} Sprint Contract` | `### Tasks` (table: ID, Subject, Type) | `### Acceptance Criteria` (per-task: testable checklist items; Red-Green pairs annotated with expected state) | `### Sign-off` (evaluator timestamp). |
| **Evaluation Report Format** | `## Evaluation Round {N} -- Batch {M}` | `### Per-Task Scores` (table: Task ID, Correctness, Completeness, Code Quality, Test Coverage, Spec Compliance, Verdict) | `### Rework Items` (list: file path + line range, issue description, affected dimension, severity) | `### Recommendations` (non-blocking observations) | `### Pivot Flag` (true/false + rationale if true). Dimensions marked N/A per task type weighting (REQ-003). |
| **Handoff Summary Format** | `## Handoff Summary {N}` | `### Completed Tasks` (table: ID, Subject, Scores, Batch) | `### Remaining Tasks` (table: ID, Subject, Status, Dependencies) | `### Key Decisions` (list) | `### File Ownership` (table: File Path, Last Modified By Task) | `### Blockers` (list). |
| **File Lifecycle** | Evaluation files are written by the evaluator after completion. Generator reads them before retry/rework. Files are NOT committed by default -- they are ephemeral execution artifacts. Users can opt-in to committing them via configuration. |
| **Success Criteria** | (1) All three file formats are defined with concrete section structures. (2) Files follow naming conventions. (3) Rework items include specific file:line references and dimension scores. (4) Generator reads evaluation files to understand rework needs -- never receives evaluator feedback through conversation injection. (5) Evaluation files are structured (tables and lists, not prose) to make parsing unambiguous. |
| **Dependencies** | None (foundational -- other requirements depend on this). |

---

## 2. Constraints

### 2.1 Pipeline Integrity

- The existing flow brainstorming -> writing-plans -> executing-plans MUST remain functional without any of these optimizations enabled.
- All optimizations are additive layers. Disabling them returns to current behavior.
- The Superpower Loop mechanism (setup-superpower-loop.sh, stop-hook.sh, promise tags) MUST NOT be modified in incompatible ways. New steps integrate within the existing Phase 1-6 structure.

### 2.2 Plugin Development Patterns

- New agent definitions MUST include 2-4 `<example>` blocks and follow Role -> Responsibilities -> Process -> Standards -> Output Format structure.
- New reference files in `references/` MUST use imperative style consistent with existing references.
- Tool invocation rules: no "Use X tool" for file ops or Bash; explicit Skill tool references for skill loading.
- Evaluator agent MUST have restricted `tools` (Read, Grep, Glob, Bash for test commands only -- no Write/Edit to prevent evaluator from fixing code itself).

### 2.3 Token Budgets

| Component | Budget | Enforcement |
|---|---|---|
| Evaluator agent metadata (name + description in plugin.json) | ~100 tokens (Level 1) | Always loaded |
| Evaluator agent body (`agents/evaluator.md`) | ~2k-3k tokens | Loaded when spawned |
| Evaluation rubrics, contract templates, file format specs | Unlimited (Level 3) | In `references/`, read on-demand by evaluator via Read tool |
| Sprint contract per batch | ~500-1000 tokens | Written to plan directory |
| Evaluation report per round | ~300-800 tokens per task | Written to plan directory |

Token impact of the full optimization suite: +2k-5k tokens per batch (evaluator prompt + contract + report). For a 20-task plan with 5 batches, total overhead is approximately 10k-25k additional tokens.

### 2.4 Configuration Precedence

All evaluator configuration follows this precedence (highest to lowest):

1. **Skill argument** (per-invocation): `/executing-plans --evaluator=enabled --intensity=light`
2. **Plan metadata** (per-plan): YAML block in `_index.md` under `evaluator:` key
3. **Plugin defaults**: `evaluator: auto`, `intensity: standard`, `thresholds: { pass: 4, rework: 2, fail: 1 }`, `commit-artifacts: false`

```yaml
# Example _index.md evaluator configuration block
evaluator:
  mode: enabled        # enabled | disabled | auto (default: auto)
  intensity: standard  # thorough | standard | light (default: standard)
  thresholds:
    pass: 4            # minimum score on all applicable dimensions
    rework: 2          # scores at or above this trigger rework
    fail: 1            # any dimension at this score = task fails
  commit-artifacts: false  # whether to git-add evaluation files
```

**Auto mode**: Evaluator activates when plan has 5+ tasks or any task has 3+ BDD scenarios. Otherwise falls back to current self-verification (Phase 4 evidence blocks).

### 2.5 Execution Mode Compatibility

- MUST work with sub-agent execution (2 tasks, no inter-agent communication).
- MUST work with Agent Teams execution (3+ tasks, shared task list, teammate messaging).
- MUST work with Linear execution (single task, direct session).
- In all modes, the Evaluator is a separate sub-agent spawned AFTER the batch completes -- not a teammate. This preserves independence regardless of execution mode.

---

## 3. Non-Functional Requirements

### 3.1 Token Cost Impact

| Optimization | Estimated Token Cost | Notes |
|---|---|---|
| REQ-001: Independent Evaluator | +3k-8k per evaluation round | Evaluator prompt (~2k) + code reading (~1k-5k) + report generation (~500) |
| REQ-002: Sprint Contract | +1k-2k per batch | Contract generation by evaluator |
| REQ-003: Graded Criteria | +500-1k per task | Rubric application adds ~500 tokens to evaluator output |
| REQ-004: Handoff Documentation | +1k per summary | Summary generation; no context cost since it doesn't affect conversation |
| REQ-005: Intensity Configuration | Net negative (saves tokens) | `light` mode reduces evaluator cost by ~60-80% vs `standard` |
| REQ-006: File-Based Communication | +200-500 per exchange | File read/write overhead vs. direct message passing |

**Worst case (all enabled, `thorough` intensity, 20 tasks)**: ~50k-80k additional tokens total.
**Standard case (`standard` intensity, 20 tasks, 5 batches)**: ~15k-25k additional tokens.
**Best case (`light` intensity, 20 tasks)**: ~5k-10k additional tokens (single end-of-run evaluation).

### 3.2 Latency Impact

| Optimization | Latency Impact | Mitigation |
|---|---|---|
| REQ-001: Independent Evaluator | +30-90s per evaluation round (model inference) | Evaluator runs after batch completes; can overlap with next batch's contract generation in pipeline |
| REQ-002: Sprint Contract | +15-30s per batch (one evaluator pass) | Contract is lightweight -- evaluator reads task files and outputs structured checklist |
| REQ-003: Graded Criteria | Negligible (scoring is part of evaluator pass) | Bundled into evaluator round |
| REQ-004: Handoff Documentation | +10-20s per summary | Runs between batches during natural pause |
| REQ-005: Intensity Configuration | Net negative (reduces evaluation frequency) | `light` mode eliminates per-batch evaluator latency |
| REQ-006: File-Based Communication | +2-5s per exchange (file I/O) | Negligible compared to model inference |

**Total additional latency per batch (`standard`)**: 45-120s.
**Total additional latency per plan (`light`)**: 45-120s (single evaluation pass).

### 3.3 Backwards Compatibility Guarantees

1. **No new required fields in plan files.** Existing `_index.md` and task files work without modification. The `evaluator:` metadata block in `_index.md` is optional.
2. **No changes to TaskCreate/TaskUpdate/TaskList API usage.** Task tracking remains identical.
3. **No changes to Superpower Loop protocol.** Promise tags, iteration counting, and stop-hook behavior are preserved.
4. **No changes to existing hook contracts.** `UserPromptSubmit`, `PostToolUse`, and `Stop` hooks retain current signatures.
5. **Existing verification (Phase 4 evidence blocks) remains the baseline.** Evaluator is an additional layer on top.
6. **plugin.json schema unchanged.** New components are registered using existing agent discovery patterns.
7. **`brainstorming` and `writing-plans` skills are not modified.** Only `executing-plans` gains new optional steps within Phase 3.

---

## 4. Risk Assessment

### REQ-001: Independent Evaluator Agent

| Risk | Severity | Mitigation |
|---|---|---|
| Evaluator is too lenient (same failure mode as self-evaluation) | High | Evaluator prompt is tuned for skepticism with explicit "assume issues exist until proven otherwise" framing. Few-shot calibration examples (PASS/REWORK/FAIL) anchor scoring expectations. Evaluator has no Write/Edit tools -- it cannot fix issues, only report them. |
| Evaluator blocks progress on subjective quality issues | Medium | Graded criteria (REQ-003) replace binary judgment. Configurable thresholds let users adjust strictness. Escalation path to user after 2 evaluation rounds. |
| Evaluator adds complexity that discourages use | Medium | Auto mode (Section 2.4) only activates for plans with 5+ tasks. `disabled` override always available. The evaluator is a single additional sub-agent call -- minimal integration surface. |
| Token cost makes evaluator impractical for small tasks | Medium | Auto mode skips evaluator for simple plans. `light` intensity reduces cost by 60-80%. |

### REQ-002: Sprint Contract Negotiation

| Risk | Severity | Mitigation |
|---|---|---|
| Contract generation adds overhead that delays batch execution start | Medium | Contract is a lightweight evaluator pass (read task files, output checklist). Expected: 15-30s. For `light` intensity, contract is a single plan-level summary. |
| Ambiguous criteria cause extended negotiation | Medium | Maximum 2 negotiation rounds. After round 2, escalate to user. Unresolved items flagged as "user-accepted risk." |
| Contract diverges from actual task file content | Low | Contract references task file IDs and verification commands directly. Any post-contract task modification invalidates the contract and triggers re-generation. |

### REQ-003: Graded Evaluation Criteria

| Risk | Severity | Mitigation |
|---|---|---|
| Scoring is subjective and inconsistent across evaluation rounds | High | Each score level has concrete examples in `evaluation-rubrics.md`. Evaluator prompt includes calibration examples. Type-aware weighting reduces irrelevant dimensions. |
| Generators over-optimize for scores rather than actual quality | Low | Generators never see rubrics or scores -- only rework instructions with specific file:line references. |
| Pivot flag triggers unnecessary rearchitecting | Medium | Pivot is a recommendation, not an automatic action. Orchestrator decides whether to pivot based on context. Flag only triggers after 2+ low-score rounds on 2+ dimensions -- conservative threshold. |

### REQ-004: Handoff Documentation

| Risk | Severity | Mitigation |
|---|---|---|
| Handoff summaries become stale or inaccurate | Medium | Summaries are generated from TaskList (authoritative) and evaluation files (structured). Automated generation reduces manual error. |
| Users mistake handoff docs for context reset mechanism | Low | Documentation explicitly states handoff docs are progress snapshots, not context management. REQ-004 description clarifies scope limitation. |

### REQ-005: Evaluation Intensity Configuration

| Risk | Severity | Mitigation |
|---|---|---|
| Users choose wrong intensity for their situation | Medium | Default `standard` is a safe middle ground. Documentation provides guidance: use `light` for experienced developers or capable models, `thorough` for critical or complex work. |
| `light` mode misses batch-level integration issues | Medium | Even in `light` mode, the evaluator reviews all tasks. The reduction is frequency (end-of-run), not scope. If end-of-run evaluation flags issues, the orchestrator can re-run specific batch evaluations. |

### REQ-006: File-Based Communication

| Risk | Severity | Mitigation |
|---|---|---|
| File I/O race conditions between evaluator and generator | Medium | Evaluator writes files only after completing. Generator reads files only after evaluator signals completion (file existence check). No concurrent writes to the same file. |
| Plan directory becomes cluttered with evaluation artifacts | Low | Clear naming convention. Files are NOT committed by default (ephemeral). Optional `commit-artifacts: true` for audit requirements. |
| Generator ignores evaluation file content | Medium | Phase 3 execution loop includes a mandatory "read evaluation file" step before rework. Evaluation report format is structured (tables, not prose) for unambiguous parsing. |
| File format changes break evaluator-generator protocol | Low | Formats are defined in `references/evaluation-file-formats.md` -- single source of truth. Both evaluator agent prompt and executing-plans skill reference this file. |

---

## 5. Dependency Graph

```
REQ-006 (File Formats + Communication)    [P0, no deps -- foundational]
  |
  +---> REQ-001 (Independent Evaluator)    [P0, depends on REQ-006]
          |
          +---> REQ-002 (Sprint Contract)  [P0, depends on REQ-001]
          |
          +---> REQ-003 (Graded Criteria)  [P1, depends on REQ-001, REQ-006]
          |
          +---> REQ-005 (Intensity Config) [P2, depends on REQ-001]

REQ-004 (Handoff Documentation)            [P2, no hard deps -- standalone]
```

**Implementation order:**
1. REQ-006 -- File format definitions and naming conventions
2. REQ-001 -- Evaluator agent definition with calibration examples
3. REQ-002 -- Sprint contract generation integrated into Phase 3 batch loop
4. REQ-003 -- Graded rubrics with type-aware weighting and pivot flag
5. REQ-004 -- Handoff documentation for long plans (parallel with 2-4)
6. REQ-005 -- Evaluation intensity presets (last, requires evaluator to be stable)

---

## 6. Integration Points with Existing Components

| Existing Component | Integration | Notes |
|---|---|---|
| `executing-plans/SKILL.md` Phase 3 | Add step 0 (Sprint Contract) and step 4 (Evaluator Assessment) to batch loop | Conditional on evaluator being enabled |
| `executing-plans/SKILL.md` Phase 4 | Evaluator report supplements (not replaces) evidence blocks | Evidence blocks remain as baseline |
| `batch-execution-playbook.md` | New "Evaluation Mode" section with evaluator invocation pattern | Documents how to spawn evaluator sub-agent after batch |
| `agent-team-driven-development` | Evaluator runs as sub-agent (not teammate) after team completes batch | Preserves independence; no change to team workflow |
| `reviewer-role.md` | Reviewer remains as in-flight teammate role; Evaluator is post-completion gate | Complementary, not competing |
| `stop-hook.sh` | No changes needed -- evaluator completion is tracked via file artifacts and TaskUpdate | Stop hook already bypasses vet for executing-plans |
| `plugin.json` | Add evaluator agent path to agent discovery | No schema changes |
| `blocker-and-escalation.md` | Add evaluator-flagged issues as a new escalation trigger type | "Evaluator rework after 2 rounds" joins existing escalation triggers |

---

## 7. Files to Create or Modify

### New Files

| File | Type | Purpose |
|---|---|---|
| `superpowers/agents/evaluator.md` | Agent | Independent Evaluator agent definition with restricted tools, skeptical framing, and 2-3 few-shot calibration examples (PASS/REWORK/FAIL) |
| `superpowers/skills/executing-plans/references/evaluation-file-formats.md` | Reference (L3) | Single source of truth for sprint contract, evaluation report, and handoff summary file formats |
| `superpowers/skills/executing-plans/references/evaluation-rubrics.md` | Reference (L3) | Graded scoring rubrics per dimension with concrete score-level examples, type-aware weighting table, and additional calibration examples |
| `superpowers/skills/executing-plans/references/sprint-contract-template.md` | Reference (L3) | Template for sprint contract files with Red-Green pair handling |
| `superpowers/skills/executing-plans/references/handoff-template.md` | Reference (L3) | Template for handoff summary files |

### Modified Files

| File | Change |
|---|---|
| `superpowers/skills/executing-plans/SKILL.md` | Add evaluator configuration parsing in Initialization. Add step 0 (Sprint Contract) and step 4 (Evaluator Assessment) to Phase 3 batch loop. Add pivot handling. All additions are conditional on evaluator being enabled. |
| `superpowers/skills/executing-plans/references/batch-execution-playbook.md` | Add "Evaluation Mode" section documenting evaluator sub-agent invocation pattern after batch completion |
| `superpowers/.claude-plugin/plugin.json` | Register evaluator agent; bump version |
| `superpowers/skills/executing-plans/references/blocker-and-escalation.md` | Add evaluator-flagged rework (after 2 rounds) as escalation trigger type |

