# Team and Skills — Venture Signal Engine

## Required Roles

### 1. Product Manager

| Attribute | Detail |
|-----------|--------|
| **Responsibilities** | Define product vision, prioritize backlog, validate MVP scope, user research, stakeholder communication, acceptance criteria |
| **Must-have skills** | Product strategy, user story writing, analytics literacy, competitive analysis, AI product management |
| **Nice-to-have** | Technical background, venture capital/BD domain knowledge, data product experience |
| **Phase involvement** | Phase 0-1: 80% (scope, requirements); Phase 2-4: 40% (backlog grooming); Phase 5+: 60% (validation, iteration) |

### 2. UX/UI Designer

| Attribute | Detail |
|-----------|--------|
| **Responsibilities** | User research, information architecture, wireframes, UI design, design system, usability testing |
| **Must-have skills** | Figma, responsive web design, data visualization design, design systems, accessibility (WCAG 2.1) |
| **Nice-to-have** | Dashboard/analytics product design, B2B SaaS experience, shadcn/ui familiarity |
| **Phase involvement** | Phase 0-1: 60% (research, IA); Phase 3-4: 80% (design system, core screens); Phase 5: 60% (iteration); Phase 6+: 20% |

### 3. Frontend Engineer (1-2)

| Attribute | Detail |
|-----------|--------|
| **Responsibilities** | Build web UI, implement design system, integrate with tRPC API, state management, client-side performance |
| **Must-have skills** | TypeScript, React 19, Next.js 15 (App Router, RSC), Tailwind CSS, tRPC client, testing (Vitest, Playwright) |
| **Nice-to-have** | shadcn/ui, data visualization (D3, Recharts), real-time UIs, accessibility engineering |
| **Phase involvement** | Phase 1: 20% (scaffold); Phase 4: 100% (frontend shell); Phase 5: 80% (features); Phase 6: 60% (polish) |

### 4. Backend Engineer (1-2)

| Attribute | Detail |
|-----------|--------|
| **Responsibilities** | tRPC API implementation, database schema, business logic, background job processing, performance optimization |
| **Must-have skills** | TypeScript, Node.js, PostgreSQL, Drizzle ORM, tRPC, BullMQ, REST API design, testing (Vitest) |
| **Nice-to-have** | pgvector, Redis, queue architecture, data pipeline experience, Auth.js |
| **Phase involvement** | Phase 1: 30% (scaffold); Phase 2-3: 100% (foundation); Phase 5: 80% (features); Phase 6: 60% |

### 5. Platform / DevOps Engineer (1)

| Attribute | Detail |
|-----------|--------|
| **Responsibilities** | CI/CD pipelines, infrastructure-as-code, Docker, cloud provisioning, monitoring, developer experience, security scanning |
| **Must-have skills** | GitHub Actions, Terraform, AWS (or GCP), Docker, PostgreSQL administration, Redis, networking, Linux |
| **Nice-to-have** | Vercel deployment, OpenTelemetry, Grafana, ECS Fargate, cost optimization |
| **Phase involvement** | Phase 1: 100% (bootstrap); Phase 2: 100% (infra); Phase 3-5: 40% (support); Phase 6: 80% (hardening) |

### 6. Security Engineer (part-time or consultant)

| Attribute | Detail |
|-----------|--------|
| **Responsibilities** | Security architecture review, auth design, secret management, dependency scanning, OWASP compliance, penetration testing |
| **Must-have skills** | OAuth2/OIDC, RBAC design, OWASP Top 10, secret scanning, SAST/DAST, AWS IAM |
| **Nice-to-have** | SOC 2 readiness, data privacy (GDPR), threat modeling |
| **Phase involvement** | Phase 1: 20% (auth design); Phase 2: 40% (infra security); Phase 5: 20% (review); Phase 6: 60% (hardening) |

### 7. Data Engineer (1)

| Attribute | Detail |
|-----------|--------|
| **Responsibilities** | Design ingestion pipelines, source adapters, data quality, deduplication, ETL workflows, data model optimization |
| **Must-have skills** | TypeScript/Python, API integration, data parsing (PDF, HTML, JSON), scheduling, rate limiting, data quality |
| **Nice-to-have** | Academic API experience (Semantic Scholar, arXiv), news API experience, web scraping, data lakehouse |
| **Phase involvement** | Phase 2: 20% (schema); Phase 3: 100% (ingestion); Phase 5: 60% (adapters); Phase 7: 80% (scale) |

### 8. ML/LLM Engineer (1)

| Attribute | Detail |
|-----------|--------|
| **Responsibilities** | LLM prompt engineering, summarization pipeline, entity extraction, signal scoring, embedding generation, hallucination mitigation, cost optimization |
| **Must-have skills** | Anthropic Claude API, prompt engineering, structured output, embedding models, vector similarity, TypeScript |
| **Nice-to-have** | LangChain/Vercel AI SDK, evaluation frameworks, fine-tuning, cost/token budgeting, autoresearch patterns |
| **Phase involvement** | Phase 2: 10% (design); Phase 3: 80% (AI pipeline); Phase 5: 80% (features); Phase 7: 100% (advanced) |

### 9. QA / Automation Engineer (part-time)

| Attribute | Detail |
|-----------|--------|
| **Responsibilities** | Test strategy, E2E test suite, regression testing, performance testing, test data management |
| **Must-have skills** | Playwright, Vitest, test automation, API testing, CI integration |
| **Nice-to-have** | Performance testing (k6), accessibility testing, AI output quality testing |
| **Phase involvement** | Phase 1: 10% (framework); Phase 4-5: 60% (test suites); Phase 6: 100% (hardening) |

### 10. Analytics Engineer (post-MVP, part-time)

| Attribute | Detail |
|-----------|--------|
| **Responsibilities** | Product analytics, usage tracking, funnel analysis, A/B test analysis, reporting on platform effectiveness |
| **Must-have skills** | Analytics tools (PostHog, Mixpanel), SQL, data visualization, experiment design |
| **Nice-to-have** | dbt, data modeling, product-led growth metrics |
| **Phase involvement** | Phase 5: 20% (instrumentation); Phase 7+: 60% (optimization) |

### 11. Technical Writer (part-time)

| Attribute | Detail |
|-----------|--------|
| **Responsibilities** | API documentation, user guides, runbooks, ADRs, onboarding materials, course content review |
| **Must-have skills** | Technical writing, Markdown, API documentation, user-facing help content |
| **Nice-to-have** | Developer documentation, codebase-to-course review, video documentation |
| **Phase involvement** | Phase 1: 20% (initial docs); Phase 5: 40% (user docs); Phase 6: 60% (launch docs) |

---

## Team Composition by Phase

### Phase 1: Bootstrap (Sprint 1-2)
| Role | FTE | Focus |
|------|-----|-------|
| Platform/DevOps | 1.0 | Repo scaffold, CI/CD, Docker, dev environment |
| Backend Engineer | 0.3 | Schema design assistance, tRPC scaffold |
| Tech Lead | 0.5 | CLAUDE.md, architecture docs, ADRs, standards |
| **Total** | **~2 FTE** | |

### Phase 2: Infrastructure (Sprint 2-3)
| Role | FTE | Focus |
|------|-----|-------|
| Platform/DevOps | 1.0 | Terraform, cloud provisioning, monitoring |
| Backend Engineer | 1.0 | Database, auth, API foundation |
| Security Engineer | 0.4 | Auth design, IAM, secret management |
| **Total** | **~2.5 FTE** | |

### Phase 3: Foundation (Sprint 3-5)
| Role | FTE | Focus |
|------|-----|-------|
| Backend Engineer | 1.0 | Business logic, workers |
| Data Engineer | 1.0 | Ingestion pipeline, source adapters |
| ML/LLM Engineer | 0.8 | AI pipeline, prompts, scoring |
| Platform/DevOps | 0.4 | Support, scaling |
| **Total** | **~3.2 FTE** | |

### Phase 4-5: Frontend + MVP (Sprint 5-9)
| Role | FTE | Focus |
|------|-----|-------|
| Frontend Engineer | 1.5 | UI implementation |
| Backend Engineer | 1.0 | API endpoints, features |
| ML/LLM Engineer | 0.8 | AI features, recommendations |
| Data Engineer | 0.6 | Additional adapters |
| UX/UI Designer | 0.6 | Design iteration |
| QA Engineer | 0.5 | Test suites |
| Product Manager | 0.5 | Validation |
| **Total** | **~5.5 FTE** | |

### Phase 6: Hardening (Sprint 10-11)
| Role | FTE | Focus |
|------|-----|-------|
| Platform/DevOps | 0.8 | Performance, monitoring, alerts |
| Security Engineer | 0.6 | Security audit, penetration testing |
| QA Engineer | 1.0 | Full regression, E2E |
| Frontend Engineer | 0.6 | Performance, accessibility |
| Backend Engineer | 0.6 | Optimization, error handling |
| Technical Writer | 0.6 | Launch docs |
| **Total** | **~4.2 FTE** | |

---

## Minimum Viable Team

For a lean startup approach, the **minimum team** to deliver MVP:

| # | Role | Notes |
|---|------|-------|
| 1 | **Full-stack Lead** | Backend + frontend + architecture decisions |
| 2 | **Platform/DevOps** | CI/CD + infra + dev environment |
| 3 | **ML/LLM + Data Engineer** | AI pipeline + ingestion (combined role) |
| 4 | **Product Manager** | Part-time, scope and priority decisions |

**Total: 3.5 FTE** — viable with strong individual contributors and Claude Code assistance for code generation and review.
