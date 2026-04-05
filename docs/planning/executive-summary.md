# Executive Summary — Venture Signal Engine

## Product

**Venture Signal Engine (VSE)** is a multi-tenant SaaS web platform that continuously scans academic publications, news sources, market/industry signals, and public API data feeds for user-defined subject areas. It distills fragmented information into structured, actionable outputs:

- **Investment opportunity identification** — surface emerging technologies, markets, and companies
- **Business development recommendations** — identify partnership, licensing, and M&A candidates
- **Strategic augmentation and pivot opportunities** — detect shifts that warrant strategic repositioning
- **Startup and enterprise use cases** — map capabilities to market needs
- **Capability-building and educational opportunities** — auto-generate learning materials from analysis artifacts

The platform moves users from information overload to structured strategic decisions, powered by AI-assisted analysis pipelines.

---

## Current Repo/Workspace Maturity

| Dimension | Status |
|-----------|--------|
| Application code | **None** — repo is a Claude Code plugin marketplace (15 plugins, Markdown/Bash/Python) |
| Package management | **None** — no package.json, tsconfig, pyproject.toml |
| CI/CD | **None** — no GitHub Actions, no deployment pipelines |
| Infrastructure-as-code | **None** — no Terraform, Docker, or container config |
| Database | **None** — no schema, migrations, or ORM |
| Auth | **None** — no auth system |
| Testing | **Minimal** — one Python test for plugin validation |
| Observability | **None** — no logging, metrics, or tracing |
| Security | **Basic** — .gitignore covers .env files; no scanning, no secrets management |
| Documentation | **Strong for plugins** — CLAUDE.md, README, CHANGELOG exist for the plugin marketplace |

**Verdict**: This is a **100% greenfield build** for the Venture Signal Engine. The existing plugin marketplace provides zero reusable application code but does offer useful patterns for git conventions, validation scripts, and documentation structure.

---

## Recommended Architecture Direction

### Stack
**TypeScript-first monorepo** using modern, well-supported tools:

| Layer | Technology |
|-------|-----------|
| Frontend | Next.js 15 (App Router) + Tailwind CSS + shadcn/ui |
| Backend API | Next.js API routes + tRPC (end-to-end type safety) |
| Database | PostgreSQL + pgvector (relational + vector search) |
| ORM | Drizzle ORM (type-safe, migration-first) |
| Auth | Auth.js v5 (OAuth2/OIDC, RBAC) |
| Queue/Jobs | BullMQ + Redis (ingestion workers, AI pipelines) |
| LLM | Anthropic Claude SDK + Vercel AI SDK |
| Search | PostgreSQL full-text search + pgvector hybrid |
| Observability | OpenTelemetry + Grafana (Loki/Tempo/Mimir) |
| CI/CD | GitHub Actions |
| IaC | Terraform |
| Testing | Vitest + Playwright + Testing Library |
| Monorepo | Turborepo + pnpm workspaces |
| File Storage | Google Drive API + S3 (PDF storage) |
| Course Generation | codebase-to-course skill (post-epic automation) |

### Why This Stack
- **TypeScript end-to-end** eliminates serialization bugs and enables shared types
- **Next.js + tRPC** collocates frontend and API with zero code generation
- **PostgreSQL + pgvector** avoids the operational cost of a separate vector database
- **BullMQ** provides reliable, observable job processing with rate limiting
- **Turborepo** enables incremental builds and task caching across packages

---

## Delivery Strategy

### Phased Approach (8 phases)
1. **Phase 0**: Discovery and repo assessment ← **COMPLETE** (this document)
2. **Phase 1**: Repo/workspace/bootstrap foundation (CI/CD, lint, test, Docker, env)
3. **Phase 2**: Infrastructure and platform services (DB, cache, queue, auth, IaC)
4. **Phase 3**: Backend and ingestion foundation (data model, source adapters, workers)
5. **Phase 4**: Frontend shell and design system (layout, navigation, auth flows)
6. **Phase 5**: MVP workflows (signal dashboard, search, analysis, reports)
7. **Phase 6**: Hardening and launch readiness (security, performance, observability)
8. **Phase 7**: Post-MVP scale (multi-tenant, advanced AI, integrations, educational content)

### Estimated Timeline
- **Phase 1-2**: 2-3 sprints (bootstrap + infra)
- **Phase 3-4**: 2-3 sprints (foundation)
- **Phase 5**: 3-4 sprints (MVP features)
- **Phase 6**: 1-2 sprints (hardening)
- **Total to MVP**: ~10-12 sprints

---

## Most Important Build-Before-Build Requirements

These must exist **before any feature code is written**:

| Priority | Item | Why |
|----------|------|-----|
| 1 | Monorepo scaffold with Turborepo + pnpm | All code depends on package structure |
| 2 | TypeScript configuration (strict mode) | Type safety from day one |
| 3 | CI pipeline (lint, type-check, test, build) | Prevents regression from first commit |
| 4 | PostgreSQL + Drizzle schema + migrations | Data model is foundational |
| 5 | Auth.js setup with RBAC skeleton | Every endpoint needs auth |
| 6 | Docker Compose for local development | Reproducible dev environment |
| 7 | Environment variable strategy (.env.example + Zod validation) | Secure, validated config |
| 8 | GitHub Actions CI/CD skeleton | Automated quality gates |
| 9 | OpenTelemetry instrumentation baseline | Observability from first request |
| 10 | Pre-commit hooks (Biome lint/format, type-check) | Code quality enforcement |

---

## Key Integrations from Referenced Repos

| Repo | Integration |
|------|-------------|
| `micro-eng/public-apis` | Seed ingestion pipeline with 1000+ cataloged API endpoints as data sources |
| `micro-eng/autoresearch-macos` | Adopt autonomous research agent pattern — `program.md`-driven directives, iterative experiment loops, fixed cost budgets |
| `micro-eng/codebase-to-course` | Post-epic hook generates educational courses from codebase; install as Claude Code skill |
| `micro-eng/dotclaude` | Replicate infrastructure patterns: CLAUDE.md guidance, git commit validation hooks, plugin-based organization, validation scripts |

---

## Decision: Separate Repo

The Venture Signal Engine should live in its **own repository**, not mixed into the plugin marketplace. Rationale:

1. Different concerns (SaaS app vs. Claude Code plugins)
2. Different CI/CD pipelines and deployment targets
3. Different team composition and access control
4. Different versioning cadence
5. Avoids polluting plugin marketplace with app dependencies

Planning documents are placed in this repo (`docs/planning/`) as requested. The actual application code will be bootstrapped in a new `venture-signal-engine` repository. See `ADR-0002` for full decision record.
