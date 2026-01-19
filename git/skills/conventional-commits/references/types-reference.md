# Commit Types and Footer Tokens

## Commit Types

- **`feat:`** - New feature
- **`fix:`** - Bug fix
- **`docs:`** - Documentation changes
- **`refactor:`** - Code change that neither fixes bug nor adds feature
- **`perf:`** - Performance improvement
- **`test:`** - Adding or correcting tests
- **`build:`** - Build system or dependencies
- **`ci:`** - CI configuration
- **`chore:`** - Other changes (not src/test)
- **`style:`** - Formatting, white-space (no code meaning change)

## SemVer

- `fix:` → PATCH
- `feat:` → MINOR
- BREAKING CHANGE → MAJOR

## Footer Tokens

**Issue References:**
- `Closes #123` - Closes issue
- `Fixes #456` - Fixes bug issue
- `Refs: #789` - Related but doesn't close

**Breaking Changes:**
- `BREAKING CHANGE: <description>` - Must be uppercase

**Other:**
- `Reviewed-by: Name`
- `Co-authored-by: Name <email>`
- `Signed-off-by: Name <email>`

**Format:** Token followed by `:` and space, or space and `#`. Multiple footers separated by blank lines.
