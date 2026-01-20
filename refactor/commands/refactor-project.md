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

**Question 2: Weighting Strategy**
- header: "Rule weighting"
- question: "How should rule priorities be weighted?"
- options:
  - Impact-based (Prioritize rules by their impact level - recommended)
  - Equal (All rules weighted equally)
  - Custom (Define custom weights in configuration file)

After gathering answers, create `.claude/refactor.local.md` with:
- YAML frontmatter containing all configuration
- Map answers to configuration structure:
  - `enabled`: true
  - `default_mode`: User's selection (all/selected/weighted)
  - `weighting_strategy`: User's selection (impact-based/equal/custom)
  - `rule_categories`: Empty object (framework and language detection will happen in the skill)
  - `custom_weights`: Empty object
  - `disabled_patterns`: Empty array
- Include helpful markdown body explaining:
  - Configuration can be edited manually anytime
  - Framework-specific rules (Next.js, React, etc.) are automatically detected and applied by the skill
  - Language-specific rules are determined based on file types in the project
  - How to disable specific patterns or categories

Then inform user:
- Configuration file created at `.claude/refactor.local.md`
- They can edit it manually anytime
- Configuration is gitignored and won't be committed
- Framework and language detection happens automatically during refactoring

### Extract Configuration (After Setup or If Exists)

Extract configuration from file or defaults:
- `enabled`: Whether refactoring is enabled (default: true)
- `default_mode`: all|selected|weighted (default: all)
- `weighting_strategy`: impact-based|equal|custom (default: impact-based)
- `rule_categories`: Object with framework and language flags (empty by default, populated by skill based on detection)
- `custom_weights`: Custom weight overrides
- `disabled_patterns`: List of disabled pattern IDs

**Note**: Framework and language detection happens automatically in the skill, not in the command.

## Step 2: Analyze Project Code (Preview Mode)

Before applying refactoring, analyze the entire project to identify:
1. **Detected frameworks**: Scan for Next.js, React, Vite, and other frameworks (performed by skill)
2. **Detected languages**: Scan files to identify languages used (TypeScript, Python, Go, Swift, etc.)
3. **Applicable rule categories**: Based on detected frameworks and languages (determined by skill)
4. **Potential improvements**: List of specific refactoring opportunities per category
5. **Cross-file patterns**: Duplication and consistency issues across the codebase
6. **Estimated scope**: Approximate number of files and changes that will be affected

**Note**: Framework detection is handled by the best-practices skill, ensuring only applicable rules are considered.

## Step 3: Interactive Rule Selection

**CRITICAL**: For project-wide refactoring, ALWAYS show preview and get confirmation.

**Note**: The skill handles framework detection and determines applicable rule categories. The command only needs to confirm scope with the user.

Show preview summary:
- Detected frameworks (e.g., "Tauri + React + Vite" or "Next.js")
- Detected languages (e.g., "TypeScript, Python")
- Applicable rule categories (determined by skill based on framework detection)
- Estimated files affected
- Estimated changes per category
- Potential impact

Use AskUserQuestion:

**Question 1: Scope Confirmation**
- header: "Confirm scope"
- question: "This will refactor the entire project with detected rules. Are you sure?"
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
   - Configuration preferences (default_mode, weighting_strategy, disabled patterns)
   - Emphasis on cross-file duplication reduction and consistent patterns
3. The agent will automatically:
   - Load the refactor:best-practices skill
   - Detect frameworks (Next.js, React, Vite, etc.) and languages
   - Apply only rules applicable to detected frameworks and languages
   - Respect configuration preferences
   - Emphasize cross-file duplication and consistent patterns

**IMPORTANT**: Framework and language detection happens in the skill, not the command. The skill will only apply Next.js rules if Next.js is detected, React rules for React projects, etc.

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
