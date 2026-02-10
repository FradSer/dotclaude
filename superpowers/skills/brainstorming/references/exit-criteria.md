# Exit Criteria - Complete Checklists

## After Phase 1: Discovery (Primary Agent)
Before proceeding to Phase 2, verify:

- [ ] **Explored codebase thoroughly**
  - Checked relevant files with Read/Glob/Grep
  - Reviewed existing patterns and conventions
  - Examined similar implementations
  - Checked docs/, README.md, CLAUDE.md for context
  - Reviewed recent git commits for development focus

- [ ] **Requirements explicitly clarified**
  - Used AskUserQuestion to fill gaps codebase couldn't answer
  - Asked questions one at a time (not bundled)
  - Preferred multiple choice questions when possible
  - Clarified purpose, constraints, and success criteria

- [ ] **Mental model built**
  - Clear understanding of what's being built
  - Known constraints and non-functional requirements
  - Success criteria defined
  - Relevant existing patterns identified

- [ ] **Ready for option analysis**
  - Have enough context to propose viable approaches
  - Know which existing patterns to follow or adapt
  - Understand trade-offs that matter for this project

## After Phase 2: Option Analysis
Before creating design document, verify:

- [ ] **At least 2 options compared with trade-offs**
  - OR clear "No Alternatives" rationale provided
  - Options grounded in codebase reality, not abstract possibilities
  - Trade-offs explained (complexity, maintainability, performance, etc.)
  - Referenced specific files/patterns from codebase

- [ ] **User approval received**
  - Presented options conversationally (not formal tables)
  - Led with recommended option and reasoning
  - Used AskUserQuestion to confirm chosen approach
  - User explicitly approved the direction

- [ ] **Respected existing architecture**
  - Proposals align with established patterns
  - Use existing libraries and frameworks when possible
  - Follow project's architectural style

- [ ] **Ready to create design document**
  - Have complete context from Phase 1
  - User has approved chosen approach
  - Know which files and patterns to reference

## After Phase 3: Design & Commit
Before marking brainstorming complete, verify design document includes:

- [ ] **Overview and requirements section**
  - Brief summary of what's being built
  - Core requirements and constraints
  - Success criteria

- [ ] **Chosen approach and rationale section**
  - Detailed description of chosen approach
  - Explanation of why it fits the requirements
  - References to existing codebase patterns

- [ ] **Alternative approaches section**
  - Brief summary of alternatives considered
  - Key trade-offs that led to rejection

- [ ] **Detailed design section**
  - Component breakdown with responsibilities
  - Data structures and interfaces
  - Integration points with existing code
  - File structure and organization

- [ ] **BDD specifications section** **MANDATORY**
  - Load `superpowers:behavior-driven-development` skill using Skill tool for guidance
  - At least 3 scenarios in Given-When-Then format
  - Covers happy path, edge cases, and error conditions
  - References specific API endpoints or methods
  - Provides clear acceptance criteria for implementation
  - Follows proper Gherkin syntax

- [ ] **Error handling and edge cases section**
  - Expected error scenarios and handling strategy
  - Edge cases identified and mitigation
  - Recovery and rollback strategies

- [ ] **Testing strategy section**
  - Unit test approach and key test cases
  - Integration test requirements
  - References BDD scenarios from above
  - Manual testing checklist if needed

- [ ] **Open questions or risks section**
  - Unresolved technical decisions
  - Known risks and mitigation plans
  - Dependencies on external systems

- [ ] **Design grounded in existing codebase**
  - References specific files and patterns throughout
  - Shows concrete examples and interfaces
  - Aligns with project's architectural style

**And the document has been saved and committed**:

- [ ] **Design folder and main document created**
  - Created folder `docs/plans/YYYY-MM-DD-<topic>-design/`
  - Saved main design to `docs/plans/YYYY-MM-DD-<topic>-design/_index.md`
  - Used correct date format (YYYY-MM-DD)
  - Ensured `docs/plans/` directory exists

- [ ] **Design folder committed to git**
  - Used `git add docs/plans/YYYY-MM-DD-<topic>-design/`
  - Used `git commit` with proper message
  - Commit message starts with `docs:` prefix
  - Subject line under 50 characters and lowercase
  - Mentioned "BDD specifications" in commit body
  - Included Co-Authored-By line with model name

- [ ] **User informed**
  - Told user the folder and file location
  - Confirmed git commit completed
  - Noted that supporting files can be added to folder later
  - Ready to proceed with implementation following BDD scenarios

## Success Indicators

**High Quality Brainstorming Session**:
- Explored codebase before asking questions
- Asked focused questions one at a time based on exploration gaps
- Proposed options grounded in existing patterns
- Got user buy-in before creating detailed design
- Design document is comprehensive and actionable
- **Design includes BDD specifications with Given-When-Then scenarios**
- Saved design as `_index.md` inside dated folder
- Committed design folder as checkpoint before implementation

**Common Pitfalls to Avoid**:
- Asking questions without exploring codebase first
- Asking multiple questions at once (always ask one at a time)
- Proposing abstract options not grounded in reality
- Creating design without user approval of approach
- Skipping alternatives without clear rationale
- **Missing BDD specifications section**
- Saving design to wrong location (should be `docs/plans/YYYY-MM-DD-<topic>-design/_index.md`)
- Design document missing key sections
- Jumping to implementation without committing design
