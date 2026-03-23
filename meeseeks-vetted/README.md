# meeseeks-vetted

**Version:** 0.2.0

Enforces task clarity before execution and requires verified work before exit.

## Installation

### From Marketplace

```bash
claude plugin install meeseeks-vetted@frad-dotclaude
```

### Local Development

```bash
# Clone or navigate to the plugin directory
cd /path/to/dotclaude
claude --plugin-dir ./meeseeks-vetted
```

## Overview

meeseeks-vetted is a Claude Code plugin that ensures every task has clear completion criteria and every deliverable is verified before the session ends. It uses hooks to automatically track session state, accumulate file changes, and block exit until work is genuinely verified.

## Features

- **Task Persistence**: Captures user prompts and saves them to session-scoped state files
- **Change Tracking**: Records every file modification during the session automatically
- **Task Evolution**: Merges prompts with assistant responses to keep task description current
- **Verification Gate**: Blocks session exit until work is explicitly verified with `<verified>` tag
- **Manual Vetting**: `/vet` skill allows manual evaluation of task clarity and completion status

## Usage

### Vet Session Task

```
/vet
```

The vet skill evaluates the current session task through three phases:

1. **Resolve Task State** - Locate and read the session state file
2. **Clarity Check** - Determine if the task has unambiguous completion criteria
3. **Completion Check** - Assess whether the task is complete based on conversation

### Example Output

```
=== Session Task ===
Task: Refactor the authentication module to use JWT tokens
Updated: 2026-03-24T10:30:00Z
Modified: 12 files

=== Clarity Check ===
✓ Task is specific with concrete deliverables

=== Completion Check ✓
All requested work completed:
- Implemented JWT token generation
- Added token validation middleware
- Updated user authentication flow
- Added unit tests

<verified>Fully Vetted.</verified>
```

## Components

### Skill: /vet

Manually surface the current session task and evaluate its clarity and completion status.

**Technical implementation**: User-invocable skill (`user-invocable: true`) stored in `skills/vet/` and registered in `plugin.json` `commands` array.

**What it does**: Executes a three-phase workflow that reads session state, evaluates task clarity, and confirms completion status.

### Hooks

| Event | Script | Purpose |
|-------|--------|---------|
| UserPromptSubmit | `task-start.sh` | Persists user prompt to session state, injects task clarity instructions |
| PostToolUse | `track-changes.sh` | Tracks modified files after Edit/Write/MultiEdit (async) |
| Stop | `verify-work.sh` | Blocks exit until `<verified>Fully Vetted.</verified>` is appended |

**Technical implementation**: Inline hooks defined in `plugin.json` `hooks` array. Each hook runs a shell script that operates on session-scoped state files in `~/.claude/projects/<project-key>/`.

### Library

`lib/utils.sh` provides shared utilities for all hooks:

- `state_dir` - Resolve project-specific state directory path
- `extract_verified` - Extract verified tag from conversation
- `build_change_summary` - Format file change summary for display
- `run_haiku_merge` - Execute Haiku model for task merging

**Technical implementation**: Bash functions sourced by all hook scripts. Uses `CLAUDE_PROJECT_DIR` environment variable to determine project-specific paths.

## Structure

```
meeseeks-vetted/
├── .claude-plugin/
│   └── plugin.json              # Manifest (commands: [./skills/vet/], hooks: inline)
├── hooks/
│   ├── task-start.sh            # UserPromptSubmit hook
│   ├── track-changes.sh        # PostToolUse hook
│   └── verify-work.sh           # Stop hook
├── lib/
│   └── utils.sh                 # Shared utilities
├── skills/
│   └── vet/                     # User-invocable skill
│       └── SKILL.md            # Three-phase vetting workflow
└── README.md
```

## How It Works

1. **Task capture**: On each user prompt, `task-start.sh` saves the task to a session-scoped state file (`~/.claude/projects/<project-key>/<session_id>.vetted.json`)
2. **Change tracking**: `track-changes.sh` records every file modified during the session
3. **Task evolution**: On each stop, `verify-work.sh` merges pending prompts with assistant responses to keep the task description current
4. **Verification gate**: Claude must verify its work and append the verified tag before the session can end

## Prerequisites

- Claude Code CLI
- Bash 4.0+
- Write access to `~/.claude/projects/` directory

## Contributing

Issues and pull requests welcome at the repository.

## License

MIT

## Author

Frad LEE (fradser@gmail.com)