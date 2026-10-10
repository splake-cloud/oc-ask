# 2026-10-10 — gpu2 swap (repeat) + gpu2-swap RAG card made bidirectional

**Seat:** pi / jett-8011 (qwen3.8-27b-fp8)

## What
1. **gpu2 swap — routine, a repeat of the 2026-10-07 card (inverse of 10-09).** Evict ComfyUI → load qwen3.6, RAG preserved.
   - Pre: gpu2 = RAG (pid 284189, `small_service.py :8765`, 12568 MiB, systemd `verifier-rag-mid.service`) + ComfyUI (pid 353373, `main.py :8188`, 34204 MiB, hand-launched tmux-spawn, **no unit**). GPU0/1 = vLLM qwen3.8 (out of scope).
   - Evict = `kill -TERM 353373` (hand-launched → no respawn; **never** the `:8765` RAG pid, never `llm-alloc evict gpu2`). gpu2 46895 → 12578 MiB.
   - Load = `systemctl --user start qwen36-coder.service` → llama-server pid 577863, 43808 MiB, `:8081` serves `qwen3.6-35b-a3b-q8`, smoke inference coherent. RAG `:8765` still `ok:true`.
2. **The actual new work — made the `system_processes` gpu2-swap RAG card bidirectional + trimmed stale facts.**
   - Source: `scripts/rag_verifier/harvest_system_processes.py` (AUTHORED list; slug `evict-model-and-load-comfyui-on-shared-gpu`; title now "Swap the model and ComfyUI on a GPU shared with the RAG (preserve the RAG, either direction)").
   - **Trimmed** the volatile "as of 2026-10-02" live-layout snapshots — per the harvester's own docstring, live "which model is on which port *right now*" belongs in `system_runtime`, not this authored procedure well (and they were wrong when I read them anyway: said ComfyUI NOT running / qwen3.6 UP, both inverted).
   - **Made it bidirectional** (either direction, same skeleton) and **added the load-via-unit step**: qwen36-coder.service's ExecStart = `launch_qwen36_35b_q8.sh --mode coder --no-think --parallel 2`, `CUDA_VISIBLE_DEVICES=2`, `enabled` + `Restart=on-failure` → load the model with `systemctl --user start`, not a raw hand-launch (which is unsupervised and diverges at boot).
   - **Added traps:** (a) never `llm-alloc evict/swap gpu2` — it SIGTERMs *every* card pid incl. the RAG; (e) tailscale's `:8081` proxy listeners (`100.84.x`, `fd7a::`, `172.29.0.1`) false-positive a bare `ss | grep 8081` (the launch guard matches `127.0.0.1:8081` specifically).
   - Commit `e9bae0f7` (master, `Agent-Print: jett-8011 (qwen3.8-27b-fp8)`); only the harvester staged (18 unrelated tree changes left untouched).
3. **Reseed (made the new card live).** `scan-stage --groups system_processes` (`input changed=True`, 5 cards restaged) → seed **mid** via `--remote-embed http://127.0.0.1:8765/embed` (resident 4B, no new GPU load) + **small** via `--device cpu` (0.6B). `mid` + `small` now `:live`; card retrievable live via `:8765` — version **2026-10-10** (was 2026-10-05), top-hit score 6.5 on the load-via-unit query.

## Key facts
- **Full root (8B / dim 4096) left STALE** — deliberately: OOM-risky beside the resident qwen3.6 (seed policy: an OOM mid-recreate can leave the well *empty*, not stale); needs a clean card or PM go to free one.
- The card is **authored prose** (string literal in the harvester), not generated — editing the file moves its fingerprint → next `scan-stage` restages; a reseed re-embeds the *whole* well.
- RAG card is the durable record of the procedure itself; this receipt is the session log.

## Open / next
- Reseed the **full** root when a card is free (or PM go to free gpu2) to clear the last STALE root.
- Boot-layout note (unchanged): `qwen36-coder.service` is `enabled` → qwen3.6 reloads on gpu2 at boot; ComfyUI has no unit (won't boot / no respawn). Making ComfyUI a unit would turn both directions into clean unit-stops (raised, not done — PM call).
