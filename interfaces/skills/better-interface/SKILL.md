---
name: better-interface
description: "User-invoked, cross-discipline interface review that coordinates six domain references: accessibility, layout, writing, typography, colors, and ui. Use when explicitly invoked for a holistic review of a screen, flow, feature, or product interface. Supports quick and full review modes. Triggers on better-interface, full interface review, holistic UI audit, cross-discipline design review, review the whole interface."
---

# Review the interface as one system

A strong interface is not six independent audits stapled together. Review the whole experience, let each domain reference own its rules, then consolidate the evidence into one prioritized verdict.

This skill owns orchestration only. Accessibility rules belong to `references/accessibility/overview.md`; structure to `references/layout/overview.md`; copy to `references/writing/overview.md`; type to `references/typography/overview.md`; color to `references/colors/overview.md`; visual polish and motion to `references/ui/overview.md`. Never duplicate or override their rules here.

## Core Principles

### 1. Resolve Scope and Mode First

Infer the screen, flow, feature, or repository scope from the request and current workspace. State the resolved scope in the output. Use `full` when no mode is supplied.

| Mode | Coverage | Finding cap |
| --- | --- | --- |
| `quick` | Primary user path and highest-traffic states; report only `HIGH` and `MEDIUM` issues | 5 |
| `full` | Entire requested scope across all six domain references, including empty, loading, error, and narrow-width states when present | 15 |

If the requested scope is too large to inspect credibly, narrow it to the highest-traffic complete flow and state the boundary. Never imply uninspected surfaces were reviewed.

### 2. Recon Before Judgment

Identify the framework, styling system, component library, design tokens, supported viewports, and available preview or test commands. Follow the project's established Tailwind, plain CSS, CSS-in-JS, token, and component conventions.

### 3. Use Domain References as the Sources of Truth

Before reviewing, read all six domain references below. Load and apply every available reference. In `quick` mode, inspect all six domains but spend depth only where the primary flow has evidence. In `full` mode, complete each available domain review before consolidation.

Review in this order so foundational failures are not hidden by polish:

1. `references/accessibility/overview.md`
2. `references/layout/overview.md`
3. `references/writing/overview.md`
4. `references/typography/overview.md`
5. `references/colors/overview.md`
6. `references/ui/overview.md`

This skill owns the final response. Apply each domain reference's principles and topic files, then consolidate into the format, shared severity, and finding cap defined in this file.

If a domain reference is unavailable, mark that domain `Not reviewed`, name the missing reference, and continue with the remaining domains. Do not recreate its rules from memory, substitute a neighboring domain, or claim holistic coverage.

When two references appear to cover the same issue, assign it to the reference that owns the underlying rule and mention secondary effects in the **Why** cell. Report it once.

### 4. Require Evidence

Every finding cites `path/to/file:line` and shows the current implementation. If the review artifact has no source files, cite the exact screen and component. Do not report a code-level finding from visual appearance alone or a visual finding from source code alone when runtime behavior determines the result.

### 5. Rank by User Impact

Use one shared severity scale:

- `HIGH`: blocks a task, misleads the user, hides content or controls, causes data-loss risk, or creates a repeated systemic failure.
- `MEDIUM`: meaningfully harms comprehension, efficiency, adaptability, or consistency.
- `LOW`: isolated polish with limited task impact. Include only in `full` mode.

Within a severity, rank by reach and leverage. A token or shared-component fix outranks the same symptom in one leaf component.

### 6. Consolidate Systemic Findings

One root cause is one finding. List every confirmed location in the same row rather than producing a row per occurrence. Do not pad the report to reach the finding cap; a short review or no findings is a valid result.

### 7. Make Restraint Visible

Record candidates considered but deliberately rejected. A candidate is rejected when the owning reference permits the current implementation, evidence is insufficient, the project convention is intentional, or the proposed change would add complexity without user benefit.

### 8. Verify What Can Be Verified

Run safe, relevant checks available in the project. Inspect the rendered interface when runtime behavior or visual judgment matters. Report the exact command or interaction and observed result. If a check cannot be run, label it **Not verified** and state what remains; never convert a verification gap into a finding.

### 9. Review Without Mutating by Default

Treat a review request as read-only. Do not edit source code unless the user also asks to implement the findings. When implementation is requested, preserve the consolidated report as the change scope and re-run the relevant verification afterward.

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| Six disconnected domain reports | Consolidate into one ranked findings table |
| Same issue reported by multiple references | Assign it to the reference that owns the underlying rule |
| Finding with no exact location | Cite `path/to/file:line` and the current implementation |
| Visual claim inferred only from source | Inspect the rendered state or mark it not verified |
| Unlimited low-impact polish | Respect the mode cap; omit `LOW` findings in `quick` |
| Silent gaps in coverage | Show which domains and states were actually inspected |
| Missing owning reference silently treated as covered | Mark the domain `Not reviewed` and name the unavailable reference |
| No rejected candidates | Include the required considered-but-rejected table |
| Review silently edits code | Stay read-only unless implementation was requested |
| “Approve” with pending actionable findings | Use `Needs changes` or `Block` |

## Review Output Format

Always use the following sections.

### Scope and Coverage

State the mode, exact scope, stack and styling conventions, and any review boundary. Then show coverage:

| Domain | Evidence inspected | Result |
| --- | --- | --- |
| Accessibility | Files, components, states, or checks | Findings count or `Clear` |

Include all six domains. `Clear` means inspected with no actionable finding; `Not reviewed` must explain why.

### Findings

Use one table ordered by severity, then reach and leverage:

| # | Severity | Domain | Location | Before | After | Why |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | HIGH | Accessibility | `src/Dialog.tsx:42` | `<button><XIcon /></button>` | Add `aria-label="Close"` and hide the icon from the accessibility tree | The icon-only control has no accessible name |

Each row is one root cause. The **Domain** value is the owning domain (accessibility, layout, writing, typography, colors, or ui). Respect the mode's finding cap. If there are no findings, omit the table and state "No actionable interface findings."

### Considered but Rejected

Include 1–3 candidates in `quick` mode and 2–5 in `full` mode:

| Location | Candidate | Rejected because |
| --- | --- | --- |
| `src/Card.tsx:28` | Increase the shadow | Existing depth matches the shared surface token; changing one card would reduce consistency |

These are real candidates inspected during the review, not invented filler. If the scope genuinely contains fewer borderline candidates, include the ones that exist and say so.

### Verification

List each check or interaction, the exact command or steps, and the observed result. Separate checks that passed from checks marked **Not verified**.

### Verdict

End with exactly one:

- `Block` — one or more `HIGH` findings remain.
- `Needs changes` — only `MEDIUM` or `LOW` findings remain.
- `Approve` — no actionable findings remain and the claimed coverage was verified.
