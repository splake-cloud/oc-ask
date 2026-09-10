# 2026-09-09 — Cboe↔ORATS↔UW 0DTE SPXW join adjudication (3 dates, repaired)

Continues the gamma-backfill thread (see 2026-09-08_gamma_backfill_oom_crash card). The
prior session `ses_f791d29d9ffeFjygSKBzT83B8K` closed mid-run on a ContextOverflowError
while deciding how to re-dispatch the ORATS 0DTE pass; it had left a **CONDITIONAL**
disposition on a structurally-wrong GO-gate.

## What was decided / built
PM instruction: do NOT launch the 22-day ORATS pass yet. Repair + adjudicate the join on
the existing 3 dates (2026-03-02/03/04). The "Cboe matched / ORATS eligible = 0.0649"
gate is **invalid** because ORATS is a *quoted-surface* universe and Cboe Open-Close is
an *activity* universe — 0.0649 divided by the wrong denominator (the ORATS surface).

**Verdict: 0.0649 WITHDRAWN, CONDITIONAL RETRACTED, 3-date adjudication PASSES.**
Correct key-mapping = Cboe→ORATS = `|C∩O|/|C|` = **1.0000 on all 3 dates** (Cboe SPXW
0DTE is a strict SUBSET of the ORATS same-day PM-settled quoted surface).

## Key facts settled (with file paths)
- Canonical grain: `(trade_date, aligned_capture, expiration_date, strike_scaled,
  call_put)`; `strike_scaled = round(strike*10000)` INT64; `aligned_capture` = 10-min
  grid int HHMM. Decision window [1000,1550].
- ORATS (`/data/parquet/spx_intraday_strikes/year=2026/month=03/<date>.parquet`):
  `ticker` uniformly SPX (no SPXW root); 0DTE = `tradeDate=expirDate AND
  expiryTod='pm' AND dte=1`; 390 @1-min snaps; same-day surface = 226 strikes/snap.
- Cboe (`/tmp/opencode/investigation1/cboe_c1_2026-03/raw/`): 126 captures/day
  (00:00–17:00 + 20:20–23:50 @10-min; NO files 17:10–20:10 = structural product gap);
  SPXW 0DTE = `option_symbol='SPXW' AND expiration_date==market_date`; cumulative
  `mm_buy_vol`/`mm_sell_vol`; safe-differenced interval flow.
- UW teacher (`gamma_research` view in `/data/agentic_trading/research.duckdb`):
  36 snaps/day 08:50–14:40 ET, ~180 strikes, `side`∈{flat,positive,negative} (dealer-
  gamma SIGN, not C/P), `expiry_raw='all'` — **March is the all-expiry era** (the
  0DTE-specific UW teacher starts 2026-06-16). So T has no expiration_date/call_put.
- Node corridor: only 03-04 is a +50% touch day (body_strike=6875,
  `node_materiality.parquet`); 03-02/03-03 use spot-nearest fallback (6884/6828).
- **Absence semantics**: established independently from raw zips — `decrease=0` (no
  cumulative reversals), only sustained gaps are the structural no-file windows (flat
  100%), `increase=0` for real gaps, zero in-window flickers → `absence_means_no_activity
  = true` (absence = no C1 activity, NOT suppressed reporting). C_absent zero-filled.

## Six metrics (3-day agg)
1. Cboe→ORATS `|C∩O|/|C|` = **1.0000** (10980/10548/10188 all 100%)
2. Flow-weighted mapping = **1.0000**
3. UW→ORATS `|T∩O|/|T|` = **1.0000** (6624/6552/6516)
4. Cboe activity density on T `|T∩C_active|/|T|` = **~0.53** (0.518/0.577/0.500)
5. Three-way `|T∩O∩C|/|T|` (C present) = **~0.92** (0.961/0.893/0.909)
6. Node-corridor (±2% body strike) metrics 1,2,4,5 = **1.0 / 1.0 / 1.0 / 1.0**
Unmatched Cboe keys: **0 on all 3 dates**. Reconciliation identities (total=matched+
unmatched; flow total reconciles) hold EXACTLY, independently recomputed.

## Artifacts
- Logic: `/tmp/opencode/investigation1/join_adjudication.py` (frozen, deterministic —
  byte-identical across runs; per-day wall ~4.5s, peak RSS ~1.1–1.5 GB, bounded).
- Spec: `/tmp/opencode/investigation1/SPEC_join_adjudication_3date.md`
- Per-day O/C/T/reconciliation parquets + `adjudication_summary.json` +
  `ADJUDICATION_3date.md` under `/tmp/opencode/investigation1/join_adjudication/`.
- verify-run transcripts: `/data/agentic_trading/verify/join_adj_3date_{main,absfix,
  indep_recompute}.*.txt` (all exit 0; indep_recompute ALL_IDENTITIES_HOLD=True).

## Defect found + fixed
The first build's absence-semantics check used raw `HHMM` integer subtraction
(`curr_hhmm - prev_hhmm > 10`), which mislabels every hour boundary (09:50→10:00 = 50)
as a "gap" — flat_run_lengths were all 50, identical across days. Verdict was right for
the wrong reason. EDIT dispatched to qwen-coder: correct minute arithmetic + classify
structural vs real gaps + additive counters. Re-verified: real_increase=0,
real_decrease=0, n_series_checked=305/293/283 (matches true SPXW 0DTE series counts).

## Open / next (GATED)
- **22-day frozen run NOT launched** (PM: only after the 3-day adjudication passes — it
  now has). Estimate from the 3 dates: 22 × ~4.5s ≈ **1.5–2 min wall**, flat RSS.
  Same frozen `join_adjudication.py` logic across all 22 March business days. Awaiting
  PM go to dispatch.
- Conformance notes (honest, in the report): three-way reported on C-present (not
  absent) keys; node corridor on 03-02/03-03 is a spot-nearest fallback (not a fly body
  strike); the "real_gaps" in the absence JSON are the 17:00→18:00 structural sub-gap
  (labeling only — the load-bearing increase=0/decrease=0 evidence is unaffected).
