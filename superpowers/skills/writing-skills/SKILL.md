---
name: writing-skills
description: Turns one-off discoveries from completed work into reusable skills or skill extensions. This skill should be used when the user has just learned something general that should outlive this conversation, has had to give the same advice more than once, or invokes "/superpowers:writing-skills" to capture a pattern. Produces a SKILL.md draft (or a patch to an existing skill) and surfaces it via AskUserQuestion for approval before any file write.
argument-hint: [topic-or-symptom]
user-invocable: true
allowed-tools: ["Read", "Write", "Edit", "Glob", "Grep"]
---

# Writing Skills

Capture what just generalized. After a task completes — or after the user has had to give the same correction twice — turn the pattern into a reusable skill or extend an existing one. This is the compounding mechanism: each discovery becomes load-bearing for future work instead of decaying with the session transcript.

## When this skill is the right tool

Invoke (or be invoked) when ANY of these match:

- The user just said something that begins with "we should remember that…", "from now on…", "always do X…", "next time…"
- You have had to give the same advice or correction more than once across this session
- A debug session surfaced a non-obvious root cause that would help future debugging of the same class
- A successful brainstorm / plan execution surfaced a pattern (gotcha, idiom, tool combination, prompt shape) that you would want to apply automatically next time
- The user explicitly invokes `/superpowers:writing-skills "<topic>"`

Do NOT invoke when:

- The pattern is fully captured by an existing CLAUDE.md or skill — adding a duplicate skill is library noise
- The pattern is one-shot project-specific (e.g., "in THIS codebase X means Y") — that belongs in CLAUDE.md, not a portable skill
- The user has already declined to extract a skill from this pattern in the current session

## Phase 1: Identify the generalization

**Read the conversation context** (this is the working transcript — you do not need to invoke Read on a file; the context is what you just experienced):

1. Name the **concrete trigger**: the specific moment in the conversation where the pattern fired. Quote it briefly.
2. Name the **generalized pattern**: what would be true across other instances of this trigger? Strip the project-specific details.
3. Name the **applicable scope**: which kinds of tasks should load this knowledge? Be specific — "all Python code" is too broad; "test fixtures that create a real git repo" is right.

If you cannot complete steps 1-3 with concrete content, the pattern is not yet ready to skill-ify — surface that to the user and stop.

## Phase 2: Decide: new skill, extend existing, or CLAUDE.md

Glob `superpowers/skills/*/SKILL.md` and any `<plugin>/skills/*/SKILL.md` paths the user mentions. For each, read the frontmatter `description` to check whether the new pattern overlaps.

Decision rules:

- **Existing skill covers the same trigger** — extend that skill's body or its `references/` directory. Output a patch (Edit operation preview), not a new skill.
- **Existing skill covers an adjacent trigger but the pattern is meaningfully different** — add a new skill in the same plugin if the plugin's identity allows it; otherwise propose a standalone plugin skill.
- **No existing skill is close** — draft a new skill.
- **The pattern is repo-specific, not portable** — propose a CLAUDE.md addition instead and exit (skills should be portable; project-specifics belong in the project's CLAUDE.md per repo's convention).

## Phase 3: Draft the skill

If a new skill is the right answer, write the SKILL.md draft as a STRING in your response — do NOT write it to disk yet. The structure:

```yaml
---
name: <kebab-case-slug>
description: <CSO-optimized: who/what/when, one sentence, third person. The first 100 chars are the trigger surface — pack the strongest "when" signals there.>
user-invocable: <true | false>  # false for internal-only skills loaded by other skills
allowed-tools: [<minimum tools the skill body actually invokes>]
---

# <Skill Title>

<2-4 sentence intro: what the skill does, when it fires, what discipline it adds.>

## <Phase or section headings>

<Imperative-voice body. Under ~500 words. Anything longer goes in `references/`.>

## References

- `./references/<topic>.md` — <one-line summary>
```

**Writing rules** (from `plugin-optimizer/skills/plugin-best-practices/`):

- **Imperative voice**: "Parse the file" not "You should parse the file".
- **Description optimized for CSO (Claude Skill Optimization)**: third-person, leads with the strongest trigger phrase. Examples: "This skill should be used when…", "Use whenever…". The first ~100 characters determine whether Claude reaches for it; do not bury the trigger.
- **Body length**: under ~2000 words. If the natural body is longer, split detailed content into `references/<topic>.md` files and reference them by relative path from SKILL.md.
- **Tool invocation language**: describe file ops directly ("Read the manifest"), describe Bash directly ("Run `git diff`"), but invoke other skills explicitly via the Skill tool ("Load `<plugin>:<skill>` using the Skill tool").

## Phase 4: Surface for approval

Use the AskUserQuestion tool to present the draft for approval before any file is written. Two questions, in order:

1. **Approve scope** — show the user the proposed `name`, `description`, and trigger conditions. Ask: "Capture this as a skill?" Options: "Yes, write it", "Yes, but adjust the trigger" (collect adjustment in `notes`), "No, keep as conversation only".

2. **Approve destination** (only if Q1 was "yes") — show the chosen plugin / directory. Ask: "Write to this location?" Options: "Yes", "Different location" (collect new path in `notes`).

PROHIBITED: do NOT write the SKILL.md to disk before Q1 is approved. Drafting it as a string is fine; persisting it to a file before approval is over-reach.

## Phase 5: Write or hand back

On approval, Write the SKILL.md to the chosen path. If extending an existing skill, use Edit to patch the existing file instead. Then:

1. Verify the new file parses (no broken frontmatter — `python3 -c "import yaml; yaml.safe_load(open('<path>').read().split('---')[1])"` or equivalent).
2. If the plugin has a `plugin.json`, suggest the user run `/utils:update-readme` to keep top-level READMEs in sync — but do NOT modify plugin.json yourself unless explicitly authorized.
3. Output a one-line summary: "Captured `<plugin>:<name>` at <path>. Next time `<trigger phrase>`, this skill fires automatically."

On rejection, output: "Skipped. Captured the pattern as conversation context only — it will not persist past this session."

## Why this exists (the compounding mechanism)

A skill library that doesn't grow from real work decays. Without an explicit capture step, every session's discoveries die with the transcript: the same advice gets re-derived, the same gotcha gets re-hit, the same prompt shape gets re-invented. `writing-skills` is the keystone that turns ephemeral learning into durable structure — paired with `using-superpowers` (the 1% Rule dispatcher), it closes the compounding loop the original `obra/superpowers` plugin established.

This skill was reintroduced in v3.0.0 alongside `using-superpowers` after both were inadvertently dropped during an earlier fork refactor.

## References

- `superpowers/skills/using-superpowers/SKILL.md` — paired dispatcher (the 1% Rule). Loads automatically; pairs with this skill to close the compounding loop.
