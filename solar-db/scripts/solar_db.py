#!/usr/bin/env python3
"""Solar company database CRUD operations for PostgreSQL."""

import argparse
import json
import os
import sys
from datetime import date, datetime
from decimal import Decimal

try:
    import psycopg2
    import psycopg2.extras
except ImportError:
    print("Error: psycopg2 is required. Install with: pip install psycopg2-binary", file=sys.stderr)
    sys.exit(1)


TABLES = ["customers", "panels", "installations", "invoices", "energy_production"]

SCHEMA_SQL = """
CREATE TABLE IF NOT EXISTS customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(50),
    address TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS panels (
    id SERIAL PRIMARY KEY,
    manufacturer VARCHAR(255) NOT NULL,
    model VARCHAR(255) NOT NULL,
    wattage INTEGER NOT NULL,
    efficiency DECIMAL(5,2),
    price_per_unit DECIMAL(10,2) NOT NULL
);

CREATE TABLE IF NOT EXISTS installations (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(id) ON DELETE CASCADE,
    panel_id INTEGER REFERENCES panels(id) ON DELETE SET NULL,
    panel_count INTEGER NOT NULL,
    site_address TEXT NOT NULL,
    total_capacity_kw DECIMAL(10,2),
    status VARCHAR(50) DEFAULT 'planned',
    installed_date DATE,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS invoices (
    id SERIAL PRIMARY KEY,
    installation_id INTEGER REFERENCES installations(id) ON DELETE CASCADE,
    amount DECIMAL(12,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    issued_date DATE DEFAULT CURRENT_DATE,
    due_date DATE,
    paid_date DATE
);

CREATE TABLE IF NOT EXISTS energy_production (
    id SERIAL PRIMARY KEY,
    installation_id INTEGER REFERENCES installations(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    kwh_produced DECIMAL(10,2) NOT NULL,
    UNIQUE(installation_id, date)
);
"""

SEED_SQL = """
INSERT INTO customers (name, email, phone, address) VALUES
    ('Alice Johnson', 'alice@example.com', '555-0101', '123 Sunny Lane, Phoenix, AZ'),
    ('Bob Smith', 'bob@example.com', '555-0102', '456 Solar Ave, Tucson, AZ'),
    ('Carol Davis', 'carol@example.com', '555-0103', '789 Bright St, Denver, CO'),
    ('Dan Wilson', 'dan@example.com', '555-0104', '321 Panel Dr, Austin, TX'),
    ('Eve Martinez', 'eve@example.com', '555-0105', '654 Sunbeam Rd, San Diego, CA')
ON CONFLICT (email) DO NOTHING;

INSERT INTO panels (manufacturer, model, wattage, efficiency, price_per_unit) VALUES
    ('SunPower', 'Maxeon 6', 440, 22.80, 350.00),
    ('LG', 'NeON R', 400, 22.00, 310.00),
    ('Canadian Solar', 'HiDM5', 390, 21.30, 270.00),
    ('Jinko Solar', 'Tiger Neo', 410, 21.80, 280.00),
    ('REC', 'Alpha Pure-R', 430, 22.30, 340.00)
ON CONFLICT DO NOTHING;

INSERT INTO installations (customer_id, panel_id, panel_count, site_address, total_capacity_kw, status, installed_date) VALUES
    (1, 1, 20, '123 Sunny Lane, Phoenix, AZ', 8.80, 'completed', '2025-03-15'),
    (2, 3, 15, '456 Solar Ave, Tucson, AZ', 5.85, 'completed', '2025-06-20'),
    (3, 2, 25, '789 Bright St, Denver, CO', 10.00, 'in_progress', NULL),
    (4, 4, 18, '321 Panel Dr, Austin, TX', 7.38, 'planned', NULL),
    (5, 5, 30, '654 Sunbeam Rd, San Diego, CA', 12.90, 'completed', '2025-01-10')
ON CONFLICT DO NOTHING;

INSERT INTO invoices (installation_id, amount, status, issued_date, due_date, paid_date) VALUES
    (1, 7000.00, 'paid', '2025-03-20', '2025-04-20', '2025-04-10'),
    (2, 4050.00, 'paid', '2025-06-25', '2025-07-25', '2025-07-20'),
    (3, 7750.00, 'pending', '2026-01-15', '2026-02-15', NULL),
    (4, 5040.00, 'pending', '2026-03-01', '2026-04-01', NULL),
    (5, 10200.00, 'paid', '2025-01-15', '2025-02-15', '2025-02-01')
ON CONFLICT DO NOTHING;

INSERT INTO energy_production (installation_id, date, kwh_produced) VALUES
    (1, '2025-04-01', 35.20),
    (1, '2025-04-02', 38.10),
    (1, '2025-04-03', 32.50),
    (2, '2025-07-01', 24.80),
    (2, '2025-07-02', 26.30),
    (5, '2025-02-01', 48.60),
    (5, '2025-02-02', 51.20),
    (5, '2025-02-03', 45.90)
ON CONFLICT (installation_id, date) DO NOTHING;
"""


class JSONEncoder(json.JSONEncoder):
    """Handle date/datetime/Decimal serialization."""
    def default(self, obj):
        if isinstance(obj, (date, datetime)):
            return obj.isoformat()
        if isinstance(obj, Decimal):
            return float(obj)
        return super().default(obj)


def get_connection():
    """Get a PostgreSQL connection from DATABASE_URL."""
    url = os.environ.get("DATABASE_URL")
    if not url:
        print("Error: DATABASE_URL environment variable is not set.", file=sys.stderr)
        print("Set it with: export DATABASE_URL='postgresql://user:pass@host:5432/dbname'", file=sys.stderr)
        sys.exit(1)
    return psycopg2.connect(url)


def cmd_init(args):
    """Initialize the database schema."""
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(SCHEMA_SQL)
        conn.commit()
        print(json.dumps({"status": "ok", "message": "Schema initialized successfully. Tables: " + ", ".join(TABLES)}))
    finally:
        conn.close()


def cmd_seed(args):
    """Insert sample data into all tables."""
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(SEED_SQL)
        conn.commit()
        print(json.dumps({"status": "ok", "message": "Sample data inserted into all tables."}))
    finally:
        conn.close()


def cmd_create(args):
    """Insert a new record into a table."""
    if not args.fields:
        print(json.dumps({"status": "error", "message": "No fields provided. Use --field key=value"}), file=sys.stderr)
        sys.exit(1)

    fields = {}
    for f in args.fields:
        key, _, value = f.partition("=")
        if not key or not _:
            print(json.dumps({"status": "error", "message": f"Invalid field format: {f}. Use key=value"}), file=sys.stderr)
            sys.exit(1)
        fields[key] = value

    columns = list(fields.keys())
    placeholders = ["%s"] * len(columns)
    values = list(fields.values())

    # Validate table name against whitelist
    if args.table not in TABLES:
        print(json.dumps({"status": "error", "message": f"Unknown table: {args.table}. Valid: {', '.join(TABLES)}"}), file=sys.stderr)
        sys.exit(1)

    # Use psycopg2.sql for safe identifier quoting
    from psycopg2 import sql
    query = sql.SQL("INSERT INTO {} ({}) VALUES ({}) RETURNING *").format(
        sql.Identifier(args.table),
        sql.SQL(", ").join(map(sql.Identifier, columns)),
        sql.SQL(", ").join(sql.Placeholder() * len(columns))
    )

    conn = get_connection()
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(query, values)
            row = cur.fetchone()
        conn.commit()
        print(json.dumps({"status": "ok", "record": dict(row)}, cls=JSONEncoder))
    finally:
        conn.close()


def cmd_read(args):
    """Query records from a table."""
    if args.table not in TABLES:
        print(json.dumps({"status": "error", "message": f"Unknown table: {args.table}. Valid: {', '.join(TABLES)}"}), file=sys.stderr)
        sys.exit(1)

    from psycopg2 import sql

    conditions = []
    values = []

    if args.id:
        conditions.append(sql.SQL("{} = %s").format(sql.Identifier("id")))
        values.append(args.id)

    if args.filter:
        for f in args.filter:
            key, _, value = f.partition(":")
            if not key or not _:
                print(json.dumps({"status": "error", "message": f"Invalid filter: {f}. Use field:value"}), file=sys.stderr)
                sys.exit(1)
            conditions.append(sql.SQL("{} = %s").format(sql.Identifier(key)))
            values.append(value)

    query = sql.SQL("SELECT * FROM {}").format(sql.Identifier(args.table))
    if conditions:
        query = query + sql.SQL(" WHERE ") + sql.SQL(" AND ").join(conditions)
    query = query + sql.SQL(" ORDER BY id")

    if args.limit:
        query = query + sql.SQL(" LIMIT %s")
        values.append(args.limit)

    conn = get_connection()
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(query, values)
            rows = [dict(r) for r in cur.fetchall()]
        print(json.dumps({"status": "ok", "count": len(rows), "records": rows}, cls=JSONEncoder))
    finally:
        conn.close()


def cmd_update(args):
    """Update a record in a table."""
    if not args.id:
        print(json.dumps({"status": "error", "message": "--id is required for update"}), file=sys.stderr)
        sys.exit(1)
    if not args.fields:
        print(json.dumps({"status": "error", "message": "No fields provided. Use --field key=value"}), file=sys.stderr)
        sys.exit(1)
    if args.table not in TABLES:
        print(json.dumps({"status": "error", "message": f"Unknown table: {args.table}. Valid: {', '.join(TABLES)}"}), file=sys.stderr)
        sys.exit(1)

    from psycopg2 import sql

    fields = {}
    for f in args.fields:
        key, _, value = f.partition("=")
        if not key or not _:
            print(json.dumps({"status": "error", "message": f"Invalid field format: {f}. Use key=value"}), file=sys.stderr)
            sys.exit(1)
        fields[key] = value

    set_clauses = [sql.SQL("{} = %s").format(sql.Identifier(k)) for k in fields]
    values = list(fields.values()) + [args.id]

    query = sql.SQL("UPDATE {} SET {} WHERE id = %s RETURNING *").format(
        sql.Identifier(args.table),
        sql.SQL(", ").join(set_clauses)
    )

    conn = get_connection()
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(query, values)
            row = cur.fetchone()
        conn.commit()
        if row:
            print(json.dumps({"status": "ok", "record": dict(row)}, cls=JSONEncoder))
        else:
            print(json.dumps({"status": "error", "message": f"No record found with id={args.id}"}))
    finally:
        conn.close()


def cmd_delete(args):
    """Delete a record from a table."""
    if not args.id:
        print(json.dumps({"status": "error", "message": "--id is required for delete"}), file=sys.stderr)
        sys.exit(1)
    if args.table not in TABLES:
        print(json.dumps({"status": "error", "message": f"Unknown table: {args.table}. Valid: {', '.join(TABLES)}"}), file=sys.stderr)
        sys.exit(1)

    from psycopg2 import sql

    query = sql.SQL("DELETE FROM {} WHERE id = %s RETURNING id").format(
        sql.Identifier(args.table)
    )

    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(query, [args.id])
            deleted = cur.fetchone()
        conn.commit()
        if deleted:
            print(json.dumps({"status": "ok", "message": f"Deleted {args.table} record id={args.id}"}))
        else:
            print(json.dumps({"status": "error", "message": f"No record found with id={args.id}"}))
    finally:
        conn.close()


def cmd_report(args):
    """Run predefined reports."""
    reports = {
        "revenue": report_revenue,
        "installations": report_installations,
        "energy": report_energy,
        "customers": report_customers,
    }

    if args.name not in reports:
        print(json.dumps({"status": "error", "message": f"Unknown report: {args.name}. Valid: {', '.join(reports.keys())}"}), file=sys.stderr)
        sys.exit(1)

    reports[args.name]()


def report_revenue():
    """Revenue summary grouped by invoice status."""
    query = """
        SELECT
            status,
            COUNT(*) AS invoice_count,
            SUM(amount) AS total_amount,
            AVG(amount) AS avg_amount
        FROM invoices
        GROUP BY status
        ORDER BY total_amount DESC;
    """
    conn = get_connection()
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(query)
            rows = [dict(r) for r in cur.fetchall()]

            cur.execute("SELECT SUM(amount) AS grand_total FROM invoices;")
            grand_total = cur.fetchone()["grand_total"]

            cur.execute("SELECT SUM(amount) AS paid_total FROM invoices WHERE status = 'paid';")
            paid_total = cur.fetchone()["paid_total"] or Decimal("0")

        print(json.dumps({
            "status": "ok",
            "report": "revenue",
            "by_status": rows,
            "grand_total": grand_total,
            "paid_total": paid_total,
            "outstanding": grand_total - paid_total if grand_total else 0,
        }, cls=JSONEncoder))
    finally:
        conn.close()


def report_installations():
    """Installation statistics by status."""
    query = """
        SELECT
            i.status,
            COUNT(*) AS count,
            SUM(i.total_capacity_kw) AS total_capacity_kw,
            AVG(i.panel_count) AS avg_panels
        FROM installations i
        GROUP BY i.status
        ORDER BY count DESC;
    """
    conn = get_connection()
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(query)
            rows = [dict(r) for r in cur.fetchall()]

            cur.execute("SELECT COUNT(*) AS total FROM installations;")
            total = cur.fetchone()["total"]

        print(json.dumps({
            "status": "ok",
            "report": "installations",
            "by_status": rows,
            "total_installations": total,
        }, cls=JSONEncoder))
    finally:
        conn.close()


def report_energy():
    """Energy production summary per installation."""
    query = """
        SELECT
            ep.installation_id,
            c.name AS customer_name,
            i.site_address,
            COUNT(ep.date) AS days_tracked,
            SUM(ep.kwh_produced) AS total_kwh,
            AVG(ep.kwh_produced) AS avg_daily_kwh
        FROM energy_production ep
        JOIN installations i ON ep.installation_id = i.id
        JOIN customers c ON i.customer_id = c.id
        GROUP BY ep.installation_id, c.name, i.site_address
        ORDER BY total_kwh DESC;
    """
    conn = get_connection()
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(query)
            rows = [dict(r) for r in cur.fetchall()]

            cur.execute("SELECT SUM(kwh_produced) AS total FROM energy_production;")
            total_kwh = cur.fetchone()["total"]

        print(json.dumps({
            "status": "ok",
            "report": "energy",
            "by_installation": rows,
            "total_kwh": total_kwh,
        }, cls=JSONEncoder))
    finally:
        conn.close()


def report_customers():
    """Customer overview with installation and invoice counts."""
    query = """
        SELECT
            c.id,
            c.name,
            c.email,
            COUNT(DISTINCT i.id) AS installation_count,
            COUNT(DISTINCT inv.id) AS invoice_count,
            COALESCE(SUM(inv.amount), 0) AS total_billed
        FROM customers c
        LEFT JOIN installations i ON c.id = i.customer_id
        LEFT JOIN invoices inv ON i.id = inv.installation_id
        GROUP BY c.id, c.name, c.email
        ORDER BY total_billed DESC;
    """
    conn = get_connection()
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(query)
            rows = [dict(r) for r in cur.fetchall()]

        print(json.dumps({
            "status": "ok",
            "report": "customers",
            "customers": rows,
        }, cls=JSONEncoder))
    finally:
        conn.close()


def main():
    parser = argparse.ArgumentParser(description="Solar company database CRUD tool")
    sub = parser.add_subparsers(dest="command", required=True)

    # init
    sub.add_parser("init", help="Initialize database schema")

    # seed
    sub.add_parser("seed", help="Insert sample data")

    # create
    p_create = sub.add_parser("create", help="Create a record")
    p_create.add_argument("table", choices=TABLES, help="Target table")
    p_create.add_argument("--field", dest="fields", action="append", metavar="KEY=VALUE",
                          help="Field value (repeatable)")

    # read
    p_read = sub.add_parser("read", help="Read records")
    p_read.add_argument("table", choices=TABLES, help="Target table")
    p_read.add_argument("--id", type=int, help="Filter by ID")
    p_read.add_argument("--filter", action="append", metavar="FIELD:VALUE",
                        help="Filter by field (repeatable)")
    p_read.add_argument("--limit", type=int, help="Limit results")

    # update
    p_update = sub.add_parser("update", help="Update a record")
    p_update.add_argument("table", choices=TABLES, help="Target table")
    p_update.add_argument("--id", type=int, required=True, help="Record ID")
    p_update.add_argument("--field", dest="fields", action="append", metavar="KEY=VALUE",
                          help="Field to update (repeatable)")

    # delete
    p_delete = sub.add_parser("delete", help="Delete a record")
    p_delete.add_argument("table", choices=TABLES, help="Target table")
    p_delete.add_argument("--id", type=int, required=True, help="Record ID")

    # report
    p_report = sub.add_parser("report", help="Run a report")
    p_report.add_argument("name", choices=["revenue", "installations", "energy", "customers"],
                          help="Report name")

    args = parser.parse_args()

    commands = {
        "init": cmd_init,
        "seed": cmd_seed,
        "create": cmd_create,
        "read": cmd_read,
        "update": cmd_update,
        "delete": cmd_delete,
        "report": cmd_report,
    }

    commands[args.command](args)


if __name__ == "__main__":
    main()
