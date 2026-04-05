# Pre-Development Bootstrap Requirements — Venture Signal Engine

Everything listed here must exist in the repository **before product feature work begins**.

---

## Legend

| Column | Meaning |
|--------|---------|
| **Blocking** | Must exist before any feature PR is merged |
| **Parallel** | Can be done alongside early feature work |
| **Post-MVP** | Can wait until after MVP features ship |

---

## 1. Repository Initialization

| Item | Why | Tool/Pattern | Blocking? | Location | Owner |
|------|-----|-------------|-----------|----------|-------|
| **Monorepo scaffold** | All code depends on package boundaries | Turborepo + pnpm workspaces | **Blocking** | Root: `turbo.json`, `pnpm-workspace.yaml`, `package.json` | Platform/DevOps |
| **TypeScript configuration** | Type safety from first line of code | `tsconfig.json` with strict mode, path aliases | **Blocking** | Root + per-package `tsconfig.json` | Platform/DevOps |
| **Package initialization** | Each package needs manifest and build config | `package.json` per app/package with `@vse/` namespace | **Blocking** | `apps/*/package.json`, `packages/*/package.json` | Platform/DevOps |
| **Git initialization** | Version control from day one | Git with `.gitignore` | **Blocking** | Root `.gitignore` | Platform/DevOps |
| **Node.js version pinning** | Reproducible builds | `.nvmrc` or `.tool-versions` (mise/asdf) | **Blocking** | Root `.nvmrc` | Platform/DevOps |
| **pnpm version pinning** | Consistent package management | `packageManager` field in root `package.json` | **Blocking** | Root `package.json` | Platform/DevOps |

## 2. Documentation and Onboarding

| Item | Why | Tool/Pattern | Blocking? | Location | Owner |
|------|-----|-------------|-----------|----------|-------|
| **README.md** | Onboarding, project overview, getting started | Markdown with setup instructions, architecture overview | **Blocking** | Root `README.md` | Tech Lead |
| **CLAUDE.md** | Claude Code development guidance (following dotclaude pattern) | Markdown with repo conventions, tool rules, coding standards | **Blocking** | Root `CLAUDE.md` | Tech Lead |
| **CONTRIBUTING.md** | Contribution guidelines, PR process, code review standards | Markdown | **Blocking** | Root `CONTRIBUTING.md` | Tech Lead |
| **Architecture docs** | System overview for new engineers | Markdown with diagrams | **Blocking** | `docs/architecture/` | Tech Lead |
| **ADR template** | Consistent decision recording | MADR format | **Blocking** | `docs/adr/template.md` | Tech Lead |
| **Initial ADRs** | Record foundational decisions | ADR-0001 (architecture), ADR-0002 (repo model) | **Blocking** | `docs/adr/` | Tech Lead |

## 3. Code Quality and Standards

| Item | Why | Tool/Pattern | Blocking? | Location | Owner |
|------|-----|-------------|-----------|----------|-------|
| **Linting** | Consistent code style, catch bugs early | Biome (replaces ESLint + Prettier — faster, all-in-one) | **Blocking** | Root `biome.json` | Platform/DevOps |
| **Formatting** | Consistent formatting across all files | Biome (built-in formatter) | **Blocking** | Root `biome.json` | Platform/DevOps |
| **Type checking** | Catch type errors before runtime | TypeScript strict mode (`noUncheckedIndexedAccess`, `strict: true`) | **Blocking** | Root + per-package `tsconfig.json` | Platform/DevOps |
| **Import sorting** | Consistent import ordering | Biome (built-in import sorting) | **Blocking** | Root `biome.json` | Platform/DevOps |
| **Commit message validation** | Conventional commits for changelog generation | commitlint + `@commitlint/config-conventional` | **Blocking** | Root `commitlint.config.ts` | Platform/DevOps |
| **Coding standards doc** | Written standards beyond what linters enforce | Markdown guide | Parallel | `docs/coding-standards.md` | Tech Lead |

## 4. Testing Infrastructure

| Item | Why | Tool/Pattern | Blocking? | Location | Owner |
|------|-----|-------------|-----------|----------|-------|
| **Unit test framework** | Test individual functions and modules | Vitest (fast, TypeScript-native, ESM) | **Blocking** | Root `vitest.config.ts` + per-package configs | Platform/DevOps |
| **Integration test setup** | Test service interactions | Vitest + testcontainers (PostgreSQL, Redis) | **Blocking** | Per-package test directories | Backend engineers |
| **E2E test framework** | Test full user workflows | Playwright | Parallel | `apps/web/e2e/` | QA/Frontend |
| **Test coverage thresholds** | Prevent coverage regression | Vitest coverage with Istanbul/v8 | Parallel | `vitest.config.ts` (global thresholds) | Platform/DevOps |
| **Mock data factory** | Consistent test data generation | Custom factories using Drizzle types | Parallel | `packages/db/src/seed/factories.ts` | Backend engineers |
| **Test database strategy** | Isolated test databases | testcontainers (PostgreSQL container per test suite) | **Blocking** | Test setup files | Backend engineers |

## 5. Local Development Environment

| Item | Why | Tool/Pattern | Blocking? | Location | Owner |
|------|-----|-------------|-----------|----------|-------|
| **Docker Compose** | Run PostgreSQL, Redis locally without manual install | `docker-compose.yml` with pg + redis services | **Blocking** | `infra/docker/docker-compose.yml` | Platform/DevOps |
| **Bootstrap script** | One-command setup for new developers | Bash script: install deps, start services, run migrations, seed | **Blocking** | `scripts/bootstrap.sh` | Platform/DevOps |
| **Dev startup script** | Start all services for development | Bash script or Turborepo `dev` pipeline | **Blocking** | `scripts/dev.sh` | Platform/DevOps |
| **Health check script** | Verify environment is working | Check DB connection, Redis, env vars, port availability | **Blocking** | `scripts/health-check.sh` | Platform/DevOps |
| **Hot reload** | Fast feedback during development | Next.js built-in + tsx for workers | **Blocking** | Per-app configuration | Platform/DevOps |

## 6. Cloud Development Environment

| Item | Why | Tool/Pattern | Blocking? | Location | Owner |
|------|-----|-------------|-----------|----------|-------|
| **devcontainer config** | Reproducible cloud dev environment (GitHub Codespaces, Claude Code) | `.devcontainer/devcontainer.json` | **Blocking** | `.devcontainer/` | Platform/DevOps |
| **Workspace postCreate script** | Auto-setup on workspace creation | Shell script triggered by devcontainer lifecycle | **Blocking** | `.devcontainer/post-create.sh` | Platform/DevOps |
| **Cloud workspace parity** | Cloud dev matches local dev | Same Docker Compose, same env vars, same scripts | **Blocking** | Verified in CI | Platform/DevOps |

## 7. Environment Configuration

| Item | Why | Tool/Pattern | Blocking? | Location | Owner |
|------|-----|-------------|-----------|----------|-------|
| **.env.example** | Document all required environment variables | Template with descriptions, no real values | **Blocking** | Root `.env.example` | Platform/DevOps |
| **Env validation** | Fail fast on missing/invalid env vars | Zod schema in `@vse/config` package | **Blocking** | `packages/config/src/env.ts` | Platform/DevOps |
| **Secrets handling strategy** | Never commit secrets; use cloud secrets manager | AWS Secrets Manager / GCP Secret Manager + local `.env` | **Blocking** | Documented in CONTRIBUTING.md | Security |
| **.env in .gitignore** | Prevent accidental secret commits | Already covered by .gitignore pattern | **Blocking** | `.gitignore` | Platform/DevOps |

## 8. Database Foundation

| Item | Why | Tool/Pattern | Blocking? | Location | Owner |
|------|-----|-------------|-----------|----------|-------|
| **ORM setup** | Type-safe database access | Drizzle ORM with PostgreSQL driver | **Blocking** | `packages/db/` | Backend |
| **Migration tooling** | Version-controlled schema changes | Drizzle Kit (`drizzle-kit generate`, `drizzle-kit migrate`) | **Blocking** | `packages/db/drizzle.config.ts` | Backend |
| **Initial schema** | Core tables for auth, org, audit | Migration `0001_initial_schema.sql` | **Blocking** | `packages/db/src/migrations/` | Backend |
| **Seed data** | Development and testing data | TypeScript seed scripts | Parallel | `packages/db/src/seed/` | Backend |
| **pgvector extension** | Vector similarity search | `CREATE EXTENSION vector` in migration | Parallel | Migration file | Backend |

## 9. API Contract Foundation

| Item | Why | Tool/Pattern | Blocking? | Location | Owner |
|------|-----|-------------|-----------|----------|-------|
| **tRPC setup** | End-to-end type-safe API | tRPC v11 with Next.js adapter | **Blocking** | `packages/api/` | Full-stack |
| **Zod schemas** | Runtime validation + TypeScript types | Zod schemas shared between frontend and backend | **Blocking** | `packages/api/src/routers/` | Full-stack |
| **OpenAPI generation** | External API documentation | `trpc-openapi` for auto-generated spec | Parallel | Generated from tRPC routers | Full-stack |

## 10. Authentication Foundation

| Item | Why | Tool/Pattern | Blocking? | Location | Owner |
|------|-----|-------------|-----------|----------|-------|
| **Auth.js v5 setup** | OAuth2 authentication | Auth.js with Google + GitHub providers | **Blocking** | `packages/auth/` | Backend + Security |
| **RBAC implementation** | Role-based access control | Custom middleware using Auth.js session | **Blocking** | `packages/auth/src/rbac.ts` | Backend + Security |
| **Protected routes** | Prevent unauthorized access | Next.js middleware + tRPC middleware | **Blocking** | `apps/web/src/middleware.ts` | Full-stack |

## 11. Feature Flagging

| Item | Why | Tool/Pattern | Blocking? | Location | Owner |
|------|-----|-------------|-----------|----------|-------|
| **Feature flag system** | Safe rollouts, A/B testing | Unleash (self-hosted) or environment-based flags for MVP | Parallel | `packages/config/src/flags.ts` | Platform/DevOps |
| **Flag evaluation** | Check flags in frontend and backend | Unleash client SDK or simple env-based | Parallel | Shared utility | Platform/DevOps |

## 12. Observability Baseline

| Item | Why | Tool/Pattern | Blocking? | Location | Owner |
|------|-----|-------------|-----------|----------|-------|
| **Structured logging** | Parseable, searchable logs | pino (JSON output) | **Blocking** | `packages/config/src/logger.ts` | Platform/DevOps |
| **OpenTelemetry SDK** | Distributed tracing and metrics | `@opentelemetry/sdk-node` with auto-instrumentation | **Blocking** | `packages/config/src/telemetry.ts` | Platform/DevOps |
| **Error tracking** | Catch and triage production errors | Sentry SDK | Parallel | `packages/config/src/sentry.ts` | Platform/DevOps |
| **Health endpoint** | Readiness/liveness probes | `/api/health` route | **Blocking** | `apps/web/src/app/api/health/route.ts` | Platform/DevOps |

## 13. Security Scanning

| Item | Why | Tool/Pattern | Blocking? | Location | Owner |
|------|-----|-------------|-----------|----------|-------|
| **Secret scanning** | Prevent secret leaks in commits | GitHub secret scanning + gitleaks in pre-commit | **Blocking** | `.github/` + pre-commit config | Security |
| **Dependency scanning** | Catch known vulnerabilities | GitHub Dependabot + `pnpm audit` in CI | **Blocking** | `.github/dependabot.yml` | Security |
| **SAST** | Static application security testing | GitHub CodeQL or Semgrep | Parallel | `.github/workflows/security-scan.yml` | Security |
| **DAST** | Dynamic application security testing | OWASP ZAP against staging | Post-MVP | CI workflow | Security |
| **License scanning** | Ensure dependency license compliance | `license-checker` or Snyk | Parallel | CI workflow step | Security |

## 14. CI/CD Foundation

| Item | Why | Tool/Pattern | Blocking? | Location | Owner |
|------|-----|-------------|-----------|----------|-------|
| **CI workflow** | Automated quality gates on every PR | GitHub Actions: lint, typecheck, test, build | **Blocking** | `.github/workflows/ci.yml` | Platform/DevOps |
| **Preview deployments** | Review changes in a live environment | Vercel preview deployments (auto per PR) | **Blocking** | `.github/workflows/deploy-preview.yml` or Vercel integration | Platform/DevOps |
| **Staging deployment** | Auto-deploy on merge to main | GitHub Actions → deploy to staging | Parallel | `.github/workflows/deploy-staging.yml` | Platform/DevOps |
| **Production deployment** | Manual promotion from staging | GitHub Actions with manual trigger | Parallel | `.github/workflows/deploy-prod.yml` | Platform/DevOps |
| **Course generation workflow** | Auto-generate courses post-merge | GitHub Actions triggered on epic/story merge | Parallel | `.github/workflows/course-gen.yml` | Full-stack |

## 15. GitHub Configuration

| Item | Why | Tool/Pattern | Blocking? | Location | Owner |
|------|-----|-------------|-----------|----------|-------|
| **CODEOWNERS** | Automatic review assignment by area | GitHub CODEOWNERS file | **Blocking** | `.github/CODEOWNERS` | Tech Lead |
| **Branch protection** | Prevent direct pushes to main | GitHub branch protection rules (CI pass, 1 review) | **Blocking** | GitHub settings (manual) | Platform/DevOps |
| **PR template** | Consistent PR descriptions | Markdown template with checklist | **Blocking** | `.github/PULL_REQUEST_TEMPLATE.md` | Tech Lead |
| **Issue templates** | Structured bug reports and feature requests | YAML issue forms | **Blocking** | `.github/ISSUE_TEMPLATE/` | Tech Lead |
| **Labels** | Consistent issue/PR categorization | GitHub labels (auto-created via script) | Parallel | `scripts/setup-labels.sh` | Platform/DevOps |

## 16. Infrastructure as Code

| Item | Why | Tool/Pattern | Blocking? | Location | Owner |
|------|-----|-------------|-----------|----------|-------|
| **Terraform structure** | Reproducible infrastructure | Terraform modules + per-environment configs | Parallel | `infra/terraform/` | Platform/DevOps |
| **Remote state** | Shared, locked Terraform state | S3 + DynamoDB backend | Parallel | `infra/terraform/backend.tf` | Platform/DevOps |
| **Dev environment IaC** | Development infrastructure | Terraform dev environment | Parallel | `infra/terraform/environments/dev/` | Platform/DevOps |

## 17. Operational Readiness

| Item | Why | Tool/Pattern | Blocking? | Location | Owner |
|------|-----|-------------|-----------|----------|-------|
| **Runbook template** | Consistent operational documentation | Markdown template | Parallel | `docs/runbooks/template.md` | Platform/DevOps |
| **Incident template** | Structured incident response | GitHub issue template for incidents | Parallel | `.github/ISSUE_TEMPLATE/incident.yml` | Platform/DevOps |
| **Deployment runbook** | Step-by-step deployment guide | Markdown | Parallel | `docs/runbooks/deployment.md` | Platform/DevOps |
| **Database migration runbook** | Safe migration process | Markdown | Parallel | `docs/runbooks/database-migration.md` | Platform/DevOps |
| **Data retention policy** | Compliance, cost control | Documented policy with implementation plan | Post-MVP | `docs/policies/data-retention.md` | Security + Legal |
| **Logging standards** | Consistent log format across services | pino with standard fields | **Blocking** | `packages/config/src/logger.ts` | Platform/DevOps |

---

## Summary: Blocking Items Count

| Category | Blocking Items |
|----------|---------------|
| Repository initialization | 6 |
| Documentation | 6 |
| Code quality | 5 |
| Testing | 4 |
| Local dev environment | 5 |
| Cloud dev environment | 3 |
| Environment config | 4 |
| Database | 3 |
| API contract | 2 |
| Auth | 3 |
| Observability | 3 |
| Security scanning | 2 |
| CI/CD | 2 |
| GitHub config | 4 |
| Operational | 1 |
| **Total blocking** | **53** |

These 53 items form the **foundation sprint** before any feature development begins.
