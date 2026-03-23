# meeseeks-vetted

**Version:** 0.3.1

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

## Core Workflow

### 1. Task Injection (UserPromptSubmit)

When the user submits a prompt:
- The task is persisted to a session-scoped state file (`~/.claude/projects/<project-key>/<session_id>.vetted.json`)
- A system message is injected requiring Claude to:
  - Classify the task as either **discussion/question** or **implementation request**
  - For implementation requests: ensure completion criteria are clear before working
  - **Must end responses with `<verified>Fully Vetted.</verified>` when done**

### 2. Verification Gate (Stop)

When Claude tries to exit:

**If verified** (`<verified>Fully Vetted.</verified>` found):
- Merge the assistant's response into the evolving task description
- Keep the state file for future reference
- Allow exit

**If NOT verified**:
- Block exit (exit code 2)
- Build a verification prompt containing:
  - The synthesized task description (from state file or transcript)
  - List of modified files during this turn
  - Instructions to verify and append the verified tag

### 3. Task Evolution (Multi-turn)

When the user submits a new prompt before the previous one is verified:
- The previous prompt is saved as `pending_prompt`
- On Stop, the hook merges:
  - Existing task description
  - The pending prompt
  - Assistant's response (what was done)
- Into a single coherent task statement for the next turn

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

| Event | Script | Trigger Condition | Purpose |
|-------|--------|-------------------|---------|
| UserPromptSubmit | `task-start.sh` | Every user prompt | Persists task to state file, injects verification instructions |
| PostToolUse | `track-changes.sh` | Edit/Write/MultiEdit tools | Tracks modified files (async) |
| Stop | `verify-work.sh` | Every exit attempt | Blocks exit until `<verified>Fully Vetted.</verified>` or merges task context |

**Technical implementation**: Inline hooks defined in `hooks/hooks.json`. Each hook runs a shell script that operates on session-scoped state files in `~/.claude/projects/<project-key>/`.

### Key Scripts

| Script | Responsibility |
|--------|----------------|
| `task-start.sh` | First prompt: save task; subsequent prompts: queue as pending |
| `track-changes.sh` | Record files modified during this turn |
| `verify-work.sh` | Check for verified tag → merge or block exit |

### State File

The state file (`~/.claude/projects/<project-key>/<session_id>.vetted.json`) stores:

```json
{
  "session_id": "abc123",
  "task": "Original user prompt or merged task description",
  "pending_prompt": "New prompt submitted before previous was verified (optional)",
  "modified_files": ["file1.ts", "file2.ts"],
  "created_at": "2026-03-24T10:00:00Z",
  "updated_at": "2026-03-24T10:30:00Z"
}
```

### Three-round Workflow

```
Round 1:
  User: "Fix the bug in auth"
  → task-start.sh saves task, injects verification prompt
  Claude: works...
  → Stop hook checks: no <verified> → blocks, returns task context

Round 2 (if user continues):
  User: "Also add unit tests"
  → task-start.sh queues "Also add unit tests" as pending_prompt
  → verify-work.sh merges: "Fix the bug in auth + what was done + Also add unit tests"
  Claude: continues with merged context...
  → Stop hook checks: <verified> found → allows exit
```

This design ensures:
1. Every task has explicit verification before completion
2. Multi-turn tasks accumulate context rather than being lost
3. Claude cannot "hand off" incomplete work to the user

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

### Stage 1: Task Injection (UserPromptSubmit Hook)

When the user submits a prompt, `task-start.sh`:

1. **Persists the task** to `~/.claude/projects/<project-key>/<session_id>.vetted.json`
2. **Injects a system message** that instructs Claude to:
   - Classify the task type
   - Ensure completion criteria are clear for implementation requests
   - **Finish with `<verified>Fully Vetted.</verified>` when done**

### Stage 2: Verification Gate (Stop Hook)

When Claude tries to exit:

**If `<verified>Fully Vetted.</verified>` is found:**
- Merge the assistant's response into the task description
- Allow exit

**If NOT verified:**
- Block exit (exit code 2)
- Return a verification prompt containing:
  - User's original task (from state file or transcript)
  - Modified files during this turn
  - Instruction to verify work and append the verified tag

### Stage 3: Task Evolution (Multi-turn)

If the user submits a new prompt before the previous one is verified:

1. `task-start.sh` saves the pending prompt to `pending_prompt`
2. On Stop, `verify-work.sh` merges:
   - Existing task description
   - Pending prompt
   - Assistant's response (what was actually done)
3. Creates a unified task description for the next turn

This ensures the task context evolves with each interaction rather than being reset.

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