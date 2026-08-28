# 2026-08-27 — ComfyUI evicted from gpu1

Freed gpu1 by killing the ComfyUI process (PID 439681) and shutting down the server.

## What was running

- PID 439681: `python3 main.py --listen 0.0.0.0 --port 8189 --disable-auto-launch`, CWD
  `/data/models/stable_diffusion/comfyui`, env `CUDA_VISIBLE_DEVICES=1` (launched by
  `launch_gpu1.sh`). MiniMax H3 video model staged (22.3 GB main + VAEs), last prompt
  finished ~18:30, idle at kill time.
- Held ~35.8 GiB on gpu1 (number from 2026-08-25 tri-card co-residency card), which was the
  blocker for the tri 397B (~81.6 GiB needed on gpu1) — tri was DOWN because of it.

## Action

- SIGTERM (`kill 439681`) → process exited cleanly within 5 s. No SIGKILL needed.
- No relaunch: gpu1 is now free for the tri.

## Verification (vantage-safe, GPU sandbox switch was OFF)

`nvidia-smi` untrustworthy from sandbox. Verified via shared `/proc` instead: enumerated all
processes holding fds on `/dev/nvidia*`. After the kill, no ComfyUI/main.py process appears.
Remaining nvidia fd holders: vllm `VLLM::EngineCore` (PID 1045838 + 1046117, all 3 cards —
the tri), PID 11998 (python, small RAG), llama-server PID 88704 (gpu0), Xorg/gnome (display).

## Gotchas

- `pgrep -af "pattern"` matches its own invoking shell — check `/proc/<pid>` existence
  instead, or filter `grep -v bash`.
- GPU sandbox switch (`claude_sandbox_gpu.py status`) governs `nvidia-smi` trust; check it
  first. fd enumeration over `/proc/*/fd` works from either vantage (PID ns + fs shared).

## Next

- gpu1 has room for the tri's ~81.6 GiB (only small RAG + display remain; RAG is on gpu1
  per co-residency math at 6 GiB → ~9.9 GiB free after tri, so RAG co-residency is the
  design intent). Relaunch tri per its own runbook when PM decides.
