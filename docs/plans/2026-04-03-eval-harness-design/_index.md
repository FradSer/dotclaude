# Eval Harness Design: Executable Verification

## Context

**Original request**: Design a multi-round eval mechanism and optimization loop for the superpowers plugin, following Anthropic's harness design blog post.

**Revised direction**: The original rubric-calibration approach has a fundamental flaw — it calibrates a proxy (rubric scores) rather than replacing the proxy with direct verification. The Anthropic article's core principle is to externalize subjective judgment as executable tests that produce objective pass/fail results, not to calibrate subjective scores against human baselines.

**Core problem with rubric scoring**:
- LLMs are sycophantic — the same artifact scored twice may get different scores as model behavior shifts
- "Architecture Soundness: 3/5" gives the generator nothing concrete to fix
- Calibrating rubric scores requires golden artifacts, human baselines, and a permanent calibration pipeline
- The calibration system itself suffers from the same bias problem it's trying to solve

**Core principle**: Externalize subjective judgment as executable tests. A test either passes or fails — it does not drift.

## Discovery Results

**What exists and is preserved:**

- `superpowers-evaluator` already runs verification commands in code mode (`Bash(test:*)`, `Bash(npm:*)`, `Bash(pnpm:*)`) — Step 3 of code mode
- Sprint contracts define per-task acceptance criteria before execution — the right source for checklist items
- Task files contain verification commands — these are the executable tests
- `executing-plans` Phase 3f already spawns the evaluator — integration point unchanged

**What is eliminated:**

- 1-5 rubric scoring in `superpowers-evaluator` (all modes)
- Calibration pipeline (eval-orchestrator, eval-bias-analyzer, eval-rubric-optimizer)
- Golden artifact management and human-scores.json
- Evaluation-history.json trend tracking
- `references/evaluation-rubrics.md` files (all three modes)

**What replaces them:**

- Binary checklists (`docs/retros/checklists/{mode}-v{N}.md`) — PASS/FAIL per item
- Manual checklist evolution via git — version files, do not mutate

## Requirements

### VER — Verification-First Evaluation

- **VER-1**: Evaluation verdict is determined solely by verification command exit codes (code mode) or binary checklist results (design/plan mode) — no numeric rubric scores
- **VER-2** (code mode): `superpowers-evaluator` runs task verification commands independently; PASS/FAIL per task is determined by exit code 0 vs. non-zero
- **VER-3** (design mode): `superpowers-evaluator` applies the binary checklist from `docs/retros/checklists/design-v{N}.md`; each item is PASS or FAIL with specific evidence
- **VER-4** (plan mode): `superpowers-evaluator` applies the binary checklist from `docs/retros/checklists/plan-v{N}.md`; each item is PASS or FAIL with specific evidence
- **VER-5**: Rework items are produced only from FAIL checklist results; each item must name the exact file, location, and violated check — "code quality could be improved" is not a valid rework item
- **VER-6**: Evaluator output format: checklist results table (item, result, evidence) + rework items list + overall verdict — no scores table
- **VER-7a**: Each computational checklist check is independently verifiable — a third party can confirm the PASS/FAIL result by reading the cited file or running the cited command without judgment calls
- **VER-7b**: Each inferential checklist check is verifiable with reference to the check method annotation — two independent evaluators applying the same check method to the same artifact reach the same PASS/FAIL result in the majority of cases; borderline results are noted but do not affect verdict
- **VER-8**: In design and plan mode, if the same checklist item FAILs with the same evidence pattern in 2 consecutive rework rounds for the same evaluation, the rework item notes the repeated failure and recommends reviewing the task specification or scope for an underlying blocker

### CHK — Checklist Design

- **CHK-1** (design checklist): Covers requirement→scenario traceability, scenario concreteness (data specificity), architecture validity (layer dependency direction), risk identification
- **CHK-2** (plan checklist): Covers scenario→task traceability, task completeness (all required sections present), dependency validity (no cycles, no missing IDs), verification command quality (concrete and executable)
- **CHK-3** (code checklist): Test suite exits 0, type checker exits 0, linter exits 0, no prohibited patterns (stubs/TODOs) in produced files
- **CHK-4**: Each checklist item is: binary (not "partially met"), concrete (references specific file paths or grep patterns), actionable (a FAIL result tells the generator exactly what to change)
- **CHK-5**: Checklists stored at `docs/retros/checklists/{mode}-v{N}.md`; sprint contracts reference the checklist version in use
- **CHK-6**: Checklist version increments when any item is added, modified, or removed; prior version files are preserved
- **CHK-7**: Each checklist item is annotated as `computational` (deterministic result from grep, exit code, graph walk) or `inferential` (requires evaluator judgment for semantic matching, architectural context, or domain understanding)
- **CHK-8**: Inferential checklist items must include an explicit check method (grep pattern, structural query) that anchors the evaluator's judgment and minimizes interpretive freedom — the annotation reduces but does not eliminate observer variability

### CTX — Context Management

- **CTX-1**: At each batch boundary in executing-plans, emit a structured batch handoff summary to the conversation context
- **CTX-2**: Batch handoff includes: completed tasks, cumulative progress, active failure patterns, modified files, next batch scope
- **CTX-3**: Batch handoff serves as compressed checkpoint — reduces context pressure from Superpower Loop's compaction model
- **CTX-4**: Per Anthropic's finding: "context resets outperform context compaction" — batch handoffs are a pragmatic middle ground that doesn't require breaking the Superpower Loop architecture

### EVO — Checklist Evolution Signals

- **EVO-1**: When a checklist item FAILs in 3+ batches within a single plan OR requires 3+ rework rounds before resolving, the plan completion summary flags it as a "checklist evolution candidate" with root cause hypothesis
- **EVO-2**: When all checklist items PASS for a batch but the batch required 2+ rework rounds, the plan completion summary notes a "potential checklist gap" — the evaluator may lack items that would have caught the initial failure earlier (variety amplification signal per Ashby's Law of Requisite Variety)
- **EVO-3**: Evolution candidate signals are informational only — they provide explicit entry points for manual checklist review but do not auto-modify checklist files
- **EVO-4**: Evolution candidates bridge the gap between intra-plan learning (immediate tactical feedback, Subsystem B) and checklist evolution (strategic manual review) — this addresses the ultra-stability transition (Ashby) between control levels
- **EVO-5**: When code evaluation identifies persistent FAILs (same checklist item failing across 2+ batches), the plan completion retrospective checks whether the related design or plan evaluation covered the upstream root cause — uncovered upstream gaps are flagged as cross-mode gaps alongside evolution candidates

### CST — Cost Tracking

- **CST-1**: Each evaluation report includes a "Run Metrics" section: evaluator input/output tokens, evaluation duration, checklist version
- **CST-2**: Token counts are best-effort: extracted from API response `usage` field if available (may not be accessible in all Claude Code spawning contexts)
- **CST-3**: Metrics are informational only — they do not affect verdicts
- **CST-4**: Per Anthropic's practice of tracking cost ($200/6hr run) and comparing solo vs harness ROI

### PLG — Plugin Integration

- **PLG-1**: `superpowers-evaluator` updated in-place to use binary checklists instead of rubric scoring — agent structure and tool permissions unchanged
- **PLG-2**: Evaluator output responsibility protocol: evaluator outputs report content as text; parent agent writes files. Evaluator remains read-only (no Write/Edit tools).
- **PLG-3**: Checklist file path is injected into evaluator spawn context by executing-plans (not hardcoded in agent definition)
- **PLG-4**: Rubric reference cleanup covers ALL three skills (executing-plans, writing-plans, brainstorming)

### Constraints and Non-Goals

**Constraints (MUST)**:
- `superpowers-evaluator` is updated, not replaced — separate evaluator agent architecture from the Anthropic article remains
- No numeric rubric scores (1-5) in any evaluation output
- Checklist evolution is manual via git; version files, do not mutate
- Code mode ground truth is command exit codes — never subjective assessment
- Evaluator runs commands independently; never trusts generator-reported results

**Non-Goals (explicitly out of scope)**:
- Calibration against human baselines
- Golden artifact management
- CI/CD integration
- Automated checklist generation or evolution (items are manually authored, evolved via git)
- Cross-plugin checklist sharing
- Interactive UI testing via Playwright MCP (future enhancement when web app development is primary use case)
- Automated harness component stress-testing (manual simplification per Anthropic's methodical removal approach)

## Architecture

### Overview

```
Subsystem A: Verification-Based Evaluation  (per batch, Phase 3f)

  executing-plans Phase 3f
    → superpowers-evaluator (updated)
        design mode: apply binary design checklist → PASS/FAIL per item
        plan mode:   apply binary plan checklist   → PASS/FAIL per item
        code mode:   run verification commands     → exit codes → PASS/FAIL per task
    ← returns: checklist results table + rework items (no scores)

Subsystem B: Intra-Plan Learning  (per batch, Phase 4 enhancement)

  executing-plans Phase 4 (after evaluator, before user confirmation)
    reads: all evaluation reports in current *-evals/ so far
    identifies: checklist items failing across 2+ batches in this plan
    injects: pattern context into next batch sprint contract preamble
    surfaces: pattern summary in evidence block to user

  On plan completion (after final batch):
    flags: items FAILing 3+ batches or requiring 3+ rework rounds as evolution candidates
    flags: batches where all PASS but 2+ rework rounds as potential checklist gaps
    traces: persistent code FAILs back to design/plan evaluation coverage as cross-mode gaps
    emits: "Checklist Evolution Candidates" section in plan completion summary

```

Checklist evolution is manual: edit files in `docs/retros/checklists/`, version via git.

### Data Structures

**`docs/retros/checklists/design-v1.md`** — binary design checklist:
```markdown
# Design Evaluation Checklist v1

## Requirements Traceability
- [ ] REQ-TRACE-01: Every requirement in _index.md maps to at least one BDD scenario
  # Type: inferential -- "maps to" requires semantic understanding of requirement-scenario coverage
  # Check: list requirement IDs from _index.md Requirements section; grep each ID in bdd-specs.md
  # Evidence: "REQ-XXX appears in _index.md:L but no scenario references it"
- [ ] REQ-TRACE-02: Every BDD scenario references a requirement (no orphan scenarios)
  # Type: inferential -- "references" may be by ID or by semantic content
  # Check: list scenario titles from bdd-specs.md; verify each cites a requirement ID from _index.md
  # Evidence: "Scenario 'XYZ' in bdd-specs.md:L cites no requirement ID"

## Scenario Concreteness
- [ ] SCEN-CONC-01: All Given clauses use specific data values, not vague placeholders
  # Type: computational -- grep for specific vague words produces deterministic result
  # Check: grep Given clauses in bdd-specs.md for "some ", "valid ", "appropriate ", "relevant ", "any "
  # Evidence: "bdd-specs.md:L -- 'Given <quoted text>' contains vague placeholder"
- [ ] SCEN-CONC-02: All Then clauses state observable outcomes (not "should work" or "should be correct")
  # Type: computational -- grep for specific non-observable terms produces deterministic result
  # Check: grep Then clauses in bdd-specs.md for "should work", "should be correct", "correctly", "properly"
  # Evidence: "bdd-specs.md:L -- 'Then <quoted text>' is not an observable outcome"

## Architecture Validity
- [ ] ARCH-01: No import described from inner layer to outer layer
  # Type: inferential -- layer boundary identification requires architectural context understanding
  # Check: scan architecture.md for import/dependency descriptions; flag any inner-to-outer direction
  # Evidence: "architecture.md:L -- describes <inner> importing from <outer>"
- [ ] ARCH-02: All external dependencies named in _index.md Constraints section
  # Type: inferential -- identifying "external dependency" requires domain judgment
  # Check: grep architecture.md for library/service names; verify each appears in _index.md Constraints
  # Evidence: "<name> referenced in architecture.md:L not listed in _index.md Constraints"
- [ ] ARCH-03: No circular component dependencies described
  # Type: computational -- cycle detection in a dependency graph is algorithmic
  # Check: build dependency graph from architecture.md component list; walk all paths for cycles
  # Evidence: "Cycle: <A> -> <B> -> <A> in architecture.md"

## Risk Identification
- [ ] RISK-01: Design includes at least 3 identified risks with mitigation strategies
  # Type: computational -- counting is mechanical
  # Check: count risk entries in _index.md Risks section; FAIL if count < 3
  # Evidence: "_index.md Risks section: N risks found (minimum 3 required)"
- [ ] RISK-02: Each risk mitigation is concrete (not "monitor closely" or "handle carefully")
  # Type: inferential -- "concrete" is a judgment call despite grep assistance for known vague patterns
  # Check: grep mitigations for "monitor", "handle carefully", "watch", "be careful", "ensure", "check"
  # Evidence: "_index.md -- mitigation '<quoted text>' specifies no concrete action or mechanism"
```

**`docs/retros/checklists/plan-v1.md`** — binary plan checklist:
```markdown
# Plan Evaluation Checklist v1

## Scenario Coverage
- [ ] PLAN-COV-01: Every BDD scenario from design maps to at least one task
  # Type: inferential -- "maps to" requires semantic matching between scenario text and task scope
  # Check: list scenario names from design bdd-specs.md; grep each in all task files
  # Evidence format: "Scenario '<name>' in bdd-specs.md has no referencing task file"
- [ ] PLAN-COV-02: No BDD scenario is unassigned in batch planning
  # Type: inferential -- scenario assignment may be implicit via task grouping
  # Check: list scenarios referenced across all batch sprint contracts; flag any design scenario absent
  # Evidence format: "Scenario '<name>' is unassigned in all batches"

## Task Completeness
- [ ] TASK-COMP-01: Every task has an acceptance criteria section
  # Type: computational -- heading presence check is deterministic
  # Check: grep each task file for "## Acceptance Criteria" heading
  # Evidence format: "task-{ID}-{slug}.md: no '## Acceptance Criteria' section"
- [ ] TASK-COMP-02: Every task has verification commands
  # Type: computational -- heading presence + non-empty content check is deterministic
  # Check: grep each task file for "## Verification" heading with non-empty content following it
  # Evidence format: "task-{ID}-{slug}.md: no '## Verification' section or section is empty"
- [ ] TASK-COMP-03: No verification command is descriptive ("verify manually", "check that it works")
  # Type: computational -- grep for description verbs produces deterministic result
  # Check: grep verification sections for "verify that", "check that", "ensure that", "manually", "confirm that"
  # Evidence format: "task-{ID}-{slug}.md:L — '<quoted text>' is a description, not an executable command"

## Dependency Validity
- [ ] DEP-01: No circular dependencies in task dependency graph
  # Type: computational -- graph cycle detection is algorithmic
  # Check: build directed graph from depends-on fields across all task files; walk for cycles
  # Evidence format: "Cycle detected: task-{A} → task-{B} → task-{A}"
- [ ] DEP-02: All task IDs in depends-on fields exist in the plan
  # Type: computational -- ID existence check is deterministic
  # Check: collect all task file IDs; verify each depends-on value matches a collected ID
  # Evidence format: "task-{ID}.md depends-on task-{X}, which does not exist in this plan"

## Test Coverage
- [ ] TEST-01: Every impl task has a corresponding test task or explicit absence justification
  # Type: computational -- filename pattern matching is deterministic
  # Check: for each *-impl.md, verify a file with matching numeric prefix and "-test" suffix exists, or grep the impl task for "no test" or "absence justification"
  # Evidence format: "task-{ID}-{slug}-impl.md: no test task and no absence justification"
```

**`docs/retros/checklists/code-v1.md`** — code verification checklist:
```markdown
# Code Evaluation Checklist v1

## Verification Gate
- [ ] CODE-VER-01: All task verification commands exit with code 0
  # Type: computational -- exit code is deterministic ground truth
  # Check: run each command from task verification sections independently; record exit code and output
  # Evidence format: "'<command>' exited with code N; last 30 lines: <output>"
- [ ] CODE-VER-02: Type checker exits 0 (if applicable)
  # Type: computational -- exit code is deterministic
  # Check: if tsconfig.json or pyproject.toml present, run tsc --noEmit or mypy; record exit code
  # Evidence format: "tsc --noEmit exited with code 1; errors: <output>"
- [ ] CODE-VER-03: Linter exits 0 (if applicable)
  # Type: computational -- exit code is deterministic
  # Check: if biome.json or .eslintrc present, run biome check or eslint; record exit code
  # Evidence format: "biome check exited with code 1; violations: <output>"

## Prohibited Patterns
- [ ] CODE-QUAL-01: No TODO/FIXME/placeholder comments in produced files
  # Type: computational -- grep for exact strings produces deterministic result
  # Check: grep produced files for "TODO", "FIXME", "HACK", "XXX", "placeholder"
  # Evidence format: "<file>:L — '<quoted line>' contains prohibited placeholder comment"
- [ ] CODE-QUAL-02: No stub function bodies (pass, ..., raise NotImplementedError)
  # Type: computational -- grep for exact patterns produces deterministic result
  # Check: grep produced files for "^\s*pass$", "^\s*\.\.\.$", "raise NotImplementedError", "throw new Error.*not implemented"
  # Evidence format: "<file>:L — stub body '<quoted line>'"
- [ ] CODE-QUAL-03: No hardcoded return values substituting real logic
  # Type: computational -- grep for exact patterns produces deterministic result
  # Check: grep produced files for "return True  #", "return \[\]  #", "return {}  #", "return None  # TODO"
  # Evidence format: "<file>:L — hardcoded return substituting real logic: '<quoted line>'"
```

**Evaluator output format** (all modes, replaces scores table):
```markdown
## Checklist Results

| Item ID       | Check                                      | Result | Evidence                                        |
|---------------|--------------------------------------------|--------|-------------------------------------------------|
| REQ-TRACE-01  | All requirements map to ≥1 scenario        | PASS   | 7/7 requirements traced                         |
| SCEN-CONC-01  | Given clauses use specific data            | FAIL   | bdd-specs.md:23 — "some valid user data"        |
| ARCH-01       | No inner→outer layer imports described     | PASS   | No violations found                             |

## Rework Items

| Item ID      | File          | Location | Issue                                                               |
|--------------|---------------|----------|---------------------------------------------------------------------|
| SCEN-CONC-01 | bdd-specs.md  | line 23  | Replace "some valid user data" with concrete field values (e.g., email, password) |

## Verdict: REWORK
1 item FAIL: SCEN-CONC-01
```

## File Structure

```
superpowers/
├── .claude-plugin/
│   └── plugin.json                       # unchanged
├── agents/
│   └── superpowers-evaluator.md          # UPDATED: binary checklists, no rubric scoring
└── skills/
    ├── brainstorming/
    │   ├── SKILL.md                      # UPDATED: evaluator refs → checklist terminology
    │   └── references/evaluation-rubrics.md  # UPDATED: checklist approach
    ├── writing-plans/
    │   ├── SKILL.md                      # UPDATED: evaluator refs → checklist terminology
    │   └── references/evaluation-rubrics.md  # UPDATED: checklist approach
    └── executing-plans/
        └── references/
            ├── evaluation-rubrics.md     # REMOVED
            └── evaluation-file-formats.md  # UPDATED: checklist format + cost tracking

docs/plans/YYYY-MM-DD-{topic}-plan/       # writing-plans output (unchanged)
  _index.md
  task-{ID}-{slug}-{type}.md

docs/plans/YYYY-MM-DD-{topic}-evals/      # NEW: executing-plans evaluation artifacts
  sprint-contract-batch-{N}.md
  evaluation-round-{N}-batch-{M}.md

docs/retros/                              # NEW: checklist storage
  checklists/
    design-v1.md                          # binary design checklist
    plan-v1.md                            # binary plan checklist
    code-v1.md                            # code verification checklist
```

## Rationale

**Why binary checks over rubric scores?**

Rubric scores drift because LLMs are sycophantic — the same artifact scored twice may get different results. Binary checks do not drift: "does this import cross a layer boundary?" is true or false regardless of what the model "thinks."

"Architecture Soundness: 3/5" gives the generator nothing concrete to fix. "[FAIL] architecture.md describes domain service importing from infra layer — domain must not depend on infra" gives the generator exactly what to change.

**Why this is simpler than the original design?**

Original design: 3 new agents + golden artifact directories + human-scores.json curation + calibration runs + run history management + rubric version tracking.

This design: 0 new agents + 0 new skills + 3 checklist files. Checklist evolution is manual via git.

**How this design relates to the Anthropic harness article**

The article's code evaluator uses Playwright MCP to run the application and observe whether user actions complete — pass/fail is determined by behavior, not by scoring. This design applies the same principle to code mode: command exit codes are the verdict.

The article does use numeric criteria (Design Quality, Originality, Craft, Functionality) for frontend aesthetic evaluation. That approach is appropriate for subjective visual judgment. This design covers structural code and document compliance, where binary checks are more appropriate: "no import from domain to infrastructure" is true or false, not 3/5.

The article observes that every harness component encodes an assumption about what the model cannot do on its own, and those assumptions go stale as models improve. Checklist items that never catch failures should be manually reviewed and removed — checks that no longer detect genuine issues are dead weight.

**How this design relates to cybernetic control theory**

The eval harness is a negative feedback control system: checklists define the setpoint, the evaluator is the sensor, PASS/FAIL is the comparator, and rework items are the error signal. Binary checks produce a 1-bit signal per item — lower nominal precision than 1-5 scores (~2.3 bits), but higher effective channel capacity because the signal is reliable and does not drift (Shannon's channel capacity = precision x reliability).

Check type annotations (CHK-7, CHK-8) address a second-order cybernetics concern: the evaluator (an LLM) is part of the system it observes. Computational checks eliminate observer bias entirely; inferential checks reduce it by anchoring judgment to explicit methods, but some noise remains. Annotating the type makes this noise budget visible rather than hidden. Note: the reliability advantage of binary over rubric is established for computational items (deterministic) and assumed for inferential items -- v1 annotation is a prerequisite for v2 measurement via multi-trial protocol, which will provide empirical data on inferential check agreement rates.

The three-level control hierarchy — immediate feedback (PASS/FAIL per batch), intra-plan learning (Phase 4 pattern injection), and checklist evolution (manual review) — maps to Ashby's ultra-stability: when first-order feedback fails to restore stability, the system changes its own parameters. EVO-1 through EVO-4 strengthen the transition between levels 2 and 3 by providing explicit signals (evolution candidates, variety gap detection) rather than relying solely on periodic manual review.

**Why add context management?**

The article explicitly states "context resets outperform context compaction." The Superpower Loop architecture is context compaction — same session, growing context. For long plan executions, this creates the "context anxiety" the article describes (premature completion as perceived limits approach). Batch-boundary handoffs are a pragmatic middle ground: they don't break the loop architecture but provide structured checkpoints that reduce the model's need to retain full prior-batch details.

**Why add cost tracking (best-effort)?**

The article compares "solo agent 20 min/$9 vs full harness." Without cost data, we cannot answer "is the evaluator overhead justified for this plan size?" Minimal metrics (duration, token counts if available) per evaluation report enable this assessment over time. Token counts are best-effort because Claude Code's Agent spawning model may not expose raw API usage metadata to the parent agent.

## Design Documents

- [BDD Specifications](./bdd-specs.md)
- [Architecture](./architecture.md)
- [Best Practices](./best-practices.md)
