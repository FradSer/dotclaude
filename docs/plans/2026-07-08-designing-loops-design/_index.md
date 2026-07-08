# Designing Loops — Design

## Context

Anthropic published guidance on "designing loops": categorizing agent work into four loop types — **turn-based**, **goal-based**, **time-based**, **proactive** — distinguished by trigger, stop criteria, and Claude Code primitive, plus two supporting sections on maintaining code quality in loops and managing token usage in loops.

The user asked for a new skill in the `superpowers` plugin (`/Users/FradSer/Developer/FradSer/dotclaude/superpowers/`) that teaches this classification, with one explicit constraint: the skill must be **organically integrated** into the existing skill system, not added as an isolated file — using `superpowers/skills/behavior-driven-development/` as the integration template (how it is triggered, cross-referenced by other skills, layered across `SKILL.md` + `references/`, and registered in `plugin.json`).

`superpowers` already implements most of what the blog describes, under different names:

- Turn-based self-check: `verification-before-completion`
- Goal-based: the native `/goal` command, documented in `skills/references/goal-wrapper.md`, used by all 5 user-invocable skills
- Code-quality-in-loops: `receiving-code-review`, the `superpowers-evaluator` agent, the BDD Iron Law, `retrospective`'s checklist evolution
- Token management: `executing-plans`' per-dispatch model-declaration `CRITICAL` block, every skill's Bail-Out Check, `workflow-orchestration.md`'s opt-in threshold, `lib/task-ledger.sh` / `lib/docs-index.sh` as deterministic scripts over re-derived reasoning

What is genuinely missing: (1) nothing in this plugin names or teaches the **time-based** loop type (`/loop`, `/schedule` — native Claude Code commands, not part of this plugin) at all, and (2) nothing connects "which of the four types is this task" to "therefore use this primitive" as an explicit, reusable decision a skill can consult mid-flow. This design adds exactly that missing layer, wired into the existing system via citations rather than duplicated content.

## Discovery Results

- `plugin.json` (`superpowers/.claude-plugin/plugin.json`) splits skills into `"commands"` (5 user-invocable: brainstorming, writing-plans, executing-plans, retrospective, systematic-debugging) and `"skills"` (4 internal, `user-invocable: false`: behavior-driven-development, using-superpowers, verification-before-completion, receiving-code-review).
- Every internal skill uses an identical minimal 3-field frontmatter (`name`, `description`, `user-invocable: false`) — confirmed via `grep -A6 "^---$" superpowers/skills/*/SKILL.md`; `argument-hint`/`allowed-tools` appear only on the 5 command skills.
- `superpowers/hooks/session-start.sh:28` builds the SessionStart bootstrap by grepping `using-superpowers/SKILL.md` for lines matching `^\| .*superpowers:` — i.e. rows of the "which skill to invoke" routing table. This table answers a different question ("which of the 5 commands") than the one this design adds ("how should the chosen work run") — a new row would be both conceptually wrong and mechanically inert (internal skills carry no `superpowers:`-prefixed invocation form for the regex to match).
- `skills/references/goal-wrapper.md` is the sole shared reference for `/goal` semantics, consumed by all 5 command skills via a one-line pointer, not inlined. Confirmed gap: its Rule 2 table documents *condition* phrasing only — it has no guidance on explicit turn caps ("stop after 5 tries"), which the blog calls out as part of managing a goal-based loop.
- `skills/references/workflow-orchestration.md` documents the native `Workflow` tool's opt-in rules (Rule 2: user must opt in) and scale threshold (Rule 3: escalate only past >4 independent tasks) — the primitive that composes into a proactive loop. It currently has zero "See also" lines.
- Baseline validation: `python3 plugin-optimizer/scripts/validate-plugin.py superpowers` → **PASSED, exit 0**, with 2 pre-existing `should`-level token warnings: `retrospective/SKILL.md` at 4671/5000 tokens and `writing-plans/SKILL.md` at 4778/5000 tokens. Any edit to either file in this design must be a single short sentence, not a paragraph, or it risks tipping a `should` warning into a `must`-level failure (exit 2).
- `README.md`'s `## Internal Skills (Loaded Automatically)` section already documents only 2 of the plugin's 4 registered internal skills — `verification-before-completion` and `receiving-code-review` have no entry at all. Pre-existing drift, confirmed by direct read of the section.
- `systematic-debugging/SKILL.md:352-361` ("When Process Reveals No Root Cause") already names the "environmental, timing-dependent" symptom class this design's time-based cross-link fits; the file also already has a `**Related skills:**` bullet-list convention at lines 372-373, giving a second, lower-risk anchor.
- No `skill-creator` plugin exists inside this repo — it is available only as an externally-registered skill outside this marketplace. There is currently no in-repo behavioral eval mechanism for skill *content* quality (as distinct from `plugin-optimizer`'s structural/token-budget validation). Noted as a forward pointer only; not built by this design.
- The checklist that will evaluate this design (`docs/retros/checklists/design-v2.md`, extending `design-v1.md`) enforces `REQ-TRACE-01` via `grep -oE "REQ-[0-9]+"` — a literal `REQ-` immediately followed by digits. This ruled out an earlier `REQ-LOOP-NN` numbering candidate (two of the three Phase 2 research sub-agents independently invented that format, which does not match the pattern) in favor of the plain `REQ-NNN` form used below — a vocabulary reconciliation applied before this design was integrated, not after.

**Task estimate hint** (for `writing-plans`' bail-out gate): ~13 tasks (skill content: SKILL.md + 2 references files; 7 cross-link edits, several single-sentence; `plugin.json` + `README.md` registration; validation). BDD scenario count (20, see `bdd-specs.md`) already clears the OR-gate independently.

## Glossary

Canonical vocabulary for this design and its implementation. Reconciled across all three Phase 2 research sub-agents' output before this document was written (one real collision found and resolved: requirement-ID format, below).

| Term | Locked form | Notes |
|---|---|---|
| Loop-type names | Lowercase compound-adjective in running prose: **turn-based loop, goal-based loop, time-based loop, proactive loop**. Title Case reserved for literal `##`/`###` headings and Gherkin `Feature:` titles only. | Matches this repo's house style (classifications stay lowercase in prose; only proper mechanism names like `Bail-Out Check`, `Iron Law`, `Workflow` are capitalized) while preserving the blog's own header casing where headings actually are headings. |
| `primitive` | Lowercase always. The set: `plain turn` (no wrapper), `/goal`, `/loop`, `/schedule`, `Workflow` (composed). Slash-command primitives are always backticked literal tokens, never spelled out as prose words. | Matches existing lowercase `native \`Workflow\` tool` phrasing in `workflow-orchestration.md`. |
| `proactive loop` | Locked. **"autonomous loop" is rejected as a synonym — must not appear anywhere in this design or its implementation.** | Collides with two existing senses: Claude Code's unrelated "auto mode" feature, and `brainstorming`'s own skill description, which already uses "autonomous" generically ("via autonomous codebase research... runs to completion without pausing") for something narrower than a full 4-primitive proactive loop. |
| `loop type` | Two words, no hyphen, as a noun ("pick a loop type"). Hyphenated only as a compound adjective before a noun ("4-loop-type classification"). | Standard compound-modifier hyphenation; prevents drift across the skill body and 7 cross-link edits. |
| `internal skill` | Locked, matching `README.md`'s existing heading `## Internal Skills (Loaded Automatically)` verbatim. | |
| `user-invocable: false` | Locked as the exact frontmatter key/value token; never paraphrased as "hidden" or "private". | |
| `cross-link` (verb) vs. `integration point` (noun) | Distinct: "cross-link" = the act of adding a pointer; "integration point" = the file/section pointed at. | Keeps Requirements REQ-013–REQ-019 unambiguous about what's being added vs. where. |
| "cite, don't duplicate" | Locked as **citation-not-duplication requirement** when referring to REQ-009/REQ-010 collectively. | One shared name for two structurally identical requirements. |
| L2 / L3 | Locked per `dotclaude/CLAUDE.md`'s token-budget levels: **L2** = `SKILL.md` body (loaded when triggered, <5k tokens), **L3** = `references/*.md` (loaded on demand, effectively unlimited). | Reuses this repo's own vocabulary rather than inventing a parallel scheme. |
| Requirement ID format | **`REQ-NNN`** (e.g. `REQ-001`), plain zero-padded digits — **not** `REQ-LOOP-NN`. | **Reconciliation finding.** The requirements-synthesis and BDD-scenario research sub-agents (run in parallel, isolated contexts) both independently produced a `REQ-LOOP-NN` numbering scheme, and — worse — numbered their own lists starting from `REQ-LOOP-01` independently, so the two sub-agents' `REQ-LOOP-01` referred to *different* requirements (one: plugin.json registration; the other: a trivial-turn BDD scenario). Neither form matches `docs/retros/checklists/design-v1.md`'s `REQ-TRACE-01` check method, which greps for literal `REQ-[0-9]+`. Resolved by renumbering to plain `REQ-NNN` in this document and retagging every scenario in `bdd-specs.md` against this document's numbering as the single source of truth. |
| Skill name: `designing-loops` | **Accepted.** Kebab-case, gerund-action form, matching `using-superpowers` and `receiving-code-review`. | |
| Alternate: `loop-design` | **Rejected.** | Breaks the gerund-action convention; risks confusion with the unrelated `*-design/` folder vocabulary already load-bearing throughout brainstorming/writing-plans. |
| Alternate: `choosing-a-loop` | **Rejected.** | No existing skill directory name contains an article; also under-scopes the skill to selection only, when it also carries quality/token-management citations. |

## Requirements

### Functional — classification behavior

- **REQ-001** — `designing-loops/` is registered under `plugin.json`'s `"skills"` array (`./skills/designing-loops/`), never `"commands"`; frontmatter declares `user-invocable: false`. *Rationale: matches the load-automatically convention of all 4 existing internal skills; a `"commands"` registration would wrongly surface it in `/help`.*
- **REQ-002** — The frontmatter `description` is third-person and names concrete trigger phrases ("should this be `/goal` or `/loop`", "run on a schedule", "set up a recurring agent", "proactive monitoring"), so the skill auto-loads without the caller knowing its name. *Rationale: internal skills have no slash-command entry point — the always-resident description is the only load trigger.*
- **REQ-003** — The skill body classifies the work at hand into exactly one of turn-based / goal-based / time-based / proactive and names the corresponding primitive. *Rationale: the core deliverable — without a forced 1-of-4 classification step the skill degenerates into a reference dump.*
- **REQ-004** — The turn-based section cites `verification-before-completion/SKILL.md` as the existing improver of self-judged stopping, without reproducing its Iron Law or Gate Function. *Rationale: single authoritative owner file; duplication drifts on the next edit.*
- **REQ-005** — The goal-based section cites `skills/references/goal-wrapper.md` and the 5 skills that wrap it, without reproducing Rule 1/Rule 2 or the per-skill condition table — **except** turn-cap phrasing, which is the one piece of original content this section carries (see REQ-023; `goal-wrapper.md` does not yet cover it). *Rationale: `goal-wrapper.md` is already the single shared reference every user-invocable skill points to instead of inlining.*
- **REQ-006** — The time-based section is original content: it describes `/loop` and `/schedule` as native Claude Code commands not shipped by this plugin, and explicitly distinguishes them from the plugin's own deleted v2.x `lib/loop.sh` continuation runtime (removed in v3.0.0, replaced by native `/goal`). *Rationale: grep confirms zero prior documentation of `/loop`/`/schedule` anywhere in this plugin — there is nothing to cite; the runtime-conflation risk is real and must be guarded against explicitly.*
- **REQ-007** — The proactive section cites `workflow-orchestration.md`'s opt-in rules and the existing brainstorming → writing-plans → executing-plans → retrospective chain as a live, partial worked example (each stage individually `/goal`-wrapped today, not yet composed under an outer `/schedule`), without reproducing Workflow's concurrency mechanics. *Rationale: `workflow-orchestration.md` already owns Workflow's opt-in semantics in full.*
- **REQ-008** — The skill states explicitly that a single obvious-outcome turn needs no loop-type classification at all and should not trigger the skill's full body, mirroring `README.md`'s "When NOT to use superpowers" table and the Bail-Out Check philosophy already shared by 4 of the 5 command skills. *Rationale: an internal skill that auto-loads on any loop-shaped language risks becoming exactly the "heavyweight mechanism over-applied to small work" this plugin explicitly guards against elsewhere.*

### Functional — quality and token-management citations

- **REQ-009** — The "maintaining code quality in loops" content cites `verification-before-completion/SKILL.md`, `receiving-code-review/SKILL.md`, the `superpowers-evaluator` agent, the BDD Iron Law (exact text: *"No production code is written without a failing test first."*), and `retrospective`'s checklist-evolution Phase 3 — as one-line pointers, never restated procedures. *Rationale: all five already exist as authoritative, independently-evolving sources; restating any blows the L2 token budget and creates a second source of truth.*
- **REQ-010** — The "managing token usage in loops" content cites `executing-plans`' `CRITICAL — declare a model on every sub-agent dispatch` block (`skills/executing-plans/SKILL.md:81`), every skill's `CRITICAL: Bail-Out Check` pattern, `workflow-orchestration.md` Rule 3's >4-task pilot/scale threshold, and `lib/task-ledger.sh` + `lib/docs-index.sh` as the existing "script over re-derived reasoning" pattern — as pointers, not restated logic. *Rationale: same duplication-avoidance argument as REQ-009.*
- **REQ-011** — The token-management section carries exactly two pieces of genuinely new guidance, since neither exists anywhere in this plugin today: (a) match `/loop`/`/schedule` polling interval to actual change frequency; (b) periodically review usage via `/usage`, `/goal` (no-arg form), and `/workflows`. *Rationale: grep-confirmed gap; these are the skill's second load-bearing original-content block, parallel to REQ-006.*
- **REQ-023** — The goal-based section (REQ-005) additionally documents explicit turn-cap phrasing ("stop after N tries") as original content, flagged inline as a candidate for future consolidation into `goal-wrapper.md` — not implemented as an edit to `goal-wrapper.md` in this design (see Risks, below, for why this stays deferred rather than bundled). *Rationale: `goal-wrapper.md`'s Rule 2 table covers condition phrasing only; the blog explicitly calls out turn caps as part of managing a goal-based loop, and REQ-005's "cite, don't restate" framing would otherwise silently drop this guidance since there is nothing to cite it from.*

### Non-functional

- **REQ-012** — Every load-bearing classification rule (the 4-way exhaustive classification itself, the trivial-work bail-out of REQ-008, the citation-not-duplication constraint) carries an explicit `CRITICAL:` block in the L2 `SKILL.md` body — never left to soft wording or deferred to L3. *Rationale: directly required by the recorded lesson that L3-only or softly-worded rules are empirically skipped by agents, most recently repeated on this exact plugin's `verification-before-completion`/`receiving-code-review` rollout.*
- **REQ-020** — `skills/designing-loops/SKILL.md`'s L2 body stays under ~5k tokens; content that would push it over moves to `references/`, except load-bearing `CRITICAL:` rules (REQ-012), which keep their marker in L2 even if supporting detail moves to L3. *Rationale: this repo's own token-budget policy.*
- **REQ-021** — Directory name, frontmatter `name:`, and every cross-link reference read exactly `designing-loops` (kebab-case, gerund-action form). *Rationale: matches the pattern set by `using-superpowers`/`receiving-code-review`.*
- **REQ-022** — `SKILL.md` and all cross-link edits use the Glossary's canonical terms exactly and never introduce "autonomous loop" anywhere. *Rationale: prevents the vocabulary-drift failure mode this design's own Phase 2 reconciliation exists to catch (see the requirement-ID-format finding above).*

### Cross-link integration (structural — see Traceability Notes in `bdd-specs.md`; verified by grep, not Gherkin)

- **REQ-013** — `using-superpowers/SKILL.md` gets a short new section (not a routing-table row) distinguishing "which skill" (its own routing table) from designing-loops' orthogonal "how to run it" — inserted between the routing table (ends line 27) and `## Lineage and rationale` (line 29). Verified: the `| Trigger signal | Invoke |` table itself contains zero occurrences of `designing-loops`.
- **REQ-014** — Each of `brainstorming`, `writing-plans`, `executing-plans`, `retrospective`, `systematic-debugging`'s existing `## Recommended: run wrapped in /goal` section gets one added sentence pointing to `designing-loops`, anchored immediately after each file's existing goal-wrapper.md citation sentence (exact anchor lines in `architecture.md`).
- **REQ-015** — `retrospective/SKILL.md` additionally notes it is a natural time-based/proactive (`/schedule`) candidate since it is inherently periodic maintenance work — merged into the same sentence as REQ-014's edit for this file, to conserve the file's already-tight token budget (4671/5000 baseline).
- **REQ-016** — `systematic-debugging/SKILL.md` additionally notes flaky/CI-dependent regressions are a natural time-based (`/loop`) candidate for repeated re-verification after Phase 4 lands a fix, anchored at the "When Process Reveals No Root Cause" section (line 361-362) and appended as a second bullet to the existing `**Related skills:**` list (lines 372-373).
- **REQ-017** — `skills/references/workflow-orchestration.md` gets exactly one new "See also" line pointing to `designing-loops`, appended as a new final section (the file currently has none).
- **REQ-018** — `README.md`'s `## Internal Skills (Loaded Automatically)` section gets a new `### Designing Loops` subsection, in the same format as the existing two entries. This edit additionally completes the section's two missing entries (`verification-before-completion`, `receiving-code-review`) — a pre-existing gap in the exact same section this design is already editing, not a bundled fix to an unrelated subsystem (see Risks).
- **REQ-019** — All 7 cross-link points above (REQ-013 through REQ-018, with REQ-014 counting as 5 files) are independently verifiable by a single `grep -l designing-loops <file>` per target file, run as a post-implementation check — not a subjective read.

## Rationale

**Why a new internal skill, not an extension of `using-superpowers` or `goal-wrapper.md`:** `using-superpowers` answers *which skill*; `designing-loops` answers the orthogonal *how to run it*. Folding the two together doesn't just conflate two decisions in one file — it concretely couldn't work, because internal skills carry no `superpowers:`-prefixed invocation for `hooks/session-start.sh`'s routing-table scrape to find. `goal-wrapper.md` is narrowly and correctly scoped to goal-based-loop semantics (its own stated purpose: "Shared reference for the `## Recommended: run wrapped in /goal` section"); extending it to also cover turn-based/time-based/proactive would mean every one of the 5 skills that link to it for pure `/goal` semantics starts pulling in unrelated content on every reference.

**Why citation-not-duplication for the two supporting blog sections:** token budget is the concrete constraint — this repo caps `SKILL.md` L2 bodies at ~5k tokens, and two of the five existing command skills are already within 5-7% of that limit. Restating five to seven existing skills' procedures verbatim would alone consume a large fraction of the new skill's budget before it says a single original word. Beyond budget: duplication creates a second source of truth with no mechanism to keep it in sync, and — critically — this isn't a new pattern being introduced here. Every one of the 5 user-invocable skills already links to `goal-wrapper.md` with a single pointer instead of re-explaining it inline; `designing-loops` follows the identical, already-proven precedent rather than inventing a second citation style.

## Detailed Design

### File layout

```
superpowers/skills/designing-loops/
├── SKILL.md                              (L2, <5k tokens)
└── references/
    ├── loop-types.md                     (L3: full 4-type decision matrix,
    │                                       /loop vs /schedule vs /goal mechanics,
    │                                       turn-cap phrasing detail, interval-
    │                                       matching guidance, the brainstorming→
    │                                       retrospective chain worked example)
    └── quality-and-token-management.md   (L3: expanded citation map — each blog
                                            concern → the specific existing
                                            skill/file:line that implements it)
```

Two L3 files, not three: the originally-considered separate `primitive-comparison.md` is folded into `loop-types.md` to avoid over-fragmenting what is, in total, a moderate amount of content (20 BDD scenarios across 5 Gherkin Features, a 4-row decision table, and two citation-heavy supporting sections) — matching how `systematic-debugging` and `writing-plans` each keep 3-5 references files rather than one-per-subtopic.

### Frontmatter

```yaml
---
name: designing-loops
description: This skill should be used when choosing how a task should run, not which skill to run. Trigger phrases — "should this run as /loop or /goal", "automate this check", "run on a schedule", "set up a recurring agent", "proactive monitoring" — route here. Classifies work into four loop types (turn-based / goal-based / time-based / proactive) and names the matching primitive; defers code-quality and token-management concerns to verification-before-completion, receiving-code-review, the superpowers-evaluator agent, and workflow-orchestration.md rather than restating them.
user-invocable: false
---
```

Matches the exact 3-field shape shared by all 4 existing internal skills (no `argument-hint`, no `allowed-tools` — both are command-skill-only fields). The description leads with the "which skill vs. how to run it" distinction so that framing is resident in context even before the body loads, directly supporting REQ-013's cross-link in `using-superpowers`.

### SKILL.md body shape (L2)

1. Title + one-paragraph framing establishing the orthogonal axis.
2. `## CRITICAL: Classify the loop type` — compact 4-row table (loop type → signal → primitive → one-line example) plus the exhaustiveness/citation-not-duplication rules, marked `CRITICAL:` per REQ-012.
3. `## CRITICAL: Stay out of the way for trivial work` — REQ-008's bail-out statement, mirroring the phrasing style of the other 4 command skills' Bail-Out Checks (though this is a shorter, single-paragraph version since designing-loops isn't itself a command with its own `$ARGUMENTS`).
4. `## Maintaining quality in loops` — short paragraph + bullet citations (REQ-009).
5. `## Managing token usage in loops` — short paragraph + bullet citations (REQ-010) + the two new-guidance bullets (REQ-011).
6. `## References` footer listing the two L3 files.

### Risks

- **Risk: cross-link edits push `retrospective`/`writing-plans` past the 5000-token L2 hard limit.** Baseline is 4671/4778 of 5000. *Mitigation:* keep each added sentence to a single clause (REQ-015's merge of two concerns into one sentence is the concrete instance of this), and re-run `python3 plugin-optimizer/scripts/validate-plugin.py superpowers` after every file edit during implementation — revert to a shorter phrasing immediately if a `should` warning escalates toward the `must`-level exit-2 threshold.
- **Risk: "autonomous loop" terminology collision.** Confirmed live risk — Claude Code's "auto mode" and `brainstorming`'s own pre-existing generic "autonomous" usage both create room for confusion. *Mitigation:* `grep -ri "autonomous loop" superpowers/skills/designing-loops/` returning zero matches is an explicit verification step in the eventual implementation plan, not left to manual review alone.
- **Risk: README's Internal Skills section backfill (REQ-018) reads as scope creep.** *Mitigation:* the backfill is confined to the exact section this design is already required to edit for its own primary entry (`### Designing Loops`) — same file, same `##` section, not a different subsystem — so it satisfies the "same lib/skill as the primary design scope" exception rather than requiring extraction to a sibling retro file.
- **Risk: `goal-wrapper.md`'s missing turn-cap guidance gets duplicated inconsistently later.** *Mitigation:* deliberately **not** edited by this design (kept out of scope — see REQ-023's "deferred, not bundled" framing); `designing-loops`' own turn-cap content carries an explicit one-line "candidate for future consolidation into `goal-wrapper.md`" note so a future editor finds the existing content before writing a second copy.

## Design Documents

- [`bdd-specs.md`](./bdd-specs.md) — 20 Gherkin scenarios across 5 Features (turn-based, goal-based, time-based, proactive, quality/token discipline), tagged against this document's `REQ-NNN` requirement IDs, plus Traceability Notes for the 11 structural/non-functional requirements not expressed as runtime behavior.
- [`architecture.md`](./architecture.md) — file layout, exact file:line anchors for all 7 cross-link edits, `plugin.json` diff shape, baseline validation output.
- [`best-practices.md`](./best-practices.md) — loop-selection-specific pitfalls (over-/under-recommendation), the CRITICAL-marker placement lesson applied to this skill, and the forward pointer on skill-content behavioral testing.
