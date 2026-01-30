# Scope Determination Advanced Strategies

## Edge Cases and Complex Scenarios

### Mixed Path and Semantic Arguments

When arguments contain both valid paths and semantic descriptions:

```
/refactor src/auth "user validation logic"
```

**Strategy**:
1. Identify valid paths first (`src/auth` exists)
2. Treat remaining arguments as semantic query ("user validation logic")
3. Search within valid path scope if paths are directories
4. Combine path-based and semantic results into single target scope

### Glob Pattern Arguments

When arguments look like glob patterns:

```
/refactor src/**/*.test.ts
```

**Strategy**:
1. Use Glob tool to expand the pattern
2. Treat all matching files as target scope
3. If no matches found, inform user and exit

### Ambiguous Semantic Queries

When semantic query is too broad or returns excessive results:

```
/refactor "utility functions"
```

**Strategy**:
1. Perform initial Grep search with pattern matching
2. If results exceed 50 files, inform user of count
3. Proceed with all results (no arbitrary limits)
4. Suggest more specific query if user wants to narrow scope

### Session Context with Staged Changes

When no arguments provided but git staging area has files:

```bash
git diff --cached --name-only
```

**Strategy**:
1. Prioritize staged changes over unstaged modifications
2. Use staged files as primary target scope
3. Display "Refactoring staged files" for clarity

### Multi-Language Projects

When target scope spans multiple languages:

**Strategy**:
1. Group files by language/framework
2. Inform user of detected languages
3. Proceed with all files; agent handles language detection per-file

## Search Pattern Best Practices

### Effective Grep Patterns for Semantic Queries

**Authentication/Authorization**:
```
(auth|login|session|token|permission|role|access)
```

**API/Routing**:
```
(route|endpoint|api|handler|controller)
```

**Data Access**:
```
(repository|dao|query|database|model)
```

**UI Components**:
```
(component|widget|view|template)
```

### Case Sensitivity

- Use case-insensitive search (`-i` flag) for semantic queries
- Preserve exact casing for technical terms in results

### File Type Filtering

When semantic query targets specific file types:

```
/refactor "test utilities"
```

**Strategy**:
- Use Grep with `--glob` filter for `.test.ts`, `.spec.ts` patterns
- Infer file type from semantic context ("test" → test files)

## Validation and Safety

### Path Existence Checks

Before treating arguments as paths:

```bash
# Use Glob to check existence
Glob: pattern="path/to/check"
```

If Glob returns results → valid path
If Glob returns empty → treat as semantic query

### Repository Root Resolution

All paths should be relative to repository root:

- Verify current working directory is within git repository
- Resolve relative paths from repository root
- Reject paths outside repository boundaries

### Excluded Patterns

Never include in refactoring scope:
- `node_modules/`, `.git/`, `dist/`, `build/`
- Lock files: `package-lock.json`, `pnpm-lock.yaml`, `uv.lock`
- Compiled artifacts: `.min.js`, `.bundle.js`

Use Grep `--glob` exclusions to enforce.
