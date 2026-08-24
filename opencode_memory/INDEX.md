# opencode_memory — session memory index

Conventions (what "write a session receipt" / "reorient me" mean): see `README.md`
and `/home/user/oc-ask/AGENTS.md` (auto-loaded every session).

One line per memory card, newest first. "Reorient me" → read this index, open matching card.

Memory repo: `git -C /home/user/oc-ask` → `git -C /home/user/oc-ask add opencode_memory/ && git -C /home/user/oc-ask commit -m "memory" && git -C /home/user/oc-ask push`
Remote: `https://github.com/splake-cloud/oc-ask` (branch `master`, commit `c17a5bf4`)

| Card | Topic | Key contents |
|---|---|---|
| [2026-08-24_qwen38_validator_detune.md](2026-08-24_qwen38_validator_detune.md) | Qwen3.8 validator detune: temp 0.8 + reasoning_effort medium, all 4 surfaces, durable via registry | two-lane config map (global opencode.jsonc vs staged registry flow); stager now emits reasoningEffort (fail-closed); activation = restart THEN restage; 5 files uncommitted; lockstep drift check deferred by PM |
| [2026-08-24_sqlmesh_daily_cycle_repair.md](2026-08-24_sqlmesh_daily_cycle_repair.md) | SQLMesh directive + INCIDENT: REMOVE deleted PROD db (symlink); restored + advanced + verified + committed | symlink-before-rm rule; backup cron PATH fixed (3 days false "corrupted"); step-9 hardened; exec-bit fix; 2 commits pushed (7 files); full directive verification with PROOF |
| [2026-08-24_qwen36_262k_restart.md](2026-08-24_qwen36_262k_restart.md) | qwen3.6 gpu1 restart: 262k ctx + q8_0 KV; full action plan preserved | config edits (L166/L945), setsid launch fix, rollback recipe, deltanet-MoE watch item, serve-restart DONE via -y |
| [2026-08-24_gpu2_slot_inspection.md](2026-08-24_gpu2_slot_inspection.md) | GPU2 ComfyUI slot: what's running + vantage proof | PID 1190318 Wan I2V live, 81-frame links ~52s, netns/Seccomp host proof |
| [2026-08-24_opencode_memory_system.md](2026-08-24_opencode_memory_system.md) | Session memory layer design + build | opencode_memory/ + AGENTS.md trigger phrases, transcript locations, RAG gap |
| [2026-08-24_sandbox_vantage_provenance.md](2026-08-24_sandbox_vantage_provenance.md) | Sandboxed observability section: provenance audit + swap_model.py fix | provenance per block (user vs assistant), live netns probes, adjudication: stay-all, commit 5c2d91fc |
| [2026-08-24_wan22_i2v_chain.md](2026-08-24_wan22_i2v_chain.md) | Wan2.2 I2V ComfyUI 3-link chain, mid-chain waypoint | workflow design, model inventory, frame extraction, session decisions |
