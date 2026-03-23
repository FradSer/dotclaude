# Exit Criteria - Validation Checklists

## Phase 1: Discovery
- [ ] Explored codebase (relevant files, patterns, docs, recent commits)
- [ ] Requirements clarified via AskUserQuestion (one at a time, prefer multiple choice)
- [ ] Complexity assessment stated (Simple/Medium/Complex)
- [ ] Ready for option analysis with enough context

## Phase 2: Option Analysis
- [ ] 2+ options compared with trade-offs (or "No Alternatives" rationale)
- [ ] Options grounded in codebase reality
- [ ] User explicitly approved direction

## Phase 3: Design Creation
- [ ] Sub-agents completed per complexity level (or main agent for Simple)
- [ ] Results integrated, conflicts resolved
- [ ] Design folder created: `docs/plans/YYYY-MM-DD-<topic>-design/`
- [ ] All required documents: `_index.md`, `bdd-specs.md`, `architecture.md`, `best-practices.md`
- [ ] `_index.md` includes Design Documents section with links

## Phase 4: Design Reflection
- [ ] Reflection completed per complexity level
- [ ] Findings prioritized (High/Medium/Low)
- [ ] Documents updated with gaps filled
- [ ] User approval received

## Phase 5: Git Commit
- [ ] Entire folder committed (not individual files)
- [ ] Message: `docs: <subject under 50 chars>`
- [ ] Co-Authored-By footer included

## Common Pitfalls
- Asking questions without exploring codebase first
- Bundling multiple questions in one call
- Skipping reflection ("it looks fine")
- Missing BDD specifications
- Wrong folder location
- Committing files individually instead of folder
