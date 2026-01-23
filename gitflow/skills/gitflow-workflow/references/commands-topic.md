# git-flow-next topic branch commands

Topic branch commands are dynamically generated from configuration. Default types include `feature`, `release`, `hotfix`, `support`, plus any custom types.

## start

Create and checkout a new topic branch.

Usage:

`git-flow <topic> start <name> [base] [options]`

Options:

- `--fetch`: fetch from remote before creating branch
- `--no-fetch`: don’t fetch (default)

## finish

Complete a topic branch by merging it to its parent branch according to configured strategy.

Usage:

- `git-flow <topic> finish [name] [options]`
- `git-flow finish [options]` (shorthand for current branch)

Operation control:

- `--continue`, `-c`: continue after resolving conflicts
- `--abort`, `-a`: abort operation
- `--force`, `-f`: force finish non-standard branch

Tag creation:

- `--tag`: create a tag
- `--notag`: don’t create a tag
- `--sign`: sign the tag with GPG
- `--signingkey <keyid>`: use a specific key
- `--message`, `-m <message>`: tag message
- `--tagname <name>`: custom tag name

Branch retention:

- `--keep`: keep topic branch after finishing
- `--keepremote`: keep remote tracking branch
- `--keeplocal`: keep local branch
- `--force-delete`: force delete even if not fully merged

Merge strategy control:

- `--rebase`: rebase before merging
- `--squash`: squash commits into one
- `--squash-message <message>`: custom message for squash merge
- `--no-rebase`: don’t rebase (use configured strategy)
- `--no-squash`: keep individual commits
- `--preserve-merges`: preserve merges during rebase
- `--no-ff`: create merge commit even for fast-forward
- `--ff`: allow fast-forward

## publish

Push a topic branch to remote.

Usage:

- `git-flow <topic> publish [name]`
- `git-flow publish [name]` (shorthand for current branch)

## list

List existing topic branches.

Usage: `git-flow <topic> list [pattern]`

## update

Update a topic branch from its parent.

Usage:

- `git-flow <topic> update [name]`
- `git-flow update [name]` (shorthand)

## delete

Delete a topic branch.

Usage:

- `git-flow <topic> delete <name>`
- `git-flow delete [name]` (shorthand)

## rename

Rename a topic branch.

Usage:

- `git-flow <topic> rename <old-name> <new-name>`
- `git-flow rename [new-name]` (shorthand)

## checkout

Switch to a topic branch.

Usage: `git-flow <topic> checkout <name|prefix>`

## Shorthand commands

These work on the current branch or accept an optional branch name:

- `git-flow delete [name]`
- `git-flow update [name]`
- `git-flow rebase [name]` (alias for update `--rebase`)
- `git-flow rename [new-name]`
- `git-flow finish [name]`
- `git-flow publish [name]`

