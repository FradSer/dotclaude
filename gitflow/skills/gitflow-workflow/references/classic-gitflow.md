# Classic GitFlow

Traditional GitFlow workflow with separate integration and production branches.

## Base Branches

- **main/master**: Holds production-ready code. Only updated via releases and hotfixes.
- **develop**: Primary integration branch for all ongoing development.

## Topic Branches

- **feature/**: Used for all new functionality. Branches from `develop`, merges back to `develop`.
- **bugfix/**: Reserved for bugfixes. Branches from `develop`, merges back to `develop`.
- **release/**: Used to prepare a new production release. Branches from `develop`, merges to both `main` and `develop`.
- **hotfix/**: Reserved for urgent, production-breaking fixes. Branches from `main`, merges to both `main` and `develop`.
- **support/**: (Optional) Used to manage and maintain older, currently supported versions of the software.

## Branch Flow

```mermaid
gitGraph
  commit id: "init"
  branch develop
  checkout develop
  commit id: "dev-1"
  branch feature/auth
  commit id: "auth-1"
  checkout develop
  branch feature/profile
  commit id: "profile-1"
  checkout develop
  merge feature/auth
  branch release/v1.1.0
  commit id: "release-prep"
  checkout main
  merge release/v1.1.0 tag: "v1.1.0"
  checkout develop
  merge release/v1.1.0
  checkout main
  branch hotfix/v1.0.1
  commit id: "hotfix"
  checkout main
  merge hotfix/v1.0.1 tag: "v1.0.1"
  checkout develop
  merge hotfix/v1.0.1
```
