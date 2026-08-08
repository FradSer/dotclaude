---
name: grilling
description: Grill the user relentlessly about a plan, decision, or idea. Use when the user wants to stress-test their thinking, or uses any 'grill' trigger phrases.
---

Interview me relentlessly about every aspect of this until we reach a shared understanding. Walk down each branch of the decision tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Use the AskUserQuestion tool to ask each question — one question per call, waiting for the answer before continuing. Give 2–4 options per question, put your recommended option first marked "(Recommended)", and rely on the tool's built-in "Other" option for answers you didn't anticipate. Asking multiple questions at once is bewildering.

If a *fact* can be found by exploring the environment (filesystem, tools, etc.), look it up rather than asking me. The *decisions*, though, are mine — put each one to me via the AskUserQuestion tool and wait for my answer.

Do not act on it until I confirm we have reached a shared understanding.

## CRITICAL: One question at a time — facts you look up, decisions the user makes

Ask each question via the AskUserQuestion tool, one question per call, waiting for the answer before continuing; multiple questions at once is bewildering. Put the recommended option first, marked "(Recommended)" — the tool's built-in "Other" option covers anything unanticipated. If a fact can be found by exploring the environment (filesystem, tools, etc.), look it up rather than asking. The decisions are the user's — put each one to them, and do not act until they confirm shared understanding.
