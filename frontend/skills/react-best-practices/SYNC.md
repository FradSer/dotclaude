# React Best Practices Skill 同步说明

## 上游仓库

- **仓库**: [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills)
- **路径**: `skills/react-best-practices/`
- **上次同步**: 2026-04-16

## 同步内容

### 核心文件
- `SKILL.md` - 主技能文档（8 个规则分类，70+ 条规则）
- `AGENTS.md` - 编译后的完整规则指南
- `README.md` - 贡献指南和构建脚本
- `metadata.json` - 版本和元数据

### 规则 (rules/)
70+ 条规则，按前缀分类: async-, bundle-, server-, client-, rerender-, rendering-, js-, advanced-

### 排除的上游目录
- `agents/` - OpenAI 特定
- `assets/` - OpenAI 特定

## 同步方法

```bash
./frontend/scripts/sync-vercel-skills.sh          # 同步（含 web-design-guidelines）
./frontend/scripts/sync-vercel-skills.sh --check   # 仅检查
./frontend/scripts/sync-vercel-skills.sh --force   # 强制同步
```
