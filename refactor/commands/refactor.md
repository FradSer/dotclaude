---
description: Refactor code with code-simplifier
argument-hint: [files-or-directories-or-semantic-query]
allowed-tools: ["Task", "AskUserQuestion", "Read", "Write", "Bash", "Grep"]
---

# Refactor Command

## Core Principles

- **Interactive and safe**: Show preview and get user confirmation before making changes
- **Configuration-aware**: Respect user preferences from `.claude/refactor.local.md`
- **Use TodoWrite**: Track all progress throughout the workflow

## Context

- **If arguments are provided**:
  - First, check if they are valid file/directory paths relative to the repo root.
  - If paths exist, treat them as target paths.
  - If paths don't exist or arguments contain semantic descriptions (e.g., "authentication logic", "user login components"), search the codebase for code matching that description.
- **If no arguments are provided**:
  - Default to refactoring code associated with the current session context.
  - Identify recently modified files from the current session.
  - If no recent changes are found, inform user to provide specific file/directory paths.
- This command supports interactive preview and rule selection before applying refactoring.

## Initial Setup

**Actions**:
1. Create todo list with all workflow steps:
   - Load or create configuration
   - Determine target scope
   - Analyze target code
   - Interactive rule selection (if needed)
   - Launch refactoring agent
   - Summarize results
2. Mark current step as in_progress as you proceed through the workflow
3. Complete todos immediately after finishing each step

## Step 1: Load or Create Configuration

Check if `.claude/refactor.local.md` exists using Read tool:
- **If exists**: Read and parse YAML frontmatter to get rule preferences
- **If not exists**: This is first-time use - guide user through configuration setup

### If Configuration Doesn't Exist (First-Time Setup)

**IMPORTANT**: Before asking configuration questions, detect the project's frameworks and languages.

**Detection Steps**:
1. Use Bash to check for Next.js (look for `next.config.js`, `next.config.ts`, or `"next"` in package.json dependencies)
2. Use Glob to detect language files (*.ts, *.tsx, *.py, *.go, *.swift)
3. Determine which framework-specific and language-specific questions to ask

Use AskUserQuestion to gather configuration preferences:

**Question 1: Default Rule Application Mode**
- header: "Default mode"
- question: "How should rules be applied by default? (You can change this later in .claude/refactor.local.md)"
- options:
  - All (Apply all applicable rules automatically - recommended for quick start)
  - Selected (Always show interactive rule selection)
  - Weighted (Apply rules based on configured weights)

**Question 2: Next.js Rule Categories** (ONLY if Next.js is detected)
- header: "Next.js rules"
- question: "Which Next.js rule categories should be enabled?"
- multiSelect: true
- options:
  - async (Eliminating waterfalls - CRITICAL impact)
  - bundle (Bundle size optimization - CRITICAL impact)
  - server (Server-side performance - HIGH impact)
  - client (Client-side data fetching - MEDIUM-HIGH impact)
  - rerender (Re-render optimization - MEDIUM impact)
  - rendering (Rendering performance - MEDIUM impact)
  - js (JavaScript micro-optimizations - LOW-MEDIUM impact)
  - advanced (Advanced patterns - LOW impact)

**Question 3: Language-Specific Rules**
- header: "Language rules"
- question: "Which language-specific rules should be enabled?"
- multiSelect: true
- options: (Dynamically include only detected languages + universal)
  - typescript (TypeScript/JavaScript best practices) [if .ts/.tsx/.js/.jsx files detected]
  - python (Python best practices) [if .py files detected]
  - go (Go best practices) [if .go files detected]
  - swift (Swift best practices) [if .swift files detected]
  - universal (Universal principles - SOLID, DRY, KISS, etc. - recommended) [always include]

After gathering answers, create `.claude/refactor.local.md` with:
- YAML frontmatter containing all configuration
- Map answers to configuration structure
- Include helpful markdown body explaining the configuration

Then inform user:
- Configuration file created at `.claude/refactor.local.md`
- They can edit it manually anytime
- Configuration is gitignored and won't be committed

### Extract Configuration (After Setup or If Exists)

Extract configuration from file or defaults:
- `enabled`: Whether refactoring is enabled (default: true)
- `default_mode`: all|selected|weighted (default: all)
- `rule_categories.nextjs`: Object with category flags
- `rule_categories.languages`: Object with language flags
- `weighting_strategy`: impact-based|equal|custom
- `custom_weights`: Custom weight overrides
- `disabled_patterns`: List of disabled pattern IDs

## Step 2: Determine Target Scope

### If Arguments Provided

1. **Check if arguments are file/directory paths**:
   - Verify if paths exist in the repository
   - If paths exist, use them directly as target scope

2. **If paths don't exist or arguments are semantic descriptions**:
   - Search the codebase for code matching the semantic description
   - Collect relevant file paths from the search
   - If multiple results, use AskUserQuestion to confirm scope:
     - header: "Confirm scope"
     - question: "Found multiple files matching your query. Which should be refactored?"
     - multiSelect: true
     - options: [List of file paths from search results]

### If No Arguments Provided (Default: Session Context)

1. **Identify recently modified files**:
   - Find files that have been recently changed in the repository
   - Filter to focus on code files (exclude configuration, documentation, lock files unless needed)

2. **If no recent changes found**:
   - Inform user that no recent changes were detected
   - Suggest providing specific file/directory paths or semantic descriptions as arguments

3. **Present scope to user**:
   - Show identified files
   - Use AskUserQuestion to confirm:
     - header: "Confirm refactoring scope"
     - question: "I found these files related to recent changes. Should I refactor them?"
     - multiSelect: true
     - options: [List of identified files]

## Step 3: Analyze Target Code (Preview Mode)

Before applying refactoring, analyze the target code to identify:
1. **Detected languages**: Based on file extensions and content
2. **Applicable rule categories**: Based on code patterns and frameworks detected
3. **Potential improvements**: List of specific refactoring opportunities
4. **Code relationships**: Dependencies and imports between files

## Step 4: Interactive Rule Selection

If `default_mode` is "selected", use AskUserQuestion:

**Question 1: Rule Categories to Apply**
- header: "Rule categories"
- question: "Which refactoring rule categories should be applied?"
- multiSelect: true
- options: [Dynamically generate based on detected languages and code patterns]
  - For Next.js code: Include async, bundle, server, client, rerender, rendering, js, advanced
  - For each detected language: Include language-specific option
  - Always include: universal (Universal principles)

**Question 2: Confirmation**
- header: "Confirm"
- question: "Ready to apply refactoring with selected rules?"
- options:
  - Yes (Proceed with refactoring)
  - No (Cancel)
  - Modify (Let me adjust the selection)

If user selects "Modify", return to Question 1.

If user selects "No", exit without changes.

## Step 5: Launch Refactoring Agent

If user confirms (or if default_mode is "all" and no interaction needed):

1. Use Task tool with subagent_type="refactor:code-simplifier"
2. Pass:
   - Target scope (file paths, semantic search results, or session context)
   - Selected rule categories (from AskUserQuestion or config)
   - Configuration preferences (weights, disabled patterns)
   - Context about how scope was determined (paths, semantic query, or session context)
3. The agent will automatically load the refactor:best-practices skill
4. Agent will respect configuration and only apply selected rules

## Step 6: Summary

After completion, summarize:
- What changed and why
- Files touched
- Rules applied (which categories)
- Suggested tests to run

## Requirements

- Follow the best-practices workflow and references in the refactor plugin skills
- Preserve functionality while improving clarity, consistency, and maintainability
- Respect user configuration from `.claude/refactor.local.md`
- If the user requests project-wide refactoring, direct them to use `/refactor-project`

<!--
Usage:
/refactor                                    # Refactor code from current session context
/refactor src/auth/login.ts                  # Refactor specific file
/refactor src/utils/ src/api/                # Refactor specific directories
/refactor authentication logic               # Semantic search for authentication-related code
/refactor user login components              # Semantic search for login-related components
-->
