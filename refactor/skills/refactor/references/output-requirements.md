# Output Requirements and Summary Format

## Summary Structure

Provide a comprehensive summary after refactoring completes. Use this exact structure:

```
## Refactoring Summary

**Files Refactored**: <count>

### Changes Applied

<categorized list of changes>

### Best Practices Applied

<list of language/framework patterns used>

### Quality Standards Enforced

<list of standards verified>

### Legacy Code Removed

<list of deprecated code eliminated>

### Test Recommendations

<specific tests to run>

### Rollback Command

git checkout -- <file1> <file2> ...
```

## Detailed Section Requirements

### 1. Files Refactored

**Format**: Simple count

**Example**:
```
**Files Refactored**: 5
```

### 2. Changes Applied

**Format**: Grouped by improvement type with file references

**Categories**:
- Code cleanup (unused imports, variables, exports)
- Simplification (nested logic, complex patterns)
- Naming improvements (renamed misleading identifiers)
- Legacy removal (backwards-compatibility hacks)
- Framework optimizations (Next.js, React patterns)
- Performance improvements
- Type safety enhancements

**Example**:
```
### Changes Applied

**Code Cleanup**:
- Removed 12 unused imports across 5 files
- Deleted unused `_handleLegacyFormat` export in [auth/login.ts:45](auth/login.ts#L45)
- Removed commented-out validation code in [utils/validator.ts:23-31](utils/validator.ts#L23-L31)

**Simplification**:
- Replaced nested ternary with guard clauses in [components/Button.tsx:67](components/Button.tsx#L67)
- Extracted complex condition to `isValidUser` boolean in [middleware/auth.ts:89](middleware/auth.ts#L89)

**Naming Improvements**:
- Renamed `tmp` to `processedUserData` in [services/user.ts:34](services/user.ts#L34)
- Renamed `handler` to `handleLoginSubmit` in [auth/login.ts:12](auth/login.ts#L12)

**Next.js Optimizations**:
- Replaced `<img>` with `<Image>` for optimization in [components/Hero.tsx:23](components/Hero.tsx#L23)
- Added `priority` prop to above-fold images
```

### 3. Best Practices Applied

**Format**: List language/framework patterns with references

**Example**:
```
### Best Practices Applied

- **TypeScript**: Strict null checks, no `any` types, proper type guards
- **Next.js**: Image optimization, dynamic imports for code splitting
- **React**: Proper hook dependencies, memoization for expensive computations
- **Universal**: DRY principle, early returns, descriptive naming

Reference: refactor:best-practices skill
```

### 4. Quality Standards Enforced

**Format**: List standards with compliance status

**Example**:
```
### Quality Standards Enforced

- ✓ No unused imports, variables, or functions
- ✓ No backwards-compatibility hacks (`_var`, re-exports)
- ✓ No `any` types; proper type safety
- ✓ No defensive checks in trusted code paths
- ✓ Comments only for complex business logic
- ✓ Consistent style matching existing codebase
```

### 5. Legacy Code Removed

**Format**: List deprecated patterns with file references

**Example**:
```
### Legacy Code Removed

- Deleted unused `_validateLegacyFormat` function in [utils/validator.ts:67-82](utils/validator.ts#L67-L82)
- Removed re-export of deleted `OldAuthConfig` type in [types/index.ts:12](types/index.ts#L12)
- Eliminated `try-catch` around trusted internal function call in [services/user.ts:45](services/user.ts#L45)
```

If no legacy code removed:
```
### Legacy Code Removed

None detected in target scope.
```

### 6. Test Recommendations

**Format**: Specific test commands or manual verification steps

**Priority**:
1. Automated tests covering refactored files
2. Integration tests for multi-file changes
3. Manual verification for UI changes

**Example**:
```
### Test Recommendations

**Run Tests**:
\`\`\`bash
npm test auth.test.ts        # Tests for auth/login.ts changes
npm test validator.test.ts   # Tests for utils/validator.ts changes
npm run test:integration     # Full integration suite
\`\`\`

**Manual Verification**:
- Test login flow in browser (auth changes)
- Verify button rendering and interactions (Button component)
- Check image loading performance (Next.js Image optimizations)

**Visual Regression**:
- Run visual tests if available: `npm run test:visual`
```

### 7. Rollback Command

**Format**: Git command with all refactored files

**Example**:
```
### Rollback Command

If needed, revert all changes:

\`\`\`bash
git checkout -- src/auth/login.ts src/utils/validator.ts src/components/Button.tsx src/services/user.ts src/middleware/auth.ts
\`\`\`
```

## Edge Cases

### No Changes Made

If analysis determines no refactoring needed:

```
## Refactoring Summary

**Files Analyzed**: <count>

**Result**: No refactoring needed. All files already follow best practices and quality standards.

**Standards Verified**:
- ✓ No unused code detected
- ✓ Naming conventions followed
- ✓ Code complexity within acceptable limits
- ✓ Framework-specific optimizations already applied
```

### Partial Failures

If some files fail to refactor:

```
## Refactoring Summary

**Files Refactored**: <success count>
**Files Skipped**: <failure count>

### Skipped Files

- [path/to/file.ts](path/to/file.ts): <reason for skip>
- [path/to/other.ts](path/to/other.ts): <reason for skip>

<continue with normal summary for successful files>
```

## Formatting Guidelines

### Code References

Use markdown links for all file references:
- `[filename.ts:42](path/to/filename.ts#L42)` for specific lines
- `[filename.ts:42-51](path/to/filename.ts#L42-L51)` for ranges
- `[directory/](path/to/directory/)` for directories

### Code Blocks

Use syntax highlighting for commands:

```bash
npm test
```

```typescript
// code examples if needed
```

### Lists

Use:
- Unordered lists (`-`) for change descriptions
- Checkmarks (`✓`) for verified standards
- File references with line numbers for traceability

### Tone

- Factual and precise
- Action-oriented (past tense for completed changes)
- Specific (no vague "improved code quality")
- Helpful (clear test recommendations and rollback options)
