# Repository Templates and Guidelines

Projects may define templates and guidelines that must be followed when creating issues and pull requests.

## Contributing Guidelines

Check for `CONTRIBUTING.md` in these locations (in order of precedence):
1. `.github/CONTRIBUTING.md`
2. `CONTRIBUTING.md` (root directory)
3. `docs/CONTRIBUTING.md`

If the file exists, read and follow its guidelines before creating issues or PRs.

## Issue Templates

Issue templates are stored in `.github/ISSUE_TEMPLATE/` directory.

### Template Detection

```bash
ls .github/ISSUE_TEMPLATE/*.md .github/ISSUE_TEMPLATE/*.yml 2>/dev/null
```

### Template Types

1. **Markdown Templates** (`.md` files): YAML frontmatter with `name` and `about` keys
2. **Issue Forms** (`.yml` files): GitHub form schema with structured inputs and validation

### Template Selection

If templates exist:
1. List available templates: `gh issue create --list`
2. Match issue type to appropriate template
3. Use `gh issue create --template <name>` to apply
4. Fill all required fields

If no templates exist, use default issue structure from this skill.

## Pull Request Templates

PR templates can be stored in (in order of precedence):
1. `.github/PULL_REQUEST_TEMPLATE.md`
2. `PULL_REQUEST_TEMPLATE.md` (root directory)
3. `docs/PULL_REQUEST_TEMPLATE.md`
4. `.github/PULL_REQUEST_TEMPLATE/<name>.md` (multiple templates)

### Template Detection

```bash
ls .github/PULL_REQUEST_TEMPLATE*.md PULL_REQUEST_TEMPLATE*.md 2>/dev/null
```

### Template Application

If a PR template exists:
1. Read the template content
2. Follow the template structure
3. Fill in all sections
4. Do not remove template headers

GitHub automatically includes the template when using `gh pr create`.

## Compliance Checklist

- [ ] Checked `CONTRIBUTING.md` and followed guidelines
- [ ] Detected and used existing templates
- [ ] Filled all required fields
- [ ] Maintained template structure

## Reference

- [About issue and pull request templates](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/about-issue-and-pull-request-templates)
- [Syntax for issue forms](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms)
