# Infrastructure Prerequisites — Venture Signal Engine

## Environment Model

| Environment | Purpose | Deployment | Data |
|-------------|---------|------------|------|
| **Local** | Developer workstation | Docker Compose | Seed/mock data |
| **Dev** | Shared development, integration testing | Auto-deploy from feature branches | Seed data + limited real sources |
| **Staging** | Pre-production validation | Auto-deploy on merge to main | Production-like data (anonymized) |
| **Production** | Live users | Manual promotion from staging | Real data |

---

## Cloud Provider Recommendation

**Primary**: AWS (mature ecosystem, broadest service coverage)
**Alternative**: GCP (if team has existing GCP expertise)

### Accounts/Projects Structure

```
AWS Organization
├── Management Account (billing, IAM Identity Center)
├── Dev Account
│   ├── VPC, RDS, ElastiCache, ECS, S3
│   └── Terraform state: s3://vse-terraform-state-dev
├── Staging Account
│   ├── VPC, RDS, ElastiCache, ECS, S3
│   └── Terraform state: s3://vse-terraform-state-staging
└── Production Account
    ├── VPC, RDS, ElastiCache, ECS, S3
    └── Terraform state: s3://vse-terraform-state-prod
```

---

## Infrastructure Components

### 1. Networking

| Item | What to Provision | Why | Pre-MVP? | Owner |
|------|------------------|-----|----------|-------|
| **VPC** | Isolated VPC per environment with public/private subnets | Network isolation, security | Yes | Platform/DevOps |
| **Security Groups** | Ingress/egress rules for each service | Least-privilege network access | Yes | Platform/DevOps |
| **NAT Gateway** | Outbound internet for private subnets | Workers need to fetch external sources | Yes | Platform/DevOps |
| **Load Balancer** | ALB for web application | HTTPS termination, health checks | Yes (staging/prod) | Platform/DevOps |

**IaC location**: `infra/terraform/modules/networking/`

### 2. DNS and Domain

| Item | What to Provision | Why | Pre-MVP? | Owner |
|------|------------------|-----|----------|-------|
| **Domain** | `venturesignal.com` or similar | Public-facing URL | Yes | Product/Platform |
| **Route 53 / Cloud DNS** | Hosted zone with A/CNAME records | DNS management | Yes | Platform/DevOps |
| **Subdomains** | `app.venturesignal.com`, `api.venturesignal.com`, `staging.venturesignal.com` | Environment separation | Yes | Platform/DevOps |

### 3. TLS/Certificates

| Item | What to Provision | Why | Pre-MVP? | Owner |
|------|------------------|-----|----------|-------|
| **ACM Certificate** | Wildcard cert `*.venturesignal.com` | HTTPS for all endpoints | Yes | Platform/DevOps |
| **Auto-renewal** | ACM handles renewal automatically | No manual cert management | Yes | Platform/DevOps |

### 4. Database

| Item | What to Provision | Why | Pre-MVP? | Owner |
|------|------------------|-----|----------|-------|
| **RDS PostgreSQL 16** | Primary instance with pgvector extension | Core data store + vector search | Yes | Platform/DevOps |
| **Read replica** | Single read replica | Offload read-heavy queries (signals, search) | No (post-MVP) | Platform/DevOps |
| **Instance sizing** | Dev: `db.t4g.small`; Staging: `db.t4g.medium`; Prod: `db.r7g.large` | Cost-appropriate sizing | Yes | Platform/DevOps |
| **Automated backups** | Daily snapshots, 30-day retention | Data recovery | Yes | Platform/DevOps |
| **Point-in-time recovery** | Enabled with 7-day window | Granular recovery | Yes | Platform/DevOps |
| **Encryption** | AES-256 encryption at rest (KMS) | Data protection | Yes | Platform/DevOps |

**IaC location**: `infra/terraform/modules/database/`

**pgvector setup**: Installed via migration:
```sql
CREATE EXTENSION IF NOT EXISTS vector;
```

### 5. Cache (Redis)

| Item | What to Provision | Why | Pre-MVP? | Owner |
|------|------------------|-----|----------|-------|
| **ElastiCache Redis 7** | Single-node cluster | Session store, BullMQ backing, LLM response cache, rate limiting | Yes | Platform/DevOps |
| **Instance sizing** | Dev: `cache.t4g.micro`; Staging: `cache.t4g.small`; Prod: `cache.r7g.large` | Cost-appropriate | Yes | Platform/DevOps |
| **Encryption** | In-transit + at-rest encryption | Data protection | Yes | Platform/DevOps |

**IaC location**: `infra/terraform/modules/cache/`

### 6. Queue / Eventing

| Item | What to Provision | Why | Pre-MVP? | Owner |
|------|------------------|-----|----------|-------|
| **BullMQ (via Redis)** | Job queues for ingestion, AI pipeline, reports | Reliable async processing with retries, priorities, rate limiting | Yes | Backend |
| **Queue types** | `ingestion`, `ai-pipeline`, `report-gen`, `course-gen` | Separation of concerns, independent scaling | Yes | Backend |

BullMQ runs on the same Redis instance as cache (separate database number). No additional infrastructure needed.

### 7. Object Storage

| Item | What to Provision | Why | Pre-MVP? | Owner |
|------|------------------|-----|----------|-------|
| **S3 bucket (documents)** | `vse-documents-{env}` | Store raw ingested documents, parsed content | Yes | Platform/DevOps |
| **S3 bucket (reports)** | `vse-reports-{env}` | Store generated PDF reports | Yes | Platform/DevOps |
| **S3 bucket (assets)** | `vse-assets-{env}` | Static assets, course outputs | Parallel | Platform/DevOps |
| **Lifecycle policies** | Move to IA after 90 days, Glacier after 365 | Cost optimization | Post-MVP | Platform/DevOps |
| **Google Drive integration** | OAuth2 service account for PDF upload | User requirement: save PDFs to Google Drive | Yes | Backend |

**IaC location**: `infra/terraform/modules/storage/`

### 8. Compute (Workers)

| Item | What to Provision | Why | Pre-MVP? | Owner |
|------|------------------|-----|----------|-------|
| **ECS Fargate** | Container service for worker processes | Serverless containers, auto-scaling | Yes | Platform/DevOps |
| **Task definitions** | Separate tasks for ingestion, AI, report workers | Independent scaling per workload | Yes | Platform/DevOps |
| **Auto-scaling** | CPU/memory-based scaling policies | Handle variable ingestion load | Parallel | Platform/DevOps |

**Alternative**: Cloud Run (GCP) or Railway (simpler, higher cost)

**IaC location**: `infra/terraform/modules/compute/`

### 9. Web Hosting

| Item | What to Provision | Why | Pre-MVP? | Owner |
|------|------------------|-----|----------|-------|
| **Vercel** | Next.js hosting with edge functions | Zero-config Next.js deployment, preview envs, edge caching | Yes | Platform/DevOps |
| **Alternative** | ECS Fargate + ALB | Full control, but more operational overhead | Consider post-MVP | Platform/DevOps |

Vercel is recommended for MVP to minimize operational burden. Production workloads can migrate to self-hosted if needed.

### 10. Auth Provider

| Item | What to Provision | Why | Pre-MVP? | Owner |
|------|------------------|-----|----------|-------|
| **Google OAuth2 app** | Client ID + secret for Google login | Primary auth provider | Yes | Backend + Security |
| **GitHub OAuth2 app** | Client ID + secret for GitHub login | Developer-friendly auth | Yes | Backend + Security |
| **Auth.js** | Configured in application code | Session management, RBAC | Yes | Backend |

No external auth provider (Auth0, Clerk) needed for MVP — Auth.js handles it directly.

### 11. Secrets Management

| Item | What to Provision | Why | Pre-MVP? | Owner |
|------|------------------|-----|----------|-------|
| **AWS Secrets Manager** | Secrets for each environment | Secure storage of API keys, DB passwords, OAuth secrets | Yes | Platform/DevOps + Security |
| **Secrets list** | `DATABASE_URL`, `REDIS_URL`, `ANTHROPIC_API_KEY`, `GOOGLE_CLIENT_SECRET`, `GITHUB_CLIENT_SECRET`, `GOOGLE_DRIVE_SERVICE_ACCOUNT_KEY` | Application configuration | Yes | Platform/DevOps |
| **Rotation policy** | 90-day rotation for database passwords | Security hygiene | Post-MVP | Security |

**IaC location**: `infra/terraform/modules/secrets/`

### 12. Key Management / Encryption

| Item | What to Provision | Why | Pre-MVP? | Owner |
|------|------------------|-----|----------|-------|
| **KMS key** | Customer-managed key for RDS, S3, Secrets Manager | Encryption key management | Yes | Platform/DevOps |
| **Key rotation** | Annual automatic rotation | Security best practice | Yes | Platform/DevOps |

### 13. Logging / Metrics / Tracing

| Item | What to Provision | Why | Pre-MVP? | Owner |
|------|------------------|-----|----------|-------|
| **Grafana Cloud** (or self-hosted) | Observability platform | Unified logs, metrics, traces | Yes | Platform/DevOps |
| **Loki** | Log aggregation | Structured log search and analysis | Yes | Platform/DevOps |
| **Tempo** | Distributed tracing | Request tracing across services | Yes | Platform/DevOps |
| **Mimir** | Metrics storage | Custom metrics, dashboards, alerting | Parallel | Platform/DevOps |
| **Sentry** | Error tracking | Real-time error detection and triage | Yes | Platform/DevOps |

**Alternative**: AWS CloudWatch (simpler, vendor-locked) for MVP, migrate to Grafana later

### 14. Alerting

| Item | What to Provision | Why | Pre-MVP? | Owner |
|------|------------------|-----|----------|-------|
| **Grafana alerting** | Alert rules for key metrics | Detect issues before users do | Parallel | Platform/DevOps |
| **PagerDuty or Slack** | Alert routing and escalation | On-call notification | Parallel | Platform/DevOps |
| **Key alerts** | Error rate > 1%, P99 latency > 5s, queue depth > 1000, disk > 80%, failed jobs > 10/min | Critical operational signals | Parallel | Platform/DevOps |

### 15. Backups and Disaster Recovery

| Item | What to Provision | Why | Pre-MVP? | Owner |
|------|------------------|-----|----------|-------|
| **RDS automated backups** | Daily, 30-day retention | Database recovery | Yes | Platform/DevOps |
| **S3 versioning** | Object versioning on document/report buckets | Recover deleted/overwritten files | Yes | Platform/DevOps |
| **Cross-region replication** | S3 replication to secondary region | Disaster recovery | Post-MVP | Platform/DevOps |
| **RDS cross-region replica** | Standby in secondary region | Disaster recovery | Post-MVP | Platform/DevOps |
| **RTO/RPO targets** | RTO: 4 hours, RPO: 1 hour (MVP); RTO: 1 hour, RPO: 15 min (post-MVP) | Recovery objectives | Documented | Platform/DevOps |

### 16. Budgets and Cost Controls

| Item | What to Provision | Why | Pre-MVP? | Owner |
|------|------------------|-----|----------|-------|
| **AWS Budgets** | Monthly budget alerts at 50%, 80%, 100% | Prevent cost overruns | Yes | Platform/DevOps |
| **LLM cost tracking** | Per-org token usage tracking in application | Control AI spend | Yes | Backend |
| **Estimated monthly cost** | Dev: ~$150/mo; Staging: ~$300/mo; Prod: ~$800-1500/mo | Budget planning | Documented | Platform/DevOps |

---

## IAM / Least-Privilege Model

| Principal | Permissions | Scope |
|-----------|------------|-------|
| **CI/CD runner** | Deploy to ECS, update Vercel, read/write S3, read secrets | Per-environment |
| **Web app** | Read/write RDS, read/write Redis, read secrets, read/write S3 | Per-environment |
| **Workers** | Read/write RDS, read/write Redis, read secrets, read/write S3, invoke Anthropic API | Per-environment |
| **Terraform** | Full infrastructure management | Per-account |
| **Developers** | Read-only production; full access dev/staging | Per-account |
| **On-call** | Read logs, restart services, scale tasks | Production |

**IaC location**: `infra/terraform/modules/iam/`

---

## IaC Module Layout

```
infra/terraform/
├── modules/
│   ├── networking/
│   │   ├── main.tf          # VPC, subnets, NAT, security groups
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── database/
│   │   ├── main.tf          # RDS PostgreSQL + pgvector
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── cache/
│   │   ├── main.tf          # ElastiCache Redis
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── storage/
│   │   ├── main.tf          # S3 buckets
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── compute/
│   │   ├── main.tf          # ECS Fargate tasks
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── secrets/
│   │   ├── main.tf          # Secrets Manager entries
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── monitoring/
│   │   ├── main.tf          # CloudWatch, Grafana Cloud
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── iam/
│       ├── main.tf          # IAM roles and policies
│       ├── variables.tf
│       └── outputs.tf
├── environments/
│   ├── dev/
│   │   ├── main.tf          # Module composition
│   │   ├── variables.tf
│   │   ├── terraform.tfvars  # Environment-specific values
│   │   └── outputs.tf
│   ├── staging/
│   │   └── ...
│   └── prod/
│       └── ...
├── backend.tf                # Remote state configuration
└── versions.tf               # Provider version constraints
```

---

## CI/CD Runner and Deploy Strategy

### GitHub Actions Runners
- **CI**: GitHub-hosted `ubuntu-latest` runners (free tier sufficient for MVP)
- **Deploy**: Same runners with OIDC federation to AWS (no long-lived credentials)
- **Secrets**: GitHub Actions secrets for `AWS_ROLE_ARN`, `VERCEL_TOKEN`, `ANTHROPIC_API_KEY`

### Deployment Flow
```
PR opened → CI runs → Preview deploy (Vercel)
PR merged → CI runs → Auto-deploy staging (Vercel + ECS)
Manual trigger → Deploy prod (Vercel + ECS) with approval gate
```

### OIDC Federation (no static AWS keys)
```yaml
# In GitHub Actions
- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/github-actions
    aws-region: us-east-1
```
