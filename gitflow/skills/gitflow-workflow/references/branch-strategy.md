# GitFlow Branch Strategies

This document describes the three preset workflows supported by git-flow-next and their branch naming conventions.

## Classic GitFlow

Traditional GitFlow workflow with separate integration and production branches.

### Base Branches

- **main/master**: Holds production-ready code. Only updated via releases and hotfixes.
- **develop**: Primary integration branch for all ongoing development.

### Topic Branches

- **feature/**: Used for all new functionality. Branches from `develop`, merges back to `develop`.
- **bugfix/**: Reserved for bugfixes. Branches from `develop`, merges back to `develop`.
- **release/**: Used to prepare a new production release. Branches from `develop`, merges to both `main` and `develop`.
- **hotfix/**: Reserved for urgent, production-breaking fixes. Branches from `main`, merges to both `main` and `develop`.
- **support/**: (Optional) Used to manage and maintain older, currently supported versions of the software.

### Branch Flow

```
main/master (production)
  │
  ├── hotfix/v1.0.1 ──┐
  │                    │
  └── release/v1.1.0 ──┤
                       │
develop (integration)  │
  │                    │
  ├── feature/auth ────┘
  ├── feature/profile
  └── bugfix/login-bug
```

### Naming Conventions

- Feature branches: `feature/kebab-case-name`
- Bugfix branches: `bugfix/kebab-case-name`
- Release branches: `release/v1.2.0` or `release/1.2.0`
- Hotfix branches: `hotfix/kebab-case-name` or `hotfix/v1.0.1`
- Support branches: `support/v1.x`

## GitHub Flow

Simplified workflow with a single base branch and feature branches.

### Base Branches

- **main**: The single source of truth and the only base branch.

### Topic Branches

- **feature/**: Covers all development work: new features, refactors, and bug fixes. Branches from `main`, merges back to `main`.

### Branch Flow

```
main (production)
  │
  ├── feature/user-auth
  ├── feature/payment
  └── feature/bugfix-login
```

### Characteristics

- Simpler than Classic GitFlow
- No separate develop branch
- All work happens in feature branches
- Direct merge to main after review
- Suitable for continuous deployment

### Naming Conventions

- Feature branches: `feature/kebab-case-name`
- Can include bugfixes: `feature/fix-issue-name`

## GitLab Flow

Multi-environment workflow with separate production and staging branches.

### Base Branches

- **production**: The only branch that deploys to the production environment.
- **main**: The primary integration branch where all new features are initially merged.
- **staging**: The final gate. Always updated from `main` before being promoted to `production`.

### Topic Branches

- **feature/**: Used for all new functionality. Branches from `main`, merges back to `main`.
- **hotfix/**: Reserved for urgent, production-breaking fixes. Branches from `production`, merges to both `production` and `main`.

### Branch Flow

```
production (deploys to prod)
  │
  └── staging (deploys to staging)
       │
       └── main (integration)
            │
            ├── feature/auth
            ├── feature/payment
            └── hotfix/critical-fix
```

### Characteristics

- Environment-based branching
- Staging branch for pre-production testing
- Production branch for live deployment
- Hotfixes branch from production
- Features merge through main → staging → production

### Naming Conventions

- Feature branches: `feature/kebab-case-name`
- Hotfix branches: `hotfix/kebab-case-name`

## Branch Naming Rules

### General Rules

1. Use kebab-case (lowercase with hyphens)
2. Be descriptive but concise
3. Avoid special characters except hyphens
4. Match branch type prefix exactly

### Examples

**Good:**
- `feature/user-authentication`
- `bugfix/login-error-handling`
- `hotfix/payment-gateway-timeout`
- `release/v1.2.0`

**Bad:**
- `feature/userAuth` (camelCase)
- `feature/user_authentication` (snake_case)
- `feature/User-Authentication` (PascalCase)
- `feature/user authentication` (spaces)

## Branch Lifecycle

### Feature Branch Lifecycle

1. **Start**: `git flow feature start my-feature`
   - Creates `feature/my-feature` from `develop`
   - Checks out the new branch

2. **Development**: Make commits using conventional format

3. **Update** (optional): `git flow feature update`
   - Syncs with latest changes from `develop`

4. **Finish**: `git flow feature finish my-feature`
   - Merges to `develop` with `--no-ff`
   - Deletes branch locally and remotely

### Hotfix Branch Lifecycle

1. **Start**: `git flow hotfix start critical-fix`
   - Creates `hotfix/critical-fix` from `main`
   - Increments patch version

2. **Fix**: Make commits to fix the issue

3. **Finish**: `git flow hotfix finish critical-fix`
   - Merges to both `main` and `develop`
   - Creates version tag
   - Deletes branch

### Release Branch Lifecycle

1. **Start**: `git flow release start 1.2.0`
   - Creates `release/1.2.0` from `develop`
   - Calculates version from commits

2. **Stabilization**: Final testing and bug fixes only

3. **Finish**: `git flow release finish 1.2.0`
   - Merges to `main` with tag
   - Merges back to `develop`
   - Deletes branch

## Merge Strategies

### Feature Branches

- Default: `--no-ff` merge to preserve branch history
- Optional: `--rebase` for linear history
- Optional: `--squash` for single commit

### Hotfix Branches

- Always merge to both `main` and `develop`
- Use `--no-ff` to preserve hotfix context
- Create version tag on `main`

### Release Branches

- Merge to `main` with `--no-ff` and tag
- Merge back to `develop` to sync changes
- Never add new features to release branch
