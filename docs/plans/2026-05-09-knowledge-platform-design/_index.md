# Superpowers v3.x — Knowledge Platform Design

**Date**: 2026-05-09
**Status**: ⚠ **DESIGN-NOT-YET-JUSTIFIED** — see §0 below
**Predecessor**: `docs/retros/meta-retro-2026-05-08-superpowers-v2.8.x.md`
**Scope deferred to sub-agents**: architecture data flow diagrams, BDD scenarios, best-practices guidance

---

## §0. Design Status & Caveats (added post-Phase-2)

This design folder is committed as **reference material**, not as approval to proceed to `writing-plans`. The Phase 2 context+requirements sub-agent, after writing this _index.md, returned an unsolicited self-reflection (delivered as a delayed task-notification) that critiqued its own output along the same lines `meta-retro-2026-05-08-superpowers-v2.8.x.md` critiqued v2.8.x:

| Sub-agent's self-critique | Verbatim quote |
|---|---|
| **N=0 evidence base** | "Based on N=0 project data, weaker than v2.8.x's N=1" |
| **Path 3 is post-hoc rationalization** | "User answering 3 forcing-function questions ≠ v3.x must be designed; Path A / Path C are strawmen" |
| **SC-NN are circular** | "Criteria assume v3.1 has shipped — the real SC should be 'should v3.0 ship at all'" |
| **NFR-01 numbers are fabricated** | "50ms p50 / 200ms p99 has no baseline measurement backing" |
| **Structurally replicates v2.8.x add-bias** | "28 requirements / 4 phases / multi-channel architecture, no external review gate, no 'don't do' path" |
| **What should have been written** | "v3.x not yet justified. Recommend: dogfood v2.8.2 + Phase 0 channels on ≥3 projects, measure read-rate, collect friction points in `docs/retros/v3-evidence.jsonl` as real-data basis before designing v3.x" |

The maintainer accepts this self-critique as substantive. The design as written has the maintainer's stated `lean B` (rewrite as reject document) but takes a non-destructive `C-variant` approach: keep the design folder as a reference of what v3.x *would* look like if justified, mark its status, and **do not advance to writing-plans**.

### Activation gate (before this design becomes implementable)

Before any portion of this design moves to `writing-plans`, the following evidence must be collected from real-project usage of v2.8.2 + Phase 0 channels:

1. **≥3 distinct projects** have completed at least one full plan cycle using v2.8.2 (post-plan-diff + bail-log + harness-observations + plans-completed channels in steady use).
2. **`docs/retros/v3-evidence.jsonl`** in each project records concrete friction points the user encountered that v3.x would have addressed — at least one per project, with a description of what was lost by not having v3.x. Append-only, format: `{"event":"v3_friction","timestamp":"...","class":"between_plan|ai_dialogue|external|cross_project","description":"...","could_phase_0_handle":false,"workaround_used":"..."}`.
3. **Phase 0 read-rate measurement** across the same ≥3 projects shows consumers (retrospective Phase 5a, executing-plans Phase 6) actually read post-plan-diff / bail-log / harness-observations data with non-trivial frequency. If Phase 0 itself doesn't earn its weight, v3.x can't.
4. **A formal `meta-retrospective` skill run** (out-of-band, not a normal `retrospective`) reviews the v3-evidence corpus and emits PASS / REWORK on whether v3.x scope still matches user friction.

If activation gate passes, this design folder is the starting reference — sub-agents in a fresh brainstorming session re-examine each FR/NFR/SC against the v3-evidence corpus and prune anything that wasn't actually a real friction. The pruning factor is expected to be 30-50% per sub-agent self-prediction.

If activation gate fails (≥3 projects use v2.8.2 happily without missing v3.x scope), this folder ages out as documentation that v3.x was considered and deemed unnecessary — itself useful audit evidence.

### Why not just delete this folder

The design surfaced real architectural reasoning (3 hard rules from Path 3 / privacy tier matrix / phase-gated rollout). If the activation gate ever passes, this artifact saves redoing that reasoning. The cost of keeping it is bytes; the cost of redoing it from scratch under deadline pressure is 30+ minutes of focused brainstorming. Keep, mark status, do not advance.

---

---

## Context

The v2.8.x arc closed with a deliberate non-implementation of v2.9.0. The maintainer wrote a meta-retrospective rather than ship retract patches, because the arc itself surfaced structural lessons that should not be buried under another round of mechanism work.

Five lessons drive v3.x:

1. **LLM add-bias is structural, not stylistic.** Across v2.8.0 / v2.8.1 / v2.8.2 / simplify, each round patched the previous round's verbosity. Implementation-mode LLMs default to visible-add over invisible-skip because adding produces tangible output. Code-layer review (`simplify`) and mechanism-layer review (external ultrathink) are different review depths and both are required periodically.
2. **N=1 decisions over-fit.** The Phase 5b veto, Pre-Check A, and `task_count` field were all predicated on a single disable-test outcome from one project (`user-simulation`). Once promoted to mechanism, they ossified.
3. **Pacing failure compounds.** Four implementation rounds in one session produced ~1,479 net lines, of which only ~80 were real bug fixes (~5%). The remaining ~1,400 lines were mechanism additions whose ROI was unverifiable from inside the session.
4. **Mechanism layering without external review** suppresses user input surface. The Phase 5b auto-veto removed candidates from Phase 4 `AskUserQuestion` review — implementing a "safety layer" that *reduced* rather than *augmented* the human approval surface.
5. **The plan is a thin slice of real work.** Rough estimate: 80% of an engineer's contextful output happens *outside* the brainstorming → plan → execute pipeline — between-plan code spelunking, AI dialogues, external reading, cross-project pattern transfer. v2.8.x captured a sliver via `plans-completed.jsonl` + `harness-observations.jsonl`. Everything else fell through.

v3.x is therefore not a continuation of v2.8.x. It is a **qualitative shift from plan-shaped capture to flow-aware capture**, while preserving the restraint DNA the v2.8.x retrospective retroactively imposed: meta-recursive calibration, bounded blast radius, phase-gated rollout. Without that DNA, v3.x would simply re-run the add-bias spiral at a larger scope.

---

## Discovery Results

The user's Phase 1 answers fixed the four-quadrant scope. Each quadrant has different signal density, different existing surrogates, and different reasons superpowers can deliver value none of the surrogates do.

| Content class | Signal density | Existing surrogate | Superpowers differentiator |
|---|---|---|---|
| **Between-plan code work** (direct edits, debugging detours, throwaway scripts, refactors not under any plan) | High — every commit + every uncommitted diff carries intent | git history, IDE local history | Links commits to *the calibration loop* — every diff becomes potential evidence for ADD/REMOVE/PROMOTE decisions in the next retrospective, not just a log entry |
| **AI dialogues** (claude-code transcripts, conversations with other agents, pasted decisions) | High but privacy-heavy — transcripts contain credentials, partial code, half-formed designs | None within superpowers; raw transcripts in `~/.claude/projects/` | Distills decision-shaped content out of conversational noise; tier-gates raw transcripts so retrospective reads decisions, not chat |
| **External reading** (browser sessions, docs, papers, blog posts, video notes) | Variable — often noise; occasional load-bearing reference | Browser history, Obsidian, Readwise | Captures only the *referenced* fraction (cited in a plan, quoted in a decision, linked in a commit message), not the firehose |
| **Cross-project pattern transfer** (a lesson from project A applied to project B) | Low frequency, very high value — the multiplier of repeated experience | Memory in `~/.claude/projects/.../memory/MEMORY.md` (already in use), retrospective notes | Indexes by pattern not project; retrospective and brainstorming can query "have we seen this shape before?" across the user's entire project portfolio |

v2.8.x Phase 0 already covers a strict subset: `post-plan-diff.sh` reads commits made *after* a plan completes (between-plan code work, scoped to the same repo + a 24h window). `bail-log.sh` captures one specific kind of decision-shaped content (skill bail-outs and `--force` overrides). `harness-observations.jsonl` captures another (component-disable trial outcomes). v3.x extends these channels rather than replacing them — Phase 0 is the proof that selective capture works under restraint.

The reject paths are equally informative:

- **Path A — plan-shaped retrenchment** (kill v2.8.x extensions, return to v2.7.0 minimal capture). Rejected: solves add-bias by amputating value the user explicitly asked for.
- **Path C — lightweight inbox** (a single jsonl any skill appends to, retrospective greps). Rejected: collapses tier semantics; once private content lands in the inbox, retraction requires deletion not de-classification, and brainstorming reads have no scoping.

---

## Requirements

### Functional Requirements

- **FR-01** — The system shall passively capture commit-shaped between-plan code work in the active repo without user action, extending the v2.8.x `post-plan-diff` channel beyond the 24h post-plan window.
- **FR-02** — The system shall expose an active capture verb (a single skill or hook entry point) so users can promote a specific diff, file, transcript snippet, or external URL into a v3.x channel without leaving their flow.
- **FR-03** — The system shall capture AI-dialogue decisions only via opt-in: each session begins with v3.x dialogue capture **off**; the user enables it explicitly per project or per session.
- **FR-04** — The system shall capture external reading references only when the user explicitly cites a URL/title in a plan, retrospective, or decision artifact. No browser-history scraping, no background polling.
- **FR-05** — The system shall index captured content by *pattern* (extracted shape: e.g. "race-condition fix in async pipeline") in addition to project + timestamp, enabling cross-project retrieval.
- **FR-06** — The retrospective skill shall, in Phase 1, read the v3.x between-plan and decision channels alongside the existing `plans-completed.jsonl` and `harness-observations.jsonl`, and surface signals from them in the analysis report.
- **FR-07** — The brainstorming skill shall, in Phase 1.5 (Harness Config Check), query v3.x for prior cross-project patterns matching the current scope and surface up to 3 to the user; user opt-in required to surface more.
- **FR-08** — The executing-plans skill shall, in Phase 6 (post-batch reporting), append batch-level observations to the v3.x decision channel only when the per-batch evaluator emits a non-trivial signal.
- **FR-09** — Each captured item shall carry a privacy **tier** field with at least three levels: `public` (shareable), `project` (this repo only), `local` (this machine only, never synced).
- **FR-10** — The user shall be able to retract a single captured item by ID via a single CLI / skill invocation; retraction shall be append-only (writes a `retracted` event), not destructive deletion, so audit history survives.
- **FR-11** — The user shall be able to promote or demote tier on a captured item without re-capturing.
- **FR-12** — The user shall be able to disable any single v3.x capture component independently (e.g. dialogue capture off, external-reading capture on) without cascading effects.
- **FR-13** — Each v3.x component shall log its own value signal — the count of times its captured data was *read* by a downstream consumer (retrospective, brainstorming) — to enable a meta-recursive calibration loop equivalent to v2.8.x `harness-observations`.
- **FR-14** — When a v3.x component's read-rate falls below threshold across N projects, the retrospective skill shall surface it as a retract candidate via `AskUserQuestion`, mirroring the existing harness-component disable flow.
- **FR-15** — The system shall provide a single "audit view" (a CLI command or skill) that lists all v3.x captured items for the current project / session, grouped by tier, in a form the user can review in under one minute.

### Non-Functional Requirements

- **NFR-01 — Performance budget**: total Stop-hook latency shall not regress beyond the v2.8.2 baseline by more than 50ms p50 / 200ms p99 across v3.x channels combined. Capture is async-first.
- **NFR-02 — Privacy SLO per tier**: `public` items pass a content scrubber (no absolute paths, no env-var values); `project` items stay inside the repo's `docs/` tree; `local` items stay under `~/.claude/projects/<project-key>/` and never enter any file the user could `git add`.
- **NFR-03 — Backward compatibility**: v2.8.x channels (`plans-completed.jsonl`, `harness-observations.jsonl`, `bail-log.jsonl`) keep their schemas; v3.x reads them but does not rewrite them. Pre-v3.x data ages out by being ignored when consumers prefer v3.x channels for new analyses; no migration step.
- **NFR-04 — Observability**: the audit view (FR-15) shall render in under 1s for a project with up to 1,000 captured items; raw jsonl files remain human-readable with `jq`.
- **NFR-05 — Reversibility**: any v3.x component shall be disable-able via a single flag in a single config file, with no cascading skill failures. The retract patch for any single component is a one-commit operation.
- **NFR-06 — Test coverage**: every new lib script (capture, query, retract, audit) ships with an integration test reproducing one realistic capture-then-read cycle; no mock-only coverage.
- **NFR-07 — Zero-cost default**: a fresh project that has not opted in shall observe zero v3.x file writes beyond what v2.8.2 already produces; v3.x is invisible until activated.
- **NFR-08 — Schema versioning**: every v3.x jsonl line carries a `schema_version` field; consumers tolerate one major-version drift to allow phase-gated rollout.

---

## Rationale

The user selected **Path 3** (knowledge platform with hard architecture constraints) over Path 1 (plan-shaped retrenchment) and Path 2 (full firehose capture). The selection rests on three load-bearing claims, each tied to a specific v2.8.x failure mode the v3.x design must avoid repeating.

**Path A retrenchment was rejected** because it amputates value: 80% of the user's contextful output remains uncaptured. The v2.8.x lesson is that mechanism can over-fit, not that capture is wrong.

**Path C lightweight-inbox was rejected** because it collapses tier semantics. A flat inbox forces a binary "captured / not captured" choice; without tier, the user cannot route private decisions through the same skill that handles shareable patterns. v2.8.x already proved that the lack of a privacy boundary breeds add-bias workarounds.

**Path 3 with three hard architecture rules — meta-recursive calibration, privacy tier, phase-gated rollout — is the choice that survives the v2.8.x post-mortem.** Each rule maps to one of the lessons:

- **Meta-recursive calibration** (FR-13, FR-14) addresses Lesson 1 (add-bias). Every v3.x component must, by construction, log its own read-rate; if no consumer reads it, the retrospective surfaces it for retract. This is the structural antidote to "add a mechanism, never review whether it earned its weight" — the exact failure mode of v2.8.x Phase 5b veto.
- **Privacy tier** (FR-09, FR-10, FR-11, NFR-02) addresses Lesson 4 (input-surface suppression). Tier semantics keep the user in the loop on every capture: nothing escapes the local tier without an explicit promote action. This is the structural inverse of an auto-veto: tiers default to *more* user agency, not less.
- **Phase-gated rollout** (NFR-03, NFR-05, NFR-07, NFR-08) addresses Lessons 2 and 3 (N=1 over-fit and pacing failure). v3.x ships as four independently disable-able phases over time; no phase blocks a later one. A single phase failing the read-rate gate freezes subsequent phases until evidence accumulates from ≥3 projects.

Together, the three rules make v3.x **architecturally incapable** of repeating v2.8.x's spiral. The retrospective gains new evidence channels without gaining new dictatorial gates; the brainstorming gains new prior-pattern reads without new auto-vetoes; the user gains new capture verbs without new ritual.

---

## Detailed Design (outline)

Architecture sub-agent will fill the data-flow diagram, schema specifications, and lib-script signatures. This section names the phase structure and the integration anchor points.

**Phase structure (cumulative; each gate is read-rate evidence over ≥3 projects):**

- **Phase 0 — already shipped in v2.8.x.** `post-plan-diff.sh`, `bail-log.sh`, `harness-observations.jsonl`. v3.x treats these as the schema baseline and consumer prototypes.
- **Phase 1 — between-plan code capture extension.** Extends `post-plan-diff.sh` beyond the 24h window to a continuous channel. Adds the audit view (FR-15) as the first cross-channel reader. Read-rate gate decides whether Phase 2 ships.
- **Phase 2 — decision-shaped capture.** AI-dialogue distillation + active capture verb. Tier-enforced from day one. Read-rate gate decides whether Phase 3 ships.
- **Phase 3 — cross-project pattern indexing.** External reading citations + pattern extraction + cross-project query. Built on Phases 1 and 2's accumulated channels; deferred until both have positive read-rate evidence.

**Order-of-magnitude deliverables (architecture sub-agent will refine):**

- ~3–5 new skills (one capture verb, one retract verb, one audit view, plus optional dialogue-distill and pattern-query skills).
- ~3–5 new lib scripts (capture-write, channel-read, retract-write, audit-render, pattern-index).
- ~3 new jsonl channels (between-plan, decisions, citations); cross-project pattern index lives in a derived form, not a fourth channel.
- ~2–3 new schemas (capture event, retract event, citation event); each carries `schema_version`, `tier`, `component`, plus channel-specific fields.

**Integration anchor points with the v2.8.x calibration loop:**

- **`retrospective` Phase 1** (Sample selection): reads v3.x channels via the same scoped-by-`docs/retros/plans-completed.jsonl` mechanism; v3.x adds new evidence rows but does not change Phase 1's existing AskUserQuestion surface.
- **`brainstorming` Phase 1.5** (Harness Config Check): adds a Cross-Project Patterns surface (FR-07) gated to top-3 hits with explicit user opt-in for more; retains Phase 1.5's existing harness-config audit role.
- **`executing-plans` Phase 6** (Per-batch reporting): appends decision-tier events only when the evaluator's signal is non-trivial; defaults to silent.

**Out of scope for v3.x:** automatic semantic search, embedding-based retrieval, any LLM-call inside a hook, any sync-to-cloud component. These remain v4.x territory and ship only after v3.x has produced ≥3-project read-rate evidence justifying the next leap.

---

## Success Criteria

- **SC-01** — After v3.1 has run on N=3 distinct projects, every Phase 1 component carries ≥1 documented read by a downstream consumer (retrospective or brainstorming) per project, or the next retrospective surfaces it for retract.
- **SC-02** — Across N=3 projects, the count of v3.x components surfaced for retract is ≤1; if ≥2 surface, Phase 2 freezes until the cause is diagnosed and the meta-recursive calibration rule itself is re-validated.
- **SC-03** — Privacy-tier violation pre-edit detection achieves 100% coverage on a curated 20-case test corpus before Phase 2 ships (cases include credentials, absolute paths, env-var values, and partial diffs against `.env`).
- **SC-04** — Stop-hook latency regression measured on the user-simulation project stays within NFR-01 across at least one full v3.1 dogfood pass.
- **SC-05** — Audit view (FR-15) renders project state in under 60 seconds of user reading time on a representative N=3 project sample, validated by direct user observation.
