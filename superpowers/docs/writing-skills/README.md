# Writing Skills References

Reference materials for authoring and maintaining Claude Code skills. Not registered as a plugin skill (no `SKILL.md` with frontmatter) — read on demand when authoring skills. Mirrored from upstream `obra/superpowers` v6.1.1 `skills/writing-skills/`.

## Files

- `persuasion-principles.md` — The seven persuasion principles (Cialdini 2021; Meincke et al. 2025) and how they apply to skill design. Use when deciding how to frame discipline-enforcing skill rules so they actually fire under pressure.
- `anthropic-best-practices.md` — Official Anthropic skill authoring guidance: conciseness, degrees of freedom, progressive disclosure, Skill Discovery Optimization, frontmatter spec, testing checklist. The canonical "how to write a SKILL.md" reference.
- `testing-skills-with-subagents.md` — Pressure-scenario methodology: write failing tests (baseline agent behavior without the skill), write the skill, watch it pass, close loopholes. RED-GREEN-REFACTOR applied to documentation.

## Relationship to plugin-optimizer

`plugin-optimizer` ships a `validate-plugin.py` script — the **checker**. These references are the **spec** the checker enforces. Read them when authoring; run the validator when done.
