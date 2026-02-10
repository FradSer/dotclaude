# Core Principles

These principles guide the entire brainstorming workflow:

## Converge in Order

Follow the structured progression:
1. Clarify constraints through exploration and questions
2. Compare options with trade-offs
3. Choose intentionally with user approval
4. Create design document with BDD specifications
5. Commit design before implementation

## Incremental Validation

Validate each phase before proceeding:
- Phase 1: Ensure requirements are clear before analyzing options
- Phase 2: Get user approval on approach before creating design
- Phase 3: Complete design with BDD specs before committing

## YAGNI Ruthlessly

Remove features not required by current constraints. Every feature adds complexity, so only include what's explicitly needed. When in doubt, ask the user rather than assuming scope.

## Context First

Build understanding from existing code and documentation before asking questions. Exploration should reveal most answers - questions should only fill gaps that codebase cannot answer. This respects user time and grounds the design in project reality.

## Test-First Mindset

Always include BDD specifications in the design document. Load `superpowers:behavior-driven-development` skill using Skill tool for comprehensive BDD guidance. Write behavior scenarios before implementation:
- Given (context/preconditions)
- When (action/event)
- Then (expected outcome)

This ensures the design is testable and implementation-ready.

## Workflow Summary

**Phase 1**: Explore → Ask → Understand
**Phase 2**: Research → Propose → Get approval
**Phase 3**: Design with BDD → Save → Commit

Each phase builds on the previous, creating a complete design document ready for implementation.
