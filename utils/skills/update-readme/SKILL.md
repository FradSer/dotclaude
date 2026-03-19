---
name: update-readme
description: Updates README.md and README.zh-CN.md to reflect the project's current state. Use this skill whenever the user asks to "update the README", "sync the docs", "update documentation", "reflect latest changes in README", or wants both the English and Chinese READMEs to match the current project. Always triggers when the user mentions updating or regenerating README files, especially for bilingual (EN/ZH) projects.
disable-model-invocation: true
---

# Update README

Keep README.md (English, primary) and README.zh-CN.md (Simplified Chinese, secondary) in sync with the project's actual current state. Both files must be accurate, complete, and consistent with each other.

## Header Format (Required)

Every README must open with this exact structure — adapt the badges, project name, and description to the project at hand:

```markdown
# <Project Name> ![](https://img.shields.io/badge/<label>-<message>-<color>)

[![<Badge1 Label>](<badge-url>)](<link>) [![<Badge2 Label>](<badge-url>)](<link>)

**English** | [简体中文](README.zh-CN.md)
```

For README.zh-CN.md, reverse the language toggle:

```markdown
# <Project Name> ![](https://img.shields.io/badge/<label>-<message>-<color>)

[![<Badge1 Label>](<badge-url>)](<link>) [![<Badge2 Label>](<badge-url>)](<link>)

[English](README.md) | **简体中文**
```

Choose badges that reflect what is genuinely true about the project. Common types: CI status, license, language/runtime version, package registry version, code coverage. Use shields.io static badges when there is no live endpoint. Prefer reference-style Markdown links for badge rows with more than two badges — it keeps the source readable. Broken or always-failing badges are worse than no badges; only include ones that are maintained.

## Process

### 1. Survey the project

Before writing anything, read the actual project state:

- Scan all skill/module directories and their SKILL.md or equivalent descriptor files
- Note each component's name, one-line purpose, installation method, and any notable prerequisites
- Check git log for recent additions or removals
- Read the existing README files to understand what is already there and what has gone stale

Write from ground truth, not from memory or assumption.

### 2. Draft README.md (English)

Use `references/template.md` as the structural starting point. Adapt section names to the project's domain — the template shows the skeleton, not the words.

**Section order** (omit what doesn't apply, don't add sections just to fill space):
1. Header — title + badges + language toggle
2. One-liner description (one sentence)
3. Logo, banner, or demo GIF — optional, but place it early if the project has one
4. Main content sections (Available Items, Usage, etc.)
5. Contributing / Adding a new item
6. License

For READMEs over ~300 lines, add a Table of Contents after the one-liner.

The README is a directory, not a tutorial. Keep each component description to one or two sentences. Installation commands must be copy-pasteable — exact commands, no ambiguity. Always use fenced code blocks with a language tag (` ```bash `, ` ```json `).

Write with a human voice. README prose is some of the most AI-trope-prone writing that exists — it tends to accumulate "robust", bold-first bullet points, and "serves as" constructions without anyone noticing. Specific things to watch for:

- Word choice: avoid "leverage", "streamline", "robust", "utilize", "delve". Say the plain thing.
- Bullets: don't start every item with a bolded phrase. It reads as AI-generated documentation.
- Descriptions: say what the component does, not what it "serves as" or "stands as".
- Marketing tone: "powerful", "seamless", "comprehensive" add nothing. Cut them.
- Filler transitions: "It's worth noting", "Importantly", "Notably" — delete these.

A useful test: read each sentence aloud. If it sounds like promotional copy, rewrite it as a plain statement of fact.

### 3. Draft README.zh-CN.md (Chinese)

Translate the English README faithfully. Rules:

- Use natural Simplified Chinese — do not translate technical terms that are universally used in English (CLI tool names, package manager commands, GitHub URLs, code blocks).
- Keep all code blocks, commands, and file paths identical to the English version.
- Section headings should be idiomatic Chinese (e.g., "可用技能", "添加新技能"), not word-for-word translations.
- The language toggle must be `[English](README.md) | **简体中文**`.
- Apply the same plain-language discipline as the English version. Chinese technical writing has its own AI tells — avoid 「赋能」, 「助力」, 「生态」 where a simpler word works.

### 4. Review before writing

Before writing either file, verify:

- Every skill/component listed actually exists in the repository right now
- Installation commands are copy-pasteable and accurate
- No section describes something that has been removed
- Both files cover the same content in the same order

Then scan the draft for writing issues:

- Em-dashes used more than 2-3 times total? Cut most of them.
- Any sentence starts with "The X serves as..."? Rewrite as "The X is...".
- Bold-first bullet pattern throughout? Remove the bold.
- Same word or metaphor repeated across multiple descriptions? Vary it.
- Unicode arrows (→)? Replace with plain text.

### 5. Write the files

Write README.md first, then README.zh-CN.md. Use the Edit or Write tool — do not output the content as a code block in the conversation.

After writing, briefly confirm what changed (e.g., "Added update-readme skill, removed stale apple-events prerequisite note").

## References

- `references/template.md` — README structure template (load when drafting)
