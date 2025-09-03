# Git Flow Hotfixes

Commands for managing critical production fixes following GitHub best practices.

## AI Instructions for Hotfix Management

### Starting a hotfix
1. **Identify and document the critical issue**:
   - Create GitHub issue for tracking
   - Assess severity and impact
   - Determine if this truly requires a hotfix vs. regular release

2. **Ensure repository is up-to-date**:
   ```bash
   git status
   git fetch origin
   git checkout main
   git pull origin main
   git status
   # Verify this is the current production version
   ```

3. **Determine hotfix version** (increment patch version):
   ```bash
   # If current production is 1.2.0, hotfix should be 1.2.1
   git flow hotfix start 1.2.1
   ```

4. **Immediately publish for team awareness**:
   ```bash
   git flow hotfix publish 1.2.1
   ```

### Working on a hotfix
1. **Analyze the issue and locate the problem**:
   ```bash
   # Review the issue details and identify affected files
   # Use search tools to locate the problematic code
   git grep "problematic_function" 
   # or use IDE/editor search functionality
   ```

2. **Make minimal, focused code changes**:
   - **MUST**: Fix only the critical issue - no other changes
   - **MUST**: Modify the minimum amount of code necessary
   - **MUST**: Avoid refactoring, optimization, or new features
   - **MUST**: Test the specific fix immediately after each change
   
   **Example workflow**:
   - Read the problematic file
   - Identify the exact lines causing the issue
   - Make targeted fix (usually 1-5 lines of code)
   - Verify the fix doesn't break existing functionality

3. **Commit each logical fix immediately**:
   ```bash
   git add [specific_fixed_files]
   git commit -m "fix: resolve critical [specific issue description]"
   git push origin hotfix/VERSION
   ```
   
   **Commit Requirements:**
   - Commit message title must be entirely lowercase
   - Title must be less than 50 characters
   - Follow conventional commits format (feat:, fix:, chore:, etc.)
   - Use atomic commits for logical units of work

4. **Test thoroughly but quickly**:
   ```bash
   # Test the specific bug scenario first
   # Run targeted tests for the affected area
   npm test -- --grep "affected_module"
   # Run full test suite if time permits
   npm test
   # Verify no regressions in related functionality
   ```

### Finishing a hotfix
1. **Final verification**:
   ```bash
   git status
   # Ensure fix is complete and tested
   # Verify no unintended changes
   ```

2. **Update version and changelog**:
   ```bash
   # Update package version (choose appropriate package manager)
   # For Node.js projects:
   npm version patch --no-git-tag-version
   # For Python projects with pyproject.toml:
   # Update version field in pyproject.toml manually
   # For other package managers, update version accordingly
   
   # Update CHANGELOG.md
   # Add entry under "## [1.2.1] - YYYY-MM-DD" section:
   # - Fixed: [Brief description of the critical fix]
   # - Security: [If security-related fix]
   ```

3. **Commit version updates**:
   ```bash
   git add package.json CHANGELOG.md  # adjust files as needed
   git commit -m "chore: bump version to 1.2.1 for hotfix"
   ```

4. **Finish the hotfix**:
   ```bash
   git flow hotfix finish 1.2.1
   ```
   Use descriptive tag message explaining the critical fix.

5. **Immediately push all changes**:
   ```bash
   git push origin main
   git push origin develop
   git push origin --tags
   ```

6. **Create emergency GitHub release**:
   ```bash
   gh release create v1.2.1 --title "Hotfix 1.2.1 - Critical Security Fix" --notes "Fixes critical security vulnerability in authentication system"
   ```

7. **Deploy to production immediately**:
   ```bash
   # Trigger deployment pipeline or manual deployment
   # Document deployment in incident tracking
   ```

## Alternative: GitHub Emergency Workflow
For organizations requiring PR reviews even for hotfixes:

1. **Create emergency PR**:
   ```bash
   gh pr create --title "HOTFIX: Critical security fix" --body "Emergency fix for production issue #123" --base main --label "hotfix,urgent"
   ```

2. **Fast-track review process**:
   - Request immediate review from senior developers
   - Use emergency approval process if available
   - Override normal review requirements if necessary

3. **After emergency merge**:
   ```bash
   git checkout main
   git pull origin main
   git tag v1.2.1
   git push origin v1.2.1
   
   # Ensure fix is in develop
   git checkout develop
   git merge main
   git push origin develop
   ```

## Hotfix Checklist
- [ ] Critical production issue confirmed
- [ ] Hotfix version number determined (patch increment)
- [ ] Fix is minimal and targeted
- [ ] Tests confirm fix works
- [ ] No unintended side effects
- [ ] Security review completed (if security-related)
- [ ] Deployment plan ready
- [ ] Incident tracking updated
- [ ] Team and stakeholders notified

## Communication Template
```
PRODUCTION HOTFIX ALERT

Issue: [Brief description]
Severity: Critical
Version: 1.2.1
ETA: [Estimated deployment time]
Affected: [What systems/users are affected]
Status: [In Progress/Testing/Deploying/Complete]

Next update in: [Time]
```

## Post-Hotfix Actions
1. **Verify fix in production**:
   ```bash
   # Monitor production logs
   # Verify issue is resolved
   # Check for any new issues
   ```

2. **Root cause analysis**:
   - Document how the issue occurred
   - Identify prevention measures
   - Update development processes if needed

3. **Create follow-up tasks**:
   - Improve test coverage for this scenario
   - Consider if similar issues exist elsewhere
   - Plan preventive measures

## Error Handling
- If hotfix finish fails, resolve merge conflicts immediately
- If deployment fails, have rollback plan ready
- If new issues arise, consider rollback and new hotfix
- Document all emergency decisions for post-incident review

## Best Practices
- Use hotfixes sparingly - only for critical issues
- Keep hotfix lifetime under 4 hours when possible
- Always test the fix, even under pressure
- Communicate clearly and frequently during hotfix process
- Learn from each hotfix to prevent similar issues
- Consider automated hotfix deployment pipelines for speed