---
name: refactor-project
description: Run project-wide refactoring with code-simplifier
argument-hint: (no arguments needed - refactors entire project)
allowed-tools: ["Task", "Read", "Write", "Bash(git:*)", "Grep", "Glob"]
user-invocable: true
---

# Refactor Project Command

Execute fully automated project-wide refactoring using the code-simplifier agent. Apply aggressive improvements across entire codebase with emphasis on cross-file duplication reduction and consistent patterns.

## Workflow

### Phase 1: Analyze Project Scope

Perform quick analysis to determine full project refactoring scope.

#### File Discovery

**Use Glob to find all code files**:
- Search for common code file patterns: `**/*.{ts,tsx,js,jsx,py,go,swift,java,rb,rs}`
- Discover all source files in the project

**Filter to source code only**:
- Exclude: `node_modules/`, `.git/`, `dist/`, `build/`, `vendor/`, `.venv/`
- Exclude: configuration files, lock files, binary files, documentation
- Focus on actual source code files

**Group files by type/language**:
- Categorize by file extensions (`.ts`, `.py`, `.go`, etc.)
- Identify primary and secondary languages
- Count files per language

**List primary source code directories**:
- Identify main source trees (`src/`, `lib/`, `app/`, `pkg/`)
- Note test directories separately (`__tests__/`, `tests/`, `*_test.go`)

**Show project structure overview**:
- Display directory tree with file counts
- Highlight main code locations

#### Scope Summary Display

Display informational summary before proceeding (no confirmation needed):

```
Project-wide Refactoring Scope:
- Total files: <count>
- Languages: <list of detected languages>
- Main directories: <list>

Proceeding with project-wide refactoring automatically.
```

See `references/scope-analysis.md` for exclusion patterns and edge cases.

### Phase 2: Launch Refactoring Agent

Launch code-simplifier agent with project-wide scope and cross-file optimization focus.

Use Task tool with:
```
subagent_type: "refactor:code-simplifier"
```

Pass the following context in the prompt:
- **Project-wide scope**: All discovered code files
- **Cross-file optimization focus**: "Emphasize duplication reduction across files and consistent patterns project-wide"
- **Aggressive mode flag**: "Enable aggressive refactoring: remove legacy code, unused exports, backwards-compatibility hacks, and rename improperly named variables"

The agent automatically:
1. Loads the refactor:best-practices skill
2. Analyzes the entire codebase
3. Detects frameworks, libraries, and languages
4. Applies relevant best practices from skill references
5. Emphasizes cross-file duplication and consistent patterns
6. Aggressively refactors while preserving behavior
7. Removes unused code and backwards-compatibility shims
8. Renames improperly named variables/functions project-wide

See `references/agent-configuration.md` for detailed Task tool parameters and agent workflow.

### Phase 3: Summary

Provide comprehensive summary of project-wide changes including:

1. **Total files refactored** - Count and percentage of project (e.g., "42 files (68% of project)")
2. **Changes categorized** - What changed and why, grouped by improvement type
3. **Files touched** - Total count of modified files
4. **Best practices applied** - Which language/framework patterns were used
5. **Cross-file improvements** - Specific deduplication and consistency changes
6. **Quality standards enforced** - What standards were verified/applied
7. **Legacy code removed** - Identification of deprecated code eliminated
8. **Test recommendations** - Suggest comprehensive test suite to run
9. **Review recommendations** - Suggest reviewing changes in logical groups (e.g., "Review auth changes first, then UI components")
10. **Rollback command** - Provide: `git reset --hard HEAD`

See `references/output-requirements.md` for detailed summary format specifications.

## Key Requirements

- **Execute immediately** - No user confirmation required after displaying scope
- **Refactor entire project** - Apply improvements across all discovered code files
- **Aggressive refactoring** - Remove legacy compatibility code, unused exports, rename improperly named vars
- **Cross-file focus** - Prioritize duplication reduction and consistent patterns across files
- **Preserve behavior** - Maintain public APIs and external contracts unchanged
- **Trust git** - Provide rollback command for safety, entire project scope means git reset
