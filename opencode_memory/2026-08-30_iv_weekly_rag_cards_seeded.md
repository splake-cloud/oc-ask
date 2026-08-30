# 2026-08-30 — IV weekly substrate RAG cards: authored, seeded, live on both roots

**Session:** opencode architect/validator seat (cwd /home/user/oc-ask).
Trigger: iron-fly study moving with its own agent; PM asked whether a RAG card describes the
IV weekly data (structure + access + refresh) and whether POOL_LEDGER is current.

## Answer to the PM's question
- **RAG card: NO** — live probe returned only the `iv_percentile_daily` DONOR (shares the
  "percentile" token); the two new models had no cards.
- **POOL_LEDGER: up to date** — `vol_infrastructure` correctly lists `atm_iv_daily` in
  `sqlmesh_tables`; `nyse_calendar` row already fixed for the 1990 extension. The weekly models
  are deliberately NOT in POOL_LEDGER (they are warehouse DuckDB tables, not `/data/parquet`
  datasets — registration = the SQLMesh model files). Nothing to add.

## Two root causes (not one)
1. **M2 was silently dropped by the harvester.** `scripts/rag_verifier/harvest_table_cards.py`
   `_parse_py_model` regex was `@model\s*\(\s*"(\w+)\.(\w+)"` — matches `@model("proj.model")`
   but NOT `@model(name="proj.model")`. `iv_weekly_percentile.py` uses the `name=` keyword form
   → parser returned None → no card. (M1 is `.sql`, parsed fine.)
2. **M1's auto card was too thin** — kind/cron/start + one docstring line; no schema/kernel/
   warm-up/access.

## Fix (EDIT, one file — dispatched to qwen-coder, verified by this seat)
`/data/agentic_trading/scripts/rag_verifier/harvest_table_cards.py` (uncommitted, working tree):
- Regex → `@model\s*\(\s*(?:name\s*=\s*)?"(\w+)\.(\w+)"` (optional `name=`, backward-compatible).
- New `SQLMESH_MODEL_OVERRIDES` dict (keyed by bare model name) with comprehensive
  `text_addendum` + `payload_extra` for the two models; applied in `harvest_sqlmesh_models()`
  via `text = text + " " + override["text_addendum"]` and `payload.update(payload_extra)`.
  Only those two names match → other 32 cards byte-identical. Chose to edit the HARVESTER
  (Checklist H step 3: "harvested well → fix the source"), NOT hand-write a staged JSONL
  (which `scan-stage` would clobber).

## Card content (facts fact-checked vs live warehouse.duckdb)
Both: 3,987 rows, 2021-05-13..2026-08-27. M1 3 rows/day (1,329 days).
- M1 `iv_weekly_state_daily` (SQL, INCREMENTAL_BY_TIME_RANGE, lookback 3, time_column trade_date,
  start 2021-05-13): 11 cols incl atm_put_iv (putMidIv at ATM strike, NULL never 0), obs_valid,
  expiry_resolved; source pool atm_iv_daily (vol_infrastructure); consumed by M2 + iron-fly.
- M2 `iv_weekly_percentile` (PYTHON, FULL, derived from M1): 12 cols iv_pct/iv_rank 10/20/60/252d;
  kernel = strictly-below IVP + min-max IVR (NOT PERCENT_RANK/NTILE); **252d structural-NULL
  caveat**: monthly only (first valid 2023-04-19), wk1/wk2 need 252 CONSECUTIVE valid priors,
  max run 241/240 < 252 → will not self-heal without a kernel change; refresh needs explicit
  restate (is_no_rebuild).
- Both: access = `duckdb -readonly /data/warehouse/warehouse.duckdb` → SQLMesh view
  `warehouse.<model>`; NOT a /data/parquet dataset (no POOL_LEDGER entry).

## Seeding (PM-gated, approved "go")
- `refresh_data_table_cards.sh stage` (CPU, no index): duckdb_views 268→270; diff vs backup
  `/tmp/opencode/rag_stage_backup_20260830/` = added 2, removed 0, content-changed 0 (133 lines
  version-only mtime re-stamp — benign).
- `refresh_data_table_cards.sh probe` (dry-run): GPU0 55,627 MiB free, fits both floors.
- `refresh_data_table_cards.sh go` — re-seeded all 4 data_table wells (data_location,
  table_recipes, duckdb_views, source_aliases) in BOTH roots (whole-well, not per-card; the 3
  sibling wells were pending from pre-existing parquet/catalog drift, independent of this change).

## Verification (Checklist E — the serving path)
- data_table group: full=live small=live, duckdb_views 270 rows.
- Keyed exact-fetch: both cards FOUND in both `/data/parquet/verifier_kb` and `_small`.
- Live service (`:8765`, serving the SMALL root) top-1:
  `iv_weekly_state_daily`→M1 [8.06], `iv_weekly_percentile`→M2 [8.69],
  `iv_weekly_state_daily weekly IV state substrate`→M1 [7.56]. Donor now ranked below.

## Traps / notes
- Live RAG probe MUST pass `collections` in the POST body — omitting it returns `ok:false` + 0
  rows, which looks like "card absent" but is a malformed request (bit me: first "n_results=0"
  was a false negative).
- The seeder re-stamps `version` from file mtime on every scan → a re-scan bumps ~133 version
  strings with no content change; diff on content (text/payload/title/source_type), not version.
- The harvester edit is UNCOMMITTED (working tree). Commit is a PM/git-enabled-seat step
  (this seat: git denied except `git -C /data/agentic_trading*`, and committing needs explicit ask).

## Next
- Nothing blocking. Iron-fly agent now grounds correctly on the IV weekly substrate.
- Optional: commit the harvester edit; the standing-janitor recommendation (from the 2026-08-30
  janitor run) is still open if PM wants the `m2_dev`/`dev_timing` dev-envs cleaned on schedule.
