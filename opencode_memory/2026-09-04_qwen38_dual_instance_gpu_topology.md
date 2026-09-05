# 2026-09-04 — Qwen 3.8 dual-instance GPU topology + durable launch recipes

**SUPERSEDED by [2026-09-05_qwen38_dual_instance_gpu_topology.md](2026-09-05_qwen38_dual_instance_gpu_topology.md).**
This card had the ports swapped between gpu1/gpu2 (gpu1=:8012 was wrong; gpu2=:8011 was wrong)
and placed RAG on gpu1 (RAG is on gpu2). The 2026-09-05 card has the verified topology.

**Why this card was created (and superseded):** a session launched a second qwen3.8 instance on
gpu1 (co-resident with RAG) and one was restored on gpu2; PM corrected the topology and the
util assumption. Recipe was pinned from the LIVE process cmdlines so a reboot/downtime could
be restored without re-researching. **Later verification showed the port-to-GPU mapping was
inverted and RAG was on gpu2, not gpu1.**

## Topology (verified 2026-09-04, `nvidia-smi` + `/proc/<pid>/cmdline` + `curl`)

| GPU | Memory | Resident | Port |
|---|---|---|---|
| gpu0 | 41.6 / 97.9 GiB | qwen3.6-35b-a3b-q8 (llama.cpp, `ik-llama-server.service` boots the 397B tri here on reboot) | :8081 |
| gpu1 | 93.2 / 97.9 GiB | **qwen3.8-27b-fp8** (vLLM) + RAG shard | :8012 |
| gpu2 | 94.8 / 97.9 GiB | **qwen3.8-27b-fp8** (vLLM, via launcher script) + RAG shard | :8011 |

RAG = `scripts/rag_verifier/small_service.py` on **:8765**, `--device split-auto` → it
holds ~1.85 GiB on gpu1 and ~2.37 GiB on gpu2 (PM shorthand: "co-resident on gpu1"; the
split puts a shard on both 3.8 cards). `verifier-rag-small.service` is **inactive** — the
RAG is running outside systemd (restarted manually; it had deactivated ~00:57Z which
coincided with a qwen3.8 EngineCore shutdown earlier that morning).

Both 3.8 instances serve `qwen3.8-27b-fp8`, `max_model_len 262144`, healthy (curl
`/v1/models` OK on both ports).

## Durable recipes (captured verbatim from live processes)

**gpu2 (dedicated) — the script's bare defaults ARE this slot.**
```bash
cd /data/agentic_trading && setsid nohup bash scripts/launch_qwen38_27b_fp8.sh \
  > logs/qwen38_launch_wrapper.log 2>&1 < /dev/null & disown
```
Expands to `vllm serve /data/models/qwen3.8-27b-fp8 --served-model-name qwen3.8-27b-fp8
--max-model-len 262144 --max-num-seqs 8 --max-num-batched-tokens 16384 --kv-cache-dtype
fp8 --gpu-memory-utilization 0.90 --speculative-config '{"method":"mtp",
"num_speculative_tokens":3}' --enable-prefix-caching --reasoning-parser qwen3
--tool-call-parser qwen3_coder --enable-auto-tool-choice --host 127.0.0.1 --port 8011`
(venv: `/home/user/projects/agentic_trading/.venv-vllm`).

**gpu1 (co-resident with RAG) — manual, NOT in the launcher script:**
```bash
cd /data/agentic_trading && nohup env CUDA_VISIBLE_DEVICES=1 VLLM_NO_USAGE_STATS=1 \
  /home/user/projects/agentic_trading/.venv-vllm/bin/vllm serve /data/models/qwen3.8-27b-fp8 \
  --served-model-name qwen3.8-27b-fp8 \
  --max-model-len 262144 --max-num-seqs 8 --max-num-batched-tokens 16384 \
  --kv-cache-dtype fp8 --gpu-memory-utilization 0.90 \
  --speculative-config '{"method":"mtp","num_speculative_tokens":3}' \
  --enable-prefix-caching --reasoning-parser qwen3 --tool-call-parser qwen3_coder \
  --enable-auto-tool-choice --host 127.0.0.1 --port 8012 \
  > /data/agentic_trading/qwen38_gpu1.log 2>&1 &
```

**The util-0.90 correction (PM: "i thought util was closer to 0.9") — confirmed:**
BOTH instances run `--gpu-memory-utilization 0.90`. The launcher header's "co-resident
slot ceiling 0.40–0.4452, NOT reproducible from this file" applies ONLY when the co-tenant
is the ~53 GiB 397B tri-card (43,579 free / 97,887 total = 0.4452). With the small RAG
(≤2.4 GiB/card) as co-tenant, 0.90 × 97.9 ≈ 88 GiB + RAG ≈ 94 GiB fits fine — the
"no longer reproducible" warning does not apply to this topology. Chunk is 16384 on both
instances, matching the script's hardcoded value (so the gpu1 command could be folded
into the launcher with `GPU=1 PORT=8012` env overrides + the log path).

## Failure mode re-confirmed (this session's incident)

Piping the launcher through `head -20` (or any foreground pipe from a shell tool) closes
the pipe / ends the tool's process group and **evicts the model mid-load**. Same class as
the `nohup ... &` tool-timeout kill documented in
`2026-08-24_qwen36_262k_restart.md`. Rule: long-running launches get `setsid` +
`</dev/null` + redirect to a file, never a foreground pipe. This session violated it
once, relaunched correctly.

## Facts

- qwen3.8 has **no systemd unit** (deliberate, PM 2026-08-23) and is **not in
  `llm_swap.py`**'s management plane — reboot/downtake is silent; restore is manual.
- Restore order if 397B owns gpu0 after reboot: `systemctl --user stop
  ik-llama-server.service` (NEVER `llm-alloc evict_gpu` — SIGTERMs every pid on the card),
  then the gpu2 recipe.
- Load-bearing flags: `--enable-prefix-caching` (29.5 s → 2.3 s/turn at 100k context,
  hit ~90%) and fp8 KV. Evidence: `docs/model-kb/QWEN38_27B_FP8_CANDIDATE_NOTE.md`.

## Open / next

- Fold the gpu1 recipe into `launch_qwen38_27b_fp8.sh` (env-overridable GPU/PORT/log) or a
  sibling script, so a reboot restores BOTH instances — PM decision.
- `verifier-rag-small.service` inactive while the RAG runs outside systemd: reconcile
  (enable the unit or note the manual start) — PM decision.
- Two 3.8 instances stretches the launcher's "ONE SEAT" ruling (it says one server / one
  seat); current dual-instance state is a known deviation, not a documented default.
