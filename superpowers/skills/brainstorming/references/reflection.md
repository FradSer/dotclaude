# Phase 4: Design Reflection - Detailed Guidance

## Goal

Use parallel sub-agents to systematically review design documents and identify gaps, inconsistencies, and missing considerations before committing.

## Why Use Sub-Agents for Reflection

Sub-agents provide:
- **Fresh perspective** - No bias from having written the documents
- **Parallel execution** - Multiple review aspects simultaneously
- **Specialized focus** - Each agent focuses on one aspect deeply
- **Objective analysis** - Independent assessment without context attachment

## Sub-Agent Launch Strategy

### Core Reflection Sub-Agents (Always Required)

Launch these three sub-agents in parallel using the Agent tool with `subagent_type=general-purpose`:

**Sub-agent 1: Requirements Traceability Review**

```
You are reviewing design documents for requirements coverage.

Context: [Provide Phase 1 requirements summary]

Your task:
1. Read all design documents in docs/plans/YYYY-MM-DD-<topic>-design/
2. Create a traceability matrix mapping each Phase 1 requirement to where it's addressed
3. Identify any orphaned requirements (not addressed anywhere)
4. Identify any implementation details without corresponding requirements

Output format:
- Requirements Traceability Matrix (requirement → document → section)
- Orphaned Requirements List (requirements not addressed)
- Scope Creep List (implementation without requirements)
```

**Sub-agent 2: BDD Completeness Review**

```
You are reviewing BDD specifications for completeness.

Context: [Provide feature summary]

Your task:
1. Read bdd-specs.md in docs/plans/YYYY-MM-DD-<topic>-design/
2. Categorize all scenarios as: happy path, error path, or edge case
3. Identify missing scenarios for each category
4. Check that each scenario has complete Given-When-Then structure

Output format:
- Scenario Coverage Summary (count by category)
- Missing Happy Path Scenarios
- Missing Error Path Scenarios (validation, auth, external failures, timeouts)
- Missing Edge Case Scenarios (boundaries, empty states, concurrency)
- Incomplete Scenarios (missing Gherkin structure)
```

**Sub-agent 3: Cross-Document Consistency Review**

```
You are reviewing design documents for consistency.

Your task:
1. Read all design documents in docs/plans/YYYY-MM-DD-<topic>-design/
2. Build a terminology glossary from all documents
3. Identify terminology inconsistencies (same concept, different terms)
4. Verify cross-references between documents work
5. Check component/file names are consistent across documents

Output format:
- Terminology Glossary (term → definition → source document)
- Inconsistencies Found (term variations, conflicting definitions)
- Broken Cross-References (links that don't resolve)
- Naming Inconsistencies (component/file name variations)
```

### Additional Reflection Sub-Agents (Launch as Needed)

**Security Review Sub-agent** (for features with security implications):

```
You are reviewing design documents for security considerations.

Context: [Provide feature summary and threat context]

Your task:
1. Read all design documents in docs/plans/YYYY-MM-DD-<topic>-design/
2. Identify security-relevant components and data flows
3. Check for documented threat model and mitigations
4. Identify potential vulnerabilities not addressed

Output format:
- Security-Relevant Components
- Threat Model Coverage (what's addressed vs missing)
- Unaddressed Security Concerns
- Recommendations
```

**Risk Assessment Sub-agent** (for complex or high-stakes features):

```
You are reviewing design documents for risks and assumptions.

Context: [Provide feature summary and constraints]

Your task:
1. Read all design documents in docs/plans/YYYY-MM-DD-<topic>-design/
2. List all explicit assumptions found
3. Identify implicit assumptions (things assumed but not stated)
4. Identify technical, integration, and implementation risks
5. Check if risks have documented mitigations

Output format:
- Explicit Assumptions List
- Implicit Assumptions List (things taken for granted)
- Technical Risks (complexity, performance, scalability)
- Integration Risks (dependencies, APIs, data migration)
- Implementation Risks (new code, changes to existing code, infrastructure)
- Risks Without Mitigations
```

## Integration Workflow

### 1. Collect Sub-Agent Results

Use TaskOutput tool to retrieve results from all launched sub-agents.

### 2. Synthesize Findings

Merge findings into a unified gap list:

| Category | Finding | Priority | Document to Update |
|----------|---------|----------|-------------------|
| Orphaned requirement | "X not addressed" | High | _index.md |
| Missing scenario | "Error case Y" | High | bdd-specs.md |
| Inconsistency | "Term Z varies" | Medium | All |
| Unaddressed risk | "Dependency W" | Medium | best-practices.md |

### 3. Prioritize Gaps

**High Priority** (must fix before commit):
- Orphaned requirements
- Missing happy path scenarios
- Security vulnerabilities
- Critical risks without mitigation

**Medium Priority** (should fix):
- Missing error/edge case scenarios
- Terminology inconsistencies
- Broken cross-references
- Implicit assumptions

**Low Priority** (nice to have):
- Additional documentation
- Diagrams
- Examples

### 4. Update Documents

Based on prioritized gap list:

1. **Fill gaps** - Add missing sections, scenarios, or details
2. **Clarify ambiguities** - Make implicit things explicit
3. **Document assumptions** - State what was assumed
4. **Add risk mitigations** - Address identified risks
5. **Fix inconsistencies** - Align terminology and references

### 5. Re-Verify Updated Sections

For significant updates, consider launching a quick verification sub-agent:

```
You are verifying that specific gaps have been addressed.

Gaps that were identified:
[List the specific gaps that were fixed]

Your task:
1. Read the updated sections in docs/plans/YYYY-MM-DD-<topic>-design/
2. Verify each gap is now addressed
3. Report any gaps that remain

Output format:
- Verification Results (gap → addressed: yes/no)
- Remaining Issues
```

## Output

- Updated design documents with gaps filled
- All Phase 1 requirements traced to implementation
- Complete BDD scenario coverage
- Consistent terminology across documents
- Documented assumptions and mitigations

## Anti-Patterns to Avoid

- **Skipping reflection** - "It looks fine, let's just commit"
- **Single-agent reflection** - Not leveraging parallel sub-agents
- **Ignoring sub-agent findings** - Not acting on identified gaps
- **Superficial fixes** - Adding content without proper integration
- **Inconsistent fixes** - Fixing in one document but not others
