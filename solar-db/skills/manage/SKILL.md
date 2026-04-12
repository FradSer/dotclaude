---
name: manage
description: Perform CRUD operations on solar company database records. This skill should be used when the user wants to "add a customer", "create an installation", "update invoice", "delete a panel", "list customers", "show installations", or perform any create/read/update/delete operation on solar company data.
argument-hint: "OPERATION TABLE [options]"
user-invocable: true
allowed-tools: Bash(python3 */solar_db.py *), Read, AskUserQuestion
---

# Solar Database CRUD Operations

Perform create, read, update, and delete operations on the solar company database.

## Available Tables

- **customers** — name, email, phone, address
- **panels** — manufacturer, model, wattage, efficiency, price_per_unit
- **installations** — customer_id, panel_id, panel_count, site_address, total_capacity_kw, status, installed_date
- **invoices** — installation_id, amount, status, issued_date, due_date, paid_date
- **energy_production** — installation_id, date, kwh_produced

## Operations

### Create a Record

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/solar_db.py create TABLE --field key=value --field key=value
```

Example — add a customer:
```bash
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/solar_db.py create customers --field name="Jane Doe" --field email="jane@example.com" --field phone="555-0200"
```

### Read Records

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/solar_db.py read TABLE [--id N] [--filter field:value] [--limit N]
```

Examples:
```bash
# List all customers
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/solar_db.py read customers

# Get a specific installation
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/solar_db.py read installations --id 1

# Filter invoices by status
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/solar_db.py read invoices --filter status:paid
```

### Update a Record

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/solar_db.py update TABLE --id N --field key=value
```

Example — mark installation as completed:
```bash
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/solar_db.py update installations --id 3 --field status=completed --field installed_date=2026-04-12
```

### Delete a Record

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/solar_db.py delete TABLE --id N
```

Always confirm deletion with the user before executing.

## Interpreting User Intent

Parse natural language requests into the appropriate command:
- "Add a new customer named X" -> `create customers --field name=X`
- "Show all pending invoices" -> `read invoices --filter status:pending`
- "Update panel 2 price to 300" -> `update panels --id 2 --field price_per_unit=300`
- "Remove customer 4" -> `delete customers --id 4` (confirm first)

All output is JSON. Present results in a readable format to the user.
