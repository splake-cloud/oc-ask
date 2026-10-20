# Qwen 397B + Qwen 3.8 Instruct: isolated Pi trial design

Session: `01a159bf-41f3-7163-b593-b088b2f0aa42` (Codex, GPT-6, `/data/agentic_trading`), 2026-10-20 UTC.

## Decided and saved

- Trial purpose: Qwen3.5-397B-A17B IQ4_KSS is the Pi lead for harder thinking, semantics, decomposition, integration, and final review. Qwen3.8-27B-FP8 in Instruct/no-thinking mode is the **only delegate**, taking the existing Qwen3.6 coder's BUILD/EDIT/EXPLORE ruleset. Compare the 3.8 delegate with the 3.6 baseline on held-out coding and tool-loop work. No `:8012` judgment tier; a required independent third-model review is unavailable in this trial, not silently replaced by self-review.
- Isolated draft: `/data/agentic_trading/.ai/staging/pi_397b_38_instruct_trial/DESIGN.md`. It contains the proposed Pi provider JSON, separate Pi-home/workspace layout, strict one-delegate routing settings, later load command, RAG choice, and gates. The initial draft under `docs/model-kb/` was moved to staging. Nothing was loaded or evicted, and no live Pi/launcher/service file was edited for this trial.
- Isolation requirement: `~/.pi/agent/models.json` symlinks to `/data/agentic_trading/.pi/models.json`; the Pi subagent extension also discovers project `.pi/agents` from cwd. The later trial must use a separate `PI_CODING_AGENT_DIR`, a separate cwd, `--no-context-files` with explicit binding lead instructions, trial-only sessions, built-in agents disabled, `fallbackSubagent: none`, and nesting depth 1. At activation, verify the Agent tool exposes exactly the one intended custom delegate.

## Evidence and limits

- The recorded 397B split is `25,37,38` across GPU0/1/2 (`scripts/launch_qwen35_397b_tri.sh`). A Qwen3.8 co-resident GPU0 configuration was measured at utilization 0.40, batched tokens 4096, FP8 KV, and MTP k=1 (`docs/model-kb/QWEN38_27B_FP8_CANDIDATE_NOTE.md`); the current launcher hardcodes 16384 batched tokens and k=3, so the draft uses a distinct proposed invocation on `:8013`.
- Small RAG is the capacity baseline. Historical 397B GPU2 allocation 79,400 MiB plus small RAG's measured 5,522 MiB leaves about 12,317 MiB after recorded driver overhead. The live mid RAG process held 18,910 MiB on GPU2 at exploration time, exceeding the recorded GPU2 headroom by 1,071 MiB with that split. A changed split for mid remains untested; the mid unit's older ~10 GiB comment is not a sufficient budget.
- The drafted Pi JSON parsed and both shell blocks passed `bash -n`. There was no actual trial Pi session, model load, simultaneous serving test, or quality comparison. The live `.pi/models.json` appeared modified in the shared working tree by other work; this session did not edit it.

## Next when authorized to test

1. Materialize the separate Pi home/workspace and full lead/delegate instruction files from the staged design; confirm no production agent cards or provider entries are discovered, and unknown delegate names fail closed.
2. Recheck host GPU/port owners and supervisors before any occupancy change. Load the 397B thinking server, the Qwen3.8 Instruct server at the measured co-resident budget, and small RAG; verify actual per-card memory, long prefill, both model tool calls, RAG `/health` plus a real `/search`, and simultaneous busy traffic.
3. Compare the 3.8 delegate with the 3.6 baseline on identical held-out coding/tool-loop tasks. Treat mid RAG as a separate split/placement experiment requiring its own load and serving proof.
