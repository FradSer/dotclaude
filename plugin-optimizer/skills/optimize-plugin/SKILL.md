---
name: optimize-plugin
description: This skill should be used when the user asks to "validate a plugin", "optimize plugin", "check plugin quality", "review plugin structure", or mentions plugin optimization and validation tasks.
argument-hint: <plugin-path>
user-invocable: true
allowed-tools: ["Read", "Glob", "Bash(realpath *)", "Bash(bash:*)", "Task", "AskUserQuestion", "TodoWrite"]
---

# Plugin Optimization

Execute plugin validation and optimization workflow through specialized agent.

**Target plugin:** $ARGUMENTS

## Background Knowledge

Follow these tool invocation patterns when writing or reviewing plugin content:

| Tool | Style | Correct Format | Wrong Format |
|------|-------|----------------|--------------|
| Read, Write, Glob, Grep, Edit | Implicit | "Find files matching...", "Read each file..." | "Use Glob tool to find..." |
| Bash | Implicit | "Run `git status`" | "Use Bash tool to run..." |
| Task | Implicit | "Launch `plugin-name:agent-name` agent" | "Use Task tool to launch...", "Launch my-agent" |
| Skill | **Explicit** | "**Load `plugin-name:skill-name` skill** using the Skill tool" | "Load X skill", "Load my-skill" |
| AskUserQuestion | **Explicit** | "Use `AskUserQuestion` tool to [action]" | "Ask user about...", "Confirm with user..." |
| TodoWrite | **Explicit** | "**Use TodoWrite tool** to track" | "Track progress" |

**Qualified names**: Plugin components MUST use `plugin-name:component-name` format. Claude Code built-in components use their own names.

---

## Initialization

**Goal**: Set up task tracking for the optimization workflow.

**Actions**:
1. Use TodoWrite tool to create task list with all phases:
   - **Phase 1: Discovery & Validation** - Validate plugin structure and detect all issues
   - **Phase 2: Agent-Based Optimization & Quality Analysis** - Launch agent to apply fixes and perform quality improvements
   - **Phase 3: Final Verification** - Re-run validation scripts to verify all fixes
   - **Phase 4: Summary Report** - Generate comprehensive validation report

---

## Phase 1: Discovery & Validation

**Goal**: Validate plugin structure and detect all issues. Orchestrator MUST NOT apply fixes in this phase.

**Actions**:
1. **Path Resolution**: Use `realpath` to resolve absolute path from `$ARGUMENTS`
2. **Existence Check**: Verify the resolved path exists
3. **Directory Structure Validation**:
   - Check for `.claude-plugin/plugin.json` manifest (required)
   - Find component directories: `commands/`, `agents/`, `skills/`, `hooks/`
   - Verify auto-discovery configuration
   - Report missing directories or files (MUST NOT create them)
4. **Component Template Validation** (CRITICAL - Read Full File Before Validation):
   - For each agent file (`./agents/*.md`), validate against Agent Template (see below)
   - For each skill file (`./skills/**/SKILL.md`):
     a. **Read complete file** (frontmatter + full body content)
     b. **Classify type**: Instruction-type (user-invocable: true) vs Knowledge-type (user-invocable: false)
     c. **Validate frontmatter** against template requirements
     d. **Validate writing style** (imperative vs declarative)
     e. **Validate structure** (CRITICAL - Must be thorough):
        - For Instruction-type: Use validation checklist to verify Phase-based structure
          * REQUIRED: Check for `## Phase 1:` section (exact format required)
          * REQUIRED: Verify all execution sections use `## Phase N:` format
          * REQUIRED: Confirm each Phase has `**Goal**:` subsection
          * REQUIRED: Confirm each Phase has `**Actions**:` subsection
          * FORBIDDEN: Any execution section not matching `## Phase N:` pattern (flag as CRITICAL violations)
        - For Knowledge-type: Verify topic-based sections (not Phase-based)
     f. **Cross-check plugin.json** declarations match component types
   - Report ALL template violations as CRITICAL issues with specific line references
   - Record all validation results for Phase 2 agent
5. **Modern Architecture Assessment**:
   - If `commands/` directory exists with `.md` files:
     - Use `AskUserQuestion` tool to ask user about migrating to skills structure
     - Record user decision for Phase 2
6. **Execute Validation Suite** - Run all scripts:
   - **Structure**: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-file-patterns.sh "$TARGET"`
   - **Manifest**: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-plugin-json.sh "$TARGET"`
   - **Components**: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-frontmatter.sh "$TARGET"`
   - **Anti-Patterns**: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-tool-invocations.sh "$TARGET"`
7. **Analysis**: Compile comprehensive list of issues by severity:
   - Critical issues (MUST fix)
   - Warnings (SHOULD fix)
   - Info (MAY improve)

### Component Template Validation

Validate that all components conform to their respective templates from `${CLAUDE_PLUGIN_ROOT}/examples/`.

#### Agent Template Validation

For each file in `./agents/*.md`, verify:

**Frontmatter Requirements**:
- `name`: Present and matches filename
- `description`: Present (MAY include 2-4 `<example>` blocks for routing - optional)
- `color`: Present (valid values: blue, cyan, green, yellow, magenta, red)
- `allowed-tools`: Present (array of tool names)

**System Prompt Requirements**:
- Uses second person: "You are...", "You analyze...", "You perform..."
- Descriptive voice focusing on capabilities (NOT directive: avoid "Load...", "Execute...")

**Structure Requirements**:
- **Knowledge Base** section: Documents loaded skills and resources
- **Core Responsibilities** section: Numbered list of agent duties
- **Approach** section: Working principles and methodology

**Template Violations** (flag as CRITICAL):
```text
agents/[agent-name].md uses imperative "Execute..." instead of descriptive "You execute..."
agents/[agent-name].md missing "## Core Responsibilities" section
```

#### Instruction-Type Skill Template Validation

For each skill with `user-invocable: true` in frontmatter:

**Frontmatter Requirements**:
- `name`: Present
- `description`: Present (when to invoke skill)
- `user-invocable: true`: Must be explicitly set
- `allowed-tools`: Present (array of tool names)

**Writing Style Requirements**:
- Imperative voice: "Load...", "Create...", "Execute...", "Analyze..."
- NO declarative descriptions: avoid "is", "are", "provides"

**Structure Requirements (CRITICAL - Must Follow Exact Format)**:

**MANDATORY Phase Format:**
- MUST use exact format: `## Phase N: [Phase Name]` where N is a number (1, 2, 3, ...)
- All execution sections MUST follow this pattern (any deviation is CRITICAL violation)
- Each phase MUST have both subsections:
  - `**Goal**:` - What this phase accomplishes (single sentence)
  - `**Actions**:` - Numbered list of steps (1., 2., 3., ...)
- Linear process flow from start to completion

**Validation Checklist (All Must Pass)**:
1. REQUIRED: At least one `## Phase 1:` section exists
2. REQUIRED: All execution sections use `## Phase N:` format (where N = 1, 2, 3...)
3. REQUIRED: Each Phase section has `**Goal**:` subsection
4. REQUIRED: Each Phase section has `**Actions**:` subsection
5. REQUIRED: Actions use numbered lists (1., 2., 3., ...)
6. FORBIDDEN: Any execution section that does not match `## Phase N:` format pattern

**Optional Sections (Allowed Before Phase 1)**:
- `## Background Knowledge` - Domain knowledge, format specs, rules
- `## Initialization` - Setup steps before main workflow
- `## Context` - Environmental information

**Template Violations** (flag as CRITICAL):
```text
skills/[skill-name]/SKILL.md has user-invocable:true but uses declarative voice instead of imperative
skills/[skill-name]/SKILL.md execution sections do not match "## Phase N:" format (CRITICAL structure violation)
skills/[skill-name]/SKILL.md has Phase sections but missing **Goal** and **Actions** subsections
skills/[skill-name]/SKILL.md missing Phase-based structure entirely
```

#### Knowledge-Type Skill Template Validation

For each skill with `user-invocable: false` or missing field:

**Frontmatter Requirements**:
- `name`: Present
- `description`: Present (domain/topic covered)
- `user-invocable: false`: Should be explicitly set or omitted

**Writing Style Requirements**:
- Declarative voice: "is", "are", "provides", "defines", "describes"
- NO imperative instructions: avoid "Load...", "Execute...", "Analyze..."

**Structure Requirements**:
- Topic-based sections: "## Core Concepts", "## Best Practices", "## Patterns"
- Reference content: definitions, tables, examples (NOT execution sequences)
- Teaching tone: "Skills are...", "Use when...", "Components MUST..."

**Template Violations** (flag as CRITICAL):
```text
skills/[skill-name]/SKILL.md uses imperative "Execute..." instead of declarative style
skills/[skill-name]/SKILL.md has Phase structure (should use topic-based sections)
```

#### Skill Type Classification & Manifest Validation

Classify each `./skills/**/SKILL.md` as Instruction-type vs Knowledge-type:

1. Read the complete file (frontmatter + body)
2. Check frontmatter `user-invocable`:
   - `user-invocable: true` -> Instruction-type (preliminary)
   - `user-invocable: false` -> Knowledge-type (preliminary)
   - Missing -> Continue with content analysis
3. Determine writing style using indicators above
4. Flag CRITICAL mismatches:
   - Frontmatter vs content conflict -> CRITICAL
   - Template structure violations -> CRITICAL
5. Validate `plugin.json` declaration:
   - Instruction-type MUST be in `commands`
   - Knowledge-type MUST be in `skills`
6. Record results for Phase 2 agent:
   - Component path, detected type, frontmatter values, template violations, recommended fix

Mismatch examples:
```text
Skill `./skills/[skill-name]/SKILL.md` has `user-invocable: true` but uses declarative voice (violates Instruction-type template)
Skill `./skills/[skill-name]/SKILL.md` has `user-invocable: true` but execution sections do not match "## Phase N:" format (CRITICAL structure violation)
Skill `./skills/[skill-name]/SKILL.md` has sections resembling phases but missing exact format and **Goal**/**Actions** subsections
Instruction-type skill `./skills/[skill-name]/` declared in `skills`, MUST move to `commands`
Agent `./agents/[agent-name].md` uses imperative voice instead of descriptive (violates Agent template)
```

Quick reference:

| Component Type | user-invocable | Voice | Structure | Declared in |
|----------------|----------------|-------|-----------|-------------|
| Agent | N/A | Descriptive (You are...) | Knowledge Base + Core Responsibilities + Approach | `agents` |
| Instruction Skill | `true` | Imperative (Load...) | Phase-based (Goal + Actions) | `commands` |
| Knowledge Skill | `false` | Declarative (is/are...) | Topic-based (concepts/patterns) | `skills` |

---

## Phase 2: Agent-Based Optimization & Quality Analysis

**Goal**: Launch agent to apply ALL fixes based on issues found in Phase 1, including redundancy and quality improvements.

**Actions**:
1. Launch `plugin-optimizer:plugin-optimizer` agent
2. Provide context:
   - Target plugin absolute path
   - Validation issues from Phase 1 (organized by severity)
   - Template validation results (component violations and recommended fixes)
   - User decisions (migration choice if applicable)
   - Current workflow phase: "optimization and quality analysis"
   - **Path reference validation rules**:
     - Files within same skill/agent directory: Use relative paths (e.g., `./reference.md`, `examples/example.md`)
     - Files outside skill/agent directory: MUST use `${CLAUDE_PLUGIN_ROOT}` paths
     - Verify all file references follow correct path pattern
   - **Component templates**: See `${CLAUDE_PLUGIN_ROOT}/examples/` for complete templates and validation checklist
   - **Template fix requirements**:
     - Before applying any template fixes, agent MUST use `AskUserQuestion` tool to present violations and get user approval
     - Present all detected template violations with specific examples from target plugin
     - Provide clear explanation of what changes will be made to conform to templates
     - **For structure violations**, show before/after comparison:
       * Example: Converting non-Phase sections to `## Phase N: [Name]` format
       * Example: Adding `**Goal**:` and `**Actions**:` subsections to sections lacking them
       * Example: Reorganizing knowledge content to optional sections (Background Knowledge, Initialization, Context)
     - Only proceed with fixes after user explicitly approves
     - **Structure refactoring priority**: Fix CRITICAL violations first (Phase format, Goal/Actions subsections)
   - **Redundancy analysis requirements**:
     - Identify true duplication (verbatim repetition without purpose)
     - **Allow strategic repetition** of critical content: core validation rules, MUST/SHOULD requirements, safety constraints, key workflow steps that must not be missed, critical decision points or constraints, templates, and examples
     - Distinguish progressive disclosure (summary → detail) from redundancy
3. Agent performs optimization workflow:
   - Apply all fixes based on Phase 1 issues
   - **For template violations**: Use `AskUserQuestion` tool BEFORE applying fixes to get user confirmation
   - Perform redundancy analysis and quality review
   - Use `AskUserQuestion` tool to ask for user confirmation before applying redundancy fixes
4. Wait for agent to complete all optimization tasks
5. Receive comprehensive list of applied fixes from agent (including template conformance, redundancy, and quality improvements)
6. **Update Plugin Documentation**:
   - Update README.md with current plugin structure, components, and usage
   - Ensure README reflects any migrations or structural changes
7. **Update Plugin Version**:
   - Increment version in `.claude-plugin/plugin.json` based on extent of changes:
     - Patch (x.y.Z+1): Bug fixes, minor corrections
     - Minor (x.Y+1.0): New components, feature additions
     - Major (X+1.0.0): Breaking changes, major migrations

**Critical**: Launch agent ONCE with all context. Orchestrator MUST NOT make fixes in main session.

---

## Phase 3: Final Verification

**Goal**: Re-run validation scripts to verify all fixes were applied correctly.

**Actions**:
1. **Re-run Validation Suite** using Bash tool:
   - `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-file-patterns.sh "$TARGET"`
   - `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-plugin-json.sh "$TARGET"`
   - `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-frontmatter.sh "$TARGET"`
   - `bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-tool-invocations.sh "$TARGET"`
2. **Compare Results**: Compare with Phase 1 validation to confirm critical issues resolved
3. **Fix Remaining Issues**: If validation reveals new or unresolved issues:
   - Resume agent from Phase 2 (preserve context)
   - Provide remaining issues from verification results
   - Wait for agent to apply additional fixes
   - Receive updated fix report
4. **Document Remaining Issues**: Note any issues that remain (design decisions, optional improvements)

---

## Phase 4: Summary Report

**Goal**: Generate comprehensive validation report with all findings and fixes.

**Actions**:
1. Synthesize all phase results into final report
2. Use the report format below
3. Include: issues detected, fixes applied, verification results, component inventory, remaining issues, recommendations
4. Provide overall assessment (PASS/FAIL) with detailed reasoning

### Report Template

```markdown
## Plugin Validation Report

### Plugin: [name]
Location: [absolute-path]
Version: [old] -> [new]

### Summary
[Overall assessment with key statistics]

### Phase 1: Issues Detected
#### Critical ([count])
- `file/path` - [Issue description]

#### Warnings ([count])
- `file/path` - [Issue description]

#### Info ([count])
- `file/path` - [Suggestion]

### Phase 2: Fixes Applied
#### Structure Fixes
- [Fix description]

#### Manifest Fixes
- [Fix description]

#### Component Fixes
- [Fix description]

#### Template Conformance
- **Agents**: [Count] validated, [count] fixed
  - [Specific agent template fixes applied]
  - Structure: [count] with proper Knowledge Base/Core Responsibilities/Approach sections
- **Instruction-type Skills**: [Count] validated, [count] fixed
  - [Specific instruction skill template fixes applied]
  - Structure: [count] with Phase-based format (## Phase N: structure)
  - Goal/Actions: [count] with proper **Goal**/**Actions** subsections
  - Format violations fixed: [list files converted from ## Your Task to Phase format]
- **Knowledge-type Skills**: [Count] validated, [count] fixed
  - [Specific knowledge skill template fixes applied]
  - Structure: [count] with topic-based sections (not Phase-based)

#### Migration Performed
- [Details if commands migrated to skills]

#### Redundancy Fixes
- [Consolidations applied]

#### Quality Improvements
- [Documentation updates]

### Phase 4: Verification Results
- Structure validation: [PASS/FAIL]
- Manifest validation: [PASS/FAIL]
- Component validation: [PASS/FAIL]
- Tool patterns validation: [PASS/FAIL]

### Component Inventory
- Commands: [count] found, [count] valid
- Agents: [count] found, [count] valid
- Skills: [count] found, [count] valid
- Hooks: [present/absent], [valid/invalid]
- MCP Servers: [count] configured

### Remaining Issues
[Issues that couldn't be auto-fixed or are design decisions with explanations]

### Positive Findings
- [What's implemented well]

### Recommendations
1. [Priority recommendation for manual follow-up]
2. [Additional suggestions]

### Overall Assessment
[PASS/FAIL] - [Detailed reasoning based on validation results]
```

Section guidelines (keep these while writing, omit them from the final report if the user asks for brevity):
- Summary: 2-3 sentences, include counts and whether production-ready
- Issues: sort Critical -> Warnings -> Info, include line numbers when relevant
- Fixes: group by category, be concrete about changes
- Verification: report PASS/FAIL per script and compare vs Phase 1
- Inventory: counts for found vs valid per component type
- Remaining issues: explain why not fixed (blocker vs design), include manual next steps
