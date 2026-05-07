---
name: brainstorming
description: Structures collaborative dialogue to turn rough ideas into implementation-ready designs. This skill should be used when the user has a new idea, feature request, ambiguous requirement, or asks to "brainstorm a solution" before implementation begins.
user-invocable: true
allowed-tools: ["Read", "Write", "Glob", "Grep", "Agent", "AskUserQuestion", "Bash(git-agent:*)", "Bash(git:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-superpower-loop.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/seed-checklists.sh:*)"]
---

# Brainstorming Ideas Into Designs

Turn rough ideas into implementation-ready designs through structured collaborative dialogue. The full pipeline (Superpower Loop + parallel research sub-agents + evaluator) is calibrated for **open-ended multi-component problems**. Trivial work bypasses via the bail-out check below.

## CRITICAL: Bail-Out Check (run before Initialization)

**Classify `$ARGUMENTS` into one of three buckets. Do NOT default to "proceed when in doubt" — that biases the harness single-direction toward over-engineering.**

**Bucket A — Strong trivial-scope signals (bail out: do NOT start the loop, do NOT write design files, do NOT spawn evaluator):**

- Names a single file or single-line change ("change X to Y", "rename foo to bar", "log level to DEBUG")
- Mechanical refactor ("extract helper", "reorder imports", "update deprecated API call")
- Bug with a named root cause ("cookie domain is wrong, fix it") — route to `/superpowers:systematic-debugging`
- One-shot script / config tweak / dependency bump
- User explicitly said "just patch" / "no plan" / "terse fix"

**Bucket B — Strong open-ended signals (proceed to Initialization):**

- Multi-component design naming explicit subsystems (e.g., "design a notification system supporting email + SMS + push")
- Ambiguous requirements that the user expects to be clarified through dialogue
- Greenfield feature with explicit "design first" / "brainstorm" framing

**Bucket C — Ambiguous (use `AskUserQuestion` to decide; do NOT pick a default):**

- `$ARGUMENTS` is brief and could go either way (e.g., a single sentence with no scope cues)
- Mixes trivial signals with open-ended language
- Names an outcome but not a scope (e.g., "improve performance", "make it faster")

For Bucket A, output the bail-out response below and stop. For Bucket B, proceed to Initialization. For Bucket C, ask the user via `AskUserQuestion` with three options:

1. **Quick edit / direct change** — skip the pipeline, edit directly
2. **Run brainstorming pipeline** — full Discovery → Design → Wrap-up
3. **Route to `/superpowers:systematic-debugging`** — if the user actually meant a bug

Use the user's answer to dispatch (Bucket A / Bucket B / debugging route). The `--force` token (literal in `$ARGUMENTS`) bypasses this entire check and proceeds to Initialization unconditionally.

**Bail-out response (Bucket A, output verbatim, then proceed with direct edit OR hand off):**

> Detected trivial-scope work. Skipping the brainstorming pipeline (calibrated for open-ended multi-component problems). To force the full pipeline, re-invoke as `/superpowers:brainstorming --force "<task>"`.

## Initialization

1. Capture `$ARGUMENTS` as the initial prompt
2. Read `CLAUDE.md` and `README.md` to understand project constraints
3. Start the Superpower Loop (no size gate beyond bail-out):
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-superpower-loop.sh" "Brainstorm: $ARGUMENTS. Progress through phases: Phase 1 (Scope Alignment) -> Phase 1.5 (Harness Config Check) -> Phase 2 (Design with QA) -> Phase 3 (Wrap-up)." --completion-promise "BRAINSTORMING_COMPLETE" --max-iterations 30
```

## Core Principles

1. **Context First**: Explore codebase before asking questions
2. **YAGNI Ruthlessly**: Only include what's explicitly needed
3. **Test-First Mindset**: Always include BDD specifications -- load `superpowers:behavior-driven-development` skill
4. **Incremental Validation**: Validate each phase exit before proceeding
5. **Context Reset by Design**: Research and QA happen in fresh sub-agent contexts (Anthropic harness-design principle 1) — the main brainstorming agent only synthesizes, it does not accumulate research transcripts.

## Phase 1: Scope Alignment

Explore codebase, propose approach, get user approval.

**Actions**:

1. **Explore codebase**: Use Read/Grep/Glob to find relevant files, patterns, docs, recent commits. Build context before asking anything.
2. **Sprint contract**: Present a structured proposal to the user:
   - "Here is my understanding of [problem]"
   - "I recommend [approach] because [rationale]"
   - "Alternatives considered: [brief list with trade-offs]"
   - "Key questions: [batch independent questions; sequence dependent ones]"
3. **Get approval**: Use AskUserQuestion with the structured proposal. Iterate (2-3 rounds) until the scope is locked.

**Open-Ended Problems**: If the problem requires challenging assumptions or radical innovation, load `superpowers:build-like-iphone-team` skill in the sprint contract phase.

**Exit**: User-approved approach, clear requirements and constraints.

**On user rejection of the sprint contract** (response says "no", "wrong", "different approach", names specific objections):
- Do NOT auto-loop with the same proposal. The Stop hook will re-inject the same prompt; absorb the rejection in the next iteration by regenerating the contract from scratch with the user's objections as new constraints.
- If the user names a different problem entirely ("actually this is about X"), reset captured `$ARGUMENTS` to the new framing and re-run Phase 1 step 1 (codebase exploration with the new scope).
- If the user says "abort" or "cancel", emit `<promise>BRAINSTORMING_COMPLETE</promise>` after a one-line cancellation note. Do not write design files.

See `./references/scope-alignment.md` for exploration patterns, question guidelines, and trade-off templates.

## Phase 1.5: Read Harness Config (assumption test)

**CRITICAL**: Before Phase 2, if `docs/retros/harness-config.json` exists and lists `design_evaluator` in `disabled_components[]`, set a local flag `_DESIGN_EVALUATOR_DISABLED=true`. Honor that flag in Phase 2 Step 2 (skip evaluator spawn) AND append one row to `docs/retros/harness-observations.jsonl` after Phase 2 completes (schema: `../executing-plans/references/intra-plan-learning.md`). Skip silently when the file does not exist or `disabled_components[]` is empty. See `../retrospective/references/harness-config.md` for supported identifiers.

## Phase 2: Design with QA

Create design documents with integrated quality assurance. All research runs in fresh sub-agent contexts; the main agent only synthesizes.

**Step 1: Create Design Documents**

**Folder**: `docs/plans/YYYY-MM-DD-<topic>-design/` (the `-design` suffix is REQUIRED)

**Required files (4)**:
- `_index.md` -- Context, Discovery Results, Requirements, Rationale, Detailed Design, Design Documents (links to companions)
- `bdd-specs.md` -- Full Gherkin scenarios (happy path, edge cases, error conditions)
- `architecture.md` -- System overview, components, data structures, integration points
- `best-practices.md` -- Security, performance, code quality, common pitfalls

**`_index.md` MUST use these exact section headings in order**: Context, Discovery Results, Requirements, Rationale, Detailed Design, Design Documents.

**`bdd-specs.md`**: Write all Gherkin scenarios directly in this file. Do NOT create separate `.feature` files -- those belong to the implementation phase.

**Sub-agent strategy (mandatory)**: Launch 3+ sub-agents in parallel via the Agent tool. Each sub-agent runs in an isolated fresh context (context reset — research transcripts never pollute the main agent):
1. **Architecture Research** — existing patterns, libraries, codebase conventions. Uses WebSearch for latest best practices. Returns architecture recommendations with specific file references.
2. **Best Practices Research** — security, performance, testing patterns. Loads `superpowers:behavior-driven-development`. Returns BDD scenarios, testing strategy, best practices.
3. **Context & Requirements Synthesis** — consolidates discovery into requirements, success criteria, rationale.
4. **Additional sub-agents**: launch for distinct research-intensive aspects as needed.

The main agent integrates returned results, resolves conflicts favoring codebase patterns, and writes the 4 design files.

**Step 2: Integrated QA (default: on, overridable only via `harness-config.json`)**

**CRITICAL**: When `_DESIGN_EVALUATOR_DISABLED=true` (set in Phase 1.5), skip the evaluator spawn entirely, treat verdict as PASS, proceed to user confirmation, and append one `harness_observation` row to `docs/retros/harness-observations.jsonl`. Otherwise, run the evaluator pass below.

Resolve the latest checklist from `docs/retros/checklists/design-v{N}.md` (highest N). Spawn `superpowers:superpowers-evaluator` agent (design mode) with the checklist path. The evaluator outputs report content as text; write it to the design folder as `evaluation-design-round-{N}.md`. Then read the report verdict:

- PASS: proceed to lightweight user confirmation
- REWORK: fix issues, re-run evaluator if needed (writes `evaluation-design-round-2.md`, etc.)
- REWORK 2+ rounds: consider pivoting back to Phase 1 to realign approach rather than patching
- Use AskUserQuestion: "Design complete. [Brief summary]. Any concerns before commit?"

**Auto-seed when missing**: If `docs/retros/checklists/design-v{N}.md` does not exist, do NOT abort. Run `bash "${CLAUDE_PLUGIN_ROOT}/lib/seed-checklists.sh" design docs/retros/checklists/design-v1.md`, log `Auto-seeded design-v1.md`, then proceed with the new file. Abort only if the script exits non-zero (e.g., disk error).

**Exit**: Design folder created with all required files, QA passed.

See `./references/design-and-qa.md` for output structure details, sub-agent patterns, and QA procedures.
See `./references/evaluation-checklist-reference.md` for evaluator checklist calibration.

## Phase 3: Wrap-up

Commit the design and transition to implementation planning.

**Actions**:
1. Stage the entire folder: `git add docs/plans/YYYY-MM-DD-<topic>-design/`
2. Run: `git-agent commit --no-stage --intent "add design for <topic>" --co-author "Claude <Model> <Version> <noreply@anthropic.com>"`
3. On auth error, retry with `--free` flag
4. **Fallback**: If git-agent is unavailable, use `git commit` with conventional format

See `../../skills/references/git-commit.md` for detailed commit patterns.

**Transition**: "Design complete. To create a detailed implementation plan, use `/superpowers:writing-plans`."

Output `<promise>BRAINSTORMING_COMPLETE</promise>` as the absolute last line. Nothing may follow the promise tag.

**CRITICAL**: Only output the promise when ALL of the following are TRUE:
- Phase 1-2 complete (scope aligned, design created, QA passed)
- Design folder committed to git
- User approval received in Phase 1 and Phase 2

## References

- `./references/scope-alignment.md` -- Exploration patterns, sprint contract model, question guidelines
- `./references/design-and-qa.md` -- Output structures, sub-agent patterns, QA procedures
- `./references/evaluation-checklist-reference.md` -- Design evaluation checklist reference for evaluator
- `../../skills/references/git-commit.md` -- Git commit patterns (shared)
- `../../skills/references/loop-patterns.md` -- Completion promise patterns (shared)
