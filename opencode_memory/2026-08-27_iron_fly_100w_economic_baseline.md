# CANONICAL BASELINE — 100W Iron Fly

**This is the verified unconditional baseline.** All later conditional studies must
reproduce these estimands under their own condition and report deltas.

---

## Population / Estimand Definition

| Field | Value |
|---|---|
| Study | Monday 11:30, 100W iron fly (body nearest-5, wings ±100) |
| Valuation basis | Economic fields (`put_wing_economic`, `put_body_economic`, `call_body_economic`, `call_wing_economic`, `fly_value_economic`, `entry_debit_economic`) |
| Substrate | `warehouse.warehouse.iron_fly_weekly_substrate_v2` |
| Sample | 352 eligible trades (173 grid-5, 179 grid-25), 173 paired weeks |
| Period | 2022-06-10 → 2026-08-21 |
| Entry | Monday 11:30, credit = `fly_value_economic` at entry |
| Exit | Friday 15:59, credit capture = `fly_value_economic` at exit |
| Wing width | 100 (all studies filtered `wing_width = 100`) |
| Body grids | 5 and 25 (combined = weighted average by trade count) |

**Status:** VERIFIED / FROZEN

---

## Primary Acquisition Baselines

*Probability of reaching ≥ X% of entry credit capture (hold-to-path, no early exit).*

| Target | P(touch X%) — grid-5 | P(touch X%) — combined |
|---|---|---|
| 15% | 85.0% | — |
| 25% | 75.7% | — |
| 35% | 68.8% | — |
| 45% | 61.3% | — |
| 50% | 56.1% | — |
| 60% | 45.7% | — |

Source: `take_profit_frontier.csv` (g5), `base_rates.csv` (combined: P(reach 35%)=68.8%, P(reach 45%)=61.3%, P(reach 50%)=56.1%)

---

## Primary Continuation / Race Baselines

*First-passage race outcomes (D=0: no giveback threshold). Probability that upside target B is reached before giveback barrier D, conditional on first touching A.*

| Race (A→B before D) | P(upside-first) | n_reached_A |
|---|---|---|
| 35→45 before 25 | 82.6% | 241 |
| 35→50 before 25 | 77.3% | 241 |
| 45→50 before 35 | 94.1% | 213 |
| 50→60 before 40 | 86.8% | 197 |

Source: `race_matrix.csv`, D_pct=0, combined body_grid.

---

## Hold-to-Friday Baseline (Combined)

| Metric | Value |
|---|---|
| Win rate (P(friday PnL > 0)) | 46.3% |
| Mean PnL | -0.84 |
| Median PnL | -5.86 |
| MFE median | 33.0 |
| MDD median | 46.4 |

Source: `baseline_summary.csv`, hold_friday_combined.

---

## Wing Overlay Summary (Combined)

| Metric | Value |
|---|---|
| Wings premium paid (mean) | 19.0 |
| Wings premium paid (median) | 14.9 |
| Overlay at fly MFE (mean) | -9.5 |
| Overlay at fly MDD (median) | -4.7 |
| Friday overlay PnL (mean) | 2.4 |
| Friday overlay PnL (median) | -9.1 |

Source: `wing_overlay_summary.csv`, combined.

---

## Straddle Comparison (Combined)

| Metric | Fly | Straddle (no wings) | Delta |
|---|---|---|---|
| Friday win rate | 46.3% | 58.0% | -11.6pp |
| Friday mean PnL | -0.84 | -3.24 | +2.4 |
| Friday median PnL | -5.86 | 9.25 | -15.1 |
| MFE median | 33.0 | 44.3 | -11.2 |
| MDD median | 46.4 | 51.6 | -5.2 |

Source: `straddle_comparison.csv`.

---

## Self-Check

All 8 PASS:
- S1_population_352
- S2_g5_g25_reconcile (173+179=352)
- S3_paired_weeks_reconcile (173)
- S4_continuation_bounds_valid (all P ∈ [0,1])
- S5_race_partition_valid (upside+giveback+unresolved ≈ 1)
- S6_straddle_population_match (352)
- S7_wing_premium_positive (19.0 > 0)
- S8_all_probabilities_0_to_1

Source: `self_check.json`.

---

## Source Artifacts

Directory: `outputs/iron_fly_100w_baseline_economic/`

| File | Content |
|---|---|
| `baseline_summary.csv` | Sample + hold-to-Friday g5/g25/combined |
| `continuation_core.csv` | P(B\|A) for A∈{15,35,40,45,50} with giveback probs |
| `race_core.csv` | 8 core races × 3 grids, D=0 |
| `straddle_comparison.csv` | Fly vs straddle: win rate, PnL, MFE/MDD, continuation, race |
| `wing_overlay_summary.csv` | 9 metrics × 3 grids |
| `pm_baseline.md` | 8 concise bullets |
| `self_check.json` | 8/8 PASS |

---

## Purpose: Conditional Study Gate

Every later conditional entry study must report deltas against these frozen baselines:

**ACQUISITION** — does the condition raise P(touch X%)?
- P(touch 35%): 68.8% → ?
- P(touch 45%): 61.3% → ?
- P(touch 50%): 56.1% → ?

**PATH QUALITY** — does the condition improve continuation once entered?
- P(35→45 first): 82.6% → ?
- P(35→50 first): 77.3% → ?
- P(45→50 first): 94.1% → ?
- P(50→60 first): 86.8% → ?

A condition that raises P(touch 45%) from 61.3% to 76% but leaves P(45→50 first) at 94% is an **opportunity-acquisition selector**.

A condition that barely changes P(touch 45%) (61.3% → 63%) but raises P(35→50 first) from 77.3% to 90% is a **path-quality selector**.

---

## Immutable Definitions (do not change)

- **Eligible week:** Monday entry, Friday exit, DTE=4, wing_width=100, body_grid∈{5,25}, quoteable=true at entry.
- **Body-grid pooling:** combined = weighted average by trade count (g5=173, g25=179).
- **Target definition:** % of entry credit capture (entry_debit_economic at Mon 11:30).
- **Race barrier:** giveback threshold D_pct from the race_matrix; D=0 means no giveback barrier.
- **Economic marking basis:** substrate v2 economic leg marks (intrinsic fallback on provider drift).
- **Entry time:** Monday 11:30.
- **Sample period:** 2022-06-10 to 2026-08-21.
