# Qwen 3.8 Instruct GPU2 seat on :8081

Session: `01a15e58-f7ad-74a0-ada8-e32fbe0d90e0` (Codex, GPT-6, `/data/agentic_trading`), 2026-10-21 UTC.

## Built and activated

- Launcher: `/data/agentic_trading/scripts/launch_qwen38_27b_fp8_instruct_gpu2.sh` (new executable, currently untracked). GPU2, port 8081, served ID `qwen3.8-27b-fp8-instruct`, context 196608, utilization 0.70, FP8 KV, MTP k=1, no-thinking chat default. Qwen coder delegate authored and edited it; full normal-path/fail-closed checks have `/tmp/verify_runs/q38_gpu2_harness_*.log` receipts.
- Authorized swap: stopped `qwen36-coder.service` after matching its MainPID 1678431 to the host `127.0.0.1:8081` port owner. Started Qwen 3.8 through transient user unit `qwen38-instruct-gpu2.service` (MainPID 2136180); engine PID 2136844 on GPU2. RAG PID 1250749 stayed on GPU2 and `127.0.0.1:8765`.
- Live proof: `/v1/models` on :8081 returned the true served ID. A chat completion returned exactly `GPU2 READY` with `reasoning:null`. RAG `/health` returned `ok:true`, and `scripts/rag-search` succeeded after the swap. Startup log: `/data/agentic_trading/logs/qwen38_instruct_8081_20261021T140516Z.log`.

## Limits and next actions

- The unit is transient. On reboot, the enabled Qwen 3.6 unit would start and the Qwen 3.8 unit would not. Permanent boot routing was not requested or changed.
- OpenCode and the existing Pi `jett-8081`/`qwen-coder` entries still request the old 3.6 ID. The direct Pi TUI entry below uses the true served ID; model identity matters at the port.
- vLLM warned that FP8 KV attention used scale 1.0 without calibrated q/prob scale factors; quality impact remains unmeasured. Log also reported 34.45 GiB available KV cache and 983,040 cache tokens after profiling.
- No repository commit or push was requested.

## Direct Pi TUI entry (later in this session)

- Added `jett-8081-instruct` to `/data/agentic_trading/.pi/models.json`, preserving the old `jett-8081` entry and the preexisting `eval-8911` entry. PM can select `jett-8081-instruct / qwen3.8-27b-fp8-instruct` with `/model` in a new Pi TUI session. It advertises 196608 context, 24000 max output, temperature 0.7, top_p 0.8, and reasoning off.
- Pi model-list receipt: `/tmp/verify_runs/q38_pi_registry_model.log`; corrected normal Pi smoke receipt: `/tmp/verify_runs/q38_pi_instruct_live_smoke2.log` (session `01a15f39-91b4-77cb-a53c-8dd66aa798e6`, actual prompt `2+2?`, response `4`, provider/model recorded as `jett-8081-instruct/qwen3.8-27b-fp8-instruct`).
- First smoke receipt `/tmp/verify_runs/q38_pi_instruct_live_smoke.log` is invalid for behavioral assessment: `scripts/verify-run` expands unquoted `$@`, splitting a multiword prompt so Pi received only `Reply`. That led to repeated reads; the session was stopped. Corrected with a single-token prompt.
- This registry edit changes the hash pinned for `.pi/models.json` by `docs/methodology_condition_a_freeze_2026-10-21.json`; that candidate-integrity check will fail until the PM review package is intentionally revised. No Condition-A study run was launched.
- No OpenCode config changed, and no repository commit or push requested.

## Pi Instruct verification mandate

- Added `/data/agentic_trading/.pi/extensions/qwen38-instruct-verification.ts`. It attaches clause-walk, per-claim evidence, independent-observable, live-state, and UNRESOLVED rules only when Pi's current model is `jett-8081-instruct/qwen3.8-27b-fp8-instruct`. The llama.cpp grammar clamp was not applied. New Pi sessions auto-load the extension.
- Fresh normal Pi Instruct run `/tmp/verify_runs/q38_instruct_mandate_live.log` (session `01a15f63-ac14-764c-b019-71be7c8733b1`) had exactly one mandate marker in its system prompt and answered `2+2?` with `4`. Separate :8011 run `/tmp/verify_runs/q38_instruct_mandate_control.log` had zero markers. The four-case hook gate (undefined model, wrong ID, wrong provider, exact match, each called twice) passed in `/tmp/verify_runs/q38_instruct_mandate_gate_final.log`.
- The first hook-gate invocation failed to parse because `scripts/verify-run` splits an argument containing spaces; the corrected single-token script passed. Delegate created an extra `node_modules/@earendil-works` symlink to run typecheck; it was removed after review. An inaccurate opening comment was corrected.
- No repository commit or push requested; Condition-A candidate manifest and AGENTS.md were not edited.
