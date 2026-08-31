# 2026-08-31 — Iron Fly L4-A within-gate R level: scoped, ratified, built, verified

Session `ses_fabec1502ffeehxAP14Y11aDp4`. Question: within the already-gated
population (R≥0.70 n=290 / R≥0.80 n=184), does the LEVEL of R carry TP50
outcome information beyond the gate — cliff or slope?

## Artifacts
- Spec: `studies/iron_fly_weekly/specs/iron_fly_L4-A_within_gate_R_level_scope.md`
  — **RATIFIED v2** (PM rulings OQ1–OQ5: OQ1 GO fixed bands+quantiles; OQ2 GO
  seed 20260901; OQ3 KEEP P_W interaction SECONDARY/single median split/no
  tiny B4×P_W interpretation; OQ4 KEEP friday_hold_pnl as
  "terminal Friday comparator / non-reach fallback" — no policy conclusion;
  OQ5 small_sample flag at C(T)<10). §4.0 interpretation contract
  (CLIFF/PLATEAU vs SLOPE vs MIXED) with a deterministic label procedure
  (core evidence = P50 reach rate, TP50 win rate, mean TP50 PnL, 35→50).
- Script: `studies/iron_fly_weekly/scripts/iron_fly_l4a_within_gate_R_level.py`
  (BUILD `ses_fa816c54dffekPEHQ0opHShwsJ`; EDIT bounce
  `ses_fa8122a25ffeDdrpLfE4G6bUyy`).
- Outputs: `studies/iron_fly_weekly/outputs/l4a_within_gate_R_level/` (7
  artifacts).

## Data access review (qwen-coder EXPLORE `ses_fa859072affeNprUgURRl2TXDe`)
7/7 PASS verbatim: frozen inputs L2-F `l2f_per_trade_outcomes.csv`
(sha `4fc3c4a0…`, 1051 rows) + L2-E `l2e_trade_outcomes.csv` (sha
`3b5e24d9…`, 352 rows); join key `f"{entry_date}_1130_{body_grid:03d}_0100_{body_strike:.1f}"`;
n=290/184; anchors 13.9987/13.9641; R within-gate p25/50/75 ≈ 0.782/0.837/0.909,
max 1.1575; bands 106/108/68/8.

## Bounce (the one real defect)
Build defined `tp50_win_rate = P(tp50_pnl>0)` (0.6690) instead of ratified
§4.1 "reach AND tp50_pnl>0" (0.5897). In this frozen data reach50==1 ⇒
pnl>0 (0 counterexamples), so spec value == reach rate — build's value was
the PnL-positive rate, a different estimand. Fixed by 2-line EDIT; re-verified.
**Trap:** my own first recompute also used the wrong definition
(0.5377==reach50 coincidence masked it); the win-rate column must be checked
against BOTH the build and the spec definition, not just internal
consistency.

## Verification (this seat, verify-run deposited)
- v1 py_compile 0; v2 full run G0–G5 20/20 PASS exit 0; v3b/v4 fix determinism
  BYTE_IDENTICAL; gate grep FAIL=0 (transcripts `verify/l4a_*`).
- Independent recompute from frozen CSVs only: n290/n184, anchor 13.9987,
  ALL band means/reach/35→50 exact, Spearman exact (tp50 −0.0284, reach
  +0.1037), 3 bootstrap CI cells exact (B1 2.3659/20.3384, B2 6.6748/24.9462,
  B3 −5.0829/17.9011), aggregate win50 0.589655 exact.
- Note: `grep -c FAIL` prints 0 but exits 1 (no matches) — expected.

## Result (descriptive; label per §4.0 procedure)
**Both populations: MIXED.** Primary band means (B1..B4): reach 0.538/0.630/
0.588/0.750; win 0.538/0.630/0.588/0.750; mean TP50 PnL 11.54/16.00/6.68/
81.86; 35→50 0.770/0.861/0.870/0.857. The B4 (R≥1, n=8, 5 weeks,
small_sample) mean PnL 81.86 is a tiny-cell artifact — no cliff/slope
structure in the core metrics: reach/win dip at B3 then spike at B4
(irregular); continuation is the only cliff-like shape (jumps B1→B2 then
flat); quantile ordering check FALSE. Robustness (B2..B4): same irregular
reach/win, continuation flat. Spearman(R, tp50_pnl) ≈ −0.03 (no linear
association); Spearman(R, tp50_reach) ≈ +0.10. **Answer to cliff-vs-slope:
neither — the 0.70 gate is not the foot of a monotone slope; within-gate R
level shows no usable ordering in the core TP50 metrics** (B4's apparent
strength is n=8 noise). P_W interaction (secondary): median 0.573250 split;
not yet interpreted in-receipt.

## SQL validation audit (2026-08-31, this seat) — build proven truth vs canonical substrate
4-layer read-only DuckDB audit vs `warehouse.warehouse.iron_fly_weekly_substrate_v2`
(v2/`1103730983`), re-deriving L4-A numbers from RAW substrate rows (bypassing the
frozen CSVs). Derivation contract from qwen-coder EXPLORE
`ses_fa80b8ea4ffe4LYph1aPiNKhEd` (6/6 PASS). All verify-run deposited:
- **A1** `l4a_audit_a1_integrity2.…131614Z`: 1,949,021 rows; DTE=4 only;
  2022-06-06→2026-08-28; 100W entry rows 354; 0 dup.
- **A2** `l4a_audit_a2_final.…131957Z`: every L2-F outcome col re-derived from
  substrate, all mismatch counters 0 (entry_credit/pw/max_risk/r_value/tp50
  reach+pnl/mfe/mdd/friday/tp35/tp45); 352 rows, 0 dup, 0 missing. ONE non-zero:
  `sub_100W_entry_rows_not_in_l2f=2` = the 2 L2A date-excluded weeks (354−352),
  a governed subset not data loss.
- **A3** `l4a_audit_a3_derive2.…132111Z`: band aggregates recomputed from
  substrate (no CSV) — n290/184, B1–B4 106/108/68/8, reach/mean50/35→50 all
  identical to output; anchors 13.9987 + 280→13.9641.
- **A4** `l4a_audit_a4_closedloop.…132151Z`: committed `l4a_band_metrics_primary.csv`
  vs substrate re-derivation — abs-diff 0.0 on reach/win/mean50/35→50/meanR,
  out_n==sub_n.
Verdict: L4-A re-derives EXACTLY from the canonical substrate through the frozen
CSVs — no drift, no silent population change, no arithmetic error. Section
appended to `receipts/l4a_within_gate_R_level.md` (after Verification).

## State
- **CLOSED & committed `7565b546`** "research: close L4-A within-gate R level
  (cliff vs slope: MIXED both pops; no R gate change adopted)" (10 files:
  spec + script + 7 outputs + receipt). PM banked the MIXED conclusion
  verbatim (R not a continuous TP50-quality slope; 0.70 gate not the lower
  end of "higher R always better"; most beyond-gate evidence irregular;
  continuation shows the clearest threshold-like behavior B1→B2 then flat;
  no R gate change adopted). Receipt
  `receipts/l4a_within_gate_R_level.md` (L2-D1 freeze format: verbatim
  result, core tables both pops, P_W secondary note, provenance incl. the
  win-rate bounce, verify transcripts, SHA256 of all 9 artifacts).
