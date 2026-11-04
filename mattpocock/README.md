# Mattpocock Plugin

BDD-first engineering skills forked from [mattpocock/skills](https://github.com/mattpocock/skills) (synced 2026-11-04, upstream v1.3.2 + 3 commits / HEAD 4ae2317).

**Version:** 0.2.0

## What this is

A Claude Code plugin that adapts Matt Pocock's engineering skill set (grilling → spec → tickets → implement → review) to a BDD-first workflow:

- The `tdd` skill is replaced by `bdd`, merging mattpocock's seams / vertical-slice / tracer-bullet vocabulary with the Gherkin / Iron Law / discovery→formulation→automation discipline.
- `to-spec` produces Gherkin scenarios as executable specifications; `code-review`'s Spec axis verifies against them.

## Installation

```bash
claude plugin install mattpocock@frad-dotclaude
```

## Post-install (required)

Plugin skills are namespaced and do **not** shadow — same-name skills coexist across plugins. To make `/mattpocock:bdd`, `/mattpocock:implement`, etc. unambiguous, disable the installed `mattpocock-skills` plugin:

- Run `/plugin` in Claude Code, select `mattpocock-skills`, disable it; **or**
- Edit `~/.claude/settings.json` (or the project `.claude/settings.json`) and set the `mattpocock-skills` plugin entry to disabled.

After disabling, `/mattpocock:bdd` is the only bdd/tdd-flavored skill invoked; mattpocock's `tdd` and mattpocock's `bdd` no longer both respond to "tdd" phrasing.

## Registered skills (31)

**Engineering (23):** ask-matt, diagnosing-bugs, grill-with-docs, triage, improve-codebase-architecture, setup-matt-pocock-skills, bdd, tdd, to-spec, to-tickets, wayfinder, implement, implement-spec, prototype, research, domain-modeling, codebase-design, code-review, deslop, pr, retro, resolving-merge-conflicts, wizard

**Productivity (8):** grill-me, grilling, handoff, teach, to-questionnaire, wait-what, writing-for-agents, writing-great-skills

The `tdd` skill is now a BDD-driven Automation reference, registered alongside `bdd` as part of the unified BDD pipeline. `implement-spec`, `pr` and `retro` graduated from `in-progress` to `engineering` at upstream v1.3.0. `resolving-merge-conflicts` was removed upstream but is kept here as a registered fork customization. `deslop` is adapted from `pi-matt-pocock` (no upstream counterpart). The remaining mattpocock skills (misc / in-progress / personal / deprecated) ship on disk but are unregistered, mirroring upstream's own promotion convention.

## Verification

The fork records its upstream baseline in `upstream-selection.json` and enforces it with a stdlib-only checker:

Run all commands from the **repository root** (the directory that contains `plugin-optimizer/` and `mattpocock/`), not from inside the plugin directory:

```bash
python3 mattpocock/scripts/check-upstream-sync.py                                 # offline: metadata, links, host-syntax guards
python3 mattpocock/scripts/check-upstream-sync.py --upstream /path/to/skills-clone  # full inventory and revision comparison
claude plugin validate ./mattpocock --strict                                     # official manifest/component schema (2.1.275+)
python3 plugin-optimizer/scripts/validate-plugin.py mattpocock                   # token budget and repo style
# optional behavioral regression; this runs the model and costs money — see SYNC.md section 9 for the full command
claude plugin eval ./mattpocock --trust-plugin --no-publish
```

The checker never clones or fetches. In **offline** mode exit 0 means: every upstream `SKILL.md` is classified; every `/mattpocock:` reference resolves to a registered skill and no bare `/skill` reference names a registered skill; every relative link resolves; the 16 distinctive upstream content fixes are present in the fork; the legacy `CONTEXT.md` migration line survives; and no host-specific syntax leaked into the skill bodies. With `--upstream` it additionally checks that all four revision fields resolve against the checkout, that the full upstream skill inventory is accounted for, and that no selected skill body was gutted. Each guard has a should-fail case documented in `SYNC.md` (verification philosophy).

`claude plugin validate --strict` and the repo's `validate-plugin.py` are complementary: the official command checks the current manifest and component schema, the local script adds token-budget and style checks. Both must exit 0. The eval suite uses the current `schema_version: "1.1"` case format.

## Native-feature policy

This plugin is deliberately content-only. Claude Code 2.1.317 already provides skill auto-discovery, `/mattpocock:<name>` slash commands, `disable-model-invocation`, the `AskUserQuestion` tool, subagents and hooks. The pi package's catalog gateway, persisted workflow state, progressive tools and dialog subsystem are workarounds for Pi's runtime and are **not** ported. Only their pure-content ideas are adopted: the AI slop baseline, the de-slop capability, model-aware instruction auditing and upstream-selection metadata.

The pi completion/verification guidance was evaluated and deliberately **not** ported: it fixes a pi-runtime regression, no fork failure was observed, and the global CLAUDE.md already covers the same rule.

Recent native features were evaluated before use. `paths` gates automatic activation against the current working directory and would hide general workflow skills; `context: fork` starts a subagent with no conversation history and would break context-dependent skills; adding `when_to_use` text consumes the 1,536-character listing cap; a `Stop`/`PreToolUse` hook that blocks turns can stall the headless eval suite. None of them fixes an observed failure here, so they are not used. `experimental.evals` is unnecessary because `evals/` is already the CLI default. See `SYNC.md` for the full decision record.

## Attribution

Forked from [mattpocock/skills](https://github.com/mattpocock/skills) (baseline v1.3.2 + 3 commits, synced 2026-11-04, MIT). The original `tdd` skill was transformed into `bdd`. See `LICENSE`.
