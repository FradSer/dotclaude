---
name: project_antigravity_plugin
description: antigravity 插件——委托 Google Gemini Managed Agents 的桥接插件；实测 API 事实与已知缺陷清单
type: project
---

`antigravity` 插件（active，commit scope `ag`）：Bridge 型，把任务委托给 Google Gemini Managed Agents 远程沙箱。两个 slash command：`/antigravity:delegate`、`/antigravity:research`。机制：`scripts/antigravity.py`（uv + PEP 723 内联 `google-genai`）经 Bash 调用，detached worker + `wait` 子命令轮询状态文件，skill 用 Monitor 等待。

**实测 API 事实（与调研文档多处不符）：**
- `background` 按 agent 与凭据路径双重决定：deep-research agent 两条路径都要求 `background=True`；antigravity agent 在 Developer API 拒绝 `background`（同步阻塞），在 Vertex 则**要求** `background=true`（否则 400 `Agent interactions must set background to true.`）
- `environment.network` 枚举是 `"disabled" | {allowlist:[...]}`。省略该字段 = 开放
- worker 里 `get()` 不传 timeout 会被服务端长轮询阻塞 → 必须 `get(timeout=60)` + 重试
- 真实 agent ID：`antigravity-preview-05-2026`、`deep-research-preview-04-2026`、`deep-research-max-preview-04-2026`（`--max`）
- `Interaction.status` 是 7 值 Literal：活跃态 `in_progress`/`requires_action`；终态 `completed`/`failed`/`cancelled`/`incomplete`/`budget_exceeded`
- 当前 SDK 版本 2.25.0（pin 是 `>=2.25.0`，已是 PyPI 最新；`>=` floor 是刻意选择，靠升级后重验兜底）
- 两条凭据路径：`vertex`（ADC + `ANTIGRAVITY_PROJECT`/`ANTIGRAVITY_LOCATION`，路由到 `aiplatform.googleapis.com/v1beta1/.../interactions`）与 `api-key`（Developer API）；`ANTIGRAVITY_AUTH` 选择，`auto` 在 Vertex 配齐时优先 Vertex
- **`interactions.create()` 最近返回 401 `ACCESS_TOKEN_TYPE_UNSUPPORTED`**——改本插件前必须先确认上游还活着

**已知 HIGH 缺陷（2026-08-04 反思确认，2026-09-26 逐条复核）：**
1. ~~无 liveness 检测~~ 已修（2026-09-26）：原代码只查 `worker.pid` 里 pid 是否存活，漏两个洞——① worker 在写 pid 之前就死掉（目录里没有 pid 文件）→ 永远卡在 running；② pid 被无关进程回收后 `os.kill(pid,0)` 判定存活 → 永远卡在 running。现按 run id 做身份校验（worker argv 含 `<run_id>`），无 pid 文件则超过 `WORKER_START_GRACE=120s` 判定死亡；命令列读不到时信任 pid（宁可等也不误报失败）
2. ~~`extract_result` 只取最后一个 model_output 段~~ 已修（2026-09-26 实测）：现按流式片段无分隔符拼接全部 model_output，并只丢弃「与上一步非 model_output 之后累积文本完全相等」的服务端重发段。注意：**SDK 的 `interaction.output_text` 只给最后一条消息**（其 `_populate_output_helpers` 遇到非 model_output 就停），所以不能直接用它取多段报告
3. ~~Monitor timeout 与 wait timeout 相等~~ 已修（写在 skill 里，非代码）：delegate `--timeout 900` / Monitor `1800000`，research `--timeout 1800` / Monitor `3600000`，均为 2× 关系
4. ~~Monitor-re-arm 无限次~~ 已修：两个 skill 都限制四次连续 timeout 后改为交付 `status --full` 命令并停止

**How to apply:** 改本插件前先 live probe 确认上游活着并按实测事实核对；API 仍 Pre-GA，升级 google-genai 后需重验。修复清单按上面 HIGH 分组。

**验证手段（2026-09-26 定下，已入库）：** 单元测试 `antigravity/tests/test_antigravity.py`（69 个：凭据解析、请求选项、步骤形状、拼接语义、等待/流式回退、liveness、cleanup、引用提取）；E2E `antigravity/tests/e2e/run.sh`（43 项，真实 Vertex 跑 delegate：沙箱真执行、输出不拆散、工具轨迹、流式进度、成本/模型/分层/标签/JSON 一次覆盖、图片输入、多段输出跨工具调用、沙箱复用与链式续跑、失败传播、CLI 负例、cleanup 三种形态、引用重新渲染、真实 requires_action）。辅助探针同目录：`research_shape.py`（create + `interactions.cancel` 零成本验证深研形状）、`render_check.py <run-id> [--write]`（离线重渲染已存交互）、`requires_action.py`。

**本机环境陷阱（写脚本时会踩）：** ① `CDPATH` 已设（`.:/Users/FradSer:...`），bash 的 `cd` 命中时**会把目录 echo 出来**，污染 `$(cd ... && pwd)`——脚本开头要 `unset CDPATH` 并读 `$PWD`。② Google 域名经 TUN + fake-IP 代理，会间歇性 TLS 失败（`SSL_ERROR_SYSCALL` / `UNEXPECTED_EOF` / `ConnectionReset`，通常 5 秒超时）；E2E 因此内置网络预检、传输错误重试，以及网络降级时直接输出 `E2E_RESULT=NETWORK_DEGRADED` 并中止（避免把网络噪声当代码结论）。

**delegate agent 的可靠性：** 会绕过工具凭记忆作答；`--network none` 下 `cat` 返回空输出也照样输出“逐字引用”；复杂格式指令（三段标题）遵从率不稳定（三次里两次不合规）。需要真实检索/严格格式时不要依赖它，应改用 research 或 `--network default`。

**踩过的坑（2026-09-26，已修）：** ① 工具轨迹在 2.25.0 + Vertex 下永远为空——Vertex 把每个工具都报成 `function_call`（工具名在 `step.name`，参数是 dict），而插件只认 `code_execution_call` 等旧名字。② 输出用 `"\n\n"` 拼接流式片段会把文本拆散（`2**64` 变成 `184467440737095516` + `16`）；去重必须用严格相等，用过 `endswith` 会把末尾 `"16"` 静默吃掉。③ **环境复用只有裸字符串形式有效**：配置对象里带 `id` 或 `environment_id` 都会被服务端接受然后**新建沙箱**，文件全丢却看起来成功。④ 链式续跑必须把 `environment` 和 `previous_interaction_id` 放同一个请求，否则历史带过去了、沙箱没有。

**API 事实（2026-09-26 实测，含 create+cancel 零成本探针）：**
- agent id：`antigravity-preview-05-2026` 可用；文档写的 `antigravity-preview-09-2026` 返回 `404 Agent not found`，最新 google-genai（2.25.0）的 `AgentOption` 也未收录——文档跑在实现前面
- 成本/模型：`agent_config.max_total_tokens` 与 `agent_config.model` **只在 AntigravityAgentConfig**；`DeepResearchAgentConfig` 只有 `collaborative_planning` / `visualization` / `thinking_summaries` / `enable_bigquery_tool`，**深研无法设 token 上限**
- 接受且生效：`system_instruction`、`labels`、`service_tier`（flex 最便宜）、图片内联 base64 输入、`response_format`
- 结构化输出**不要发 `response_mime_type`**：单独发或与 `response_format` 同发都会 400（“responseFormat must be set when responseMimeType is set”），只发 `response_format` 才生效
- 流式：不是 create 参数，而是对已有 background interaction 做 `get(id, stream=True)`，事件为 `interaction.created` / `status_update` / `step.start` / `step.delta` / `step.stop` / `interaction.completed`，Vertex 上可用
- `interactions` 有 `cancel` / `delete` / `get`；`store=True` 是 background、链式、流式的前置条件，保留期付费 55 天 / 免费 1 天
- `mcp_server` 虽在文档工具表里，但 Google 写明 Gemini 3 不支持远程 MCP
- `NetworkEnum = Literal["disabled"]`，省略该字段=允许出网；agent 在 Vertex 上强制 `background=true`
- **深研 agent 不接受 `system_instruction`**（400 "not supported for the deep-research-preview-04-2026 agent"，并提示把要求写进 input）——research 永不发送，`--system` 直接拒绝而不静默改写 query
- **引用在 text content 的 `annotations` 里**（`type=url_citation`，含 `title`/`url`，title 内嵌换行），正文用 `[cite: N]` 指代；插件原本全丢，现渲染为 `## Sources` 并写入 `output.json` 的 `citations`
- 深研实测：75,694 tokens / 120 秒（参考 memory 里 2.13M tokens 的旧记录，成本波动很大，不要拿单次样本估计上限）
- 已存 interaction 可以离线重新提取与渲染（`/tmp/ag-render-check.py <run-id> --write`），不需要重新花钱调用
- 删除生命周期：刚创建的交互 `delete` 会被拒（400 "cannot be deleted in its current state"），已沉淀的拒绝 `cancel`（409）；`404` 视为“已删完”（应剪枝目录而不是无限重试），其他失败保留目录与 interaction id 供重试。两条路径已 live 验证
- `requires_action` 可用**自定义 function 工具**真实触发（agent 约 5 秒后停在该状态），是验证插件快速失败的备用手段


关联：[[feedback_verification]]、[[feedback_claude_code_guide]]