# Superpowers Plugin

Advanced development superpowers for orchestrating complex workflows from idea to execution.

**Version**: 1.4.0

## Installation

```bash
claude plugin install superpowers@frad-dotclaude
```

## Overview

The superpowers plugin provides a comprehensive framework for collaborative software development, enabling teams to move from rough ideas through structured planning to coordinated execution. It combines strategic planning tools with behavior-driven development practices.

## User-Invocable Skills

### `/superpowers:brainstorming`

Turn rough ideas into implementation-ready designs through structured collaborative dialogue.

- Clarifies ambiguous requirements through focused questioning
- Explores design alternatives grounded in codebase reality
- Produces design documents with BDD specifications (Given-When-Then)
- Prepares the project for planning and implementation

**Workflow:** Discovery → Option Analysis → Design & Commit → Transition to Writing Plans

**Output:** Design folder with `_index.md` and `bdd-specs.md` ready for planning

### `/superpowers:writing-plans [design-folder-path]`

Create executable implementation plans that reduce ambiguity for execution.

- Decomposes designs into granular, testable tasks
- Maps each task to specific BDD scenarios
- Enforces Test-First (Red-Green) ordering
- Ensures compatibility with behavior-driven development practices

**Prerequisites:** Output from `brainstorming` skill (design folder with `bdd-specs.md`)

**Output:** Plan folder with `_index.md` and task files ready for execution

### `/superpowers:executing-plans [plan-folder-path]`

Execute written implementation plans in predictable batches.

- Validates plans before execution begins
- Supports both serial (single agent) and parallel (Agent Team) execution
- Tracks task completion and captures evidence
- Provides closure and verification loops

**Prerequisites:** Output from `writing-plans` skill (plan folder with `_index.md`)

**Modes:**
- **Serial Execution:** Single agent executes tasks sequentially
- **Parallel Execution:** Coordinates an Agent Team for independent tasks

**Output:** Executed tasks with verification evidence and completion confirmation

## Internal Skills (Loaded Automatically)

### Behavior-Driven Development

Loaded when implementing features or bugfixes during execution. Enforces the Red-Green-Refactor cycle driven by BDD scenarios in Gherkin format (Given-When-Then).

### Agent Team Driven Development

Loaded when orchestrating complex multi-step tasks across specialized agents. Provides guidance on creating and managing Agent Teams with specialized roles:

- **Implementer:** Focuses on BDD, testing, and isolated implementation
- **Reviewer:** Focuses on spec compliance and strict code quality
- **Architect:** Focuses on high-level design and breaking down complex plans

### Systematic Debugging

Loaded when diagnosing bugs or unexpected behavior. Provides a 4-phase methodology: root cause investigation, pattern analysis, hypothesis testing, and implementation.

## End-to-End Workflow

```
1. User has an idea or feature request
   ↓
2. /superpowers:brainstorming
   Clarify requirements, explore options, design solution
   Output: Design folder with BDD specs
   ↓
3. /superpowers:writing-plans [design-folder]
   Break design into testable tasks, map to BDD scenarios
   Output: Plan folder with task definitions
   ↓
4. /superpowers:executing-plans [plan-folder]
   Execute tasks using behavior-driven development
   - Serial: Single agent executes sequentially
   - Parallel: Agent Team with Implementer, Reviewer, Architect
   Output: Implemented, tested, verified code
   ↓
5. Code is merged and shipped
```

## Core Principles

- **Test-First:** Every implementation starts with a failing test
- **Explicit over Implicit:** Tasks are detailed and context-independent
- **Collaborative:** Built on structured dialogue and user approval
- **Incremental:** Validate each phase before proceeding
- **Verification-Driven:** Every task includes verification steps
- **BDD-Centric:** All specifications use Given-When-Then format
- **Team-Aware:** Supports both solo and parallel Agent Team execution

## File Structure

```
superpowers/
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest with skill registration
├── skills/
│   ├── brainstorming/
│   │   ├── SKILL.md             # Skill definition and phases
│   │   └── references/          # Detailed guidance for each phase
│   ├── writing-plans/
│   │   ├── SKILL.md             # Skill definition and phases
│   │   └── references/          # Task decomposition patterns
│   ├── executing-plans/
│   │   ├── SKILL.md             # Skill definition and phases
│   │   └── references/          # Batch execution and blocker handling
│   ├── agent-team-driven-development/
│   │   ├── SKILL.md             # Team orchestration guidance
│   │   ├── roles/               # Role descriptions
│   │   └── workflows/           # Team workflows
│   ├── behavior-driven-development/
│   │   ├── SKILL.md             # BDD cycle guidance
│   │   └── references/          # Gherkin reference, phase guides, anti-patterns
│   └── systematic-debugging/
│       ├── SKILL.md             # Debugging methodology
│       └── references/          # Phase-specific debugging guides
└── README.md
```

## Integration with Claude Code

- **Skill Tool:** Load skills dynamically during workflows
- **Task Management:** Create and track tasks during execution
- **Agent Teams:** Spawn specialized agents for parallel work
- **Git Integration:** Automatic commit messages with proper attribution

## Author

Frad LEE (fradser@gmail.com)

## License

MIT
