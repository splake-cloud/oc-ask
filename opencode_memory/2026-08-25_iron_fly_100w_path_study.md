# Iron-fly 100W path study — deterministic analysis layer over v2 substrate

**Date:** 2026-08-25 · **Seat:** oc-ask · **Topic:** mechanical Monday 11:30 100W short iron fly — path economics, take-profit frontier, body-rule comparison

Companion to `2026-08-25_iron_fly_substrate_v2_sixcell.md` (the verified substrate this reads). Analysis layer only: NO option reconstruction, NO model mutation, NO warehouse write.

## Deliverable
- `scripts/iron_fly_path_study_100w.py` (analysis layer, `/data/agentic_trading/.venv/bin/python` — the only interpreter with duckdb+pyarrow).
- Outputs in `/data/agentic_trading/outputs/iron_fly_path_study_100w/` (5 artifacts, .csv + .parquet each): `trade_path_summary` (352 trades = 173+179), `take_profit_frontier` (28 = 2 grids × 14 targets), `executable_take_profit_frontier` (28), `drawdown_timing` (352), `paired_body_comparison` (173 shared expiries), + `baseline_summary.json` + `self_check.json`.

## Frozen universe
- Table `sqlmesh__warehouse.warehouse__iron_fly_weekly_substrate_v2__1230283500`, `wing_width=100`, `body_grid IN (5,25)` (A=5, B=25).
- Trade = (body_grid, expiry_date); path grain (body_grid, expiry_date, valuation_ts) unique; ~1800 rows/trade (Mon 11:30 → Fri 15:59).
- Enterable = entry row (valuation_ts=entry_ts) has entry_quoteable=TRUE → **173 (g5) / 179 (g25)**.

## Load-bearing sign convention (verified against data, NOT assumed)
Substrate stores the NEGATIVE of value: `entry_debit_mid<0`, `fly_value_mid<=0`.
- `entry_credit = -entry_debit_mid` (~+60)
- `pnl_mid_t = fly_value_mid_t - entry_debit_mid` (= entry_credit − close_cost; 0 at entry)
- DO NOT use `entry_credit - fly_value_mid` (wrong sign).
- `max_loss = 100 - entry_credit`; `credit_capture = pnl/credit`; `return_on_risk = pnl/max_loss` (NOT capped to [-1,1] — mid marks exceed payoff bounds; worst mid PnL −56.9).
- Executable-side (verified identity, 0 bad rows): `close_cost_exec = put_body_ask + call_body_ask - put_wing_bid - call_wing_bid = -fly_value_bidask`; executable rows = 4 legs>0 (≈81% coverage).

## THE BUG (caught in receipt review, not by the delegate)
`_percentile` did correct linear interpolation but **assumed sorted input**; every caller passed unsorted lists. All `mean_*` (separate sum/len) were RIGHT; every percentile was WRONG.
Symptom (impossible internally): `p05 −4.88 > p25 −49.43`; `mfe_median 47.4 > mfe_p90 39.6`; `mdd_median 101.1 > mdd_p90 39.8`; `median_entry_credit 46.5` (true 61.0).
**Fix:** sort inside `_percentile` (`vals = sorted(sorted_vals)`, then interpolate over vals). One function, ~2 line changes. Self-check V1–V7 did NOT cover percentiles → passed vacuously. Re-verified every percentile field by independent duckdb recompute (exact match, monotone).

## Results (verified)
- **Friday last-mark (hold to expiry) is the WORST policy**: win rate 0.468 (g5) / 0.447 (g25), mean PnL −2.5/−2.0, median −7.2/−6.9, p05/p95 ≈ −50/+52. median ROR ≈ −1.0 (typical trade loses ~100% of max risk by Friday because most end near zero → ROR ≈ −credit/max_loss).
- **MFE**: median 34.5/34.2, p90 61.8/62.7 (pts). **MDD**: median 46.9/45.9, p90 86.8/92.3 (pts); most-frequent MDD bucket = Friday 15:xx (expiry).
- **Mid take-profit frontier** (idealized, first-touch of T×credit else hold): hit-rate g5 = 0.913/0.855/0.763/0.578/0.341 @ T=0.10/0.15/0.25/0.50/0.75; mean policy PnL 2.34→2.91→3.88→7.08→7.24. **50% capture ≈ mean-PnL optimum** (flips −2.5 hold to +7.1, win rate → 0.65); **15–25% dominates on frequency** (76–86% hit).
- **Executable-side frontier collapses the opportunity**: hit-rate drops to ~0.82/0.70/0.56/0.25 @ same targets; mean policy PnL NEGATIVE at low targets (−0.25 to −1.16 @ 10–25%), crosses zero only ~T=0.30, peaks ~+0.86 at T=0.50, ≈0 at 75–90%. **The mid-mark take-profit edge mostly does NOT survive executable fill** — the answer to the study's final question. (Bid/ask on the 4 legs eats the thin mid-margin, especially on far OTM wings.)
- **Body rule (5 vs 25) is second-order at 100W**: g5 and g25 nearly identical (win 0.468 vs 0.447, mean −2.5 vs −2.0, frontier within ~0.5 pts). The contrast will show more at 75W (out of scope this study).

## Verification
- self_check.json: V1 sign-identity 0 bad, V2 all enterable quoteable, V3 universe clean, V4 grain unique, V5 paired set valid, V6 hand-recompute of 3 anchor trades (5/2022-06-10, 5/2022-06-17, 25/2022-06-10: entry_credit, friday pnl, MFE+ts, MDD+ts, first-touch 15/25/50%) exact, V7 executable identity 0 bad. All PASS.
- Independent recompute (mine, direct duckdb, separate from the script) confirmed: baseline percentiles, MFE/MDD, median credit 61.0, T=0.25 frontier (med_ror 0.323, p05 −1.0, mean 3.88). Deposit: `verify/ironfly-100w-path-study-rerun.*` (exit=0).

## Commit
**`c64a1d18`** `research: add verified 100W iron fly path study` — 4 files:
`scripts/iron_fly_path_study_100w.py`, `outputs/.../baseline_summary.json`,
`outputs/.../self_check.json`, `verify/ironfly-100w-path-study-rerun.*`.
The 5 .csv/.parquet data artifacts are intentionally NOT committed (left untracked in outputs/).
**`6d82b3bc`** `research: surface post-touch Friday loss rate in iron fly frontier` —
1-line script delta (the "winner became loser" after-touch rate = Friday mark <= 0, distinct from
friday_loser_after_touch_rate = Friday mark fell back below the target level; both now in the frontier
output). Regenerated frontier .csv/.parquet still untracked.
**`4c663e1b`** `research: document the two distinct after-touch rate semantics in iron fly frontier` —
comments-only (15 insertions): the two rates are now explicit in the module docstring + definition site.
- `friday_loser_after_touch_rate`      = P(Friday PnL < target PnL | target touched) — give-back of the captured opportunity.
- `friday_zero_or_less_after_touch_rate` = P(Friday PnL <= 0 | target touched) — complete reversal (available winner ends non-positive).

**FROZEN 100W L0 study = `c64a1d18` + `6d82b3bc`** (PM-designated). `4c663e1b` is a documentation
follow-up (no behavior change); no squash.

## Frozen research conclusion (PM-approved, 2026-08-26)
- No attractive hold-to-Friday expectancy (win 0.468/0.447, mean −2.5/−2.0). Opportunity = harvesting
  intraweek path movement via take-profit exits.
- Mid marks: frontier centered ~50% credit capture (mean-PnL/ROR peak); 15–25% maximizes realization
  frequency (0.86/0.76 hit).
- Executable side: NOT literally dead — negative at low targets, crosses positive ~30%, peaks ~+0.86 at
  50%. Edge becomes **economically marginal** under conservative executable pricing (NOT "does not
  survive" — that overstates it); four-leg execution costs remove most of the mid-mark advantage.
- 5pt vs 25pt body: not a material driver at 100W.

## Open / next
1. ~~Commit~~ — DONE `c64a1d18` + `6d82b3bc` (frozen L0) + `4c663e1b` (after-touch rate semantics doc).
2. NOT done (out of scope per task): stop-loss optimization, regime/event conditioning, 75W/120W, entry-time/rule changes.
3. If the richer frontier (with friday_zero_or_less_after_touch_rate) is ever wanted persisted, commit the regenerated .csv/.parquet — currently deliberately untracked.
