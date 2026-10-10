# 2026-09-30 — pi mid-run 400 deaths ROOT-CAUSED + FIXED (pi seat jett-8011 / qwen3.8-27b-fp8)

**Session ID: `01a0f30b-098f-7095-b816-d0f7dfa5bfa1`**
(01a0f30b-098f-7095-b816-d0f7dfa5bfa1 — file `~/.pi/agent/sessions/--data-agentic_trading--/2026-09-30T15-59-41-967Z_01a0f30b-098f-7095-b816-d0f7dfa5bfa1.jsonl`)

## What was decided / built

- **Root cause of repeated pi terminations** (PM: "find out why the fuck it keeps terminating"): the model cards reserved half the window for output that never happens. `.pi/models.json` had `maxTokens: 131072` on 8011/8012 (window 262144). pi (0.99.1) sends `max_tokens = min(131072, 262144 − est − 4096)`; vLLM rejects `real_prompt + max_tokens > 262144`. Above ~131K real prompt the flat 131,072 reservation is always fatal; above est ~127K the dynamic clamp dies on any estimator drift > 4,096 (pi estimates trailing tool results at chars/4; dense code/JSON runs ~3.0 chars/token). **Reproduced to the token**: 09-23 400 replayed → est 129,441 → req 128,607 (exact match); drift 4,097 = 4,096 margin + 1. All 24 recorded 400s (both cards, both roots) sum to exactly 262,145.
- **Fix (applied, committed `816e006d`, pushed)**: 8011/8012 → `contextWindow: 229376, maxTokens: 32768`; 8081 → `contextWindow: 122880` (its llama-server caps at 131,072 despite `-c 393216`). New fatal-drift margin in clamp region: constant 36,864 (was 4,096); compaction fires at est 212,992, ahead of the fatal edge. One physical file governs both roots (`~/.pi/agent/models.json` is a symlink to `/data/agentic_trading/.pi/models.json`; research_agent has no local override). **Running sessions keep the old card until restart** — the fix bit this session itself (started 15:59, fixed 17:12, old-config 400 at 17:16:19, recovered via auto-compaction).
- **.gitignore (committed `8c997073`, pushed)**: PM ruling — blanket `*.parquet` (supersedes the "outputs/*.parquet deliberately NOT ignored" note). Does not untrack the ~206 tracked parquets.
- **Why maxTokens reduction is free**: 39,737 assistant turns/30d → p50 508, p90 2,610, p99 7,974 out-tok; only 3 turns ever > 32,768; a binding cap = clean `stopReason: length`, not a crash.

## Secondary causes documented (receipts in transcript)

- npm-updating pi mid-session → `Cannot find module` crashes (4, incl. 09-30 00:18 during the 0.99.1 update).
- :8081 llama-server 131,072 hard cap despite `-c 393216` (30× 500 + 6× 400).
- qwen3.6 malformed tool-call XML (28 parse errors, 8081).
- 71 aborts (Esc / repetition-guard) + 17 `terminated` fetch drops. No OOM.

## Open

- **Uncommitted warehouse-vol pair** (from the prior 12:04 run, awaiting PM word): `scripts/deploy_warehouse_vol_models.py` (new) + `scripts/daily_eod_build.py` (step 9b) — go live ~23:33 UTC timer run.
- 8081: making the 393K context actually take effect needs a server restart with correct rope/ctx flags (separate task).
- seat/fwg container has its own models.json (separate Docker fs) — needs same six numbers if it shows the same deaths.
- Optional: `_pre_export_` archive copies of the 5 frozen .bak files; add the 5 other sqlmesh tables to the deploy script.
