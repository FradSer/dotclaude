# Retrospective Event Stream — Current Status

> 状态参考文档。压缩自已删的 `plans/2026-05-12-unified-retro-events-design/`、
> `2026-05-12-unified-retro-events-plan/`。

## 演进史

**2026-05-12 原设计**：4-helper 层
- `lib/retro-events.sh`（shared core）+ 3 wrapper：`observations.sh`、`evolution-log.sh`、`skill-events.sh`
- 迁移 2 个 SKILL.md 内联 bash block，在 systematic-debugging Phase 4 加 `fix_completed` emission
- commit `069f16b` 实现

**2026-05-21 演进**：commit `985e871`（`feat(sp): add pretooluse hook and unify logging`）把 4 文件
全部删除，合并为单一 `superpowers/lib/jsonl-emit.sh` 调度器。原 4-helper 架构不再存在。

## 现状

`superpowers/lib/jsonl-emit.sh` 是统一的 NDJSON 通道 writer。retrospective SKILL.md 调：

```
bash "${CLAUDE_PLUGIN_ROOT}/lib/jsonl-emit.sh" <channel>=evolution-log ...
```

`docs/retros/evolution-log.jsonl` 是 retrospective 的唯一 watermark 源——
Phase 1 step 5 用它做 re-proposal guard（避免重复加已移除 item），Phase 5 closure 写
`retrospective_run` watermark。`plans-completed.jsonl` 至今缺失（每个 retro 都记一笔），
evolution-log 是唯一 watermark。

## 关键产物

- `superpowers/lib/jsonl-emit.sh` — 统一 NDJSON 通道 writer
- `docs/retros/evolution-log.jsonl` — 事件 log / watermark（运行时状态，retrospective 读写，勿删）
- `superpowers/skills/retrospective/SKILL.md` — 调用点

## 与原设计差异

原设计把通道写作逻辑分散在 4 个 helper 文件，每个 channel 一个 wrapper。8 天后实践发现 4 文件
均为薄包装，合并为单 `jsonl-emit.sh` 用 `<channel>=<name>` 参数区分更简。功能（统一 NDJSON 发射）不变，形态简化。
