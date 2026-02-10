# Phase 3: Design & Commit - Detailed Guidance

## Goal

Create comprehensive design documents (split into multiple files) with BDD specifications, save to folder, and commit to git.

## Actions

### 1. Create Design Document

Draft complete design documents, splitting content into logical files (e.g., `_index.md`, `architecture.md`, `api.md`).

**Required Structure**:

- **MANDATORY**: BDD specifications MUST be in a separate file named `bdd-specs.md`.
- Main content in `_index.md`.
- Other details in supporting files.

#### Context and Discovery (New Requirement)
The `_index.md` must now include:
- **Context**: The user's original request and the Q&A history that led to this design.
- **Discovery Results**: What was found during the exploration phase.
- **Requirements**: The finalized requirements.
- **Rationale**: Why this design was chosen.

#### BDD Specifications

**CRITICAL**: Every design MUST include BDD scenarios in a **separate file named `bdd-specs.md`**.

Load `superpowers:behavior-driven-development` skill using Skill tool for comprehensive BDD guidance.

**BDD Format**:

```gherkin
Feature: [Feature name from design]

  Scenario: [Primary happy path]
    Given [initial context/state]
    When [action/event occurs]
    Then [expected outcome]
    And [additional assertions]
```

**BDD Coverage Requirements**:
- At least 3 scenarios per feature
- Cover happy path, edge cases, and error conditions

#### Advanced Gherkin Syntax

**Scenario Outline (Data-Driven Tests)**
Use when testing the same logic with different inputs.

```gherkin
Scenario Outline: Login validation
  Given the login page is open
  When user enters "<username>" and "<password>"
  Then the system should show error "<error_message>"

  Examples:
    | username | password | error_message      |
    |          | 123456   | Username required  |
    | alice    |          | Password required  |
    | bob      | wrong    | Invalid credentials|
```

**Background (Shared Setup)**
Use to avoid repeating `Given` steps in every scenario.

```gherkin
Feature: Admin Dashboard

  Background:
    Given the database is seeded
    And an admin user "admin@test.com" exists
    And the admin is logged in

  Scenario: View users
    When ...
  
  Scenario: Delete user
    When ...
```

### 3. Save Design Document

**CRITICAL: You MUST follow this exact folder structure**

**Required Folder Pattern**: `docs/plans/YYYY-MM-DD-<topic>-design/`

**Enhanced Structure** (recommended):
```
docs/plans/YYYY-MM-DD-<topic>-design/
├── _index.md            # Main design document (MANDATORY)
├── bdd-specs.md         # BDD specifications (MANDATORY)
├── architecture.md      # Architecture details (optional)
├── decisions/           # Related ADRs (optional)
│   └── 0001-*.md
└── diagrams/            # Visual artifacts (optional)
    ├── sequence.png
    └── architecture.mmd
```

**Folder Naming Rules**:
- Use `YYYY-MM-DD` date prefix for chronological ordering
- Use kebab-case for topic name (lowercase with hyphens)
- Example: `2024-02-10-user-auth-design/`

**Required Main Document**: `docs/plans/YYYY-MM-DD-<topic>-design/_index.md`
- The main design document MUST be named `_index.md`.
- You MUST split the design into multiple files for maintainability.

### 4. Commit Design to Git

**CRITICAL: You MUST commit the entire folder, not just _index.md**

**Commit Pattern**:
```bash
git add docs/plans/YYYY-MM-DD-<topic>-design/
git commit -m "docs: add design for <topic>
```

**Commit Message Requirements**:
- Prefix: `docs:` (lowercase)
- Subject: Short description under 50 characters, lowercase
- Body:
    - User's original request or context
    - Specific actions taken (list)
    - Brief summary of the design approach
- Footer: `Co-Authored-By: <Model Name> <noreply@anthropic.com>`

**Example**:
```bash
git commit -m "docs: add design for user authentication

Request: Implement JWT auth for API.

- Explored existing auth in /admin
- Proposed JWT vs Session
- Selected JWT for scalability

Summary: Implements stateless JWT auth using the existing library.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

### 5. Inform User

Tell the user:
- Design folder and main document location
- Git commit completed
- Ready to proceed with implementation following BDD scenarios
- Note that supporting files can be added to the folder later if needed

## Output

- Design folder created at `docs/plans/YYYY-MM-DD-<topic>-design/`
- Main design document `_index.md` (with context, discovery, requirements)
- **MANDATORY**: Separate `bdd-specs.md` file with BDD scenarios
- Other supporting files (`architecture.md`, etc.)
- Design folder committed to git with proper message
- User informed and ready for implementation

## Best Practices

**Co-locate related documents** within each design folder for easy navigation:
- Main design in `_index.md`
- BDD specifications in `bdd-specs.md`
- Architecture details in `architecture.md`
- Related ADRs in `decisions/` subfolder
- Visual artifacts in `diagrams/` subfolder

**Folder naming conventions**:
- Use `YYYY-MM-DD` date prefix for chronological ordering
- Use kebab-case for topic name (lowercase with hyphens)
- Example: `2024-02-10-user-auth-design/`
