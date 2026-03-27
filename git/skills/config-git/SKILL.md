---
name: config-git
description: Interactively configures git setup for user identity and project conventions. This skill should be used when the user asks to "configure git", "setup git", "set commit scopes", or needs to set up Git for a new project, configure commit scopes and types, or create project-specific Git settings.
user-invocable: true
allowed-tools: ["Bash(git-agent:*)", "Bash(git:*)", "Bash(ls:*)", "Bash(find:*)", "Read", "Write", "Glob", "AskUserQuestion", "Skill", "Task"]
model: sonnet
context: fork
---

## Workflow Execution

**Launch a general-purpose agent** that executes all 5 phases in a single task.

**Prompt template**:
```
Execute the complete git configuration workflow (5 phases).

Load `git:use-git-agent` skill using the Skill tool for git-agent CLI reference.

## Phase 1: Verify User Identity
**Goal**: Ensure git user.name and user.email are configured

**Actions**:
1. Run `git config --list --show-origin` to get current config
2. Check if `user.name` and `user.email` are set
3. If EITHER is missing, use AskUserQuestion to request the missing information
4. Set the values globally (or locally if user specifies) using `git config`

## Phase 2: Analyze Project Context
**Goal**: Detect project languages and frameworks for gitignore configuration

**Actions**:
1. Run `ls -F` or `find . -maxdepth 2 -not -path '*/.*'` to detect project languages/frameworks

## Phase 3: Generate Scopes with git-agent
**Goal**: Auto-generate commit scopes using git-agent

**Actions**:
1. Run `git-agent init --scope --force` to generate scopes from git history via AI
2. On auth/provider error, follow the fallback chain from the use-git-agent skill
3. Read generated scopes from `.git-agent/config.yml`
4. Validate all scopes follow naming rules:
   - Single words: use as-is
   - Multi-word names: MUST convert to first letters (e.g., `multi-word-name` -> `mwn`)
   - MUST NOT use commit types as scopes
5. If genuine ambiguity exists, use AskUserQuestion

## Phase 4: Generate Configuration File
**Goal**: Create `.claude/git.local.md` with complete structure from example template

**CRITICAL - Template Requirements**:
- Use the ENTIRE example file structure as template
- Preserve ALL sections from the example:
  - YAML frontmatter with `scopes`, `types`, `branch_prefixes`, AND `gitignore`
  - "# Project-Specific Git Settings" section
  - "## Usage" section with all bullet points
  - "## Additional Guidelines" section with all bullet points

**Actions**:
1. Read the example configuration file: `${CLAUDE_PLUGIN_ROOT}/examples/git.local.md`
2. Replace the `scopes` list with validated scopes from Phase 3
3. Update `gitignore` technologies based on detected project languages/frameworks from Phase 2
4. Keep `types` as standard conventional commit types (unless user requests changes)
5. Keep `branch_prefixes` as shown in example (unless user requests changes)
6. Create or overwrite `.claude/git.local.md` in the project root
7. Read the file back to verify it matches the example's complete structure

**Output**: `.claude/git.local.md` file with project-specific configuration

## Phase 5: Confirmation
**Goal**: Inform user of successful configuration

**Actions**:
1. Confirm configuration is complete
2. Show the location of the created file
```

**Execute**: Launch a general-purpose agent using the prompt template above
