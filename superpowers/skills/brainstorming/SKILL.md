---
name: brainstorming
description: Structures collaborative dialogue to turn rough ideas into implementation-ready designs. This skill should be used when the user has a new idea, feature request, ambiguous requirement, or asks to "brainstorm a solution" before implementation begins.
user-invocable: true
allowed-tools: ["Read", "Write", "Glob", "Grep", "Agent", "AskUserQuestion", "Bash(git-agent:*)", "Bash(git:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-superpower-loop.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/seed-checklists.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/bail-log.sh:*)"]
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

**Calibration log** (run regardless of which branch fired — Bucket A bail, `--force` override, or Bucket C user-chose-skip):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/lib/bail-log.sh" brainstorming <event> "<short reason>" "$ARGUMENTS"
```

Where `<event>` is `bail_out` for a Bucket A skip, `force_override` for the `--force` branch entering Initialization, or `user_chose_skip` for a Bucket C user-chose-quick-edit. Skip the call only when the user routes to `/superpowers:systematic-debugging` (that skill writes its own log entry). The log feeds retrospective Phase 5a — frequent `force_override` against trivial-shaped inputs surfaces the bail-out threshold being too aggressive.

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

**`_index.md` MUST use these exact section headings in order**: Context, Discovery Results, Glossary, Requirements, Rationale, Detailed Design, Design Documents. The `## Glossary` section is populated by the vocabulary reconciliation pass below — required even when no divergence was found, so canonical labels are recorded for future readers.

**`bdd-specs.md`**: Write all Gherkin scenarios directly in this file. Do NOT create separate `.feature` files -- those belong to the implementation phase.

**Sub-agent strategy (mandatory)**: Launch 3+ sub-agents in parallel via the Agent tool. Each sub-agent runs in an isolated fresh context (context reset — research transcripts never pollute the main agent):
1. **Architecture Research** — existing patterns, libraries, codebase conventions. Uses WebSearch for latest best practices. Returns architecture recommendations with specific file references.
2. **Best Practices Research** — security, performance, testing patterns. Loads `superpowers:behavior-driven-development`. Returns BDD scenarios, testing strategy, best practices.
3. **Context & Requirements Synthesis** — consolidates discovery into requirements, success criteria, rationale.
4. **Additional sub-agents**: launch for distinct research-intensive aspects as needed.

**Vocabulary reconciliation (MANDATORY, before integration)**: After all sub-agents return and before integrating their outputs into design files, the main agent runs one explicit pass:

1. Scan each sub-agent's output for **domain-noun vocabulary**: privacy tiers, channel names, role names, schema field names, capability/component names, status flag values. Anything that names a concept rather than describing it.
2. Build a glossary table: rows = concept (one per distinct concept), columns = each sub-agent's chosen label. If a row has divergent labels across sub-agents, that concept needs reconciliation.
3. For each divergent concept, pick **one canonical label** — prefer the most-precise / most-discriminating form, prefer codebase patterns over external recommendations, prefer single-word forms only when they don't introduce ambiguity. Document the rejected variants alongside the canonical choice (so future maintainers see what was considered).
4. Rewrite divergent labels in the affected sub-agent outputs **before** producing the integrated `_index.md` / `architecture.md` / `bdd-specs.md` / `best-practices.md`. Do not write the four files first and reconcile after — divergent labels in the integrated output are an outcome to prevent at write time.
5. Record the canonical labels in `_index.md` under a `## Glossary` section directly after `## Discovery Results`.

**Verification (after integration)**: `grep -oE "<concept-noun>"` across the four files must return only the canonical label, never any rejected variant. If any rejected variant appears in any file, the integration step has not closed the loop — return to step 4 above.

**Why this exists**: The 2026-05-09 v3.x knowledge platform brainstorm produced three different privacy-tier vocabularies across `_index.md` (`public/project/local`), `architecture.md` (`local-only/cross-session/cross-project/external`), and `bdd-specs.md` (the latter). The divergence was not a content disagreement — sub-agents independently filled in vocabulary gaps and the main agent integrated all three without reconciliation. See `docs/retros/2026-05-09-v3-considered-deferred.md` for the inciting case.

**Integration**: After reconciliation, the main agent integrates returned results, resolves remaining conflicts favoring codebase patterns, and writes the 4 design files.

**Step 2: Integrated QA (default: on, overridable only via `harness-config.json`)**

**CRITICAL**: When `_DESIGN_EVALUATOR_DISABLED=true` (set in Phase 1.5), skip the evaluator spawn entirely, treat verdict as PASS, proceed to user confirmation, and append one `harness_observation` row to `docs/retros/harness-observations.jsonl`. Otherwise, run the evaluator pass below.

Resolve the latest checklist from `docs/retros/checklists/design-v{N}.md` (highest N). Spawn `superpowers:superpowers-evaluator` agent (design mode) with the checklist path. The evaluator outputs report content as text; write it to the design folder as `evaluation-design-round-{N}.md`. Then read the report verdict:

- PASS: proceed to lightweight user confirmation
- REWORK: fix issues, re-run evaluator if needed (writes `evaluation-design-round-2.md`, etc.)
- REWORK 2+ rounds: consider pivoting back to Phase 1 to realign approach rather than patching
- Use AskUserQuestion: "Design complete. [Brief summary]. Any concerns before commit?"

**Auto-seed when missing**: If `docs/retros/checklists/design-v{N}.md` does not exist, do NOT abort. Run `bash "${CLAUDE_PLUGIN_ROOT}/lib/seed-checklists.sh" design docs/retros/checklists/design-v1.md`, log `Auto-seeded design-v1.md`, then proceed with the new file. Exit code handling: 0 = seeded, 3 = already exists (treat as success and proceed with the existing file), 1/2 = real failure (disk/usage error → abort).

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

## References

- `./references/scope-alignment.md` -- Exploration patterns, sprint contract model, question guidelines
- `./references/design-and-qa.md` -- Output structures, sub-agent patterns, QA procedures
- `./references/evaluation-checklist-reference.md` -- Design evaluation checklist reference for evaluator
- `../../skills/references/git-commit.md` -- Git commit patterns (shared)
- `../../skills/references/loop-patterns.md` -- Completion promise patterns (shared)
