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
# Check for issue templates
ls .github/ISSUE_TEMPLATE/*.md .github/ISSUE_TEMPLATE/*.yml 2>/dev/null
```

### Template Types

1. **Markdown Templates** (`.md` files): Contain YAML frontmatter with `name` and `about` keys
2. **Issue Forms** (`.yml` files): Use GitHub form schema with structured inputs

### Template Selection Logic

If issue templates exist:
1. List available templates using `gh issue create --list`
2. Match the issue type to the appropriate template
3. Use `gh issue create --template <template-name>` to apply the template
4. Ensure all required fields from the template are filled

If no templates exist, use the default issue structure from this skill.

## Pull Request Templates

PR templates can be stored in (in order of precedence):
1. `.github/PULL_REQUEST_TEMPLATE.md`
2. `PULL_REQUEST_TEMPLATE.md` (root directory)
3. `docs/PULL_REQUEST_TEMPLATE.md`
4. `.github/PULL_REQUEST_TEMPLATE/<name>.md` (multiple templates)

### Template Detection

```bash
# Check for PR templates
ls .github/PULL_REQUEST_TEMPLATE*.md PULL_REQUEST_TEMPLATE*.md docs/PULL_REQUEST_TEMPLATE*.md 2>/dev/null
```

### Template Application

If a PR template exists:
1. Read the template content
2. Ensure the PR body follows the template structure
3. Fill in all required sections from the template
4. Do not remove or modify template headers

If using `gh pr create`:
- GitHub automatically includes the template in the PR body
- Verify template sections are properly filled before submitting

## Template Compliance Checklist

Before creating issues or PRs:

- [ ] Checked for `CONTRIBUTING.md` and followed its guidelines
- [ ] Detected existing issue/PR templates
- [ ] Selected appropriate template if multiple exist
- [ ] Filled all required fields from the template
- [ ] Maintained template structure and headers
- [ ] Added content appropriate to each section

## Reference

- [Setting guidelines for repository contributors](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/setting-guidelines-for-repository-contributors)
- [About issue and pull request templates](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/about-issue-and-pull-request-templates)
