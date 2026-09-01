# 2026-09-01 — SQLMesh warehouse health check (read-only) + full verification

## Verdict
- **Warehouse DATA: healthy/current.** All 28 models materialize through trade day 2026-08-31 (`sqlmesh._intervals` frontier = 2026-09-01 excl. end). An out-of-band run advanced everything 2026-09-01 01:59–02:01 UTC (actor unknown; not `shadow_run.py` — no ledger rows appended).
- **Nightly automation: UNHEALTHY.** `daily_eod_build.service` failed 2026-08-31 23:33:32 UTC (first failure since 08-26; 08-26…30 all exit 0). Step 10 `warehouse_shadow` → subprocess crash: `TypeError: Object of type date is not JSON serializable`. Will recur at the 2026-09-01 23:31 UTC timer fire until fixed.

## Root cause (verified, named — NOT applied)
- `warehouse/shadow_run.py:108` — `json.dumps(row)` in `_append_ledger` has no date handler; row dict embeds a pandas sample via `.to_dict(orient="records")` at lines 94–96. Traceback frame byte-identical to `/usr/lib/python3.12/json/encoder.py:180`.
- Crash point in the failed run: reconcile completed 12 of 20 tables (all clean, unexplained 0), then the append died on the 13th table in R.TABLES order = `intraday_post_checkpoint_outcomes` (ledger file rows 1347–1358, reconstructed).
- Exact offending dict field: **UNVERIFIED** — `scripts/daily_eod_build.py:194` keeps only `stderr.splitlines()[-2:]`, discarding the full traceback.
- **F1** (the fix): date/datetime handler on the `json.dumps` at shadow_run.py:108 (or coerce the sample at 94–96). **F2** (hardening): keep more stderr in step detail at daily_eod_build.py:194. **F3**: no catch-up needed — data already current.

## Verification method
All claims re-executed via `verify-run` with deposited transcripts in `/data/agentic_trading/verify/` (labels: `eod-service-state`, `eod-journal-failure`, `eod-json-state`, `parity-ledger-state`, `state-db-stat`, `code-unchanged-since-aug31`, `f1-cpython-frame`, `ledger-0831-write-order`, `warehouse-frontier-v3`, `eod-start-lines-since-aug26`, `no-run-in-flight-clean2`, + 2 frontier query retries that failed on schema/cast). Verification **disproved two turn-1 claims**: (1) "warehouse not advanced past 2026-08-30" — false; (2) "crashed before reconcile ran" — false, 12 tables reconciled clean first.

## Observations left open (one line each)
- 217 GB in `/data/warehouse/duckdb_temp` (spill files), grew 02:11–02:15 UTC today — source undetermined.
- EOD exited 0 on 08-27…08-30 but ledger has no rows for those dates (gaps before too: 08-17…19, 08-21…24) — shadow step apparently skipped; mechanism unverified.
- `per_contract` step 08-31: `missing_partition front=ESU6 new=0` (unrelated to SQLMesh).
- `sqlmesh-subagent-watchdog.sh` (PID 3239) persistent watcher; legacy `iron_fly_weekly_substrate` v1 frozen at 2026-08-25.

## Next session
- If user asks about the EOD failure: fix F1 is named, one-line change, never applied (read-only mandate this session).
- Watch for the 2026-09-01 23:31 run: expect the same `shadow_alert` unless F1 landed.
