---
name: brainstorming
description: Structures collaborative dialogue to turn rough ideas into implementation-ready designs. This skill should be used when the user has a new idea, feature request, ambiguous requirement, or asks to "brainstorm a solution" before implementation begins.
user-invocable: true
allowed-tools: ["Bash(git-agent:*)", "Bash(git:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-superpower-loop.sh:*)"]
---

# Brainstorming Ideas Into Designs

Turn rough ideas into implementation-ready designs through structured collaborative dialogue, scaled by task complexity.

## Complexity Routing

Assess complexity early (from `$ARGUMENTS` + quick codebase scan) and route the entire workflow:

| Aspect | Simple | Medium | Complex |
|--------|--------|--------|---------|
| Superpower Loop | Skip | Skip | Start (--max-iterations 30) |
| Questions | Sprint contract (1 round) | Sprint contract (1-2 rounds) | Sprint contract (2-3 rounds) |
| Approval gates | 1 (Phase 1) | 1 (Phase 1) | 2 (Phase 1 + Phase 2 light confirm) |
| Sub-agents (Design) | None | 2 | 3+ |
| QA | Evaluator (design mode) | Evaluator (design mode) | Evaluator (design mode) |
| Output files | `_index.md` + `bdd-specs.md` | `_index.md` + `bdd-specs.md` | All 4 + optional |

## Initialization

1. Capture `$ARGUMENTS` as the initial prompt
2. Read `CLAUDE.md` and `README.md` to understand project constraints
3. **If Complex** (determined by initial assessment or user hint): start Superpower Loop:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-superpower-loop.sh" "Brainstorm: $ARGUMENTS. Progress through phases: Phase 1 (Scope Alignment) -> Phase 2 (Design with QA) -> Phase 3 (Wrap-up)." --completion-promise "BRAINSTORMING_COMPLETE" --max-iterations 30
```
4. If not Complex: proceed directly, no loop needed

## Core Principles

1. **Context First**: Explore codebase before asking questions
2. **YAGNI Ruthlessly**: Only include what's explicitly needed
3. **Test-First Mindset**: Always include BDD specifications -- load `superpowers:behavior-driven-development` skill
4. **Incremental Validation**: Validate each phase exit before proceeding
5. **Complexity-Proportional**: Match effort to scope -- simple tasks get lightweight flow. Periodically re-test whether each complexity level's components are still load-bearing (use `/superpowers:retrospective`)

## Phase 1: Scope Alignment

Explore codebase, classify complexity, propose approach, get user approval.

**Actions**:

1. **Explore codebase**: Use Read/Grep/Glob to find relevant files, patterns, docs, recent commits. Build context before asking anything.
2. **Classify complexity**:
   - **Simple**: single file/component, clear pattern to follow
   - **Medium**: cross-module, some architectural decisions
   - **Complex**: new system, large refactor, multiple integration points
   - When uncertain, round up one level
3. **Sprint contract**: Present a structured proposal to the user:
   - "Here is my understanding of [problem]"
   - "I recommend [approach] because [rationale]"
   - "Alternatives considered: [brief list with trade-offs]"
   - "Key questions: [batch independent questions; sequence dependent ones]"
4. **Get approval**: Use AskUserQuestion with the structured proposal. Iterate if needed (1-2 rounds for Simple/Medium, 2-3 for Complex).

**Open-Ended Problems**: If the problem requires challenging assumptions or radical innovation, load `superpowers:build-like-iphone-team` skill in the sprint contract phase.

**Exit**: User-approved approach, complexity level stated, clear requirements and constraints.

See `./references/scope-alignment.md` for exploration patterns, question guidelines, and trade-off templates.

## Phase 2: Design with QA

Create design documents with integrated quality assurance, scaled by complexity.

**Step 1: Create Design Documents**

**Folder**: `docs/plans/YYYY-MM-DD-<topic>-design/` (the `-design` suffix is REQUIRED)

**Simple/Medium** (2 files):
- `_index.md` -- Context, Discovery Results, Requirements, Rationale, Detailed Design (include architecture and best practices inline), Design Documents
- `bdd-specs.md` -- Full Gherkin scenarios (happy path, edge cases, error conditions)

**Complex** (4 files):
- `_index.md` -- Context, Discovery Results, Requirements, Rationale, Detailed Design, Design Documents (links to companions)
- `bdd-specs.md` -- Full Gherkin scenarios
- `architecture.md` -- System overview, components, data structures, integration points
- `best-practices.md` -- Security, performance, code quality, common pitfalls

**`_index.md` MUST use these exact section headings in order**: Context, Discovery Results, Requirements, Rationale, Detailed Design, Design Documents.

**`bdd-specs.md`**: Write all Gherkin scenarios directly in this file. Do NOT create separate `.feature` files -- those belong to the implementation phase.

**Sub-agent strategy** (for design creation):
- **Simple**: No sub-agents. Main agent handles all research and document creation in a single pass.
- **Medium**: 2 sub-agents in parallel -- (1) Architecture & Best Practices Research, (2) Context & Requirements Synthesis. Integrate results.
- **Complex**: 3+ sub-agents in parallel -- (1) Architecture Research with WebSearch, (2) Best Practices Research with BDD, (3) Context & Requirements Synthesis. Additional sub-agents for distinct research-intensive aspects as needed. Integrate results, resolve conflicts favoring codebase patterns.

**Step 2: Integrated QA**

**All complexities (mandatory)**: Resolve the latest checklist from `docs/retros/checklists/design-v{N}.md` (highest N). Spawn `superpowers:superpowers-evaluator` agent (design mode) with the checklist path. Read the evaluator report:

- PASS: proceed to lightweight user confirmation
- REWORK: fix issues, re-run evaluator if needed
- REWORK 2+ rounds: consider pivoting back to Phase 1 to realign approach rather than patching
- Use AskUserQuestion: "Design complete. [Brief summary]. Any concerns before commit?"

Evaluator output is non-negotiable regardless of complexity. For Medium/Complex, pre-evaluator sub-agents may additionally run in parallel for finer-grained structural review (see `./references/design-and-qa.md`); these are complements, not substitutes. If the resolved `design-v{N}.md` does not exist, abort with a clear error naming the expected path — seed the checklist via `/superpowers:retrospective` before retrying.

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

**If Superpower Loop is active**: Output `<promise>BRAINSTORMING_COMPLETE</promise>` as the absolute last line. Nothing may follow the promise tag.

**CRITICAL**: Only output the promise when ALL of the following are TRUE:
- Phase 1-2 complete (scope aligned, design created, QA passed)
- Design folder committed to git
- User approval received in Phase 1 (and Phase 2 for Complex)

## References

- `./references/scope-alignment.md` -- Exploration patterns, sprint contract model, question guidelines
- `./references/design-and-qa.md` -- Output structures, sub-agent patterns, QA procedures
- `./references/evaluation-checklist-reference.md` -- Design evaluation checklist reference for evaluator
- `../../skills/references/git-commit.md` -- Git commit patterns (shared)
- `../../skills/references/loop-patterns.md` -- Completion promise patterns (shared)
