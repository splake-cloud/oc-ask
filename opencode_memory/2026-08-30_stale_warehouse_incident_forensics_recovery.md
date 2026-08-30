# 2026-08-30 — Stale-warehouse incident: forensics + staged recovery plan (5-deliverable scope executed)

## What was built/decided
PM overrode the earlier "hand to the SQLMesh agent, NOT this seat" scope and dispatched the
5-deliverable stale-warehouse incident to **this seat** to execute. Executed all 5 (investigation
+ planning only; **no shadow re-enable, no frontier recovery executed** — both stay PM-gated).
Deliverable: `studies/iv_weekly_substrate/receipts/2026-08-30_stale_warehouse_incident_forensics_and_recovery_plan.md`.

## Key facts settled (with paths)
- **D1 — the 00:20:50 "mystery write" is explained.** The full journal 2026-08-27 00:20:40→00:21:10
  shows **only `es_live_ingest`** (PIDs 172328/172391) flushing ES 1-min bars + kernel UFW blocks —
  **no sqlmesh/warehouse/duckdb process**. The `sqlmesh_2026_08_27_00_20_48.log` the 2026-08-27 card
  cited **no longer exists** (rotated); it was a 2-sec connect-only run that triggered a DuckDB WAL
  checkpoint (updated the DB file mtime to 00:20:50) with no logical write. **The actual row loss is
  the 22:35:23 restate** (mirror-root log `sqlmesh_2026_08_26_22_35_23.log`): a real
  `DELETE FROM ...__1230283500 WHERE trade_date BETWEEN 2022-06-01 AND 2026-08-24` + `INSERT`, then
  `Promoting/Finalizing environment 'prod'`. **This CONTRADICTS the 2026-08-27 card's "22:35 restate
  was a NO-OP" claim** — the restate mutated the old physical table. Row loss confirmed live:
  `__1230283500` = 1,930,133 rows (max 08-17) vs `__1103730983` = 1,938,281 (max 08-21).
- **The "mirror root" `/data/warehouse/warehouse/` is NOT a rogue project.** It is
  `shadow_run._setup_ctx`'s ephemeral working dir: `shutil.rmtree(PROJECT)` + `copytree(R.WAREHOUSE,
  PROJECT)` each run, `sqlmesh.yml` rewritten to point at the same prod DB (shadow_run.py:55-60).
  Both roots share `/data/warehouse/warehouse.duckdb` (both `sqlmesh.yml` line 10). No cron/systemd
  trigger for it. Its 08-27 21:40 logs are 2-sec connect-only runs.
- **D2 — advance path is structurally sound but NOT safe to re-enable yet.** `ctx.run()` incremental
  + reconcile (last 10 days) → parity ledger; last full run (08-26 23:30) was `ok, 0 unexplained,
  all_ok=True`. Safe to re-enable **only after** (a) the state/bytes mismatch is resolved and
  (b) a preflight confirms no concurrent writer. Keep `--skip-shadow` through recovery; re-enable as
  the **last** gated step.
- **D3 — real staleness (state `end_ts` is EXCLUSIVE, so 1-day gaps are normal EOD lag, NOT stale):**
  - `breadth_daily` (FULL): state 08-26, **physical 2026-04-10 (138 d)** — deep stale.
  - `weekly_vix_study` (FULL): state 08-25, **physical 2026-04-10 (137 d)** — deep stale.
  - `iron_fly_weekly_substrate_v2` (INCR): state 08-26, **physical 08-21 (5 d)** — 22:35 restate dropped 08-18..21.
  - ~12 daily models: physical 08-25, missing frontier days **08-26, 08-27, 08-28** (pool is at 08-28).
  - `nyse_calendar` physical 2026-12-31 = forward-filled, not stale.
  - `warehouse.duckdb` mtime = 2026-08-30 14:56:12; several `_intervals` rows carry `created_ts`
    14:56:12 → state DB rewritten/compacted then (separate event).
- **D4 — staged recovery plan (PM-gated, NOT executed):** Stage 0 preflight (read-only: confirm
  `--skip-shadow` still set, snapshot 26.8 GB state DB + sha256, capture baseline inventory, check
  source freshness for the deep-stale models) → Stage 1 re-derive breadth/weekly_vix (FULL, scoped,
  gated on source freshness) → Stage 2 backfill iron_fly_v2 08-22..08-28 (INCR) → Stage 3 advance
  daily models to 08-28 (first scoped one-shot advance) → Stage 4 janitor cleanup of orphaned tables
  (Option B one-shot) → Stage 5 remove `--skip-shadow` (the withheld PM-gated mutation) + observe K
  clean runs. Post-recovery proofs: D3 re-run all at frontier, K× 0-unexplained parity, KASA, prod
  sha256 invariant, retain Stage-0 checkpoint.
- **D5 — remove Option B as the final close-out step, after Stage 5's K clean runs.** Its gate
  (`_shadow_skipped AND _blocking_steps_ok`, daily_eod_build.py:618) makes it run **only** under
  `--skip-shadow`; once the advance is re-enabled, `Context.run()` owns the janitor
  (context.py:806-807) → no double-run. It is a temporary bridge for the `--skip-shadow` era.

## Verification (all via `verify-run`, deposited under `verify/`)
- `stale_wh_d3_inventory.20260830T193508Z.txt` — full state-vs-physical table (exit 0).
- `stale_wh_d1_journal_002050.20260830T193513Z.txt` — 00:20:50 journal window = es_live_ingest only (exit 0).
- `stale_wh_d1_rowloss_proof.20260830T193519Z.txt` — restate log DELETE/INSERT/Promoting/Finalizing (exit 0).
- `stale_wh_d1_rowcounts.20260830T193519Z.txt` — `__1230283500` 1930133/08-17 vs `__1103730983` 1938281/08-21 (exit 0).

## Open / next (PM decisions)
1. **Authorize Stage 0 preflight** (read-only; safe now). Stages 1-5 are PM-gated mutations.
2. **Source-freshness ruling** for breadth_daily (firstrate zips) / weekly_vix_study (VIX source):
   if the *source* is stale past 2026-04-10, the fix is a source refresh, not a warehouse re-derive.
3. **22:35 restate row loss now attributed** (corrects the 2026-08-27 card). Old `__1230283500` is
   orphaned (not the prod version); cleanup is a Stage-4 janitor concern.
4. **00:20:48 connect-only origin unresolvable** (log rotated). To pin it would require durable
   audit logging of every sqlmesh invocation on the shared DB (separate hardening task).

## Traps
- State `end_ts` is **exclusive** — do not report the daily models' 1-day gap as staleness; that is
  normal EOD lag (build trade_date = previous day). Real gaps: breadth/weekly_vix (137-138 d), iron_fly_v2 (5 d).
- The "mirror root" is `shadow_run`'s ephemeral working dir, NOT a second writer.
- Console "Deleted object" lines are NOT the authoritative drop set (janitor trap) — physical diff vs baseline JSON is.
- `sqlmesh -p warehouse status` does not exist; use `check_intervals` + direct `_intervals`/physical queries.
- `verify-run <label> <prog> <args...>` takes program + args as separate argv (a single quoted string → exit 127).
- The `warehouse.duckdb?mode=READ_ONLY` file (12288 B, Aug 27 10:28) is a **separate** incident (malformed
  connection string created a stray 12 KB DuckDB file), not part of this one.
