---
name: refactor
description: Refactor code with code-simplifier
argument-hint: [files-or-directories-or-semantic-query]
allowed-tools: ["Task", "Read", "Write", "Bash(git:*)", "Grep", "Glob"]
user-invocable: true
---

# Refactor Command

Execute fully automated refactoring using the code-simplifier agent. Apply aggressive improvements, remove legacy code, and trust git as the safety net.

## Workflow

### Phase 1: Determine Target Scope

Identify files to refactor based on arguments or session context.

#### When Arguments Are Provided

**Path Validation**:
- Check if arguments are valid file/directory paths relative to the repo root
- Use Glob to verify path existence

**Path-Based Refactoring**:
- If paths exist, treat them as target paths
- Use them directly as the refactoring scope

**Semantic Search Fallback**:
- If paths don't exist or arguments contain semantic descriptions (e.g., "authentication logic", "user login components")
- Search the codebase using Grep for code matching that description
- Automatically include ALL matching files in the refactoring scope without user confirmation

#### When No Arguments Are Provided (Session Context)

**Identify Recent Changes**:
- Use `git diff --name-only` to identify recently modified files
- Filter to focus on code files (exclude configuration, documentation, lock files)

**Handle No Changes Scenario**:
- If no recent changes found, inform user that no recent changes were detected
- Suggest providing specific file/directory paths or semantic descriptions as arguments
- Exit without refactoring

**Proceed Automatically**:
- If recent changes exist, automatically proceed using all identified files as refactoring scope
- Display the file list for transparency

See `references/scope-determination.md` for advanced search strategies and edge cases.

### Phase 2: Launch Refactoring Agent

Launch code-simplifier agent with aggressive mode enabled.

Use Task tool with:
```
subagent_type: "refactor:code-simplifier"
```

Pass the following context in the prompt:
- **Target scope**: File paths, semantic search results, or session context
- **Scope determination method**: How scope was determined (paths, semantic query, or session context)
- **Aggressive mode flag**: "Enable aggressive refactoring: remove legacy code, unused exports, backwards-compatibility hacks, and rename improperly named variables"

The agent automatically:
1. Loads the refactor:best-practices skill
2. Detects languages and frameworks
3. Applies relevant best practices from skill references
4. Aggressively refactors while preserving behavior
5. Removes unused code and backwards-compatibility shims
6. Renames improperly named variables/functions

See `references/agent-configuration.md` for detailed Task tool parameters and agent workflow.

### Phase 3: Summary

Provide comprehensive summary of changes including:

1. **Total files refactored** - Count of files changed
2. **Changes categorized** - What changed and why, grouped by improvement type (e.g., "Removed unused imports", "Simplified nested ternaries", "Applied Next.js optimizations")
3. **Best practices applied** - Which language/framework patterns were used
4. **Quality standards enforced** - What standards were verified/applied
5. **Legacy code removed** - Identification of deprecated code eliminated
6. **Test recommendations** - Suggest specific tests to run for verification
7. **Rollback command** - Provide: `git checkout -- <files>`

See `references/output-requirements.md` for detailed summary format specifications.

## Key Requirements

- **Execute immediately** - No user confirmation required based on scope determination
- **Refactor ALL matching files** - When semantic search finds multiple results, refactor them all
- **Aggressive refactoring** - Remove legacy compatibility code, unused exports, rename improperly named vars
- **Preserve behavior** - Maintain public APIs and external contracts unchanged
- **Trust git** - Provide rollback command for safety, don't add compatibility shims
- **Project-wide scope** - If user requests project-wide refactoring, direct them to use `/refactor-project`
