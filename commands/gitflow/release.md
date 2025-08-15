# Git Flow Releases

Commands for managing release branches following GitHub best practices and semantic versioning.

## AI Instructions for Release Management

### Starting a release
1. **Ensure repository is up-to-date**:
   ```bash
   git status
   git fetch origin
   git checkout develop
   git pull origin develop
   git status
   # Ensure all intended features are merged
   ```

2. **Determine version number** using Semantic Versioning (semver):
   - **Major** (X.y.z): Breaking changes that are not backward compatible
   - **Minor** (x.Y.z): New features that are backward compatible
   - **Patch** (x.y.Z): Bug fixes that are backward compatible
   
   **AI should analyze the changes since last release to determine appropriate version bump:**
   - Review git log and merged features
   - Check for breaking changes in API/behavior
   - Identify new features vs bug fixes
   - Consider deprecations and removals

3. **Start release branch**:
   ```bash
   # First, analyze changes to determine version (AI responsibility)
   git log --oneline $(git describe --tags --abbrev=0)..develop
   git diff $(git describe --tags --abbrev=0)..develop --name-only
   
   # Then start release with determined version
   git flow release start VERSION
   # AI should replace VERSION with appropriate semver (e.g., 1.2.0)
   ```

4. **Immediately publish for team collaboration**:
   ```bash
   git flow release publish VERSION
   ```

### Working on a release
1. **Only make release-specific changes**:
   - Update version numbers in package.json, setup.py, etc.
   - Update CHANGELOG.md following "Keep a Changelog" format
   - Fix critical bugs found during testing
   - Update documentation

2. **Update CHANGELOG.md** (if exists, following Keep a Changelog format):
   ```bash
   # Move items from [Unreleased] to new version section
   # Example format:
   ## [1.2.0] - 2024-01-15
   ### Added
   - New feature descriptions
   
   ### Changed
   - Modified functionality descriptions
   
   ### Deprecated
   - Features marked for removal
   
   ### Removed
   - Deleted features
   
   ### Fixed
   - Bug fix descriptions
   
   ### Security
   - Security improvements
   ```

3. **Commit changes with clear messages**:
   ```bash
   git add .
   git commit -m "chore: bump version to 1.2.0 and update changelog"
   git push origin release/1.2.0
   ```

4. **Run comprehensive testing**:
   ```bash
   # Run all tests
   npm test
   # Run integration tests
   npm run test:integration
   # Build and verify
   npm run build
   ```

### Finishing a release
1. **Final verification before finish**:
   ```bash
   git status
   # Ensure all tests pass
   npm test
   # Verify version numbers are correct
   ```

2. **Finish the release**:
   ```bash
   git flow release finish VERSION
   ```
   This will prompt for tag message - use meaningful description.

3. **Push all changes and tags**:
   ```bash
   git push origin main
   git push origin develop
   git push origin --tags
   ```

4. **Create GitHub release** (recommended):
   ```bash
   gh release create v1.2.0 --title "Release 1.2.0" --notes-file CHANGELOG.md
   ```

## Alternative: GitHub Release Workflow
For better integration with GitHub features:

1. **Create release PR instead of direct finish**:
   ```bash
   # Create PR from release/1.2.0 to main
   gh pr create --title "Release 1.2.0" --body "Release preparation" --base main
   ```

2. **After PR approval and merge**:
   ```bash
   # Create release tag
   git checkout main
   git pull origin main
   git tag v1.2.0
   git push origin v1.2.0
   
   # Merge back to develop
   git checkout develop
   git merge main
   git push origin develop
   ```

## Release Checklist
- [ ] All intended features are in develop
- [ ] **Version number determined via Semantic Versioning analysis**:
  - [ ] Analyzed git log since last release
  - [ ] Identified breaking changes (→ Major bump)
  - [ ] Identified new features (→ Minor bump)
  - [ ] Identified bug fixes only (→ Patch bump)
- [ ] CHANGELOG.md updated following "Keep a Changelog" format
- [ ] All tests pass
- [ ] Documentation is updated
- [ ] Version numbers in files are updated
- [ ] Security vulnerabilities are addressed
- [ ] Performance benchmarks are acceptable

## Version Management
Update these files typically:
- `package.json` (Node.js)
- `setup.py` (Python)
- `Cargo.toml` (Rust)
- `pom.xml` (Java)
- `CHANGELOG.md`
- Documentation files

## Error Handling
- If release finish fails, check for merge conflicts
- If tagging fails, ensure you have push permissions
- Use `git flow release delete VERSION` to remove unwanted releases
- If version already exists, use next patch version

## Best Practices
- Keep release branches short-lived (1-2 weeks max)
- Use release candidates for major releases (1.2.0-rc.1)
- Always test release branch thoroughly before finishing
- Coordinate release timing with team and stakeholders
- Use GitHub Actions for automated release processes