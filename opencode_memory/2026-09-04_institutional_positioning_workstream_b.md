# 2026-09-04 — Institutional Positioning Data Layer, Workstream B (13F + Reference Data)

Mission: BUILD Workstream B of the institutional positioning data layer per
`/data/agentic_trading/studies/institutional_positioning_intelligence/specs/build_spec_institutional_positioning_v1.md`.
Scope was 13F + reference data only (Workstream A = COT/Form4/short-interest/cftc_market_ref, already built in the same dir — NOT touched).

## What was built

1. **`scripts/fetch_13f.py`** (pattern a, direct parquet+lineage write)
   - Enumerates 13F-HR/13F-N filings via the SEC EDGAR **full-text search API**
     (`https://efts.sec.gov/LATEST/search-index?forms=13F-HR&dateRange=custom&startdt=..&enddt=..&size=100&start=..`).
   - Sub-windows by month (efts caps a single query at **10,000 hits**; a quarter has ~9,364 filings).
   - Resolves the standardized 13F holdings XML by scanning each filing's `index.json` for a
     non-`primary_doc.xml` XML whose body contains `<informationTable>` (the standardized filename is
     NOT stable: observed `13FReportOfManagedAssets.XML`, `infotable.xml`, `primebuchholz12312024.xml`, `PTE_PZU_2023q1.xml`).
   - Parses `<infoTable>` holdings into the typed `holdings_13f` schema (§2.1). Filer identity
     (cik/filer_name/period_end_date/filing_date/form) comes from the efts hit `_source`; holdings from the XML.
   - `ticker` is NULL until G1; stored by CUSIP.
   - **Resumable: window-level skip** — `holdings_13f_windows_done.json` records harvested windows; re-runs
     skip them (the parquet is the durable pool). This was a deliberate design: a per-filing row cache
     (first attempt) grew to 46MB for 278 filings and would not scale to the full backfill.
   - **Quarterly self-guard**: no-ops unless the most recent quarter-end is ≥45d old (`window_closed()`).
     Refresh window is a FIXED 45-day span after quarter-end (not growing to `today`), so a coarse cron
     no-ops idempotently via the window-level resume.
   - Rate-limited to 5 req/s (SEC throttles bursts below the nominal 10; observed 403s), 3 concurrent workers.
   - Flags: `--backfill` (2010+), `--window-start/--window-end`, `--windows` (multi-quarter slice),
     `--force`, `--max-filings`, `--no-resume`, `--dry-run`.

2. **`scripts/build_reference_data.py`** (pattern a, derived from holdings_13f)
   - `filers.parquet`: one row per distinct cik; `tier` from SUM(value_usd) per cik in its LATEST 13F window
     (1=>$5B, 2=>$1B, 3=rest); filer_type/strategy='unknown' (G3), aum_estimate=NULL, aum_source='unknown',
     inception_date=NULL, status='active', notes=''.
   - `equity_ref.parquet`: JOIN-KEYS ONLY (ticker NULL, cusip, issuer_name); G5-gated fundamentals NOT emitted.
   - `cusip_ticker_map.parquet`: SCHEMA STUB ONLY (cusip, ticker, source, as_of) — zero rows (G1-blocked).

3. **Registration (§5.4, all four per pool)**: POOL_LEDGER rows (status PROPOSED), data_catalog.yaml entries
   (read_via.canonical: none), views appended to `catalog/institutional_positioning_views.sql` (already in
   `SQL_SOURCES`), 4 `catalog_freshness` branches in `catalog/catalog_freshness.sql`. Applied via
   `catalog/register_catalog.py` to both research.duckdb + research_v2.duckdb.

4. **Cron** (live crontab, ET region before the `CRON_TZ=UTC` switch):
   - `0 6 * * * ... scripts/fetch_13f.py`
   - `0 7 * * * ... scripts/build_reference_data.py`

## Key facts settled (with evidence)

- **efts is the enumerator, not the submissions API**: the submissions API is per-filer and can't enumerate
  the universe; the spec's first-named source is the full-text search API. efts caps at 10,000 hits/query →
  month sub-windowing. efts `forms=13F-HR` filter returns `13F-HR` + `13F-HR/A` (amendments); `13F-N` total is 0
  (unused form).
- **The `<value>` element is dollar-denominated** (Trust Co of the South: 3M value=247466 for 1917 shares ≈
  $129/share). So tier thresholds are 5e9/1e9 (not 5e6/1e6).
- **Dedup must be on the FULL row identity, not CUSIP**: a fund commonly holds the same security across several
  sub-accounts (e.g. ABBOTT LABS CUSIP 002824100 held 4× at 273/60/1282/858 shares in one filing). A CUSIP-level
  dedup collapsed 61,446→27,638 (55%); only 1/414 rows in that filing was a true byte-identical dup. Fixed to
  `drop_duplicates()` on all columns → 104,035→103,991 (44 dups removed, correct).
- **SEC 403s are burst-sensitive**: urllib got 403s under a request burst even at nominal rate; curl with the
  same UA succeeded. Lowered to 5 rps + 3s backoff on 403.
- **Bounded slice run** (full 2010+ backfill is a multi-day follow-up at ~2.2 filings/s latency-bound):
  windows 2025-03-01..20, 2025-06-01..20, 2025-09-01..20 → **278 filings → 103,991 holdings, 116 distinct CIKs,
  period_end_date 2013-06-30 → 2025-06-30**. filers: 116 (tier 1:11, 2:16, 3:89). equity_ref: 16,358 rows
  (9,411 distinct CUSIPs). cusip_ticker_map: 0 rows.

## Verification (all 9 spec checks PASS)

1. holdings_13f COUNT = 103,991 (>0)
2. range 2013-06-30→2025-06-30, 116 distinct cik
3. filers COUNT = 116 (>0)
4. tier: 1→11, 2→16, 3→89
5. equity_ref cols = [ticker, cusip, issuer_name] (join-keys only, no fundamentals)
6. cusip_ticker_map COUNT = 0 (schema stub)
7. all 8 parquet+lineage files present
8. catalog_freshness: 4 branches (all frozen/FROZEN)
9. 2 cron entries present
Plus spec §9.2.1 (typed: shares BIGINT, value_usd DOUBLE, dates DATE) and §9.2.2 (0 null cusip, 0 non-null ticker).
`data_catalog_check.py`: my 4 entries add **0 new drift** (baseline had 4 pre-existing WS-A issues:
short_interest/insider_trades/cftc_market_ref — not mine).

## Declared deviations

- **Cron schedule**: spec §7.2 names `0 6 48 3,6,9,12 *` (day 48 never fires, max day 31). Per the spec's own
  declared decision #3 (§7.2 note), the builder uses a coarse schedule + in-script self-guard. I used a **daily**
  coarse schedule (`0 6 * * *` / `0 7 * * *`) in the ET region; the self-guard + window-level resume make it
  no-op idempotently until the quarter window closes. The literal `48` day would have been a no-op that never ran.
- **Bounded slice, not full 2010+ backfill**: per the spec's explicit allowance ("If the full 13F backfill is too
  large for a single run ... run a bounded slice ... and note that the full 2010+ backfill is a follow-up run").
  The lineage documents the bounded windows, not the full backfill.
- **Dateless reference pools use `governed_by: holdings_13f`** in data_catalog.yaml (filers/equity_ref/
  cusip_ticker_map have no populated date column). WS-A's dateless `cftc_market_ref` entry used
  `date_col: null` + `frozen_max_date: TBD`, which produces a "no resolvable date column" drift failure; I did not
  replicate that. `governed_by` is skipped by data_catalog_check.py (established box convention) and adds no drift.
- **catalog_freshness branches for dateless pools** follow WS-A's pattern (`CURRENT_DATE` + `from (select 1 ...)`),
  using `from (select 1)` for the 0-row cusip_ticker_map so the branch still emits a row.

## Files

- NEW: `scripts/fetch_13f.py`, `scripts/build_reference_data.py`
- MODIFIED: `catalog/institutional_positioning_views.sql` (+4 views), `catalog/catalog_freshness.sql` (+4 branches),
  `docs/data_catalog.yaml` (+4 entries), `docs/data_pools/POOL_LEDGER.yaml` (+4 rows), live crontab (+2 entries)
- DATA: `/data/parquet/institutional_positioning/` — holdings_13f.parquet (+lineage +windows_done.json),
  filers.parquet (+lineage), equity_ref.parquet (+lineage), cusip_ticker_map.parquet (+lineage)

## Open / next

- **Full 2010+ backfill is a follow-up run**: `python scripts/fetch_13f.py --backfill` (resumable; window-level
  skip). At ~2.2 filings/s latency-bound from this box, 2010+ (~10k filers × 16 quarters) is multi-day.
- **G1 (CUSIP→ticker)**: holdings_13f.ticker + equity_ref.ticker are NULL; cusip_ticker_map is a 0-row stub.
  Populating requires a CUSIP→ticker source (PM ruling).
- **G3 (filer curation)**: filer_type/strategy are 'unknown'; classification depth is PM-gated.
- **G5 (equity_ref fundamentals)**: sector/industry/exchange/shares/float/market_cap deferred until a source is named.
- **PM classification**: the 4 POOL_LEDGER rows are `PROPOSED — PM classification pending`.
- Stray pre-existing file `research.duckdb?mode=readonly` (dated Sep 2, before this session) left in place — out of scope.
