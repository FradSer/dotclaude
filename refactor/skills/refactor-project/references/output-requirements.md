# Project-Wide Refactoring Summary Requirements

## Summary Structure

Provide a comprehensive summary after project-wide refactoring completes. Use this structure:

```
## Project-Wide Refactoring Summary

**Files Refactored**: <count> (<percentage>% of project)

### Changes Applied

<categorized list with file counts>

### Cross-File Improvements

<specific consolidations and consistency changes>

### Best Practices Applied

<list of language/framework patterns used>

### Quality Standards Enforced

<list of standards verified>

### Legacy Code Removed

<list of deprecated code eliminated>

### Test Recommendations

<comprehensive test suite suggestions>

### Review Recommendations

<suggested review order and groupings>

### Rollback Command

git reset --hard HEAD
```

## Detailed Section Requirements

### 1. Files Refactored

**Format**: Count with percentage

**Example**:
```
**Files Refactored**: 42 files (68% of project)
```

**Calculation**:
- Percentage = (refactored files / total project files) × 100
- Include only files that were actually modified

### 2. Changes Applied

**Format**: Same as file-level refactoring, but include file counts per category

**Example**:
```
### Changes Applied

**Code Cleanup** (35 files):
- Removed 127 unused imports across 35 files
- Deleted 8 unused utility functions
- Removed 15 commented-out code blocks

**Simplification** (22 files):
- Replaced 18 nested ternaries with guard clauses
- Extracted 12 complex conditions to named boolean variables
- Simplified 6 overly defensive null checks

**Naming Improvements** (15 files):
- Renamed 23 misleading identifiers to descriptive names
- Standardized 8 inconsistent function names across files

**TypeScript Best Practices** (28 files):
- Replaced 12 `any` types with proper types
- Added 15 missing type guards
- Improved 8 type definitions for better inference

**Next.js Optimizations** (10 files):
- Replaced 6 `<img>` tags with `<Image>` components
- Added dynamic imports to 4 heavy components
```

### 3. Cross-File Improvements

**NEW SECTION** - Specific to project-wide refactoring

**Format**: List consolidations and consistency changes with before/after file counts

**Example**:
```
### Cross-File Improvements

**Duplication Consolidation**:
- Consolidated 3 duplicate `formatDate` implementations into shared [utils/date.ts](utils/date.ts)
- Merged 2 similar validation functions from [services/auth.ts](services/auth.ts) and [services/user.ts](services/user.ts) into [utils/validation.ts](utils/validation.ts)
- Removed 5 duplicate type definitions, centralized in [types/common.ts](types/common.ts)

**Naming Consistency** (12 files affected):
- Standardized user data fetching: `getUserInfo` → `getUserData` across 4 files
- Unified error handling function names: `handleErr` / `onError` → `handleError` across 8 files

**Pattern Consistency** (18 files affected):
- Standardized import style: `import * as React` → `import React` across all React files
- Unified error handling in services: all now throw errors instead of mixed approaches
- Consistent async/await usage: removed Promise chains in favor of async/await
```

### 4. Best Practices Applied

**Format**: Same as file-level, but note project-wide application

**Example**:
```
### Best Practices Applied

- **TypeScript**: Strict null checks, no `any` types, proper type guards
- **Next.js**: Image optimization, dynamic imports, proper hydration patterns
- **React**: Proper hook dependencies, memoization, consistent component patterns
- **Universal**: DRY principle (cross-file), early returns, descriptive naming

Applied consistently across all 42 refactored files.

Reference: refactor:best-practices skill
```

### 5. Quality Standards Enforced

**Format**: List standards with compliance status, note project-wide scope

**Example**:
```
### Quality Standards Enforced

✓ No unused imports, variables, or functions project-wide
✓ No backwards-compatibility hacks (`_var`, re-exports)
✓ No `any` types; proper type safety throughout
✓ No defensive checks in trusted code paths
✓ Comments only for complex business logic
✓ Consistent style matching project conventions
✓ Uniform error handling patterns across services
✓ Standardized naming conventions project-wide
```

### 6. Legacy Code Removed

**Format**: Same as file-level, but note if cross-file cleanup occurred

**Example**:
```
### Legacy Code Removed

**Unused Utilities** (cross-file cleanup):
- Deleted `formatLegacyDate` from [utils/date.ts:45-67](utils/date.ts#L45-L67) (no longer used anywhere)
- Removed `validateOldFormat` from [utils/validation.ts:23-41](utils/validation.ts#L23-L41) (replaced project-wide)

**Backwards Compatibility Shims**:
- Removed `_handleOldAPI` exports from 3 service files
- Deleted deprecated type re-exports from [types/index.ts](types/index.ts)

**Dead Code**:
- Removed 8 unreachable error handlers in [services/](services/)
- Deleted 4 unused internal functions
```

### 7. Test Recommendations

**Format**: Comprehensive suite recommendation with grouped tests

**Example**:
```
### Test Recommendations

**Full Test Suite**:
\`\`\`bash
npm test                    # Run all tests
npm run test:integration    # Integration tests
npm run test:e2e            # End-to-end tests
\`\`\`

**Grouped by Area** (for incremental verification):

**Authentication & User** (highest priority):
\`\`\`bash
npm test auth.test.ts user.test.ts session.test.ts
\`\`\`

**UI Components**:
\`\`\`bash
npm test -- components/
\`\`\`

**Services & API**:
\`\`\`bash
npm test -- services/
\`\`\`

**Manual Verification**:
- Test complete user flow from login to checkout
- Verify image loading performance (Next.js Image optimizations)
- Check error handling in edge cases

**Visual Regression**:
\`\`\`bash
npm run test:visual    # If available
\`\`\`
```

### 8. Review Recommendations

**NEW SECTION** - Specific to project-wide refactoring

**Format**: Suggested review order and logical groupings

**Example**:
```
### Review Recommendations

Suggest reviewing changes in this order:

**1. Cross-File Changes First** (highest impact):
- Review consolidated utilities in [utils/](utils/)
- Check standardized naming changes across files
- Verify consistent patterns in [services/](services/)

**2. Feature Areas** (group by domain):
- **Authentication**: [services/auth.ts](services/auth.ts), [middleware/auth.ts](middleware/auth.ts), [types/auth.ts](types/auth.ts)
- **User Management**: [services/user.ts](services/user.ts), [components/UserProfile.tsx](components/UserProfile.tsx)
- **UI Components**: [components/](components/) directory

**3. Infrastructure & Utilities**:
- [utils/](utils/) directory
- [types/](types/) directory

**4. Tests**:
- [tests/](tests/) directory

**Review Tips**:
- Focus on cross-file consistency changes
- Verify public API signatures remain unchanged
- Check that consolidated utilities are imported correctly
```

### 9. Rollback Command

**Format**: Git reset command (hard reset for project-wide changes)

**Example**:
```
### Rollback Command

If needed, revert all project-wide changes:

\`\`\`bash
git reset --hard HEAD
\`\`\`

**Create a backup branch first** (recommended):

\`\`\`bash
git branch backup-before-refactor HEAD
git reset --hard HEAD
\`\`\`

To restore after rollback:
\`\`\`bash
git cherry-pick backup-before-refactor
\`\`\`
```

## Edge Cases

### No Cross-File Improvements

If project-wide analysis found no cross-file issues:

```
### Cross-File Improvements

No cross-file duplication or consistency issues detected. Files already follow consistent patterns.
```

Continue with other sections normally.

### Partial Project Coverage

If some files couldn't be refactored:

```
**Files Refactored**: 38 files (62% of project)
**Files Skipped**: 4 files

**Skipped Files**:
- [vendor/legacy.ts](vendor/legacy.ts): Third-party code, excluded
- [scripts/build.py](scripts/build.py): Parse error, review manually
```

### Very Large Projects

For projects with 100+ files:

**Summarize Changes**:
- Use file counts more than individual file references
- Group by directory or feature area
- Keep summary concise and scannable

**Example**:
```
**Code Cleanup** (85 files):
- Removed 342 unused imports across all files
- Deleted 23 unused utility functions
- Removed 45 commented-out code blocks in [services/](services/) and [components/](components/)
```

## Formatting Guidelines

### Same as File-Level

Use same formatting conventions:
- Markdown links for file references
- Syntax highlighting for code blocks
- Checkmarks for verified standards
- Past tense for completed changes

### Additional Project-Wide Guidelines

**File Counts**:
Always include affected file counts for project-wide changes:
- "across 12 files"
- "(22 files affected)"
- "in 8 files"

**Directory References**:
Use directory links when changes affect entire directories:
- `[services/](services/)` instead of listing all files
- `[components/](components/)` for component-wide changes

**Grouping**:
Group changes by impact or feature area for readability in large summaries.

### Tone

Same as file-level:
- Factual and precise
- Action-oriented (past tense)
- Specific with file counts and references
- Helpful with structured review recommendations
