# 2026-09-05 — Qwen 3.8 dual-instance GPU topology + systemd boot units

**Why this card:** topology was verified live on 2026-09-05. Both 3.8 instances are now
managed by systemd units (`qwen38-seat.service` on gpu0, `qwen38-delegate.service` on gpu1).
RAG runs on gpu2 alongside qwen3.6. The previous card (2026-09-04) had the ports swapped
between gpu1/gpu2 and placed RAG on gpu1 — both incorrect.

## Topology (verified 2026-09-05, `nvidia-smi` + `/proc/<pid>/cmdline` + `systemctl`)

| GPU | Memory | Resident | Port |
|---|---|---|---|
| gpu0 | 91.6 / 97.9 GiB | **qwen3.8-27b-fp8** (vLLM, systemd `qwen38-seat.service`, temp 1.0) | :8011 |
| gpu1 | 89.9 / 97.9 GiB | **qwen3.8-27b-fp8** (vLLM, systemd `qwen38-delegate.service`, temp 0.8) | :8012 |
| gpu2 | 75.7 / 97.9 GiB | RAG (34 GiB) + qwen3.6 llama-server (41.6 GiB) | :8765 / :8081 |

RAG = `scripts/rag_verifier/small_service.py` on **:8765**, `--device gpu2` → runs
entirely on gpu2 (PID 2731, 34,080 MiB). `verifier-rag-small.service` is **inactive** —
the RAG is running outside systemd.

qwen3.6 = llama.cpp `ik-llama-server.service` on **:8081** (PID 3921, 41,566 MiB).

Both 3.8 instances serve `qwen3.8-27b-fp8`, `max_model_len 262144`, healthy (curl
`/v1/models` OK on both ports).

## Systemd units (verified 2026-09-05, both enabled + active)

**gpu0 — qwen38-seat.service** (`:8011`, temp 1.0, non-coder/author lane):
```
# /home/user/.config/systemd/user/qwen38-seat.service
Environment=TEMP=1.0
Environment=PORT=8011
Environment=GPU=0
ExecStart=/bin/bash /data/agentic_trading/scripts/launch_qwen38_27b_fp8.sh
```

**gpu1 — qwen38-delegate.service** (`:8012`, temp 0.8, coder lane):
```
# /home/user/.config/systemd/user/qwen38-delegate.service
Environment=TEMP=0.8
Environment=PORT=8012
Environment=GPU=1
ExecStart=/bin/bash /data/agentic_trading/scripts/launch_qwen38_27b_fp8.sh
```

Both call the same launcher script (`launch_qwen38_27b_fp8.sh`), which is the single
source of truth for ctx, util, KV dtype, MTP, prefix caching and parsers. The launcher
pins the card via `CUDA_VISIBLE_DEVICES="$GPU"` — the systemd `GPU=` env var drives that.

## Boot layout (PM 2026-09-05)

- gpu0 = qwen3.8 seat (:8011, temp 1.0)
- gpu1 = qwen3.8 delegate (:8012, temp 0.8)
- gpu2 = RAG (:8765) + qwen3.6 llama-server (:8081)

`ik-llama-server.service` is **DISABLED** (not deleted) — re-enable to go back:
```
systemctl --user disable qwen38-seat qwen38-delegate && systemctl --user enable ik-llama-server
```

## Failure mode

Piping the launcher through `head -20` (or any foreground pipe from a shell tool) closes
the pipe / ends the tool's process group and **evicts the model mid-load**. Same class as
the `nohup ... &` tool-timeout kill documented in
`2026-08-24_qwen36_262k_restart.md`. Rule: long-running launches get `setsid` +
`</dev/null` + redirect to a file, never a foreground pipe.

## Facts

- Both 3.8 instances are **systemd-managed** (enabled, active since boot). No manual
  restore needed after reboot.
- `Restart=no` on both units: a crash does NOT self-heal. This is deliberate — gpu0/gpu1
  are cards the PM reallocates by hand.
- Load-bearing flags: `--enable-prefix-caching` (29.5 s → 2.3 s/turn at 100k context,
  hit ~90%) and fp8 KV. Evidence: `docs/model-kb/QWEN38_27B_FP8_CANDIDATE_NOTE.md`.
- The launcher's default is `GPU=2`; both systemd units override this (`GPU=0` and
  `GPU=1`) because the default no longer matches the boot layout.
