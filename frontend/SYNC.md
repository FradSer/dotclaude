# Frontend Skills 同步说明

每个 section 维护独立 `**上次同步**` 时间戳，由对应 sync 脚本自动更新。

## shadcn

- **上次同步**: 2026-06-20
- **仓库**: [shadcn-ui/ui](https://github.com/shadcn-ui/ui)
- **路径**: `skills/shadcn/`
- **同步脚本**: `./frontend/scripts/sync-shadcn.sh`
- **说明**: 使用 sparse checkout 同步目录内容，自动排除 `agents/`、`assets/`，并保留本地 `.backup/`。

## impeccable

- **上次同步**: 2026-06-20
- **仓库**: [pbakaus/impeccable](https://github.com/pbakaus/impeccable)
- **路径**: `skills/impeccable/`（单一 skill）
- **同步脚本**: `./frontend/scripts/sync-impeccable.sh`
- **说明**: 上游自 v3.6.0 起为**单一 `impeccable` skill**（各命令合并为 `reference/<cmd>.md`）。本地不再拆分 `impeccable-*` 子技能（2026-06-16 已删除 17 个孤立目录，回归单 skill）。sync 像其他 skill 一样**整体覆盖**目录（含 SKILL.md），上游 SKILL.md 另存为 `reference/upstream-SKILL.md`。
- **SKILL.md 机制**: **追随上游原文,无 curated 重放**（2026-06-16 起,按「所有内容以上游为优先」)。sync 覆盖进来的上游 `SKILL.md` 即最终版,`modifications/impeccable.md` 不含可重放块（replay 计数为 0,脚本不再提示重放）。`reference/upstream-SKILL.md` 与 live `SKILL.md` 同源,留作 pristine 快照供 diff。收尾的 `check-references.sh` 校验 reference 链接解析。**已知局限**: 上游 SKILL.md 里 5 处 `node .claude/skills/impeccable/scripts/*.mjs` 路径在 plugin 安装后不解析(脚本优雅降级),详见 `modifications/impeccable.md` 的取舍选项 A/B/C（2026-06-20 落地 Option A + 本地 `PLUGIN-INSTALL-NOTES.md` 文档补充,sync wipe 时保留该文件）。
- **anti-patterns（已退役）**: 上游从未存在独立 `anti-patterns.md`（仓库 code search = 0、git history = 0）。规则权威源为两处，均随 skill 整体同步：(a) `skills/impeccable/SKILL.md` 的 `### Absolute bans`（8 条文字 ban）；(b) `skills/impeccable/scripts/detector/registry/antipatterns.mjs`（~40 条可执行规则，注意是 `registry/` 不是 `engines/`）。本地 frozen `agents/references/anti-patterns.md` 已于 2026-06-20 删除，`frontend-anti-patterns` agent 改为指向上游两处权威源；`sync-impeccable.sh` 的 anti-patterns agent 步骤已改 no-op，不再每轮报「上游未找到」。
- **本地非同步补充文件（sync wipe 时保留,2026-06-20 P1-b Option B）**: `skills/impeccable/PLUGIN-INSTALL-NOTES.md`（插件布局脚本路径 caveat + 解析配方）、`skills/impeccable/AUDIT-AUTHORITY.md`（四权威 evidence-type 对账阶梯）。二者上游不存在,sync-impeccable.sh wipe 时显式 skip。`hooks/design-md-first.sh`（UserPromptSubmit hook,cwd 有 DESIGN.md 时注入 design-md-first + token authority ladder preamble）。

## react-best-practices

- **上次同步**: 2026-06-16
- **仓库**: [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills)
- **路径**: `skills/react-best-practices/`
- **同步脚本**: `./frontend/scripts/sync-vercel-skills.sh`
- **说明**: 同步后脚本会重写 SKILL.md `name:` 字段为 `react-best-practices`，匹配目录名（上游原名是 `vercel-react-best-practices`）。

## web-design-guidelines

- **上次同步**: 2026-06-16
- **仓库**: [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills)
- **路径**: `skills/web-design-guidelines/`
- **同步脚本**: `./frontend/scripts/sync-vercel-skills.sh`

## supabase

- **上次同步**: 2026-06-16
- **仓库**: [supabase/agent-skills](https://github.com/supabase/agent-skills)
- **路径**: `skills/supabase/`
- **同步脚本**: `./frontend/scripts/sync-supabase-skills.sh`

## supabase-postgres-best-practices

- **上次同步**: 2026-06-16
- **仓库**: [supabase/agent-skills](https://github.com/supabase/agent-skills)
- **路径**: `skills/supabase-postgres-best-practices/`
- **同步脚本**: `./frontend/scripts/sync-supabase-skills.sh`

## design-md

- **上次同步**: 2026-06-16
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

# 引用完整性独立校验(也在每次 sync 收尾自动运行)
./frontend/scripts/check-references.sh
```

## 同步体系约定

- **`scripts/lib/sync-common.sh`** — 共享 lib。`--check` 优先比对「当前上游 vs 上次同步快照」（`.sync-snapshots/<key>.manifest`，随仓库提交），而非「本地 vs 上游」。本地有 modifications 重放的源（shadcn / vercel / impeccable）因此不再永远误报「有更新」。无快照时回退旧的本地比对（首次 sync 后建立快照基线）。design-md 是全量 clone 且无本地改动，不接入快照。
- **`scripts/check-references.sh`** — 扫描所有 `SKILL.md` 的 `reference/*.md` 链接是否解析；每次 sync 收尾自动运行（死链不阻断同步,仅告警）。上游删除/重命名 reference 文件造成的死链会当场暴露。
- **`modifications/*.md`** — 所有「sync 覆盖后需重放的本地改动」的唯一声明式来源（react-best-practices / shadcn / impeccable）。sync 脚本打印 replay 提示;让 Claude 读对应文件重新应用。
