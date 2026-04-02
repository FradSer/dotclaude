# Design Evaluation Rubrics

## Goal

Provide a standardized scoring framework for evaluating design document quality before committing. Apply these rubrics during Phase 4 (Design Reflection) to determine whether documents meet the bar for implementation.

## Evaluation Dimensions

Score every dimension on a 1-5 scale. Record each score and cite the evidence that justifies it.

### 1. Requirements Traceability

Does the design cover all identified requirements?

| Score | Description |
|-------|-------------|
| 5 | Every Phase 1 requirement traced to a specific design section; bidirectional traceability matrix complete |
| 4 | All requirements addressed; minor traceability gaps (requirement mentioned but not in a specific section) |
| 3 | Most requirements addressed; 1-2 requirements only partially covered |
| 2 | Multiple requirements missing or only superficially addressed |
| 1 | Significant requirements gaps; design does not reflect discovered needs |

### 2. BDD Completeness

Do scenarios cover happy path, edge cases, and errors?

| Score | Description |
|-------|-------------|
| 5 | All happy paths, error paths, and edge cases covered; scenarios are specific and testable |
| 4 | Happy paths and main error paths covered; minor edge cases missing |
| 3 | Happy paths covered; some error paths missing or vague |
| 2 | Only happy paths covered; error and edge cases largely absent |
| 1 | BDD scenarios missing or too vague to be testable |

### 3. Document Consistency

Are terminology, references, and component names consistent?

| Score | Description |
|-------|-------------|
| 5 | All terms, references, and component names consistent across all documents; no ambiguity |
| 4 | Consistent with minor variations that do not cause confusion |
| 3 | Generally consistent but 1-2 terminology conflicts between documents |
| 2 | Multiple inconsistencies; same concept called different names in different documents |
| 1 | Pervasive inconsistencies; documents appear to describe different systems |

### 4. Architecture Soundness

Is the proposed architecture viable and maintainable?

| Score | Description |
|-------|-------------|
| 5 | Architecture is clearly viable, well-justified, follows established patterns; separation of concerns correct |
| 4 | Architecture is sound with minor concerns about specific component boundaries |
| 3 | Architecture is workable but has questionable decisions that may cause problems during implementation |
| 2 | Architecture has significant design flaws that will likely require rework |
| 1 | Architecture is fundamentally flawed or contradicts project constraints |

### 5. Risk Coverage

Are key risks identified and mitigated?

| Score | Description |
|-------|-------------|
| 5 | All significant risks identified with concrete mitigation strategies documented |
| 4 | Key risks identified; most have mitigations; minor risks acknowledged |
| 3 | Some risks identified but mitigations are vague or incomplete |
| 2 | Few risks documented; critical risks unaddressed |
| 1 | No risk assessment; design ignores potential failure modes |

## Verdict Rules

Compute the verdict after scoring all five dimensions.

| Verdict | Condition |
|---------|-----------|
| **PASS** | All dimensions >= 3 AND no dimension == 1 |
| **REWORK** | Any dimension < 3 OR any dimension == 1 |

When the verdict is REWORK, list each failing dimension with its score and the specific gaps that must be addressed before re-evaluation.

## Calibration Example

### Scenario: Plugin Notification System Design

A design folder `docs/plans/2026-03-15-plugin-notifications-design/` contains four documents: `_index.md`, `bdd-specs.md`, `architecture.md`, `best-practices.md`. Phase 1 identified six requirements:

1. Send notifications when a plugin update is available
2. Support email and in-app notification channels
3. Allow users to configure notification preferences
4. Rate-limit notifications to prevent spam
5. Log all sent notifications for auditing
6. Handle notification delivery failures gracefully

**Evaluation:**

| Dimension | Score | Evidence |
|-----------|-------|----------|
| Requirements Traceability | 4 | Requirements 1-5 each traced to specific sections in `_index.md` and `architecture.md`. Requirement 6 (delivery failures) mentioned in `best-practices.md` but not linked in the traceability section of `_index.md`. |
| BDD Completeness | 3 | `bdd-specs.md` has 8 scenarios covering happy paths for both channels and preference configuration. Error scenarios exist for invalid preferences and missing email. No scenarios for rate-limit edge cases (burst at boundary) or partial delivery failure (email succeeds, in-app fails). |
| Document Consistency | 5 | Terminology is uniform: "notification channel" used everywhere, component names (`NotificationService`, `PreferenceStore`, `DeliveryQueue`) match across all four documents, cross-references resolve correctly. |
| Architecture Soundness | 4 | Clean separation between preference management, delivery orchestration, and channel adapters. Minor concern: `DeliveryQueue` couples retry logic with rate-limiting in a single component -- these could be separated for testability. |
| Risk Coverage | 2 | Only one risk documented (email provider downtime with fallback to retry queue). No mention of rate-limit bypass risk, preference data migration risk, or notification volume scaling risk. |

**Scores:** 4, 3, 5, 4, 2

**Verdict:** REWORK

**Reason:** Risk Coverage scored 2 (below threshold of 3).

**Required actions before re-evaluation:**

1. Add risk entries for rate-limit bypass, preference data migration, and notification volume scaling
2. Document concrete mitigation strategies for each identified risk in `best-practices.md`
3. Add BDD scenarios for rate-limit boundary conditions and partial delivery failure
4. Link requirement 6 (delivery failures) to a specific design section in the `_index.md` traceability section
