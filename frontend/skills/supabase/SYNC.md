# Supabase Skill 同步说明

## 上游仓库

- **仓库**: [supabase/agent-skills](https://github.com/supabase/agent-skills)
- **路径**: `skills/supabase/`
- **上次同步**: 2026-04-16

## 同步内容

### 核心文件
- `SKILL.md` - Supabase 基础技能（安全检查清单、CLI、MCP、文档访问）

### 参考文档 (references/)
- `skill-feedback.md` - 用户反馈流程

### 资源 (assets/)
- `feedback-issue-template.md` - Issue 模板

## 同步方法

```bash
./frontend/scripts/sync-supabase-skills.sh          # 同步（含 postgres-best-practices）
./frontend/scripts/sync-supabase-skills.sh --check   # 仅检查
./frontend/scripts/sync-supabase-skills.sh --force   # 强制同步
```
