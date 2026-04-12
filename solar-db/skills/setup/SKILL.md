---
name: setup
description: Initialize and configure a solar company PostgreSQL database. This skill should be used when the user wants to "set up solar database", "initialize solar schema", "create solar tables", "seed solar data", or configure database connection settings.
argument-hint: "[init|seed]"
user-invocable: true
allowed-tools: Bash(python3 */solar_db.py *), Read, Write, Edit, AskUserQuestion
---

# Solar Database Setup

Configure the PostgreSQL connection and initialize the solar company database schema.

## Prerequisites

Ensure `psycopg2-binary` is installed:

```bash
pip install psycopg2-binary
```

## Step 1: Configure Connection

Check if `DATABASE_URL` is set in the environment. If not, ask the user for their PostgreSQL connection string in this format:

```
postgresql://user:password@host:5432/dbname
```

Suggest the user add it to their shell profile or `.env` file for persistence.

## Step 2: Initialize Schema

Run the schema initialization script:

```bash
DATABASE_URL="$DATABASE_URL" python3 ${CLAUDE_PLUGIN_ROOT}/scripts/solar_db.py init
```

This creates five tables (idempotent — safe to re-run):
- **customers** — client records
- **panels** — solar panel product catalog
- **installations** — customer installation projects
- **invoices** — billing records
- **energy_production** — daily energy output tracking

## Step 3: Seed Sample Data (Optional)

If the user wants test data or passes `seed` as an argument:

```bash
DATABASE_URL="$DATABASE_URL" python3 ${CLAUDE_PLUGIN_ROOT}/scripts/solar_db.py seed
```

This inserts 5 sample customers, panels, installations, invoices, and energy production records.

## Troubleshooting

- **Connection refused**: Verify PostgreSQL is running and the host/port are correct
- **Authentication failed**: Check username and password in the connection string
- **Database does not exist**: Create it first with `createdb dbname`
