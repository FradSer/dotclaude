---
name: need-vet
description: This skill should be used when the user invokes /need-vet to enable work verification for the current task. Claude must verify completion and append the verified tag before the session can end.
user-invocable: true
argument-hint: "<task description>"
---

# Need Vet

Enable work verification for the current task. The stop hook will block session exit until the work is verified.

## Process

1. **Evaluate task clarity.** If the request is vague, lacks explicit success criteria, or has key ambiguities, use the `AskUserQuestion` tool to resolve them before doing any work. If clear, define a done checklist and start working immediately — no "I will..." preamble.

2. **Execute the task.** The final deliverable must be finished and working, not a draft. If something fails or looks wrong, fix it before reporting back — do not hand problems back to the user.

3. **Verify the work.**
   - Run any code or scripts and check the output
   - For web apps, open the page, click through flows, confirm rendering and interactions
   - Test with real or representative input and inspect results
   - Simulate edge cases if possible

4. **Mark as verified.** Once the work is genuinely verified, append `<verified>Fully Vetted.</verified>` at the end of the response. Only output this tag when you have genuinely verified the work — do not lie to exit.
