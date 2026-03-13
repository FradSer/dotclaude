# acpx Plugin

A Claude Code plugin providing knowledge about `acpx` - a headless CLI client for the Agent Client Protocol (ACP).

**Original Project**: [@openclaw/acpx](https://github.com/openclaw/acpx)

## Overview

This plugin helps Claude understand and guide users on using `acpx` for agent-to-agent communication, session management, and scriptable workflows.

## Features

- Comprehensive knowledge of acpx commands and workflows
- Session management guidance (persistent, named, parallel sessions)
- Queue-aware prompt submission patterns
- Output format recommendations (text, json, quiet)
- Permission mode best practices
- Config file structure and usage

## Installation

### Global Installation

```bash
npm install -g acpx
```

### Plugin Installation

This plugin is automatically discovered when placed in your `.claude-plugin/` directory or loaded via `--plugin-dir`.

## What acpx Provides

`acpx` is a scriptable CLI for running coding agents through the Agent Client Protocol:

- **Persistent sessions**: Multi-turn conversations scoped by repo/cwd
- **One-shot execution**: `exec` mode for temporary tasks
- **Named sessions**: Run parallel workflows with `-s/--session`
- **Queue management**: Automatic queueing with `--no-wait` support
- **Structured output**: `text`, `json`, or `quiet` formats
- **Built-in agent registry**: Friendly names for popular ACP agents

## Usage Examples

### Persistent repo assistant

```bash
acpx codex 'inspect failing tests and propose a fix plan'
acpx codex 'apply the smallest safe fix and run tests'
```

### Parallel named streams

```bash
acpx codex -s backend 'fix API pagination bug'
acpx codex -s docs 'draft changelog entry for release'
```

### Machine-readable output

```bash
acpx --format json codex 'review current branch changes' > events.ndjson
```

## When Claude Uses This Skill

Claude automatically loads this skill when you ask about:

- acpx commands and usage
- Agent Client Protocol (ACP)
- Agent-to-agent communication
- Session management for coding agents
- Scriptable agent workflows

## License

MIT

## Author

Frad LEE <fradser@gmail.com>
