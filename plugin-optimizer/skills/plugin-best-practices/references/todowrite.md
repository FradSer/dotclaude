# TodoWrite Tool Usage Standards

Complete guide to using the TodoWrite tool effectively in Claude Code plugins.

## 6. TodoWrite Tool Usage Standards

**When to Use TodoWrite:**

- **3+ Distinct Steps:** Only create todo lists for tasks with 3 or more distinct, meaningful steps
- **Complex Multi-Component Work:** Plugin development involving multiple files (commands + agents + skills)
- **Sequential Dependencies:** When later steps depend on earlier step completion
- **User Visibility:** When users need to track progress of multi-step operations

**Must Do**

- **Dual Form Naming:** Every task requires both `content` (imperative: "Run tests") and `activeForm` (continuous: "Running tests")
- **Real-time Updates:** Mark tasks `in_progress` BEFORE starting work, `completed` IMMEDIATELY after finishing
- **Single Active Task:** Maintain exactly ONE task as `in_progress` at any time
- **Honest Status:** NEVER mark incomplete tasks as `completed` - if blocked or failed, keep as `in_progress` and create new task for resolution

**When NOT to Use TodoWrite:**

- **Simple Tasks:** Single-file edits, trivial changes, 1-2 step operations
- **Research Only:** Pure exploration, reading files, searching codebase
- **Conversational:** Answering questions, explaining concepts

## Task Structure

Every task must have:

```json
{
  "content": "Imperative form - what needs to be done",
  "activeForm": "Present continuous - what is being done",
  "status": "pending|in_progress|completed"
}
```

### Content Field (Imperative)

Use verb-first, command form:

**Good examples:**
- "Create plugin manifest and directory structure"
- "Implement command with frontmatter and validation"
- "Run tests and fix any failures"
- "Generate optimization report"

**Bad examples:**
- "I will create the plugin manifest" (first person)
- "Plugin manifest creation" (noun form)
- "Creating plugin manifest" (continuous form - use in activeForm)

### ActiveForm Field (Present Continuous)

Use "-ing" form to show ongoing work:

**Good examples:**
- "Creating plugin manifest and directory structure"
- "Implementing command with frontmatter and validation"
- "Running tests and fixing failures"
- "Generating optimization report"

**Bad examples:**
- "Create plugin manifest" (imperative - use in content)
- "Plugin manifest creation in progress" (wordy)
- "Will create manifest" (future tense)

## Task Status Management

### pending

Task hasn't started yet:
```json
{
  "content": "Validate all frontmatter fields",
  "activeForm": "Validating all frontmatter fields",
  "status": "pending"
}
```

### in_progress

Currently working on this task:
```json
{
  "content": "Validate all frontmatter fields",
  "activeForm": "Validating all frontmatter fields",
  "status": "in_progress"
}
```

**Critical:** Only ONE task should be `in_progress` at a time.

### completed

Task finished successfully:
```json
{
  "content": "Validate all frontmatter fields",
  "activeForm": "Validating all frontmatter fields",
  "status": "completed"
}
```

**Critical:** Only mark as `completed` when FULLY accomplished.

## Workflow Patterns

### Starting Work

```json
// Before starting
[
  {"content": "Task 1", "activeForm": "Doing task 1", "status": "in_progress"},
  {"content": "Task 2", "activeForm": "Doing task 2", "status": "pending"}
]
```

### Completing Task

```json
// Immediately after finishing Task 1
[
  {"content": "Task 1", "activeForm": "Doing task 1", "status": "completed"},
  {"content": "Task 2", "activeForm": "Doing task 2", "status": "in_progress"}
]
```

### Handling Blockers

If blocked, keep task as `in_progress` and create new task:

```json
[
  {"content": "Run tests", "activeForm": "Running tests", "status": "in_progress"},
  {"content": "Fix failing test in auth.js", "activeForm": "Fixing failing test", "status": "pending"}
]

// After addressing blocker
[
  {"content": "Run tests", "activeForm": "Running tests", "status": "completed"},
  {"content": "Fix failing test in auth.js", "activeForm": "Fixing failing test", "status": "completed"}
]
```

## Example: Plugin Creation (USE TodoWrite)

This requires 3+ steps with dependencies:

```json
[
  {
    "content": "Create plugin manifest and directory structure",
    "activeForm": "Creating plugin manifest and directory structure",
    "status": "in_progress"
  },
  {
    "content": "Implement command with frontmatter and validation",
    "activeForm": "Implementing command with frontmatter and validation",
    "status": "pending"
  },
  {
    "content": "Create agent with triggering examples",
    "activeForm": "Creating agent with triggering examples",
    "status": "pending"
  },
  {
    "content": "Write skill with progressive disclosure",
    "activeForm": "Writing skill with progressive disclosure",
    "status": "pending"
  },
  {
    "content": "Validate plugin with validation scripts",
    "activeForm": "Validating plugin with validation scripts",
    "status": "pending"
  }
]
```

## Example: Single File Edit (DON'T use TodoWrite)

These are too simple for task tracking:

- "Fix typo in README.md" → Just do it
- "Add missing description field" → Just do it
- "Update version number" → Just do it

## Example: Multi-File Refactoring (USE TodoWrite)

```json
[
  {
    "content": "Identify all files using old API",
    "activeForm": "Identifying all files using old API",
    "status": "in_progress"
  },
  {
    "content": "Update auth.js to new API",
    "activeForm": "Updating auth.js to new API",
    "status": "pending"
  },
  {
    "content": "Update database.js to new API",
    "activeForm": "Updating database.js to new API",
    "status": "pending"
  },
  {
    "content": "Run tests and verify changes",
    "activeForm": "Running tests and verifying changes",
    "status": "pending"
  }
]
```

## Best Practices

### 1. Granularity

Break complex tasks into manageable steps:

**Too coarse:**
```json
{"content": "Implement entire plugin", ...}
```

**Too fine:**
```json
{"content": "Write line 1 of command", ...}
{"content": "Write line 2 of command", ...}
```

**Just right:**
```json
{"content": "Implement command with frontmatter", ...}
{"content": "Implement agent with examples", ...}
{"content": "Create skill with references", ...}
```

### 2. Dependencies

Order tasks by dependency:

```json
[
  {"content": "Create plugin structure", ...},  // Do first
  {"content": "Write command file", ...},       // Depends on structure
  {"content": "Test command", ...}              // Depends on command
]
```

### 3. Immediate Updates

Update status IMMEDIATELY after state changes:

```
✅ Good workflow:
1. Start task → Update to in_progress
2. Work on task
3. Finish task → Update to completed IMMEDIATELY
4. Start next task → Update to in_progress

❌ Bad workflow:
1. Start task 1
2. Finish task 1
3. Start task 2
4. Finish task 2
5. Update all tasks at once (too late!)
```

### 4. Honest Status

Never mark incomplete work as complete:

**Bad:**
```json
// Tests are failing but marked complete
{"content": "Run tests", "status": "completed"}
```

**Good:**
```json
// Keep in_progress, add fix task
[
  {"content": "Run tests", "status": "in_progress"},
  {"content": "Fix failing auth test", "status": "pending"}
]
```

### 5. Clear Descriptions

Use specific, actionable descriptions:

**Vague:**
```json
{"content": "Do validation", ...}
{"content": "Fix issues", ...}
```

**Specific:**
```json
{"content": "Validate frontmatter in all component files", ...}
{"content": "Fix missing description fields in agents", ...}
```

## Common Mistakes

### Mistake 1: No ActiveForm

```json
// Bad - Missing activeForm
{"content": "Run tests", "status": "in_progress"}

// Good
{
  "content": "Run tests",
  "activeForm": "Running tests",
  "status": "in_progress"
}
```

### Mistake 2: Multiple In-Progress

```json
// Bad - Two tasks in_progress
[
  {"content": "Task 1", "status": "in_progress"},
  {"content": "Task 2", "status": "in_progress"}
]

// Good - Only one in_progress
[
  {"content": "Task 1", "status": "completed"},
  {"content": "Task 2", "status": "in_progress"}
]
```

### Mistake 3: Batched Updates

```
// Bad - Update all at once at the end
- Do task 1
- Do task 2
- Do task 3
- Update all todos together

// Good - Update after each task
- Start task 1, mark in_progress
- Finish task 1, mark completed
- Start task 2, mark in_progress
- Finish task 2, mark completed
```

### Mistake 4: Wrong Form

```json
// Bad - ActiveForm is imperative
{
  "content": "Run tests",
  "activeForm": "Run tests",
  "status": "in_progress"
}

// Good - ActiveForm is continuous
{
  "content": "Run tests",
  "activeForm": "Running tests",
  "status": "in_progress"
}
```

## Integration with Commands and Agents

### In Commands

Commands can instruct Claude to use TodoWrite:

```markdown
---
description: Multi-step plugin optimization
allowed-tools: [Read, Glob, Grep, TodoWrite, AskUserQuestion]
---

**Use TodoWrite tool** to track the following phases:

1. Scan plugin structure
2. Validate each component type
3. Check tool invocations
4. Generate report
```

### In Agents

Agents should use TodoWrite for complex workflows:

```markdown
You are a plugin optimizer agent.

When analyzing a plugin:

1. **Use TodoWrite tool** at the start to create tasks:
   - Scan structure
   - Validate components
   - Check patterns
   - Generate report

2. Mark each task as in_progress before starting
3. Mark as completed immediately after finishing
4. Maintain exactly one in_progress task at a time
```

## Decision Tree: Should I Use TodoWrite?

```
Is this a multi-step task (3+ steps)?
├─ No → Don't use TodoWrite
└─ Yes → Does it involve multiple files/components?
    ├─ No → Probably don't need TodoWrite
    └─ Yes → Do later steps depend on earlier steps?
        ├─ No → Might not need TodoWrite
        └─ Yes → USE TodoWrite ✅

OR

Does the user need progress visibility?
└─ Yes → USE TodoWrite ✅
```

## Summary

**USE TodoWrite when:**
- 3+ distinct steps
- Multiple files/components
- Sequential dependencies
- User needs progress tracking

**DON'T use TodoWrite when:**
- Simple 1-2 step tasks
- Single file edits
- Pure research/reading
- Conversational responses

**Key requirements:**
- Dual form naming (content + activeForm)
- Real-time updates (immediately after state changes)
- Single active task (exactly one in_progress)
- Honest status (never mark incomplete as complete)
