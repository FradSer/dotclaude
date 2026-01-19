# git-flow-next Core Commands

Core commands for initializing, configuring, and managing git-flow-next in your repository. Based on [official documentation](https://git-flow.sh/docs/commands/) and cheat sheet.

## init

Initialize git-flow configuration in the current Git repository.

**Usage:**
```bash
git flow init [--preset=preset] [--custom] [--defaults] [options]
```

**Options:**
- `--preset=preset` - Apply predefined workflow preset (`classic`, `github`, `gitlab`)
- `--custom` - Enable custom configuration mode
- `--defaults, -d` - Use default branch naming without prompting
- `--no-create-branches` - Don't create branches even if they don't exist
- `--main=name` - Override main branch name (default: main)
- `--develop=name` - Override develop branch name (default: develop)
- `--production=name` - Override production branch name for GitLab flow
- `--staging=name` - Override staging branch name for GitLab flow
- `--feature=prefix` - Override feature branch prefix (default: feature/)
- `--bugfix=prefix, -b prefix` - Override bugfix branch prefix (default: bugfix/)
- `--release=prefix, -r prefix` - Override release branch prefix (default: release/)
- `--hotfix=prefix, -x prefix` - Override hotfix branch prefix (default: hotfix/)
- `--support=prefix, -s prefix` - Override support branch prefix (default: support/)
- `--tag=prefix, -t prefix` - Override version tag prefix (default: v)

**Examples:**
```bash
# Interactive initialization
git flow init

# Initialize with Classic GitFlow preset
git flow init --preset=classic

# Initialize with defaults without prompting
git flow init --defaults

# GitHub Flow with custom main branch
git flow init --preset=github --main=master
```

## config

Manage git-flow configuration for base branches and topic branch types.

**Usage:**
```bash
git flow config <command> [args] [options]
```

**Commands:**
- `list` - Display current git-flow configuration
- `add base <name> [parent]` - Add a base branch configuration
- `add topic <name> <parent>` - Add a topic branch type configuration
- `edit base <name>` - Edit an existing base branch configuration
- `edit topic <name>` - Edit an existing topic branch type configuration
- `rename base <old-name> <new-name>` - Rename a base branch
- `rename topic <old-name> <new-name>` - Rename a topic branch type
- `delete base <name>` - Delete a base branch configuration
- `delete topic <name>` - Delete a topic branch type configuration

**Base Branch Options:**
- `--upstream-strategy=strategy` - Merge strategy when merging to parent (`merge`, `rebase`, `squash`)
- `--downstream-strategy=strategy` - Merge strategy when updating from parent (`merge`, `rebase`)
- `--auto-update[=bool]` - Auto-update from parent on finish (default: false)

**Topic Branch Options:**
- `--prefix=prefix` - Branch name prefix (default: `name/`)
- `--starting-point=branch` - Branch to create from (defaults to parent)
- `--upstream-strategy=strategy` - Merge strategy when merging to parent
- `--downstream-strategy=strategy` - Merge strategy when updating from parent
- `--tag[=bool]` - Create tags on finish (default: false)

**Examples:**
```bash
# List current configuration
git flow config list

# Add production trunk branch
git flow config add base production

# Add feature branch type with custom prefix
git flow config add topic feature develop --prefix=feat/

# Edit feature branches to use rebase when finishing
git flow config edit topic feature --upstream-strategy=rebase
```

## overview

Display repository workflow overview showing current git-flow configuration and all active topic branches.

**Usage:**
```bash
git flow overview
```

## version

Show version information for git-flow-next.

**Usage:**
```bash
git flow version
```

## Configuration

git-flow-next uses Git's configuration system, storing settings under the `gitflow.*` namespace. Configuration follows a three-layer hierarchy:

1. **Branch Type Defaults** (`gitflow.branch.*`) - Default behavior for branch types
2. **Command Overrides** (`gitflow.<type>.<command>.*`) - Override defaults for specific operations
3. **Command-line Flags** - Always take highest precedence

## Git-flow-avh Compatibility

git-flow-next automatically detects and translates git-flow-avh configuration at runtime without modifying existing settings. Legacy configuration is mapped to the new format transparently.

## Global Options

Available for all commands:

- `--verbose, -v` - Enable verbose output showing detailed operation information
- `--help, -h` - Show help information for any command
