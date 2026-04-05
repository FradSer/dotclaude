# Hooks, Automation, and Guardrails — Venture Signal Engine

## Overview

Developer workflow enforcement ensures code quality, security, and consistency from the first commit. Each guardrail runs locally (fast feedback), in CI (enforcement), or both.

---

## Pre-Commit Hooks

### 1. Lint and Format (Biome)

| Attribute | Value |
|-----------|-------|
| **Purpose** | Enforce consistent code style, catch common bugs |
| **Behavior** | Run Biome lint + format on staged files only |
| **Tooling** | Biome via lint-staged + Husky |
| **Failure condition** | Lint errors or formatting differences block commit |
| **Runs** | Local (pre-commit) + CI |
| **Mandatory before coding** | Yes |

**Configuration:**
```json
// .husky/pre-commit
pnpm lint-staged

// package.json
{
  "lint-staged": {
    "*.{ts,tsx,js,jsx}": ["biome check --write"],
    "*.{json,md,yaml}": ["biome format --write"]
  }
}
```

### 2. Type Check (TypeScript)

| Attribute | Value |
|-----------|-------|
| **Purpose** | Catch type errors before they enter the codebase |
| **Behavior** | Run `tsc --noEmit` on affected packages |
| **Tooling** | TypeScript via Turborepo `typecheck` pipeline |
| **Failure condition** | Any type error blocks commit |
| **Runs** | CI only (too slow for pre-commit on full repo) |
| **Mandatory before coding** | Yes (CI enforcement) |

### 3. Secret Detection (gitleaks)

| Attribute | Value |
|-----------|-------|
| **Purpose** | Prevent secrets from being committed |
| **Behavior** | Scan staged files for API keys, passwords, tokens, private keys |
| **Tooling** | gitleaks (pre-commit hook) |
| **Failure condition** | Any detected secret blocks commit with clear error message |
| **Runs** | Local (pre-commit) + CI |
| **Mandatory before coding** | Yes |

**Configuration:**
```yaml
# .gitleaks.toml
[allowlist]
paths = [".env.example", "docs/"]

[[rules]]
id = "generic-api-key"
description = "Generic API Key"
regex = '''(?i)(api[_-]?key|apikey)\s*[:=]\s*['"]?[a-zA-Z0-9]{20,}'''
```

---

## Commit-msg Hooks

### 4. Conventional Commit Validation

| Attribute | Value |
|-----------|-------|
| **Purpose** | Enforce conventional commit format for changelog generation |
| **Behavior** | Validate commit message matches `type(scope): description` |
| **Tooling** | commitlint + `@commitlint/config-conventional` |
| **Failure condition** | Non-conforming message blocks commit with example of correct format |
| **Runs** | Local (commit-msg hook) + CI (PR title check) |
| **Mandatory before coding** | Yes |

**Allowed types:** `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`, `ci`, `build`

**Allowed scopes:** `web`, `workers`, `db`, `api`, `auth`, `ingestion`, `ai`, `signals`, `ui`, `config`, `infra`, `ci`, `docs`

**Configuration:**
```js
// commitlint.config.ts
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'scope-enum': [2, 'always', [
      'web', 'workers', 'db', 'api', 'auth',
      'ingestion', 'ai', 'signals', 'ui', 'config',
      'infra', 'ci', 'docs'
    ]],
    'subject-max-length': [2, 'always', 72],
  },
};
```

---

## Pre-Push Hooks

### 5. Test Gate

| Attribute | Value |
|-----------|-------|
| **Purpose** | Prevent pushing code that breaks tests |
| **Behavior** | Run affected tests (based on changed files) before push |
| **Tooling** | Vitest via Turborepo `test` pipeline with `--filter` |
| **Failure condition** | Any test failure blocks push |
| **Runs** | Local (pre-push) |
| **Mandatory before coding** | Yes |

**Script:**
```bash
#!/bin/sh
# .husky/pre-push
pnpm turbo test --filter='...[HEAD~1]'
```

---

## CI Required Status Checks

### 6. Full CI Pipeline

| Attribute | Value |
|-----------|-------|
| **Purpose** | Comprehensive quality gate before merge |
| **Behavior** | Lint → Type check → Unit tests → Integration tests → Build |
| **Tooling** | GitHub Actions |
| **Failure condition** | Any step failure blocks PR merge |
| **Runs** | CI only |
| **Mandatory before coding** | Yes |

**Pipeline steps:**
```yaml
# .github/workflows/ci.yml
name: CI
on: [pull_request]
jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
      - run: pnpm install --frozen-lockfile
      - run: pnpm turbo lint
      - run: pnpm turbo typecheck
      - run: pnpm turbo test
      - run: pnpm turbo build

  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: gitleaks/gitleaks-action@v2
      - run: pnpm audit --audit-level=high
```

### 7. PR Title Conventional Format

| Attribute | Value |
|-----------|-------|
| **Purpose** | Ensure squash-merge commits follow conventional format |
| **Behavior** | Validate PR title matches `type(scope): description` |
| **Tooling** | GitHub Action (`amannn/action-semantic-pull-request`) |
| **Failure condition** | Non-conforming PR title blocks merge |
| **Runs** | CI only |
| **Mandatory before coding** | Yes |

### 8. Required Reviews

| Attribute | Value |
|-----------|-------|
| **Purpose** | Code review before merge |
| **Behavior** | Minimum 1 approving review required; CODEOWNERS auto-assigned |
| **Tooling** | GitHub branch protection |
| **Failure condition** | No approval blocks merge |
| **Runs** | GitHub (not CI) |
| **Mandatory before coding** | Yes |

---

## Schema and Migration Safety

### 9. Migration Validation

| Attribute | Value |
|-----------|-------|
| **Purpose** | Prevent destructive or unsafe migrations |
| **Behavior** | Check migrations for DROP TABLE, DROP COLUMN without safeguards |
| **Tooling** | Custom script scanning migration SQL files |
| **Failure condition** | Destructive migration without explicit `-- safe: true` annotation blocks CI |
| **Runs** | CI only |
| **Mandatory before coding** | Parallel (needed when migrations start) |

**Script logic:**
```bash
# scripts/validate-migrations.sh
#!/bin/bash
for file in packages/db/src/migrations/*.sql; do
  if grep -iE "DROP (TABLE|COLUMN|INDEX)" "$file" > /dev/null; then
    if ! grep -q "-- safe: true" "$file"; then
      echo "ERROR: Destructive migration in $file requires '-- safe: true' annotation"
      exit 1
    fi
  fi
done
```

### 10. Schema Validation (Zod)

| Attribute | Value |
|-----------|-------|
| **Purpose** | Ensure API input/output schemas are valid and complete |
| **Behavior** | Type-check tRPC router Zod schemas as part of `typecheck` pipeline |
| **Tooling** | TypeScript compiler (Zod schemas are type-checked natively) |
| **Failure condition** | Type errors in schema definitions block CI |
| **Runs** | CI (typecheck step) |
| **Mandatory before coding** | Yes (part of typecheck) |

---

## Generated Code Consistency

### 11. Drizzle Schema Sync Check

| Attribute | Value |
|-----------|-------|
| **Purpose** | Ensure generated migrations match schema definitions |
| **Behavior** | Run `drizzle-kit generate --check` to detect drift |
| **Tooling** | Drizzle Kit |
| **Failure condition** | Schema drift detected blocks CI |
| **Runs** | CI only |
| **Mandatory before coding** | Parallel (needed when schema work starts) |

---

## Automation

### 12. Changelog Generation

| Attribute | Value |
|-----------|-------|
| **Purpose** | Auto-generate changelog from conventional commits |
| **Behavior** | On release tag, generate CHANGELOG.md from commit history |
| **Tooling** | `changesets` or `conventional-changelog-cli` |
| **Failure condition** | N/A (automation, not gate) |
| **Runs** | CI (on release) |
| **Mandatory before coding** | No (parallel) |

### 13. Release Tagging

| Attribute | Value |
|-----------|-------|
| **Purpose** | Automated version bumping and git tags |
| **Behavior** | On merge to main with release label, bump version, tag, generate changelog |
| **Tooling** | GitHub Actions + changesets |
| **Failure condition** | N/A (automation) |
| **Runs** | CI only |
| **Mandatory before coding** | No (parallel) |

### 14. Course Generation Post-Merge

| Attribute | Value |
|-----------|-------|
| **Purpose** | Auto-generate educational courses after epics/stories merge |
| **Behavior** | On merge of PR with `epic` or `story` label, trigger codebase-to-course |
| **Tooling** | GitHub Actions + codebase-to-course skill |
| **Failure condition** | Course generation failure does not block (non-critical) |
| **Runs** | CI only (post-merge) |
| **Mandatory before coding** | No (parallel) |

**Workflow:**
```yaml
# .github/workflows/course-gen.yml
name: Course Generation
on:
  pull_request:
    types: [closed]
    branches: [main]
jobs:
  generate:
    if: github.event.pull_request.merged == true && contains(github.event.pull_request.labels.*.name, 'epic')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Generate course
        run: ./scripts/generate-course.sh
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: course-${{ github.event.pull_request.number }}
          path: dist/courses/
```

### 15. Dependency Updates

| Attribute | Value |
|-----------|-------|
| **Purpose** | Keep dependencies up to date automatically |
| **Behavior** | Weekly PRs for dependency updates |
| **Tooling** | GitHub Dependabot |
| **Failure condition** | N/A (creates PRs for review) |
| **Runs** | GitHub scheduled |
| **Mandatory before coding** | Yes |

**Configuration:**
```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: npm
    directory: "/"
    schedule:
      interval: weekly
    groups:
      minor-and-patch:
        update-types: ["minor", "patch"]
  - package-ecosystem: github-actions
    directory: "/"
    schedule:
      interval: weekly
```

---

## Branch Naming Enforcement

### 16. Branch Name Validation

| Attribute | Value |
|-----------|-------|
| **Purpose** | Consistent branch naming for automation |
| **Behavior** | Validate branch name matches `type/scope/description` pattern |
| **Tooling** | GitHub Actions check or pre-push hook |
| **Failure condition** | Non-conforming branch name triggers warning (not blocking for MVP) |
| **Runs** | Local (pre-push) |
| **Mandatory before coding** | No (nice-to-have) |

---

## Summary: Guardrail Implementation Priority

### Must Have Before Feature Work (Sprint 0)

| # | Guardrail | Local | CI |
|---|-----------|-------|-----|
| 1 | Biome lint + format (lint-staged) | ✓ | ✓ |
| 2 | Secret detection (gitleaks) | ✓ | ✓ |
| 3 | Conventional commit validation | ✓ | ✓ |
| 4 | TypeScript type checking | | ✓ |
| 5 | Unit test gate | ✓ (pre-push) | ✓ |
| 6 | Full CI pipeline | | ✓ |
| 7 | PR title validation | | ✓ |
| 8 | Required reviews | | ✓ |
| 9 | Dependabot | | ✓ |

### Add During Feature Work

| # | Guardrail | Local | CI |
|---|-----------|-------|-----|
| 10 | Migration validation | | ✓ |
| 11 | Drizzle schema sync | | ✓ |
| 12 | Changelog generation | | ✓ |
| 13 | Release tagging | | ✓ |
| 14 | Course generation | | ✓ |

### Post-MVP

| # | Guardrail |
|---|-----------|
| 15 | DAST scanning |
| 16 | Performance regression testing |
| 17 | Bundle size monitoring |
