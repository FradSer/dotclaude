---
name: brainstorming
description: Structures collaborative dialogue to turn rough ideas into implementation-ready designs. This skill should be used when the user has a new idea, feature request, ambiguous requirement, or asks to "brainstorm a solution" before implementation begins.
user-invocable: true
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-superpower-loop.sh:*)"]
---

# Brainstorming Ideas Into Designs

Turn rough ideas into implementation-ready designs through structured collaborative dialogue using Superpower Loop for continuous iteration.

## CRITICAL: First Action - Start Superpower Loop NOW

**THIS MUST BE YOUR FIRST ACTION. Do NOT explore codebase, do NOT ask questions, do NOT do anything else until you have started the Superpower Loop.**

1. Capture `$ARGUMENTS` as the initial prompt
2. Immediately run:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-superpower-loop.sh" "Brainstorm: $ARGUMENTS. Continue progressing through the superpowers:brainstorming skill phases: Phase 1 (Discovery) → Phase 2 (Option Analysis) → Phase 3 (Design Creation) → Phase 4 (Design Reflection) → Phase 5 (Git Commit) → Phase 6 (Transition)." --completion-promise "BRAINSTORMING_COMPLETE" --max-iterations 50
```
3. Only after the loop is running, proceed to explore the codebase and continue with Phase 1

**The loop enables self-referential iteration throughout the brainstorming process.**

## Superpower Loop Integration

This skill uses Superpower Loop to enable self-referential iteration throughout the brainstorming process.

**CRITICAL**: Throughout the process, you MUST output `<promise>BRAINSTORMING_COMPLETE</promise>` only when:
- Phase 1-4 (Discovery, Option Analysis, Design Creation, Design Reflection) are all complete
- Design folder created with all required documents
- User approval received in Phase 2
- Git commit completed

Do NOT output the promise until ALL conditions are genuinely TRUE.

**ABSOLUTE LAST OUTPUT RULE**: The promise tag MUST be the very last text you output. Output any transition messages or instructions to the user BEFORE the promise tag. Nothing may follow `<promise>BRAINSTORMING_COMPLETE</promise>`.

## Initialization

(The Superpower Loop was already started in the critical first action above - do NOT start it again)

1. **Context Check**: Ensure you have read `CLAUDE.md` and `README.md` to understand project constraints.
2. **Codebase Index**: Verify you have access to the codebase and can run searches.

The loop will continue through all phases until `<promise>BRAINSTORMING_COMPLETE</promise>` is output.

## Core Principles

1. **Converge in Order**: Clarify → Compare → Choose → Design → Reflect → Commit → Transition
2. **Context First**: Explore codebase before asking questions
3. **Incremental Validation**: Validate each phase before proceeding
4. **YAGNI Ruthlessly**: Only include what's explicitly needed
5. **Test-First Mindset**: Always include BDD specifications - load `superpowers:behavior-driven-development` skill

## Phase 1: Discovery

Explore codebase first, then ask focused questions to clarify requirements.

**Actions**:

1. **Explore codebase** - Use Read/Grep/Glob to find relevant files and patterns
2. **Review context** - Check docs/, README.md, CLAUDE.md, recent commits
3. **Identify gaps** - Determine what's unclear from codebase alone
4. **Ask questions** - Use AskUserQuestion with exactly 1 question per call
   - Prefer multiple choice (2-4 options)
   - Ask one at a time, never bundle
   - Base on exploration gaps

**Open-Ended Problem Context**:

If the problem appears open-ended, ambiguous, or requires challenging assumptions:
- Consider applying first-principles thinking to identify the fundamental value proposition
- Question "why" repeatedly to reach core truths
- Be prepared to **explicitly load `superpowers:build-like-iphone-team` skill** in Phase 2 for radical innovation approaches

**Output**: Clear requirements, constraints, success criteria, and relevant patterns.

See `./references/discovery.md` for detailed patterns and question guidelines.
See `./references/exit-criteria.md` for Phase 1 validation checklist.

## Phase 2: Option Analysis

Research existing patterns, propose viable options, and get user approval.

**Actions**:

1. **Research** - Search codebase for similar implementations
2. **Identify options** - Propose 2-3 grounded in codebase reality, or explain "No Alternatives"
3. **Present** - Write conversationally, lead with recommended option, explain trade-offs
4. **Get approval** - Use AskUserQuestion, ask one question at a time until clear

**Radical Innovation Context**:

If the problem involves:
- Challenging industry conventions or "how things are usually done"
- Creating a new product category rather than improving existing
- Questioning fundamental assumptions
- Open-ended or ambiguous requirements that need disruptive thinking

Then **explicitly load `superpowers:build-like-iphone-team` skill** using the Skill tool to apply iPhone design philosophy (first-principles thinking, breakthrough technology, experience-driven specs, internal competition, Purple Dorm isolation).

**Output**: User-approved approach with rationale and trade-offs understood.

See `./references/options.md` for comparison and presentation patterns.
See `./references/exit-criteria.md` for Phase 2 validation checklist.

## Phase 3: Design Creation

Launch sub-agents in parallel for specialized research, integrate results, and create design documents.

**Core sub-agents (always required)**:

**Sub-agent 1: Architecture Research**
- Focus: Existing patterns, architecture, libraries in codebase
- Use WebSearch for latest best practices
- Output: Architecture recommendations with codebase references

**Sub-agent 2: Best Practices Research**
- Focus: Web search for best practices, security, performance patterns
- Load `superpowers:behavior-driven-development` skill
- Output: BDD scenarios, testing strategy, best practices summary

**Sub-agent 3: Context & Requirements Synthesis**
- Focus: Synthesize Phase 1 and Phase 2 results
- Output: Context summary, requirements list, success criteria

**Additional sub-agents (launch as needed based on project complexity)**:

Launch additional specialized sub-agents for distinct, research-intensive aspects. Each agent should have a single, clear responsibility and receive complete context.

**Integrate results**: Merge all findings, resolve conflicts, create unified design.

**Design document structure**:

```
docs/plans/YYYY-MM-DD-<topic>-design/
├── _index.md              # Context, Requirements, Rationale, Detailed Design, Design Documents section (MANDATORY)
├── bdd-specs.md           # BDD specifications (MANDATORY)
├── architecture.md        # Architecture details (MANDATORY)
├── best-practices.md      # Best practices and considerations (MANDATORY)
├── decisions/             # ADRs (optional)
└── diagrams/              # Visual artifacts (optional)
```

**CRITICAL: _index.md MUST include Design Documents section with references:**

```markdown
## Design Documents

- [BDD Specifications](./bdd-specs.md) - Behavior scenarios and testing strategy
- [Architecture](./architecture.md) - System architecture and component details
- [Best Practices](./best-practices.md) - Security, performance, and code quality guidelines
```

**Output**: Design folder created with all files saved.

See `./references/design-creation.md` for sub-agent patterns and integration workflow.
See `./references/exit-criteria.md` for Phase 3 validation checklist.

## Phase 4: Design Reflection

Before committing, launch sub-agents in parallel to verify design quality and identify gaps.

**Core reflection sub-agents (always required)**:

**Sub-agent 1: Requirements Traceability Review**
- Focus: Verify every Phase 1 requirement is addressed in design
- Output: Traceability matrix, orphaned requirements list

**Sub-agent 2: BDD Completeness Review**
- Focus: Check BDD scenarios cover happy path, edge cases, and error conditions
- Output: Missing scenarios list, coverage gaps

**Sub-agent 3: Cross-Document Consistency Review**
- Focus: Verify terminology, references, and component names are consistent
- Output: Inconsistencies list, terminology conflicts

**Additional sub-agents (launch as needed)**:
- Security Review - Identify security considerations not addressed
- Risk Assessment - Identify risks, assumptions, and failure modes

**Integrate and Update**:
1. Collect all sub-agent findings
2. Prioritize issues by impact
3. Update design documents to fix issues
4. Re-verify updated sections
5. **Confirm with user**: Present reflection summary and get approval before committing

**Output**: Updated design documents with issues resolved and user approval received.

See `./references/reflection.md` for sub-agent prompts and integration workflow.

## Phase 5: Git Commit

Commit the design folder to git with proper message format.

**Critical requirements**:
- Commit the entire folder: `git add docs/plans/YYYY-MM-DD-<topic>-design/`
- Prefix: `docs:` (lowercase)
- Subject: Under 50 characters, lowercase
- Footer: Co-Authored-By with model name

See `../../skills/references/git-commit.md` for detailed patterns.

## Phase 6: Transition to Implementation

Prompt the user to use `superpowers:writing-plans`, then output the promise as the absolute last line.

Output in this exact order:
1. Transition message: "Design complete. To create a detailed implementation plan, use `/superpowers:writing-plans`."
2. `<promise>BRAINSTORMING_COMPLETE</promise>` — nothing after this

**PROHIBITED**: Do NOT offer to start implementation directly. Do NOT output any text after the promise tag.

## References

- `./references/core-principles.md` - Core principles guiding the workflow
- `./references/discovery.md` - Exploration patterns and question guidelines
- `./references/options.md` - Option comparison and presentation patterns
- `./references/design-creation.md` - Sub-agent patterns, integration workflow, design structure
- `./references/reflection.md` - Design reflection patterns and gap identification strategies
- `./references/exit-criteria.md` - Validation checklists, success indicators, common pitfalls
- `../../skills/references/git-commit.md` - Git commit patterns and requirements (shared cross-skill resource)
- `../../skills/references/prompt-patterns.md` - Writing effective superpower loop prompts for each phase
- `../../skills/references/completion-promises.md` - Completion promise design and safety nets