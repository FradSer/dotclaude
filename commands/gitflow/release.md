# Git Flow Releases

Commands for managing release branches in git-flow.

## Start a release
```bash
git flow release start RELEASE [BASE]
```
- Creates a release branch from develop (or specified BASE)
- Use semantic versioning for release names (e.g., 1.2.0)

## Publish a release
```bash
git flow release publish RELEASE
```
Publishes the release branch to remote repository for team collaboration and testing.

## Finish a release
```bash
git flow release finish RELEASE
```
- Merges release branch into main/master
- Tags the release with version number
- Back-merges release into develop
- Removes the release branch

**Important:** Remember to push tags after finishing:
```bash
git push origin --tags
```

## Release workflow
1. Start release when develop has all features for next release
2. Only bug fixes and release preparations go into release branch
3. No new features should be added to release branch
4. Publish for team testing and final preparations
5. Finish when release is ready for production