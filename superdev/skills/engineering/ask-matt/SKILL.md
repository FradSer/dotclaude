---
name: ask-matt
description: Recommends the skill or flow that fits the user's situation. A router over the skills in this repo. Use when the user asks which skill to use, is unsure what fits, or needs a pointer to the right workflow.
disable-model-invocation: true
---

# Ask Matt

You don't remember every skill, so ask.

A **flow** is a path through the skills. Most paths run along one **main flow**, and two **on-ramps** merge onto it. Everything else is standalone, or a vocabulary layer that runs underneath.

## The main flow: idea → ship

The route most work travels. You have an idea and want it built.

1. **`/superdev:grill-with-docs`** — sharpen the idea by interview. Start here when you **have a codebase**: it's stateful, retaining what it learns in `CONTEXT.md` and ADRs. (No codebase? Use `/superdev:grill-me` — see Standalone. Both run the same `/superdev:grilling` primitive; `grill-with-docs` is the one that leaves a paper trail.)
2. **Branch — can you settle every question in conversation?** If a question needs a runnable answer (state, business logic, a UI you have to see), detour through a prototype, bridged by **`/superdev:handoff`** in both directions (see Crossing sessions):
   - **`/superdev:handoff`** out, then open a fresh session against that file,
   - **`/superdev:prototype`** to answer the question with throwaway code,
   - **`/superdev:handoff`** back what you learned, and reference it from the original idea thread.
3. **Branch — is this a multi-session build?**
   - **Yes** → **`/superdev:to-spec`** (turn the thread into a spec), then **`/superdev:to-tickets`** to split it into tracer-bullet tickets, each declaring its **blocking edges**. On a local tracker that's one file per ticket under `.scratch/<feature>/issues/`, worked blockers-first by hand; on a real tracker the edges become native blocking links, so any ticket whose blockers are done can be grabbed — kick off **`/superdev:implement`** per ticket, **clearing context between each one**.
   - **No** → **`/superdev:implement`** right here, in the same context window.

   Either way, **`/superdev:implement`** builds each issue by driving **`/superdev:bdd`** internally — one red-green slice at a time — then closes out by running **`/superdev:code-review`**, a two-axis review (Standards + Spec) of the diff, before committing. Reach for **`/superdev:bdd`** on its own when you just want to build a concrete behaviour test-first without a full spec, and **`/superdev:code-review`** on its own whenever you want to review a branch or PR against a fixed point.

### Context hygiene

Keep steps 1–3 in **one unbroken context window** — don't compact or clear until after `/superdev:to-tickets` — so the grilling, spec, and tickets all build on the same thinking. Each `/superdev:implement` then starts fresh, working from the ticket.

The limit on this is the **[smart zone](https://www.aihero.dev/ai-coding-dictionary/smart-zone)**: the window (~120k tokens on state-of-the-art models) within which the model still reasons sharply. If a session approaches it before `/superdev:to-tickets`, don't push on degraded — `/superdev:handoff` and continue in a fresh thread.

## CRITICAL: Route by scenario, not by habit

Wayfinder is only for work too big for one session — never a well-scoped feature. Triage is only for issues the user didn't create — never for the tickets `/superdev:to-tickets` produced. Keep steps 1–3 in one unbroken context window: no compact or clear until after `/superdev:to-tickets`.

## On-ramps

A starting situation that generates work, then merges onto the main flow.

- **Bugs and requests piling up** → **`/superdev:triage`**. It moves issues through triage roles and produces agent-ready issues, which **`/superdev:implement`** later picks up.

  Triage is only for issues **you didn't create** — bug reports, incoming feature requests, anything that arrives raw. Tickets that `/superdev:to-tickets` produced are already agent-ready, so **don't triage them**.

- **Something's broken** → **`/superdev:diagnosing-bugs`**. For the hard ones: the bug that resists a first glance, the intermittent flake, the regression that crept in between two known-good states. It refuses to theorise until it has a **tight feedback loop** — one command that already goes red on *this* bug — then fixes with a regression test. Its post-mortem hands off to **`/superdev:improve-codebase-architecture`** when the real finding is that there's no good seam to lock the bug down.

- **A huge, foggy effort — a greenfield project or a huge feature build, too big for one session** → **`/superdev:wayfinder`**, the most cognitively demanding flow here. When the way from here to the destination isn't visible yet, it charts a **shared map** of **decision tickets** on the issue tracker and resolves them one at a time — producing **decisions, not deliverables** — until the fog is pushed back and the way is clear. Where **`/superdev:grill-with-docs`** sharpens an idea you can hold in one session, wayfinder is for the idea you can't — and it's slower and denser, so save it for exactly that, never a well-scoped feature.

  When the map clears, **it hands off, it doesn't build**: merge onto the main flow at **`/superdev:to-spec`**, which collapses the map's linked decisions into a buildable plan, then `/superdev:to-tickets` and `/superdev:implement` as usual. Looping the map straight into `/superdev:implement` skips that collapse and throws the linked detail away — go straight to `/superdev:implement` only when the effort turned out genuinely small.

## Codebase health

Not feature work — upkeep.

- **`/superdev:improve-codebase-architecture`** — run whenever you have a spare moment to keep the codebase good for agents to operate in. It surfaces **deepening opportunities**; picking one _generates an idea_ you can take into the main flow at `/superdev:grill-with-docs`. It's the survey that finds the candidates; **`/superdev:codebase-design`** (below) is the bench you design the chosen one on.

## Vocabulary underneath

Two model-invoked references that run *beneath* the other skills — each the single source of truth for its vocabulary. Reach for them directly when the **words**, not the process, are the problem; or let the skills above pull them in.

- **`/superdev:domain-modeling`** — sharpen the project's *domain* language: challenge a fuzzy term, resolve an overloaded word ("account" doing three jobs), record a hard-to-reverse decision as an ADR. It's the active discipline `/superdev:grill-with-docs` drives to keep `CONTEXT.md` a clean glossary.
- **`/superdev:codebase-design`** — the deep-module vocabulary (module, interface, depth, seam, adapter, leverage, locality) for designing a module's *shape*: a lot of behaviour behind a small interface at a clean seam. `/superdev:bdd` and `/superdev:improve-codebase-architecture` both speak it.

## Crossing sessions

A **phase** is a chunk of work inside a session — the grilling, the implementation, the QA. At the **boundary** between two of them you have five options, and picking between them is the fuzziest decision in this whole map:

- **Continue** — stay put. Costs nothing, loses nothing.
- **`/clear`** — empty the window, when nothing here matters to what's next.
- **`/superdev:handoff`** — write a portable markdown file. Narrow: only for a **new harness**, a **new directory**, a **colleague**, or forking a side task **mid-phase**. What it buys is portability. It's the bridge between context windows, in either direction.
- **Subagent** — send a tightly-scoped task to its own window and get a report back.
- **`/compact`** (built-in) — compress this context and seed a fresh session with it. The **default**, at the bottom of the tree rather than the first reach.

Read [PHASE-BOUNDARIES.md](PHASE-BOUNDARIES.md) for the ordered tree — the five questions, the reasoning behind each branch, and why the primary-source cost makes **Continue** the one to rule out first. Make the decision **at** a boundary; mid-phase, continue or split the rest into subagents. `/superdev:handoff` forks; `/compact` continues.

## Standalone

Off the main flow entirely.

- **`/superdev:grill-me`** — the same relentless interview as `/superdev:grill-with-docs`, but for when you have **no codebase**. Stateless: it saves nothing locally, builds no `CONTEXT.md`. Reach for it to sharpen any plan or design that doesn't live in a repo.
- **`/superdev:grilling`** — the interview primitive itself: one question at a time via the AskUserQuestion tool, facts are the agent's job and decisions are yours. `/superdev:grill-me` and `/superdev:grill-with-docs` are the two named ways in, and `/superdev:triage`, `/superdev:wayfinder` and `/superdev:improve-codebase-architecture` all run it internally. Reach for it directly only when you want the interview with no wrapper around it.
- **`/superdev:resolving-merge-conflicts`** — work an in-progress merge or rebase conflict hunk by hunk, resolving by **intent** traced to each side's primary source rather than by picking lines, then finish the operation. It never runs `--abort`. Standalone and off every flow: reach for it when you are already mid-conflict.
- **`/superdev:prototype`** — a small, throwaway program that answers one design question: does this state model feel right, or what should this UI look like. It's the detour in step 2 of the main flow, but reach for it any time a design question is hard to settle on paper.
- **`/superdev:research`** — delegate reading legwork to a **background agent**: it investigates a question against **primary sources**, then leaves a cited Markdown file in the repo. Keep working while it reads. The file it produces is something to take *into* the main flow at `/superdev:grill-with-docs` — research feeds the thinking, it doesn't replace it.
- **`/superdev:to-questionnaire`** — when the thing blocking you isn't in your head or the codebase but in **someone else's**, this writes them a questionnaire to fill in. It's the inverse of `/superdev:grill-me`: instead of interviewing you about the subject, it interviews you about the **send** — who it's going to, what you need back — and aims the questions at the gap. What comes back is material for `/superdev:grill-with-docs` or `/superdev:to-spec`.
- **`/superdev:wizard`** — for the steps only a **human** can take: provisioning infrastructure, setting up credentials or CI secrets, clicking through an unfamiliar third-party dashboard, running a one-off migration or cutover. It generates an interactive bash script that opens each URL, captures each value, and writes it into `.env` and GitHub secrets — so the procedure stops being something you re-explain to an agent every time. Model-invoked, so the agent reaches for it the moment it hits a wall only you can pass. If the agent could just do it itself, it should; this is for where a human is genuinely in the loop.
- **`/superdev:wait-what`** — the corrective for a message that didn't land. Use it mid-conversation, inside any other skill, and the agent re-pitches what it just said with the context you were missing, in plain English, using the `CONTEXT.md` vocabulary. It works after the fact; `/superdev:grill-with-docs` is the upfront cure, because a shared language agreed early is what stops the jargon arriving at all.
- **`/superdev:teach`** — learn a concept over multiple sessions, using the current directory as a stateful workspace.
- **`/superdev:writing-for-agents`** — reference for writing documents agents consume: skills, `AGENTS.md`/`CLAUDE.md`, pointed-at docs.
- **`/superdev:writing-great-skills`** — reference for writing and editing skills well.

## Precondition

**`/superdev:setup-matt-pocock-skills`** — run before your first engineering flow to configure the issue tracker, triage labels, and doc layout the other skills assume. Custom issue trackers also work.
