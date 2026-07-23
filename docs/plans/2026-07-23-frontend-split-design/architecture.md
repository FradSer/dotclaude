# Frontend Plugin Slim-Down — Architecture

## 1. Delete / Keep / Rewrite map

| Path | Action | REQ | Rationale |
|---|---|---|---|
| `skills/supabase/` | DELETE | REQ-001 | mirror (supabase/agent-skills) |
| `skills/supabase-postgres-best-practices/` | DELETE | REQ-001 | mirror (supabase/agent-skills) |
| `skills/web-design-guidelines/` | DELETE | REQ-001 | mirror (vercel-labs/agent-skills) |
| `skills/impeccable/` | DELETE | REQ-001 | verbatim mirror (pbakaus/impeccable) |
| `skills/shadcn/` | DELETE | REQ-001 | mirror (shadcn-ui/ui) |
| `skills/design-md/` | KEEP | — | local SKILL.md + cached upstream spec; original integration layer |
| `skills/articulate/` | KEEP | — | index.how source (non-git, cannot re-install via marketplace github) |
| `skills/next-devtools-guide/` | KEEP | — | local, pairs with next-devtools mcpServer |
| `agents/frontend-expert.md` | REWRITE | REQ-005 | prune pipelines to 3 surviving skills |
| `agents/frontend-anti-patterns.md` | REWRITE | REQ-004 | drop detect.mjs hard dep |
| `hooks/design-md-first.sh` | REWRITE | REQ-006 | drop ladder steps 2-3 (impeccable/shadcn) |
| `.claude-plugin/plugin.json` | REWRITE | REQ-009 | prune manifest arrays |
| `scripts/sync-supabase-skills.sh` | DELETE | REQ-002 | serviced deleted skill |
| `scripts/sync-vercel-skills.sh` | DELETE | REQ-002 | serviced deleted skills |
| `scripts/sync-shadcn.sh` | DELETE | REQ-002 | serviced deleted skill |
| `scripts/sync-impeccable.sh` | DELETE | REQ-002 | serviced deleted skill |
| `scripts/sync-design-md.sh` | KEEP | REQ-010 | services surviving design-md |
| `scripts/lib/sync-common.sh` | KEEP | REQ-010 | shared by sync-design-md |
| `scripts/check-coherence.sh` | REWRITE | REQ-011 | drop impeccable assertions 1-2, re-scope assertion 4 |
| `scripts/check-references.sh` | REWRITE | REQ-011 | re-scope to surviving skill reference links |
| `.sync-snapshots/supabase-skills.manifest` | DELETE | REQ-002 | serviced deleted skills |
| `.sync-snapshots/vercel-skills.manifest` | DELETE | REQ-002 | serviced deleted skills |
| `.sync-snapshots/shadcn.manifest` | DELETE | REQ-002 | serviced deleted skill |
| `.sync-snapshots/impeccable.manifest` | DELETE | REQ-002 | serviced deleted skill |
| `modifications/impeccable.md` | DELETE | REQ-003 | targets deleted impeccable |
| `modifications/shadcn.md` | DELETE | REQ-003 | targets deleted shadcn |
| `modifications/patches/shadcn-tailwind-v4.md` | DELETE | REQ-003 | patch for deleted shadcn |
| `modifications/react-best-practices.md` | DELETE | REQ-003 | targets deleted react-best-practices |
| `modifications/README.md` | DELETE or TRIM | REQ-003 | if no modifications survive, delete the dir + assertion 3 |
| `README.md` | REWRITE | REQ-013 | migration note listing deleted skills + upstream repos |
| `SYNC.md` | REWRITE | REQ-002 | drop sections for deleted skills; keep design-md section |
| `next-devtools` mcpServer (in plugin.json) | KEEP | — | local pair with next-devtools-guide |

## 2. Surviving frontend/ tree

```
frontend/
├── .claude-plugin/plugin.json      # pruned: design-md, articulate, next-devtools-guide, 2 agents, hook, next-devtools mcpServer
├── agents/
│   ├── frontend-expert.md          # pruned pipelines
│   └── frontend-anti-patterns.md   # detector block removed
├── hooks/
│   └── design-md-first.sh          # ladder steps 2-3 removed
├── skills/
│   ├── design-md/                  # SURVIVES
│   ├── articulate/                 # SURVIVES
│   └── next-devtools-guide/        # SURVIVES
├── scripts/
│   ├── lib/sync-common.sh          # SURVIVES (design-md uses it)
│   ├── sync-design-md.sh           # SURVIVES
│   ├── check-coherence.sh          # re-scoped
│   └── check-references.sh         # re-scoped
├── .sync-snapshots/                # design-md manifest only (if design-md uses snapshots — verify)
├── README.md                       # migration note
└── SYNC.md                         # design-md section only
```

## 3. Dependency direction (ARCH-01 invariant)

The surviving integration layer has NO inner-to-outer dependency. The hook reads only `cwd` filesystem state (DESIGN.md presence) and emits advisory prose — no import/require/reference to infra/database/CLI layers. The agents reference sibling skills by qualified skill ID (advisory, resolved by the Skill tool at runtime, not a static import). Nothing in the slimmed plugin `import`s or `require`s an infrastructure layer.

## 4. Rewritten file anchors

- `hooks/design-md-first.sh:44-47` — current preamble ladder. Rewrite to drop steps citing `frontend:impeccable` and `frontend:shadcn`; keep step 1 (`frontend:design-md` source of truth). The "four quality authorities" framing (current `:47`) collapses to design-md + manual anti-patterns.
- `agents/frontend-anti-patterns.md:50-57,95` — current `find ~/.claude -path '*/frontend/skills/impeccable/SKILL.md'` + `node "$SKILL_DIR/scripts/detect.mjs" --json` block. Remove entirely; keep the manual-check fallback (already documented at `:57` onward).
- `agents/frontend-expert.md:36-185` — current pipelines + "Available Skills" list. Prune every `frontend:<deleted-skill>` reference; keep `frontend:design-md`, `frontend:articulate`, `frontend:next-devtools-guide`, and the rewritten anti-patterns agent.
- `skills/design-md/SKILL.md:188-194` — "Sibling Skill Integration". Remove `frontend:impeccable` / `frontend:web-design-guidelines` / `frontend:shadcn` references.
- `skills/articulate/SKILL.md:22` — pairing sentence. Remove `frontend:impeccable` / `frontend:web-design-guidelines`.
- `.claude-plugin/plugin.json` `commands`/`skills` arrays — remove deleted skill paths; keep design-md, articulate, next-devtools-guide.
- `scripts/check-coherence.sh:156,159` — assertion 4 frontend-expert ID registration; re-validate against pruned plugin.json. Drop assertions 1 (phantom impeccable-<cmd>) and 2 (.mjs path).

## 5. Verification (REQ-001, REQ-002, REQ-003, REQ-004, REQ-005, REQ-006, REQ-007, REQ-008, REQ-009, REQ-010, REQ-011, REQ-014)

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude/frontend

# REQ-001: 5 mirror skills deleted, 3 survive
! [ -d skills/supabase ] && ! [ -d skills/supabase-postgres-best-practices ] && \
! [ -d skills/web-design-guidelines ] && ! [ -d skills/impeccable ] && ! [ -d skills/shadcn ]
[ -d skills/design-md ] && [ -d skills/articulate ] && [ -d skills/next-devtools-guide ]

# REQ-002: sync scripts + manifests deleted; design-md sync kept
! [ -f scripts/sync-supabase-skills.sh ] && ! [ -f scripts/sync-vercel-skills.sh ] && \
! [ -f scripts/sync-shadcn.sh ] && ! [ -f scripts/sync-impeccable.sh ]
[ -f scripts/sync-design-md.sh ] && [ -f scripts/lib/sync-common.sh ]

# REQ-003: mirror-bound modifications deleted
! [ -f modifications/impeccable.md ] && ! [ -f modifications/shadcn.md ] && \
! [ -f modifications/patches/shadcn-tailwind-v4.md ] && ! [ -f modifications/react-best-practices.md ]

# REQ-004: anti-patterns agent has no detect.mjs / impeccable find-path
! grep -q "detect.mjs" agents/frontend-anti-patterns.md
! grep -q "skills/impeccable/SKILL.md" agents/frontend-anti-patterns.md

# REQ-005: coordinator has no deleted-skill IDs
! grep -qE "frontend:(supabase|supabase-postgres-best-practices|shadcn|react-best-practices|web-design-guidelines|impeccable)" agents/frontend-expert.md

# REQ-006: hook has no deleted-skill IDs, keeps design-md
! grep -q "frontend:impeccable" hooks/design-md-first.sh
! grep -q "frontend:shadcn" hooks/design-md-first.sh
grep -q "frontend:design-md" hooks/design-md-first.sh

# REQ-007, REQ-008: surviving SKILL.md have no deleted-sibling refs
! grep -qE "frontend:(impeccable|web-design-guidelines|shadcn)" skills/design-md/SKILL.md
! grep -qE "frontend:(impeccable|web-design-guidelines|shadcn)" skills/articulate/SKILL.md

# REQ-009: plugin.json arrays list only surviving skills
python3 -c "import json; d=json.load(open('.claude-plugin/plugin.json')); \
arrs=d.get('commands',[])+d.get('skills',[]); \
assert all(p not in arrs for p in ['./skills/supabase/','./skills/supabase-postgres-best-practices/','./skills/web-design-guidelines/','./skills/impeccable/','./skills/shadcn/']); \
assert './skills/design-md/' in arrs and './skills/articulate/' in arrs and './skills/next-devtools-guide/' in arrs; \
assert 'next-devtools' in d.get('mcpServers',{})"

# REQ-012: marketplace version == plugin.json version
python3 -c "import json; p=json.load(open('.claude-plugin/plugin.json')); \
m=[x for x in json.load(open('../.claude-plugin/marketplace.json'))['plugins'] if x['name']=='frontend'][0]; \
assert p['version']==m['version'], f\"{p['version']} != {m['version']}\""

# REQ-014: hook has no LLM/network/subprocess call
! grep -qE "curl|npx|node |http" hooks/design-md-first.sh

# REQ-015 + REQ-009: validator passes
python3 ../plugin-optimizer/scripts/validate-plugin.py frontend/ ; echo "exit=$?"
```

All commands must succeed (exit 0) for the slim-down to be considered complete.
