# 2026-08-31 — SQLMesh advance re-enabled (K=3) + iron-fly field-contract HOLD

Two threads closed/advanced today (oc-ask seat).

## 1. Warehouse advance re-enabled — de-risked, K=3 in progress
PM directive: re-enable the scheduled warehouse advance (remove `--skip-shadow`),
verify 5 criteria per run, continue through K=3 clean scheduled runs. Iron-fly
scheduling metadata NOT changed unless the restored daily path shows a cadence failure.

- **Staged** the unit change (root-owned file, this seat can't sudo):
  `verify/advance_reenable_20260831/daily_eod_build.service.staged` (diff = only the
  flag removal). PM applied it; confirmed `ExecStart` now has no `--skip-shadow`.
- **Controlled manual run** (de-risk before tonight's scheduled run): `daily_eod_build.py`
  (no --skip-shadow), trade_date 2026-08-30, 157.3s, all_ok=True. step 10
  `warehouse_shadow: ok (118.2s) 0 unexplained`. **5/5 criteria PASS** (transcript
  `verify/advance_reenable_manual_run1.*.txt`): c1 no regress, c2 IV M1+M2 both
  08-27→08-28 (FULL M2 kept pace), c3 iron-fly no false-complete interval, c4 janitor
  deleted nothing (34/34), c5 parity ledger 2026-08-31 zero unexplained.
- **Harness bug fixed during run**: c3 false-complete detector originally compared
  `interval end_excl − 1 day` vs pool dates (flagged the Sunday); corrected to flag
  only intervals whose range has pool trading days but 0 physical rows.
- **Key code facts**: step 10 `shadow_run.py daily --include-pool` → `ctx.run()` on the
  LIVE `/data/warehouse/warehouse.duckdb` (the advance path). `ctx.run()` runs the
  SQLMesh janitor INTERNALLY (context.py:804-805, env=prod, skip_janitor=False). The
  standalone `step_warehouse_janitor` is skipped after re-enable (gate: shadow not
  skipped) → no double-run. Reconcile covers the 19 daily cut-over tables (iron_fly +
  IV weekly are NOT in the reconcile registry — verified via intervals/physical).
- **K=3**: manual run is a de-risk, NOT a scheduled run (k stays 0). Tonight's scheduled
  run (23:30 UTC / 19:30 ET) = run1. Verify via
  `verify_advance_run.py runN` (in `/tmp/opencode/wh_recovery_20260830/`).
- **IV correction**: IV weekly substrate reads the OPTIONS POOL (spx_pool_glob, current)
  + calendar — NOT the stale vix_daily (that's only `weekly_vix_study`). Both substrates
  have current sources; neither is source-blocked.

## 2. SQLMesh health check — HEALTHY (10 PASS, 1 WARN, 0 FAIL)
`verify/sqlmesh_health_20260831/health_report.json` + transcript
`verify/sqlmesh_health_check.20260831T050727Z.txt`. 11 dimensions A–K. The 1 WARN =
G_pending_changes (below).

## 3. Iron-fly field-contract HOLD (the G_WARN)
The plan dry-run revealed an **unapplied semantic change** in
`warehouse/models/iron_fly_weekly_substrate_v2.sql` (git ` M`, mtime 02:25 UTC — the
"final build / cleanup" thread that ran out of context). Three edits:
- `fly_value_mid`: uncapped → **capped [−50,50]** (would change 66.3% of rows; range is [−179,3610])
- `entry_quoteable`: 8-leg `>0` check → **`TRUE`** (flips 375,936 rows)
- `entry_debit_mid`: re-capped (redundant)

**Load-bearing downstream**: L-studies filter the population on `entry_quoteable=TRUE`
(frozen 352-trade baseline) and use `fly_value_mid` for the extreme-mark diagnostic
(`|mid|>150`). The cap would suppress that diagnostic; the always-TRUE quoteable would
grow the population. Published results safe (frozen exports); NEW live-table runs shift.

**PM ruling (Option 3): HOLD — do NOT apply, do NOT discard.** Live snapshot
`1103730983` remains authoritative; K=3 unaffected (ctx.run() uses the applied snapshot,
not the working tree). Safer target shape if the cap is ever wanted: (1) keep uncapped
raw/diagnostic mark, (2) separate bounded value for economics, (3) explicit out-of-bounds
flag, (4) retain genuine entry_quoteable. **Do NOT plan-apply the working tree until
adjudicated** (would silently mint a new prod version).

Full note: `studies/iron_fly_weekly/receipts/iron_fly_v2_field_contract_HOLD.md`
Cross-ref: `verify/advance_reenable_20260831/K3_TRACKING.md`.

## Traps
- DuckDB: a long-lived read-only connection + a later read-write `Context()` on the same
  file = "different configuration" error (hit in health check G + the earlier P8). Close
  the read-only conn before the plan build.
- DuckDB connections aren't directly iterable — need `.fetchall()`.
- `git` is blocked except `git -C /data/agentic_trading`; `sudo`/`rm` blocked.
- Health check G (plan build) writes no WAL but takes ~2s; the WAL present after the
  advance is normal (uncheckpointed writes), not a failure.

## Open / next
- **K=3**: verify tonight's scheduled run (run1), then run2/run3.
- **Iron-fly field contract**: adjudicate the HOLD (discard / apply-with-safe-shape /
  keep pending) — PM decision, not blocking.
