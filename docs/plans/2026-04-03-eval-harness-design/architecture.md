# Architecture

## System Overview

The eval harness is a pure agent pipeline that calibrates the `superpowers-evaluator` and tracks score trends across executing-plans rework rounds. Two independent subsystems share a common rubric file target:

```
Subsystem A: Calibration Pipeline (one-shot, user-triggered)
  /superpowers:eval-harness
    → eval-orchestrator
      → superpowers-evaluator (per golden artifact)
      → eval-bias-analyzer
      → eval-rubric-optimizer (optional, user-approved)

Subsystem B: Score Trend Tracking (continuous, in executing-plans)
  executing-plans Phase 3f
    → append to evaluation-history.json
    → compute trend label per task
  executing-plans Phase 4
    → surface trend in evidence block
    → plateau x2 → escalation
```

## Component Specifications

### eval-harness skill

**Role**: Entry point. Validates prerequisites, parses arguments, spawns `eval-orchestrator`.

**Arguments**: `[--mode design|plan|code|all] [--dry-run] [--apply-rubric-changes]`

**Pre-flight checks** (performed before spawning orchestrator):
1. Verify `eval-harness/golden/{mode}/` directory exists and contains at least one artifact
2. Verify each artifact directory contains `manifest.json` and `human-scores.json`
3. Verify each rubric file path is resolvable
4. If any check fails: report setup error with path, link to calibration protocol

**Allowed tools**: `Read`, `Glob`, `Grep`, `Agent`

---

### eval-orchestrator agent

**Role**: Coordinates the full calibration pipeline. Decides whether to invoke rubric-optimizer based on bias analysis results. Presents amendment proposals to user. Writes calibration report.

**Process**:
1. Read all artifact directories for the specified mode
2. For each artifact: spawn `superpowers-evaluator` with spawn context format:
   - Design: `"Evaluate the design at [artifact-path]. Read rubrics from [brainstorming-rubric-path]."`
   - Plan: `"Evaluate the plan at [artifact-path]. Read rubrics from [writing-plans-rubric-path]."`
   - Code: `"Evaluate the batch with sprint contract at [contract-path]. Read rubrics from [executing-plans-rubric-path]."`
3. Collect evaluator scores from each report file written to artifact directory
4. Spawn `eval-bias-analyzer` with paths to all evaluator reports and `human-scores.json` files
5. Receive bias analysis results
6. Write `calibration-report.json` to `eval-harness/runs/YYYY-MM-DD-HH-MM/`
7. If `bias_detected == true` AND NOT `--dry-run`:
   - Spawn `eval-rubric-optimizer` with calibration report path + rubric file paths
   - Receive amendment proposals
   - Present proposals to user via AskUserQuestion
   - If approved AND `--apply-rubric-changes`: instruct optimizer to write rubric files

**Allowed tools**: `Read`, `Glob`, `Grep`, `Agent`, `Write`

**Evaluator spawn context format** (critical — mode detection depends on exact keywords):

| Mode | Spawn context must contain |
|------|---------------------------|
| design | `"design"` + absolute path to artifact folder |
| plan | `"plan"` + absolute path to artifact folder |
| code | `"batch"` + absolute path to `sprint-contract-batch-{N}.md` |

---

### eval-bias-analyzer agent

**Role**: Read-only. Computes score deltas between evaluator output and human baseline. Classifies bias patterns. Returns structured analysis.

**Process**:
1. For each artifact: read `human-scores.json` and the evaluator's output report
2. Compute delta per (artifact × dimension): `delta = evaluator_score - human_score`
3. Compute per-dimension summary across all artifacts: `mean_delta`, `classification`
4. Classify each dimension:
   - `leniency`: mean_delta > 1.0
   - `borderline_leniency`: mean_delta in (0.75, 1.0]
   - `calibrated`: |mean_delta| <= 0.75
   - `borderline_severity`: mean_delta in [-1.0, -0.75)
   - `severity`: mean_delta < -1.0
5. Compute verdict accuracy: count verdicts matching `expected_verdict` / total artifacts
6. Compute overall agreement rate: pairs with |delta| <= 1.0 / total pairs
7. Output structured bias analysis (not a file write — returned to orchestrator)

**Allowed tools**: `Read`, `Grep`, `Glob`

**Canonical bias thresholds** (authoritative — `_index.md` CAL-3 and `bdd-specs.md` scenarios must use these values):

| Delta range (mean_delta) | Classification | Optimization triggered? |
|--------------------------|---------------|------------------------|
| > 1.0 | `leniency` | Yes |
| (0.75, 1.0] | `borderline_leniency` | No (advisory only) |
| [-0.75, 0.75] | `calibrated` | No |
| [-1.0, -0.75) | `borderline_severity` | No (advisory only) |
| < -1.0 | `severity` | Yes |

Bias optimization triggers only for full `leniency` or `severity` classification (mean_delta > 1.0 or < -1.0). Borderline classifications are reported but do not trigger rubric changes.

**Bias detection precedence**: Dimension-specific bias takes precedence over global calibration. An evaluator that is globally well-calibrated but systematically lenient on `risk_coverage` MUST be flagged.

---

### eval-rubric-optimizer agent

**Role**: Proposes concrete rubric amendments based on bias analysis. Writes files only after user approval is confirmed by orchestrator.

**Process**:
1. Read `calibration-report.json` (proposals input)
2. For each dimension classified as `leniency` or `severity`:
   a. Read the relevant rubric file section for that dimension
   b. Identify which score-level description creates the scoring window that enables the bias
   c. Propose a concrete amendment: rewrite the score-N description to tighten or loosen the boundary
3. Validate each amendment preserves `fail-ceiling < rework-floor <= pass` invariant
4. Present amendment proposals (not yet written to disk)
5. After orchestrator confirms user approval: write amendments to rubric files via Edit tool

**Amendment format** (per dimension):
```
Dimension: risk_coverage (design mode)
Current score-3 description: "Some risks identified but mitigations are vague or incomplete"
Proposed score-3 description: "At least 3 key risks identified; at least 2 have concrete mitigations; remaining risks acknowledged without mitigation"
Rationale: Evaluator mean_delta = 1.5 on risk_coverage; current description is too permissive — adds "or incomplete" qualifier that allows partial mitigations to reach score 3
Driving artifact: design-low-001 (human=1, evaluator=3, delta=+2)
```

**Allowed tools**: `Read`, `Grep`, `Glob`, `Edit` (Edit only activated after user approval)

**Anti-oscillation rule**: If a dimension was amended in a prior calibration run (detectable via run history), require `mean_delta > 1.25` before proposing another amendment to the same dimension. This prevents overcorrection.

---

### Score Trend Tracking (executing-plans augmentation)

**Where it fits**: Phase 3, step 2f (post-evaluation, after evaluator writes report).

**How it works**:
1. After evaluator writes `evaluation-round-{N}-batch-{M}.md`, read per-task scores from that report
2. Parse `evaluation-history.json` if it exists in plan directory; create if not
3. For each task in current round:
   - Find prior round entry for same task (if any)
   - Compute trend label (see rules in _index.md)
   - Append new round entry with trend label
4. Write updated `evaluation-history.json`

**Trend injection into generator prompt** (Phase 3f, before next rework cycle):

When evaluator returns REWORK and trend data is available, inject structured context:

```
## Evaluation Round {N} Results

| Task | Verdict | Trend | Dimensions scoring below 3 |
|------|---------|-------|---------------------------|
| 003  | REWORK  | improving | Completeness (2→3), Spec Compliance (2→3) |
| 005  | REWORK  | plateau | Completeness (2=2), Spec Compliance (2=2) |

Strategy recommendation:
- Task 003: continue refinement — scores are improving
- Task 005: PLATEAU detected — consider architectural change (see rework items)
```

**Escalation logic** (Phase 3f):
- Task verdict == REWORK AND trend == `plateau` AND plateau_count >= 2:
  → Log task_id to `escalated_tasks` array in `evaluation-history.json`
  → Do NOT attempt rework round 3; proceed to escalation per `blocker-and-escalation.md`

## Agent Interaction Diagram

```
User prompt: /superpowers:eval-harness --mode design
    │
    ▼
eval-harness skill
  pre-flight: check golden/design/ exists
    │ PASS
    ▼
eval-orchestrator agent
  reads: golden/design/*/manifest.json
  reads: golden/design/*/human-scores.json
    │
    │ for each artifact (sequential):
    ▼
  superpowers-evaluator agent (existing)
    reads: artifact files
    runs: rubric scoring
    writes: evaluation report to artifact dir
    returns: (control back to orchestrator)
    │
    │ all artifacts evaluated
    ▼
  eval-bias-analyzer agent
    reads: all evaluator reports + human-scores.json
    computes: deltas, classifications, agreement rate
    returns: bias_analysis struct
    │
    ▼
  eval-orchestrator: writes calibration-report.json
    │
    │ bias_detected == true?
    │ YES
    ▼
  eval-rubric-optimizer agent (proposals only)
    reads: calibration-report.json
    reads: brainstorming/references/evaluation-rubrics.md
    proposes: amendments (no file writes)
    returns: amendment_proposals[]
    │
    ▼
  AskUserQuestion: display proposals, request approval
    │
    │ approved + --apply-rubric-changes?
    │ YES
    ▼
  eval-rubric-optimizer: writes rubric file amendments
    │
    ▼
  eval-orchestrator: report summary to user
```

## File Layout

```
superpowers/
├── .claude-plugin/
│   └── plugin.json                          # +eval-harness in commands, +3 agents in agents
├── agents/
│   ├── superpowers-evaluator.md             # unchanged
│   ├── eval-orchestrator.md                 # NEW
│   ├── eval-bias-analyzer.md                # NEW
│   └── eval-rubric-optimizer.md             # NEW
├── eval-harness/
│   ├── golden/
│   │   ├── design/
│   │   │   ├── design-high-001/
│   │   │   │   ├── _index.md                # synthetic design document
│   │   │   │   ├── bdd-specs.md
│   │   │   │   ├── architecture.md
│   │   │   │   ├── best-practices.md
│   │   │   │   ├── manifest.json
│   │   │   │   └── human-scores.json
│   │   │   └── design-low-001/
│   │   │       └── [same structure, lower-quality content]
│   │   ├── plan/
│   │   │   ├── plan-high-001/
│   │   │   └── plan-low-001/
│   │   └── code/
│   │       ├── code-high-001/
│   │       └── code-low-001/
│   └── runs/
│       └── YYYY-MM-DD-HH-MM/
│           └── calibration-report.json
└── skills/
    ├── eval-harness/
    │   ├── SKILL.md                         # NEW
    │   └── references/
    │       └── calibration-protocol.md      # NEW: golden artifact authoring guide
    └── executing-plans/
        └── references/
            └── evaluation-file-formats.md   # augmented: evaluation-history.json section

In plan directories (docs/plans/*/):
  evaluation-history.json                    # NEW: per-round score tracking
```

## Plugin.json Changes

```json
{
  "commands": [
    "./skills/brainstorming/",
    "./skills/writing-plans/",
    "./skills/executing-plans/",
    "./skills/need-vet/",
    "./skills/eval-harness/"
  ],
  "agents": [
    "./agents/superpowers-evaluator.md",
    "./agents/eval-orchestrator.md",
    "./agents/eval-bias-analyzer.md",
    "./agents/eval-rubric-optimizer.md"
  ]
}
```

## Rubric File Paths (per mode)

| Mode | Rubric path |
|------|-------------|
| design | `skills/brainstorming/references/evaluation-rubrics.md` |
| plan | `skills/writing-plans/references/evaluation-rubrics.md` |
| code | `skills/executing-plans/references/evaluation-rubrics.md` |

These paths are injected by `eval-orchestrator` into each evaluator spawn context and each rubric-optimizer invocation. They are NOT hardcoded in the agent definitions.

## Dependency Map

```
eval-harness skill
  └── depends on: eval-orchestrator agent

eval-orchestrator agent
  └── depends on: superpowers-evaluator (existing)
  └── depends on: eval-bias-analyzer (new)
  └── depends on: eval-rubric-optimizer (new, conditional)
  └── depends on: eval-harness/golden/* (test data)
  └── writes to: eval-harness/runs/*/calibration-report.json

eval-bias-analyzer agent
  └── depends on: evaluator output (in artifact dirs)
  └── depends on: human-scores.json (in artifact dirs)

eval-rubric-optimizer agent
  └── depends on: calibration-report.json
  └── depends on: rubric files (3 paths)
  └── writes to: rubric files (only after user approval)

executing-plans skill (augmented)
  └── depends on: superpowers-evaluator (existing, unchanged)
  └── writes to: evaluation-history.json (new, in plan dir)
  └── reads from: evaluation-history.json (for trend labels)
```
