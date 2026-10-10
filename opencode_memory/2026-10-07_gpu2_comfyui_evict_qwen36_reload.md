# 2026-10-07 — gpu2: ComfyUI evicted, qwen3.6 reloaded (RAG kept)

Task: inventory gpu2; confirm ComfyUI + RAG; evict ComfyUI; load qwen3.6. PM: keep RAG;
"the process should already be documented" — it was (LOAD_CARD.md + 2026-08-27 eviction
card + RAG service cards).

## Before (22:04 UTC)

gpu2 = 31891 / 97887 MiB:
- **ComfyUI** — pid 579937, `python3 main.py --listen 0.0.0.0 --port 8188
  --disable-auto-launch` (launch_gpu2.sh, setsid nohup, NOT systemd-managed), 12860 MiB.
- **RAG** — pid 2849787, `verifier-rag-mid.service` (Restart=always):
  `rag_verifier/small_service.py --port 8765 --device gpu2`. PM confirmed "the rag
  should be the 4B system": `/health` → kb_root `/data/parquet/verifier_kb_mid`,
  embed `/data/models/qwen3-embedding-4b` (dim 2560), rerank `/data/models/qwen3-reranker-0.6b`
  (cuda), selected_gpu 2.

## Action

1. `claude_sandbox_gpu.py on` → host vantage (`readlink /proc/self/ns/net` =
   net:[4026531833], Seccomp 0).
2. `kill -TERM 579937` → clean exit <5 s (precedent 2026-08-27). gpu2 31891 → 18930 MiB;
   :8188 freed; RAG same pid, untouched.
3. `systemctl --user start qwen36-coder.service` (user unit: CUDA_VISIBLE_DEVICES=2,
   `launch_qwen36_35b_q8.sh --mode coder --no-think --parallel 2`, VRAM floor guard).
   → llama-server pid 1792076, 43718 MiB, :8081 serves `qwen3.6-35b-a3b-q8`
   (34.66B params, n_ctx 196608/slot). Coherence verified (17*23 → 391, twice).

## After (22:12 UTC)

gpu2 = 62653 / 97887 MiB (34597 free): qwen36 43718 + RAG 18910. Matches the unit's
documented design (~41.5 + ~19 GiB). `qwen36-coder.service` active; unit is enabled,
so boot layout = qwen3.6 + RAG on gpu2 again.

## Procedure that worked (documented, followed as-is)

- **Never** `llm-alloc evict gpu2` / `stop` — they SIGKILL *every* pid on the card,
  RAG included (gpu_co_residency.md:123). RAG is systemd Restart=always; killing it
  just trades a clean state for a respawn race.
- ComfyUI eviction = SIGTERM its main.py pid; verify via /proc + nvidia-smi + port
  (host vantage required for loopback curls — sandboxed 127.0.0.1 is the sandbox's own ns).
- qwen3.6 on gpu2 = the user unit, not a hand launch (hand orphans are the documented
  "trap"; unit carries ExecStartPre GPU gate + floor + health post-check).

## Open / notes

- ~~`/data/models/stable_diffusion/comfyui/LOAD_CARD.md` "Updated 2026-10-02" block is now
  STALE~~ — **RESOLVED same session on PM request**: card rewritten (Updated 2026-10-07) with
  live state, measured VRAM ledger, both-direction swap procedure (executed today), the
  "never" list (llm-alloc evict/stop, add-refusal, RAG kill, port changes), host-vantage
  step 0, and the think-block coherence-check caveat. ComfyUI ↔ qwen3.6 on gpu2 is now
  copy-paste from the card.
- ComfyUI has no systemd unit; it will not auto-respawn. Relaunch = `bash
  /data/models/stable_diffusion/comfyui/launch_gpu2.sh` (needs room: ~13 GiB).
- GPU switch flipped back OFF at session end (secure default).
- Bare `/v1/completions` probes can spend the token budget inside a think block even
  under the --no-think server (chat-API seats unaffected); documented row is
  temp 0.7 / top_p 0.8.
