---
enabled: true
database_url: postgresql://user:password@localhost:5432/solar_company
---

# Solar DB Local Configuration

## Setup

Set the `DATABASE_URL` environment variable before using the plugin:

```bash
export DATABASE_URL="postgresql://user:password@localhost:5432/solar_company"
```

## Quick Start

1. `/solar-db:setup init` — Create tables
2. `/solar-db:setup seed` — Load sample data
3. `/solar-db:manage read customers` — List all customers
4. `/solar-db:report revenue` — View revenue summary
