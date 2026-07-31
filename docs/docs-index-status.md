# Docs Index Convention — Current Status

> 状态参考文档。压缩自已删的 `plans/2026-07-04-docs-index-design/`、
> `2026-07-04-docs-index-plan/`。

## 当前架构

`superpowers/lib/docs-index.sh`（~900 行）维护单一 `docs/README.md` 管道表索引，
四个 skill（brainstorming、writing-plans、executing-plans、retrospective）在开工前
consult、提交后 upsert。回答"哪些 design/plan/retro artifact 存在、是否仍权威"。

## 五子命令

| 子命令 | 作用 |
|---|---|
| `list` | 列索引行，可 `--kind`/`--status` 过滤 |
| `show` | 显示单行详情 |
| `upsert` | 幂等插入或更新行（kind/path/status/summary） |
| `set-status` | 翻转单行 status |
| `rebuild` | 以文件系统为真相重建表，保留已知 status/summary |

## 受控 status 词表（6 值）

| status | 含义 |
|---|---|
| `wip` | 进行中草稿 |
| `active` | 当前权威，"consult me" |
| `implemented:<sha>` | 已发布（SHA 入 status，可审计） |
| `superseded-by:<path>` | 被后继替代（路径入 status，可导航） |
| `expired:<reason>` | 历史存在但不应再信赖（reason 必填，可审计） |
| `reference` | 常青参考（如 `docs/writing-skills/`） |

未知 status 值在 `upsert`/`set-status` 时 exit 2、不写。`kind` 同样受控：
`design|plan|retro|memory`（见 `docs/memory-layer-status.md`）。

## anti-bloat

- **folder 级条目**（非 per-file）：一个 design 文件夹 4+ 文件，per-file 会 5-10× 行数无导航价值；folder 路径是 click target，folder 自身 `_index.md` 是 per-file 目录。
- **60 行硬上限** + 二阶段塌缩：先合并 ≥3 同 status/topic 行；仍超预算则整行丢弃 `expired` 行（其 tombstone 保留在 expire 它的 retro 里）。
- **每行单物理行**，按 path 排序，diff-friendly（`git diff docs/README.md` 读作 append 或单行 status 翻转）。

## consult-before / upsert-after 触点

每个 in-scope skill 在入口跑 `list`，在提交同 commit-group 跑 `upsert`（CRITICAL，不可 defer——索引翻转与实现改动同提交，revert 同 revert）。

retrospective 可通过 retro 报告里 grep-able 的 `invalidates: <path>` 行把前序条目标
`expired:<reason>` 而不重写前序文档文件本身——索引行 mutate，历史 artifact 不动。

## 关键产物

- `superpowers/lib/docs-index.sh` — 调度脚本
- `docs/README.md` — 索引表

## 注意

`repo_root()` fallback 在 plugin 自开发时（`CLAUDE_PROJECT_DIR` unset）会静默定位到父 repo，见 `docs/memory/pitfall_repo-root-claude-project-dir.md`。
