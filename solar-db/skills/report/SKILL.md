---
name: report
description: Run reports and analytics on solar company database. This skill should be used when the user wants "revenue report", "installation stats", "energy production summary", "customer overview", or asks for solar business analytics and metrics.
argument-hint: "REPORT_NAME"
user-invocable: true
allowed-tools: Bash(python3 */solar_db.py *), Read
---

# Solar Database Reports

Run predefined reports and analytics queries against the solar company database.

## Available Reports

### Revenue Report

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/solar_db.py report revenue
```

Returns:
- Invoice counts and totals grouped by status (paid, pending, overdue, cancelled)
- Grand total billed
- Total paid vs outstanding

### Installation Statistics

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/solar_db.py report installations
```

Returns:
- Installation counts by status (planned, in_progress, completed, maintenance)
- Total capacity in kW per status
- Average panel count per installation

### Energy Production Summary

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/solar_db.py report energy
```

Returns:
- Per-installation energy output (total kWh, average daily kWh)
- Customer name and site address for each installation
- Overall total kWh produced

### Customer Overview

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/solar_db.py report customers
```

Returns:
- Each customer with their installation count, invoice count, and total billed
- Sorted by total billed (descending)

## Presenting Results

Parse the JSON output and present it in a clear, formatted table or summary. Highlight key metrics and trends. If the user asks follow-up questions, use the manage command to drill into specific records.
