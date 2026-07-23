# Frontend Skills 同步说明

v0.6.0 slim-down 后，本插件只保留原创集成层。`design-md` 是唯一仍接入 sync 体系的 skill（缓存上游 spec 作审计参考；SKILL.md 为本地自定义）。其余镜像 skill（`impeccable` / `shadcn` / `react-best-practices` / `web-design-guidelines` / `supabase` / `supabase-postgres-best-practices`）已删除，用户直装上游 repo。

## design-md

- **上次同步**: 2026-07-16
- **仓库**: [google-labs-code/design.md](https://github.com/google-labs-code/design.md)
- **路径**: `skills/design-md/references/`（仅缓存上游 spec 作为审计参考；`SKILL.md` 为本地自定义集成，不由 sync 管理）
- **同步脚本**: `./frontend/scripts/sync-design-md.sh`
- **说明**: 同步上游 `docs/spec.md` → `upstream-spec.md` 和 `README.md` → `upstream-README.md`。`SKILL.md` 不会被覆盖；当 `spec.md` 变更时，脚本会提示人工比对 `SKILL.md` 的内联 schema / section 顺序 / lint 规则表是否仍然一致（上游版本为 `alpha`，期待破坏性变更）。

## 常用命令

```bash
# design-md spec
./frontend/scripts/sync-design-md.sh --check
./frontend/scripts/sync-design-md.sh

# 引用完整性独立校验(也在每次 sync 收尾自动运行)
./frontend/scripts/check-references.sh

# cross-skill 一致性校验
./frontend/scripts/check-coherence.sh
```

## 同步体系约定

- **`scripts/lib/sync-common.sh`** — 共享 lib。`--check` 优先比对「当前上游 vs 上次同步快照」（`.sync-snapshots/<key>.manifest`，随仓库提交），而非「本地 vs 上游」。design-md 是全量 clone 且无本地改动，不接入快照。
- **`scripts/check-references.sh`** — 扫描所有 `SKILL.md` 的 `reference/*.md` 链接是否解析；每次 sync 收尾自动运行（死链不阻断同步,仅告警）。
- **`scripts/check-coherence.sh`** — cross-skill 一致性校验（v0.6.0 后只剩断言 4：coordinator 引用的 skill ID 都在 plugin.json 注册）。

## 已删除的镜像 skill（迁移参考）

| 删除的 skill | 上游 repo | 安装方式 |
|---|---|---|
| `impeccable` | [pbakaus/impeccable](https://github.com/pbakaus/impeccable) | 直装上游 repo |
| `shadcn` | [shadcn-ui/ui](https://github.com/shadcn-ui/ui) | 直装上游 repo |
| `react-best-practices` | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) | 直装上游 repo |
| `web-design-guidelines` | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) | 直装上游 repo |
| `supabase` | [supabase/agent-skills](https://github.com/supabase/agent-skills) | 直装上游 repo |
| `supabase-postgres-best-practices` | [supabase/agent-skills](https://github.com/supabase/agent-skills) | 直装上游 repo |
