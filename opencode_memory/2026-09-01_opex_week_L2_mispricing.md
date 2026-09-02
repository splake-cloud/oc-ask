# OPEX Week L2 — Movement Mispricing (design + SSV acquisition)

**Date:** 2026-09-01 · **Status:** spec rev r3 committed `34913285`; awaiting PM
ratification of the r3 re-scope; SSV acquisition in flight (PM-owned).

## What this layer is

Question: *Is ordinary OPEX-week SPX movement systematically mispriced by the
options market?* (NOT "is IV high/low" — that was L1, closed.) Parent layers
`studies/opex_week/` (daily v1) and `studies/opex_weekly_L1/` (weekly) are
closed/byte-clean. L2 root: `studies/opex_week_l2_iv/` (new).

## Design settled (spec revs r1→r3, all 2026-09-01)

- **PM settlement doctrine (r3, load-bearing):** 09:30 SPX open is NOT an
  SSV/SET proxy (SET = constituents' official opening prices; can fall
  outside the SPX high–low). Open/close OPEX payoffs = unbounded valuation
  approximations — no floor, no verdict, not execution. Open-to-close is NOT
  an ambiguity band.
- **Primary (verdict-grade) = price-level contrast:** θ_price =
  mean(straddle price | OPEX) − mean(| non-OPEX), Holm family {val/mid,
  long/ask, short/bid}, 10 bp floor, month-clustered block bootstrap (10k,
  SEED=42), replication 2013–16 vs 2017–21. Execution gate: valuation sign
  picks direction; the corresponding ask/bid member must clear the floor.
  Direction-specific P&L: long = |S_T−K| − ask; short = bid − |S_T−K|. Mid
  never executable.
- **W1 = 2013–2021** (2012 excluded: vendor lists that year's expiries on
  Saturday). First-session-only snapshots (vendor gap → INCOMPLETE; ≤2-day
  fallback = sensitivity S6). Dual-series OPEX weeks (6 in 2021) EXCLUDED
  from primary; row-wise reporting, min/max identification sensitivity —
  never averaged (economically different AM/PM roots, unlabeled).
- **Non-OPEX settlement is exact** (PM-settled weeklies: spine close ≡ 16:00
  official close, verified p99 ±3.45 bp) → exact P&L tables for ordinary
  weeks. OPEX settlement P&L infeasible until SSV arrives.
- **Frozen §11 estimand** (θ_settle with S_T=SSV) runs unchanged when SSV
  history lands.

## Feasibility gate (read-only, all verified)

- Chain = ORATS EOD `/data/parquet/spx_daily_strikes` (2006-2021 usable,
  3997 files, year-partitioned; single ticker SPX, **no root/series label** —
  2013–2020 merged grids, 2021 OPEX co-lists both roots unlabeled).
- 482/482 weeks 2012–2021 have same-week expiries; 2013–2020 all single-ATM;
  2021: 6/10 OPEX dual-ATM, 0/31 non-OPEX.
- **My G0 anchor error caught:** original anchors 2012-03-19→23 and
  2021-09-20→24 were 4th-Friday weeklies, not OPEX monthlies. Corrected
  anchors: 2013-06-10, 2015-06-15, 2020-03-16, 2021-06-14.
- **Smoke-test bug caught by PM:** my "sane magnitude" table used a buggy
  row selection (`first() ORDER BY n_dup DESC` → arbitrary strikes): the
  "17.56% crash-week straddle" was strike 2870, not ATM. True ATM
  2020-03-16: K=2445, straddle mid 243.87 (9.98%), IV 119.5–120.0, Black
  backout Δ ≤ 0.45 pts, PCP −0.056 pts — now a G0 leg-reconciliation anchor.
- No SSV/SET anywhere on the box (duckdb, /data/parquet, data registry, RAG;
  525 GB live pool = PM-settled 0DTE only).

## SSV provider chase (2026-09-01)

1. ORATS (the box's provider; endpoint `api.orats.io/datav2/hist/strikes`,
   token root-only in /etc/default/spx_live_ingest): full 39-field payload
   has no settlement field; documented datav2 surface (docs fetched) has no
   settlement endpoint; authenticated probes: control 200 (302→S3
   `orats-data-api` objects), nonsense route AND settlements both 403
   "explicit deny" → 403 is blanket, route existence unprovable.
2. **ORATS support ruling: they don't have it; CBOE is the authoritative
   source.**
3. **CBOE verified:** SPX dashboard (cboe.com/us/indices/dashboard/SPX)
   shows daily Settlement Value (free, current day). Bulk history = **Cboe
   DataShop** → Cboe Global Indices **MAIN (SPX, VIX)** channel; pricing
   not published (login/quote). Quote ask drafted: one-time CSV 2012-01-01→
   2021-12-31, SSV + Closing Settlement Value, ~2,400 rows, research,
   non-redistributable (2012 included free-ride for later layers).
4. Massive.com (existing key): indices API = OHLC only, no settlement
   (checked full endpoint list). Databento: not on box at all.
- Probe scripts used: /tmp/orats_settle_probe{3,4,5}.sh (sudo, token never
  printed).

## Settlement acquisition (2026-09-02) — RESOLVED via public endpoint

PM instructions: pull the Cboe settlement values directly. **DataShop NOT
needed** — the free public endpoint
`https://www.cboe.com/index_settlement_values/get_sv_data/{S,W}/{YEAR}/` (no
auth) carries both feeds 2013–2021. Acquired by
`scripts/opex_l2_settlement_ingest.py` (18 files, 3 s polite rate, retries,
sha256): raw bytes `studies/opex_week_l2_iv/data/raw/`; manifest (url,
fetched_utc, http_status, sha256) `data/manifest.csv`; normalized
data/settlements_spx.csv (**1024 rows: 96 S, 928 W**); receipt + gap ledger
`data/receipts/ingest_v1.md`, `data/gap_ledger.csv`.

- Formats: 2020–21 structured JSON records (explicit expiration_date);
  2013–19 HTML fragments (S: 12 monthly sections, no dates → month mapped to
  the certified OPEX final session from pattern_opex_week; W: SPXW rows with
  explicit MM/DD/YYYY; label drift by year handled in parser).
- **GAP LEDGER (source-side omissions — fail-closed, nothing fabricated):**
  S missing 12 OPEX months (2014-12, 2016-12, 2019 Jan–Oct — public archive
  partial); W missing 82 chain weekly expiries (2013: 32, 2014: 16, 2015: 8,
  2016: 4, 2017: 6, 2018: 3, 2019: 7, 2020: 3, 2021: 3; 26 of 82 are Saturday
  expiries settling the prior session). Receipt status
  FAILED by design until PM fills (DataShop SPX index daily) or waives.
- Spot-checks vs spine (consistency, not identity): S vs open −5.4 / −6.5 /
  +6.0 pts (the measured open-vs-SET gap — small, nonzero: doctrine
  validated); W vs close −0.73 / +1.26 / +0.14 pts (≈0 → W = 16:00 close
  confirmed).
- Two W values on OPEX final sessions (2019-08-16, 2021-04-16) = the
  PM-settled SPXW weekly expiring ON OPEX day (dual roots) — provenance only,
  never referenced by the study.

**FILL RESOLVED 2026-09-02 (no DataShop login needed for 81 of 82 W + 11 S):**
- Parser bug found: a hidden `<input>` between `<h4>` and `<table>` made the
  section regex silently drop 11 S months (2016-12 + 2019 Jan–Oct) that were
  in the ALREADY-DOWNLOADED raw files all along. Window-based sectioning
  fixed it → S gaps 12 → 1 (only 2014-12-19; the 2014 file genuinely has 11
  sections). Ledger 94 → 83.
- **Yahoo Finance ^GSPC daily close (free, no auth) IS the same official
  16:00-close series as the public W feed**: overlap 928/928 dates, 923 exact
  within 0.01, worst 5.29 pts on one bad-tick day (2021-08-11). Raw JSON +
  normalized CSV in `studies/opex_week_l2_iv/data/yahoo/`.
- `--vendor` fill mode: overlap rule ≥99% within tol + no value > 0.5% off,
  W-only (vendor files have no AM settlement), T(E) on the file's calendar,
  **weekday holes never proxied** (a weekday expiry missing from the file is
  UNFILLABLE — caught Yahoo's 2018-12-05 hole; 2013-01-19 is a SATURDAY
  expiry so Friday-settle is legitimate). 81 filled; ledger → 2 pending:
  S 2014-12-19 + W 2018-12-05 (two-vendor hole). Status PARTIAL, post-fill
  G1 1007/1009 < 0.1% (2 known exceptions). Final: 1116 rows (107 S, 1009 W).

**Fill mechanism (2026-09-02, PM elected DataShop fill):** commit
`6e7a67a6`. `scripts/opex_l2_settlement_ingest.py --offline --fill <csv>`:
- **T(E) convention** (verified from the feeds): the public W feed dates
  rows by the settlement session; a chain expiry E settles at T(E) = latest
  trading day ≤ E (weekend expiries → prior session; S fills require
  T(E) = E — AM SET never proxied). The DataShop file's own date set is the
  authoritative calendar (the spine has vendor holes, e.g. 2013-01-19).
- Overlap validation BEFORE any fill: S column must match the 89 public S
  values exactly on all overlapping OPEX dates; W column within 0.01 on all
  928 overlapping W dates; per-candidate columns tried, 100%-passer chosen,
  else abort with stats. Filled rows tagged source=datashop + settlement_date.
- Test battery: synthetic file incl. decoy SSV column → PASS (1118 rows,
  ledger 94→0, 27 weekend-mapped fills); wrong-S-series → FAIL closed;
  missing OPEX date → FAIL closed. Ledger untouched on abort.
- Normalized table now has `source` + `settlement_date` columns for all rows.
- G1 note: 2 W rows (2016-01-29, 2020-03-18) deviate 0.11–0.34% from spine
  close (official vs vendor close) — spec G1 is ≥99% compliant; exceptions
  reported, not fatal.
- Commits `bb194be3` (ingest + data) + `70d3a221` (spec §10 final); verify
  transcripts verify/l2_settle_ingest_*.

## Open / next

- **2 weeks remain pending** (both in the ledger, INCOMPLETE in the primary
  unless resolved): S 2014-12-19 (AM SET — no public source carries the AM
  print) and W 2018-12-05 (Wednesday absent from Yahoo AND the spine —
  two-vendor hole). PM: one DataShop SPX daily file resolves both, or waive
  (n floors hold either way).
- Then: BUILD+EXECUTE dispatch to qwen-coder per house envelope (spec rev
  r4; gates G0/G1(+settlement)/G2/G3; main-seat re-verification of a sample
  of weeks).
- L2 memory card gets results section post-run.
- L3 (OI/gamma/auction) + prospective OPEX Monday accumulation unchanged.
