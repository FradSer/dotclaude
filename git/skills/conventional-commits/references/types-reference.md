# Commit Types and Footer Tokens Reference

Complete reference for conventional commit types and footer tokens.

## Standard Commit Types

- **`feat:`** - A new feature
- **`fix:`** - A bug fix
- **`docs:`** - Documentation only changes
- **`style:`** - Changes that do not affect the meaning of the code (white-space, formatting, etc.)
- **`refactor:`** - A code change that neither fixes a bug nor adds a feature
- **`perf:`** - A code change that improves performance
- **`test:`** - Adding missing tests or correcting existing tests
- **`build:`** - Changes that affect the build system or external dependencies
- **`ci:`** - Changes to CI configuration files and scripts
- **`chore:`** - Other changes that don't modify src or test files

## SemVer Correlation

- **`fix:`** → PATCH version
- **`feat:`** → MINOR version
- **BREAKING CHANGE** (any type) → MAJOR version

## Footer Tokens

### Issue References

- **`Closes #123`** - Closes the issue
- **`Fixes #456`** - Fixes a bug issue
- **`Refs: #789`** - Related but doesn't close

### Breaking Changes

- **`BREAKING CHANGE:`** - Indicates a breaking change (must be uppercase)

### Other Common Footers

- **`Reviewed-by: Name`** - Code reviewer
- **`Co-authored-by: Name <email>`** - Co-author
- **`Signed-off-by: Name <email>`** - Developer's certificate of origin

## Footer Format

Footers follow git trailer format:
- Token followed by `:` and space, or space and `#`
- Example: `Closes #123` or `Reviewed-by: Z`
- Multiple footers separated by blank lines or newlines
