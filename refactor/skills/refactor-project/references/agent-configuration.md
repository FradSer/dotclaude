# Agent Configuration for Project-Wide Refactoring

## Task Tool Invocation

### Required Parameters

```
Task tool parameters:
  subagent_type: "refactor:code-simplifier"
  description: "Refactor entire project with cross-file optimization"
  prompt: <detailed context below>
```

### Prompt Context Structure

Pass the following information to the agent:

```
Refactor the entire project with aggressive cleanup and cross-file optimization.

Project Scope: <total file count> files across <language count> languages

Target Files:
<organized list of files by directory or language>

Project-Wide Mode: Emphasize duplication reduction across files and consistent patterns project-wide.

Cross-File Optimization Focus:
- Identify and consolidate duplicate utilities across files
- Standardize naming conventions project-wide
- Ensure consistent error handling patterns
- Apply uniform code style and structure

Aggressive Mode: Remove legacy code, unused exports, backwards-compatibility hacks, and rename improperly named variables.

Frameworks Detected: <list of frameworks>
```

### Example Invocation

```
Refactor the entire project with aggressive cleanup and cross-file optimization.

Project Scope: 65 files across 2 languages

Target Files:
TypeScript (45 files):
  src/components/: Button.tsx, Input.tsx, Modal.tsx, ...
  src/services/: auth.ts, api.ts, user.ts, ...
  src/utils/: validation.ts, formatting.ts, ...
  tests/: auth.test.ts, user.test.ts, ...

Python (12 files):
  scripts/: build.py, deploy.py, validate.py, ...

Project-Wide Mode: Emphasize duplication reduction across files and consistent patterns project-wide.

Cross-File Optimization Focus:
- Identify and consolidate duplicate utilities across files
- Standardize naming conventions project-wide
- Ensure consistent error handling patterns
- Apply uniform code style and structure

Aggressive Mode: Remove legacy code, unused exports, backwards-compatibility hacks, and rename improperly named variables.

Frameworks Detected: Next.js, React
```

## Agent Internal Workflow

The code-simplifier agent executes the following workflow for project-wide refactoring:

### 1. Load Best Practices Skill

```
Load refactor:best-practices skill using Skill tool
```

Provides same references as file-level refactoring:
- Language-specific rules
- Framework detection and optimization patterns
- Universal code quality principles

### 2. Analyze Entire Codebase

**Two-Pass Analysis**:

**Pass 1: Individual File Analysis**
- Detect language and framework for each file
- Identify code quality issues per file
- Track patterns and naming conventions

**Pass 2: Cross-File Pattern Detection**
- Identify duplicate utility functions across files
- Find inconsistent naming patterns for similar concepts
- Detect scattered implementations that could be consolidated
- Note style inconsistencies

### 3. Apply Refactoring

**Individual File Improvements** (same as file-level):
- Remove unused imports, exports, variables
- Simplify complex logic
- Apply language-specific best practices
- Framework-specific optimizations

**Cross-File Improvements** (project-wide specific):

**Duplication Consolidation**:
```typescript
// Before: Duplicate formatting in 3 files
// src/utils/auth.ts
const formatDate = (date) => { /* impl */ }

// src/utils/user.ts
const formatDate = (date) => { /* impl */ }

// After: Single shared utility
// src/utils/date.ts
export const formatDate = (date) => { /* impl */ }

// Updated imports in auth.ts and user.ts
import { formatDate } from './date'
```

**Naming Standardization**:
```typescript
// Before: Inconsistent naming
// file1.ts: getUserInfo()
// file2.ts: fetchUserData()
// file3.ts: loadUserDetails()

// After: Consistent naming
// All files: getUserData()
```

**Pattern Consistency**:
```typescript
// Before: Inconsistent error handling
// file1.ts: throw new Error()
// file2.ts: console.error() + return null
// file3.ts: try-catch with recovery

// After: Consistent approach based on context
// Services: throw errors (caller handles)
// UI: try-catch with user-friendly messages
```

### 4. Validate Changes

**Project-Wide Validation**:
- Suggest running full test suite
- Recommend smoke tests for critical paths
- Note areas requiring manual verification

**Incremental Review Suggestions**:
- Group changes by feature area for review
- Suggest reviewing cross-file changes first
- Recommend checking public API stability

### 5. Generate Summary

Track changes across two dimensions:
1. **Per-file changes** - What improved in individual files
2. **Cross-file changes** - What improved project-wide

See `output-requirements.md` for complete summary structure.

## Best Practices Skill Integration

### Same Loading Mechanism

Project-wide refactoring uses the same best-practices skill as file-level refactoring.

### Extended Application

**Cross-File Context**:
- Agent applies rules with awareness of entire project
- Identifies violations of DRY principle across files
- Detects inconsistent application of patterns

**Example - Consistent Import Patterns**:
```typescript
// Before: Mixed import styles
// file1.ts: import React from 'react'
// file2.ts: import * as React from 'react'

// After: Standardized (based on project's tsconfig)
// All files: import React from 'react'
```

## Model and Performance Considerations

### Model Configuration

```yaml
model: opus  # Required for cross-file reasoning
```

Project-wide refactoring requires Opus for:
- Cross-file pattern recognition
- Consistency analysis across large codebases
- Complex duplication detection

### Allowed Tools

```yaml
allowed-tools:
  - Read       # Read all target files
  - Edit       # Apply refactoring changes
  - Glob       # Discover files and patterns
  - Grep       # Search for patterns project-wide
  - Bash(git:*)  # Git status, diff for context
  - Skill      # Load best-practices
```

**Same restrictions as file-level**:
- No Write tool (use Edit for surgical changes)
- Restricted Bash (only git commands)

### Performance Optimization

**Batching Strategy**:
- Agent may process files in logical groups
- Related files (same directory/feature) processed together
- Maintains context across related changes

**Progress Indication**:
Agent should provide progress updates for large projects:
```
Analyzing files... (1/3 - TypeScript source)
Analyzing files... (2/3 - Python scripts)
Analyzing files... (3/3 - Test files)

Applying refactoring... (components)
Applying refactoring... (services)
...
```

## Safety and Rollback

### Git Integration

**Pre-Refactoring**:
- Agent checks git status for context
- Notes current branch

**Post-Refactoring**:
- Provides rollback command: `git reset --hard HEAD`
- Recommends creating a backup branch if not already on feature branch

### Rollback Instructions

Include in summary:

```
### Rollback

If needed, revert all project-wide changes:

git reset --hard HEAD

Or create a backup first:
git branch backup-before-refactor
git reset --hard HEAD
```
