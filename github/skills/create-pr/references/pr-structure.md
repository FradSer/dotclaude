# PR Structure Requirements

## Title

- Maximum 70 characters
- Imperative mood, no emojis
- Pattern: `type(scope): description` (e.g., `feat(auth): add oauth support`)

## Body Template

```markdown
## Summary
Brief description of changes and business impact

## Changes
- Key modification 1
- Key modification 2

## Related Issues
Fixes #123

## Testing
- [ ] Unit tests added/updated
- [ ] All tests pass
- [ ] Manual testing completed

## Checklist
- [ ] No sensitive data exposed
- [ ] Linting and type checking passed
- [ ] Documentation updated (if applicable)
- [ ] Breaking changes documented (if applicable)
```

## Automated Labeling

| Label | Trigger Files |
|-------|---------------|
| `testing` | `*.test.*`, `*.spec.*`, `__tests__/*` |
| `documentation` | `*.md`, `docs/*` |
| `dependencies` | `package.json`, `requirements.txt`, `Cargo.toml` |

## Best Practices

1. Keep PRs small (<400 lines when possible)
2. One logical change per PR
3. Self-review before requesting review
4. Include tests for new functionality

## Template Compliance

When project has a PR template:
1. Read from `.github/PULL_REQUEST_TEMPLATE.md`
2. Preserve all section headers
3. Fill all sections (use "N/A" if not applicable)
