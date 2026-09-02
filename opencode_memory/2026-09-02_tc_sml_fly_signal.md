# 2026-09-02 — TC "Strongest Morning Line" as a conditional signal for the SPX 0DTE put-fly

Topic: does the Discord channel author's **SML (Strongest Morning Line)** / **SAL (Strongest Afternoon Line)**
carry edge for the desk's SPX 0DTE long-put butterfly as a condition on the convergence tree
(premium% gate → SML side)? Plus a re-derivation of the "gold cell" peel/runner.

**STATUS (after three audits): the line-specific tradable structure largely did NOT survive.**
The only robust findings are the **premium% entry gate** (not line-related) and the **SML/SAL
morning price-magnet** (a price-path effect, not a fly P/L signal). The SML *direction* entry
edge, the **SML "ceiling"/exit**, and the gold-cell×SAL hold finding were each **retracted or
downgraded** by the audits below. Full detail in
`/data/agentic_trading/analysis/sml_fly_verify/TECHNICAL_REPORT.md` (17 sections) + 9 verify scripts.

## Constraints (stated once — professional desk, don't re-qualify small-n every message)
- **Fill data excluded** — ORATS bid/ask worst-fill is too conservative; ALL analysis on **mid** marking.
- **ES is the live anchor**; **SPX is a hand-waved estimate** from the ES-SPX spread. Fly test is vs
  **SPX**; repaired rows snap SPX to the true `spx_1min` index level.
- **SML is a MAGNET** (price migrates toward it). Direction (above/below body) is the tested axis;
  proximity-to-body is NOT the signal.
- **POINT-IN-TIME-SAFE joins** (decisive, from audit #1): the reference line = the most recent line
  printed **at or before** the decision time; if none, no line (entry → side='none'; hold → drop the
  row). The earlier "first line of the day regardless of print time" **leaked** on ~30% of entry days
  and 20/21 gold-cell×SAL rows.

## Data built
- `data/discord/strongest_lines.parquet` — **600 rows** (336 SML, 263 SAL, 1 GENERIC) from the
  VolSignals.com Discord export (`~/discord-export`). 2025-02-13→2026-09-01 (326 SML days). SML
  first-print spans 9:49–15:30 (only 32% before 11:00, 30% after 11:30 — *not* "always before 11").
  SAL first-print spans 11:55–15:56 (249/263 in 14:00–15:59).
- Repairs: 14 SPX backfilled, 9 ES digit-garbles fixed, 16 SPX snapped. 600/600 coverage.
- Do NOT use `es_continuous_databento close − cumulative_offset` as ES ground truth (roll-seam artifact,
  ~50-70pts off on a subset; ES ends 2026-08-31).

## THREE AUDITS (the load-bearing part of this thread)
Each audit was prompted by a valid critique, confirmed empirically, and removed a claimed piece.

1. **POINT-IN-TIME audit** (`verify_07_pit.py`, report §2.1) — look-ahead on the line joins.
   - **F6 gold-cell×SAL: RETRACTED** (n collapses 21→1; the SAL printed 17–133 min *after* the +50%
     touch — the "SAL aligned → 100% reach 2x" was reading the afternoon path back into the morning).
   - **F9 hold: survives only as *afternoon-only*, smaller** (n=342; was n=525 leaked).
   - Entry SML leak was **conservative** (removing it *strengthened* the 11:30 tilt).
2. **CLUSTERING / pseudoreplication audit** (`verify_08_cluster.py`, report §2.2) — pooled 3
   checkpoints (~3 rows/day, within-day win corr 0.63) and tested as independent.
   - **Premium% GATE survives valid (day-level / cluster-robust) inference** (cheap-vs-exp p≈0.000).
   - **SML-direction cheap-cell REFINEMENT does NOT** — valid p 0.135–0.320, not the claimed ~0.02
     (the p=0.017 pooled was the understated SE — exactly as predicted).
   - **SML direction is only a *marginal 11:30* tilt** (all-premium, p=0.039, one row/day); 12:30 has
     none. NOT an established edge.
3. **GEOMETRY / exit audit** (`verify_09_geometry_exit.py`, report §6) — the old F3 "SML ceiling."
   - **F3 RETRACTED** as both a ceiling test and a live exit. It was (a) **outcome-on-outcome**
     (15:55 close → 15:55 target), (b) **butterfly payoff geometry** (distance from the body;
     corr(close−body, close−SML)=0.89; SML is body+gap, median gap 10), and (c) **temporally
     impossible** ("cut if SPX closes above the SML" = the day is over).
   - Live "cut at SML+25" test: the fly is **already worth ~0** at the cross (past the upper wing,
     body-distance ~40) and holding was **never worse** (0/88). The "ceiling exit" is the payoff,
     observed after the fact.
   - Small residual (SML-near vs far at same body-distance: 74% vs 31%, p=0.00) but axes are
     collinear → NOT cleanly separable from geometry; not established.

## WHAT SURVIVES (defensible) vs WHAT DIDN'T
**Defensible (robust under valid inference, not geometry):**
- **Premium% is the entry gate** (not line-related): cheap ≤28% ≈ 53-60% vs expensive >45% ≈ 15%;
  monotone; survives day-level clustering (cheap-vs-exp p≈0.000; GEE OR 0.15). **The only robust
  entry factor.**
- **SML attraction fades AM→PM; SAL is the PM magnet** (F7, p~1e-55, 326 days) — a *price* effect:
  SML pulls SPX toward it in the morning (2.27 approaches/day) and stops pulling by the afternoon
  (0.67); the SAL takes over in the PM. **Tradable content = the magnet/path, not a fly exit.**
- **The line is a specific, real, idiosyncratic tick** (F4): 16.4% on round-5 (null 10%), ~1.5×
  random → an arbitrary tick, not a generic round number.

**Suggestive (NOT capital-grade):**
- **SML-above at 11:30 → marginal +15pp tilt** (all-premium, p=0.039, one row/day); cheap-cell
  refinement not significant. Secondary tilt, not an edge.
- **F9 (afternoon-only):** after the SAL prints, SAL on the body → steadier remainder (dip 13% vs
  35%, n=342, p=0.000) but confounded by SPX position at SAL print; does NOT extend the runner.
- **F2 path quality:** SML-above = rough path (MAE ~1.85 wings) but small-n (n=43).

**RETRACTED:** F3 "SML ceiling/exit" (geometry), F6 gold-cell×SAL (look-ahead, n→1).

## Gold cell (peel/runner) re-derivation — unchanged by the audits
- Source: `verifications/artifacts/2026-08-14_fly_hold_cut_surface_v1/`. 4 conditions:
  premium_at_touch≤26.5%, checkpoint∈{1130,1230}, regime=3, first_touch<14:30, threshold=1.50×.
- **n=52, 39 days, 2022-03→2026-08 (~12/yr)** — the spec's "40-70/yr" was wrong.
- **Mid: mean continuation +6.9% (CI [−14.1%, +27.9%])** → hold-all is the mean-EV corner at mid.
  **Worst-fill: mean −12.9%** → peel-all corner. **Peel 60-75% at +50%, keep 25-40% runner** is
  defensible. **Peel fraction = PM DECISION (live position), not a study output.**
- The gold cell is a **peel/runner, not a hold.**

## "What is the line?" — unverifiable by design; behavior (magnet) is real
- Author's claim: a standing dark-pool spot order "from swaps." No terminal shows a standing dark
  order; swaps flow is private; DTCC is EOD. **Origin = the author's narrative, cannot be
  corroborated** (expected, not evidence against). Stop chasing it.
- **Net:** whatever the level is, its robust tradable content is the **morning price-magnet (F7)**
  and, weakly, the 11:30 direction tilt. It is **not** a fly ceiling/exit (F3 retracted).

## Files / substrate
- `/data/agentic_trading/data/discord/strongest_lines.parquet` (the SML/SAL table).
- `/data/agentic_trading/outputs/fly_trades_nearest25.parquet` (8488×80; key cols `tradeDate,
  checkpoint_label, body_strike, entry_debit, wing_width, regime_id, target_hit_by_1555,
  entry_quoteable`). Body = `FLOOR((stockPrice+12.5)/25)*25`. Premium% = `entry_debit/wing_width*100`.
- `spx_1min` in `research.duckdb` (SPX index 1-min, 11:00-16:00 ET).
- **Report + 9 scripts:** `/data/agentic_trading/analysis/sml_fly_verify/` — `TECHNICAL_REPORT.md`
  + `verify_01..09`. verify_07 (PIT leak), verify_08 (clustering), verify_09 (geometry/exit) are
  the three audits — read all three. All read-only, all rc=0.
- Python venv: `/data/agentic_trading/.venv/bin/python` (pandas 2.3.3, pyarrow 25.0.1, duckdb 1.5.5,
  scipy, statsmodels).

## Open / next
1. **PM: gold-cell peel fraction** (60-75% peel / 25-40% runner) — live position decision.
2. **Forward test** — out-of-sample / live tracking of the **premium% gate** (the one robust entry
   factor). There is no line-based exit to forward-test (F3 retracted). This is the actual gate
   before capital.
3. **F9 confound control** — SAL alignment conditioned on SPX-vs-body *at SAL print* (causal vs
   proxy). Prerequisite for trusting F9 for sizing.
4. **Magnet-depletion test** — does the SML's *attraction* (F7) deplete after repeated same-day
   touches? (failure mode; test the *magnet*, not the retracted ceiling.)
5. **Establish the SML direction validly** — only a marginal 11:30 tilt (p=0.039); needs more line
   history or a prespecified multi-checkpoint day-level design.
6. **Hygiene:** change Discord password (invalidate token) → delete `~/discord-export/token`; add
   `data/discord/` to `.gitignore`.

## NOTES
- DuckDB reserved words on this box: `first`, `last`, `days` — alias them.
- Pandas precedence trap: parenthesize each comparison (`(f.a==x) & (f.b==y)`).
- HHMM vs total-minutes: `first_touch_time_mid` is HHMM (1424=14:24) but the line `time` is total
  minutes (856=14:16) — convert before comparing.
- Merge on a non-unique key (e.g. `ym`) makes a Cartesian product — assign by position.
- `verify_01_sources.py` ends with `sys.exit()` — do NOT import it from other verify scripts
  (define REPO/ERA directly).
