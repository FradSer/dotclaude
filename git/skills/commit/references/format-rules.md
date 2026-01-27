# Conventional Commits Format Rules

Complete specification for conventional commit messages following Commitizen (cz) style and v1.0.0 specification.

## Message Structure

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## Title Rules

- **ALL LOWERCASE** (no capitalization in description)
- **<50 characters** total length
- **Imperative mood** (e.g., "add" not "added")
- **No period at end**
- **Breaking changes**: Add "!" before ":" (e.g., `feat!:`, `feat(api)!:`)

### Common Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `perf`: Performance improvement
- `test`: Adding or correcting tests
- `chore`: Routine task or maintenance
- `build`: Changes to build system or dependencies
- `ci`: Continuous integration changes
- `style`: Code style changes (formatting, missing semi-colons, etc.)

## Body Rules (Mandatory)

- **Body is REQUIRED** - all commits must include bullet points
- **Blank line after title** (mandatory separator)
- **≤72 characters per line**
- **Bullet points format**:
  - Use `- ` prefix (dash + space)
  - Start with imperative verb (Add, Remove, Update, Fix, Refactor, Implement)
  - Each bullet describes a specific change
- **Optional paragraphs**:
  - Context paragraph BEFORE bullets explains background
  - Explanation paragraph AFTER bullets provides impact/reasoning

### Valid Body Formats

**Simple (bullet points only)**:
```
- <Action> <component> <detail>
- <Action> <component> <detail>
```

**With explanation after**:
```
- <Action> <component> <detail>
- <Action> <component> <detail>

<Explanation of impact or benefit>.
```

**With context before**:
```
<Background context explaining why changes are needed>.

- <Action> <component> <detail>
- <Action> <component> <detail>

<Summary of what this resolves>.
```

**Complex example**:
```
<Background context providing problem statement>.

- <Action> <component> <detail>
- <Action> <component> <detail>
- <Action> <component> <detail>
- <Action> <component> <detail>

<Explanation of multiple impacts and benefits>.
```

## Footer (Optional)

Blank line after body, then optionally add footers:

### Issue References
- `Closes #123` - Closes a single issue
- `Fixes #456` - Fixes a bug report
- `Resolves #789` - Resolves an issue
- `Closes #123, #456` - Multiple issues

### Breaking Changes
```
BREAKING CHANGE: <description>
```
- Describes what broke and migration steps
- Should also have ! in title (e.g., `feat!:`)

### Co-Authorship
```
Co-Authored-By: Name <email>
```
- **REQUIRED** for all Claude Code commits
- Standard attribution: `Co-Authored-By: <Model Name> <noreply@anthropic.com>`

## Complete Examples

### Feature Commit
```
feat(<scope>): <description of new feature>

- <Action> <component> <detail>
- <Action> <component> <detail>
- <Action> <component> <detail>

Co-Authored-By: <Model Name> <noreply@anthropic.com>
```

### Bug Fix with Context
```
fix(<scope>): <description of fix>

<Background context explaining the problem>.

- <Action> <component> <detail>
- <Action> <component> <detail>
- <Action> <component> <detail>

<Explanation of what this resolves>.

Fixes #<issue-number>
Co-Authored-By: <Model Name> <noreply@anthropic.com>
```

### Breaking Change
```
<type>(<scope>)!: <description of breaking change>

- <Action> <component> <detail>
- <Action> <component> <detail>
- <Action> <component> <detail>
- <Action> <component> <detail>

BREAKING CHANGE: <Description of what changed>.
<Migration instructions or guidance>.
See <reference to migration documentation>.

Co-Authored-By: <Model Name> <noreply@anthropic.com>
```

### Refactoring
```
refactor(<scope>): <description of refactoring>

- <Action> <component> <detail>
- <Action> <component> <detail>
- <Action> <component> <detail>

<Explanation of improvements and benefits>.

Co-Authored-By: <Model Name> <noreply@anthropic.com>
```

## Validation Checklist

Before committing, verify:

- [ ] Title is ALL LOWERCASE
- [ ] Title is <50 characters
- [ ] Title uses imperative mood
- [ ] Title has no trailing period
- [ ] Blank line separates title from body
- [ ] Body includes at least one bullet point
- [ ] All bullets start with imperative verb
- [ ] Body lines are ≤72 characters
- [ ] Footer includes Co-Authored-By
- [ ] Breaking changes marked with ! in title AND BREAKING CHANGE footer
