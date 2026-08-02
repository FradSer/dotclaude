# Analysis Patterns Reference

Detailed analysis logic for the retrospective skill. Adapted from superpowers' analysis-patterns for the superdev spec/ticket workflow: `design`→`spec`, `plan`→`tickets`, `code` kept.

## Evaluation Data Source

There are no evaluation files on disk. The evaluation signal comes from:

1. **This conversation** — the checklist PASS/FAIL outcomes of the `/superdev:code-review` runs and the self-evaluate steps of `/superdev:to-spec` / `/superdev:to-tickets` that produced the specs/tickets being analyzed.
2. **The produced artifacts themselves** — the spec (Gherkin scenarios), tickets, and code under review, read to verify the claimed outcomes.
3. **Git history** — post-correction commits (Phase 2 step 5) and, on cold start, the bootstrap analysis (below).

Count distinct specs/tickets (not evaluation rounds) when aggregating.

## Failure Frequency Analysis

For each checklist item across all input specs/tickets:

1. Collect the checklist results from the review outcomes (per item: PASS/FAIL with evidence)
2. Count distinct specs/tickets where the item has at least one FAIL
3. Sort by frequency descending

Output format:

```markdown
## Failure Frequency

| Item ID | Mode | FAILed in N specs/tickets | Specs/tickets | Most common evidence |
|---------|------|---------------------------|---------------|----------------------|
| SPEC-CONC-01 | spec | 3 | spec-1, spec-2, spec-3 | vague Given clauses |
| CODE-QUAL-01 | code | 2 | spec-1, spec-3 | TODO comments |
```

## Plateau Ticket Detection

A plateau ticket is one that received REWORK across 2+ consecutive evaluation rounds, with the same or similar error each time.

Detection process:
1. For each spec/ticket, list the review rounds in order
2. Track per-ticket verdict history: `[PASS, REWORK, REWORK, PASS]`
3. Identify consecutive REWORK streaks of length >= 2
4. Extract the rework item from each round -- if the same Item ID FAILs, it's a plateau
5. Analyze the root cause: was the failure due to a missing checklist item or an implementation difficulty?

Output format:

```markdown
## Plateau Tickets

| Spec/ticket | Ticket | Consecutive REWORK rounds | Root cause | Checklist gap? |
|-------------|--------|---------------------------|------------|----------------|
| spec-2 | T-004 | 2 (rounds 1-2) | verification command not executable | Yes: TICKETS-COMP-03 not enforced |
```

## Never-Failing Item Analysis

Items that have never FAILed may not be detecting genuine issues.

Detection process:
1. For each checklist item, count total evaluation reports where it was applied
2. Count total FAILs for that item
3. Items with 0 FAILs and 3+ total reports are candidates for REMOVE (the 3+ threshold matches the evolution-protocol REMOVE threshold — see its history section for why it was lowered from 10+)

Caveat: Some items are legitimately easy to satisfy (e.g., "file exists"). Check whether the pattern is still a real failure mode before removing — the checklist should shrink only when an item is dead weight, not when it is simply cheap to satisfy.

Output format:

```markdown
## Never-Failing Items

| Item ID | Mode | Reports evaluated | FAILs | Candidate action |
|---------|------|-------------------|-------|-------------------|
| TICKETS-GRAN-01 | tickets | 5 | 0 | REMOVE candidate |
```

## Variety Gap Analysis

Specs/tickets where all items PASS but 2+ rework rounds occurred. These indicate the checklist missed the failure mode that caused rework. Cross-reference with the rework items to identify what was failing.

Output format:

```markdown
## Variety Gaps

| Spec/ticket | Round | Rework rounds | Failure mode not covered |
|-------------|-------|----------------|---------------------------|
| spec-3 | 2 | 3 | Import path resolution errors |
```

## Post-Correction Mining (advisory)

Scan git history for commits on spec/ticket-related files that arrived *after* the review verdict:

- `fix:`, `refactor:`, `style:`, `perf:` prefixes touching files the spec/ticket covers
- Each such commit is the user correcting superdev output the checklist did not catch
- Render a corrections table and graduate each missed pattern to a Phase 3 ADD proposal at 1-spec/ticket evidence

This catches what grep-based checks cannot: consistency, API-contract, and coverage gaps.

## Cross-Layer Correlation

When a code-mode item (CODE-VER, CODE-QUAL) persistently FAILs, check whether the upstream spec or tickets checklist covered the related requirement:

- If the spec checklist has no item for the requirement → propose ADD to spec checklist
- If the tickets checklist has the requirement but verification is weak → propose MODIFY to tickets checklist
- If both upstream checklists pass but code still fails → the gap is in implementation guidance, not checklists

## Bootstrap Analysis (Phase 0 Full History)

Runs only on cold-start: no completed specs/tickets, no evaluation signal, ≥ 50 commits in git history. The goal is to seed checklists with project-specific items drawn from the actual failure patterns the project has already corrected — so the first real evaluation run is not starting from a purely generic rubric.

### 1. Commit Classification

Fetch `git log --oneline --all` and classify each line by conventional-commit prefix:

| Prefixes | Class | Retrospective value |
|----------|-------|--------------------|
| `fix:`, `refactor:`, `style:`, `perf:` | feedback | Strong signal — user correcting prior output |
| `feat:`, `docs:`, `chore:`, `build:`, `ci:`, `test:` | evolution | Noise — new requirements, not failures |
| No recognized prefix | unknown | Skip unless the commit message clearly describes a correction |

Count totals per class. A project with no feedback commits has no extractable failure signal — log `Phase 0: no feedback commits, skipping bootstrap analysis` and seed only the generic template.

### 2. Cluster Feedback Commits by Scope+Type

Parse `type(scope): message` from each feedback commit. Group by `(type, scope)` and count. Rank clusters by frequency descending.

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
| Updated line-number references in docs | Stale architectural references | spec (ARCH-REF-01) |
| Added Gherkin scenarios post-implementation | Boundary scenarios missed at spec time | spec (BDD-COV-01) |
| Removed references to deleted features | Stale docs referencing removed code | spec (STALE-01) |
| Split a large ticket into smaller ones mid-implementation | Ticket scope too large | tickets (SCOPE-01) |
| Added cleanup ticket after feature removal | Feature removal lacked cleanup ticket | tickets (CLEANUP-01) |
| Reordered so tests precede implementation | Test-after-impl ordering | tickets (BATCH-ORDER-01) |

### 4. Mode Assignment

Each failure pattern maps to exactly one mode layer:

- **code** — anything detectable by grep/exit-code on produced files (dead code, lint, i18n, duplicates, stubs)
- **spec** — anything in the spec or its Gherkin scenarios (stale refs, missing scenarios, references to deleted features)
- **tickets** — anything in the tickets' dependency edges, ordering, or pairing (scope, cleanup pairing, test-before-impl ordering)

If a pattern doesn't fit cleanly, prefer code over tickets over spec — code-level checks are the most deterministic.

### 5. Item Generation

For each failure pattern that survived the cluster-frequency filter, produce a checklist item using the `evolution-protocol.md` New Item Template.

Item ID naming: `{MODE}-{CATEGORY}-{NN}` where CATEGORY is a 3–6 letter slug derived from the failure mode (DEAD, I18N, FMT, DUP, STALE, SCOPE, etc.) and NN is a two-digit sequence scoped to that category within this bootstrap run. Start at 01 per category.

**Check method quality bar**: prefer computational (grep/exit-code). If the pattern requires judgment, write an anchored inferential check — grep narrows candidates, the `/superdev:code-review` refutation protocol confirms. Every check must be executable by `/superdev:code-review` step 5.5 without project-specific tooling.

### 6. Append to Seeded Checklists

For each mode that received ≥ 1 item:

1. Read the seeded `checklist-{mode}.md`
2. Insert `## Project-Specific Items (Bootstrap Analysis)` immediately before `## Evaluation Protocol`
3. Under the new section, add a one-line preamble: `Items derived from {N} feedback commits across {M} git history commits. Generated {date}.`
4. Append each generated item

### 7. What Not to Extract

Skip these — they produce false-positive items that clutter the checklist:

- **One-off fixes** — a single commit correcting a typo, not a recurring pattern
- **Refactors that rename/move code** — structural preference, not a failure
- **Dependency bump commits** — chore, not corrective
- **Test-only commits** — evolution class, not feedback
- **Merge commits** — not analyzable for failure patterns

When in doubt about whether a cluster represents a genuine failure mode vs. a stylistic preference, skip it.
