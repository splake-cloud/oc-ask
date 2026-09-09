# 2026-09-09 — SPX intraday vol-state (IV + RV) to live-frequency

**Objective.** Bring IV and RV volatility statistics to intraday (sub-checkpoint)
frequency so they are usable for live trading, while the EOD SQLMesh warehouse keeps
accumulating the historical record. Two deliverables, both built + independently
verified this session; **both committed + pushed** (`f6e56d30`). A second thread in
the same session — the `uw_gamma` EOD gate failure — was root-caused, re-certified,
and pushed (`4626d695`, see "uw_gamma re-certification" below).

## Decisions (PM/operator rulings, this thread)
- **IV source = SPX options** (`stg_spx_options_live`), collect **BOTH call and put**
  mid-IV at the ATM strike (matches the `atm_straddle_0dte_daily` precedent). Primary
  `atm_iv` = **put** IV, to stay comparable to canonical `atm_iv_daily`.
- **RV source moved ES → SPX.** EOD RV from `spx_1min` (Massive I:SPX). **Live RV from
  ORATS `stockPrice`** (per-minute in `current_session.parquet`, same 5-min
  clock/underlying as IV) because `spx_1min` is **15-min delayed** (Massive feed) and
  would defeat sub-checkpoint freshness.
- **ES `rv_daily` stays as-is** (no cutover). SPX assets are additive/parallel: canonical
  (ES) for backtest, SPX for the live/trading path.
- **Live layer = script + cron**, NOT a SQLMesh model, NOT the canonical/5-gated path.
  Canonical stays EOD.
- **Freshness ceiling = 5 min** (ORATS options refresher cadence). One shared clock:
  `as_of = MAX(snapShotEstTime)`; IV and RV both derive from `stg_spx_options_live`.
- **RAG/seat-config updates deferred until after the data work** (user instruction).

## Deliverable 1 — `warehouse.rv_daily_spx` (EOD SQLMesh model)
- File: `/data/agentic_trading/warehouse/models/rv_daily_spx.py` (UNTRACKED).
- Built by 3rd dispatch to the sqlmesh-builder seat (model override
  `coder-ask/qwen3.6-35b-a3b-q8` — the default `qwen38-seat/qwen3.8-27b-fp8` burns its
  16k output budget on reasoning and goes in circles with 0 tool calls; the fix is a
  commit-rule, see below).
- **Single-branch, NO `cumulative_offset`/`active_contract`/roll seam** — SPX is a
  continuous cash index (unlike ES). 17 cols, 6 checkpoints {1130,1230,1330,1400,1430,1500},
  0931 absent (IV-only). `TRADING_DAYS_PER_YEAR=252`, `MINUTES_PER_RTH=390`.
- Test: `/data/agentic_trading/tests/test_warehouse_rv_daily_spx_equivalence.py`
  (UNTRACKED, **11/11 pass in ~2.4 s**). I rewrote it to be **self-contained**: it
  materializes the repo model into a throwaway duckdb via `Context.plan(auto_apply=True)`.
  The seat's original hardcoded `/var/tmp/oc_sqlmesh-builder/scratch_warehouse.duckdb`
  (a transient-state landmine) and queried `warehouse.warehouse.rv_daily_spx` — the real
  scratch view is `warehouse.rv_daily_spx` (SQLMesh exposes the model as a view over the
  versioned physical table `sqlmesh__warehouse.warehouse__rv_daily_spx__<ver>`).
- PM spec: `.ai/inbox/build_spec_rv_daily_spx.md` (sha256
  `e144ca0f7e1d9c165907772a25e6f9ecc1540298d1e494315a75271ea92bfa2c`).
- Receipt: `local-ai/seed_author/production_delta/rv_daily_spx/` (BUILDER_RECEIPT.json
  CERTIFIED by `scripts/validate_builder_receipt.py` + BUILDER_RECEIPT.md + REPORT.md).
- NOTE: the pre-existing house test `tests/test_warehouse_rv_daily_equivalence.py` is
  **itself broken** (references nonexistent `warehouse/config.yaml`; the warehouse uses
  `sqlmesh.yml`) → "1 failed, 1 passed". NOT introduced by this work.

## Deliverable 2 — `scripts/refresh_vol_live.py` (intraday live refresh)
- File: `/data/agentic_trading/scripts/refresh_vol_live.py` (UNTRACKED). Built by
  `qwen-coder` subagent (default lane).
- Short-lived cron script; every ~5 min during the US session it reads the current ORATS
  options snapshot + SPX prices and publishes the current intraday IV/RV state as a
  single-row parquet. READ-ONLY against every `/data/parquet` source; writes ONLY under
  `--out-dir`. Atomic (`<path>.tmp` + `os.replace`), single-writer, no threads/locks.
- **26 columns** (spec said 24 in one clause — counting error; 26 is correct and complete):
  as_of, trade_date, iv_as_of, rv_as_of, spx_price, atm_strike, put_mid_iv, call_mid_iv,
  iv_spread_cp, atm_iv, iv_valid_put, iv_valid_call, rv_intraday_raw, rv_intraday_ann,
  n_rth_minutes, rv_5d, rv_10d, rv_20d, iv_rv_spread_{5,10,20}d, iv_rv_ratio_{5,10,20}d,
  iv_rv_spread_intraday, iv_rv_ratio_intraday.
- IV: both call+put mid-IV at ATM strike; ATM strike = `FLOOR((spot+12.5)/25)*25`; tie-breaker
  `(putMidIv>0) DESC, putMidIv DESC` (== canonical `atm_iv_daily.sql:48-50`); `atm_iv=put`.
- Intraday RV: from ORATS `stockPrice` (rows 930–1559, `>0`, `DISTINCT snapShotEstTime`),
  `SQRT(SUM(lr^2))` raw, `SQRT(SUM(lr^2)*252*390/n_returns)` ann; `n_rth_minutes=n_returns+1`.
- Rolling RV 5/10/20d: from `spx_1min` RTH closes (hour/minute cols; `>9:30, <16:00, >0`),
  `close_to_close_return=LN(close_d/close_{d-1})`, `STDDEV(ret)*sqrt(252)` over the N days
  **immediately before today (today excluded)**. Matches `rv_daily.py:97` convention
  (DuckDB sample stddev).
- Stale guard (SPEC.1): if `status.session != today_et` OR `now - refreshed_utc > 10 min`
  → print `STALE: ...` and exit 0 with no write.
- Test-only hooks: `--force-date YYYY-MM-DD` (override today for the guard) and
  `--test-status <path>` (fabricated status.json).
- **INDEPENDENTLY VERIFIED** (not just the delegate's report) via
  `verify-run refresh_vol_live_verify` → transcript
  `/data/agentic_trading/verify/refresh_vol_live_verify.20260909T113723Z.txt`, **ALL PASS,
  exit=0**. Every field re-derived from scratch in a separate duckdb query: spot 7669.36,
  atm_strike 7675, put/call IV 0.0552/0.0556, n_rth_minutes 390, rv_intraday_ann 6.2411%,
  rv_5d/10d/20d = 11.252%/8.699%/8.170% (4699 prior days). Idempotent re-run confirmed
  (SKIP, exit 0). Real-run guard confirmed: today=2026-09-09 vs source session=2026-09-08 →
  correct `STALE`.

## Key facts settled (with source)
- `spx_1min` HAS `hour`/`minute` BIGINT cols (so bare-column RTH SQL is valid);
  `datetime` is US/Eastern; sole writer is the Massive I:SPX live service (15-min delayed).
- `current_session.parquet` is the canonical 0DTE slice (tradeDate=expirDate, expiryTod='pm');
  exactly ONE `stockPrice` per `(tradeDate, snapShotEstTime)`; 250 strike rows/snapshot;
  390 RTH snapshots 930–1559. Full day = 390 (status says 390, partial_session=true because
  it was mid-ingest; the 1559 row is present).
- `refresh_0dte_live.py` is the reference pattern (atomic tmp+os.replace, retry×3,
  stale-beats-truncated, status.json) that `refresh_vol_live.py` mirrors.
- DO NOT run `sqlmesh plan/run/apply` against the real warehouse state
  (`/data/warehouse/warehouse.duckdb`) — use a scratch project.

## Commit / push state
- **Both deliverables committed + pushed as `f6e56d30`** (vol live work). No longer untracked.
- The `uw_gamma` re-cert from the same session pushed as **`4626d695`** (it rode along
  when the ES/institutional-positioning session rebased the shared local stack and pushed;
  all 10 files byte-identical on the remote, Agent-Print trailer intact).
- A dangling local `commit-tree` (`5643383b`) from an aborted "push just my commit" attempt
  is **NOT** on the remote — it was a naive tree-swap that would have dropped other
  sessions' files; caught before push, now orphaned locally.

## Open / next
- **Cron + real out-dir not wired.** `refresh_vol_live.py` is OUT_DIR-parameterized and
  builds/tests against scratch (honors read-only `/data/parquet`). Choosing the real
  production out-dir and adding the cron entry is a PM/ops step, not done.
- `rv_daily_spx` not yet registered/added to the warehouse plan (no `sqlmesh plan/apply`
  run — would touch the real warehouse state). Backfill to live is a separate, PM-gated step.
- **Deferred (user-ordered: after data work):** RAG/seat-config updates — commit-rule in
  the sqlmesh-builder seat config, its smoke test, and the stale RAG activation card
  (wrong #3 pre-flight path; documents helm.py flow but the seat was staged via
  `scripts/oc_seat_stage.experiment.py`).
- Pre-existing ES test `test_warehouse_rv_daily_equivalence.py` still broken
  (references `warehouse/config.yaml`); left alone (not this thread's scope).

## uw_gamma re-certification (second thread, same session)
- EOD SQLMesh build red-lined on `uw_gamma` alone (all 12 health checks green otherwise).
- **Root cause:** `/data/parquet/gamma_intraday` is **restating** — the laptop `GammaEOD`
  job + `gamma/gamma_lake_sync.sh` atomic swap rewrites historical dates. The 2026-09-08
  20:16 UTC re-capture changed 18 May–Jun dates (+1 late 20:00Z snapshot each, spot restated)
  → the frozen-slice exact count-pins in `sqlmesh/tests/uw_gamma_equivalence.py` broke
  (4 FAIL → 15 FAIL).
- **PM ruling — Option A:** accept the 09-08 re-capture as new certified truth; split into
  two materializations:
  - **A — frozen/certified**: `pools/uw_gamma/certified/20260909_post_restatement/`
    (pinned, immutable, git-tracked; re-verifiable via `RE_CERTIFICATION.md`).
  - **B — growing**: the live pool (`pools/uw_gamma/*.parquet`, gitignored, rebuilt in-place
    daily by `build_core.py`); gate checks it with **restatement-stable** checks only
    (structural invariants + per-date raw-lake row reconciliation), **no exact count-pins**.
- **New certified frozen-slice values** (`< 2026-09-02`): per_strike 1,592,730 / 7,280 snaps
  / 550 strikes / gamma_zero 840,753 / gamma_null 1,882 / spot_null_pre_0616 4,123;
  snapshot 7,280 / 7,197 accepted / 74 off-schedule / 9 null_net_gamma; manifest 368 (184+184).
- **Gate reworked 32→21 assertions, ALL PASS** (verify-run deposit
  `verify/uw_gamma_gate_growing.20260909T123140Z.txt`).
- `data_catalog_check` OK (line 704 re-pinned 1587919→1592730).
- Docs updated: `docs/data_catalog.yaml`, `docs/data_pools/POOL_LEDGER.yaml`,
  `pools/uw_gamma/SQLMESH_BRIEFING.md`.
- Mutation boundary respected: no SQLMesh state-DB writes, no `docs/SQLMESH_*` writes,
  no `sqlmesh plan/apply`.

## Relevant files
- `/data/agentic_trading/warehouse/models/rv_daily_spx.py` — SPX RV EOD model (committed `f6e56d30`).
- `/data/agentic_trading/tests/test_warehouse_rv_daily_spx_equivalence.py` — self-contained, 11/11 (committed).
- `/data/agentic_trading/scripts/refresh_vol_live.py` — intraday live refresh (committed).
- `/data/agentic_trading/pools/uw_gamma/certified/20260909_post_restatement/` — pinned frozen-slice artifact (4 parquet/csv + `RE_CERTIFICATION.md`), the re-validation anchor (committed `4626d695`).
- `/data/agentic_trading/sqlmesh/tests/uw_gamma_equivalence.py` — reworked gate, 21 restatement-stable assertions (committed).
- `/data/agentic_trading/pools/uw_gamma/.gitignore` — anchored (live copies ignored, pin tracked).
- `/data/agentic_trading/pools/uw_gamma/SQLMESH_BRIEFING.md` — re-certification record.
- `/data/agentic_trading/verify/uw_gamma_gate_growing.20260909T123140Z.txt` — verify-run deposit (21/21 PASS).
- `/data/agentic_trading/verify/refresh_vol_live_verify.20260909T113723Z.txt` — verify-run deposit (Phase 2, ALL PASS).
- `/data/agentic_trading/.ai/inbox/build_spec_rv_daily_spx.md` — PM spec (sha256 above).
- `/data/agentic_trading/local-ai/seed_author/production_delta/rv_daily_spx/` — receipt + report.
- `/data/agentic_trading/verify/refresh_vol_live_verify.20260909T113723Z.txt` — verify-run transcript.
- `/data/agentic_trading/warehouse/models/rv_daily.py` — ES RV reference (roll logic the SPX model omits).
- `/data/agentic_trading/warehouse/models/atm_iv_daily.sql` — canonical ATM formula + tie-breaker.
- `/data/parquet/spx_1min/spx_1min.parquet` — EOD RV source (Massive, 15-min delayed).
- `/data/parquet/stg_spx_options_live/current_session.parquet` + `status.json` — live IV + stockPrice-for-RV (5-min, 0DTE PM slice).
