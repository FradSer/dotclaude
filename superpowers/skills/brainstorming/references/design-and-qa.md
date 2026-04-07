# Design with QA

## Goal

Create design documents with integrated quality assurance, scaled by complexity.

## Output Structure by Complexity

### Simple/Medium (2 files)

```
docs/plans/YYYY-MM-DD-<topic>-design/
├── _index.md              # Main design + inline architecture/best practices
└── bdd-specs.md           # BDD specifications
```

For Simple/Medium, fold architecture and best practices into the Detailed Design section of `_index.md`. The Design Documents section lists only:

```markdown
## Design Documents

- [BDD Specifications](./bdd-specs.md) - Behavior scenarios and testing strategy
```

### Complex (4 files)

```
docs/plans/YYYY-MM-DD-<topic>-design/
├── _index.md              # Main design document
├── bdd-specs.md           # BDD specifications
├── architecture.md        # Architecture details
├── best-practices.md      # Best practices and considerations
├── decisions/             # ADRs (optional)
└── diagrams/              # Visual artifacts (optional)
```

The Design Documents section lists all companions:

```markdown
## Design Documents

- [BDD Specifications](./bdd-specs.md) - Behavior scenarios and testing strategy
- [Architecture](./architecture.md) - System architecture and component details
- [Best Practices](./best-practices.md) - Security, performance, and code quality guidelines
```

## `_index.md` Required Sections (all complexity levels)

MUST use these exact section headings in this order:

1. `## Context` -- Original request and Q&A history
2. `## Discovery Results` -- Codebase exploration findings
3. `## Requirements` -- Finalized requirements and constraints
4. `## Rationale` -- Why this approach was chosen over alternatives
5. `## Detailed Design` -- Components, interfaces, implementation approach
   - For Simple/Medium: include architecture overview and key best practices inline
6. `## Design Documents` -- Links to companion documents (only those that exist)

## `bdd-specs.md` Content

Write all Gherkin scenarios directly in this file. Do NOT create separate `.feature` files -- those belong to the implementation phase only.

Cover:
- Happy path scenarios
- Edge cases and boundary conditions
- Error conditions and failure modes
- Testing strategy (unit, integration, E2E approach)

## `architecture.md` Content (Complex only)

- System overview and high-level architecture
- Component breakdown with responsibilities
- Data structures and interfaces
- Integration points with existing systems
- Technology choices with rationale

## `best-practices.md` Content (Complex only)

- Security considerations and patterns
- Performance considerations and optimizations
- Code quality standards and patterns
- Common pitfalls and anti-patterns to avoid

## Sub-Agent Strategy (Design Creation)

### Simple

No sub-agents. Main agent handles all research and document creation in a single pass: explore codebase, search for best practices, write BDD scenarios, create design documents.

### Medium (2 sub-agents)

Launch in parallel using the Agent tool:

**Sub-agent 1: Architecture & Best Practices** -- Research existing patterns, libraries, security, performance. Load `superpowers:behavior-driven-development` skill. Output: architecture recommendations, BDD scenarios in Given-When-Then format, best practices.

**Sub-agent 2: Context & Requirements Synthesis** -- Synthesize Phase 1 results into unified context. Output: requirements list, success criteria, rationale for chosen approach.

Integrate results, resolve conflicts favoring codebase patterns.

### Complex (3+ sub-agents)

Launch in parallel:

**Sub-agent 1: Architecture Research** -- Existing patterns, libraries, codebase conventions. Use WebSearch for latest best practices. Output: architecture recommendations with specific file references.

**Sub-agent 2: Best Practices Research** -- Security, performance, testing patterns. Load `superpowers:behavior-driven-development` skill. Output: BDD scenarios, testing strategy, best practices.

**Sub-agent 3: Context & Requirements Synthesis** -- Synthesize discovery and option results into unified context. Output: requirements list, success criteria, rationale.

**Additional sub-agents**: Launch for distinct research-intensive aspects as needed.

**Conflict resolution**: Favor codebase patterns over external recommendations. Verify disagreements with WebSearch. Document trade-offs.

**Integration workflow**:
1. Start with context and requirements from Synthesis sub-agent
2. Incorporate architecture recommendations
3. Add BDD scenarios and best practices
4. Resolve conflicts between sub-agent findings
5. Create unified design documents

## Integrated QA

### Simple: Self-Review Checklist

After creating documents, verify:
- [ ] Every Phase 1 requirement addressed in Detailed Design
- [ ] BDD scenarios cover happy path, key edge cases, error conditions
- [ ] `_index.md` uses required section headings in correct order
- [ ] Folder ends with `-design` suffix
- [ ] No scope creep beyond approved requirements

No human approval gate. Proceed to Phase 3 after self-review passes.

### Medium: 2 Sub-Agent Review

Launch 2 sub-agents in parallel:

**Sub-agent 1: Requirements & BDD Review** -- Verify every Phase 1 requirement is addressed. Check BDD scenarios cover happy path, edge cases, error conditions. Report traceability gaps and missing scenarios. Be skeptical: if a requirement appears partially addressed, flag it as a gap rather than rationalizing coverage.

**Sub-agent 2: Consistency & Risk Review** -- Check terminology consistency across documents. Verify cross-references work. Identify unaddressed risks. Report issues. Do not self-talk into approving: if a risk lacks a concrete mitigation action, it is unaddressed.

Note: the 2-agent QA split for Medium is an assumption that can be tested. If a single combined review agent produces equivalent quality, simplify.

**Priority scheme**:
- **High** (must fix): Orphaned requirements, missing happy path scenarios, security gaps, critical risks without mitigation
- **Medium** (should fix): Missing edge case scenarios, terminology inconsistencies, broken references
- **Low** (nice to have): Additional documentation, diagrams, examples

Fix High and Medium issues. No human approval gate. Proceed to Phase 3.

### Complex: Evaluator Mode

1. Resolve latest design checklist: scan `docs/retros/checklists/` for `design-v{N}.md`, select highest N
2. Spawn `superpowers:superpowers-evaluator` agent (design mode) with context: "Evaluate the design at [path] using the design checklist at [checklist-path]."
3. Evaluator outputs report content as text; main agent writes it to the design folder
4. Read the report:
   - **PASS**: Proceed to lightweight user confirmation
   - **REWORK**: Fix identified issues, re-run evaluator if needed
   - **REWORK 2+ rounds**: Consider pivoting back to Phase 1 to realign approach rather than repeatedly patching the same design
5. Present to user via AskUserQuestion: "Design complete. [Brief summary of what was created]. Any concerns before commit?"

See `./evaluation-checklist-reference.md` for checklist categories, verdict rules, and calibration examples.

## Folder Naming Rules

- Use `YYYY-MM-DD` date prefix for chronological ordering
- Use kebab-case for topic name (lowercase with hyphens)
- **MUST end with `-design`**
- Example: `2024-02-10-user-auth-design/`
