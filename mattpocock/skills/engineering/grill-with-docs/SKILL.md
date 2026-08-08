---
name: grill-with-docs
description: Runs a relentless interview that sharpens a plan or design and creates docs (ADRs and glossary) along the way. Use when the user wants to stress-test a plan or design, or produce decision records.
disable-model-invocation: true
---

Run a `/mattpocock:grilling` session, using the `/mattpocock:domain-modeling` skill.

## CRITICAL: Grill with the docs skills loaded

Run the `/mattpocock:grilling` session with the `/mattpocock:domain-modeling` skill active. Every sharpened term and locked decision lands in `CONTEXT.md` or an ADR as it crystallises — the paper trail is what distinguishes this skill from `/mattpocock:grill-me`. Interview questions go through the AskUserQuestion tool, one per call, as `/mattpocock:grilling` dictates.
