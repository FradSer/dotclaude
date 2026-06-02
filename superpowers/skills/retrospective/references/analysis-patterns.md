# Analysis Patterns Reference

Detailed analysis logic for the retrospective skill.

## Failure Frequency Analysis

For each checklist item across all input plans:

1. Read all `evaluation-round-*-batch-*.md` files
2. Parse the Checklist Results table for each report
3. Count distinct plans (not batches) where the item has at least one FAIL
4. Sort by frequency descending

Output format:

```markdown
## Failure Frequency

| Item ID | Mode | FAILed in N plans | Plans | Most common evidence |
|---------|------|-------------------|-------|---------------------|
| SCEN-CONC-01 | design | 3 | plan-1, plan-2, plan-3 | vague Given clauses |
| CODE-QUAL-01 | code | 2 | plan-1, plan-3 | TODO comments |
```

## Plateau Task Detection

A plateau task is one that received REWORK across 2+ consecutive evaluation rounds within a single plan, with the same or similar error each time.

Detection process:
1. For each plan, read evaluation rounds sequentially
2. Track per-task verdict history: `[PASS, REWORK, REWORK, PASS]`
3. Identify consecutive REWORK streaks of length >= 2
4. Extract the rework item from each round -- if the same Item ID FAILs, it's a plateau
5. Analyze the root cause: was the failure due to a missing checklist item or an implementation difficulty?

Output format:

```markdown
## Plateau Tasks

| Plan | Task | Consecutive REWORK rounds | Root cause | Checklist gap? |
|------|------|---------------------------|------------|----------------|
| plan-2 | task-004 | 2 (rounds 1-2) | verification command not executable | Yes: TASK-COMP-03 not enforced |
```

## Never-Failing Item Analysis

Items that have never FAILed may not be detecting genuine issues.

Detection process:
1. For each checklist item, count total evaluation reports where it was applied
2. Count total FAILs for that item
3. Items with 0 FAILs and 10+ total reports are candidates for REMOVE

Caveat: Some items are legitimately easy to satisfy (e.g., "file exists"). The user must confirm that the pattern is no longer a real failure mode before removing.

Output format:

```markdown
## Never-Failing Items

| Item ID | Mode | Reports evaluated | FAILs | Candidate action |
|---------|------|-------------------|-------|-----------------|
| PLAN-GRAN-01 | plan | 12 | 0 | REMOVE candidate |
```

## Variety Gap Analysis

Read executing-plans completion summaries for entries matching:
`"Batch {N}: all items PASS after {M} rework rounds"`

These indicate the checklist missed the failure mode that caused rework. Cross-reference with the batch's rework items to identify what was failing.

Output format:

```markdown
## Variety Gaps

| Plan | Batch | Rework rounds | Failure mode not covered |
|------|-------|---------------|------------------------|
| plan-3 | Batch 2 | 3 | Import path resolution errors |
```

## Harness Health Criteria

Evaluate each harness component against recent data:

| Component | Health signal | Recommendation if triggered |
|-----------|--------------|---------------------------|
| Evaluator | All tasks PASS on first round in 3+ consecutive plans | Note the evaluator as a REMOVE/MODIFY candidate for a future Phase 3 proposal (report note only — never auto-disabled) |
| Sprint contracts | No "Recurring Failure Patterns" injection in 5+ batches | Sprint contracts still valuable for acceptance criteria; keep |
| Intra-plan learning | Recurring patterns injected but same items still FAIL | Review injection mechanism -- may need stronger generator guidance |
| Checklist mode X | Only regression items, all passing in 3+ plans | Propose REMOVE for those items via standard checklist evolution |
| Context reset (per-batch coordinator) | Main-agent context stays compact across 10+ batch runs | Confirm load-bearing; no action unless it demonstrably costs more than it saves |

Output as "Harness Health" section with recommendations. Never auto-disable components.

## Cross-Layer Correlation

When a code-mode item (CODE-VER, CODE-QUAL) persistently FAILs, check whether the upstream design or plan checklist covered the related requirement:

- If the design checklist has no item for the requirement → propose ADD to design checklist
- If the plan checklist has the requirement but verification is weak → propose MODIFY to plan checklist
- If both upstream checklists pass but code still fails → the gap is in implementation guidance, not checklists

## Bootstrap Analysis (Phase 0 Full History)

Runs only on cold-start: no completed plans, no evaluation reports, ≥ 50 commits in git history. The goal is to seed v1 checklists with project-specific items drawn from the actual failure patterns the project has already corrected — so the first real evaluation run is not starting from a purely generic rubric.

### 1. Commit Classification

Fetch `git log --oneline --all` and classify each line by conventional-commit prefix:

| Prefixes | Class | Retrospective value |
|----------|-------|--------------------|
| `fix:`, `refactor:`, `style:`, `perf:` | feedback | Strong signal — user correcting prior output |
| `feat:`, `docs:`, `chore:`, `build:`, `ci:`, `test:` | evolution | Noise — new requirements, not failures |
| No recognized prefix | unknown | Skip unless the commit message clearly describes a correction |

Count totals per class. A project with no feedback commits has no extractable failure signal — log `Phase 0: no feedback commits, skipping bootstrap analysis` and seed only the generic template.

### 2. Cluster Feedback Commits by Scope+Type

Parse `type(scope): message` from each feedback commit. Group by `(type, scope)` and count. Rank clusters by frequency descending. Typical top clusters look like:

- `fix(ui):` 32 commits → UI layer correctness gaps
- `fix(i18n):` 15 commits → translation coverage gaps
- `refactor:` (no scope) with large diff → dead code / cleanup debt

Select the top 3–5 clusters for deep analysis. Skip clusters with < 3 commits — too sparse to generalize into a checklist item.

### 3. Diff Mining per Cluster

For each selected cluster, sample 3–5 representative commits via `git show <sha>`. Read the diff looking for the **correction pattern** — what the fix commit *removed or replaced* reveals the original failure mode:

| Diff shape | Likely failure mode | Candidate mode |
|-----------|--------------------|----|
| Removed `console.log` / debug prints | Debug logs shipped to production | code (CODE-DEAD-01 style) |
| Removed unused exports / imports | Dead surface area | code (CODE-DEAD-02) |
| Removed commented-out blocks | Commented-out code persisted | code (CODE-DEAD-03) |
| Added missing i18n keys | Translation gaps after UI changes | code (CODE-I18N-01) |
| Biome/lint auto-fixes applied | Lint violations in produced code | code (CODE-FMT-01) |
| Removed duplicate definitions | Copy-paste across files | code (CODE-DUP-01) |
| Updated line-number references in docs | Stale architectural references | design (ARCH-REF-01) |
| Added BDD scenarios post-implementation | Boundary scenarios missed at design time | design (BDD-COV-01) |
| Removed references to deleted features | Stale docs referencing removed code | design (STALE-01) |
| Split a large task into smaller ones mid-plan | Task scope too large | plan (SCOPE-01) |
| Added cleanup task after feature removal | Feature removal lacked cleanup task | plan (CLEANUP-01) |
| Reordered so tests precede implementation | Test-after-impl ordering | plan (BATCH-ORDER-01) |

### 4. Mode Assignment

Each failure pattern maps to exactly one mode layer:

- **code** — anything detectable by grep/exit-code on produced files (dead code, lint, i18n, duplicates, stubs)
- **design** — anything in `_index.md` / `bdd-specs.md` / `architecture.md` / `best-practices.md` (stale refs, missing scenarios, references to deleted features)
- **plan** — anything in `_index.md` depends-on graph, task files, or batch ordering (scope, cleanup pairing, test-before-impl ordering)

If a pattern doesn't fit cleanly, prefer code over plan over design — code-level checks are the most deterministic.

### 5. Item Generation

For each failure pattern that survived the cluster-frequency filter, produce a checklist item using the `evolution-protocol.md` New Item Template:

```markdown
### {MODE}-{CATEGORY}-{NN} -- {short description}

**Description:** {what this check verifies and why this project needs it}

**Check method:**
```bash
{executable grep / exit-code check, or anchored inferential scan}
```

**Evidence format:** {how to report findings}

**Rework format:** {corrective instruction template}
```

Item ID naming: `{MODE}-{CATEGORY}-{NN}` where CATEGORY is a 3–6 letter slug derived from the failure mode (DEAD, I18N, FMT, DUP, STALE, SCOPE, etc.) and NN is a two-digit sequence scoped to that category within this bootstrap run. Start at 01 per category.

**Check method quality bar**: prefer computational (grep/exit-code). If the pattern requires judgment, write an anchored inferential check — grep narrows candidates, evaluator confirms. Every check must be executable by the superpowers-evaluator agent without project-specific tooling.

### 6. Append to Seeded v1 Files

For each mode that received ≥ 1 item:

1. Read the seeded `{mode}-v1.md`
2. Insert `## Project-Specific Items (Bootstrap Analysis)` immediately before `## Evaluation Protocol`
3. Under the new section, add a one-line preamble: `Items derived from {N} feedback commits across {M} git history commits. Generated {date}.`
4. Append each generated item

Log a summary table in the retrospective report:

```markdown
| Mode | Items added | Top cluster | Example item |
|------|-------------|-------------|--------------|
| code | 6 | fix(ui): 32 commits | CODE-I18N-01 |
| design | 3 | docs/architecture: 8 commits | ARCH-REF-01 |
| plan | 3 | refactor: (large diff) 11 commits | SCOPE-01 |
```

### 7. What Not to Extract

Skip these — they produce false-positive items that clutter the checklist:

- **One-off fixes** — a single commit correcting a typo, not a recurring pattern
- **Refactors that rename/move code** — structural preference, not a failure
- **Dependency bump commits** — chore, not corrective
- **Test-only commits** — evolution class, not feedback
- **Merge commits** — not analyzable for failure patterns

When in doubt about whether a cluster represents a genuine failure mode vs. a stylistic preference, skip it. The next retrospective (after 2+ real evaluation runs) will pick it up from actual evaluator FAILs with stronger evidence than git-history inference.
