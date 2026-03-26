# Git Commit - Detailed Guidance

## Goal

Commit changes to git using git-agent (with git fallback).

## Context

This guide applies to three phases of the development workflow:

| Phase | Folder Type | Intent Template |
|-------|-------------|-----------------|
| Brainstorming (Design) | `*-design/` | `add design for ${topic}` |
| Writing Plans | `*-plan/` | `add implementation plan for ${topic}` |
| Executing Plans | Implementation changes | `${description}` |

## Actions

### 1. Commit with git-agent (Primary)

**CRITICAL: For design/plan folders, stage the entire folder first, then use `--no-stage`**

**Commit Pattern for Design and Plan Folders**:

```bash
git add docs/plans/${date}-${folder-type}-${topic}/
git-agent commit --no-stage --intent "add ${type} for ${topic}" \
  --co-author "Claude <Model> <Version> <noreply@anthropic.com>"
```

**Commit Pattern for Implementation Changes**:

```bash
git-agent commit --intent "${description}" \
  --co-author "Claude <Model> <Version> <noreply@anthropic.com>"
```

git-agent handles staging, diff analysis, message generation, and atomic splitting automatically. For implementation changes, do NOT manually stage files -- let git-agent handle it.

**On auth error (401 / missing key)**, retry with `--free` flag:

```bash
git-agent commit --intent "${description}" \
  --co-author "Claude <Model> <Version> <noreply@anthropic.com>" --free
```

### 2. Fallback to git (when git-agent is unavailable or fails)

If git-agent is not installed or all retries fail, fall back to manual git commit:

**Commit Pattern for Design and Plan Folders**:

```bash
git add docs/plans/${date}-${folder-type}-${topic}/
git commit -m "docs: add ${type} for ${topic}

${context}

- ${specific_action_1}
- ${specific_action_2}

${summary}

Co-Authored-By: <Model Name> <noreply@anthropic.com>"
```

**Commit Pattern for Implementation Changes**:

```bash
git add ${files_to_commit}
git commit -m "feat(${scope}): ${description}

${context}

- ${specific_action_1}
- ${specific_action_2}

${summary}

Co-Authored-By: <Model Name> <noreply@anthropic.com>"
```

**Fallback Commit Message Requirements**:

- **Prefix**: `docs:` for design/plan folders, `feat(${scope}):` for implementation
- **Subject**: Short description under 50 characters, lowercase
- **Body**:
  - Context (user request, feature description, or project background)
  - Specific actions taken (as a bulleted list)
  - Brief summary of the approach
- **Footer**: `Co-Authored-By: <Model Name> <noreply@anthropic.com>` (valid: `Claude Sonnet 4.6`, `Claude Opus 4.6`, `Claude Haiku 4.5`)

### 3. Verify Commit

Run `git log -1` to confirm the commit was created:

```bash
git log -1
```

Expected output should show:
- The commit with correct prefix
- Proper subject line
- Co-Authored-By footer(s)

### 4. Inform User

Tell the user:
- Folder and main document location
- Number of files or tasks created
- Git commit completed (note whether git-agent or fallback was used)
- Clear next steps for the workflow phase

## Best Practices

**Commit Quality**:
- Always stage entire folders for design/plan docs before using `--no-stage`
- Use `--intent` to keep git-agent focused on the right message
- Keep fallback subject lines under 50 characters
- Include Co-Authored-By footer with model name

**git-agent Advantages**:
- Automatic conventional commit message generation
- Atomic commit splitting (up to 5 groups)
- Built-in hook validation
- Auto-scope inference from git history

## Common Pitfalls to Avoid

**Don't stage manually for implementation changes**:
```bash
# Wrong: Manual staging when git-agent handles it
git add src/auth.ts
git-agent commit --intent "add auth module"

# Correct: Let git-agent handle staging
git-agent commit --intent "add auth module"
```

**Do stage manually for design/plan folders** (git-agent needs `--no-stage`):
```bash
# Correct: Stage folder, then commit with --no-stage
git add docs/plans/2026-03-26-auth-design/
git-agent commit --no-stage --intent "add design for auth"
```

**Don't skip verification**:
```bash
# Always verify commit was created
git log -1
```
