# Audit authority ladder (local supplement, not synced)

> **Not synced from upstream.** Local supplement kept outside `SKILL.md` /
> `reference/audit.md` so `sync-impeccable.sh` (verbatim wipe) does not touch
> it. The upstream `audit` flow is the source of truth for *how to audit*;
> this file documents how audit's findings reconcile with the OTHER three
> quality authorities in the `frontend` plugin.

> **Reachability (known gap).** This file is injected by two channels only:
> the `design-md-first` UserPromptSubmit hook (when `DESIGN.md` is present)
> and the `frontend-expert` coordinator's Report step. The upstream-synced
> `reference/audit.md` cannot reference it (verbatim policy). Consequence: a
> standalone `frontend:impeccable` (argument: `audit`) run with no `DESIGN.md`
> and no coordinator will not see this ladder — the ladder only matters when
> another quality authority is also running, so apply it when you have
> cross-authority findings to reconcile, otherwise audit's own heuristic
> output stands.

## The four quality authorities measure different axes

When the frontend plugin runs multiple quality checks on the same UI, four
authorities can each emit findings on contrast / typography / spacing / a11y:

| Authority | Skill / Agent | Evidence type | What it actually measures |
|-----------|---------------|---------------|---------------------------|
| design-md lint | `frontend:design-md` (`lint --format json`) | **computed** | Token resolution, WCAG contrast ratios (deterministic) |
| impeccable audit | `frontend:impeccable` (argument: `audit`) | **heuristic** | Spacing "cramped", hierarchy, composition (LLM judgment) |
| web-design-guidelines | `frontend:web-design-guidelines` | **standard-citation** | Fetched standards compliance checklist |
| anti-patterns agent | `frontend-anti-patterns` agent | **pattern-match** | AI-slop tells (gradient text, icon-tile stacks, etc.) |

## Reconciliation by evidence type (not by static priority)

A static priority (`design-md > impeccable > ...`) is the **wrong abstraction**
because these authorities measure different axes. Reconcile by evidence type:

- **computed supersedes heuristic on the same node.** design-md's contrast
  ratio of 3.1:1 beats impeccable audit's "contrast looks okay" for the same
  color pair. design-md is deterministic fact; audit is LLM estimate.
- **pattern-match is additive, not substitutive.** The anti-patterns agent's
  slop findings (e.g. "gradient text detected") ADD to the audit's findings;
  they don't replace them. A slop hit on a UI that impeccable audit "passed"
  is redundancy catching an LLM omission, not two authorities in conflict —
  re-run the relevant impeccable sub-command (e.g. `quieter` / `typeset`) on
  the flagged area.
- **standard-citation is advisory.** web-design-guidelines findings SUGGEST;
  they don't block. Surface them as recommendations, not as P1 blockers.
- **Same evidence type, same node, conflicting value** → the more specific /
  more recent authority wins. In practice this is rare; default to design-md
  (computed) for token-level conflicts.

## Where audit emits

impeccable `audit` is the single reconciliation **outlet** for heuristic
findings: it should incorporate (not duplicate) computed findings from
design-md lint and additive pattern-match findings from the anti-patterns
agent, then emit one consolidated finding set. The coordinator's Report step
(no longer the reconciliation point under Option B) consumes that set.

## Absolute Bans (upstream authoritative)

The text bans live in upstream `SKILL.md`'s `### Absolute bans` (8 rules,
synced verbatim). The executable detector rules live in
`scripts/detector/registry/antipatterns.mjs` (~40 ids). Note:
`hero-metric` and `glassmorphism-as-default` are text-only bans with **no**
corresponding registry rule; the other bans map to advisory registry rules.
