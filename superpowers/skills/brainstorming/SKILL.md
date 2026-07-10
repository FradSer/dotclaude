---
name: brainstorming
description: Turns rough ideas into implementation-ready designs for the current repository via autonomous codebase research and BDD specs, then commits the design for your review (it runs to completion without pausing for mid-design questions). This skill should be used when the user wants to design a new software feature or multi-component change to be built in the current repo before implementation begins — including new features that do not yet reference existing code. NOT for hardware or physical-system design (sensors, devices, firmware-to-app communication, embedded behavior), questions outside this repo's codebase, single-file refactors, known-root-cause bug fixes, or "how does X work" questions (those route to systematic-debugging or direct code reading instead).
user-invocable: true
allowed-tools: ["Read", "Write", "Glob", "Grep", "Agent", "Bash(git-agent:*)", "Bash(git:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/seed-checklists.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh:*)"]
---

# Brainstorming Ideas Into Designs

Turn rough ideas into implementation-ready designs through structured codebase-grounded research. The full pipeline (parallel research sub-agents + evaluator) is calibrated for **open-ended multi-component problems**. Trivial work bypasses via the bail-out check below. This is substantial multi-phase work — **the recommended way to run it is wrapped in Claude Code's built-in `/goal`** (see below).

## Recommended: run wrapped in `/goal`

Brainstorming does open-ended, multi-turn research. **Launch it under Claude Code's built-in `/goal`** (v2.1.139+) so a fresh evaluator drives it to completion across turns instead of stopping mid-pipeline:

```
/goal "Claude has narrated a successful design commit (with commit hash) and the evaluator's verdict is PASS" /superpowers:brainstorming "<problem>"
```

`/goal` is a **user-typed outer wrapper** (a skill cannot enable it for itself mid-run), and its evaluator judges only what Claude narrates in the transcript — phrase the condition against narrated output (the commit hash, the literal evaluator verdict line), never filesystem state. Full semantics, condition phrasing, and bail-out interaction: `../../skills/references/goal-wrapper.md`.

## CRITICAL: Bail-Out Check (run before Initialization)

**Classify `$ARGUMENTS` into one of three buckets. Do NOT default to "proceed when in doubt" — that biases the agent single-direction toward over-engineering.**

**Bucket A — Strong trivial-scope signals (bail out: do NOT write design files, do NOT spawn evaluator):**

- Names a single file or single-line change ("change X to Y", "rename foo to bar", "log level to DEBUG")
- Mechanical refactor ("extract helper", "reorder imports", "update deprecated API call")
- Bug with a named root cause ("cookie domain is wrong, fix it") — route to `/superpowers:systematic-debugging`
- One-shot script / config tweak / dependency bump
- User explicitly said "just patch" / "no plan" / "terse fix"

**Bucket B — Strong open-ended signals (proceed to Initialization):**

- Multi-component design naming explicit subsystems (e.g., "design a notification system supporting email + SMS + push")
- Ambiguous requirements that the user expects to be clarified through dialogue
- Greenfield feature with explicit "design first" / "brainstorm" framing

**Bucket C — Ambiguous (default to Bucket B, do NOT pause to ask):**

- `$ARGUMENTS` is brief and could go either way (e.g., a single sentence with no scope cues)
- Mixes trivial signals with open-ended language
- Names an outcome but not a scope (e.g., "improve performance", "make it faster")

For Bucket A, output the bail-out response below and stop. For Bucket B (including all Bucket C cases), proceed to Initialization. The `--force` token is preserved for backward compatibility and now no-ops (the bail-out is per-invocation); a later scope pivot is absorbed by Phase 1's mid-stream pivot handling.

**Bail-out response (Bucket A, output verbatim, then proceed with direct edit OR hand off):**

> Detected trivial-scope work. Skipping the brainstorming pipeline (calibrated for open-ended multi-component problems). To force the full pipeline, re-invoke as `/superpowers:brainstorming --force "<task>"`.

## Initialization

1. **Capture the problem statement**: Reduce `$ARGUMENTS` to a single declarative sentence under ~150 chars — the problem to brainstorm, in the user's own framing. Do NOT paraphrase, summarize away constraints, or introduce vocabulary the user did not use. Strip a leading `--force` token if present (already consumed by the bail-out check). If `$ARGUMENTS` is empty, use the open problem the user just described in conversation.
2. **Read project context**: Read `CLAUDE.md` and `README.md` to understand project constraints. Then consult the docs index — run `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" list --kind design --status active` and `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" list --status expired`. Treat any `expired:` design's conclusions as non-authoritative — create a fresh design rather than extending an expired one. If an `active` design on the same topic already exists, surface it in the Phase 1 sprint contract and either extend it (preferred) or supersede it via the Phase 3 wrap-up. Then consult memory: run `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" list --kind memory --status active` and Read the 3-5 topically-relevant rows' files before Phase 1 exploration.
3. **Proceed to Phase 1** in the same turn.

## Core Principles

1. **Context First**: Explore codebase before asking questions
2. **YAGNI Ruthlessly**: Only include what's explicitly needed
3. **Test-First Mindset**: Always include BDD specifications -- load `superpowers:behavior-driven-development` skill
4. **Incremental Validation**: Validate each phase exit before proceeding
5. **Context Reset by Design**: Research and QA happen in fresh sub-agent contexts (Anthropic harness-design principle 1) — the main agent only synthesizes.

## Phase 1: Scope Alignment

Explore codebase, lock the approach inline, proceed to Phase 2 in the same iteration.

**Actions**:

1. **Explore codebase**: Use Read/Grep/Glob to find relevant files, patterns, docs, recent commits. Build context before recording the contract.
2. **Sprint contract**: Record a structured proposal inline in your turn output:
   - "Here is my understanding of [problem]"
   - "I recommend [approach] because [rationale]"
   - "Alternatives considered: [brief list with trade-offs]"
   - "Open questions absorbed: [questions you answered yourself from codebase evidence; never punt these to the user]"
3. **Lock and advance**: Treat the sprint contract as the locked scope and proceed to Phase 2. Do NOT pause to ask for approval — the evaluator at Phase 2 plus the user's post-commit review are the quality gates. If a question genuinely cannot be answered from the codebase, pick the safest default, document the assumption in the sprint contract, and surface it in Phase 2's design files so the evaluator can flag it.

**Open-Ended Problems**: When the problem requires challenging assumptions, apply first-principles reasoning inline in the sprint contract — name the assumption being challenged, the alternative framing, and why it changes the chosen approach.

**Exit**: Sprint contract recorded inline with a single chosen approach, clear requirements and constraints, ready for Phase 2.

**Mid-stream pivots** (only possible when wrapped in `/goal`): re-run Phase 1 step 1 with the new scope and regenerate the sprint contract from scratch; on a fundamental override or "abort"/"cancel", stop with a one-line note and write no design files. Full handling: `./references/scope-alignment.md` §Mid-Stream Pivots.

See `./references/scope-alignment.md` for exploration patterns, question guidelines, and trade-off templates.

## Phase 2: Design with QA + Vocabulary Reconciliation

Create design documents with integrated quality assurance, then reconcile cross-sub-agent vocabulary into a canonical glossary before integration. All research runs in fresh sub-agent contexts; the main agent only synthesizes and reconciles — it does not author content.

**Step 1: Create Design Documents**

**Folder**: `docs/plans/YYYY-MM-DD-<topic>-design/` (the `-design` suffix is REQUIRED). A second same-day design on the same topic gets a `-design-2/` (then `-3/`) suffix — the docs index keys on the full folder path. Full rules: `./references/design-and-qa.md` §Folder Naming Rules.

**Required files (4)**:
- `_index.md` -- Context, Discovery Results, Requirements, Rationale, Detailed Design, Design Documents (links to companions)
- `bdd-specs.md` -- Full Gherkin scenarios (happy path, edge cases, error conditions)
- `architecture.md` -- System overview, components, data structures, integration points
- `best-practices.md` -- Security, performance, code quality, common pitfalls

**`_index.md` MUST use these exact section headings in order**: Context, Discovery Results, Glossary, Requirements, Rationale, Detailed Design, Design Documents. The `## Glossary` section is populated by the vocabulary reconciliation pass below — required even when no divergence was found, so canonical labels are recorded for future readers.

**`bdd-specs.md`**: Write all Gherkin scenarios directly in this file. Do NOT create separate `.feature` files -- those belong to the implementation phase.

**Sub-agent strategy (mandatory)**: Launch 3+ sub-agents in parallel via the Agent tool, each in an isolated fresh context (research transcripts never pollute the main agent): Architecture Research (patterns, libraries, conventions; WebSearch for latest practices), Best Practices Research (security/performance/testing; loads `superpowers:behavior-driven-development`), Context & Requirements Synthesis, plus additional sub-agents for research-intensive aspects. Full prompts and outputs: `./references/design-and-qa.md` §Sub-Agent Strategy.

**Vocabulary reconciliation (MANDATORY, before integration)**: After all sub-agents return and before integrating their outputs, run one explicit pass: scan sub-agent outputs for domain-noun vocabulary (anything that names a concept rather than describing it), build a concept-by-sub-agent glossary table, pick ONE canonical label per divergent concept (prefer codebase patterns; document rejected variants), and rewrite divergent labels in the sub-agent outputs BEFORE producing the integrated four files — never write first and reconcile after. Record the canonical labels in `_index.md` under a `## Glossary` section directly after `## Discovery Results`. Full procedure and the 2026-05-09 inciting case: `./references/design-and-qa.md` §Vocabulary reconciliation.

**Verification (after integration)**: `grep -oE "<concept-noun>"` across the four files must return only the canonical label, never any rejected variant. A surviving variant means the reconciliation pass missed a file — return to it before proceeding.

**Integration**: After reconciliation, the main agent integrates returned results, resolves remaining conflicts favoring codebase patterns, and writes the 4 design files.

**Step 2: Integrated QA**

Resolve the latest checklist from `docs/retros/checklists/design-v{N}.md` (highest N). Spawn `superpowers:superpowers-evaluator` agent (design mode) with the checklist path. The evaluator outputs report content as text; write it to the design folder as `evaluation-design-round-{N}.md`. Then read the report verdict:

- PASS: proceed directly to Phase 3 wrap-up — do NOT pause for user confirmation (the PASS verdict + post-commit `git show` diff are the review surface).
- REWORK: fix issues, re-run evaluator if needed (writes `evaluation-design-round-2.md`, etc.)
- REWORK 2+ rounds: consider pivoting back to Phase 1 to realign approach rather than patching

**Auto-seed when missing**: If `docs/retros/checklists/design-v{N}.md` does not exist, do NOT abort. Run `bash "${CLAUDE_PLUGIN_ROOT}/lib/seed-checklists.sh" design docs/retros/checklists/design-v1.md`, log `Auto-seeded design-v1.md`, then proceed with the new file. Exit code handling: 0 = seeded, 3 = already exists (treat as success and proceed with the existing file), 1/2 = real failure (disk/usage error → abort).

**Exit**: Design folder created with all required files, QA passed.

See `./references/design-and-qa.md` for output structure details, sub-agent patterns, and QA procedures.
See `./references/evaluation-checklist-reference.md` for evaluator checklist calibration.

## Phase 3: Wrap-up

Commit the design and transition to implementation planning.

**Actions**:
0. **CRITICAL — do not defer**: Upsert the design into the docs index so downstream writer skills can discover it. Run `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" upsert design docs/plans/YYYY-MM-DD-<topic>-design/ --status active --summary "<one-line summary>"`. If a prior `active` design on the same topic is being replaced, first run `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" set-status docs/plans/<prior-design-path>/ "superseded-by:docs/plans/YYYY-MM-DD-<topic>-design/"` to mark it superseded. This consult-before/upsert-after pairing is what keeps the index truthful across phases.
0.5. **CRITICAL — do not defer**: Conditional memory-write step, gated on REWORK 2+ rounds (the Phase 2 trigger) — if 2+ REWORK rounds occurred on this design, capture the recurring cause: write `docs/memory/<category>_<slug>.md` (`category: decision` for a scope reversal, `category: pitfall` for a recurring evaluator-caught mistake), then run `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" upsert memory docs/memory/<category>_<slug>.md --status active --summary "<one-line>" --category <category>`. If fewer than 2 REWORK rounds occurred, this step is a no-op.
1. Stage and commit the entire folder in ONE chained command — a standalone `git add` is denied by the git plugin's hook: `git add docs/plans/YYYY-MM-DD-<topic>-design/ && git-agent commit --no-stage --intent "add design for <topic>" --co-author "Claude <Model> <Version> <noreply@anthropic.com>"`
2. On auth error, retry with `--free` flag
3. **Fallback**: If git-agent is unavailable, invoke the `/git:commit` skill via the Skill tool; full ladder in `../../skills/references/git-commit.md`
4. **Transition line** (output to user): "Design complete. To create a detailed implementation plan, use `/superpowers:writing-plans`."

Do NOT add a review/polish iteration after the commit. The four design files + evaluator PASS + commit are the complete exit conditions.

See `../../skills/references/git-commit.md` for detailed commit patterns.

## References

- `./references/scope-alignment.md` -- Exploration patterns, sprint contract model, question guidelines
- `./references/design-and-qa.md` -- Output structures, sub-agent patterns, QA procedures
- `./references/evaluation-checklist-reference.md` -- Design evaluation checklist reference for evaluator
- `../../skills/references/git-commit.md` -- Git commit patterns (shared)
- `../../skills/references/goal-wrapper.md` -- `/goal` wrapper semantics and condition phrasing (shared)
