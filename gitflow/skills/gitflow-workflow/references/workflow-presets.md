# Workflow Presets

git-flow-next supports presets (classic, github, gitlab). These presets define the base branches and the default “branch-from / merge-to” relationships.

## Classic GitFlow

Base branches:
- `main` (or `master`): production
- `develop`: integration

Topic branches:
- `feature/*`: `develop` → `develop`
- `release/*`: `develop` → `main` + back-merge to `develop`
- `hotfix/*`: `main` → `main` + merge to `develop`
- `bugfix/*`: `develop` → `develop`
- `support/*`: optional long-term support lines

## GitHub Flow

Base branches:
- `main`: single trunk

Topic branches:
- `feature/*`: `main` → `main` (covers features, refactors, fixes)

Characteristics:
- No `develop` branch
- Suited to continuous deployment

## GitLab Flow

Base branches (environment flow):
- `main` → `staging` → `production`

Topic branches:
- `feature/*`: `main` → `main`
- `hotfix/*`: `production` → `production` + merge to `main`

Characteristics:
- Environment-based promotion (staging gate)
- Hotfixes branch from production

