# Git Flow Features

Commands for managing feature branches in git-flow.

## Start a new feature
```bash
git flow feature start MYFEATURE
```
Creates a new feature branch based on develop branch.

## Finish a feature
```bash
git flow feature finish MYFEATURE
```
- Merges feature branch into develop
- Removes the feature branch
- Switches back to develop branch

## Publish a feature
```bash
git flow feature publish MYFEATURE
```
Publishes the feature branch to remote repository for collaboration.

## Pull a published feature
```bash
git flow feature pull origin MYFEATURE
```
Gets latest changes for a published feature from remote.

## Track a feature
```bash
git flow feature track MYFEATURE
```
Tracks a remote feature branch that was started by another developer.

## Best practices
- Use descriptive feature names
- Keep features focused on single functionality
- Regularly sync with develop branch for long-running features