# Harness Design Optimizations -- Requirements Document

**Date**: 2026-03-31
**Plugin**: superpowers v2.1.0
**Approach**: Layered Integration (no breaking changes)
**Source**: Anthropic blog "Harness Design for Long-Running Apps"

---

## 1. Requirements Matrix

### REQ-001: Independent Evaluator Agent

| Field | Value |
|---|---|
| **Priority** | P0 (must-have) |
| **Description** | Introduce a standalone Evaluator agent, architecturally separated from the generator (Implementer). The Evaluator reviews completed work with a skeptical lens rather than relying on the generator to self-assess. |
| **Rationale** | Blog: "Naive self-evaluation fails. Agents grade themselves too generously." and "Tuning a standalone evaluator to be skeptical is far more tractable than making a generator critical." The current system has no independent evaluator -- verification in Phase 4 is performed by the same orchestrator that directed execution, and the existing Reviewer role (`reviewer-role.md`) is optional and lens-scoped (Security, Performance, etc.) rather than a systematic pass/fail gate. |
| **Success Criteria** | (1) Evaluator is a distinct agent definition in `superpowers/agents/evaluator.md` with its own restricted tool set. (2) Evaluator never shares conversation context with the generator session. (3) When enabled, Evaluator produces a structured evaluation report before any task is marked `completed`. (4) False-pass rate (tasks marked complete that fail on re-verification) decreases compared to baseline self-verification. |
| **Dependencies** | REQ-006 (file-based communication for report exchange). |

---

### REQ-002: Sprint Contract Negotiation

| Field | Value |
|---|---|
| **Priority** | P0 (must-have) |
| **Description** | Before batch execution begins, the Evaluator reviews acceptance criteria from task files and negotiates a "sprint contract" -- a concrete, testable checklist that both generator and evaluator agree constitutes done. This replaces the implicit done criteria currently embedded in task YAML. |
| **Rationale** | Blog: "Sprint contracts bridge the gap between user stories and testable implementation." Currently, acceptance criteria live in task files as BDD scenarios and verification commands, but there is no explicit negotiation step where an independent party confirms they are sufficient and unambiguous before work starts. |
| **Success Criteria** | (1) A `sprint-contract.md` file is produced per batch before execution begins. (2) The contract lists each task with its testable acceptance criteria and the Evaluator's sign-off. (3) Ambiguous criteria are flagged and resolved (via user question or refinement) before execution. (4) Phase 3 execution does not start until the contract file exists. |
| **Dependencies** | REQ-001 (Evaluator agent must exist to perform the review). |

---

### REQ-003: Graded Evaluation Criteria

| Field | Value |
|---|---|
| **Priority** | P1 (should-have) |
| **Description** | Replace the current binary pass/fail verification gate with a 1-5 graded scoring system. Define per-dimension rubrics (correctness, completeness, code quality, test coverage, spec compliance) and configurable thresholds for pass/rework/fail. |
| **Rationale** | Blog: "Grading criteria made subjective quality measurable." The current system uses a hard binary gate (exit code 0 = pass, non-zero = fail) with up to 2 retries. This misses nuanced quality issues -- a task can pass verification commands yet have poor structure, missing edge cases, or subtle deviations from the spec. |
| **Success Criteria** | (1) Evaluation reports include per-dimension scores (1-5) for each task. (2) Configurable thresholds: default pass >= 4 on all dimensions, rework if any dimension is 2-3, fail if any dimension is 1. (3) Thresholds are adjustable in skill configuration (not hardcoded). (4) Existing binary verification gate remains as a prerequisite -- graded evaluation is an additional layer, not a replacement for exit-code checks. |
| **Dependencies** | REQ-001 (Evaluator produces the grades). REQ-006 (grades written to evaluation files). |

---

### REQ-004: Context Reset Strategy

| Field | Value |
|---|---|
| **Priority** | P1 (should-have) |
| **Description** | For plans with 16+ tasks, implement clean-slate handoff between batch groups. After every N batches (configurable, default 3), summarize cumulative state into a handoff document and reset the orchestrator context to prevent degradation from long conversation histories. |
| **Rationale** | Blog finding implicit in harness design for long-running apps. The current Superpower Loop (`setup-superpower-loop.sh`) supports up to 100 iterations, and stop-hook.sh manages state via JSON files, but there is no mechanism to compress or reset accumulated context. For 16+ task plans, the orchestrator conversation can exceed useful context window, leading to instruction drift and reduced quality. |
| **Success Criteria** | (1) A `handoff-summary-N.md` file is produced at each reset boundary containing: completed tasks, remaining tasks, key decisions, file ownership map, and accumulated evaluation scores. (2) The new context window starts with only the handoff summary and the original plan -- no raw conversation history. (3) No task state is lost across the reset (TaskList remains authoritative). (4) Reset boundary is configurable (default: every 3 batches or every 15 tasks, whichever comes first). |
| **Dependencies** | None (standalone, but benefits from REQ-006 file patterns). |

---

### REQ-005: Harness Model Calibration

| Field | Value |
|---|---|
| **Priority** | P2 (nice-to-have) |
| **Description** | Adjust evaluation intensity and sprint structure based on the model capability executing the work. On high-capability models (Opus 4.6), reduce overhead by eliminating per-batch sprints and using a single end-of-run evaluation pass. On lower-capability models, retain full per-batch evaluation. |
| **Rationale** | Blog: "On Opus 4.6, sprints were removed entirely. Evaluator moved to single end-of-run pass." and "The evaluator is cost-effective when the task sits at the boundary of the model's solo capability." Over-evaluating capable models wastes tokens; under-evaluating weaker models risks quality. |
| **Success Criteria** | (1) A model-tier mapping exists (e.g., opus = high, sonnet = medium, haiku = low). (2) For "high" tier: evaluator runs once at end-of-plan, sprint contracts are simplified summaries. (3) For "medium" tier: evaluator runs per-batch (current default). (4) For "low" tier: evaluator runs per-task. (5) Tier can be overridden manually. (6) The system auto-detects model from agent configuration where possible. |
| **Dependencies** | REQ-001 (Evaluator must exist). REQ-002 (sprint contracts vary by tier). |

---

### REQ-006: File-Based Evaluator-Generator Communication

| Field | Value |
|---|---|
| **Priority** | P0 (must-have) |
| **Description** | All communication between the Evaluator and Generator (Implementer/orchestrator) occurs through structured files -- never through direct message passing or shared conversation context. Evaluation results, rework requests, and sprint contracts are written to and read from the plan directory. |
| **Rationale** | Blog: "Agents communicated by writing/reading files, not by direct message passing." The current Agent Teams model uses direct teammate messaging and shared task lists. While this works for coordination, it couples evaluator and generator contexts, undermining independent evaluation. File-based communication enforces separation and creates an auditable trail. |
| **Success Criteria** | (1) Evaluation files follow the naming convention `evaluation-round-{N}-{batch-id}.md` in the plan directory. (2) Sprint contracts are written as `sprint-contract-batch-{N}.md`. (3) Rework requests include specific line references and dimension scores. (4) The generator reads evaluation files to understand rework needs -- it never receives evaluator feedback through conversation injection. (5) All evaluation artifacts are committed alongside implementation code. |
| **Dependencies** | None (foundational -- other requirements depend on this). |

---

## 2. Constraints

### 2.1 Pipeline Integrity

- The existing flow brainstorming -> writing-plans -> executing-plans MUST remain functional without any of these optimizations enabled.
- All six optimizations are additive layers. Disabling them returns to current behavior.
- The Superpower Loop mechanism (setup-superpower-loop.sh, stop-hook.sh, promise tags) MUST NOT be modified in incompatible ways. New phases integrate within the existing Phase 1-6 structure.

### 2.2 Plugin Development Patterns

- New skill files MUST follow CLAUDE.md conventions: imperative body style, YAML frontmatter with description in third person, under 2000 words with overflow in `references/`.
- New agent definitions MUST include 2-4 `<example>` blocks and follow Role -> Responsibilities -> Process -> Standards -> Output Format structure.
- Tool invocation rules: no "Use X tool" for file ops or Bash; explicit Skill tool references for skill loading.
- Evaluator agent MUST have restricted `tools` (Read, Grep, Glob, Bash for test commands only -- no Write/Edit to prevent evaluator from fixing code itself).

### 2.3 Token Budgets

| Component | Budget | Enforcement |
|---|---|---|
| Evaluator agent metadata (name + description) | ~100 tokens (Level 1) | Always loaded |
| Evaluator SKILL.md body | Under 5k tokens (Level 2) | Loaded when triggered |
| Evaluation rubrics, contract templates, calibration tables | Unlimited (Level 3) | In `references/`, loaded on demand |
| Sprint contract per batch | ~500-1000 tokens | Written to plan directory |
| Evaluation report per round | ~300-800 tokens per task | Written to plan directory |

Token impact of the full optimization suite: +2k-5k tokens per batch (evaluator prompt + contract + report). For a 20-task plan with 5 batches, total overhead is approximately 10k-25k additional tokens.

### 2.4 Evaluator Configurability

- The Evaluator MUST be optional. A configuration flag (e.g., `evaluator: enabled|disabled|auto`) controls activation.
- `auto` mode: Evaluator activates only when plan has 5+ tasks or task complexity exceeds a threshold (determined by task type and BDD scenario count).
- `disabled` mode: Falls back to current self-verification (Phase 4 evidence blocks).
- `enabled` mode: Evaluator always runs.
- Default: `auto`.

### 2.5 Execution Mode Compatibility

- MUST work with sub-agent execution (2 tasks, no inter-agent communication).
- MUST work with Agent Teams execution (3+ tasks, shared task list, teammate messaging).
- MUST work with Linear execution (single task, direct session).
- In Agent Teams mode, the Evaluator is NOT a teammate -- it runs as a separate sub-agent after the batch completes, preserving independence.

---

## 3. Non-Functional Requirements

### 3.1 Token Cost Impact

| Optimization | Estimated Token Cost | Notes |
|---|---|---|
| REQ-001: Independent Evaluator | +3k-8k per evaluation round | Evaluator prompt (~2k) + code reading (~1k-5k) + report generation (~500) |
| REQ-002: Sprint Contract | +1k-2k per batch | Contract generation + evaluator review |
| REQ-003: Graded Criteria | +500-1k per task | Rubric application adds ~500 tokens to evaluator output |
| REQ-004: Context Reset | Net neutral to positive | Resets save tokens on long plans by compressing context; handoff summary ~1k |
| REQ-005: Model Calibration | Net negative (saves tokens) | Reduces evaluation frequency on capable models; Opus saves ~60% evaluator cost |
| REQ-006: File-Based Communication | +200-500 per exchange | File read/write overhead vs. direct message passing |

**Worst case (all enabled, medium model, 20 tasks)**: ~30k-50k additional tokens total.
**Best case (auto mode, Opus, 20 tasks)**: ~5k-10k additional tokens (single end-of-run evaluation).

### 3.2 Latency Impact

| Optimization | Latency Impact | Mitigation |
|---|---|---|
| REQ-001: Independent Evaluator | +30-90s per evaluation round (model inference) | Run evaluator in parallel with next batch setup when possible |
| REQ-002: Sprint Contract | +15-30s per batch (one evaluator pass) | Contract generation can overlap with task dependency analysis |
| REQ-003: Graded Criteria | Negligible (scoring is part of evaluator pass) | Bundled into evaluator round |
| REQ-004: Context Reset | +10-20s per reset (handoff document generation) | Reset happens between batches during natural pause |
| REQ-005: Model Calibration | Net negative (reduces evaluation frequency) | Directly reduces latency on capable models |
| REQ-006: File-Based Communication | +2-5s per exchange (file I/O) | Negligible compared to model inference |

**Total additional latency per batch**: 45-120s (medium model), 10-25s (Opus with end-of-run only).

### 3.3 Backwards Compatibility Guarantees

1. **No new required fields in plan files.** Existing `_index.md` and task files work without modification.
2. **No changes to TaskCreate/TaskUpdate/TaskList API usage.** Task tracking remains identical.
3. **No changes to Superpower Loop protocol.** Promise tags, iteration counting, and stop-hook behavior are preserved.
4. **No changes to existing hook contracts.** `UserPromptSubmit`, `PostToolUse`, and `Stop` hooks retain current signatures.
5. **Existing verification (Phase 4 evidence blocks) remains the baseline.** Evaluator is an additional layer on top.
6. **plugin.json schema unchanged.** New components are registered using existing `commands`, `skills`, and agent discovery patterns.
7. **`brainstorming` and `writing-plans` skills are not modified.** Only `executing-plans` gains new optional phases.

---

## 4. Risk Assessment

### REQ-001: Independent Evaluator Agent

| Risk | Severity | Mitigation |
|---|---|---|
| Evaluator is too lenient (same failure mode as self-evaluation) | High | Evaluator prompt is tuned for skepticism with explicit "assume guilty until proven innocent" framing. Evaluator has no Write/Edit tools -- it cannot fix issues, only report them. Separation of concerns enforces the adversarial dynamic. |
| Evaluator blocks progress on subjective quality issues | Medium | Graded criteria (REQ-003) replace binary judgment. Configurable thresholds let users adjust strictness. Escalation path to user after 2 evaluation rounds. |
| Token cost makes evaluator impractical for small tasks | Medium | Auto mode (REQ-005 calibration) skips evaluator for simple plans. Explicit `evaluator: disabled` override. |

### REQ-002: Sprint Contract Negotiation

| Risk | Severity | Mitigation |
|---|---|---|
| Contract negotiation adds overhead that delays execution start | Medium | Contract generation runs in parallel with Phase 2 task dependency analysis. For simple tasks, contract is a lightweight checklist (not a full document). Model calibration (REQ-005) simplifies contracts on capable models. |
| Ambiguous criteria cause infinite negotiation loops | Medium | Maximum 2 negotiation rounds. After round 2, escalate ambiguities to user via AskUserQuestion. Unresolved items are flagged in contract as "user-accepted risk." |
| Contract diverges from actual task file content | Low | Contract references task file IDs and verification commands directly. Any post-contract task modification invalidates the contract and triggers re-negotiation. |

### REQ-003: Graded Evaluation Criteria

| Risk | Severity | Mitigation |
|---|---|---|
| Scoring is subjective and inconsistent across evaluation rounds | High | Rubrics are explicit and dimension-specific (stored in `references/evaluation-rubrics.md`). Each score level has concrete examples. Evaluator prompt includes calibration examples. |
| Teams over-optimize for scores rather than actual quality | Low | Scores are evaluator-only output -- generators never see rubrics, only rework instructions. This prevents gaming. |
| Threshold configuration complexity confuses users | Low | Sensible defaults (pass >= 4 all dimensions). Users only adjust thresholds if they want to. Configuration is documented with examples. |

### REQ-004: Context Reset Strategy

| Risk | Severity | Mitigation |
|---|---|---|
| Critical context lost during reset | High | Handoff summary is generated by a dedicated summarization pass, not truncation. TaskList state (authoritative) is never part of conversation context -- it persists independently. File-based evaluation artifacts (REQ-006) survive resets. Handoff summary template is validated to include: completed tasks, remaining tasks, key decisions, file ownership, evaluation scores. |
| Reset boundary misconfigured (too frequent or too rare) | Medium | Default is conservative (every 3 batches). Monitoring: if post-reset batch has higher failure rate than pre-reset, boundary is adjusted. User can override. |
| Superpower Loop iteration count interacts poorly with resets | Medium | Reset does not restart the Superpower Loop -- it only compresses conversation context. Loop iteration counter and state file persist across resets. |

### REQ-005: Harness Model Calibration

| Risk | Severity | Mitigation |
|---|---|---|
| Model detection is unreliable or unavailable | Medium | Fallback to "medium" tier if model cannot be detected. Manual override always available. The `model` field in agent frontmatter (inherit/sonnet/opus/haiku) provides a detection signal. |
| Opus-tier single-pass evaluation misses batch-level issues | Medium | Even in single-pass mode, the evaluator still reviews all tasks. The reduction is in frequency (end-of-run vs. per-batch), not in scope. If the single-pass evaluation fails, fallback to per-batch re-evaluation for remaining rework. |
| Calibration tiers become stale as models improve | Low | Tier mapping is in a `references/` file, easily updated. Not hardcoded into skill logic. |

### REQ-006: File-Based Evaluator-Generator Communication

| Risk | Severity | Mitigation |
|---|---|---|
| File I/O race conditions between evaluator and generator | Medium | Evaluation files are written by the evaluator only after it completes. Generator reads evaluation files only after evaluator signals completion (via TaskUpdate or file existence check). No concurrent writes to the same file. |
| Plan directory becomes cluttered with evaluation artifacts | Low | Clear naming convention (`evaluation-round-N-batch-M.md`, `sprint-contract-batch-N.md`). Evaluation files are committed as documentation. Optional cleanup step in Phase 6. |
| Generator ignores evaluation file content | Medium | Phase 3 execution loop includes a mandatory "read evaluation file" step before retry. The step is part of the skill instructions, not optional. Evaluator report format is structured (not prose) to make parsing unambiguous. |

---

## 5. Dependency Graph

```
REQ-006 (File-Based Communication)     [P0, no deps -- foundational]
  |
  +---> REQ-001 (Independent Evaluator) [P0, depends on REQ-006]
          |
          +---> REQ-002 (Sprint Contract)     [P0, depends on REQ-001]
          |
          +---> REQ-003 (Graded Criteria)     [P1, depends on REQ-001, REQ-006]
          |
          +---> REQ-005 (Model Calibration)   [P2, depends on REQ-001, REQ-002]

REQ-004 (Context Reset)                [P1, no hard deps -- standalone]
```

**Recommended implementation order:**
1. REQ-006 -- File-based communication patterns and naming conventions
2. REQ-001 -- Evaluator agent definition and integration into Phase 3-4
3. REQ-002 -- Sprint contract generation before batch execution
4. REQ-003 -- Graded rubrics added to evaluator output
5. REQ-004 -- Context reset for long plans (can be developed in parallel with 2-4)
6. REQ-005 -- Model calibration (last, requires all others to be stable)

---

## 6. Integration Points with Existing Components

| Existing Component | Integration |
|---|---|
| `executing-plans/SKILL.md` Phase 3 | Add optional evaluator invocation after batch verification gate |
| `executing-plans/SKILL.md` Phase 4 | Evaluator report replaces or supplements evidence blocks |
| `batch-execution-playbook.md` | New "Evaluation Mode" section added alongside existing execution modes |
| `agent-team-driven-development` | Evaluator runs as sub-agent (not teammate) to maintain independence |
| `reviewer-role.md` | Reviewer remains as teammate role for in-flight review; Evaluator is post-completion gate |
| `need-vet/SKILL.md` | Evaluator-verified tasks satisfy vet requirements automatically |
| `stop-hook.sh` | No changes needed -- evaluator completion is tracked via TaskUpdate and file artifacts |
| `plugin.json` | Add evaluator agent path; optionally add evaluation skill to `"skills"` array |
| `blocker-and-escalation.md` | Add evaluator-flagged issues as a new escalation trigger |

---

## 7. Files to Create or Modify

### New Files

| File | Type | Purpose |
|---|---|---|
| `superpowers/agents/evaluator.md` | Agent | Independent Evaluator agent definition |
| `superpowers/skills/executing-plans/references/evaluation-rubrics.md` | Reference (L3) | Graded scoring rubrics per dimension |
| `superpowers/skills/executing-plans/references/sprint-contract-template.md` | Reference (L3) | Template for sprint contract files |
| `superpowers/skills/executing-plans/references/context-reset-protocol.md` | Reference (L3) | Handoff summary template and reset procedure |
| `superpowers/skills/executing-plans/references/model-calibration.md` | Reference (L3) | Model tier mapping and calibration rules |

### Modified Files

| File | Change |
|---|---|
| `superpowers/skills/executing-plans/SKILL.md` | Add optional Evaluator invocation in Phase 3-4; add Phase 2.5 (Sprint Contract); add context reset hooks between batches |
| `superpowers/skills/executing-plans/references/batch-execution-playbook.md` | Add Evaluation Mode section; add evaluator prompt template |
| `superpowers/.claude-plugin/plugin.json` | Register evaluator agent; bump version |
| `superpowers/skills/executing-plans/references/blocker-and-escalation.md` | Add evaluator-flagged blockers as escalation type |
