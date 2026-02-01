# PR Structure Requirements

## Title Guidelines

- Maximum 70 characters
- Use imperative mood
- No emojis
- Clear and descriptive

## Body Template

```markdown
## Summary
Brief description of changes and business impact

## Changes
- List of key modifications
- Technical details and rationale

## Related Issues
Fixes #123, Closes #456

## Testing
- [ ] Unit tests added/updated
- [ ] All tests pass
- [ ] Manual testing completed
- [ ] Edge cases covered

## Security & Quality
- [ ] No sensitive data exposed
- [ ] Input validation implemented
- [ ] Linting and type checking passed
- [ ] Build successful

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update
```

## Automated Labeling

Apply labels automatically based on file changes:

- `testing` - Test file modifications
- `documentation` - Documentation updates
- `dependencies` - Package file changes (package.json, requirements.txt, etc.)
- `security` - Security-related modifications
