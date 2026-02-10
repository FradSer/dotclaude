# Phase 3: Design Creation - Detailed Guidance

## Goal

Create comprehensive design documents using parallel sub-agents for research and synthesis.

## Actions

### 1. Launch Sub-agents in Parallel

Use Task tool with `subagent_type=general-purpose` to spawn sub-agents simultaneously.

**CRITICAL**: Provide complete context in each sub-agent prompt. Sub-agents start with fresh context and do not see your conversation history.

## Core Sub-agents (Always Required)

**Sub-agent 1: Architecture Research**

Research existing patterns, architecture, and libraries in the codebase for the chosen approach. Use WebSearch to find latest best practices. Output architecture recommendations with specific files to reference, libraries/frameworks to use or avoid, and codebase patterns to follow.

**Sub-agent 2: Best Practices Research**

Research best practices, security considerations, and performance patterns for the feature. Load `superpowers:behavior-driven-development` skill. Output BDD scenarios in Given-When-Then format, testing strategy recommendations, best practices and considerations, and security/performance notes.

**Sub-agent 3: Context & Requirements Synthesis**

Synthesize Phase 1 discovery results and Phase 2 options into a unified context. Output user's original request, discovery results summary, finalized requirements list, success criteria, and rationale for the chosen approach.

## Additional Sub-agents (Launch as Needed)

Based on project complexity and requirements, launch additional specialized sub-agents for distinct, research-intensive aspects. Each agent should have a single, clear responsibility and receive complete context (Phase 1 and Phase 2 results).

### 2. Wait for All Sub-agents to Complete

Use TaskOutput tool to retrieve results from each sub-agent before proceeding to integration.

### 3. Integrate Results

Review and merge the outputs from all sub-agents:

**Merge Strategy**:

1. Start with the context and requirements from Context & Requirements Synthesis
2. Incorporate architecture recommendations
3. Add BDD scenarios and best practices
4. Include findings from any additional sub-agents
5. Resolve conflicts between sub-agent findings
6. Create a unified design document structure

**Conflict Resolution**:

- If sub-agents disagree on technical approach, favor the codebase patterns
- If sub-agents disagree on best practices, verify with WebSearch
- Document any trade-offs or open questions in the design

### 4. Create Design Document Structure

**File Structure**:

```
docs/plans/YYYY-MM-DD-<topic>-design/
├── _index.md              # Main design document (MANDATORY)
├── bdd-specs.md           # BDD specifications (MANDATORY)
├── architecture.md        # Architecture details (MANDATORY)
├── best-practices.md      # Best practices and considerations (MANDATORY)
├── decisions/             # Related ADRs (optional)
│   └── 0001-*.md
└── diagrams/              # Visual artifacts (optional)
    ├── sequence.png
    └── architecture.mmd
```

**`_index.md` Content Structure**:

```markdown
# Design: <Feature Name>

## Context

User's original request and the Q&A history that led to this design.

## Discovery Results

What was found during the exploration phase.

## Requirements

The finalized requirements and constraints.

## Rationale

Why this design was chosen.

## Detailed Design

Component breakdown, interfaces, and implementation approach.

## Design Documents

- [BDD Specifications](./bdd-specs.md) - Behavior scenarios and testing strategy
- [Architecture](./architecture.md) - System architecture and component details
- [Best Practices](./best-practices.md) - Security, performance, and code quality guidelines
```

**`architecture.md` Content Structure**:

```markdown
# Architecture for <Feature Name>

## System Overview

High-level architecture description.

## Components

Component breakdown with responsibilities.

## Data Structures

Data models and interfaces.

## Integration Points

How this feature integrates with existing systems.

## Technology Choices

Libraries, frameworks, and patterns chosen with rationale.
```

**`bdd-specs.md` Content Structure**:

```markdown
# BDD Specifications for <Feature Name>

## Feature: <Feature Name>

### Scenarios

Given-When-Then scenarios covering:
- Happy path
- Edge cases
- Error conditions

## Testing Strategy

Unit, integration, and E2E testing approach.
```

**`best-practices.md` Content Structure**:

```markdown
# Best Practices for <Feature Name>

## Security Considerations

Security patterns and vulnerabilities to avoid.

## Performance Considerations

Performance patterns and optimizations.

## Code Quality

Coding standards and patterns to follow.

## Common Pitfalls

Anti-patterns and mistakes to avoid.
```

### 5. Save Design Document

**CRITICAL: You MUST follow this exact folder structure**

**Required Folder Pattern**: `docs/plans/YYYY-MM-DD-<topic>-design/`

**Folder Naming Rules**:
- Use `YYYY-MM-DD` date prefix for chronological ordering
- Use kebab-case for topic name (lowercase with hyphens)
- Example: `2024-02-10-user-auth-design/`

**Required Documents**:
- `_index.md` (MANDATORY)
- `bdd-specs.md` (MANDATORY)
- `architecture.md` (MANDATORY)
- `best-practices.md` (MANDATORY)

## Output

- Design folder created at `docs/plans/YYYY-MM-DD-<topic>-design/`
- All design documents saved with proper structure
- **Ready for Phase 4 git commit**

## Best Practices

**Sub-agent Parallelization**:
- Launch all sub-agents simultaneously for maximum efficiency
- Provide complete context in each sub-agent prompt
- Use descriptive sub-agent names for easy identification

**Integration Quality**:
- Review each sub-agent output before integration
- Document any trade-offs or open questions
- Ensure consistency across all design documents

**File Organization**:
- Keep each document focused on its specific purpose
- Use clear section headings
- Include references to specific files and patterns from codebase