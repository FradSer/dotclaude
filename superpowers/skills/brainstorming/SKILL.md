---
name: brainstorming
description: This skill should be used when the user has a new idea, feature request, or ambiguous requirement. It clarifies needs, explores options, and produces a solid design document and BDD specs before implementation starts.
user-invocable: true
---

# Brainstorming Ideas Into Designs

Turn rough ideas into implementation-ready designs through structured collaborative dialogue.

## Initialization

1. **Context Check**: Ensure you have read `CLAUDE.md` and `README.md` to understand project constraints.
2. **Codebase Index**: Verify you have access to the codebase and can run searches.

## Core Principles

1. **Converge in Order**: Clarify → Compare → Choose → Design → Commit → Transition
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
4. **Ask questions** - Use AskUserQuestion tool with exactly 1 question per call
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

## Git Commit

Commit the design folder to git with proper message format.

See `../../skills/references/git-commit.md` for detailed patterns, commit message templates, and requirements.

**Critical requirements**:
- Commit the entire folder: `git add docs/plans/YYYY-MM-DD-<topic>-design/`
- Prefix: `docs:` (lowercase)
- Subject: Under 50 characters, lowercase
- Footer: Co-Authored-By with model name
See `./references/exit-criteria.md` for Phase 4 validation checklist.

## Phase 4: Transition to Implementation

Prompt the user to use `superpowers:writing-plans` to create a detailed implementation plan.

Example prompt:
"Design complete. To create a detailed implementation plan, use `/superpowers:writing-plans`."

**PROHIBITED**: Do NOT offer to start implementation directly.

## Quality Check

See `./references/exit-criteria.md` for:
- Complete validation checklists for all phases
- Success indicators for high-quality brainstorming sessions
- Common pitfalls to avoid

## References

Detailed guidance for each phase:

- `./references/core-principles.md` - Core principles guiding the workflow
- `./references/discovery.md` - Exploration patterns and question guidelines
- `./references/options.md` - Option comparison and presentation patterns
- `./references/design-creation.md` - Sub-agent patterns, integration workflow, design structure
- `../../skills/references/git-commit.md` - Git commit patterns and requirements
- `./references/exit-criteria.md` - Validation checklists, success indicators, common pitfalls