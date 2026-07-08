# Designing Loops — Architecture (v2, reference-file shape)

Repo-root-relative paths. Anchors re-verified against live files 2026-07-08. The round-1 (skill-shaped) architecture — `plugin.json` diff, frontmatter, README section — is superseded by the pivot recorded in `_index.md`; this file describes only the pivoted shape.

## 1. New file

`superpowers/skills/references/loop-types.md` — plain markdown, no frontmatter, no registration (REQ-001). Sits beside `git-commit.md`, `goal-wrapper.md`, `workflow-orchestration.md`. Skeleton (REQ-002–REQ-008; ~60-90 lines per REQ-017):

```markdown
# Choosing how a task should run (loop types)

One-paragraph intro: four loop types, pick exactly one; trivial single-turn
work needs no classification — proceed directly.

| Loop type | Trigger / stop | Primitive | Example |
|---|---|---|---|
| turn-based | user prompt / Claude judges done | plain turn | (edit + verify) |
| goal-based | user prompt / condition met or turn cap | `/goal` | /goal "tests print 0 failures" (stop after 5 tries) ... |
| time-based | interval / user cancels or work completes | `/loop`, `/schedule` | /loop 5m "check PR #482 CI" |
| proactive | event or schedule, unattended / each task exits on its goal | `/schedule` + `/goal` + `Workflow` + auto mode | (hourly triage routine) |

## Turn-based        (citations: verification-before-completion; receiving-code-review + superpowers-evaluator)
## Goal-based        (citation: ./goal-wrapper.md incl. Rule 3 — zero original content)
## Time-based        (ORIGINAL: native /loop and /schedule; NOT the deleted v2.x lib/loop.sh runtime; interval matching)
## Proactive         (citations: ./workflow-orchestration.md Rule 2 opt-in + Rule 3 threshold; the brainstorming→retrospective chain as partial example)
## Quality and token discipline in loops   (citation map + /usage, /goal no-arg, /workflows review note)
```

Citation style throughout (REQ-009): `file path + section/rule name`, e.g. "`./workflow-orchestration.md` Rule 2 — user must opt in"; no bare line numbers; verbatim quotes only where the exact wording is the point (the two Iron Law one-liners at most).

## 2. goal-wrapper.md Rule 3 (REQ-010)

Insert between Rule 2's table (ends line 28, blank line 29) and `## Recommended conditions per skill` (line 30):

```markdown
## Rule 3 — pair the condition with an explicit turn cap for open-ended work

For hypothesis-driven or exploratory work (root-cause debugging, "keep improving
until it feels right"), the completion condition alone is not enough — pair it
with an explicit cap: "stop after N tries". Without a cap, a condition that never
quite resolves (a flaky reproduction, a subjective quality bar) can run
indefinitely:

/goal "<completion condition>" (stop after <N> tries) /superpowers:<skill> <args>

Not every invocation needs a cap — a bounded, well-scoped pipeline (e.g.
writing-plans on an already-locked design) converges naturally. Reach for a cap
when the condition depends on an outcome Claude does not fully control — see
`./loop-types.md` for the broader turn-based/goal-based/time-based/proactive
classification this pairs with.
```

The closing pointer doubles as this file's REQ-014 grep witness.

## 3. Pointer-sentence anchors (REQ-011, REQ-012, REQ-013)

### 3.1 Five command skills — after each `/goal` section's closing goal-wrapper citation, before the next `##` heading

| File | Anchor line (closing sentence) | Next heading |
|---|---|---|
| `brainstorming/SKILL.md` | 20 | 22 `## CRITICAL: Bail-Out Check...` |
| `writing-plans/SKILL.md` | 21 | 23 `## CRITICAL: Bail-Out Check (run first)` |
| `executing-plans/SKILL.md` | 21 | 23 `## Step 1 of every iteration...` |
| `retrospective/SKILL.md` | 23 | 25 `## Pre-Check (run first, in order)` |
| `systematic-debugging/SKILL.md` | 27 | 29 `## CRITICAL: Bail-Out Check...` |

Sentence (brainstorming / writing-plans / executing-plans / systematic-debugging): *"To decide whether this run should be a plain turn, `/goal`, `/loop`, or `/schedule`, see `../../skills/references/loop-types.md`."*

retrospective (merged single sentence — 4671/5000 ceiling): *"Retrospective is periodic maintenance work — a natural time-based/proactive (`/schedule`) candidate rather than a one-off `/goal` run; see `../../skills/references/loop-types.md`."*

### 3.2 systematic-debugging — second anchor (REQ-011)

After line 361 (`**Note:** 95% of "no root cause"...`), before line 363 `## References`: one sentence — environmental/timing-dependent symptoms and flaky reproductions fit a time-based `/loop` re-verification loop; pointer to `../../skills/references/loop-types.md`. Plus one bullet appended to the existing `**Related skills:**` list (lines 372-373): `- \`../../skills/references/loop-types.md\` - loop-type classification (turn/goal/time/proactive) for flaky or recurring debugging work`.

### 3.3 using-superpowers — one sentence, outside the table (REQ-012)

Between the routing table (ends line 27) and `## Lineage and rationale` (line 29). Must NOT be a table row — `hooks/session-start.sh:28` greps `^\| .*superpowers:` into every session bootstrap. Sentence: *"That table answers which skill; for the orthogonal question of how the chosen work should run (plain turn, `/goal`, `/loop`, `/schedule`), see `../references/loop-types.md`."*

### 3.4 workflow-orchestration.md — final section (REQ-013)

Append after line 52 (current EOF):

```markdown
## See also

`./loop-types.md` — `Workflow` composition is the proactive arm of the four loop types; the other three (turn-based, goal-based/`/goal`, time-based/`/loop` `/schedule`) live there.
```

## 4. Verification (REQ-014, REQ-015, REQ-016)

```bash
# pointer existence — all 8 files must match
grep -l "loop-types" \
  superpowers/skills/{brainstorming,writing-plans,executing-plans,retrospective,systematic-debugging,using-superpowers}/SKILL.md \
  superpowers/skills/references/{workflow-orchestration,goal-wrapper}.md
# Rule 3 content actually present, not just the pointer
grep -q "Rule 3" superpowers/skills/references/goal-wrapper.md && echo RULE3-OK
# vocabulary gate
grep -ri "autonomous loop" superpowers/skills/ && echo FAIL || echo VOCAB-OK
# token ceilings — after EVERY edit to retrospective/writing-plans
python3 plugin-optimizer/scripts/validate-plugin.py superpowers   # must stay exit 0
```

Baseline (2026-07-08): superpowers validator exit 0 with two pre-existing `should` warnings (retrospective 4671, writing-plans 4778 of 5000).
