# 2026-09-12 — Warehouse health checks + SPX investigations (09-10 → 09-12)

Seat: pi (qwen3.8-27b-fp8), PM-directed. Read-only investigations + two small
committed fixes, all pushed to master (splake-cloud/market_data).

## What was built / decided

1. **Warehouse health checks** (09-10, 09-11) per `docs/WAREHOUSE_HEALTH.md` §2–§11.
   Store shrank 25.6 → 14.68 GB after 3 snapshots reaped — diagnosed as checkpoint
   reclamation, NOT data loss. This empirically falsifies the doc's "main file never
   shrinks" invariant (measured at 53 MB scale). Data fresh through 09-10, parity
   clean, backup OK.
2. **09-09 parity "unexplained"** (`es_regime`, `rv_daily`, `vol_summary`) → cross-vintage
   back-adjustment rebaseline at the ESU2026→ESZ2026 roll (source rewritten 09-09
   23:34:43Z). Store now matches prod cell-for-cell. `warehouse/reconcile.py` lacks
   a `back_adjustment` classifier for these 3 tables (future EDIT).
3. **spx_1min guard drift** → single degenerate VENDOR bar: flat O=H=L=C=7606.77 at
   2026-09-10 13:10 ET. Vendor (massive) API re-fetch still returns the flat bar
   (vendor-side defect); no alternative source on the box with a verified intrabar
   range. PM approved the documented-exception fix: guard SQL one-minute exclusion in
   `docs/data_catalog.yaml` + anomaly note in `docs/data_pools/POOL_LEDGER.yaml`.
   **Commit `3defcb84`.**
4. **spx_options_pool guard error** (09-11 16:36 UTC, "Error: don't know what
   type:") → transient mid-write read of the day file. **Attribution correction
   (important):** the live pool writer is
   `src/market_research/spx_live_ingest/spx_live_service.py:476` (`_save_chain`),
   which has been **atomic (tmp + os.replace) since `cefaa0bf` 2026-05-13**; the
   service restarted 09-12 06:18:55Z runs that code, so the incident's writer
   vintage is retired — **no restart needed**. The earlier :8012 attribution to
   `scripts/orats_intraday_ingest.py:252` was WRONG (legacy standalone script, not
   in the service path). That script still carried the same hazard → fixed with the
   same tmp+replace pattern and verified (real-code concurrent probe: 20 rewrite
   cycles, 0 reader errors, 0 orphaned tmps). **Commit `a3655f56`.**

## Key facts settled

- Live pool writer path: `spx_live_ingest.service` → `python -m
  market_research.spx_live_ingest` → `spx_live_service.py` (atomic since 05-13).
  `scripts/orats_intraday_ingest.py` is NOT in the service path.
- massive 1-min history is the only canonical 1-min OHLC source; its 09-10 13:10
  bar is defective; only remedy is a vendor correction (async PM action), after
  which the exception entries in `data_catalog.yaml`/`POOL_LEDGER.yaml` get retired.
- Reports: `outputs/spx_1min_drift_investigation_20260911.md`,
  `outputs/spx_options_pool_assertion_error_20260911.md`.
  Verify receipts: `verify/spx1min-*`, `verify/spxpool-*`, `verify/atomic-v*`.
- Both commits carry `Agent-Print: pi (qwen3.8-27b-fp8)` and are pushed.

## Open / next

- PM async: vendor correction request (massive/Polygon) for the 2026-09-10 13:10
  SPX 1-min aggregate.
- EDIT: `back_adjustment` classifiers in `warehouse/reconcile.py` TABLES for
  `es_regime` (9 price cols), `rv_daily` (seam-day return), `vol_summary` (seam-day
  return passthrough).
- Doc EDIT (PM-ratified): `docs/WAREHOUSE_HEALTH.md` §1b/§2 "main file never
  shrinks" invariant rewrite.
- Triage `daily_data_integrity.service` (failed since 09-10 21:34Z).
- UNRESOLVED: unidentified store writes at 14:00:04Z (no cron/timer/process found;
  host-vantage auditd needed). Pre-existing `gamma_intraday` working-tree edits in
  `docs/data_catalog.yaml` are PM's call — left unstaged by this line.
