---
name: brainstorming
description: Turns rough ideas into implementation-ready designs via autonomous codebase research and BDD specs, then commits the design for your review (it runs to completion without pausing for mid-design questions). This skill should be used when the user has a new idea, feature request, ambiguous requirement, or asks to "brainstorm a solution" before implementation begins.
user-invocable: true
allowed-tools: ["Read", "Write", "Glob", "Grep", "Agent", "Bash(git-agent:*)", "Bash(git:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/seed-checklists.sh:*)"]
---

# Brainstorming Ideas Into Designs

Turn rough ideas into implementation-ready designs through structured codebase-grounded research. The full pipeline (parallel research sub-agents + evaluator) is calibrated for **open-ended multi-component problems**. Trivial work bypasses via the bail-out check below. This is substantial multi-phase work — **the recommended way to run it is wrapped in Claude Code's built-in `/goal`** (see below).

## Recommended: run wrapped in `/goal`

Brainstorming does open-ended, multi-turn research. **Launch it under Claude Code's built-in `/goal`** (v2.1.139+) so a fresh evaluator drives it to completion across turns instead of stopping mid-pipeline:

```
/goal "Claude has narrated a successful design commit (with commit hash) and the evaluator's verdict is PASS" /superpowers:brainstorming "<problem>"
```

`/goal` is a **user-typed outer wrapper** — it must prefix the invocation; a skill cannot enable it for itself mid-run. The evaluator judges only what Claude narrates in the transcript (it does NOT read files or run commands) — phrase the condition against narrated output (the commit hash, the literal evaluator verdict line), never filesystem state, which is unverifiable and will time out. Full semantics, condition phrasing, and bail-out interaction: `../../skills/references/goal-wrapper.md`.

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

For Bucket A, output the bail-out response below and stop. For Bucket B (including all Bucket C cases), proceed to Initialization. The `--force` token (literal in `$ARGUMENTS`) is preserved for backward compatibility; it now no-ops since the bail-out is per-invocation. If the user later signals the scope is wrong, the Phase 1 rejection-handling block at the bottom of this section absorbs the pivot.

**Bail-out response (Bucket A, output verbatim, then proceed with direct edit OR hand off):**

> Detected trivial-scope work. Skipping the brainstorming pipeline (calibrated for open-ended multi-component problems). To force the full pipeline, re-invoke as `/superpowers:brainstorming --force "<task>"`.

## Initialization

1. **Capture the problem statement**: Reduce `$ARGUMENTS` to a single declarative sentence under ~150 chars — the problem to brainstorm, in the user's own framing. Do NOT paraphrase, summarize away constraints, or introduce vocabulary the user did not use. Strip a leading `--force` token if present (already consumed by the bail-out check). If `$ARGUMENTS` is empty, use the open problem the user just described in conversation.
2. **Read project context**: Read `CLAUDE.md` and `README.md` to understand project constraints.
3. **Proceed to Phase 1** in the same turn.

## Core Principles

1. **Context First**: Explore codebase before asking questions
2. **YAGNI Ruthlessly**: Only include what's explicitly needed
3. **Test-First Mindset**: Always include BDD specifications -- load `superpowers:behavior-driven-development` skill
4. **Incremental Validation**: Validate each phase exit before proceeding
5. **Context Reset by Design**: Research and QA happen in fresh sub-agent contexts (Anthropic harness-design principle 1) — the main brainstorming agent only synthesizes, it does not accumulate research transcripts.

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

**Open-Ended Problems**: When the problem requires challenging assumptions or radical innovation, apply first-principles reasoning inline in the sprint contract — name the assumption being challenged, the alternative framing, and why the new framing changes the chosen approach. The user's global CLAUDE.md "Challenge the premise before implementing" rule already covers this surface; no separate skill load is needed.

**Exit**: Sprint contract recorded inline with a single chosen approach, clear requirements and constraints, ready for Phase 2.

**Mid-stream pivots** (only possible when wrapped in `/goal`; on a re-prompt turn the user injects "actually this is about X" or "wrong direction"):
- Absorb the new framing by re-running Phase 1 step 1 (codebase exploration with the new scope) and regenerating the sprint contract from scratch with the new framing as the constraint.
- If the override is fundamental (the user wants a completely unrelated brainstorm), stop the current brainstorm with a one-line note and have the user re-invoke `/superpowers:brainstorming` with the new framing.
- If the user says "abort" or "cancel", stop with a one-line cancellation note. Do not write design files.

See `./references/scope-alignment.md` for exploration patterns, question guidelines, and trade-off templates.

## Phase 2: Design with QA + Vocabulary Reconciliation

Create design documents with integrated quality assurance, then reconcile cross-sub-agent vocabulary into a canonical glossary before integration. All research runs in fresh sub-agent contexts; the main agent only synthesizes and reconciles — it does not author content.

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

**Step 2: Integrated QA**

Resolve the latest checklist from `docs/retros/checklists/design-v{N}.md` (highest N). Spawn `superpowers:superpowers-evaluator` agent (design mode) with the checklist path. The evaluator outputs report content as text; write it to the design folder as `evaluation-design-round-{N}.md`. Then read the report verdict:

- PASS: proceed directly to Phase 3 wrap-up — do NOT pause for user confirmation. The evaluator PASS verdict plus the post-commit git diff are the review surface; the user audits via `git show` if they want a check.
- REWORK: fix issues, re-run evaluator if needed (writes `evaluation-design-round-2.md`, etc.)
- REWORK 2+ rounds: consider pivoting back to Phase 1 to realign approach rather than patching

**Auto-seed when missing**: If `docs/retros/checklists/design-v{N}.md` does not exist, do NOT abort. Run `bash "${CLAUDE_PLUGIN_ROOT}/lib/seed-checklists.sh" design docs/retros/checklists/design-v1.md`, log `Auto-seeded design-v1.md`, then proceed with the new file. Exit code handling: 0 = seeded, 3 = already exists (treat as success and proceed with the existing file), 1/2 = real failure (disk/usage error → abort).

**Exit**: Design folder created with all required files, QA passed.

See `./references/design-and-qa.md` for output structure details, sub-agent patterns, and QA procedures.
See `./references/evaluation-checklist-reference.md` for evaluator checklist calibration.

## Phase 3: Wrap-up

Commit the design and transition to implementation planning.

**Actions**:
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
