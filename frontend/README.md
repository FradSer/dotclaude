# frontend

Web frontend development toolkit combining component management, framework tools, best practices, and design skills.

## Skills (24)

### Component & Framework


| Skill                 | Source                                                                  | Sync Script             |
| --------------------- | ----------------------------------------------------------------------- | ----------------------- |
| shadcn                | [shadcn-ui/ui](https://github.com/shadcn-ui/ui)                         | `sync-shadcn.sh`        |
| next-devtools-guide   | local                                                                   | --                      |
| react-best-practices  | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) | `sync-vercel-skills.sh` |
| web-design-guidelines | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) | `sync-vercel-skills.sh` |


### Backend & Data


| Skill                            | Source                                                            | Sync Script               |
| -------------------------------- | ----------------------------------------------------------------- | ------------------------- |
| supabase                         | [supabase/agent-skills](https://github.com/supabase/agent-skills) | `sync-supabase-skills.sh` |
| supabase-postgres-best-practices | [supabase/agent-skills](https://github.com/supabase/agent-skills) | `sync-supabase-skills.sh` |


### Design & Quality (from impeccable)


| Skill                         | Source                                                      | Sync Script          |
| ----------------------------- | ----------------------------------------------------------- | -------------------- |
| impeccable + 17 design skills | [pbakaus/impeccable](https://github.com/pbakaus/impeccable) | `sync-impeccable.sh` |


Impeccable skills: adapt, animate, audit, bolder, clarify, colorize, critique, delight, distill, harden, impeccable, layout, optimize, overdrive, polish, quieter, shape, typeset

## Agents (2)


| Agent                  | Purpose                                                             |
| ---------------------- | ------------------------------------------------------------------- |
| frontend-expert        | Guides usage of all skills, recommends the right skill for any task |
| frontend-anti-patterns | Detects UI anti-patterns: AI slop and design quality issues         |


## Syncing

Sync metadata is centralized in `SYNC.md` (single file under `frontend/`), and all sync scripts update its `**上次同步**` field.

Run these commands from the `frontend/` directory:

```bash
# shadcn (from shadcn-ui/ui)
./scripts/sync-shadcn.sh

# React best practices + web design guidelines (from vercel-labs/agent-skills)
./scripts/sync-vercel-skills.sh

# Supabase + Postgres best practices (from supabase/agent-skills)
./scripts/sync-supabase-skills.sh

# Impeccable design skills + anti-patterns agent (from pbakaus/impeccable)
./scripts/sync-impeccable.sh

# Check all for updates (dry run)
./scripts/sync-shadcn.sh --check
./scripts/sync-vercel-skills.sh --check
./scripts/sync-supabase-skills.sh --check
./scripts/sync-impeccable.sh --check
```

## MCP Server

- **next-devtools**: Next.js runtime diagnostics, Cache Components, documentation (7 tools + 2 prompts + 17 resources)

## License

MIT