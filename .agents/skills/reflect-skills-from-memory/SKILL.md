---
name: reflect-skills-from-memory
description: This skill should be used when the user asks to "reflect on skills from memory", "audit marketplace skills against memory", "从记忆中检查 skills 的问题", "反思并修改 skill", "apply memory feedback to skills", or wants to turn accumulated memory feedback about this marketplace's skills into concrete skill fixes. Reads the project's persistent memory, re-verifies each known skill problem against current code, then fixes the skill or corrects the stale memory.
version: 0.1.0
---

# Reflect Skills From Memory

Turn accumulated memory feedback about a Claude Code plugin marketplace's skills into
concrete, verified fixes. Memory records hard-won lessons ("L3 rules get skipped",
"git plugin still has no commit hook") but
memory is a point-in-time snapshot — it drifts from the code. This skill closes the loop:
recall the feedback, re-verify it against the live skills, then fix whichever is wrong —
the skill, or the memory.

Run this in a plugin marketplace repo (e.g. `dotclaude`) whose feedback lives in the
per-project memory directory.

## When To Use

Trigger on requests to reflect on / audit / reconcile this marketplace's skills against
remembered feedback, or to apply outstanding memory feedback to skill files.

## Workflow

### Phase 1: Locate and load memory

Resolve the per-project memory directory. Claude Code encodes it by replacing every `/`
in the project path with `-`:

```bash
MEM="$HOME/.claude/projects/$(pwd | sed 's/\//-/g')/memory"
ls "$MEM"/MEMORY.md "$MEM"/*.md
```

Read `MEMORY.md` first (the index), then read every `feedback_*.md` memory — these carry
the actionable problems. Also read `project_*.md` memories that name a specific plugin
(they often record version-pinned fixes and "re-verify after upgrade" cues).

### Phase 2: Extract candidate skill problems

From the feedback memories, build a list of concrete, checkable claims about skills. Each
candidate needs: the claim, the target skill/file it implicates, and how to verify it.
Skip memories that are pure preference (e.g. "reply in Chinese") with no skill artifact.

Recurring problem classes encoded in this project's memory (treat as a standing checklist):
- **L2/L3 enforcement** (`skill-l2-l3-enforcement-pattern`): mandatory rules that live only
  in `references/*.md` or in soft prose (`## Pre-operation Checks`, `Note:`, `warn user`)
  get skipped. They must be a `CRITICAL:` block in the SKILL.md body (L2).
- **Missing enforcement hook** (`git-commit-hook-added`): a plugin.json may lack a needed
  hook. Verify by inspecting the live `hooks` field, not by trusting the remembered version.
- **Stale model / branch / version facts** (`project_gitflow_plugin` and siblings): hardcoded
  model names, branch-landing assumptions, or version numbers drift.

### Phase 3: Re-verify against current code (do not trust memory)

For each candidate, verify against the live files before changing anything. Memory carries a
"may be outdated" warning for a reason, and self-audits in this project have caught the
auditor's own just-written bugs (`feedback_self_audit_caught_my_bugs`,
`verification-requirement-before-reporting`). Concretely:
- Read the actual SKILL.md / plugin.json the memory points at.
- Confirm the problem still exists (grep for the soft prose, inspect the `hooks` key, check
  the model string / version). 
- Classify each candidate as: **STILL-BROKEN** (fix the skill), **ALREADY-FIXED** or
  **WRONG** (fix the memory instead), or **NOT-APPLICABLE** (note and move on).

When the change touches Claude Code's own API surface (hook schemas, frontmatter fields,
tool names), confirm current behavior with the `claude-code-guide` agent before editing
(`use-claude-code-guide-agent`) — do not edit from remembered API shape.

### Phase 4: Fix the skill (STILL-BROKEN)

Apply the minimal change that resolves the verified problem, matching surrounding style:
- Promote a skipped/soft rule into a `CRITICAL:` block in the SKILL.md body; keep the L3
  reference as the detail pointer, not the sole home of the rule.
- Add the missing hook / correct the stale fact.
- When a CRITICAL assertion intentionally duplicates a later phase (e.g. a top-line guard
  plus a detailed Phase 0), note in both that they must change together.

After editing a plugin's skill, bump its version in the plugin's `plugin.json` and sync the
matching entry in `.claude-plugin/marketplace.json` — these must stay equal (verify every
`plugin.json` version against `marketplace.json` before reporting). For README plugin-list
drift after add/remove/rename, defer to the project's `/utils:update-readme`.

### Phase 5: Fix the memory (ALREADY-FIXED / WRONG)

When verification shows the memory is stale or wrong, correct the memory file instead of the
skill: update the version/date/claim, and keep the `MEMORY.md` index line in sync. If a
memory's `name:` slug changes, the filename-based `MEMORY.md` link still resolves, but check
for `[[slug]]` wikilinks that now dangle. Memory files live outside the git repo and need no
commit.

### Phase 6: Validate and report

Validate touched plugins with the project's optimizer (`/plugin-optimizer:optimize-plugin`
or `python3 plugin-optimizer/scripts/validate-plugin.py <plugin-path>`). When the fix is a
hook or other guard script, test BOTH the should-act and should-pass paths before reporting
(`feedback_self_audit_caught_my_bugs`). Then report, per candidate: claim → verdict
(STILL-BROKEN / ALREADY-FIXED / WRONG / NOT-APPLICABLE) → action taken (skill edit with file
path, or memory correction). State what was verified and how.

## Hard Rules

- CRITICAL: Re-verify every remembered claim against the live file before editing. Never edit
  a skill or assert a fix based solely on memory contents.
- CRITICAL: Never run `git add` / `git commit` / `git status` / `git diff` for committing.
  When the user asks to commit the skill fixes, invoke the `/git:commit` skill via the Skill
  tool — it handles staging and message generation.
- Keep changes minimal and in the surrounding style; do not introduce defensive checks,
  extra comments, or abstractions the file does not already use.
