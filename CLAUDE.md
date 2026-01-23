# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a **Claude Code plugin marketplace** repository containing a curated collection of plugins for Claude Code. Each plugin provides specialized commands, agents, and skills for development and productivity workflows.

## Architecture

### Plugin Marketplace Structure

```
dotclaude/
├── .claude-plugin/
│   └── marketplace.json       # Central plugin registry
├── .claude/
│   └── git.local.md          # Local git conventions (commit scopes/types)
├── docs-claude/               # Internal documentation for plugin development
└── [plugin-name]/             # Individual plugins
```

### Plugin Structure Pattern

Each plugin follows the standard Claude Code plugin layout:

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json           # Plugin manifest (minimal - uses auto-discovery)
├── commands/                  # Slash commands (*.md)
├── agents/                    # Agent definitions (*.md)
├── skills/                    # Skill directories
│   └── skill-name/
│       ├── SKILL.md          # Main skill file
│       └── references/       # Detailed reference materials
├── hooks/                     # Hook configurations
└── README.md
```

### Current Plugins

| Plugin | Purpose | Key Components |
|--------|---------|----------------|
| `git` | Conventional Git automation | Commands: commit, commit-and-push, gitignore; Skills: conventional-commits |
| `gitflow` | GitFlow workflow automation | Commands: start/finish for feature, hotfix, release; Skills: gitflow-workflow |
| `github` | GitHub operations with quality gates | Commands: create-issues, create-pr, resolve-issues |
| `review` | Multi-agent code review | Agents: code-reviewer, security-reviewer, tech-lead-reviewer, ux-reviewer |
| `refactor` | Code simplification | Agents: code-simplifier; Commands: refactor, refactor-project |
| `swiftui` | SwiftUI architecture review | Agents: swiftui-clean-architecture-reviewer |
| `office` | Patent application generation | Skills: patent-architect |
| `utils` | Day-to-day automation | Commands: continue, create-command |

## Key Conventions

### Git Commit Conventions (from .claude/git.local.md)

**Scopes:** git, flow, gh, office, refactor, review, swiftui, utils, build, ci

**Types:** feat, fix, docs, refactor, test, chore, perf, style, build, ci

**Branch Prefixes:**
- feature/*, fix/*, hotfix/*, refactor/*, docs/*

### Plugin Development Patterns

**Commands** (instructions FOR Claude, not descriptions):
- Use YAML frontmatter with `description`, `argument-hint`, `allowed-tools`
- Always restrict Bash with filters: `Bash(git:*)`, never bare `Bash`
- Use inline bash execution: `!`git status`` for dynamic context

**Agents** (autonomous subprocesses):
- Must include 2-4 `<example>` blocks in description for routing
- Use second person in system prompt ("You are...")
- Assign distinct colors for UI identification

**Skills** (domain knowledge):
- Place SKILL.md inside subdirectory: `skills/skill-name/SKILL.md`
- Use imperative style ("Parse the file...", not "You should...")
- Keep SKILL.md under 2000 words; move details to `references/`

### Tool Invocation in Plugin Content

- **Do NOT explicitly call** Read, Write, Glob, Grep, Edit - describe actions directly
- **Do NOT say "Use Bash tool"** - describe commands directly
- **Always explicitly call** Skill tool: "Load X skill using the Skill tool"
- **Task tool**: Describe agent launch directly unless providing full JSON structure

## References

- Plugin best practices: `docs-claude/PLUGIN_BEST_PRACTICES.md`
- File patterns: `docs-claude/FILE_PATTERNS.md`
- Skills documentation: `docs-claude/skills.md`
