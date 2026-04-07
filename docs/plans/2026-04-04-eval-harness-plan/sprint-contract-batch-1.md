# Batch 1 Sprint Contract

## Tasks

| ID | Subject | Type |
|----|---------|------|
| 001 | Setup docs/retros directory structure | setup |
| 002 | Create initial design checklist | impl |
| 003 | Create initial plan checklist | impl |
| 004 | Create initial code checklist | impl |

## Acceptance Criteria

### Task 001: Setup docs/retros directory structure

- [ ] `docs/retros/checklists/` directory exists
- [ ] No files are created inside the directory (checklists are created in subsequent tasks)
- [ ] Verification command `test -d docs/retros/checklists/ && echo "PASS: checklists directory exists"` exits 0

### Task 002: Create initial design checklist

- [ ] File `docs/retros/checklists/design-v1.md` exists
- [ ] File contains checklist item SCEN-CONC-01 (Given clauses use specific data values)
- [ ] File contains checklist item REQ-TRACE-01 (every requirement ID maps to a scenario)
- [ ] File contains checklist item ARCH-01 (no inner-to-outer layer dependencies)
- [ ] File contains checklist item RISK-02 (each risk mitigation specifies a concrete action)
- [ ] Each item has an ID, description, check method annotation, and evidence format
- [ ] Each item has a `# Type: computational` or `# Type: inferential` annotation
- [ ] SCEN-CONC-01 is annotated `# Type: computational`
- [ ] REQ-TRACE-01, ARCH-01, and RISK-02 are annotated `# Type: inferential`
- [ ] Inferential items include explicit anchors (grep patterns or structural queries) that minimize interpretive freedom
- [ ] File contains no numeric scoring language (no "score", "1-5", "rubric")
- [ ] File includes a header with version, mode (design), and creation date
- [ ] Verification command `grep -c "SCEN-CONC-01" docs/retros/checklists/design-v1.md` exits 0
- [ ] Verification command `grep -c "REQ-TRACE-01" docs/retros/checklists/design-v1.md` exits 0
- [ ] Verification command `grep -c "ARCH-01" docs/retros/checklists/design-v1.md` exits 0
- [ ] Verification command `grep -c "RISK-02" docs/retros/checklists/design-v1.md` exits 0
- [ ] Verification command `! grep -qi "score\|1-5\|rubric" docs/retros/checklists/design-v1.md` exits 0

### Task 003: Create initial plan checklist

- [ ] File `docs/retros/checklists/plan-v1.md` exists
- [ ] File contains checklist item PLAN-COV-01 (every BDD scenario maps to a task)
- [ ] File contains checklist item TASK-COMP-03 (verification commands are executable, not descriptive)
- [ ] File contains checklist item DEP-01 (no circular dependencies)
- [ ] File contains checklist item DEP-02 (all depends-on references resolve to existing task IDs)
- [ ] File contains checklist item TEST-01 (every impl task has a test task or absence justification)
- [ ] Each item has an ID, description, check method annotation, and evidence format
- [ ] Each item has a `# Type: computational` or `# Type: inferential` annotation
- [ ] TASK-COMP-03, DEP-01, DEP-02, and TEST-01 are annotated `# Type: computational`
- [ ] PLAN-COV-01 is annotated `# Type: inferential`
- [ ] Inferential items include explicit anchors that minimize interpretive freedom
- [ ] File contains no numeric scoring language (no "score", "1-5", "rubric")
- [ ] File includes a header with version, mode (plan), and creation date
- [ ] Verification command `grep -c "PLAN-COV-01" docs/retros/checklists/plan-v1.md` exits 0
- [ ] Verification command `grep -c "TASK-COMP-03" docs/retros/checklists/plan-v1.md` exits 0
- [ ] Verification command `grep -c "DEP-01" docs/retros/checklists/plan-v1.md` exits 0
- [ ] Verification command `grep -c "DEP-02" docs/retros/checklists/plan-v1.md` exits 0
- [ ] Verification command `grep -c "TEST-01" docs/retros/checklists/plan-v1.md` exits 0
- [ ] Verification command `! grep -qi "score\|1-5\|rubric" docs/retros/checklists/plan-v1.md` exits 0

### Task 004: Create initial code checklist

- [ ] File `docs/retros/checklists/code-v1.md` exists
- [ ] File contains checklist item CODE-VER-01 (all verification commands exit with code 0)
- [ ] File contains checklist item CODE-QUAL-01 (no TODO, FIXME, HACK, XXX, or stub patterns)
- [ ] File contains checklist item CODE-QUAL-02 (no NotImplementedError, bare pass, or ellipsis implementation)
- [ ] Each item has an ID, description, check method annotation, and evidence format
- [ ] All three items are annotated `# Type: computational`
- [ ] CODE-VER-01 specifies independent command execution (not trusting generator reports)
- [ ] CODE-QUAL-01 specifies concrete grep patterns for prohibited content
- [ ] CODE-QUAL-02 specifies grep patterns for stub implementation patterns
- [ ] File contains no numeric scoring language (no "score", "1-5", "rubric")
- [ ] File includes a header with version, mode (code), and creation date
- [ ] Verification command `grep -c "CODE-VER-01" docs/retros/checklists/code-v1.md` exits 0
- [ ] Verification command `grep -c "CODE-QUAL-01" docs/retros/checklists/code-v1.md` exits 0
- [ ] Verification command `grep -c "CODE-QUAL-02" docs/retros/checklists/code-v1.md` exits 0
- [ ] Verification command `! grep -qi "score\|1-5\|rubric" docs/retros/checklists/code-v1.md` exits 0

## Red-Green Pairs

None. This batch contains one setup task and three impl tasks that produce checklist markdown files. No test+impl pairs share a common NNN prefix.

Tasks not part of a Red-Green pair have no Red state expectation.

## Sign-off

- **Evaluator:** superpowers-evaluator
- **Timestamp:** 2026-04-06T00:00:00Z
- **Status:** APPROVED
