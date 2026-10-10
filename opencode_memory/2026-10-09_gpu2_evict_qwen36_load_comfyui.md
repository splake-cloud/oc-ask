# 2026-10-09 — gpu2 swap: evict qwen3.6 → load ComfyUI, RAG preserved untouched (pi seat jett-8012 / qwen3.8-27b-fp8)

**Mission (PM, verbatim):** "evict qwen 3.6 on gpu2 leave the rag in place untouched, load comfyui on gpu2." Mid-run PM reinforcements: "there is a card on this whole operation" (write this card); "rag / do not disable it" (the RAG stays running AND enabled — never disable it).

This is the **inverse** of the 2026-10-07 card (`2026-10-07_gpu2_comfyui_evict_qwen36_reload.md`, which evicted ComfyUI and reloaded qwen3.6). Recurring gpu2 swap pattern.

## gpu2 inventory (before)

| Role | PID | cmdline | VRAM | supervisor |
|---|---|---|---|---|
| RAG | 284189 | `.venv/bin/python scripts/rag_verifier/small_service.py --host 127.0.0.1 --port 8765 --device gpu2 --warm` | 12562 MiB | **none** — orphaned to PID 1 (NOT a systemd unit) |
| qwen3.6 | 284611 | `llama.cpp/build/bin/llama-server -m /data/models/qwen3.6-35b-a3b-q8_0/Qwen3.6-35B-A3B-Q8_0.gguf --alias qwen3.6-35b-a3b-q8 -ngl 99 -fa on -c 393216 --jinja --host 127.0.0.1 --port 8081 --parallel 2` | 43808 MiB | **systemd user unit `qwen36-coder.service`** (Main PID 284611, `active (running)`, `enabled`) |

GPU2 pre: 56385 / 97887 MiB used, 40865 free. GPU0/GPU1 = two vllm `qwen3.8-27b-fp8` seats (`:8011`/`:8012`) — untouched, not in scope.

## Two load-bearing discoveries (both changed the mechanism)

1. **`llm-alloc evict gpu2` / `stop` is UNSAFE with the RAG co-resident.** `evict_gpu(card)` in `scripts/llm_alloc.py` (line 389) calls `_pids_on_gpu(card)` (line 351) = `nvidia-smi --query-compute-apps=pid -i <card>` → **every** compute PID on the card, then SIGTERM (→SIGKILL after 60 s). That would have taken the RAG (284189) down with the qwen3.6 (284611). Confirms the 2026-10-07 "Procedure banked: never `llm-alloc evict/stop` gpu2 (SIGKILLs every card pid incl. RAG)". `llm-alloc status` only reported qwen3.6 as RESIDENT (the RAG isn't in its registry), which is exactly the trap — status looks clean, evict would still nuke the RAG.

2. **qwen3.6 is a live systemd user service, so a plain `kill`/SIGTERM of PID 284611 would auto-restart.** Correct evict = `systemctl --user stop qwen36-coder.service` (clean stop, no respawn). This is the *opposite* of the 2026-10-02 note ("qwen36-coder user unit inactive/dead → kill-PID is the correct eviction"): that day the unit was dead and the llama-server was hand-launched from tmux; today the unit is the live owner, so the unit is the lever. Rule: **check `systemctl --user is-active/is-enabled` first** — if the unit owns the PID, stop the unit; only kill-PID when the unit is dead and the server is hand-launched.

## What was done

1. `systemctl --user stop qwen36-coder.service` → qwen3.6 evicted. (NOT `kill`, NOT `llm-alloc evict`.)
2. Verified: GPU2 12572 / 84679 free (RAG only); RAG 284189 alive (STAT `Ssl`), `:8765` LISTENING; `:8081` llama-server gone; unit `is-active=inactive`, `is-enabled=enabled` (**not** disabled — PM: "do not disable it").
3. Loaded ComfyUI: `nohup setsid bash launch_gpu2.sh >> comfyui_gpu2.log 2>&1 &` (launcher = `CUDA_VISIBLE_DEVICES=2; python3 main.py --listen 0.0.0.0 --port 8188 --disable-auto-launch`) → PID 353373, `:8188` LISTENING, "Starting server … http://0.0.0.0:8188". `comfyui_controlnet_aux` import-FAILED = known non-critical (missing cv2), per runbook.

## Final state (verified, host vantage — `readlink /proc/self/ns/net` = `net:[4026531833]`, `Seccomp: 0`)

- GPU2: 13127 used (RAG 12562 + ComfyUI 550 warming) / **84123 free**.
- ComfyUI `:8188` UP (353373). RAG `:8765` UP (284189), untouched, enabled. qwen3.6 `:8081` down (unit stopped, still enabled).

## Gotchas banked

- **Backgrounded-`cd` trap:** `cd X && nohup setsid … & ; tail log` — the `&` backgrounds the *whole* `cd && …` list, so a following `; tail log` runs from the ORIGINAL cwd → "No such file". Use the absolute log path (or `cd` in a separate statement).
- **Vantage:** GPU switch was OFF, but this pi seat's bash ran host-side anyway (Seccomp:0, host net id) — nvidia-smi + `systemctl --user` were trustworthy. Verify vantage in-call before trusting GPU/port state.

## Open / divergence to flag

- **Boot-layout divergence:** `qwen36-coder.service` is still `enabled` → next boot re-loads qwen3.6 onto gpu2. ComfyUI is NOT a unit (hand-launched `launch_gpu2.sh`, no respawn) → it will NOT be on gpu2 after a reboot, and qwen3.6 will boot back into the same card. If the PM wants ComfyUI to be the durable gpu2 occupant, the unit's boot policy needs a decision (PM said "do not disable" the RAG; said nothing about disabling qwen3.6's unit — left enabled, evict-only, as asked).
- ComfyUI (353373) will not auto-respawn if killed — relaunch `launch_gpu2.sh`.
