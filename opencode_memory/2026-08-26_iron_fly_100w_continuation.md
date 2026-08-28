# 100W iron fly L0.5 — continuation & give-back after first touch (FROZEN) (2026-08-26)

**Date:** 2026-08-26 · **Seat:** oc-ask · **Topic:** continuation probabilities + give-back tail after first touching level A

Companion to `2026-08-25_iron_fly_100w_path_study.md` (L0) and `2026-08-26_iron_fly_100w_race_frozen_geometry.md` (L0.6, built on top).

## What was built (L0.5, FROZEN)
- Script: `scripts/iron_fly_continuation_100w.py` (read-only, deterministic, exit 0 on PASS)
- Commit: `8a5d9724` (script + continuation_matrix.csv + giveback_table.csv + base_rates.csv + self_check.json + 2 verify deposits; parquet excluded)
- Verification: 5 self-checks PASS + my independent raw-row recompute (159/159 continuation cells, all base rates, all give-back rows, anchor trade) EXACT match (deposited `verify/ironfly-100w-continuation-{selfcheck,independent-diff}.*`).

## Method pins
- Population/sign convention identical to frozen L0 (173/179/352 eligible).
- Continuation: P(reach B | reached A) = P(MFE ≥ B) / P(MFE ≥ A), A,B in {15..75}.
- Give-back anchored at touched level A (profit in hand), in pp of credit: P(giveback X%) = P(PnL later falls to ≤ (A−X)·credit); P(return ≤0) = P(PnL later ≤ 0).
- Spec correction on the record: my written inequality was backwards; true order is
  P(gb5) ≥ P(gb10) ≥ P(gb20) ≥ P(≤0) (holds for A≥20; at A<20 the 20% bar overshoots into negative).
  Numbers were correct; only my written check was wrong.

## Frozen result (combined)
- Continuation never drops below ~50% inside 35–45 for any core target (68–94%); only the far 75% target crosses under 50%.
- Give-back tail dominates: after touching 35%, P(return ≤0)=60.8%, P(≥20pp give-back)=74.7%. Path is highly oscillatory — deep continuation and deep give-back both frequent on the same paths.
- As A rises 35→50: P(≤0) falls 60.8%→50.7%, P(gb5) rises 89.0%→90.1% — deeper wins stickier in the big, always a little give-back.
- g5 vs g25 second-order (within ~2pts).
- P(reached A) base: 35%→69.6%, 40%→65.6%, 45%→61.9%, 50%→57.7%.

## Artifacts
`outputs/iron_fly_continuation_100w/`: continuation_matrix.csv (159 cells × 3 pools), giveback_table.csv, base_rates.csv, self_check.json (+ .parquet untracked).
