# git-flow-next core commands

This reference contains the core commands used to initialize and configure git-flow-next.

## Global options

- `--verbose`, `-v`: enable verbose output
- `--help`, `-h`: show help for any command

## init

Initialize git-flow configuration in the current Git repository.

Usage:

`git-flow init [--preset=preset] [--custom] [--defaults] [options]`

Options:

- `--preset=preset`: apply a workflow preset (`classic`, `github`, `gitlab`)
- `--custom`: enable custom configuration mode
- `--defaults`, `-d`: use defaults without prompting
- `--no-create-branches`: don’t create branches even if missing
- `--main=name`: override main branch name (default: main)
- `--develop=name`: override develop branch name (default: develop)
- `--production=name`: override production branch name for GitLab flow (default: production)
- `--staging=name`: override staging branch name for GitLab flow (default: staging)
- `--feature=prefix`: override feature prefix (default: feature/)
- `--bugfix=prefix`, `-b prefix`: override bugfix prefix (default: bugfix/)
- `--release=prefix`, `-r prefix`: override release prefix (default: release/)
- `--hotfix=prefix`, `-x prefix`: override hotfix prefix (default: hotfix/)
- `--support=prefix`, `-s prefix`: override support prefix (default: support/)
- `--tag=prefix`, `-t prefix`: override tag prefix (default: v)

## config

Manage git-flow configuration for base branches and topic branch types.

Usage:

`git-flow config <command> [args] [options]`

Commands:

- `list`
- `add base <name> [parent]`
- `add topic <name> <parent>`
- `edit base <name>`
- `edit topic <name>`
- `rename base <old-name> <new-name>`
- `rename topic <old-name> <new-name>`
- `delete base <name>`
- `delete topic <name>`

Base branch options:

- `--upstream-strategy=strategy`: merge strategy when merging to parent (`merge`, `rebase`, `squash`)
- `--downstream-strategy=strategy`: merge strategy when updating from parent (`merge`, `rebase`)
- `--auto-update[=bool]`: auto-update from parent on finish (default: false)

Topic branch options:

- `--prefix=prefix`: branch name prefix (default: `name/`)
- `--starting-point=branch`: branch to create from (defaults to parent)
- `--upstream-strategy=strategy`
- `--downstream-strategy=strategy`
- `--tag[=bool]`: create tags on finish (default: false)

## overview

Display repository workflow overview showing current git-flow configuration and all active topic branches.

Usage: `git-flow overview`

## version

Show version information for git-flow-next.

Usage: `git-flow version`

## completion

Generate shell completion script for bash, zsh, fish, or PowerShell.

Usage: `git-flow completion [shell]`

Available shells: `bash`, `zsh`, `fish`, `powershell`

## Configuration namespace

git-flow-next stores settings under `gitflow.*` in Git config. Precedence is typically:

1. Branch type defaults (`gitflow.branch.*`)
2. Command overrides (`gitflow.type.command.*`)
3. CLI flags (highest precedence)

## git-flow-avh compatibility

git-flow-next can detect and translate git-flow-avh configuration at runtime without modifying existing settings.

