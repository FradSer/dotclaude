# Meta-Retrospective — superpowers v2.8.x — 2026-05-08

**Type**: Meta-level retrospective on a single-session implementation arc, not a per-plan retrospective. Emitted out-of-band from the standard `superpowers:retrospective` flow because the subject under review *is* `superpowers` itself.

**Scope**: 2 commits ahead of `origin/develop` (range `4ddf04a..HEAD` at write time):

- `4a902f8 feat(sp): add bail-log and plan completion logging` — v2.8.0
- `0903c91 feat(sp): add post-plan diff and plan logging` — v2.8.1 + v2.8.2 + simplify

**Diff size**: ~1,479 net inserted lines across 19 files.

**Empirical sample base for the entire arc**: N = 1 project (`/Users/FradSer/Developer/RayNeo/user-simulation/`), 1 retrospective, 1 disable test (`recurring_failure_patterns`), 5 post-plan refactor commits.

**Status**: this document is a **design-stage candidate for v2.9.0 — DO NOT IMPLEMENT**. It records an independent ultrathink agent's judgment plus the maintainer's calibration, to be revisited when ≥3 real projects have produced post-v2.8.x retrospective data.

---

## 1. The actual delta of the arc

| Change category | Approx lines | Real bug fix? |
|---|---|---|
| Hook-write `plan_completed` (was Claude-instructed, silently dropped) | ~30 | **Yes** — empirical: pre-v2.8.0 user-simulation never wrote the file despite SKILL.md instruction |
| `dedup` gate (slash-normalized, plan-level key) | ~10 | **Yes** — empirical: user-simulation logged the same plan twice in 7.5h |
| Repo-relative `plan` field + `repo_root` audit field + single `git rev-parse` fork | ~20 | **Yes** — pre-v2.8.2 wrote absolute paths (cross-worktree / cross-clone unstable) |
| Documentation contradiction fixes (systematic-debugging L15 ↔ L269; retrospective Superpower Loop schema; writing-plans AND→OR) | ~60 | **Yes** — discovered by 5-agent simulation review |
| `lib/bail-log.sh` + 4-skill integration | ~120 | **Infrastructure**, not a fix — closes the `--force` override blind spot in calibration loop |
| `lib/post-plan-diff.sh` + `references/post-plan-diff.md` + tests + Pre-Check A + Phase 5b veto gate + Phase 5a 1-plan ADD override + `component_reinstated` event schema | **~700** | **New mechanism**, not a fix — predicated on N=1 over-correction (see §4 R1) |
| `self_value` + LOW-YIELD pre-check + dual-branch RETROSPECTIVE-DUE/LOW-YIELD reminder | ~80 | **New mechanism**, not a fix |
| Tests + `conftest.py` extraction + `simplify` round (9 fixes) | ~600 | **Test scaffolding** — much of this is post-hoc cleanup of v2.8.0 over-elaboration |

**Truth**: real bug fixes ≈ 80 lines. The remaining ~1,400 lines are mechanism additions, predicated on a sample of 1.

---

## 2. Independent ultrathink agent verdict (condensed)

The agent ran in isolated context, read the full diff + real user-simulation data + key SKILL.md / reference files, and rendered:

> "Direction is partially wrong, not entirely. The real fix was a v2.7.0 bug (Phase 6 step 2 manual jsonl write being silently dropped by Claude), closable in ~25 lines of Stop-hook write. **Actual cumulative addition was ~1,479 lines, 6 jsonl/config file types, 3 Pre-Checks, 1 veto gate, 1 new event schema — based on N=1 of one disable decision turning out wrong. Largest risk: the v2.8.1 work upgraded 'one user retrospective decision was wrong' into 'systemic bias' — exactly the over-fitting it claims to prevent.**"

### Agent's recommended retracts (R1–R4)

| ID | Mechanism to retract | File anchors | Agent's core argument |
|---|---|---|---|
| **R1** | Phase 5b post-plan-diff **veto gate** (auto-blocks 5b candidates when ≥2 feedback commits map to scope) | `superpowers/skills/retrospective/SKILL.md:122-136`; `references/post-plan-diff.md:109-141` | Phase 4 `AskUserQuestion` is already the human approval layer; veto suppresses candidates the user would otherwise see, *reducing* their judgment input surface. Conventional-commit assumption is unverified. Manual scope-match table is ritual. |
| **R2** | **Pre-Check A INSUFFICIENT-POST-PLAN** gate (`<24h` + zero post-plan commits → AskUserQuestion 3-way wait/run/greenfield) | `superpowers/skills/retrospective/SKILL.md:15-20`; `references/post-plan-diff.md:22-60` | Trigger window covers only greenfield; early retros should tolerate weak evidence (their value is establishing baseline, not producing ADD/REMOVE). LOW-YIELD pre-check already covers "should we run". |
| **R3** | `task_count` / `batch_count` extraction in `_loop_log_plan_completion_if_executing` hot path | `superpowers/lib/loop.sh:97-105` | 0 downstream consumers (grepped full repo); YAGNI. |
| **R4** | LOW-YIELD pre-check **AskUserQuestion 3-way prompt** (`Run anyway / Skip / Show prior`) | `superpowers/skills/retrospective/SKILL.md:21-33` | Violates user memory `feedback_skill_no_user_asks` (skill must not ask for flow choices mid-execution). |

### Agent's keep list (K1–K5) — uncontested

| ID | Mechanism | Why kept |
|---|---|---|
| K1 | Hook-driven `plan_completed` write (minus R3 fields) | Real v2.7.0 bug fix, empirically demonstrated |
| K2 | `dedup` gate (`tail`-bounded `grep -qF`, plan-only key) | Real bug, empirical evidence in user-simulation |
| K3 | Repo-relative path + single `git rev-parse` fork | Cross-worktree / cross-clone correctness |
| K4 | `lib/bail-log.sh` infrastructure | 68 lines, no schema sprawl, append-only — fills the only `--force` blind spot the user can't see otherwise |
| K5 | `component_reinstated (manual_correction)` event schema | User-driven audit slot for reversing a prior weak-evidence decision |

### Agent's open questions (U1–U3)

- **U1**: post-plan-diff data collection itself (Phase 1 step 8 + Phase 5a info table). Lean retract under N=1 + same-author-as-refactorer scenario, but needs N≥3 data to confirm.
- **U2**: Conventional-commit type bucket assignments (`perf` → feedback, `revert` → evolution) are guesses with zero data backing.
- **U3**: Dual-branch `RETROSPECTIVE DUE` / `LOW-YIELD` reminder is currently dead code (requires ≥2 zero-change retros to differentiate).

---

## 3. Maintainer calibration of the agent verdict

| Verdict | Maintainer position | Note |
|---|---|---|
| R1 retract veto | **Strong agree** | Initial framing ("v2.7.0 disable decision needs a safety net") missed that the safety net is the human in Phase 4. Agent's "cybernetic loop failure" critique is correct. |
| R2 retract Pre-Check A | **Agree** | Replace with single line in Phase 6 report: `post-plan window: {N}h, {total} commits — weak evidence`. No gate, no prompt. |
| R3 retract task_count/batch_count | **Agree, full removal** | Field + extraction both go. Retrospective derives from plan dir on demand if needed. |
| R4 retract LOW-YIELD prompt | **Agree** | Reminder text only; user reads and decides whether to abort manually. |
| K1–K5 keep | **Full agree** | All five stand. K4 SKILL integration verbosity is a v2.9.0 simplify candidate (see §6). |
| U1 (info table) | **Disagree with retract; lean keep as info** | Without it, ~700 lines of v2.8.1 mechanism collapse to nothing. N=1 is not enough to retract the whole channel — only enough to retract the auto-veto layer above it. |
| U2 / U3 | **Defer** | Validate against real corpus when available. |

### What the agent caught that the maintainer missed

The most cutting argument was about Phase 4 already covering audit:

> Auto-veto suppresses 5b candidates from the user. The user no longer sees the candidate. Phase 4's "one-by-one approval" then never gets a chance to reject — because the rejection was machine-made, invisibly.

This is the maintainer's blind spot: implementing a "safety layer" that *removes* user input surface rather than augments it. The maintainer's earlier ultrathink rounds (which retracted the "ROI 25-30%" pseudo-quantification and the "P0 state_update rc bug" misdiagnosis) were *self-corrections within implementation perspective*. The veto critique requires *exiting* implementation perspective entirely — which only an external agent could provide cheaply.

---

## 4. The deeper meta-lesson — LLM **add bias**

The arc shape is the symptom, not the disease:

```
v2.8.0  add bail-log + self_value (with verbose version-tag comments and per-line jq)
v2.8.1  add post-plan-diff (with per-line jq fork, with blank EOF read bug)
v2.8.2  add dedup + repo-relative (which surfaced 4 v2.8.0/8.1 issues)
simplify  9 fixes — most retroactively cleaning v2.8.0/8.1's verbosity
ultrathink-agent  another ~250 retract candidates spanning SKILL.md design
```

Each round is a patch on the previous. **The pattern is not bad pacing — it's structural LLM bias toward visible-add over invisible-skip.** Implementation-mode LLM defaults to "I can add X to make Y better" because adding produces tangible output; skipping produces nothing to show.

`simplify` caught code-layer add-bias (verbose comments, duplicated jq, redundant existence checks). The current ultrathink agent caught **mechanism-layer** add-bias (whole gates and pre-checks that shouldn't exist). These are two different review depths and *both are needed periodically*.

This argues for a `superpowers` design pattern not currently in the plugin:

> **Periodic "external mechanism review"** — every N major changes, an isolated agent reviews not just code quality but *whether the mechanism should exist at all*, with explicit license to recommend retract.

This is adjacent to but distinct from `meta-retrospective` (proposed earlier in this session). meta-retrospective reviews superpowers-as-a-tool over time; mechanism-review checks individual additions for over-engineering at write time. Both should exist; neither does today.

**Maintenance hypothesis** (to validate against future arcs): without a built-in mechanism-review hook, every multi-round implementation arc inside `superpowers` will produce ~20–30 % over-engineered mechanisms that need retro-active retract. The v2.8.x arc adds ~1,400 mechanism lines; the agent's R1+R2+R3+R4 retract is ~240 lines = ~17 % of that. If the hypothesis holds, future arcs will need similar retract phases.

---

## 5. v2.9.0 retract patch — design only, not implementation

When (and only when) one of the trigger conditions in §6 is met, execute:

### Patch v2.9.0-A — Retract veto + Pre-Check A

```
- Delete superpowers/skills/retrospective/SKILL.md:15-33  (Pre-Check A entire section)
- Delete superpowers/skills/retrospective/SKILL.md:122-136  (Phase 5b veto gate paragraph)
- Delete superpowers/skills/retrospective/references/post-plan-diff.md:22-60  (§Pre-Check A)
- Delete superpowers/skills/retrospective/references/post-plan-diff.md:109-141  (§Phase 5b)
- Modify superpowers/skills/retrospective/references/evolution-protocol.md:
    - Remove `post_plan_diff.vetoed_disables` field from retrospective_run schema
    - Mark `component_reinstated.reinstatement_method = "post_plan_diff_veto"` as DEPRECATED
      (manual_correction stays — agent K5)
- Add to superpowers/skills/retrospective/SKILL.md Phase 6 step:
    "If post_plan_diff data collected, append one line to report:
       'post-plan window: {N}h, {feedback}/{total} feedback commits — {evidence_label}'
     where evidence_label = 'weak' if N<24h or total<2, else 'sufficient'."
```

### Patch v2.9.0-B — Retract LOW-YIELD prompt

```
- Modify superpowers/skills/retrospective/SKILL.md:21-33:
    Replace "Then call AskUserQuestion ... 3-way" with single-line reminder text.
    Change downstream `consecutive_zero_change >= 2` handling to be
    informational only.
```

### Patch v2.9.0-C — Retract task_count/batch_count

```
- Modify superpowers/lib/loop.sh:97-105: delete the index_file grep + glob loop
- Modify superpowers/lib/loop.sh:122-130: drop $tc and $bc from final jq
- Modify superpowers/skills/retrospective/references/evolution-protocol.md:
    Plan Completion Log Schema: remove task_count + batch_count fields
- Modify superpowers/tests/test_phase_integration.py:
    test_plan_completion_log_includes_task_and_batch_counts → delete or invert
    test_plan_completion_log_zero_counts_when_files_missing → simplify (remove
      tc/bc assertions, keep the rest)
```

### Patch v2.9.0-D — Compress bail-log SKILL.md integration verbosity (maintainer addition, agent did not flag)

```
- Modify superpowers/skills/{brainstorming,writing-plans,executing-plans,systematic-debugging}/SKILL.md:
    Replace each per-skill ~10-line "Calibration log" block with single line:
      "On bail-out or --force, run `bash ${CLAUDE_PLUGIN_ROOT}/lib/bail-log.sh
      <skill> <event> '<reason>' \"$ARGUMENTS\"`."
    Remove repeated explanations of when each event fires (the helper docstring is
    the source of truth).
```

**Estimated net delta**: -240 to -260 lines.

---

## 6. Triggers for executing v2.9.0

The retract is **suspended** until one of these conditions holds:

| Trigger | Threshold | Source of truth |
|---|---|---|
| **T1: Real-data invalidation** | After ≥3 distinct projects have run a v2.8.x retrospective and Phase 5b veto has triggered ≤1 time across them | `evolution-log.jsonl` `retrospective_run.post_plan_diff.vetoed_disables` field counts across projects |
| **T2: User friction signal** | A user files an issue / sends feedback that one of {Pre-Check A, LOW-YIELD prompt, Phase 5b veto} interrupted a legitimate workflow | external — observation by maintainer |
| **T3: Calendar timeout** | 90 days from `0903c91` (i.e., 2026-08-06) without either T1 or T2 having occurred — execute v2.9.0 anyway, since "no signal in 90 days across all uses" is itself sufficient evidence the mechanism is over-engineered | calendar |
| **T4: Maintainer observation** | Direct experience using v2.8.x on a project where the veto / Pre-Check A clearly did or did not earn its weight | external |

**Bias warning**: do not execute v2.9.0 inside the same conversational arc that produced v2.8.x. That would be the 5th round in a single session — the exact pacing failure this document identifies. New session, new context, new project as the trigger.

---

## 7. What this document deliberately does **not** decide

- **U1 (post-plan-diff info table)**: agent leans retract, maintainer leans keep. Defer to T1 data.
- **U2 (commit-type assignments)**: defer until ≥1,000 real commits classified, accuracy measurable.
- **U3 (dual-branch reminder)**: dead code by design until N≥2 zero-change retros happen. Leave.
- Whether to add a `superpowers` mechanism-review hook (§4): a v3.0-scope question. Out of scope here.

---

## 8. Audit trail

- Verdict source: independent ultrathink agent, isolated context, read-only
- Maintainer calibration: post-agent ultrathink, executed by main session
- Decision: option **C** ("write to docs, do not implement, await trigger")
- Counter-options considered:
  - A: implement v2.9.0 immediately — rejected as 5th-round pacing failure
  - B: commit + dogfood 1–2 weeks — rejected because dogfood = T1 trigger; this is identical to C's T1 mechanism
- Co-author: Claude Opus 4.7 (mechanism implementation + ultrathink calibration); independent agent (verdict)

End of meta-retrospective.
