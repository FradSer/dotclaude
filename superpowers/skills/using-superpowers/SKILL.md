---
name: using-superpowers
description: This skill should be used whenever any superpowers skill might apply. The 1% Rule — if there is even a 1% chance one of the user-invocable superpowers skills (brainstorming, writing-plans, executing-plans, retrospective, systematic-debugging) is the right tool for the current request, invoke it explicitly via the Skill tool rather than improvising. Loaded automatically as internal context.
user-invocable: false
---

# Using Superpowers (the 1% Rule dispatcher)

This is the keystone that makes the superpowers skill library actually fire. Without it, you tend to improvise — re-deriving methodology that the dedicated skills already encode. With it, the cost of trying the right skill is low and the cost of skipping it is high.

## The 1% Rule

**If there is even a 1% chance one of the user-invocable superpowers skills is the right tool for what the user just asked, invoke it explicitly via the Skill tool — don't improvise.**

The cost of trying the right skill and finding it's a poor fit is one extra Skill invocation. The cost of improvising past the right skill is re-deriving structure the skill already encodes, missing the BDD discipline / per-batch evaluator / checklist evolution that the skill ships, and producing a worse outcome.

When in doubt, invoke. The bail-out checks built into each skill (brainstorming line 12, writing-plans line 15, executing-plans line 19) will exit cheaply if the work is genuinely trivial — you have not been over-invoking, you have been letting the skill self-select scope.

## When to invoke which skill

| Trigger signal | Invoke |
|---|---|
| "brainstorm", "design", "I have an idea", new feature with ambiguous shape, multi-component design | `superpowers:brainstorming` |
| "write a plan", "decompose into tasks", "implementation plan" — a completed design folder under `docs/plans/*-design/` exists | `superpowers:writing-plans` |
| "execute the plan", "run the plan", "implement", a completed plan folder under `docs/plans/*-plan/` exists | `superpowers:executing-plans` |
| Bug report, "fix this error", test failure, unexpected behavior, "why does X happen" | `superpowers:systematic-debugging` |
| After a completed plan: "let's retro", "what should we learn", "update checklists" | `superpowers:retrospective` |
| Several independent work streams to run in parallel | `superpowers:agent-team-driven-development` (advisory) |
| Need to challenge industry convention, radical-innovation framing required | `superpowers:build-like-iphone-team` (advisory) |

## Lineage and rationale

The 1% Rule comes from the original `obra/superpowers` plugin's `using-superpowers` skill — see <https://blog.fsck.com/2025/10/05/how-im-using-coding-agents-in-october-2025/> for the full reasoning. The short version: skills are only valuable if they fire. A library of well-written skills that the dispatcher routinely improvises past is worth zero. This dispatcher is the keystone that makes the rest of the library actually load-bearing.

This skill was reintroduced in v3.0.0 after the maintainer's fork inadvertently dropped it during an earlier refactor.

## What this skill is NOT

- Not a permission gate. You don't need to ask the user before invoking a superpowers skill — the skill's own bail-out check handles "this is too small" deterministically.
- Not a dispatcher that requires reading both this skill's body and the target skill's body before invoking. The triggers above are sufficient — invoke first, let the skill decide its own scope.
- Not a meta-skill that should be invoked itself. It is loaded automatically as internal context (`user-invocable: false`) so the trigger table is always available; you never type `/superpowers:using-superpowers`.
