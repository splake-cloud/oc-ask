# 2026-08-31 — Iron Fly L5-B entry-day timing: BUILT + CLOSED (banked)

Session `ses_fabec1502ffeehxAP14Y11aDp4`. Question: for the same
Friday-expiry 100W iron fly at Monday-selected strikes, does delaying the
sale from Mon 11:30 to Tue/Wed/Thu 11:30 reduce MAE while preserving TP50
expectancy? **CLOSED + banked (PM, 2026-08-31). No entry-day rule adopted.**

## Banked conclusion (PM verbatim)

> Delaying entry does reduce total MAE, but that reduction comes primarily
> from shortening the exposure window—not from entering into a cleaner
> market state. Once exposure length is equalized, Wednesday and especially
> Thursday are worse environments, while TP50 expectancy deteriorates
> materially.

Label NO ENTRY-DAY IMPROVEMENT.

### Banked block (PM final, 2026-08-31)

L5-B ENTRY-DAY TIMING — BANKED

Monday remains the preferred initiation day.

Delaying entry:
- reduces total MAE primarily through shorter exposure;
- does not reduce equal-horizon adverse excursion;
- materially worsens TP50 completion and expectancy by Wednesday/Thursday;
- produces no superior MAE/expectancy tradeoff.

No entry-day change adopted.

PM wording correction (binding): do NOT write "Monday best on every
load-bearing metric" — Monday is NOT best on literal MAE_to_exit (later
entries have smaller total MAE). Correct framing: "Monday provides the best
overall MAE/expectancy tradeoff among the tested entry days. Later entry
reduces total MAE, but Wednesday/Thursday do so at a disproportionate loss
of TP50 expectancy, while equal-horizon MAE shows no improvement in
underlying entry-state risk and becomes substantially worse by Thursday."

## Key numbers (pooled, week-cluster CI; quoteable panel survives, P4)

- MAE_to_exit: Mon 56.11 → Tue 54.27 (Δ−2.15, CI crosses 0) → Wed 52.61
  (−3.83 sig) → Thu 49.32 (−6.80 sig).
- MAE_24h (equal 1-day window): 8.17 / 8.81 / 11.76 / **44.96** — Thu−Mon
  +37.24 [5.25, 98.20]. The day before expiry is where per-day drawdown
  concentrates.
- addl_adv_exc (after first 24h): Mon 46.79 vs Thu 4.09 — adverse movement
  is BACK-loaded, not front-loaded; "delay to avoid early-week MAE" is the
  wrong mechanism.
- TP50 policy PnL: 20.61 → 17.41 (−3.01, marginal) → 11.11 (−9.25 sig) →
  9.07 (−11.87 sig). Reach: 0.556/0.521/0.431/0.375 (Wed/Thu sig negative).
  Entry credit flat (±2, CIs cross 0) — expectancy loss is not a premium
  story.
- Tuesday ≈ Monday on everything (all CIs cross 0): waiting one day buys
  nothing.
- Context: foregone early hits 8.6/16.2/20.8% of 197 Monday-reached;
  quoteable 98.2/99.0/91.9% at later 11:30s; spread gap (executable−modeled
  credit) median −0.3 to −0.6 pts.

## Construction (approved pins + freezes)

- P1 same Monday-selected body/strikes, timing only. P2 primary fixed
  horizon = entry 11:30 → next trading day 11:30. P3 addl_adv_exc =
  MAE_to_exit − MAE_24h (nonnegative) — **corrected before first build**:
  original operand order was identically zero (24h window ⊂ exit window).
  P4 modeled + quoteable panels separate; conclusion must survive
  quoteable. F1–F3 frozen: reach = first touch +0.50×rebased credit; policy
  PnL = touch PnL else Friday terminal; win = policy PnL > 0. No composite
  MAE/expectancy ratio. Primary contrasts Tue−Mon/Wed−Mon/Thu−Mon, paired
  within-week, week-cluster bootstrap seed 20260904.
- OQ1 complete-case quoteable panel = primary (317 trades). OQ2 1-min grid.
  OQ3 time-to-TP50 + RoMR kept, context only. OQ4 Thursday convergence kept,
  diagnostic only.
- Re-basing: every later entry is a counterfactual re-entry — credit, TP50
  target, max_risk, PnL path, MAE, terminal all re-based per day on UNCAPPED
  `fly_value_economic` (frozen Monday basis). Substrate v1103730983 pinned;
  keyed by (entry_ts, body_grid, body_strike) — NOT entry_spread_key
  (per-snapshot trap).

## Verified facts (this seat, before/during build)

- `entry_quoteable` = all 8 leg quotes > 0 at that snapshot (committed model
  c2da4c04:226-238), per-snapshot (363/364 trades vary across path), TRUE
  Mon–Thu 11:30 / FALSE Fri 11:30. Working-tree model hardcodes TRUE (the
  unapplied HOLD) → G0 liveness gate `COUNT(DISTINCT entry_quoteable) > 1`
  fails closed on a silent rebuild.
- Executable sale value PROVEN constructible (PM requirement):
  put_body_bid + call_body_bid − put_wing_ask − call_wing_ask; fields
  non-null 98.2–99.6% at later 11:30s; gap vs modeled always ≤ 0 (90-row
  check).
- Panel: ~1,785 rows/trade, 1-min 09:30→15:59, fly_value_economic non-null;
  69.9% of 100W path rows < −50 (capped vs uncapped basis is material).

## Bounce record (first build rejected)

Build `ses_fa6f079e5ffeyXuUztNfpBD3L6` passed its self-checks; 4 defects
found on independent verification: (1) addl_adv_exc all-zero (P3 operand
order — material, spec corrected first); (2) Table 2 foregone incidence 1.0
tautology (wrong denominator → 197 Monday-reached); (3) CHECK A quoteable
rates not reproducible (1.0 reported vs true 98.22/98.96/91.90) + G3
weakened to vacuous >0.5 valueless row → restored [0.91,0.995] + 1.0→FAIL;
(4) MAE contrasts missing CIs. Fix `ses_fa6d4896cffeRxMHujbpcXj1Rl`; all 4
verified by this seat against outputs (addl 46.79 w/ CIs; 17/32/41 of 197;
G3 actual values; MAE CIs; G2 anchor still 0/352; byte-identical).

## Artifacts (uncommitted at card time)

- Spec: `specs/iron_fly_L5-B_entry_day_timing_scope.md` (RATIFIED v1, P3
  corrected; committed f63f1fea before the P3 correction — P3 fix
  uncommitted)
- Script: `scripts/iron_fly_l5b_entry_day_timing.py`
- Outputs: `outputs/l5b_entry_day_timing/` (panel 1,407 / table1 192 /
  table2 3 / table3 25 / proof_gate 22 all PASS)
- Receipt: `receipts/l5b_entry_day_timing.md`
