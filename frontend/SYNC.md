# Frontend Skills 同步说明

- **上次同步**: 2026-04-16

## shadcn

- **仓库**: [shadcn-ui/ui](https://github.com/shadcn-ui/ui)
- **路径**: `skills/shadcn/`
- **同步脚本**: `./frontend/scripts/sync-shadcn.sh`
- **说明**: 使用 sparse checkout 同步目录内容，自动排除 `agents/`、`assets/`，并保留本地 `.backup/`。

## impeccable

- **仓库**: [pbakaus/impeccable](https://github.com/pbakaus/impeccable)
- **路径**: `.claude/skills/` 与 `.claude/agents/`
- **同步脚本**: `./frontend/scripts/sync-impeccable.sh`
- **说明**: 子 skill 自动加 `impeccable-` 前缀；`impeccable/SKILL.md` 保留本地版本；上游 anti-patterns 原文保存到 `frontend/agents/references/`。

## react-best-practices

- **仓库**: [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills)
- **路径**: `skills/react-best-practices/`
- **同步脚本**: `./frontend/scripts/sync-vercel-skills.sh`

## web-design-guidelines

- **仓库**: [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills)
- **路径**: `skills/web-design-guidelines/`
- **同步脚本**: `./frontend/scripts/sync-vercel-skills.sh`

## supabase

- **仓库**: [supabase/agent-skills](https://github.com/supabase/agent-skills)
- **路径**: `skills/supabase/`
- **同步脚本**: `./frontend/scripts/sync-supabase-skills.sh`

## supabase-postgres-best-practices

- **仓库**: [supabase/agent-skills](https://github.com/supabase/agent-skills)
- **路径**: `skills/supabase-postgres-best-practices/`
- **同步脚本**: `./frontend/scripts/sync-supabase-skills.sh`

## 常用命令

```bash
# shadcn
./frontend/scripts/sync-shadcn.sh --check
./frontend/scripts/sync-shadcn.sh

# impeccable
./frontend/scripts/sync-impeccable.sh --check
./frontend/scripts/sync-impeccable.sh

# vercel skills
./frontend/scripts/sync-vercel-skills.sh --check
./frontend/scripts/sync-vercel-skills.sh

# supabase skills
./frontend/scripts/sync-supabase-skills.sh --check
./frontend/scripts/sync-supabase-skills.sh
```

