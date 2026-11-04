---
name: wizard-template-frozen
description: Wizard generation must reuse template.sh's frozen library verbatim, keep the STAGES marker, and statically verify without running.
tags: [wizard]
runs: 2
max_turns: 30
timeout_seconds: 600
---

Use the mattpocock:wizard skill (load it with the Skill tool) to generate an interactive bash wizard for a Node + Cloudflare Workers project in the current working directory. The procedure walks a human developer through:

1. Stripe test API keys (publishable + secret) -> `.env`
2. D1 database id and binding -> `wrangler.toml`
3. Stripe webhook signing secret -> `.env` and a GitHub Actions secret named `STRIPE_WEBHOOK_SECRET`

Write the wizard to `scripts/setup-wizard.sh` (create `scripts/`). Verify it the way the skill requires: `bash -n`, plus `shellcheck` if it happens to be available (do not install anything — no network; if shellcheck is missing, say so). Do NOT run the wizard itself.

End with a short report: verification output, and one line stating exactly how the file above the STAGES marker was produced.
