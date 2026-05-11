# Brainstorming SKILL.md vocab reform — 2026-05-10 retro

**Type**: dedicated retro for four `superpowers/skills/brainstorming/SKILL.md` changes that surfaced during the unrelated harness-evidence channel design and were already landed in 2026-05-09 commits. This file extracts that audit trail from `docs/plans/2026-05-09-harness-evidence-channel-design/` so the harness-evidence PR is single-scope.

**Predecessor**: `docs/retros/2026-05-09-v3-considered-deferred.md` (the v3.x reject retro that triggered this brainstorm cycle in the first place).

## Why this exists as its own file

The harness-evidence design (which is itself a downstream-of-v3-retro design) surfaced four issues in `brainstorming/SKILL.md` while being authored. Bundling them into the harness-evidence PR would repeat the v3 retro §6 add-bias mode: "do not advance v3.x inside any conversational arc that produces v2.8.x or v2.9.x retract patches" — generalized, "do not bundle unrelated discoveries into a single PR even when the discovery happened during that PR's work".

The four changes landed on 2026-05-09 in commits `45e5096` and `904b18f`. This file is the retroactive audit trail.

## The four changes

### Change 1 — Phase 1.5 rename in the loop template

The loop template inside `Initialization` referenced "Read Harness Config" as the Phase 1.5 step, while the actual Phase 1.5 heading downstream said "Read Harness Config — assumption test". The template and the heading were authored at different times and drifted.

**Fix**: template updated to match the heading verbatim. No behavior change; readability.

### Change 2 — Phase 2 promoted to "Design with QA + Vocabulary Reconciliation"

The previous heading was "Design with QA". Vocabulary reconciliation was a sub-step buried inside the phase body. The harness-evidence design's Glossary requirement made it visible that the *primary failure mode* the v3 retro §2 documented (sub-agents diverging on `privacy-tier` vocabulary: `public/project/local` vs `local-only/cross-session/cross-project/external`) was caused by vocab-reconciliation happening too late inside the phase rather than being a Phase entry-condition.

**Fix**: vocab reconciliation promoted from sub-step to header-level concern. Phase 2 now opens with a vocab-pass before design work. This is the direct generalization of the v3 retro §2 symptom into a phase-level discipline.

### Change 3 — New "Pre-loop Resolution" section before Initialization

The loop's `state.prompt` is immutable after `setup-superpower-loop.sh` writes it. Authoring the harness-evidence design exposed that `$ARGUMENTS` resolution (specifically the `--force` token strip) needed to happen *before* the script runs, not after. Without this section, the bail-out check's `--force` handling and the loop's `state.prompt` could disagree about what the user actually typed.

**Fix**: dedicated "Pre-loop Resolution" section between the Bail-Out Check and Initialization. Documents the `state.prompt` immutability contract and the `$ARGUMENTS` strip-and-anchor sequence.

### Change 4 — Phase 1 rejection branch reword

The rejection branch in Phase 1 contained an instruction to "reset captured `$ARGUMENTS`" — a no-op given Change 3's invariant that `$ARGUMENTS` is already resolved at loop-start time. Confusing to read; carried no behavior.

**Fix**: instruction removed. The branch now only describes the user-facing reset (asking the user to re-scope), not a redundant variable touch.

## Why these were not in the harness-evidence PR

`docs/plans/2026-05-09-harness-evidence-channel-design/architecture.md` §D originally enumerated all four as "downstream consequences of this design". Post-round-1 evaluation pivot, design checklist v2's SCOPE-CREEP-01 made the cleaving explicit: discoveries that surface during a design but address an unrelated subsystem get their own PR, even when the cost is one extra commit.

The harness-evidence design's §D audit-trail addendum now carries only a single one-line cross-reference to this file, not the four-item enumeration.

## Audit trail

- 2026-05-09: changes landed in commits `45e5096 docs(sp): clarify brainstorming arg resolution` and `904b18f docs: document brainstorming input flow`
- 2026-05-10: harness-evidence design pivot identified the bundling as SCOPE-CREEP-01 violation; this file created as the retroactive audit trail
- 2026-05-10: harness-evidence `architecture.md` §D and `docs/retros/2026-05-09-v3-considered-deferred.md` §7 trimmed to a one-line cross-reference to this file

## Sources

- `superpowers/skills/brainstorming/SKILL.md` — current state of the file post-changes
- `docs/retros/2026-05-09-v3-considered-deferred.md` §2 — original vocab-divergence symptom
- `docs/plans/2026-05-09-harness-evidence-channel-design/_index.md` Glossary — the discipline that exposed Change 2's need
