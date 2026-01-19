# git-flow-next Topic Branch Commands

Commands for managing topic branches (feature, release, hotfix, support, and custom types). Based on [official documentation](https://git-flow.sh/docs/commands/) and cheat sheet.

## Overview

Topic branch commands are dynamically generated based on your configuration. Default types include `feature`, `release`, `hotfix`, `support`, plus any custom types you define.

## start

Create and checkout a new topic branch of the specified type.

**Usage:**
```bash
git flow <topic> start <name> [base] [options]
```

**Arguments:**
- `topic` - The topic branch type (feature, release, hotfix, support, or custom type)
- `name` - Name of the new topic branch (without prefix)
- `base` - Optional base commit, tag, or branch to start from

**Options:**
- `--fetch` - Fetch from remote before creating branch
- `--no-fetch` - Don't fetch from remote (default)

**Examples:**
```bash
# Start a new feature
git flow feature start user-authentication

# Start a release
git flow release start 1.2.0

# Start feature from specific commit
git flow feature start emergency-fix abc123def

# Fetch latest changes before starting
git flow feature start new-api --fetch
```

## finish

Complete a topic branch by merging it to its parent branch according to the configured merge strategy.

**Usage:**
```bash
git flow <topic> finish [name] [options]
git flow finish [options]  # shorthand for current branch
```

**Operation Control:**
- `--continue, -c` - Continue after resolving merge conflicts
- `--abort, -a` - Abort operation and return to original state
- `--force, -f` - Force finish non-standard branch

**Tag Creation:**
- `--tag` - Create a tag for the finished branch
- `--notag` - Don't create a tag
- `--sign` - Sign the tag cryptographically with GPG
- `--signingkey <keyid>` - Use specific GPG key
- `--message, -m <message>` - Use given message for tag
- `--tagname <name>` - Use specific tag name

**Branch Retention:**
- `--keep` - Keep topic branch after finishing
- `--keepremote` - Keep remote tracking branch
- `--keeplocal` - Keep local branch
- `--force-delete` - Force delete even if not fully merged

**Merge Strategy Control:**
- `--rebase` - Rebase topic branch before merging
- `--squash` - Squash all commits into single commit
- `--no-rebase` - Don't rebase (use configured strategy)
- `--no-squash` - Keep individual commits
- `--preserve-merges` - Preserve merges during rebase
- `--no-ff` - Create merge commit even for fast-forward
- `--ff` - Allow fast-forward merge when possible

**Examples:**
```bash
# Finish current branch (shorthand)
git flow finish

# Finish specific feature
git flow feature finish user-authentication

# Finish release with signed tag
git flow release finish 1.2.0 --tag --sign

# Handle conflicts
git flow feature finish my-feature
# ... resolve conflicts ...
git flow feature finish my-feature --continue

# Force rebase strategy
git flow feature finish my-feature --rebase

# Squash all commits
git flow feature finish my-feature --squash
```

## list

List existing topic branches of the specified type.

**Usage:**
```bash
git flow <topic> list [pattern]
```

**Examples:**
```bash
# List all features
git flow feature list

# List all releases
git flow release list
```

## update

Update topic branch from its parent branch using the configured downstream strategy.

**Usage:**
```bash
git flow <topic> update [name]
git flow update [name]  # shorthand
```

**Examples:**
```bash
# Update current branch
git flow update

# Update specific feature
git flow feature update user-auth

# Update hotfix branch
git flow hotfix update critical-fix
```

## delete

Delete a topic branch (local and/or remote).

**Usage:**
```bash
git flow <topic> delete <name>
git flow delete [name]  # shorthand for current branch
```

**Examples:**
```bash
# Delete specific feature
git flow feature delete old-feature

# Delete current branch
git flow delete
```

## rename

Rename a topic branch.

**Usage:**
```bash
git flow <topic> rename <old-name> <new-name>
git flow rename [new-name]  # shorthand for current branch
```

**Examples:**
```bash
# Rename specific feature
git flow feature rename old-name new-name

# Rename current branch
git flow rename better-name
```

## checkout

Switch to a topic branch.

**Usage:**
```bash
git flow <topic> checkout <name|prefix>
```

**Examples:**
```bash
# Checkout specific feature
git flow feature checkout user-auth

# Partial match checkout
git flow feature checkout user
```

## Shorthand Commands

These commands work on the current branch or accept an optional branch name:

- `git flow delete [name]` - Delete current or specified topic branch
- `git flow update [name]` - Update current or specified topic branch from parent
- `git flow rebase [name]` - Rebase current or specified topic branch (alias for update --rebase)
- `git flow rename [new-name]` - Rename current topic branch
- `git flow finish [name]` - Finish current or specified topic branch

## Global Options

Available for all commands:

- `--verbose, -v` - Enable verbose output showing detailed operation information
- `--help, -h` - Show help information for any command
