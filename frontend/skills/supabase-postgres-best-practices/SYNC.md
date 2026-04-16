# Supabase Postgres Best Practices Skill 同步说明

## 上游仓库

- **仓库**: [supabase/agent-skills](https://github.com/supabase/agent-skills)
- **路径**: `skills/supabase-postgres-best-practices/`
- **上次同步**: 2026-04-16

## 同步内容

### 核心文件
- `SKILL.md` - 主技能文档（8 个分类，30+ 条 Postgres 最佳实践）

### 参考文档 (references/)
规则按前缀分类: query-, conn-, security-, schema-, lock-, data-, monitor-, advanced-

## 同步方法

```bash
./frontend/scripts/sync-supabase-skills.sh          # 同步（含 supabase 基础技能）
./frontend/scripts/sync-supabase-skills.sh --check   # 仅检查
./frontend/scripts/sync-supabase-skills.sh --force   # 强制同步
```
