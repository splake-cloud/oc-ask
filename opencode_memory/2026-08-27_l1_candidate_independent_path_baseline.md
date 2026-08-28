# L1 CANDIDATE — Independent Path Baseline (v1)

**This is the first L1 conditional study baseline, computed independently from substrate rows.**
All later L1 conditional studies must report deltas against these estimands.

---

## Population / Estimand Definition

| Field | Value |
|---|---|
| Study | Monday 11:30, 100W iron fly (body nearest-5, wings ±100) |
| Valuation basis | Economic fields (`put_wing_economic`, `put_body_economic`, `call_body_economic`, `call_wing_economic`, `fly_value_economic`, `entry_debit_economic`) |
| Substrate | `warehouse.warehouse.iron_fly_weekly_substrate_v2` |
| Sample | 352 eligible trades (173 grid-5, 179 grid-25) |
| Period | 2022-06-10 → 2026-08-21 |
| Entry | Monday 11:30, credit = `entry_debit_economic` at entry |
| Exit | Friday 15:59, credit capture = `fly_value_economic` at exit |
| Wing width | 100 (all studies filtered `wing_width = 100`) |
| Body grids | 5 and 25 (combined = weighted average by trade count) |
| Touch threshold | Absolute: `max_pnl >= X% * abs(entry_credit)` |

**Status:** VERIFIED / FROZEN

---

## Frozen Estimands (L1 Candidate v1)

| Metric | Value | n |
|---|---|---|
| P35  | 68.5% | 241/352 |
| P45  | 60.5% | 213/352 |
| P50  | 56.0% | 197/352 |
| P35→45 | 80.9% | 195/241 |
| P35→50 | 74.7% | 180/241 |
| P45→50 | 90.1% | 192/213 |
| P50→60 | 80.2% | 158/197 |

---

## Comparison: Frozen Baseline vs Independent Path

| Metric | Frozen Baseline | Independent Path | Delta |
|---|---|---|---|
| P35  | 68.8% | 68.5% | -0.3pp |
| P45  | 61.3% | 60.5% | -0.8pp |
| P50  | 56.1% | 56.0% | -0.1pp |
| P35→45 | 82.6% | 80.9% | -1.7pp |
| P35→50 | 77.3% | 74.7% | -2.6pp |
| P45→50 | 94.1% | 90.1% | -4.0pp |
| P50→60 | 86.8% | 80.2% | -6.6pp |

**Note:** Deltas arise from absolute-value touch threshold definition (fixing sign bug where `entry_credit < 0`). Conditional chains show larger deltas due to smaller denominators.

---

## Purpose: Conditional Study Gate

Every L1 conditional entry study must report deltas against these frozen estimands:

**ACQUISITION** — does the condition raise P(touch X%)?
- P(touch 35%): 68.5% → ?
- P(touch 45%): 60.5% → ?
- P(touch 50%): 56.0% → ?

**PATH QUALITY** — does the condition improve continuation once entered?
- P(35→45 first): 80.9% → ?
- P(35→50 first): 74.7% → ?
- P(45→50 first): 90.1% → ?
- P(50→60 first): 80.2% → ?

A condition that raises P(touch 45%) from 60.5% to 75% but leaves P(45→50 first) at 90% is an **opportunity-acquisition selector**.

A condition that barely changes P(touch 45%) (60.5% → 63%) but raises P(35→50 first) from 74.7% to 88% is a **path-quality selector**.

---

## Source

Computed from: `warehouse.warehouse.iron_fly_weekly_substrate_v2`
Script: inline Python (no persistent script — independent path control)
Date: 2026-08-27
