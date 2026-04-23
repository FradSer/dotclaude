# Frontend Skills 同步说明

每个 section 维护独立 `**上次同步**` 时间戳，由对应 sync 脚本自动更新。

## shadcn

- **上次同步**: 2026-04-22
- **仓库**: [shadcn-ui/ui](https://github.com/shadcn-ui/ui)
- **路径**: `skills/shadcn/`
- **同步脚本**: `./frontend/scripts/sync-shadcn.sh`
- **说明**: 使用 sparse checkout 同步目录内容，自动排除 `agents/`、`assets/`，并保留本地 `.backup/`。

## impeccable

- **上次同步**: 2026-04-22
- **仓库**: [pbakaus/impeccable](https://github.com/pbakaus/impeccable)
- **路径**: `.claude/skills/` 与 `.claude/agents/`
- **同步脚本**: `./frontend/scripts/sync-impeccable.sh`
- **说明**: 子 skill 自动加 `impeccable-` 前缀；`impeccable/SKILL.md` 保留本地版本；上游 SKILL.md 存为 `reference/upstream-SKILL.md`；anti-patterns 原文保存到 `frontend/agents/references/`。

## react-best-practices

- **上次同步**: 2026-04-22
- **仓库**: [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills)
- **路径**: `skills/react-best-practices/`
- **同步脚本**: `./frontend/scripts/sync-vercel-skills.sh`
- **说明**: 同步后脚本会重写 SKILL.md `name:` 字段为 `react-best-practices`，匹配目录名（上游原名是 `vercel-react-best-practices`）。

## web-design-guidelines

- **上次同步**: 2026-04-22
- **仓库**: [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills)
- **路径**: `skills/web-design-guidelines/`
- **同步脚本**: `./frontend/scripts/sync-vercel-skills.sh`

## supabase

- **上次同步**: 2026-04-22
- **仓库**: [supabase/agent-skills](https://github.com/supabase/agent-skills)
- **路径**: `skills/supabase/`
- **同步脚本**: `./frontend/scripts/sync-supabase-skills.sh`

## supabase-postgres-best-practices

- **上次同步**: 2026-04-22
- **仓库**: [supabase/agent-skills](https://github.com/supabase/agent-skills)
- **路径**: `skills/supabase-postgres-best-practices/`
- **同步脚本**: `./frontend/scripts/sync-supabase-skills.sh`

## design-md

- **上次同步**: 2026-04-22
- **仓库**: [google-labs-code/design.md](https://github.com/google-labs-code/design.md)
- **路径**: `skills/design-md/references/`（仅缓存上游 spec 作为审计参考；`SKILL.md` 为本地自定义集成，不由 sync 管理）
- **同步脚本**: `./frontend/scripts/sync-design-md.sh`
- **说明**: 同步上游 `docs/spec.md` → `upstream-spec.md` 和 `README.md` → `upstream-README.md`。`SKILL.md` 不会被覆盖；当 `spec.md` 变更时，脚本会提示人工比对 `SKILL.md` 的内联 schema / section 顺序 / lint 规则表是否仍然一致（上游版本为 `alpha`，期待破坏性变更）。

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

# design-md spec
./frontend/scripts/sync-design-md.sh --check
./frontend/scripts/sync-design-md.sh
```
