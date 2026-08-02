---
name: grill-with-docs
description: Runs a relentless interview that sharpens a plan or design and creates docs (ADRs and glossary) along the way. Use when the user wants to stress-test a plan or design, or produce decision records.
disable-model-invocation: true
---

Run a `/superdev:grilling` session, using the `/superdev:domain-modeling` skill.

## CRITICAL: Grill with the docs skills loaded

Run the `/superdev:grilling` session with the `/superdev:domain-modeling` skill active. Every sharpened term and locked decision lands in `CONTEXT.md` or an ADR as it crystallises — the paper trail is what distinguishes this skill from `/superdev:grill-me`. Interview questions go through the AskUserQuestion tool, one per call, as `/superdev:grilling` dictates.
