---
description: Run project-wide refactoring with code-simplifier
allowed-tools: ["Task", "AskUserQuestion", "Read", "Write", "Bash", "Grep"]
---

# Refactor Project Command

## Core Principles

- **Safety first**: Always show preview and require explicit confirmation for project-wide changes
- **Configuration-aware**: Respect user preferences from `.claude/refactor.local.md`
- **Cross-file focus**: Emphasize duplication reduction and consistent patterns
- **Use TodoWrite**: Track all progress throughout the workflow

## Context

- This command is for project-wide refactoring across the entire codebase.
- This command supports interactive preview and rule selection before applying refactoring.

## Initial Setup

**Actions**:
1. Create todo list with all workflow steps:
   - Load or create configuration
   - Analyze project code (preview mode)
   - Interactive rule selection
   - Launch refactoring agent
   - Summarize results
2. Mark current step as in_progress as you proceed through the workflow
3. Complete todos immediately after finishing each step

## Step 1: Load or Create Configuration

Check if `.claude/refactor.local.md` exists using Read tool:
- **If exists**: Read and parse YAML frontmatter to get rule preferences
- **If not exists**: This is first-time use - guide user through configuration setup

### If Configuration Doesn't Exist (First-Time Setup)

Use AskUserQuestion to gather configuration preferences:

**Question 1: Default Rule Application Mode**
- header: "Default mode"
- question: "How should rules be applied by default? (You can change this later in .claude/refactor.local.md)"
- options:
  - All (Apply all applicable rules automatically - recommended for quick start)
  - Selected (Always show interactive rule selection)
  - Weighted (Apply rules based on configured weights)

**Question 2: Next.js Rule Categories**
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
- options:
  - typescript (TypeScript/JavaScript best practices)
  - python (Python best practices)
  - go (Go best practices)
  - swift (Swift best practices)
  - universal (Universal principles - SOLID, DRY, KISS, etc. - recommended)

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

## Step 2: Analyze Project Code (Preview Mode)

Before applying refactoring, analyze the entire project to identify:
1. **Detected languages**: Scan files to identify languages and frameworks used
2. **Applicable rule categories**: Based on codebase patterns and architecture
3. **Potential improvements**: List of specific refactoring opportunities per category
4. **Cross-file patterns**: Duplication and consistency issues across the codebase
5. **Estimated scope**: Approximate number of files and changes that will be affected

## Step 3: Interactive Rule Selection

**CRITICAL**: For project-wide refactoring, ALWAYS show preview and get confirmation.

Use AskUserQuestion:

**Question 1: Rule Categories to Apply**
- header: "Rule categories"
- question: "Which refactoring rule categories should be applied project-wide?"
- multiSelect: true
- options: [Dynamically generate based on detected languages]
  - For Next.js code: Include async, bundle, server, client, rerender, rendering, js, advanced
  - For each detected language: Include language-specific option
  - Always include: universal (Universal principles - SOLID, DRY, KISS, etc.)

Show preview summary:
- Estimated files affected
- Estimated changes per category
- Potential impact

**Question 2: Scope Confirmation**
- header: "Confirm scope"
- question: "This will refactor the entire project. Are you sure?"
- options:
  - Yes (Proceed with project-wide refactoring)
  - No (Cancel)
  - Targeted (Switch to /refactor for specific files)

If user selects "No", exit without changes.

If user selects "Targeted", suggest using `/refactor` command instead.

## Step 4: Launch Refactoring Agent

If user confirms:

1. Use Task tool with subagent_type="refactor:code-simplifier"
2. Pass:
   - "project-wide scope"
   - Selected rule categories (from AskUserQuestion or config)
   - Configuration preferences (weights, disabled patterns)
   - Emphasis on cross-file duplication reduction and consistent patterns
3. The agent will automatically load the refactor:best-practices skill
4. Agent will respect configuration and only apply selected rules
5. Agent will emphasize cross-file duplication and consistent patterns

## Step 5: Summary

After completion, summarize:
- What changed and why
- Files touched (total count)
- Rules applied (which categories)
- Cross-file improvements made
- Suggested tests to run
- Recommendation to review changes in logical groups

## Requirements

- Follow the best-practices workflow and references in the refactor plugin skills
- Preserve functionality while improving clarity, consistency, and maintainability
- Emphasize cross-file duplication reduction and consistent patterns
- ALWAYS show preview and get confirmation for project-wide changes
- Respect user configuration from `.claude/refactor.local.md`

<!--
Usage:
/refactor-project
-->
