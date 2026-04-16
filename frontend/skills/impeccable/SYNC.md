# Impeccable Design Skills 同步说明

## 上游仓库

- **仓库**: [pbakaus/impeccable](https://github.com/pbakaus/impeccable)
- **路径**: `.claude/skills/` 和 `.claude/agents/`
- **上次同步**: 2026-04-16

## 同步内容

### 核心 skill: impeccable (不加前缀)
- `SKILL.md` - 本地引导文件（不被同步覆盖）
- `reference/` - 9 个详细参考文档 + design-guide-upstream.md
- `scripts/` - 维护脚本

### 设计 skills (17 个, 带 impeccable- 前缀)
impeccable-adapt, impeccable-animate, impeccable-audit, impeccable-bolder, impeccable-clarify, impeccable-colorize, impeccable-critique, impeccable-delight, impeccable-distill, impeccable-harden, impeccable-layout, impeccable-optimize, impeccable-overdrive, impeccable-polish, impeccable-quieter, impeccable-shape, impeccable-typeset

### impeccable-critique skill
- `SKILL.md` - Nielsen 十大可用性启发式评估
- `reference/` - 评分指南、认知负荷、用户画像

### anti-patterns agent
- 原始文本保存在 `frontend/agents/references/anti-patterns-upstream.md`
- 已升级为 `frontend/agents/frontend-anti-patterns.md`

## 同步方法

```bash
./frontend/scripts/sync-impeccable.sh          # 同步所有 impeccable skills + agent
./frontend/scripts/sync-impeccable.sh --check   # 仅检查
./frontend/scripts/sync-impeccable.sh --force   # 强制同步
```

## 注意事项

- 同步脚本自动发现上游所有 skill 目录
- 子 skill 自动添加 `impeccable-` 前缀（impeccable 本身不加）
- impeccable 的 `SKILL.md` 保留本地版本，上游原文存为 `reference/design-guide-upstream.md`
- 每个 skill 目录中的 `SYNC.md` 不会被覆盖
- anti-patterns.md 原始文本保存到 `agents/references/` 目录
