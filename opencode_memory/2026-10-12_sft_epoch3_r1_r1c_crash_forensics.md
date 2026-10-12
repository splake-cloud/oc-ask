# 2026-10-12 — sft_epoch_3 crash forensics: R1 + R1c executed, :8011 self-kill incident (pi seat jett-8011)

## What was done

1. **Corrected forensics record committed** (`verifications/2026-10-12_sft_epoch3_lora_mtp_enginecore_deaths.md`, commit 44bb54cdb): line-by-line verification of the 5 A–E failures, 12 corrections applied (false embedding_modules claim removed, canary 3.55→2.63, "byte-identical"→semantically identical, corrupted-capture caveat, PM's two epistemic qualifications as binding rails).
2. **R1 executed** (`training/sft_eval_20261011/r1_20261012/`, commit f079b0dd8): A's request reconstructed byte-exactly — pi session JSONL persists the full system prompt in `message.sections` (27,979-char preamble + 15 tools); rendered with pi-ai's own `getSystemMessageText`; wire-tools variant selected by the 12,568 token gate (persisted params, no strict field; strictified = 12,709). Server-side identity: R1 dump `prefix_cache_stats.queries=12568`. Crash reproduced: t+1.8s, 2nd prefill chunk (9600/2968 split), Xid 31 VIRT_READ. **Refuted as necessary conditions: artifactory-timeout→flashinfer-native fallback, inference-time JIT (R1 startup clean: xqa backend, 0 inference JIT).** Kernel NOT named: CUDA_LAUNCH_BLOCKING catches kernel launches but the fault survived to the event sync → faulting op is not a regular launch; leading candidate async D2D memcpy in GDN/mamba prefill-state path (VIRT_READ excludes H2D; graph replay excluded by size 9600>64 max capture).
3. **R1c executed** (`training/sft_eval_20261011/r1c_20261012/`, commit 49a5fd369): identical body, only `model→qwen3.8-27b-fp8` (one-field diff verified pre-send; sha256 0a14d2bf...). **Base completes** (t+5.3s, finish_reason=tool_calls, no Xid, prefix_cache_queries_total=12568). PM's bound: adapter selection distinguishes the attempts; does NOT yet identify a LoRA kernel.

## Key facts settled

- **pi session JSONL**: `message.content` is empty for system; the real prompt is in `message.sections` (+ `toolsAdded` with full declarations). Session-format doc: `docs/session-format.md`.
- **A's request**: system 28,015 chars (preamble 27,979 + cwd 34), user 1,090 chars (byte-identical to nine_first_request_payloads O38), 15 tools, `reasoning_effort=low` (thinkingLevel=medium + sft_epoch_3 thinkingLevelMap {"medium":"low"}), max_completion_tokens 32768, temp 1.0/top_p 0.95/top_k 20/min_p 0.0 (all from `~/.pi/agent/models.json` eval-8911 sft_epoch_3 entry).
- **Crash semantics**: `synchronize_input_prep` block covers only input-prep (ends after `_preprocess`, ~gpu_model_runner.py:4420); forward runs OUTSIDE. A died at `record()` (block exit, :3853), R1 at `synchronize()` (block entry, :3849) — both latched in **step 1 = the first 9600-token chunk** (target forward + MTP drafter).
- **:8011 production seat** = systemd user unit `qwen38-seat.service` (Restart auto-recovery; boot-loads gpu0). GPU layout: GPU0 :8011 prod, GPU1 eval :8911 (reserved), GPU2 RAG 284189 + llama-server 577863.

## INCIDENT — killed the :8011 server serving my own session (04:26:49)

`pgrep -f "vllm serve /data/models/qwen3.8-27b-fp8" | head -1` matched the :8011 production server (same model path, older PID 3138614) instead of the R1c instance; killed it. Down 04:26:49→04:33:13 (~6.5 min), auto-recovered by qwen38-seat.service. The R1c APIServer pid (3794055) was in `server_r1c.log` on disk and in context; the pgrep on a shared model path was the wrong selection tool. **Binding rule (PM, 2026-10-12): do not kill a server using pgrep — use pid only.** Kill targets come from the run-dir pid file / server log, cross-checked against the port owner (`ss -ltnp`) before signaling. pgrep is never a kill selector. **Operating-context copy: AGENTS.md §Execution rules rule 11** (the memory card is retrieval-only; AGENTS.md is what loads into every session). (Related trap, same family: `cd X && nohup … &` backgrounds the whole chain — the post-`&` commands run in the original cwd; both bites hit this session.)

## Second process failure (same session) — `git commit -am` sweep

Committing the AGENTS.md rule with `git commit -am` swept 18 unrelated uncommitted files (other seats' outputs/ parquet, sqlmesh yaml, telemetry, a symlink deletion) into my commit under my Agent-Print trailer, and it was pushed. Fixed: `reset --soft` → unstage → commit AGENTS.md alone → `push --force-with-lease` (verified remote had nothing else since). **Rule for this seat: never `commit -a`; stage explicitly (`git add <path>`), and check `git status` for unrelated changes before any commit in the shared checkout.**

## Open / next

- **R1b** (pending PM): `compute-sanitizer --tool memcheck` on the R1 (adapter) run — names the faulting kernel/memcpy, address, source line. The identifying instrument.
- Whether to amend the three stale receipts (o38_epoch3_crash_20261012.md, HANDOFF_20261011.md lines 39/44/100, HANDOFF_20261012.md "byte-identical").
- Whether the 89/92/88% base-name runs get repeated with the adapter actually targeted.
- A/B/C are withdrawn — nothing revives them; retraining decision is the PM's.

## R1d / R1e / citation sweep (same session, later)
- **R1d (workaround test):** `--attention-config.use_trtllm_attention=0` (supported tri-state
  knob, identical in upstream main; no LoRA guard in either tree) → saved R1 single request
  COMPLETES (5.88 s, tool_calls, 0 Xid). Workaround = necessary, per single-request evidence.
  Deviation: R1d watchdog never started (launch precedence bug) — no hard deadline armed.
- **R1e (full O38 dev case, fixed wrapper):** crash returns at **turn 7** (t+77.1 s, 20,612-token
  prefill): **device-side assert in `lora_shrink`** on the LoRA-wrapped lm_head logits path
  (`logits_processor.py:204 → punica_gpu.py:309 → lora_shrink_op.py:192`), **Xid 43 only, no MMU
  fault** — case-D assert family, same op family as the original plan's shrink candidate.
  **Verdict: workaround necessary but NOT sufficient; ≥2 latent fault surfaces (XQA decode +
  lora_shrink/lm_head).** Rubric: PERFORM/INTERPRET/COMPLETE(a/b/d) all PASS — matches frozen
  baseline anchor — on the code written pre-crash; case itself incomplete (no final report).
- **Fixed wrapper** (`launch_with_watchdog.sh` + `watchdog.sh`, all-absolute, real owned pid
  pre-exec, fail-closed) CPU-verified (deadline-kill demo + fail-closed demo). Use it for all
  future GPU runs.
- **Citation sweep of the forensics record vs venv:** 23/24 venv citations + 5 eval-script
  citations match verbatim; the one miss (`interfaces.py:694` → actual **`:698`** for the
  embedding_modules protocol default) fixed (commit 1010d4fbd).
- **Post-crash GPU1 orphaned SM spin: second occurrence** (after R1e crash) — clears with a
  bounded CUDA probe (context+kernel+sync), ~immediate this time. Known failure mode after
  fatal Xids on this card; verify with utilization, not just VRAM.
- Commits: 8a1db922b (R1d), 60f22a3e2 (R1b corrections), 8d7305dc8 (wrapper+CPU demos),
  1010d4fbd (citation fix), 34f813d31 (R1e).
