# Designing Loops — Design (v2, reference-file shape)

## Context

Anthropic published guidance on "designing loops": four loop types — **turn-based, goal-based, time-based, proactive** — distinguished by trigger, stop criteria, and Claude Code primitive, plus supporting sections on maintaining code quality and managing token usage in loops. The user asked for this knowledge to be organically integrated into the `superpowers` plugin.

**Shape history (three rounds):** Round 1 designed a new auto-loading internal skill (`designing-loops`, `user-invocable: false`) and PASSED the 10-item structural checklist (`evaluation-design-round-1.md`). A post-PASS user review caught a trigger-precision self-contradiction and a weakly-deferred `goal-wrapper.md` gap (both fixed in a revision). An adversarial proportionality review then returned **RECONSIDER THE SHAPE**: a separately-registered auto-loading skill is heavier than ~5 short paragraphs of genuinely novel content warrants, its trigger precision is unverifiable in this repo (no skill-content eval harness), and two decisive facts had gone unweighed — (a) this repo's own convention for materially identical content is a plain `skills/references/*.md` file with zero trigger surface and zero README billing (`goal-wrapper.md`, `workflow-orchestration.md`); (b) Claude Code natively ships `loop` and `schedule` as top-level skills whose descriptions already route standalone recurring-task requests. **The user confirmed the pivot on 2026-07-08: reference file, not skill.** This document is the pivoted design; round-1's skill-shaped requirements are superseded.

`superpowers` already implements most of the blog under different names (verification-before-completion, `/goal` via `goal-wrapper.md`, receiving-code-review + the evaluator, retrospective's checklist evolution, the model-declaration and Bail-Out Check disciplines, `workflow-orchestration.md`). What is genuinely missing: nothing names the **time-based** type (`/loop`, `/schedule`) or connects "which loop type" to "which primitive" as a consultable decision aid. This design adds exactly that, as one reference file plus pointer sentences from the skills that are already loaded when the question arises.

## Discovery Results

- Repo convention for shared cross-skill guidance: `superpowers/skills/references/` holds `git-commit.md`, `goal-wrapper.md`, `workflow-orchestration.md` — plain files, no frontmatter, no `plugin.json` registration, no README entries (grep-confirmed zero mentions), consumed via one-line pointers from the 5 command skills.
- Native Claude Code ships `loop` ("Run a prompt or slash command on a recurring interval", worked example "check the deploy every 5 minutes") and `schedule` (cron-scheduled cloud agents) as top-level skills — standalone recurring-task requests route there without any superpowers surface. Confirmed live in this session's own environment.
- `goal-wrapper.md` Rule 2 covers condition phrasing only; no turn-cap guidance exists anywhere in the plugin despite the blog calling it out ("stop after 5 tries"). Confirmed by full read.
- The plugin has zero documentation of `/loop`/`/schedule`; the only "loop" mentions concern the **deleted** v2.x `lib/loop.sh` continuation runtime (removed v3.0.0) — a live conflation risk.
- Token ceilings: `retrospective/SKILL.md` 4671/5000, `writing-plans/SKILL.md` 4778/5000 (validator baseline, exit 0) — edits to those two files must be single sentences.
- `hooks/session-start.sh:28` scrapes `using-superpowers`' routing table (`^\| .*superpowers:`) into every session — content added to that file must stay out of the table rows.
- Checklist `REQ-TRACE-01` greps `REQ-[0-9]+`; requirement IDs use plain `REQ-NNN` (an earlier `REQ-LOOP-NN` candidate from two parallel research sub-agents was reconciled away — the two agents' numbering also mutually collided).
- **Task estimate hint** (writing-plans bail-out gate): ~9 tasks (1 content file; goal-wrapper Rule 3; 7 pointer-sentence edits across 7 files; validation). 20 BDD scenarios clear the OR-gate independently.

## Glossary

| Term | Locked form | Notes |
|---|---|---|
| Loop-type names | Lowercase in prose: **turn-based loop, goal-based loop, time-based loop, proactive loop**; Title Case only in literal headings/`Feature:` titles. | Repo house style: classifications lowercase; only proper mechanism names (`Bail-Out Check`, `Iron Law`, `Workflow`) capitalized. |
| `primitive` | Lowercase; the set: `plain turn`, `/goal`, `/loop`, `/schedule`, `Workflow` (composed). Slash commands always backticked. | Matches `workflow-orchestration.md` phrasing. |
| `proactive loop` | Locked. **"autonomous loop" must not appear anywhere.** | Collides with Claude Code "auto mode" and `brainstorming`'s pre-existing generic "autonomous". |
| `loop type` | Two words as noun; hyphenated only as compound adjective. | |
| Artifact name: `loop-types.md` | **Accepted** — `superpowers/skills/references/loop-types.md`. | Plural noun file naming matches sibling `references/` files (descriptive, not gerund — gerund-action naming is the *skill* convention, which no longer applies). |
| Superseded name: `designing-loops` (skill) | **Superseded by the shape pivot.** The name survives only in this design folder's path and history sections. | |
| Requirement ID format | `REQ-NNN`, renumbered fresh for the pivoted shape (round-1 numbering is superseded together with the shape). | |
| "cite, don't duplicate" | **citation-not-duplication requirement** (REQ-007/REQ-008 collectively). | |

## Requirements

### Content (the reference file)

- **REQ-001** — The artifact is a single plain file `superpowers/skills/references/loop-types.md`: no frontmatter, no `plugin.json` registration, no README entry — exactly matching `goal-wrapper.md`/`workflow-orchestration.md`'s shape. *Rationale: the null-alternative shape; deletes the trigger-precision risk and the L2-body lifecycle rather than mitigating them.*
- **REQ-002** — The file opens with a compact 4-row classification table (loop type → trigger/stop signals → primitive → one-line example command) and states that classification picks exactly one type. *Rationale: the core deliverable; without a forced 1-of-4 step the file is a link dump.*
- **REQ-003** — The time-based section is original content: `/loop` and `/schedule` as native Claude Code commands not shipped by this plugin, explicitly disambiguated from the deleted v2.x `lib/loop.sh` runtime (removed v3.0.0, replaced by native `/goal`). *Rationale: grep-confirmed gap; live conflation risk.*
- **REQ-004** — The proactive section cites `./workflow-orchestration.md`'s opt-in rules and the brainstorming → writing-plans → executing-plans → retrospective chain as a partial worked example (each stage `/goal`-wrapped today; not yet composed under an outer `/schedule`), without reproducing Workflow mechanics. *Rationale: that file owns opt-in semantics.*
- **REQ-005** — The turn-based section cites `verification-before-completion` (self-judged stopping) and `receiving-code-review` + the `superpowers-evaluator` agent (second-agent review), without reproducing their content, and states that trivial single-turn work needs no classification at all (mirroring the plugin-wide Bail-Out philosophy). *Rationale: existing owner files; over-classification of trivial work is the failure mode the plugin guards against everywhere else.*
- **REQ-006** — The goal-based section cites `./goal-wrapper.md` in full, including its new Rule 3 (REQ-010) — zero original goal-based content in `loop-types.md`. *Rationale: `goal-wrapper.md` is the single authoritative `/goal` reference.*
- **REQ-007** — Quality-in-loops content is a citation map only: verification-before-completion, receiving-code-review, the evaluator agent, the BDD Iron Law, retrospective Phase 3 checklist evolution. *Rationale: citation-not-duplication; each concern has an owner file.*
- **REQ-008** — Token-management content cites the model-declaration CRITICAL discipline (`executing-plans`), the Bail-Out Check pattern, `workflow-orchestration.md`'s >4-task threshold, and the `lib/*.sh` script-over-reasoning pattern — plus carries the two genuinely new items: (a) match polling interval to actual change frequency; (b) periodically review via `/usage`, `/goal` (no-arg), `/workflows`. *Rationale: citations for what exists; original content only for the grep-confirmed gaps.*
- **REQ-009** — All citations in `loop-types.md` use stable anchors (file path + section/rule *name*, e.g. "workflow-orchestration.md Rule 2 — user must opt in") and keep verbatim quotes to a minimum; no bare line-number citations. *Rationale: adversarial-review finding — pointer-existence greps can't detect a citation whose target content silently changed; naming the section makes renumber/rename drift detectable by the human reader and cheap to grep.*

### Content (goal-wrapper.md)

- **REQ-010** — `goal-wrapper.md` gets `## Rule 3 — pair the condition with an explicit turn cap for open-ended work`, inserted between Rule 2 and "Recommended conditions per skill": turn caps for hypothesis-driven/unbounded work ("stop after N tries"), not needed for bounded pipelines; closes with a pointer to `./loop-types.md` for the broader classification. *Rationale: fixes the gap at its source; a deferred note was rejected in the post-PASS revision as non-structural.*

### Integration (pointer sentences)

- **REQ-011** — Each of the 5 command skills' `## Recommended: run wrapped in /goal` sections gains one sentence pointing to `../../skills/references/loop-types.md` ("to decide whether this run should be a plain turn, `/goal`, `/loop`, or `/schedule`..."). For `retrospective`, the sentence also names it a natural `/schedule` candidate (merged, single sentence — token ceiling). For `systematic-debugging`, an additional sentence at "When Process Reveals No Root Cause" (flaky/timing-dependent → `/loop` re-verification) plus a `**Related skills:**`-style reference line. *Rationale: the moment a reader weighs `/goal` is the moment the broader classification is relevant; anchors verified in `architecture.md`.*
- **REQ-012** — `using-superpowers/SKILL.md` gains one sentence (not a section, not a table row) after the routing table: the table answers "which skill"; `references/loop-types.md` answers the orthogonal "how should it run". *Rationale: scoped down from round-1's full section per the proportionality verdict; must stay out of the hook-scraped table rows.*
- **REQ-013** — `workflow-orchestration.md` gains a final `## See also` line pointing to `./loop-types.md` (Workflow is the proactive arm; the other three types live there). *Rationale: reciprocal pointer at the file whose Rule 3 threshold loop-types cites.*
- **REQ-014** — All 8 integration-point files (5 command skills, `using-superpowers`, `workflow-orchestration.md`, `goal-wrapper.md`) are verifiable by `grep -l "loop-types" <file>`; `goal-wrapper.md` additionally by `grep -q "Rule 3"`. *Rationale: binary post-implementation check. Count: 5+1+1+1 = 8 (README is no longer touched — the round-1 "All 8"-vs-9 miscount is moot under the pivoted shape, and the count here is derived from the enumeration, not asserted separately.)*

### Non-functional

- **REQ-015** — No file introduces "autonomous loop"; glossary casing rules hold across `loop-types.md` and all 8 edits. *Verification: `grep -ri "autonomous loop"` over the touched files returns zero.*
- **REQ-016** — Edits to `retrospective`/`writing-plans` SKILL.md are single sentences; `python3 plugin-optimizer/scripts/validate-plugin.py superpowers` re-run after each edit, must stay exit 0. *Rationale: 4671/4778 of 5000 baseline.*
- **REQ-017** — `loop-types.md` has no size gate (L3 is effectively unlimited) but targets the same order of magnitude as its siblings (`goal-wrapper.md` ~50 lines, `workflow-orchestration.md` ~50 lines): the 4-row table plus five short sections, roughly 60-90 lines. *Rationale: proportionality made checkable; the content is ~5 paragraphs of novelty plus citations.*

## Rationale

**Why a reference file, not a skill (the pivot):** the round-1 skill shape carried three costs the content never needed — an always-resident description whose trigger precision this repo cannot verify (no skill-content eval harness) and which round-1 already got wrong once ("automate this check" colliding with its own stay-out-of-the-way rule); a `plugin.json`/README registration lifecycle; and an L2/L3 split requiring CRITICAL-marker policing. The null alternative deletes all three: pointer sentences live in skills that are *already loaded* when the question arises (the `/goal` sections), standalone recurring-task requests are already routed by Claude Code's native `loop`/`schedule` skills, and the file shape matches the exact convention its two siblings already use. The L2/L3 lesson (`feedback_skill_level_enforcement`) does not block this: that lesson gates *mandatory rules*, which must live in a loaded SKILL.md body — `loop-types.md` is advisory decision support, and the one mandatory-adjacent behavior it touches (turn caps) lands in `goal-wrapper.md`, which the 5 command skills' existing `/goal` sections already point to.

**Why citation-not-duplication (unchanged from round 1):** every cited concern has an owner file that evolves independently; the 5 command skills already consume `goal-wrapper.md` by pointer. REQ-009 adds what round 1 missed: citations must be *drift-detectable* (stable section names, minimal verbatim quotes), because grep-for-pointer-existence cannot catch a target that changed underneath.

## Detailed Design

```
superpowers/skills/references/loop-types.md   (new, ~60-90 lines, no frontmatter)
superpowers/skills/references/goal-wrapper.md (edit: + Rule 3)
superpowers/skills/{brainstorming,writing-plans,executing-plans,retrospective,systematic-debugging}/SKILL.md  (one pointer sentence each; systematic-debugging +1 anchor)
superpowers/skills/using-superpowers/SKILL.md (one pointer sentence, outside the table)
superpowers/skills/references/workflow-orchestration.md (+ ## See also)
```

`loop-types.md` outline: (1) intro sentence — what this file answers and that trivial single-turn work needs none of it; (2) the 4-row table; (3) `## Turn-based` (citations); (4) `## Goal-based` (citation to goal-wrapper incl. Rule 3); (5) `## Time-based` (original: native `/loop`/`/schedule`, v2.x disambiguation, interval matching); (6) `## Proactive` (composition, opt-in citation, chain example); (7) `## Quality and token discipline in loops` (citation map + `/usage`//`/goal`//`/workflows` review note).

### Risks

- **Token ceilings** (`retrospective` 4671, `writing-plans` 4778 of 5000): single-sentence edits only; re-validate after each (REQ-016).
- **Citation staleness** (adversarial-review finding, now owned): mitigated by REQ-009's stable-anchor rule; residual honestly stated — no automated cross-file drift check exists, and building one is out of scope (noted as a possible future retrospective checklist item, not built here).
- **Discoverability without a trigger surface**: a standalone loop-shaped request with no superpowers skill active reaches native `loop`/`schedule` skills, not this file. Accepted deliberately — that case is already served by the platform; this file serves the in-workflow decision moment via the 7 pointer sentences.
- **"autonomous loop" collision**: REQ-015 grep gate.

## Design Documents

- [`bdd-specs.md`](./bdd-specs.md) — 20 scenarios across 5 Features, retagged to this document's REQ-NNN set, plus Traceability Notes for structural requirements.
- [`architecture.md`](./architecture.md) — exact anchors for all 8 integration points, `loop-types.md` skeleton, verification commands.
- [`best-practices.md`](./best-practices.md) — over-/under-recommendation pitfalls, the advisory-vs-mandatory L2/L3 boundary, citation-staleness discipline, forward pointer on behavioral testing.
- [`evaluation-design-round-1.md`](./evaluation-design-round-1.md) — historical: round-1 (skill-shaped) checklist PASS, superseded by this pivot; kept for the audit trail.

## Addendum: shape-pivot record

Round-1 PASS → user review (2 fixes) → adversarial proportionality review (RECONSIDER) → user decision 2026-07-08: pivot to reference file. Lesson captured in persistent memory (`null-alternative-before-new-surface`): before adding any new delivery surface, the sprint contract must weigh the null alternative (existing references file + platform-native coverage); a structural checklist PASS validates compliance, not proportionality.
