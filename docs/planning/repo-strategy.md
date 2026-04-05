# Repo and Codebase Strategy — Venture Signal Engine

## Repository Model Decision

### Recommendation: Monorepo (single repository)

| Option | Verdict | Rationale |
|--------|---------|-----------|
| **Monorepo** | **Selected** | Shared types, atomic changes, unified CI, simpler dependency management |
| Polyrepo | Rejected | Too much overhead for a small team; cross-repo type sharing is painful |
| Hybrid | Rejected | Unnecessary complexity at this stage |

The Venture Signal Engine uses a **Turborepo + pnpm workspaces monorepo**. This keeps all application code, infrastructure, and documentation in one repository while maintaining clear package boundaries.

### Separate from Plugin Marketplace

The VSE repo is **separate from `micro-eng/dotclaude`** (the plugin marketplace). Rationale:
- Different concerns: SaaS webapp vs. Claude Code plugins
- Different CI/CD pipelines and deployment targets
- Different team composition and access control
- Different versioning and release cadence
- Planning docs live in `dotclaude/docs/planning/` per initial request; app code in its own repo

See `ADR-0002` for the full decision record.

---

## Ownership Boundaries

| Package/App | Owner | Responsibility |
|------------|-------|----------------|
| `apps/web` | Frontend + Full-stack engineers | UI, API routes, tRPC routers |
| `apps/workers` | Backend + Data engineers | Job processors, ingestion, AI pipeline |
| `packages/db` | Backend engineers | Schema, migrations, seed data |
| `packages/api` | Full-stack engineers | tRPC router definitions, shared types |
| `packages/auth` | Security + Backend engineers | Auth config, RBAC logic |
| `packages/ingestion` | Data engineers | Source adapters, parsers |
| `packages/ai` | ML/LLM engineers | Prompt engineering, LLM orchestration |
| `packages/signals` | Backend engineers | Signal processing, scoring |
| `packages/ui` | Frontend engineers | Shared React components |
| `packages/config` | Platform/DevOps | Environment config, validation |
| `packages/course-gen` | Full-stack engineers | codebase-to-course integration |
| `infra/` | Platform/DevOps | Terraform, Docker, IaC |
| `.github/` | Platform/DevOps | CI/CD workflows, templates |
| `docs/` | All (led by Tech Lead) | Planning, ADRs, runbooks |

---

## Branching Model

### Trunk-Based Development with Short-Lived Feature Branches

```
main ─────────●─────────●─────────●─────────●──────► (always deployable)
               ╲       ╱ ╲       ╱ ╲       ╱
                feat/A  feat/B  feat/C
                (1-3d)  (1-3d)  (1-3d)
```

**Rules:**
| Rule | Policy |
|------|--------|
| Default branch | `main` |
| Feature branches | `feat/<description>` (max 3 days) |
| Bug fix branches | `fix/<description>` |
| Release branches | Not used — continuous deployment from `main` |
| Branch protection | Required: CI pass, 1 review, no force push |
| Merge strategy | Squash merge for features; merge commit for multi-commit PRs |

**Branch naming convention:**
```
feat/<area>/<short-description>    e.g., feat/ingestion/news-adapter
fix/<area>/<short-description>     e.g., fix/auth/session-expiry
chore/<area>/<short-description>   e.g., chore/ci/add-playwright
docs/<description>                 e.g., docs/adr-0003-search-strategy
```

---

## Release Model

### Continuous Deployment

| Environment | Trigger | Strategy |
|-------------|---------|----------|
| **Preview** | Every PR | Vercel preview deployment (web); worker preview via Docker |
| **Staging** | Merge to `main` | Auto-deploy; runs full integration test suite |
| **Production** | Manual promotion from staging | One-click deploy after staging validation |

### Versioning Strategy

- **Application**: CalVer `YYYY.MM.DD` for deployments (e.g., `2026.04.15`)
- **Packages**: SemVer `MAJOR.MINOR.PATCH` for internal packages (managed by Turborepo)
- **API**: URL-versioned `/api/v1/...` for external API stability
- **Database**: Sequential migration numbering `0001_initial_schema.sql`

---

## Recommended Folder Structure

```
venture-signal-engine/
│
├── apps/
│   ├── web/                              # Next.js 15 application
│   │   ├── src/
│   │   │   ├── app/                      # App Router pages
│   │   │   │   ├── (auth)/               # Auth pages (login, callback)
│   │   │   │   ├── (dashboard)/          # Authenticated dashboard routes
│   │   │   │   │   ├── signals/          # Signal list, detail, search
│   │   │   │   │   ├── reports/          # Report generation and history
│   │   │   │   │   ├── sources/          # Source configuration
│   │   │   │   │   ├── analyses/         # Analysis views
│   │   │   │   │   └── settings/         # User and org settings
│   │   │   │   ├── admin/                # Admin-only routes
│   │   │   │   ├── api/                  # API routes (tRPC adapter)
│   │   │   │   │   └── trpc/[trpc]/      # tRPC HTTP handler
│   │   │   │   ├── layout.tsx            # Root layout
│   │   │   │   └── page.tsx              # Landing page
│   │   │   ├── components/               # App-specific components
│   │   │   │   ├── signals/
│   │   │   │   ├── reports/
│   │   │   │   ├── sources/
│   │   │   │   └── layout/
│   │   │   ├── hooks/                    # React hooks
│   │   │   ├── lib/                      # App utilities
│   │   │   │   ├── trpc.ts              # tRPC client setup
│   │   │   │   └── utils.ts
│   │   │   └── styles/                   # Global styles
│   │   ├── public/                       # Static assets
│   │   ├── next.config.ts
│   │   ├── tailwind.config.ts
│   │   ├── tsconfig.json
│   │   └── package.json
│   │
│   └── workers/                          # Background job processors
│       ├── src/
│       │   ├── index.ts                  # Worker entry point
│       │   ├── processors/
│       │   │   ├── ingestion.ts          # Ingestion job processor
│       │   │   ├── ai-pipeline.ts        # AI processing jobs
│       │   │   ├── report-gen.ts         # Report generation jobs
│       │   │   └── course-gen.ts         # Course generation jobs
│       │   ├── queues/                   # Queue definitions
│       │   │   ├── ingestion.queue.ts
│       │   │   ├── ai.queue.ts
│       │   │   └── report.queue.ts
│       │   └── lib/                      # Worker utilities
│       ├── Dockerfile
│       ├── tsconfig.json
│       └── package.json
│
├── packages/
│   ├── db/                               # Database package
│   │   ├── src/
│   │   │   ├── schema/                   # Drizzle schema definitions
│   │   │   │   ├── users.ts
│   │   │   │   ├── organizations.ts
│   │   │   │   ├── sources.ts
│   │   │   │   ├── documents.ts
│   │   │   │   ├── signals.ts
│   │   │   │   ├── analyses.ts
│   │   │   │   ├── recommendations.ts
│   │   │   │   ├── reports.ts
│   │   │   │   ├── audit-logs.ts
│   │   │   │   └── index.ts
│   │   │   ├── migrations/               # Generated migration files
│   │   │   ├── seed/                     # Seed data
│   │   │   │   ├── dev.ts
│   │   │   │   └── test.ts
│   │   │   ├── client.ts                 # Database client
│   │   │   └── index.ts                  # Package exports
│   │   ├── drizzle.config.ts
│   │   ├── tsconfig.json
│   │   └── package.json
│   │
│   ├── api/                              # Shared API types and routers
│   │   ├── src/
│   │   │   ├── routers/
│   │   │   │   ├── signal.ts
│   │   │   │   ├── source.ts
│   │   │   │   ├── report.ts
│   │   │   │   ├── user.ts
│   │   │   │   ├── analysis.ts
│   │   │   │   └── admin.ts
│   │   │   ├── middleware/
│   │   │   │   ├── auth.ts
│   │   │   │   ├── rate-limit.ts
│   │   │   │   └── audit.ts
│   │   │   ├── root.ts                   # Root router
│   │   │   └── index.ts
│   │   ├── tsconfig.json
│   │   └── package.json
│   │
│   ├── auth/                             # Authentication package
│   │   ├── src/
│   │   │   ├── config.ts                 # Auth.js configuration
│   │   │   ├── rbac.ts                   # Role-based access control
│   │   │   ├── providers.ts              # OAuth providers
│   │   │   └── index.ts
│   │   ├── tsconfig.json
│   │   └── package.json
│   │
│   ├── ingestion/                        # Source adapters
│   │   ├── src/
│   │   │   ├── adapters/
│   │   │   │   ├── base.ts              # Abstract adapter interface
│   │   │   │   ├── news/
│   │   │   │   │   ├── newsapi.ts
│   │   │   │   │   ├── gdelt.ts
│   │   │   │   │   └── rss.ts
│   │   │   │   ├── academic/
│   │   │   │   │   ├── semantic-scholar.ts
│   │   │   │   │   ├── arxiv.ts
│   │   │   │   │   └── crossref.ts
│   │   │   │   ├── market/
│   │   │   │   │   └── public-apis.ts   # micro-eng/public-apis integration
│   │   │   │   └── index.ts
│   │   │   ├── parser/                   # Content parsers
│   │   │   ├── dedup/                    # Deduplication logic
│   │   │   └── index.ts
│   │   ├── tsconfig.json
│   │   └── package.json
│   │
│   ├── ai/                               # LLM pipeline
│   │   ├── src/
│   │   │   ├── prompts/                  # Prompt templates
│   │   │   │   ├── summarize.ts
│   │   │   │   ├── extract-entities.ts
│   │   │   │   ├── score-signal.ts
│   │   │   │   ├── recommend.ts
│   │   │   │   └── classify.ts
│   │   │   ├── pipeline/                 # Processing pipelines
│   │   │   │   ├── document-pipeline.ts
│   │   │   │   ├── signal-pipeline.ts
│   │   │   │   └── recommendation-pipeline.ts
│   │   │   ├── embedding/                # Embedding generation
│   │   │   ├── hallucination/            # Hallucination detection
│   │   │   ├── cost/                     # Token tracking, budget enforcement
│   │   │   └── index.ts
│   │   ├── tsconfig.json
│   │   └── package.json
│   │
│   ├── signals/                          # Signal processing logic
│   │   ├── src/
│   │   │   ├── scoring.ts
│   │   │   ├── ranking.ts
│   │   │   ├── clustering.ts
│   │   │   ├── dedup.ts
│   │   │   ├── trends.ts
│   │   │   └── index.ts
│   │   ├── tsconfig.json
│   │   └── package.json
│   │
│   ├── ui/                               # Shared UI components
│   │   ├── src/
│   │   │   ├── components/               # shadcn/ui based components
│   │   │   ├── primitives/               # Low-level UI primitives
│   │   │   └── index.ts
│   │   ├── tsconfig.json
│   │   └── package.json
│   │
│   ├── config/                           # Shared configuration
│   │   ├── src/
│   │   │   ├── env.ts                    # Zod-validated env vars
│   │   │   ├── constants.ts
│   │   │   └── index.ts
│   │   ├── tsconfig.json
│   │   └── package.json
│   │
│   └── course-gen/                       # Course generation integration
│       ├── src/
│       │   ├── generator.ts              # codebase-to-course wrapper
│       │   └── index.ts
│       ├── tsconfig.json
│       └── package.json
│
├── infra/
│   ├── terraform/
│   │   ├── modules/
│   │   │   ├── networking/               # VPC, subnets, security groups
│   │   │   ├── database/                 # RDS PostgreSQL + pgvector
│   │   │   ├── cache/                    # ElastiCache Redis
│   │   │   ├── storage/                  # S3 buckets
│   │   │   ├── compute/                  # ECS/Cloud Run for workers
│   │   │   ├── secrets/                  # Secrets Manager
│   │   │   ├── monitoring/               # CloudWatch, Grafana Cloud
│   │   │   └── iam/                      # IAM roles and policies
│   │   ├── environments/
│   │   │   ├── dev/
│   │   │   │   ├── main.tf
│   │   │   │   ├── variables.tf
│   │   │   │   └── terraform.tfvars
│   │   │   ├── staging/
│   │   │   └── prod/
│   │   ├── backend.tf                    # Remote state configuration
│   │   └── versions.tf                   # Provider versions
│   └── docker/
│       ├── Dockerfile.web
│       ├── Dockerfile.workers
│       └── docker-compose.yml            # Local development services
│
├── docs/
│   ├── planning/                         # This planning package
│   ├── adr/                              # Architecture Decision Records
│   └── runbooks/                         # Operational runbooks
│       ├── deployment.md
│       ├── database-migration.md
│       ├── incident-response.md
│       └── source-adapter-guide.md
│
├── scripts/
│   ├── bootstrap.sh                      # First-run workspace setup
│   ├── dev.sh                            # Start development environment
│   ├── seed.sh                           # Seed database with test data
│   ├── health-check.sh                   # Verify workspace is operational
│   ├── generate-course.sh                # Trigger course generation
│   └── validate.sh                       # Run all validation checks
│
├── .github/
│   ├── workflows/
│   │   ├── ci.yml                        # Lint, typecheck, test, build
│   │   ├── deploy-preview.yml            # Preview environment per PR
│   │   ├── deploy-staging.yml            # Auto-deploy to staging on merge
│   │   ├── deploy-prod.yml              # Manual production deployment
│   │   ├── course-gen.yml               # Post-merge course generation
│   │   └── security-scan.yml            # Dependency + secret scanning
│   ├── PULL_REQUEST_TEMPLATE.md
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug-report.yml
│   │   ├── feature-request.yml
│   │   └── epic.yml
│   └── CODEOWNERS
│
├── .claude/
│   ├── settings.json
│   └── commands/
│
├── CLAUDE.md                             # Claude Code development guidance
├── turbo.json                            # Turborepo pipeline configuration
├── package.json                          # Root package.json (workspaces)
├── pnpm-workspace.yaml                  # pnpm workspace definition
├── tsconfig.json                         # Base TypeScript config
├── biome.json                            # Linting + formatting
├── .env.example                          # Environment variable template
├── .gitignore
├── CONTRIBUTING.md
├── README.md
└── CHANGELOG.md
```

---

## Naming Conventions

| Item | Convention | Example |
|------|-----------|---------|
| Packages | `@vse/<name>` | `@vse/db`, `@vse/api`, `@vse/ui` |
| Apps | `@vse/<name>` | `@vse/web`, `@vse/workers` |
| Files | kebab-case | `signal-pipeline.ts`, `news-adapter.ts` |
| Components | PascalCase | `SignalCard.tsx`, `ReportList.tsx` |
| Functions | camelCase | `fetchSignals()`, `scoreDocument()` |
| Types/Interfaces | PascalCase | `Signal`, `SourceAdapter`, `UserRole` |
| Constants | SCREAMING_SNAKE | `MAX_TOKENS`, `DEFAULT_PAGE_SIZE` |
| DB tables | snake_case | `signals`, `audit_logs`, `subject_areas` |
| DB columns | snake_case | `created_at`, `trust_score`, `org_id` |
| Env vars | SCREAMING_SNAKE | `DATABASE_URL`, `ANTHROPIC_API_KEY` |
| Branches | type/area/description | `feat/ingestion/arxiv-adapter` |
| Commits | conventional | `feat(ingestion): add arXiv adapter` |

---

## Shared Library Strategy

| Package | Consumers | Purpose |
|---------|-----------|---------|
| `@vse/config` | All | Validated environment variables, shared constants |
| `@vse/db` | `web`, `workers` | Schema, client, migration utilities |
| `@vse/api` | `web` | tRPC router definitions and types |
| `@vse/auth` | `web` | Auth.js configuration, RBAC helpers |
| `@vse/ui` | `web` | Shared React components |
| `@vse/ingestion` | `workers` | Source adapters |
| `@vse/ai` | `workers`, `web` (for on-demand) | LLM pipeline |
| `@vse/signals` | `workers`, `web` | Signal processing logic |

---

## API Contract Strategy

- **Internal**: tRPC provides automatic type-safe contracts between frontend and backend
- **External**: OpenAPI spec auto-generated from tRPC routers using `trpc-openapi`
- **Location**: `packages/api/src/routers/` (source of truth)
- **Validation**: Zod schemas in router definitions serve as both runtime validation and TypeScript types
- **Documentation**: Auto-generated API docs from OpenAPI spec, hosted at `/api/docs`

---

## Infra Code Location

All infrastructure code lives under `infra/`:
- `infra/terraform/` — IaC modules and environment configs
- `infra/docker/` — Dockerfiles and docker-compose for local development
- Terraform state stored remotely (S3 + DynamoDB for locking)
- Environment-specific variables in `infra/terraform/environments/<env>/terraform.tfvars`
