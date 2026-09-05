# 2026-09-04 — COT backfill to current (institutional positioning, workstream A)

Backfilled the CFTC Commitments of Traders (TFF) raw pool from 2026-03-31 → 2026-08-25
and repaired the broken pattern-(b) pipeline (SQLMesh model + export) that the
2026-09-04 SQLMesh 0.236.1 upgrade had silently broken.

## Exit condition (met)
`cot_positions` typed model + stable parquet + `research.duckdb` view + `catalog_freshness`
all show 1954 rows, max report_date 2026-08-25.

## What was done
1. **Found the working source.** The fetcher's URL (`/dea/newcot/t_f_00.csv`) is DEAD (404).
   The correct source is the yearly FINANCIAL-futures archive
   `https://www.cftc.gov/files/dea/history/fut_fin_txt_{YEAR}.zip` → contains `FinFutYY.txt`
   (87-col CSV, header row, MODERN schema: Dealer/Asset_Mgr/Lev_Money). The other yearly
   archives are WRONG schema: `fut_disagg_txt` = pre-2004 (Prod_Merc/Swap/M_Money),
   `deahistfo`/`deacot` = old (Noncommercial/Commercial). `fut_fin_txt` is the only one
   matching the pool.
2. **Confirmed provenance.** The pool was built from this same archive: the archive's
   2026-03-31 E-mini SPX row matches the pool cell-for-cell (OI=1947769, Dealer_L=130907,
   AM_L=1139703, Lev_L=163425).
3. **Stringification rule (validated 3393 cells, 0 mismatches across all 39 overlap rows):**
   read archive CSV with pandas DEFAULT inference; numeric→`str(v)` (strips leading spaces,
   normalizes '00'→'0', ' 1947769'→'1947769'); string→keep raw (do NOT strip); NaN→None.
   Pool is ALL-string (89 object cols) = archive's 87 + 2 derived: `report_date`
   (== `Report_Date_as_YYYY-MM-DD`) and `Report_Date_as_MM_DD_YYYY` (always None).
4. **Universe by stable CFTC contract-market code** (name changes over time; code does not):
   `13874A` (E-mini SPX, renamed E-MINI S&P 500 STOCK INDEX→E-MINI S&P 500 @2022-02-08),
   `13874U` (Micro E-mini SPX), `1170E1` (VIX).
5. **Merge:** appended 63 rows (3 codes × 21 dates 2026-04-07→2026-08-25) in pool column
   order, all-object. 1891→1954 rows. Backup at `/tmp/opencode/cot_tff.parquet.bak_20260904`.
   0 duplicate (code,date) keys; 0 gaps in overlap.
6. **Repaired the pattern-(b) chain** (all pre-existing bugs from the 0.236.1 upgrade,
   surfaced by the backfill):
   - `warehouse/models/cot_positions.py` + `short_interest.py`: `context.sql(...)` →
     `context.fetchdf(...)` (`ExecutionContext` has no `.sql` in 0.236.1). This is why the
     registered snapshot held a STUB (`SELECT 1`) and the model never truly materialized.
   - `scripts/export_warehouse_models.py` `resolve_model_version`: `ORDER BY tsql_hash`
     (column GONE in 0.236.1; now `updated_ts`) + fragile hardcoded two-name match →
     per-model `partition(".")` candidate loop. Also `COPY ({table})` →
     `COPY (SELECT * FROM {table})` (DuckDB needs the SELECT wrapper).
7. **Re-materialized** via `sqlmesh plan --auto-apply --skip-tests --skip-linter`.
   `cot_positions` full-refreshed (1954 rows, audit passed). `short_interest` FAILED the
   plan (all-or-nothing) because its source `short_interest_raw.parquet` is 0 rows
   (pre-existing G-blocked: FINRA data never pulled) — NOT caused by the COT work.
   Export then ran cleanly: `cot_positions.parquet` = 1954 rows, max 2026-08-25.
8. **fetch_cot.py rewritten** (qwen-coder): resumable append-only from the yearly
   `fut_fin_txt_{YEAR}.zip` archive, derives target codes from the pool, dedups on
   (code, date), no-op when current. `--dry-run` verified: 0 new rows, no write.

## Key facts
- `catalog_freshness` is a DYNAMIC view (computes `max_date` from the parquet live) — it
  auto-updated to 2026-08-25 with NO static edit. `data_catalog.yaml` has no COT date field.
- `research.duckdb` `cot_positions` view reads the parquet via `read_parquet()` (live).
  `research_v2.duckdb` does NOT exist (summary was wrong on that).
- Export resolves the physical table by version directly (`sqlmesh__warehouse.
  warehouse__cot_positions__<version>`), independent of the prod environment.
- **PROD ENVIRONMENT IS NOT COMMITTED**: `sqlmesh diff prod` still shows both models as
  "Added (Breaking)" because the plan failed on short_interest (empty source). The export
  still works (reads by version), but the prod env is inconsistent. Fix = make
  short_interest non-empty (FINRA data) OR yield-from-empty, then `plan --auto-apply`.
  Cron `run --ignore-cron` is safe (no-op when interval complete; no crash).
- `catalog_freshness.sql` on disk has only 6 branches (the 8 institutional branches live in
  the DuckDB view, not the .sql file — the file is stale/legacy; do not trust the on-disk
  file for the live view).

## Files
- `/data/parquet/cot/cot_tff.parquet` — 1954 rows, 2010-07-20→2026-08-25
- `/data/parquet/cot/cot_tff_lineage.json` — source fut_fin_txt_2026, appended 63
- `/data/parquet/institutional_positioning/cot_positions.parquet` — 1954 rows (typed export)
- `/data/agentic_trading/scripts/fetch_cot.py` — rewritten resumable
- `/data/agentic_trading/warehouse/models/cot_positions.py` — context.fetchdf fix
- `/data/agentic_trading/warehouse/models/short_interest.py` — context.fetchdf fix
- `/data/agentic_trading/scripts/export_warehouse_models.py` — resolve + COPY fixes

## Open
- short_interest prod-env inconsistency (needs FINRA data or empty-yield) — G-blocked.
- Form 4 / short interest / full 13F backfill still 0-row (separate workstreams).
- G1 (CUSIP→ticker), G3 (filer classification), G5 (equity_ref fundamentals) still open.
