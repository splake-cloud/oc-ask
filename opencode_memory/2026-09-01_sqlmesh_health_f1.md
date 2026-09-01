# 2026-09-01 — SQLMesh health check, F1 fix, and the delegation doctrine

## What happened
- 08-31 23:33 EOD failed: `shadow_run.py` parity-ledger writer crashed on
  `json.dumps` of a `datetime.date` in `unexplained_keys` — masking a real
  UNEXPLAINED diff in `atm_iv_daily` @ 2026-08-28 09:31.
- The diff was transient: an out-of-band `sqlmesh run` (user's Coder seat,
  01:59–02:01 UTC) re-materialized the warehouse through 08-31; the NULL became
  7737.2 = exact prod value. Warehouse now Complete everywhere.

## F1 (DONE, verified)
- `warehouse/shadow_run.py:108`: `json.dumps(row)` → `json.dumps(row, default=str)`.
- Receipt transcripts: `/data/agentic_trading/verify/f1_{grep,compile,serial}.*.txt` (02:52).
- Ledger guard: still 1359 lines. Acceptance test: the 2026-09-01 23:31 EOD run.

## The proven doctrine (bank this)
Diagnosis/delegation prompt = task (one line) + five execution rules:
1. Do exactly the task as asked; self-invented subtasks → NOTES, never action.
2. State the exit condition before the first action; non-delivering work is out of scope.
3. Budget: 5 unstructured probes → commit or state what's missing; +3 only to verify load-bearing claims.
4. Mutations only when the deliverable IS a mutation; checks are read-only, fixes named never applied.
5. Every load-bearing claim carries one verbatim evidence line; mysteries → one OBSERVATIONS line; unknown = "UNDETERMINED: <blocker>".
Plus: re-execute claims through verify-run; corrections noted in-document.
Measured: ~10k tokens / minutes vs 35k / 15 min unbounded; two turn-1 errors
self-disproved by the verification pass.

## Seats
- qwen-coder :8081 = qwen3.6-35b-a3b-q8 (provider `jett-8011`), 4 concurrent vLLM streams.
- Raw `:8081/v1/chat/completions` has NO shell → returns formatted fiction (3.9s).
  Delegation MUST spawn an agent with tools (`pi -p --provider jett-8011 --model qwen3.6-35b-a3b-q8`).
- `delegate.ts` pi extension (headless subagent dispatch) — envelope drafted, build pending.

## Still open
- ~217 GB in /data/warehouse/duckdb_temp (spill from the 02:00 out-of-band run) — reclaim.
- Iron_fly_weekly_substrate_v2: breaking diff pending backfill 2022→2026 (needs plan+apply, PM call).
- iv_weekly_state_daily / iv_weekly_percentile: in check_intervals but NOT in reconcile.TABLES (no parity coverage).
- per_contract 08-31: missing_partition front=ESU6 (separate from SQLMesh).
