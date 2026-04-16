# shadcn Skill 同步说明

## 上游仓库

- **仓库**: [shadcn-ui/ui](https://github.com/shadcn-ui/ui)
- **路径**: `skills/shadcn/`
- **上次同步**: 2026-04-16

## 同步内容

此 skill 通过 `git sparse-checkout` 从上游仓库整个目录同步，自动处理新增/变更/删除的文件。

当前同步的文件:

### 核心文件
- `SKILL.md` - 主技能文档
- `cli.md` - CLI 命令参考
- `customization.md` - 主题和 CSS 变量
- `mcp.md` - MCP server 工具

### 规则 (rules/)
- `styling.md` - Tailwind/CSS 布局规则
- `forms.md` - 表单组件和验证
- `composition.md` - 组件结构和组合
- `icons.md` - 图标用法
- `base-vs-radix.md` - 基础库 API 差异

### 测试 (evals/)
- `evals.json` - 验证用例

### 排除的上游目录
- `agents/` - OpenAI 特定的 agent 接口
- `assets/` - OpenAI 特定的图标资源

## 同步方法

使用 `frontend/scripts/sync-shadcn.sh` 脚本进行同步:

```bash
# 检查更新
./frontend/scripts/sync-shadcn.sh --check

# 同步所有文件
./frontend/scripts/sync-shadcn.sh

# 强制同步
./frontend/scripts/sync-shadcn.sh --force
```

## 注意事项

- 脚本使用 `git sparse-checkout` 同步整个目录，自动处理新增/删除文件
- 本地 `SYNC.md` 不会被上游覆盖
- 本地修改会在同步时被覆盖（其他文件）
- 脚本会自动创建备份到 `.backup/` 目录
- 使用 `--no-backup` 选项可跳过备份
- `agents/` 和 `assets/` 目录为 OpenAI 特定内容，已自动排除
