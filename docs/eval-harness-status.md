# Eval Harness — Current Status

> 状态参考文档。压缩自已删的 `plans/2026-04-01-harness-optimizations-plan/`、
> `2026-04-03-eval-harness-design/`、`2026-04-04-eval-harness-plan/`。

## 当前架构

评估系统独立于生成器，外化主观判断为可执行测试。

```
Subsystem A — 验证评估（executing-plans Phase 3f，每 batch）
  → superpowers-evaluator (sub-agent, 受限工具)
      design mode: 套用 design-v{N}.md 二元 checklist → PASS/FAIL per item
      plan mode:   套用 plan-v{N}.md 二元 checklist   → PASS/FAIL per item
      code mode:   独立运行 task 验证命令 → exit code → PASS/FAIL per task
  ← 返回: checklist 结果表 + rework items（无评分）

Subsystem B — 计划内学习（Phase 4 增强）
  读当前 plan 所有 evaluation report → 识别跨 2+ batch 失败的 checklist item
  → 注入 pattern context 到下个 batch sprint contract preamble

Subsystem EVO — checklist 演进信号
  3+ batch 失败 / 2+ rework round 才 PASS → 标记 "evolution candidate"（信息性，不自动改 checklist）
```

## 核心原则

**二元 PASS/FAIL 替代 1-5 rubric 评分。** LLM 评分会漂移（同一 artifact 两次评分可能不同）；二元判断不漂移："这个 import 是否跨层"与模型怎么想无关。"Architecture Soundness: 3/5" 给生成器无从下手；"[FAIL] architecture.md 描述 domain service import infra 层" 给出生成器确切要改什么。

**评估器独立运行验证命令，从不信任生成器自报结果。** code mode ground truth 是 exit code，design/plan mode 是二元 checklist。

**checklist 演进手动 git 版本化。** item 加/改/删时版本号递增，prior 版本文件保留不删。

## 关键产物

| 产物 | 位置 |
|---|---|
| Evaluator agent | `superpowers/agents/superpowers-evaluator.md` |
| Binary checklists | `docs/retros/checklists/{design,plan,code}-v{N}.md` |
| Sprint contracts | `docs/plans/*-plan/sprint-contract-batch-{N}.md` |
| Evaluation reports | `docs/plans/*-plan/evaluation-round-{N}-batch-{M}.md` |
| Handoff summaries | `docs/plans/*-plan/handoff-summary-{N}.md` |
| Event log | `docs/retros/evolution-log.jsonl` |

## checklist type 标注

每个 checklist item 标注 `computational`（grep/exit code/图遍历，确定性）或
`inferential`（需评估器语义判断，附显式 check method 锚定，减少但不消除观察者变异）。
v1 标注是 v2 多次试验协议测量 inferential agreement 率的前置条件。

## 历史注记

原 harness-optimizations-plan README 标 `implemented:cd29fd7`，但 `cd29fd7` 实为小 refactor；evaluator/sprint-contract/handoff 真实落地跨 `f68d6df`/`9a8dcaf`/`d2ebbd8` 等提交。工作真实存在，SHA 不准。
