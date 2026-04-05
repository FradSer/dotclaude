# System Architecture — Venture Signal Engine

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              CLIENTS                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                       │
│  │  Web Browser  │  │  API Client  │  │  Mobile PWA  │                       │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘                       │
└─────────┼──────────────────┼──────────────────┼─────────────────────────────┘
          │                  │                  │
          ▼                  ▼                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         EDGE / CDN LAYER                                     │
│  ┌──────────────────────────────────────────────────────────┐               │
│  │  Vercel / CloudFront — static assets, edge caching       │               │
│  └──────────────────────────┬───────────────────────────────┘               │
└─────────────────────────────┼───────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      APPLICATION LAYER                                       │
│                                                                              │
│  ┌─────────────────────────────────────────────────────┐                    │
│  │              Next.js Application                     │                    │
│  │  ┌───────────────┐  ┌────────────────────────────┐  │                    │
│  │  │  React RSC     │  │   tRPC API Router          │  │                    │
│  │  │  Frontend      │  │   ┌─────────────────────┐  │  │                    │
│  │  │  (App Router)  │  │   │ Auth middleware      │  │  │                    │
│  │  │                │  │   │ Rate limiting        │  │  │                    │
│  │  │  - Dashboard   │  │   │ Input validation     │  │  │                    │
│  │  │  - Search      │  │   │ RBAC enforcement     │  │  │                    │
│  │  │  - Reports     │  │   └─────────────────────┘  │  │                    │
│  │  │  - Settings    │  │                            │  │                    │
│  │  │  - Admin       │  │   Routers:                 │  │                    │
│  │  └───────────────┘  │   - signal.*               │  │                    │
│  │                      │   - source.*               │  │                    │
│  │                      │   - report.*               │  │                    │
│  │                      │   - user.*                 │  │                    │
│  │                      │   - analysis.*             │  │                    │
│  │                      │   - admin.*                │  │                    │
│  │                      └────────────────────────────┘  │                    │
│  └─────────────────────────────────────────────────────┘                    │
└─────────────────────────────┬───────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
┌──────────────────┐ ┌──────────────┐ ┌──────────────────┐
│   AUTH LAYER     │ │  CACHE LAYER │ │   QUEUE LAYER    │
│                  │ │              │ │                  │
│  Auth.js v5      │ │  Redis       │ │  BullMQ + Redis  │
│  ┌────────────┐  │ │  ┌────────┐ │ │  ┌────────────┐  │
│  │ OAuth2     │  │ │  │Session │ │ │  │ Ingestion  │  │
│  │ Google     │  │ │  │API resp│ │ │  │ AI Pipeline│  │
│  │ GitHub     │  │ │  │LLM out │ │ │  │ Report Gen │  │
│  │ OIDC       │  │ │  │Search  │ │ │  │ Scoring    │  │
│  └────────────┘  │ │  └────────┘ │ │  │ Course Gen │  │
│  ┌────────────┐  │ │              │ │  └────────────┘  │
│  │ RBAC       │  │ │              │ │                  │
│  │ Admin      │  │ │              │ │                  │
│  │ Analyst    │  │ │              │ │                  │
│  │ Viewer     │  │ │              │ │                  │
│  └────────────┘  │ │              │ │                  │
└──────────────────┘ └──────────────┘ └────────┬─────────┘
                                               │
                                               ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        WORKER LAYER                                          │
│                                                                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│  │ Ingestion Worker │  │  AI Worker      │  │ Report Worker   │             │
│  │                  │  │                  │  │                  │             │
│  │ - News adapter   │  │ - Summarization │  │ - PDF generation│             │
│  │ - Academic adapt │  │ - Entity extract│  │ - Google Drive  │             │
│  │ - Market adapter │  │ - Signal scoring│  │ - Email delivery│             │
│  │ - RSS adapter    │  │ - Recommendations│ │ - Course gen    │             │
│  │ - PublicAPI adapt│  │ - Embeddings    │  │                  │             │
│  │ - Rate limiting  │  │ - Classification│  │                  │             │
│  │ - Deduplication  │  │ - Hallucination │  │                  │             │
│  │ - Quality check  │  │   mitigation    │  │                  │             │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘             │
└───────────┼─────────────────────┼─────────────────────┼─────────────────────┘
            │                     │                     │
            ▼                     ▼                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          DATA LAYER                                          │
│                                                                              │
│  ┌──────────────────────────┐  ┌────────────────────┐  ┌────────────────┐  │
│  │  PostgreSQL + pgvector   │  │  Redis              │  │  S3 / GDrive   │  │
│  │                          │  │                      │  │                │  │
│  │  Tables:                 │  │  - Job queues        │  │  - PDFs        │  │
│  │  - users                 │  │  - Session store     │  │  - Reports     │  │
│  │  - organizations         │  │  - Rate limit state  │  │  - Raw content │  │
│  │  - sources               │  │  - LLM response cache│  │  - Exports     │  │
│  │  - documents             │  │  - Search cache      │  │                │  │
│  │  - signals               │  │                      │  │                │  │
│  │  - analyses              │  │                      │  │                │  │
│  │  - recommendations       │  │                      │  │                │  │
│  │  - reports               │  │                      │  │                │  │
│  │  - audit_logs            │  │                      │  │                │  │
│  │  - embeddings (pgvector) │  │                      │  │                │  │
│  └──────────────────────────┘  └────────────────────┘  └────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                     OBSERVABILITY LAYER                                       │
│                                                                              │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐  ┌─────────────┐ │
│  │ OpenTelemetry  │  │  Grafana      │  │  Sentry       │  │  Uptime     │ │
│  │ Collector      │  │  Dashboards   │  │  Error Track  │  │  Monitoring │ │
│  │                │  │               │  │               │  │             │ │
│  │ Traces → Tempo │  │ Custom:       │  │ - Exceptions  │  │ - Health    │ │
│  │ Metrics→ Mimir │  │ - Ingestion   │  │ - Perf issues │  │   endpoints │ │
│  │ Logs → Loki    │  │ - AI pipeline │  │ - User impact │  │ - Alerts    │ │
│  │                │  │ - User        │  │               │  │             │ │
│  │                │  │ - System      │  │               │  │             │ │
│  └───────────────┘  └───────────────┘  └───────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Service Boundaries

### 1. Web Application (`apps/web`)
- **Responsibility**: Serve the frontend UI and tRPC API endpoints
- **Technology**: Next.js 15 with App Router, React Server Components
- **Boundary**: Handles HTTP requests, auth sessions, rendering, API routing
- **Does NOT**: Execute long-running jobs, directly call LLM APIs, process raw documents

### 2. Worker Service (`apps/workers`)
- **Responsibility**: Process background jobs from BullMQ queues
- **Technology**: Node.js process consuming BullMQ jobs
- **Sub-workers**:
  - **Ingestion Worker**: Fetches content from configured sources, parses, deduplicates, stores
  - **AI Worker**: Runs LLM pipelines (summarization, entity extraction, scoring, recommendations)
  - **Report Worker**: Generates PDFs, uploads to Google Drive, triggers course generation
- **Boundary**: Stateless processors that read from queue, write to database/storage
- **Does NOT**: Serve HTTP requests, manage auth sessions

### 3. Database Package (`packages/db`)
- **Responsibility**: Schema definition, migrations, seed data, query utilities
- **Technology**: Drizzle ORM with PostgreSQL + pgvector
- **Boundary**: Single source of truth for data model; shared by web and workers

### 4. Auth Package (`packages/auth`)
- **Responsibility**: Auth.js configuration, RBAC logic, session management
- **Boundary**: Shared auth config consumed by web app; RBAC utilities used by API routers

### 5. Ingestion Package (`packages/ingestion`)
- **Responsibility**: Source adapter interfaces and implementations
- **Adapters**: News (NewsAPI, GDELT, RSS), Academic (Semantic Scholar, arXiv, CrossRef), Market (public APIs), Custom
- **Boundary**: Pure data fetching and parsing; no database writes (workers handle persistence)

### 6. AI Package (`packages/ai`)
- **Responsibility**: LLM orchestration, prompt templates, response parsing, cost tracking
- **Technology**: Anthropic Claude SDK, Vercel AI SDK
- **Boundary**: Stateless AI operations; receives content, returns structured results

### 7. Signals Package (`packages/signals`)
- **Responsibility**: Signal processing logic — scoring, ranking, deduplication, clustering
- **Boundary**: Pure business logic; no I/O

---

## Data Flows

### Source Ingestion Flow

```
Source Config ──► Scheduler (cron) ──► BullMQ Queue
                                          │
                                          ▼
                                    Ingestion Worker
                                          │
                    ┌─────────────────────┼─────────────────────┐
                    ▼                     ▼                     ▼
              News Adapter         Academic Adapter       PublicAPI Adapter
                    │                     │                     │
                    ▼                     ▼                     ▼
              Fetch + Parse         Fetch + Parse         Fetch + Parse
                    │                     │                     │
                    └─────────────────────┼─────────────────────┘
                                          │
                                          ▼
                                    Deduplication
                                    (content hash)
                                          │
                                          ▼
                                    Quality Check
                                    (relevance pre-filter)
                                          │
                                          ▼
                                    Store Document
                                    (PostgreSQL)
                                          │
                                          ▼
                                    Enqueue for
                                    AI Processing
```

### Signal Processing Flow

```
New Document ──► AI Worker Queue
                      │
                      ▼
               ┌──────────────┐
               │ Summarization │ ──► Claude API ──► Summary stored
               └──────┬───────┘
                      ▼
               ┌──────────────┐
               │ Entity Extract│ ──► Claude API ──► Entities stored
               └──────┬───────┘
                      ▼
               ┌──────────────┐
               │ Embed Content │ ──► Embedding API ──► pgvector stored
               └──────┬───────┘
                      ▼
               ┌──────────────┐
               │ Signal Score  │ ──► Scoring algorithm ──► Signal created
               └──────┬───────┘     (relevance × novelty
                      │              × source trust × recency)
                      ▼
               ┌──────────────┐
               │ Classify      │ ──► Signal tagged:
               └──────────────┘     investment | BD | strategic | educational
```

### Recommendation / Reporting Flow

```
User Request ──► tRPC API ──► Validate + Auth
                                    │
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
             Signal Query    Trend Analysis    Cluster Detection
             (PostgreSQL)    (time-series)     (pgvector similarity)
                    │               │               │
                    └───────────────┼───────────────┘
                                    │
                                    ▼
                            ┌──────────────┐
                            │ Recommendation│ ──► Claude API
                            │ Generation    │     (structured prompt)
                            └──────┬───────┘
                                    │
                                    ▼
                            ┌──────────────┐
                            │ Hallucination │ ──► Cross-reference against
                            │ Check         │     source documents
                            └──────┬───────┘
                                    │
                                    ▼
                            Store Recommendation
                                    │
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
             Dashboard View   PDF Report      Google Drive Upload
                              Generation      (async via worker)
```

### Audit and Observability Flow

```
Every Operation ──► OpenTelemetry SDK
                         │
              ┌──────────┼──────────┐
              ▼          ▼          ▼
         Trace Span   Metric    Log Entry
              │          │          │
              ▼          ▼          ▼
         OTel Collector (sidecar or agent)
              │          │          │
              ▼          ▼          ▼
           Tempo      Mimir      Loki
              │          │          │
              └──────────┼──────────┘
                         ▼
                    Grafana Dashboards
                         │
                         ├──► Alert Manager ──► PagerDuty/Slack
                         │
                         └──► Sentry (error tracking, session replay)

Audit Trail:
  User Action ──► Middleware ──► audit_logs table
  AI Output   ──► Worker     ──► audit_logs table (with source_document_ids)
  Admin Action──► API Router ──► audit_logs table
```

---

## Core Data Model

```
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│ organizations │────<│    users      │     │ subject_areas │
│               │     │               │     │               │
│ id            │     │ id            │     │ id            │
│ name          │     │ email         │     │ org_id (FK)   │
│ slug          │     │ org_id (FK)   │     │ name          │
│ settings      │     │ role          │     │ keywords[]    │
│ created_at    │     │ created_at    │     │ scope_config  │
└───────────────┘     └───────────────┘     └───────┬───────┘
                                                     │
                           ┌─────────────────────────┘
                           ▼
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│   sources     │────<│  documents    │────<│   signals     │
│               │     │               │     │               │
│ id            │     │ id            │     │ id            │
│ type          │     │ source_id(FK) │     │ document_id   │
│ name          │     │ title         │     │ subject_area  │
│ adapter       │     │ content       │     │ score         │
│ config        │     │ summary       │     │ type          │
│ schedule      │     │ url           │     │ entities[]    │
│ rate_limit    │     │ content_hash  │     │ embedding     │
│ trust_score   │     │ metadata      │     │ classification│
│ enabled       │     │ fetched_at    │     │ created_at    │
└───────────────┘     │ embedding     │     └───────┬───────┘
                      └───────────────┘             │
                                                     │
                      ┌─────────────────────────────┘
                      ▼
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│  analyses     │     │recommendations│     │   reports     │
│               │     │               │     │               │
│ id            │     │ id            │     │ id            │
│ signal_ids[]  │     │ analysis_id   │     │ user_id (FK)  │
│ user_id (FK)  │     │ type          │     │ title         │
│ type          │     │ content       │     │ content       │
│ summary       │     │ confidence    │     │ signals[]     │
│ trends[]      │     │ source_refs[] │     │ format        │
│ clusters[]    │     │ actions[]     │     │ gdrive_url    │
│ created_at    │     │ created_at    │     │ created_at    │
└───────────────┘     └───────────────┘     └───────────────┘

┌───────────────┐
│  audit_logs   │
│               │
│ id            │
│ user_id       │
│ action        │
│ resource_type │
│ resource_id   │
│ metadata      │
│ ip_address    │
│ created_at    │
└───────────────┘
```

---

## Security Architecture

### Authentication Flow
```
User ──► Next.js ──► Auth.js v5
              │
              ├──► Google OAuth2
              ├──► GitHub OAuth2
              └──► (Future: SAML/OIDC for enterprise)
              │
              ▼
         Session created (JWT in httpOnly cookie)
              │
              ▼
         tRPC middleware extracts session
              │
              ▼
         RBAC check against user.role + org membership
```

### RBAC Model
| Role | Permissions |
|------|------------|
| **Admin** | Full access: manage users, sources, settings, view all data |
| **Analyst** | Read/write signals, analyses, reports; configure subject areas |
| **Viewer** | Read-only access to signals, reports; no configuration |

### API Security
- All endpoints require authentication (except health check)
- Rate limiting per user and per organization
- Input validation via Zod schemas (shared with tRPC)
- CSRF protection via Auth.js
- Content Security Policy headers
- CORS restricted to known origins

### Data Encryption
- **In transit**: TLS 1.3 for all connections
- **At rest**: AES-256 for PostgreSQL (provider-managed encryption), S3 server-side encryption
- **Secrets**: Cloud provider secrets manager (AWS Secrets Manager / GCP Secret Manager)
- **API keys**: Encrypted in database, never exposed in API responses

---

## Infrastructure Architecture

```
┌────────────────────────────────────────────────────┐
│                    AWS / GCP                        │
│                                                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐ │
│  │  Vercel   │  │  ECS or  │  │  RDS PostgreSQL  │ │
│  │  (Web)    │  │  Cloud   │  │  + pgvector      │ │
│  │           │  │  Run     │  │                  │ │
│  │  Next.js  │  │ (Workers)│  │  Primary + Read  │ │
│  │  App      │  │          │  │  Replica         │ │
│  └──────────┘  └──────────┘  └──────────────────┘ │
│                                                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐ │
│  │ ElastiC  │  │  S3      │  │  CloudWatch /    │ │
│  │ ache     │  │  Bucket  │  │  Cloud Monitoring│ │
│  │ (Redis)  │  │  (Files) │  │  + Grafana Cloud │ │
│  └──────────┘  └──────────┘  └──────────────────┘ │
│                                                    │
│  ┌──────────┐  ┌──────────┐                       │
│  │ Secrets  │  │ IAM      │                       │
│  │ Manager  │  │ Roles    │                       │
│  └──────────┘  └──────────┘                       │
└────────────────────────────────────────────────────┘

Environments: dev → staging → prod
IaC: Terraform with per-environment state
```
