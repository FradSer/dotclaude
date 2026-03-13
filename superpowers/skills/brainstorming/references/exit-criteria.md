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

## After Phase 3: Design Creation
Before proceeding to Phase 4 (Reflection), verify:

- [ ] **Core sub-agents completed**
  - Architecture Research sub-agent completed with recommendations
  - Best Practices Research sub-agent completed with BDD scenarios
  - Context & Requirements Synthesis sub-agent completed with requirements

- [ ] **Additional sub-agents completed (if launched)**
  - Each additional sub-agent completed successfully
  - All specialized research incorporated into design

- [ ] **Results integrated successfully**
  - Conflicts between sub-agent findings resolved
  - Consistent unified design document created
  - All findings incorporated into design

- [ ] **Design document structure created**
  - Folder pattern: `docs/plans/YYYY-MM-DD-<topic>-design/`
  - `_index.md` created with Context, Requirements, Rationale, Detailed Design
  - `bdd-specs.md` created with BDD scenarios
  - `architecture.md` created with architecture details
  - `best-practices.md` created with best practices and considerations

- [ ] **Design documents include required sections**
  - Context and discovery results
  - Finalized requirements and success criteria
  - Rationale for chosen approach
  - Detailed component breakdown
  - BDD specifications with Given-When-Then scenarios
  - Architecture patterns and integration points
  - Best practices and considerations
  - Error handling and edge cases
  - Testing strategy

- [ ] **Design grounded in codebase reality**
  - References specific files and patterns throughout
  - Shows concrete examples and interfaces
  - Aligns with project's architectural style

## After Phase 4: Design Reflection
Before proceeding to Phase 5 (Git Commit), verify:

- [ ] **Core reflection sub-agents launched and completed**
  - Requirements Traceability Review sub-agent completed
  - BDD Completeness Review sub-agent completed
  - Cross-Document Consistency Review sub-agent completed

- [ ] **Additional reflection sub-agents completed (if launched)**
  - Security Review sub-agent completed (if applicable)
  - Risk Assessment sub-agent completed (if applicable)

- [ ] **Findings synthesized and prioritized**
  - All sub-agent outputs collected via TaskOutput
  - Findings merged into unified gap list
  - Gaps prioritized by impact (High/Medium/Low)

- [ ] **Requirements traceability verified**
  - Every Phase 1 requirement is addressed in design
  - Requirements are traced to specific sections
  - No orphaned requirements without implementation

- [ ] **Gaps identified and filled**
  - Error handling paths documented
  - Edge cases covered in BDD scenarios
  - Integration points clearly defined
  - Non-functional requirements addressed

- [ ] **Cross-document consistency verified**
  - Terminology consistent across all documents
  - Cross-references between documents work
  - Component and file names consistent

- [ ] **BDD scenario completeness verified**
  - Happy path scenarios covered
  - Error path scenarios covered
  - Edge case scenarios covered
  - Testing strategy is clear

- [ ] **Documents updated based on findings**
  - High priority gaps addressed
  - Gaps filled with new content
  - Ambiguities clarified
  - Inconsistencies fixed

## After Phase 5: Git Commit
Before proceeding to Phase 6, verify:

- [ ] **Entire folder committed**
  - Used `git add docs/plans/YYYY-MM-DD-<topic>-design/`
  - NOT just individual files
  - Folder pattern matches requirements

- [ ] **Commit message follows requirements**
  - Prefix: `docs:` (lowercase)
  - Subject: Under 50 characters, lowercase
  - Body: User context, specific actions, design summary
  - Footer: Co-Authored-By with model name

- [ ] **Commit verified**
  - Ran `git log -1` to confirm commit
  - Commit message displays correctly
  - All files included in commit

- [ ] **User informed**
  - Told user the folder and file location
  - Confirmed git commit completed
  - Ready to proceed with implementation planning

## Success Indicators

**High Quality Brainstorming Session**:
- Explored codebase before asking questions
- Asked focused questions one at a time based on exploration gaps
- Proposed options grounded in existing patterns
- Got user buy-in before creating detailed design
- Launched core sub-agents in parallel for design creation
- Launched additional sub-agents as needed for specialized research
- Integrated all sub-agent results successfully
- Launched reflection sub-agents in parallel for gap identification
- Synthesized and prioritized reflection findings
- Updated design documents based on reflection findings
- Design document is comprehensive and actionable with BDD scenarios
- Saved design files with proper structure inside dated folder
- Committed design folder as checkpoint before implementation

**Common Pitfalls to Avoid**:
- Asking questions without exploring codebase first
- Asking multiple questions at once (always ask one at a time)
- Proposing abstract options not grounded in reality
- Creating design without user approval of approach
- Skipping alternatives without clear rationale
- Launching sub-agents without providing complete context
- Not integrating sub-agent results before creating documents
- Launching too many sub-agents for simple features (stay focused)
- Skipping reflection phase - "it looks fine, let's just commit"
- Single-agent reflection - not leveraging parallel sub-agents
- Ignoring sub-agent findings - not acting on identified gaps
- Superficial fixes - adding content without proper integration
- Missing BDD specifications or best practices sections
- Saving design to wrong location (should be `docs/plans/YYYY-MM-DD-<topic>-design/`)
- Committing individual files instead of entire folder
- Jumping to implementation without committing design
