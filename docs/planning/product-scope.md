# Product Scope — Venture Signal Engine

## Target Users

### Primary Personas

| Persona | Role | Goal |
|---------|------|------|
| **Strategic Analyst** | Venture capital analyst, corporate strategy team member | Identify investment-worthy signals in a defined domain |
| **Business Development Lead** | BD/partnerships manager at tech company | Find partnership, licensing, and M&A candidates |
| **Innovation Manager** | R&D or innovation team lead at enterprise | Detect emerging technologies that could augment current capabilities |
| **Startup Founder** | Early-stage founder exploring market adjacencies | Validate market opportunities and find white space |
| **Research Director** | Academic or corporate research lead | Track research frontiers and identify commercialization pathways |

### Secondary Personas

| Persona | Role | Goal |
|---------|------|------|
| **Platform Admin** | Internal team managing the VSE instance | Configure sources, manage users, monitor system health |
| **Content Consumer** | Executive receiving reports | Consume distilled, actionable summaries without raw data interaction |

---

## Jobs-to-Be-Done

| JTBD | Description |
|------|-------------|
| **Monitor a domain** | "When I define a subject area, I want the platform to continuously scan relevant sources so I always have a current picture." |
| **Surface signals** | "When new research, news, or market activity appears, I want it scored and ranked so I focus on what matters most." |
| **Understand context** | "When I see a signal, I want AI-generated summaries and entity relationships so I understand its significance quickly." |
| **Generate recommendations** | "When signals cluster into patterns, I want actionable recommendations for investment, partnerships, or pivots." |
| **Create reports** | "When I need to share findings, I want structured reports I can export and present to stakeholders." |
| **Learn continuously** | "When epics ship and the platform evolves, I want auto-generated educational content that helps me understand the system." |
| **Store and organize** | "When I find important documents, I want them saved to Google Drive with proper organization." |

---

## MVP Scope (Phase 5 deliverable)

### In Scope

| Feature | Description |
|---------|-------------|
| **Subject area definition** | User defines domains of interest with keywords, categories, and scope parameters |
| **Source configuration** | Admin connects news APIs, academic databases (Semantic Scholar, arXiv, CrossRef), and selected public APIs |
| **Automated ingestion** | Background workers fetch, parse, and store content from configured sources on schedule |
| **Signal extraction** | AI pipeline extracts entities, topics, and relevance scores from ingested content |
| **Signal dashboard** | Filterable, sortable view of extracted signals with relevance scores and summaries |
| **Search** | Full-text + semantic hybrid search across all ingested content and signals |
| **AI summarization** | On-demand and batch summarization of signals, clusters, and trends |
| **Basic recommendations** | AI-generated investment/BD/strategy recommendations based on signal patterns |
| **Report generation** | Export structured reports as PDF and save to Google Drive |
| **User authentication** | OAuth2 login (Google, GitHub) with role-based access (Admin, Analyst, Viewer) |
| **Basic audit trail** | Log all user actions and AI pipeline executions |
| **Responsive web UI** | Desktop-first with mobile-responsive layout |

### Out of MVP Scope (Post-MVP)

| Feature | Target Phase |
|---------|-------------|
| Multi-tenant organization isolation | Phase 7 |
| Custom scoring models per user | Phase 7 |
| Real-time streaming ingestion | Phase 7 |
| Collaborative annotations and comments | Phase 7 |
| Slack/Teams/email notifications | Phase 7 |
| API marketplace for third-party integrations | Phase 7+ |
| Advanced charting and data visualization | Phase 7 |
| Autonomous research agents (autoresearch pattern) | Phase 7+ |
| White-label/embedded deployment | Phase 8+ |
| Mobile native app | Phase 8+ |
| Course generation from analysis artifacts | Phase 7 |

---

## Explicit Assumptions

| # | Assumption |
|---|-----------|
| A1 | The platform will be deployed to a single cloud provider (AWS recommended, GCP acceptable) |
| A2 | Anthropic Claude is the primary LLM; no multi-model orchestration for MVP |
| A3 | PostgreSQL with pgvector handles both relational and vector search needs for MVP |
| A4 | Users authenticate via OAuth2 providers (Google, GitHub); no username/password for MVP |
| A5 | A team of 3-5 engineers can deliver MVP in 10-12 sprints |
| A6 | Academic source APIs (Semantic Scholar, arXiv, CrossRef) are freely available |
| A7 | News sources are accessed via free tiers or existing subscriptions (NewsAPI, GDELT, RSS) |
| A8 | Public APIs from `micro-eng/public-apis` provide supplementary data feeds |
| A9 | Google Drive API is used for PDF storage and document organization |
| A10 | The `codebase-to-course` skill generates educational content post-merge via CI hook |
| A11 | The platform starts as single-tenant with multi-tenant architecture designed in |
| A12 | LLM costs are managed via caching, batching, and token budgets per operation |

---

## Non-Functional Requirements

| Category | Requirement |
|----------|-------------|
| **Performance** | Dashboard loads in < 2s; search returns in < 1s; ingestion processes 1000 documents/hour |
| **Availability** | 99.5% uptime SLA for MVP; 99.9% post-MVP |
| **Scalability** | Support 100 concurrent users for MVP; 10,000 post-MVP |
| **Security** | OWASP Top 10 compliance; encrypted at rest and in transit; RBAC enforced |
| **Data retention** | Configurable per organization; default 2 years; GDPR-aware delete |
| **Observability** | All services emit OpenTelemetry traces; structured JSON logging; error budgets |
| **Accessibility** | WCAG 2.1 AA compliance for web UI |
| **API** | REST/tRPC with OpenAPI spec; rate-limited; versioned |
| **Backup** | Daily automated database backups; point-in-time recovery for 30 days |
| **Cost** | LLM spend capped per organization; ingestion rate limits configurable |
| **Auditability** | All user actions logged; all AI outputs traceable to source inputs |
| **Internationalization** | English-only for MVP; i18n-ready architecture |

---

## Compliance and Security Assumptions

| Item | Assumption |
|------|-----------|
| **Data classification** | Ingested content is publicly available (academic papers, news, public APIs) — no PII ingestion for MVP |
| **Copyright** | Platform stores metadata and AI-generated summaries, not full copyrighted text. Source links provided for attribution |
| **GDPR** | User data (accounts, preferences, reports) is GDPR-compliant with delete capability |
| **SOC 2** | Architecture designed to support future SOC 2 Type II audit, but not pursued for MVP |
| **Encryption** | TLS 1.3 in transit; AES-256 at rest for database and object storage |
| **Access control** | RBAC with organization-scoped permissions; admin can manage users |
| **Secret management** | All secrets in cloud provider's secrets manager (AWS Secrets Manager or GCP Secret Manager) |
| **Dependency scanning** | Automated via CI; critical vulnerabilities block merge |

---

## Pre-Project Setup Features (Before PRD)

Inspired by referenced repos, these capabilities must be established before feature development:

| Feature | Source |
|---------|--------|
| CLAUDE.md development guidance for VSE repo | `micro-eng/dotclaude` |
| Git commit validation hooks (conventional commits) | `micro-eng/dotclaude` git plugin |
| Plugin-style modular organization for source adapters | `micro-eng/dotclaude` plugin pattern |
| Autonomous research agent pattern for AI pipeline | `micro-eng/autoresearch-macos` |
| Post-merge course generation CI workflow | `micro-eng/codebase-to-course` |
| Public API data source registry | `micro-eng/public-apis` |
| Google Drive integration for PDF storage | User requirement |
| Validation scripts with severity levels | `micro-eng/dotclaude` plugin-optimizer pattern |
