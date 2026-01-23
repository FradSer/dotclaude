---
name: optimize-plugin
description: This skill should be used when the user asks to "validate a plugin", "optimize plugin", "check plugin quality", or mentions plugin optimization and validation tasks.
argument-hint: <plugin-path>
user-invocable: true
allowed-tools: ["Read", "Glob", "Grep", "Bash(bash:*)", "Task", "TodoWrite", "AskUserQuestion"]
---

# Plugin Optimization

You are the Orchestrator. Guide the Agent through these strict phases to ensure a comprehensive audit and optimization of the target plugin.

## Core Principles

-   **Strict Phases**: Follow the phases sequentially. Do not skip steps.
-   **User Confirmation**: Ask for user input and confirmation where specified.
-   **Use TodoWrite**: Track all progress throughout the workflow.
-   **Resolve Path First**: Always ensure you are working with the absolute path of the target plugin.

**Initial request:** $ARGUMENTS

---

## Phase 1: Discovery & Validation

**Goal**: Validate plugin structure and detect issues. No fixes are applied in this phase.

**CRITICAL - Orchestrator Role**: As the Orchestrator, you will:
1. Run validation scripts to identify issues
2. Ask user for decisions (e.g., migration approval)
3. **NEVER fix issues yourself** - all fixes are delegated to the agent in Phase 2

**Actions**:
1.  **Context**: User input is `$ARGUMENTS`.
2.  **Resolution**: Use `realpath` to resolve the absolute path to the plugin by treating `$ARGUMENTS` as a path.
3.  **Validation**: Ensure the resolved path exists.
4.  **Validate Directory Structure**:
    -   Check for `.claude-plugin/plugin.json` manifest file (required)
    -   Use Glob to find component directories
    -   Check standard locations:
        -   `commands/` for slash commands
        -   `agents/` for agent definitions
        -   `skills/` for skill directories
        -   `hooks/hooks.json` for hooks
    -   Verify auto-discovery works
    -   Report any missing directories or files (do NOT create them in this phase)
5.  **Check for Commands Directory** (Modern Architecture Assessment):
    -   **CRITICAL**: If a `commands/` directory exists with `.md` files:
        -   Use `AskUserQuestion` tool to ask the user: "This plugin uses the legacy `commands/` structure. Modern best practice recommends using `skills/` for better modularity and self-contained documentation. Would you like to migrate commands to skills structure?"
        -   Options: "Yes, migrate to skills" / "No, keep commands as-is"
        -   If user chooses "Yes", record this decision for Phase 2 (Automated Fixes)
        -   If user chooses "No", skip migration and proceed with validation
    -   **Note**: This check aligns with modern plugin architecture where Skills are preferred over Commands for new functionality
6.  **Execute Validation Suite**: As the Orchestrator, run the following validation scripts directly using the `Bash` tool. Do NOT launch a sub-agent in this phase.
    -   **Structure**: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-file-patterns.sh "$TARGET"`
    -   **Manifest**: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-plugin-json.sh "$TARGET"`
    -   **Components**: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-frontmatter.sh "$TARGET"`
    -   **Anti-Patterns**: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-tool-invocations.sh "$TARGET"`
7.  **Review**: Analyze the output of each script to identify all failures and issues. Compile a comprehensive list of problems found.
8.  **Do NOT Fix**: Even if you see obvious fixes, do NOT apply them. All fixes will be handled by the agent in Phase 2.

---

## Phase 2: Automated Fixes

**Goal**: Launch the optimizer agent to apply ALL fixes for issues found in Phase 1.

**CRITICAL - Orchestrator Role**: You are the Orchestrator. Your ONLY job in this phase is to:
1. Launch the agent with clear instructions
2. Wait for the agent to complete
3. Do NOT make any fixes yourself in the main session

**Actions**:
1.  **Delegate**: Launch the `plugin-optimizer:plugin-optimizer` agent. This must be the first time the sub-agent is launched.
2.  **Context**: Provide the agent with the resolved absolute path and the validation errors from Phase 1.
3.  **Fix Strategy**: Instruct the agent to apply ALL necessary fixes including:
    -   **Commands to Skills Migration** (if user approved in Phase 1):
        -   For each command in `commands/*.md`:
            -   Create corresponding skill directory `skills/<command-name>/`
            -   Transform command `.md` file to `SKILL.md` format with proper frontmatter
            -   Add `user-invocable: true` to SKILL.md frontmatter
            -   Update plugin.json to declare new skills in `commands` field with full paths
            -   Document the migration in commit message
    -   **Validation Script Issues**: Fix any bugs or outdated logic in validation scripts themselves
    -   **Missing README**: Create basic `README.md` using content from `plugin.json`
    -   **Missing Frontmatter**: Add default frontmatter to agent/command files
    -   **Directory Structure**: Create missing standard directories (`commands`, `agents`, `skills`)
    -   **Refactor**: Rename files to kebab-case if needed
4.  **NO Intermediate Verification**: The agent should NOT re-run validation scripts. All verification happens in Phase 6.
5.  **Reporting**: Agent returns a list of all applied fixes.

---

## Phase 3: Redundancy Analysis

**Goal**: Identify content duplication and execute consolidation fixes after user confirmation.

**CRITICAL - Agent Continuity**: Resume the SAME agent from Phase 2.

**Actions**:
1.  **Resume Agent**: **CRITICAL**: Resume the agent from Phase 2 to preserve context. DO NOT spawn a new agent.
2.  **Analyze**: Perform **Comprehensive Redundancy Analysis** according to standards in `skills/plugin-best-practices/references/`.
3.  **Consult**: Use `AskUserQuestion` tool when uncertain about classification.
4.  **Report**: Report findings with severity classifications and consolidation recommendations.
5.  **Confirm Before Fixing (Mandatory)**: After reporting, you MUST ask the user whether to apply the consolidation fixes using `AskUserQuestion` tool.
    -   Always provide multiple options so the user can explicitly choose whether to proceed (no freeform fallback).
    -   Use the title "Fix redundancy".
    -   Ask: "Redundancy analysis found issues that can be consolidated. Do you want to apply all recommended redundancy fixes?"
    -   Force a single choice with at least these two options:
        -   "Yes, apply all recommended redundancy fixes"
        -   "No, skip redundancy fixes"
6.  **Execute Consolidation**: Only if the user selects "Yes", perform the file operations immediately. If "No", proceed to Phase 4 with no changes.

---

## Phase 4: Quality Review

**Goal**: Validate documentation quality and fix issues (automatically or with confirmation).

**CRITICAL - Agent Continuity**: Resume the SAME agent from Phase 3.

**Actions**:
1.  **Validate README**: Verify `README.md` in the plugin directory. Ensure it accurately reflects the plugin's name, description, and installed components (Agents, Commands, Skills).
2.  **Consult**: **MUST** use `AskUserQuestion` tool to confirm with the user before classifying severity if issues are found.
3.  **Apply Fixes**: If the user agrees to the quality improvements (e.g., updating README), apply the changes immediately.

---

## Phase 5: Version Management

**Goal**: Update plugin version based on optimization changes

**CRITICAL - Agent Continuity**: Resume the SAME agent from Phase 4.

**Actions**:
1.  **Assess Changes**: Review the extent of changes made during Phases 2-4.
2.  **Determine Increment**:
    -   **Patch Update (+0.0.1)**: For minor fixes (e.g., formatting, small documentation updates, frontmatter tweaks).
    -   **Minor Update (+0.1.0)**: For significant changes (e.g., directory restructuring, logic fixes, major redundancy removal).
3.  **Update Version**:
    -   Read the current version from `.claude-plugin/plugin.json`.
    -   Calculate the new version based on the increment.
    -   Update the `version` field in `.claude-plugin/plugin.json`.
4.  **Log**: Record the version change for the final report.

---

## Phase 6: Final Verification

**Goal**: Re-run all validation scripts to verify fixes were correctly applied

**CRITICAL - Orchestrator Role**: You take back control from the agent. Run validation scripts exactly ONCE to verify all fixes.

**Actions**:
1.  **Re-run Validation Suite**: Execute all validation scripts again using the `Bash` tool:
    -   **Structure**: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-file-patterns.sh "$TARGET"`
    -   **Manifest**: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-plugin-json.sh "$TARGET"`
    -   **Components**: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-frontmatter.sh "$TARGET"`
    -   **Anti-Patterns**: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-tool-invocations.sh "$TARGET"`
2.  **Compare Results**: Compare with Phase 1 validation results to confirm all critical issues were resolved
3.  **Document Remaining Issues**: If any issues remain (e.g., design-decision warnings), document them clearly in the final report with explanations
4.  **Do NOT Fix Issues**: If new issues are discovered, document them in the report. Do NOT attempt fixes in this phase.

---

## Phase 7: Summary & Report

**Goal**: Generate final optimization report

**CRITICAL - Orchestrator Role**: Synthesize all phase results into a comprehensive report.

**Actions**:
1.  **Compliance Checklist**: Summary of all checks (both Phase 1 and Phase 6 results).
2.  **Applied Fixes Summary**: List all fixes applied by the agent during Phases 2-5.
3.  **Verification Status**: Confirm validation results from Phase 6.
4.  **Remaining Issues**: Document any issues that could not be automatically fixed, or are design decisions (e.g., internal-only skills not declared).
5.  **Final Report**: Generate the report using the following strict format:

**Output**: Complete validation report in the specified format with all findings, fixes, and recommendations

**Output Format**:

```markdown
## Plugin Validation Report

### Plugin: [name]
Location: [path]

### Summary
[Overall assessment - pass/fail with key stats]

### Issues by Severity
#### Critical ([count])
- `file/path` - [Issue] - [Fix]

#### Warnings ([count])
- `file/path` - [Issue] - [Recommendation]

### Component Inventory
- Commands: [count] found, [count] valid
- Agents: [count] found, [count] valid
- Skills: [count] found, [count] valid
- Hooks: [present/not present], [valid/invalid]
- MCP Servers: [count] configured

### Positive Findings
- [What's done well]

### Recommendations
1. [Priority recommendation]
2. [Additional recommendation]

### Overall Assessment
[PASS/FAIL] - [Reasoning]
```
