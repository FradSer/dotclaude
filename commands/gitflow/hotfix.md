# Git Flow Hotfixes

Commands for managing hotfix branches in git-flow for critical production fixes.

## Start a hotfix
```bash
git flow hotfix start VERSION [BASENAME]
```
- Creates a hotfix branch from main/master (or specified BASENAME)
- Use version number that reflects the urgency (e.g., 1.2.1)

## Finish a hotfix
```bash
git flow hotfix finish VERSION
```
- Merges hotfix branch into main/master
- Tags the hotfix with version number
- Back-merges hotfix into develop
- Removes the hotfix branch

**Important:** Remember to push tags and branches after finishing:
```bash
git push origin --tags
git push origin main
git push origin develop
```

## Hotfix workflow
1. Start hotfix when critical bug is found in production
2. Make minimal changes necessary to fix the issue
3. Test thoroughly before finishing
4. Finish to deploy fix to production immediately
5. Hotfix automatically integrates back into develop for future releases

## Best practices
- Use hotfixes only for critical production issues
- Keep changes minimal and focused
- Document the issue and fix thoroughly
- Consider if the same issue exists in develop branch