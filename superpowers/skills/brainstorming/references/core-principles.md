# Core Principles

These principles guide the entire brainstorming workflow:

## Converge in Order

Follow the structured progression:
1. Clarify constraints through exploration and questions
2. Compare options with trade-offs
3. Choose intentionally with user approval
4. Create design document using parallel sub-agents with BDD specifications
5. Commit design to git
6. Transition to implementation planning

## Incremental Validation

Validate each phase before proceeding:
- Phase 1: Ensure requirements are clear before analyzing options
- Phase 2: Get user approval on approach before creating design
- Phase 3: Complete design with BDD specs using sub-agents before committing
- Phase 4: Verify git commit before transitioning to implementation

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
**Phase 3**: Parallel sub-agents (Architecture, Best Practices, Context) → Integrate → Save
**Phase 4**: Git commit → Verify
**Phase 5**: Transition to writing-plans

Each phase builds on the previous, creating a complete design document ready for implementation planning.
