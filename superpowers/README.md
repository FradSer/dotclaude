# Superpowers Plugin

Advanced development superpowers for orchestrating complex workflows from idea to execution.

## Overview

The superpowers plugin provides a comprehensive framework for collaborative software development, enabling teams to move from rough ideas through structured planning to coordinated execution. It combines strategic planning tools with behavior-driven development practices.

## User-Invocable Skills

### Brainstorming

**Command:** `/superpowers:brainstorming`

Turn rough ideas into implementation-ready designs through structured collaborative dialogue. This skill:

- Clarifies ambiguous requirements through focused questioning
- Explores design alternatives grounded in codebase reality
- Produces design documents with BDD specifications (Given-When-Then)
- Prepares the project for planning and implementation

**Workflow:** Discovery → Option Analysis → Design & Commit → Transition to Writing Plans

**Output:** Design folder with `_index.md` and `bdd-specs.md` ready for planning

---

### Writing Plans

**Command:** `/superpowers:writing-plans [design-folder-path]`

Create executable implementation plans that reduce ambiguity for execution. This skill:

- Decomposes designs into granular, testable tasks
- Maps each task to specific BDD scenarios
- Enforces Test-First (Red-Green) ordering
- Ensures compatibility with behavior-driven development practices

**Prerequisites:** Output from `brainstorming` skill (design folder with `bdd-specs.md`)

**Output:** Plan folder with `_index.md` and task files ready for execution

---

### Executing Plans

**Command:** `/superpowers:executing-plans [plan-folder-path]`

Execute written implementation plans in predictable batches. This skill:

- Validates plans before execution begins
- Supports both serial (single agent) and parallel (Agent Team) execution
- Tracks task completion and captures evidence
- Provides closure and verification loops

**Prerequisites:** Output from `writing-plans` skill (plan folder with `_index.md`)

**Modes:**
- **Serial Execution:** Single agent executes tasks sequentially
- **Parallel Execution:** Coordinates an Agent Team for independent tasks

**Output:** Executed tasks with verification evidence and completion confirmation

---

## Internal Skills (Loaded Automatically)

### Behavior-Driven Development

**Loaded when:** Implementing features or bugfixes during execution

This skill enforces the Red-Green-Refactor cycle:

1. **Red Phase:** Write a failing test that proves the absence of the feature
2. **Green Phase:** Write minimal code to make the test pass
3. **Refactor Phase:** Clean up code while keeping tests green

All phases are driven by BDD scenarios in Gherkin format (Given-When-Then).

---

### Agent Team Driven Development

**Loaded when:** Orchestrating complex multi-step tasks across specialized agents

This skill provides guidance on:

- Creating and managing Agent Teams with specialized roles:
  - **Implementer:** Focuses on BDD, testing, and isolated implementation
  - **Reviewer:** Focuses on spec compliance and strict code quality
  - **Architect:** Focuses on high-level design and breaking down complex plans
- Coordinating work across multiple agents
- Monitoring progress and integrating results

---

## End-to-End Workflow

### From Idea to Shipped Code

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

---

## Core Principles

- **Test-First:** Every implementation starts with a failing test
- **Explicit over Implicit:** Tasks are detailed and context-independent
- **Collaborative:** Built on structured dialogue and user approval
- **Incremental:** Validate each phase before proceeding
- **Verification-Driven:** Every task includes verification steps
- **BDD-Centric:** All specifications use Given-When-Then format
- **Team-Aware:** Supports both solo and parallel Agent Team execution

---

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
│   │   ├── roles/               # Role descriptions (Implementer, Reviewer, Architect)
│   │   └── workflows/           # Team workflows (initiate, manage)
│   └── behavior-driven-development/
│       ├── SKILL.md             # BDD cycle guidance
│       └── references/          # Gherkin reference, phase guides, anti-patterns
└── README.md                    # This file
```

---

## Documentation

Each skill includes detailed references:

- **Brainstorming References:**
  - `core-principles.md` — Converge in Order, Context First, Incremental Validation
  - `phase1-discovery.md` — Exploration patterns and question guidelines
  - `phase2-option-analysis.md` — Presenting options and trade-offs
  - `phase3-design-commit.md` — Design structure, BDD format, git integration
  - `exit-criteria.md` — Success checklists for each phase

- **Writing Plans References:**
  - `plan-structure-template.md` — Template for plan structure
  - `task-granularity-and-verification.md` — Task breakdown and verification patterns

- **Executing Plans References:**
  - `blocker-and-escalation.md` — Identifying and handling execution blockers
  - `batch-execution-playbook.md` — Serial and parallel execution patterns

- **Behavior-Driven Development References:**
  - `cucumber-gherkin-reference.md` — Complete Gherkin syntax guide
  - `red-phase-guide.md` — Writing failing tests
  - `green-phase-guide.md` — Implementing minimal code
  - `refactor-phase-guide.md` — Cleaning up code while keeping tests green
  - `test-design-patterns.md` — Common BDD test patterns
  - `anti-patterns-and-rationalizations.md` — Common mistakes to avoid
  - `verification-checklist.md` — BDD verification checklist
  - `testing-anti-patterns.md` — Testing anti-patterns (mocks vs real behavior)

- **Agent Team Driven Development References:**
  - `roles/implementer.md` — Implementer role guidance
  - `roles/reviewer.md` — Reviewer role guidance
  - `roles/architect.md` — Architect role guidance
  - `workflows/initiate-team.md` — Starting a team
  - `workflows/manage-team.md` — Assigning tasks and monitoring progress

---

## Getting Started

### For Planning

1. Have a rough idea or feature request
2. Run `/superpowers:brainstorming` to clarify and design
3. Use the output as input to `/superpowers:writing-plans`

### For Implementation

1. Have a plan folder from the writing-plans skill
2. Run `/superpowers:executing-plans [plan-folder-path]`
3. Choose serial or parallel execution based on task dependencies

### For Code Review

1. During execution, the Reviewer agent checks for spec compliance
2. Review suggestions are provided before merging

---

## Integration with Claude Code

This plugin integrates with Claude Code's native features:

- **Skill Tool:** Load skills dynamically during workflows
- **Task Management:** Create and track tasks during execution
- **Agent Teams:** Spawn specialized agents for parallel work
- **Git Integration:** Automatic commit messages with proper attribution

---

## Version

Plugin Version: 1.4.0

Individual skill versions:
- brainstorming: 2.1.0
- writing-plans: 1.3.0
- executing-plans: 1.5.0
- behavior-driven-development: 3.0.0
- agent-team-driven-development: 2.3.0
- systematic-debugging: 1.0.0
- build-like-iphone-team: 1.0.0

---

## Author

Frad LEE (fradser@gmail.com)
