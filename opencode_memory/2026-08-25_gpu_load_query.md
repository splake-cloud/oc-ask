# 2026-08-25 — Querying the GPU directly for what is loaded

Narrow card: the exact commands to ask the driver (not a process list) which
cards are occupied and by which model.

## The commands

Which process holds each card:
```bash
nvidia-smi --query-compute-apps=gpu_uuid,pid,used_memory,process_name --format=csv
```

Per-card totals:
```bash
nvidia-smi --query-gpu=index,name,memory.used,memory.total,utilization.gpu --format=csv
```

Model identity (nvidia-smi cannot answer this — join PID to cmdline):
```bash
nvidia-smi --query-compute-apps=pid,used_memory --format=csv,noheader \
  | while IFS=, read pid mem; do
      echo "$pid $mem $(tr '\0' ' ' < /proc/$pid/cmdline | cut -c1-200)"
    done
```

## Gotchas (each cost a wrong read)

- **The driver knows PID and bytes, never the model.** Model identity lives only
  in the process cmdline. Any "what is loaded" answer is a join, not a query.
- **vLLM's GPU-holding process renames itself `VLLM::EngineCore`** via prctl, so
  its own `/proc/<pid>/cmdline` carries no model path. Walk up:
  `ps -o ppid= -p <pid>`, then read the parent's cmdline (the parent has
  `vllm serve <model-path> --served-model-name ...`).
- **`--query-compute-apps` returns `gpu_uuid`, not index.** For the index→PID
  mapping use plain `nvidia-smi`, or add `gpu_bus_id`.
- **`pgrep -c -f vllm` self-matches** the shell running it (its own cmdline
  contains the pattern), so the count is unstable and reads 1 high. Use
  `pgrep -f '[v]llm'`, or enumerate with `-a` and inspect.
- **0% utilization is not a free card.** All three cards below were idle-resident
  at probe time. Per CLAUDE.md's GPU-active hard stop, an active compute PROCESS
  holding memory means OCCUPIED — no eviction/launch without PM permission.

## Observed state 2026-08-25 ~10:35Z (example output)

| GPU | Mem used / total | What |
|---|---|---|
| 0 | 41.6 / 97.9 GiB | `qwen3.6-35b-a3b-q8` — llama-server PID 15592, `-c 262144` |
| 1 | 5.3 / 97.9 GiB | RAG `small_service.py` on `:8765` (`--device gpu1`), PID 2729 |
| 2 | 92.4 / 97.9 GiB | `qwen3.8-27b-fp8` — vLLM `:8011`, engine PID 15681, parent 15358 |

Cards are `NVIDIA RTX PRO 6000 Blackwell Max-Q`, 97887 MiB each.

## See also

- `2026-08-24_gpu2_slot_inspection.md` — why an nvidia-smi-anchored call gives
  reliable HOST vantage (a call built only from sandboxable primitives can run
  isolated and return false "port free / server down" negatives).
