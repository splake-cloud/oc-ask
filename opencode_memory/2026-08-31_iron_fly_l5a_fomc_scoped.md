# 2026-08-31 — Iron Fly L5-A FOMC event conditioning: BUILT + CLOSED

Session `ses_fabec1502ffeehxAP14Y11aDp4`. Objective: determine whether FOMC
event risk — a scheduled FOMC statement landing INSIDE the iron fly's
Mon 11:30 → Fri 15:59 holding window — impacts the weekly iron-fly outcome.
**BUILT + VERIFIED + CLOSED (2026-08-31). Result: MIXED — FOMC weeks are a
DIFFERENT trade (higher premium, larger move, more wing breaches), net TP50
PnL lower (full Δ −10.06, CI [−23.44, +3.50] crosses zero). No rule change.**

## Artifacts (uncommitted)
- Spec: `studies/iron_fly_weekly/specs/iron_fly_L5-A_fomc_event_conditioning_scope.md`
  (RATIFIED v2). L5 = new axis: external scheduled macro-event conditioning.
- Script: `studies/iron_fly_weekly/scripts/iron_fly_l5a_fomc_event_conditioning.py`
- Outputs: `studies/iron_fly_weekly/outputs/l5a_fomc_event_conditioning/` (6 files)
- Receipt: `studies/iron_fly_weekly/receipts/l5a_fomc_event_conditioning.md`

## FOMC data found on workstation
- `/data/parquet/fomc_pool_v1/` — built pool: `band_a/band_a.parquet` (1.09 GB
  option chains, dte<=7, OUT OF SCOPE), `spot_1min/spot_1min.parquet`
  (37,530 bars, 48 events, T-1 09:30→T 16:00), `_lineage.json`.
- `/data/parquet/fomc_calendar/fomc_calendar.parquet` — separate calendar ref
  (meeting_date, sep, status, source); NOT the statement events.
- **Authoritative events:** `docs/fomc_pool/fomc_events.v003.REVISED.yaml` —
  49 verified statement events, 2020-09-16→2026-07-29; `statement_ts_et`
  ∈ {14:00 ×48, 10:00 ×1 (2025-08-22 Fri)}. NO standalone events parquet
  (the pool's events table was never materialized — only band_a + spot_1min).

## Data-access review (qwen-coder EXPLORE `ses_fa7eb3d32ffelv636LeBXIiJRr`)
7/7 PASS verbatim:
- Frozen 100W outcomes: 352 trades / **179 distinct entry weeks**,
  2022-06-06→2026-08-17 (warehouse has 182; 3 non-FOMC weeks lack 100W trades).
- Timezone: both ET wall-clock — direct join valid (entry Mon 11:30:00,
  exit Fri 15:59:00).
- **Core split (review said 34/145 on the 182-week WAREHOUSE — superseded):**
  on the **179-week frozen CSV** the true split is **33 FOMC / 146 non-FOMC**
  (adjudicated 2026-08-31, `l5a_split_adjudication2` / `l5a_fomc_week_probe`).
  Two in-window meetings have no enterable 100W trade → excluded: 2025-03-19
  (Mon 2025-03-17, warehouse week w/o 100W entry row) and 2026-06-17 (Mon
  2026-06-15, no 100W substrate data). In-window rule: meeting_date ∈ [Mon,
  Mon+4d] AND statement after Mon 11:30.
- spot_1min: 8 cols (event_id, bar_ts, OHLC, bar_source, bar_stamp), 48
  events, 782 bars/event. **2025-08-22_1000 missing** (only spot gap).
- 14 events predate the fly (2020-09→2022-05) — excluded.

## Blueprint key design points
- **A-priori mechanism (the real question):** iron fly = short-vol/short-
  straddle (wings body±100). FOMC = scheduled vol event landing mid-hold.
  Two opposing channels: pricing (higher IV → richer entry credit → favors
  short) vs realization (large |move| breaches wings → loss to max_risk).
  Net = realized move vs richer premium. All move stats are |·| (two-sided).
- **Load-bearing confound (§6.1) — PM-corrected (2026-08-31):** original
  draft said "FOMC→higher IV→higher credit→higher R"; PM ruled the last
  step is NOT automatic because R = entry_credit/friday_straddle and the
  denominator can also rise. Corrected language (PM-verbatim): "FOMC exposure
  may alter entry credit, Friday-straddle premium, R, and P_W. Their
  distributions must therefore be reported separately before interpreting
  gated comparisons." The higher-IV/richer-credit channel is a plausible
  HYPOTHESIS, not an identity. Handling unchanged: report credit,
  friday_straddle, R, P_W each SEPARATELY + realized move (§5.2), both
  populations, optional matched comparison.
- **PM correction 2 — wing-breach rate was misdefined:** was "|Friday
  close-to-close move| > 100". Corrected to distance-from-BODY-STRIKE:
  (a) terminal |SPX(Fri15:59)−body|>100; (b) any-time max_t|SPX_t−body|≥100.
  (close-to-close is net change between closes, not distance from the strike
  the wings protect.) §5.2 move stats also re-based to |SPX−body|, not
  close-to-close.
- **PM correction 3 — spot source limit:** spot_1min covers T-1 09:30→T 16:00
  (T = statement day, ~Wed), does NOT extend to Friday 15:59. §5.3 re-scoped
  to same-day statement reaction only; the through-Friday leg uses the
  iron-fly substrate's own SPX path (MFE/MDD/friday terminal), not the pool.
- **Estimands = THREE output tables (PM-specified 2026-08-31):**
  - **Table 1 (primary)** `l5a_table1_outcome_primary.csv`: FOMC vs non-FOMC
    + Δ, for **BOTH FULL and R≥0.70 gated** (OQ1 RESOLVED = both). 14 metrics:
    n weeks, n trades, TP50 reach, TP50 win rate, Mean TP50 PnL, **Median
    TP50 PnL**, 35→50 continuation, Mean MFE, Mean abs MDD, Mean terminal
    fallback, Mean entry credit, Mean Friday straddle, Mean R, Mean P_W
    (+ wing-breach rows + CI on Δ mean TP50 PnL).
  - **Table 2 (mechanism)** `l5a_table2_mechanism.csv`: FOMC vs non-FOMC —
    entry premium, Friday-straddle premium, R, P_W, realized SPX movement.
  - **Table 3 (FOMC-only reaction)** `l5a_table3_statement_reaction.csv`:
    immediate same-day statement moves (±5m/±15m/±30m/±2h/T 14:00→16:00),
    per-event rows + summary; spot ends at statement-day close (no Friday leg).
- **Outlier:** 2025-08-22 Fri 10:00 (5h59m before exit, no spot data) —
  include in primary + sensitivity excluding it.
- Gates G0–G5 (incl. reproduce **33/146** split EXACTLY + L4-A 13.9987 anchor
  on pooled gated). Descriptive-first, week-cluster bootstrap, seed 20260902,
  no pass/fail threshold (n=33).
- **OQs — ALL RATIFIED (PM, 2026-08-31):** OQ1 BOTH (FULL + gated); OQ2 NO
  matching (raw split + §5.2 decomposition only); OQ3 immediate reaction
  (Table 3 in v1); OQ4 include 2025-08-22 Friday event + sensitivity; OQ5
  week-level exposure / week-cluster; OQ6 descriptive clustered CI.
- **BLOCKER RESOLVED (full-hold SPX/body-distance availability):** probe
  `ses_fa7bb9309ffeZ7fIKHsePae5kD` (6/6 PASS) proved the full-hold SPX path
  IS available in the canonical substrate `spx_close_5min`/`spx_high_5min`/
  `spx_low_5min` (span Mon11:30→Fri15:59, ~0.9–1.1% nulls only at
  09:31–09:34 pre-first-5min-bar; body_strike present). NOT in the two
  frozen CSVs (scalar mfe/mdd only) → build reads the substrate for the SPX
  path, joined on (entry_ts, body_grid, wing_width=100, body_strike);
  max-excursion uses spx_high/low (intra-bar extremes). §4 source table +
  G0 updated to bind the substrate (version 1103730983).
- **CLEANUP DONE — Table-3 return definitions frozen (§5.3):** source
  spot_1min (1-min, ET wall-clock, bar_stamp HHMM, statement bar present).
  Signed close-to-close ret(h1→h2)=(C(h2)−C(h1))/C(h1) in bps + |·|;
  columns ret_pm5/pm15/pm30/pm120 (S∓Δ→S±Δ), ret_stmt_close (S→1600),
  pts_pm30 (points). Anchor rule: if S−Δ<0930 anchor at 09:30 open +
  anchored_open=1 (affects only 2025-08-22 10:00). Missing bar → NA +
  incomplete_window=1 (no silent drop). 2025-08-22 has no spot data →
  excluded from Table 3 (no_spot_data), kept in Tables 1–2.

## Build + results (2026-08-31)
- **Build:** qwen-coder `ses_fa7b0f14cffezMzHQvmDhNxJCq` (6/6 artifacts, gates
  PASS). G1-gate-tightening EDIT `ses_fa79a9dfdffedufKkPyzn018ho` (exact 33/146
  + exact 33-date set; outputs byte-identical). My verify-run `l5a_final_gate`:
  exit 0, all G0–G5 PASS, byte-identical re-run, `grep -c FAIL`=0.
- **RESULT (MIXED):** FOMC weeks enter at a different premium (credit +3.8,
  friday-straddle +10.7, R −0.053) and show larger realized moves (terminal
  +13.1 pts, max excursion +15.7 pts) + more wing breaches (terminal +0.118,
  any-time +0.095); net mean TP50 PnL 4.90 vs 14.97 (Δ −10.06, CI [−23.44,
  +3.50] crosses zero). Same direction gated + both grids; grid-5 CI excludes
  zero (−0.71 vs 15.35). Table 3 (n=32): no consistent same-day direction
  (median stmt→close −21 bps; tail = 2024-07-31 160 bps). Sensitivity
  excl-2025-08-22: pattern robust (Δ worsens to −10.82).
- **Data-quality notes (in receipt):** MFE/MDD are PnL-path metrics (max/min
  of pnl_path), NOT SPX distance — the "lower FOMC MDD" is two 2024-04-22
  non-FOMC outliers (mdd −4996.67 bad-mark artifact); median MDD identical
  (−26.8 vs −27.4). `realized_move_terminal_pct_wing` is mislabeled (spec
  (pts/100)*100 is a no-op → equals points). spot_1min lacks the 16:00 bar for
  2026-04-29 + 2026-07-29 (incomplete_window=1, NA not 0). tp50_win_rate ==
  tp50_reach by construction (all 197 reached trades pnl>0).
- **LSP false alarm:** write-time LSP flagged IndentationError in the L5-A
  script — stale mid-edit snapshot; `py_compile` + `ast.parse` both OK on the
  final file (`l5a_indent_recheck`).

## State
- **CLOSED.** All artifacts uncommitted (spec + script + 6 outputs +
  receipt). Awaiting PM commit/next direction.
