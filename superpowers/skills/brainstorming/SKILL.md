---
name: brainstorming
description: This skill should be used when the user has a new idea, feature request, or ambiguous requirement. It clarifies needs, explores options, and produces a solid design document and BDD specs before implementation starts.
user-invocable: true
version: 1.0.0
---

# Brainstorming Ideas Into Designs

Turn rough ideas into implementation-ready designs through structured collaborative dialogue.

## Initialization

1. **Context Check**: Ensure you have read `CLAUDE.md` and `README.md` to understand project constraints.
2. **Codebase Index**: Verify you have access to the codebase and can run searches.

## Background Knowledge

1. **Converge in Order**: Clarify → Compare → Choose → Design → Commit
2. **Context First**: Explore codebase before asking questions
3. **Incremental Validation**: Validate each phase before proceeding to the next
4. **YAGNI Ruthlessly**: Only include what's explicitly needed
5. **Test-First Mindset**: Always include BDD specifications - load `superpowers:behavior-driven-development` skill using Skill tool

See `./references/core-principles.md` for detailed explanations.

## Phase 1: Discovery

**Goal**: Understand what you're building by exploring current state and clarifying requirements.

**Actions**:

1. **Explore codebase first** - Use Read/Grep/Glob to find relevant files and patterns
2. **Review project context** - Check docs/, README.md, CLAUDE.md, recent commits
3. **Identify gaps** - Determine what's unclear from codebase alone
4. **Ask focused questions** - Use AskUserQuestion tool with exactly 1 question per call
   - **Prefer multiple choice** with 2-4 options (A, B, C) to reduce user cognitive load
   - Ask one at a time, never bundle questions
   - Base questions on exploration gaps

**Output**:

- Clear requirements and constraints
- Success criteria defined
- Relevant existing patterns identified

See `./references/phase1-discovery.md` for exploration patterns and question guidelines.

## Phase 2: Option Analysis

**Goal**: Evaluate different approaches and get user buy-in on the chosen direction.

**Actions**:

1. **Research existing patterns** - Search for similar implementations in codebase
2. **Identify viable approaches** - Propose 2-3 options grounded in codebase reality
   - OK to say "No Alternatives" if the path is obvious/constrained, but must explain why
3. **Present conversationally** - Write naturally as if explaining to a colleague (**Do NOT use formal tables**)
   - Lead with recommended option
   - Explain trade-offs (complexity, maintainability, performance)
   - Reference specific files from codebase
4. **Get user approval** - Use AskUserQuestion with exactly 1 question per call
   - Ask one at a time, never bundle questions
   - Continue asking single questions until the approach is fully clear and agreed upon

**Output**:

- User-approved approach with rationale
- Alternatives considered (brief summary)
- Trade-offs and constraints understood

See `./references/phase2-option-analysis.md` for option comparison and presentation patterns.

## Phase 3: Design & Commit

**Goal**: Create comprehensive design document and commit to git.

**Actions**:

1. **Create design document**:
   - Use `_index.md` as the main filename
   - Include: Context, Requirements, Rationale, Detailed Design
   - **MANDATORY**: Include BDD specifications in a separate `bdd-specs.md` file

2. **Write BDD Specifications** (in `bdd-specs.md`):
   - Load `superpowers:behavior-driven-development` skill using Skill tool for guidance
   - At least 3 scenarios in Given-When-Then format (Gherkin syntax)
   - Cover happy path, edge cases, and error conditions
   - Reference specific API endpoints or methods

   **Example Gherkin**:
   ```gherkin
   Feature: User Login
     Scenario: Successful login
       Given a user with email "user@example.com"
       When the user submits valid credentials
       Then they should be redirected to the dashboard
   ```

3. **Save to folder structure**:
   - Folder pattern: `docs/plans/YYYY-MM-DD-<topic>-design/`
   - Use kebab-case for topic name (lowercase with hyphens)
   - **Enhanced structure** (recommended):
     ```
     docs/plans/YYYY-MM-DD-<topic>-design/
     ├── _index.md              # Main design document
     ├── bdd-specs.md           # BDD specifications (MANDATORY)
     ├── architecture.md        # Architecture details
     ├── decisions/             # Related ADRs (optional)
     └── diagrams/              # Visual artifacts (optional)
     ```

3. **Commit to git**:
   ```bash
   git add docs/plans/YYYY-MM-DD-<topic>-design/
   git commit -m "docs: add design for <topic>

   <User's original request or context>

   - <Specific action taken>
   - <Specific action taken>

   <Brief summary of the design approach>

   Co-Authored-By: <Model Name> <noreply@anthropic.com>"
   ```

**Output**:

- Returns: The absolute path to the created design folder.
- Design folder created and committed.
- **Ready for `writing-plans`**: `bdd-specs.md` is now the contract for task planning.

See `./references/phase3-design-commit.md` for design structure, BDD format, file operations, and git commit patterns.

See `./references/exit-criteria.md` for complete checklists and success indicators.

## Phase 4: Transition to Implementation

**Goal**: Prepare the environment and plan for coding.

**Actions**:

1. **Ask**: "Ready to set up for implementation?"
2. **Invoke `superpowers:writing-plans`** using the Skill tool, passing the design folder path as an argument.
   - **REQUIRED**: Create a detailed implementation plan.
   - **PROHIBITED**: Do NOT use platform planning features (e.g., EnterPlanMode, plan mode).
   - **PROHIBITED**: Do NOT start implementing directly - the writing-plans skill comes first.

## References

Detailed guidance for each phase:

- `./references/core-principles.md` - Core principles guiding the workflow
- `./references/phase1-discovery.md` - Exploration patterns and question guidelines
- `./references/phase2-option-analysis.md` - Option comparison and presentation patterns
- `./references/phase3-design-commit.md` - Design structure, BDD format, file operations, git commit
- `./references/exit-criteria.md` - Complete checklists and success indicators
