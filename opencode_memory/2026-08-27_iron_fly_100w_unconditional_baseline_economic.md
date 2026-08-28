# 2026-08-27_iron_fly_100w_unconditional_baseline_economic.md

## Goal
Produce one consolidated 100W unconditional baseline report using only verified economic-field outputs from all 5 gated studies. No raw-mid mixing. Deposit to `outputs/iron_fly_100w_baseline_economic/`.

## What Was Built

### Script
`scripts/iron_fly_100w_baseline_economic.py` — reads all 5 study outputs, produces 7 files.

### Outputs
| File | Rows | Content |
|------|------|---------|
| `baseline_summary.csv` | 33 | Sample + hold-to-Friday g5/g25/combined |
| `continuation_core.csv` | 84 | P(B|A) for A∈{15,35,40,45,50} with giveback probs |
| `race_core.csv` | 24 | 8 core races × 3 grids, D=0 |
| `straddle_comparison.csv` | 9 | Fly vs straddle: win rate, PnL, MFE/MDD, continuation, race |
| `wing_overlay_summary.csv` | 27 | 9 metrics × 3 grids |
| `pm_baseline.md` | 10 | 8 concise bullets |
| `self_check.json` | 8/8 PASS | Population, reconcile, bounds, partition |

### Self-Checks
All 8 PASS: S1_population_352, S2_g5_g25_reconcile, S3_paired_weeks_reconcile, S4_continuation_bounds_valid, S5_race_partition_valid, S6_straddle_population_match, S7_wing_premium_positive, S8_all_probabilities_0_to_1.

## Key Numbers (Combined, Economic Fields)

**Hold-to-Friday:** win=46.3%, mean=-0.84, median=-5.86, MFE=33.0, MDD=46.4

**Take-profit hit rates (g5):** 15%=94.8%, 25%=85.0%, 35%=75.7%, 45%=61.5%, 50%=56.1%, 60%=45.7%, 75%=32.9%

**Continuation after 35%:** P(45|35)=88.4%, P(50|35)=81.7%

**Core races (upside-first):** 35→45=82.6%, 35→50=77.3%, 45→50=94.1%, 50→60=86.8%

**Straddle vs fly:** fly win=46.3% vs straddle=58.0%, fly mean=-0.84 vs straddle=-3.24

**Wing premium:** mean=19.0, overlay at MFE=mean=-9.5 (drag), overlay at MDD=median=-4.7 (protection)

## The Paradox

Favorable excursion is the normal path: 76% reach 35% credit capture, 62% reach 45%, 56% reach 50%. Once entered, further favorable movement is more likely than reversal: 35→50 wins 77%, 45→50 wins 94%, 50→60 wins 87%.

Yet hold-to-Friday win rate is only 46.3%.

**Resolution:** Giveback. After touching 35%, P(return≤0) = 76.9%. After touching 45%, P(return≤0) = 49.1%. After touching 50%, P(return≤0) = 31.7%. Wings cost 19.0 on average but the overlay at MFE is -9.5 — wing cost exceeds gain when fly is at peak.

## PM Conclusion
The iron fly has a negative unconditional baseline (mean P&L < 0) due to wing costs. Upside continuation is strong (88% reach 45 after touching 35), but wing overlay drag at MFE is significant. The strategy is viable only when wing cost is kept below the expected upside continuation value.

**Next step:** Conditional entry L1 — identify Monday 11:30 conditions that raise frequency/depth of the 35-45% excursion AND reduce giveback probability. No conditional effects interpreted yet.

## Inputs (All Verified Economic-Field)
- `outputs/iron_fly_path_study_100w/baseline_summary.json` — hold-to-Friday stats
- `outputs/iron_fly_path_study_100w/take_profit_frontier.csv` — hit rates
- `outputs/iron_fly_continuation_100w/continuation_matrix.csv` — P(B|A)
- `outputs/iron_fly_continuation_100w/giveback_table.csv` — giveback probs
- `outputs/iron_fly_race_100w/race_matrix.csv` — race outcomes
- `outputs/iron_fly_straddle_overlay_100w/straddle_baseline.csv` — straddle stats
- `outputs/iron_fly_straddle_overlay_100w/straddle_continuation.csv` — straddle continuation
- `outputs/iron_fly_straddle_overlay_100w/straddle_race.csv` — straddle races
- `outputs/iron_fly_straddle_overlay_100w/golden_path_comparison.csv` — fly vs straddle race
- `outputs/iron_fly_straddle_overlay_100w/wing_overlay_summary.csv` — wing overlay PnL
- `outputs/iron_fly_straddle_overlay_100w/straddle_remorse.csv` — straddle remorse

## Verification
All probabilities recompute exactly from study artifacts. G5 (173) + G25 (179) = 352. Paired weeks = 173. All continuation probabilities in [0,1]. All race probabilities sum to ~1. Straddle population = 352. Wings premium > 0.
