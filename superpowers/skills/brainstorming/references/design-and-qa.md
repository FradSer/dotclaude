# Design with QA

## Goal

Create design documents with integrated quality assurance. Unconditional 4-file output — no complexity routing.

## Output Structure (4 files, mandatory)

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

## `_index.md` Required Sections

MUST use these exact section headings in this order:

1. `## Context` -- Original request and Q&A history
2. `## Discovery Results` -- Codebase exploration findings
3. `## Glossary` -- Canonical labels for domain nouns; populated by the vocabulary reconciliation pass below. Required even when no reconciliation conflict was found (record the canonical labels for the concepts the design names so future readers and downstream skills don't reintroduce divergent forms).
4. `## Requirements` -- Finalized requirements and constraints
5. `## Rationale` -- Why this approach was chosen over alternatives
6. `## Detailed Design` -- Components, interfaces, implementation approach
7. `## Design Documents` -- Links to companion documents

## `bdd-specs.md` Content

Write all Gherkin scenarios directly in this file. Do NOT create separate `.feature` files -- those belong to the implementation phase only.

Cover:
- Happy path scenarios
- Edge cases and boundary conditions
- Error conditions and failure modes
- Testing strategy (unit, integration, E2E approach)

## `architecture.md` Content

- System overview and high-level architecture
- Component breakdown with responsibilities
- Data structures and interfaces
- Integration points with existing systems
- Technology choices with rationale

## `best-practices.md` Content

- Security considerations and patterns
- Performance considerations and optimizations
- Code quality standards and patterns
- Common pitfalls and anti-patterns to avoid

## Sub-Agent Strategy (Design Creation)

Launch 3+ sub-agents in parallel via the Agent tool. No size gates — research always runs in fresh contexts so the main agent's context stays focused on synthesis:

**Sub-agent 1: Architecture Research** -- Existing patterns, libraries, codebase conventions. Use WebSearch for latest best practices. Output: architecture recommendations with specific file references.

**Sub-agent 2: Best Practices Research** -- Security, performance, testing patterns. Load `superpowers:behavior-driven-development` skill. Output: BDD scenarios, testing strategy, best practices.

**Sub-agent 3: Context & Requirements Synthesis** -- Synthesize discovery and option results into unified context. Output: requirements list, success criteria, rationale.

**Additional sub-agents**: Launch for distinct research-intensive aspects as needed.

**Conflict resolution**: Favor codebase patterns over external recommendations. Verify disagreements with WebSearch. Document trade-offs.

**Vocabulary reconciliation (mandatory, before integration)**:

Sub-agents running in parallel will independently fill in vocabulary gaps for any concept the user did not name explicitly. If they pick different labels for the same concept (e.g. privacy tiers as `public/project/local` vs `local-only/cross-session/cross-project/external`), and the main agent integrates without reconciling, the four design files end up using divergent vocabularies — a defect that is hard to catch by content review and produces real downstream confusion.

Before integration:

1. Scan each sub-agent's output for **domain-noun vocabulary**: privacy tiers, channel names, role names, schema field names, capability/component names, status flag values. Anything that names a concept rather than describing it.
2. Build a glossary: rows = concept, columns = each sub-agent's chosen label. Rows with divergent columns need reconciliation.
3. For each divergent concept, pick **one canonical label** — prefer the most-precise / most-discriminating form; prefer codebase patterns over external recommendations; prefer forms that already appear in shipped `superpowers/lib/` or `docs/retros/` schema rows. Note rejected variants briefly so the choice is auditable.
4. Rewrite divergent labels in the affected sub-agent outputs **before** producing the integrated four files. Reconciling after-the-fact across four already-written files is more error-prone and frequently missed.
5. Record canonical labels in `_index.md` under a `## Glossary` section directly after `## Discovery Results`.

**Verification**: After integration, `grep -oE "<concept-noun>" docs/plans/<folder>/*` returns only the canonical label across all four files. Any rejected variant surfacing means step 4 missed a file.

**Inciting case**: `docs/retros/2026-05-09-v3-considered-deferred.md` records a brainstorm where three sub-agents produced three privacy-tier vocabularies that were never reconciled, and two evaluator rounds passed the resulting design without flagging the divergence. JUST-01 in `docs/retros/checklists/design-v1.md` blocks the produce-then-evaluate path; this vocab-reconciliation step blocks the produce-divergent-vocab path at write time.

**Integration workflow**:
1. Start with context and requirements from Synthesis sub-agent
2. Incorporate architecture recommendations
3. Add BDD scenarios and best practices
4. Run vocabulary reconciliation pass (above) before producing the integrated files
5. Resolve remaining conflicts between sub-agent findings
6. Create unified design documents (with `## Glossary` section in `_index.md` recording canonical labels)

## Integrated QA (Evaluator Mode, mandatory)

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
