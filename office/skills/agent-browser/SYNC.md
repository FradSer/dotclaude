# Agent-Browser Skill 同步说明

## 上游仓库

- **仓库**: [vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser)
- **路径**: `skills/agent-browser/`
- **上次同步**: 2026-01-25

## 同步内容

此 skill 从上游仓库同步,包含以下文件:

### 核心文件
- `SKILL.md` - 主技能文档

### 参考文档 (references/)
- `authentication.md` - 认证模式
- `proxy-support.md` - 代理支持
- `session-management.md` - 会话管理
- `snapshot-refs.md` - 快照引用
- `video-recording.md` - 视频录制

### 模板脚本 (templates/)
- `authenticated-session.sh` - 认证会话模板
- `capture-workflow.sh` - 捕获工作流模板
- `form-automation.sh` - 表单自动化模板

## 同步方法

使用 `office/scripts/sync-agent-browser.sh` 脚本进行同步:

```bash
# 检查更新
./office/scripts/sync-agent-browser.sh --check

# 同步所有文件
./office/scripts/sync-agent-browser.sh

# 强制同步
./office/scripts/sync-agent-browser.sh --force
```

## 注意事项

- 本地修改会在同步时被覆盖
- 脚本会自动创建备份到 `.backup/` 目录
- 使用 `--no-backup` 选项可跳过备份
