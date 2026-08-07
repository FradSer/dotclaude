# Superdev Plugin

BDD-first engineering skills forked from [mattpocock/skills](https://github.com/mattpocock/skills) v1.2.3.

**Version:** 0.1.3

## What this is

A Claude Code plugin that adapts Matt Pocock's engineering skill set (grilling → spec → tickets → implement → review) to a BDD-first workflow:

- The `tdd` skill is replaced by `bdd`, merging mattpocock's seams / vertical-slice / tracer-bullet vocabulary with the Gherkin / Iron Law / discovery→formulation→automation discipline.
- `to-spec` produces Gherkin scenarios as executable specifications; `code-review`'s Spec axis verifies against them.

## Installation

```bash
claude plugin install superdev@frad-dotclaude
```

## Post-install (required)

Plugin skills are namespaced and do **not** shadow — same-name skills coexist across plugins. To make `/superdev:bdd`, `/superdev:implement`, etc. unambiguous, disable the installed `mattpocock-skills` plugin:

- Run `/plugin` in Claude Code, select `mattpocock-skills`, disable it; **or**
- Edit `~/.claude/settings.json` (or the project `.claude/settings.json`) and set the `mattpocock-skills` plugin entry to disabled.

After disabling, `/superdev:bdd` is the only bdd/tdd-flavored skill invoked; mattpocock's `tdd` and superdev's `bdd` no longer both respond to "tdd" phrasing.

## Registered skills (26)

**Engineering (18):** ask-matt, diagnosing-bugs, grill-with-docs, triage, improve-codebase-architecture, setup-matt-pocock-skills, bdd, to-spec, to-tickets, wayfinder, implement, prototype, research, domain-modeling, codebase-design, code-review, resolving-merge-conflicts, wizard

**Productivity (8):** grill-me, grilling, handoff, teach, to-questionnaire, wait-what, writing-for-agents, writing-great-skills

The upstream `tdd` skill ships on disk as a mirror (unregistered — `bdd` is its BDD-flavored replacement). The remaining mattpocock skills (misc / in-progress / personal / deprecated) ship on disk but are unregistered, mirroring upstream's own promotion convention.

## Attribution

Forked from [mattpocock/skills](https://github.com/mattpocock/skills) v1.2.3 (MIT). The original `tdd` skill was transformed into `bdd`. See `LICENSE`.
