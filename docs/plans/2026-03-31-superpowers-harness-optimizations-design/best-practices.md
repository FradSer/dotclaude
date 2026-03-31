# Best Practices: AI Agent Evaluation and Harness Design

Research findings and best practices for the superpowers harness optimizations,
compiled from Anthropic's engineering publications, academic research, and
industry patterns (2025-2026).

## 1. Separation of Generation from Evaluation

### The Core Problem

When asked to evaluate work they produced, agents tend to respond with confident
praise -- even when the quality is obviously mediocre. This self-evaluation bias
is the primary motivation for independent evaluation.

Source: Anthropic, "Harness design for long-running application development"

### Best Practices

- **Never let the generator grade its own output.** Launch a separate agent
  instance that has no memory of the generation process. It receives only the
  artifacts, not the reasoning or self-assessment.

- **Use adversarial framing.** The evaluator's role description should emphasize
  finding problems, not confirming success. Anthropic's GAN-inspired architecture
  sets generator and evaluator in productive tension.

- **Keep the evaluator's context minimal.** The evaluator should receive the
  sprint contract (acceptance criteria), the produced artifacts, and verification
  output -- nothing more. Excess context dilutes the evaluator's focus.

- **File-based handoff between agents.** Evaluation artifacts written to disk
  survive context resets and provide an audit trail. This is strictly preferable
  to passing evaluation state through agent memory or conversation context.

## 2. Graded Evaluation Rubrics

### Design Principles

- **Atomic criteria.** Each criterion targets a single, diagnosable dimension.
  "Code quality" is too broad; "no function body is a stub or placeholder" is
  testable.

- **Defined scale anchors.** A 1-5 scale requires written descriptions for each
  level. Without anchors, different evaluation runs produce inconsistent scores.

  | Score | Meaning |
  |-------|---------|
  | 1     | Missing or fundamentally broken |
  | 2     | Present but incomplete or has major issues |
  | 3     | Functional and meets minimum requirements |
  | 4     | Solid implementation with good practices |
  | 5     | Excellent -- exceeds requirements, well-tested |

- **Hard thresholds, not averages.** A single criterion below threshold fails
  the batch, regardless of how high other scores are. This prevents a high score
  in one dimension from masking a critical gap elsewhere.

- **Weight by task type.** Implementation tasks weight functionality higher;
  refactoring tasks weight code quality higher. The rubric adapts to what matters
  most for the current work.

### Hybrid Evaluation

Combine rubric-based LLM grading with deterministic checks:

| Check Type | Examples | Method |
|------------|----------|--------|
| Deterministic | Exit code 0, no TODO/FIXME, test count | Script |
| Rubric-based | Spec compliance, code quality, depth | LLM evaluator |

Deterministic checks run first as a gate. If they fail, there is no need to
invoke the LLM evaluator at all, saving cost.

## 3. Sprint Contract Negotiation

### The Problem

Vague acceptance criteria ("the feature works") allow the generator to declare
victory on incomplete implementations. The evaluator then has nothing concrete to
grade against.

### Best Practices

- **Negotiate before coding.** The evaluator reviews BDD scenarios and acceptance
  criteria before the generator writes any code. This aligns both agents on what
  "done" means.

- **Flag ambiguity explicitly.** Scenarios with vague Then-clauses ("Then it works
  correctly") must be rewritten with measurable outcomes ("Then the response
  contains a valid JSON body with status 200").

- **Add edge cases proactively.** The evaluator identifies missing error paths,
  boundary conditions, and integration edge cases. The contract grows during
  negotiation, not during evaluation.

- **Write the contract to a file.** The sprint-contract-batch-N.md file is the
  single source of truth for both generator and evaluator. Both reference it; neither
  operates from memory.

## 4. Context Management for Long Plans

### The Problem

Claude Sonnet 4.5 exhibited context anxiety that compaction alone could not fix,
making context resets essential for long tasks. As plans grow beyond 16 tasks,
accumulated context degrades quality in later batches.

Source: Anthropic, "Harness design for long-running application development"

### Best Practices

- **Detect long plans at load time.** Plans with 16+ tasks are marked for handoff
  mode. The threshold is configurable via the calibration config. Shorter plans
  use the standard Superpower Loop without handoff overhead.

- **Write handoff artifacts, not summaries.** The handoff document is structured
  data -- completed task IDs, pending task IDs, files modified, decisions made,
  blockers -- not a prose summary. Structure enables machine parsing; prose
  invites drift.

- **Keep handoffs under 2000 tokens.** The handoff must fit comfortably in a
  fresh context window alongside the skill instructions, task files for the
  current batch, and the evaluation history. Overly large handoffs defeat the
  purpose of resetting context.

- **Handoff artifacts reference evaluation state.** The handoff must include the
  latest evaluation round number so the fresh session knows which evaluation files
  to read. Without this, evaluation history is lost across resets.

- **Validate handoff artifacts on read.** A malformed handoff is worse than no
  handoff. If required sections are missing, fall back to reconstructing state
  from task files rather than operating on partial information.

- **Subagents inherit minimal context.** Each subagent receives only its assigned
  task file and relevant file paths -- not the full conversation history. This
  natural isolation prevents context contamination.

## 5. Model-Aware Harness Calibration

### The Problem

Running the full evaluation pipeline on every batch with a frontier model like
Opus is wasteful -- Opus's self-evaluation is stronger and requires less external
checking. Conversely, running reduced evaluation on Sonnet risks missing issues
that a lighter model would produce.

### Best Practices

- **Calibrate evaluation frequency by model capability.** Opus can run
  evaluators every other batch; Sonnet runs every batch. The mapping is explicit
  in a configuration file, not hardcoded.

- **Calibrate contract negotiation by model.** Opus may skip contract
  negotiation for simple batches; Sonnet always negotiates. The calibration
  config encodes this per model pattern.

- **Calibrate context reset thresholds.** Stronger models maintain coherence
  over longer contexts. Opus can handle 24-task plans before needing a reset;
  Sonnet triggers at 16.

- **Use wildcard defaults.** Unknown models get the most conservative settings
  (full evaluation, mandatory contracts, low reset threshold). This ensures
  safety when the model is unfamiliar.

- **Configuration file, not code.** The calibration config is a YAML file at
  .claude/harness-calibration.yml. Changes to calibration should not require
  editing skill files or scripts.

### Example Calibration Config

```yaml
# .claude/harness-calibration.yml
calibration:
  - model_pattern: "claude-opus-*"
    eval_frequency: every_other_batch
    contract_required: optional
    context_reset_threshold: 24
    evaluator_depth: standard

  - model_pattern: "claude-sonnet-*"
    eval_frequency: every_batch
    contract_required: mandatory
    context_reset_threshold: 16
    evaluator_depth: thorough

  - model_pattern: "*"
    eval_frequency: every_batch
    contract_required: mandatory
    context_reset_threshold: 12
    evaluator_depth: thorough
```

## 6. File-Based Communication Protocol

### The Problem

Agent-to-agent communication through conversation context is ephemeral -- it
does not survive context resets, is not auditable, and grows the context window.
For a multi-agent harness running over hours, file-based communication is the
only reliable medium.

Source: Anthropic, "In Agentic AI, It's All About the Markdown"

### Best Practices

- **Structured filenames with round numbers.** evaluation-round-1.md,
  sprint-contract-batch-2.md. The naming convention encodes ordering without
  requiring a manifest.

- **Required sections in evaluation files.** Every evaluation file must contain:
  batch_id, timestamp, criteria_scores, verdict, remediation (if FAIL), and
  files_reviewed. Missing sections are flagged but do not block the process.

- **Remediation is actionable.** "Code quality is low" is not remediation.
  "Function X in file Y has a stub body -- implement the validation logic per
  the sprint contract criterion 3" is remediation.

- **Cross-reference between rounds.** Round N references Round N-1's findings
  and confirms whether each issue was resolved. This creates a traceable
  improvement chain.

- **Files live in the plan folder.** All evaluation and contract files are
  co-located with task files in docs/plans/YYYY-MM-DD-topic-plan/. This makes
  the entire plan execution self-contained and portable.

- **Schema validation on write.** Validate that required sections exist when
  writing evaluation files. Log warnings for missing sections but do not crash --
  a partial report is better than no report.

## 7. Security Considerations

- **Evaluator isolation.** The evaluator agent must not have write access to
  implementation files. It reads artifacts and writes evaluation reports only.
  This prevents an evaluator bug from corrupting the codebase.

- **No secret leakage in evaluation files.** Evaluation reports are committed
  to the repository. Ensure they never contain credentials, API keys, or
  sensitive data from the codebase.

- **Handoff artifacts are gitignored.** Handoff files at .claude/handoff-*.md
  contain transient execution state and should not be committed.

- **Calibration config is version-controlled.** The harness-calibration.yml
  file is part of the project configuration and should be committed so that
  all contributors share the same calibration.

## 8. Performance Considerations

- **Cost optimization through skip rules.** Simple tasks (config, setup) skip
  the evaluator entirely. This can reduce evaluation cost by 20-40% on typical
  plans without sacrificing quality on substantive tasks.

- **Deterministic gates before LLM evaluation.** Run exit-code and stub-detection
  checks before invoking the evaluator. Failed deterministic checks do not need
  LLM grading.

- **Batch evaluation, not per-task evaluation.** The evaluator assesses an
  entire batch at once, not individual tasks. This amortizes the evaluator's
  context setup cost.

- **Capped retry count.** Maximum 2 rework rounds per batch before escalation.
  Unlimited retries waste tokens on issues that may require human judgment.

## Sources

- [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps)
- [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Demystifying evals for AI agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)
- [Rubric-Based Evaluation for Agentic Systems](https://medium.com/@aiforhuman/rubric-based-evaluation-for-agentic-systems-db6cb14d8526)
- [Evaluating AI Agents: A Hybrid Deterministic and Rubric-Based Framework](https://www.hebbia.com/blog/evaluating-ai-agents-a-hybrid-deterministic-and-rubric-based-framework)
- [Context Engineering for Coding Agents](https://martinfowler.com/articles/exploring-gen-ai/context-engineering-coding-agents.html)
- [State of Context Engineering in 2026](https://www.newsletter.swirlai.com/p/state-of-context-engineering-in-2026)
- [The GAN-Style Agent Loop: Deconstructing Anthropic's Harness Architecture](https://www.epsilla.com/blogs/anthropic-harness-engineering-multi-agent-gan-architecture)
- [In Agentic AI, It's All About the Markdown](https://visualstudiomagazine.com/articles/2026/02/24/in-agentic-ai-its-all-about-the-markdown.aspx)
