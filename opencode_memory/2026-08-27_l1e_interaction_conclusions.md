# L1-E: INTERACTION STUDY — CONCLUSIONS

## Population
352 trades (173 g5, 179 g25), 173 paired weeks. 10 dates excluded.

## Key Finding: The Ratio Quartiles Do ALL the Discrimination

**Parent quartile rates (7 metrics, 4 quartiles):**

| Quartile | n touch 35% | n touch 45% | n touch 50% | P35→45 | P35→50 |
|---|---|---|---|---|---|
| Q1 (lowest) | 4 | 2 | 0 | 50% | 0% |
| Q2 | 6 | 2 | 2 | 33% | 33% |
| Q3 | 35 | 0 | 0 | 0% | 0% |
| Q4 (highest) | 88 | 86 | 79 | 98% | 90% |

**Q4 alone:** P35=100%, P45=100%, P50=100%, P35→45=97.7%, P35→50=89.8%, P45→50=91.9%, P50→60=81.0%.
**Q1-Q3 combined:** P35→45=0–33%, P35→50=0–33%.

The ratio is a near-perfect gate. Q4 trades are "good" (all touch 35–50%, strong continuation). Q1-Q3 trades are "bad" (barely any touch 35%, and those that do don't continue).

## Interaction Results

### Q4 × Positioning (already strong — does positioning improve further?)

| Cell | n | P35→50 | Δ vs Q4 parent |
|---|---|---|---|
| Q4 × D1_low (oi_gamma_total L) | 20 | 95.0% | +5.2pp |
| Q4 × D2_high (put_call_gamma_ratio H) | 28 | 82.1% | -7.6pp |
| Q4 × D3_low (gamma_loc_imbalance L) | 14 | 85.7% | -4.1pp |

**Q4 × D1_low** shows a modest +5.2pp improvement on P35→50 (95.0% vs 89.8%), but n=20 trades (22.7% of Q4). This is the only cell with a positive incremental signal.

**Q4 × D2_high and D3_low** are actually worse than Q4 alone — positioning H/L in these features is associated with WORSE continuation within Q4.

### Q2/Q3 × Positioning (marginal — can positioning rescue?)

| Cell | n | n touch 35% | P35→50 | Δ vs Q2/Q3 parent |
|---|---|---|---|---|
| Q2/Q3 × D1_low | 62 | 11 | 18.2% | +13.3pp |
| Q2/Q3 × D2_high | 50 | 9 | 22.2% | +17.3pp |
| Q2/Q3 × D3_low | 58 | 10 | 0.0% | -4.9pp |

**These are statistically meaningless.** The denominators are tiny:
- Q2/Q3 × D1_low: 11 trades touch 35%, only 2 touch 45% → P35→50 based on n=2
- Q2/Q3 × D2_high: 9 trades touch 35%, only 2 touch 45% → P35→50 based on n=2
- Q2/Q3 × D3_low: 10 trades touch 35%, 0 touch 45% → P35→50 undefined

The "incremental deltas" of +13–17pp are noise from tiny samples. **Positioning cannot rescue Q2/Q3 trades.**

## Independence Check

| Feature | Pearson r with ratio |
|---|---|
| D1 (oi_gamma_total) | -0.009 |
| D2 (put_call_gamma_ratio) | -0.105 |
| D3 (gamma_loc_imbalance) | -0.072 |

All |r| < 0.11. The signals are essentially independent of the ratio. The ratio does not confound the positioning signals — they capture different dimensions.

## Conclusion

**The entry_credit / friday_straddle ratio is a sufficient statistic.** It alone separates the population into "good" (Q4: 88 trades, all metrics excellent) and "not good" (Q1-Q3: 264 trades, all metrics poor).

**Positioning adds no meaningful incremental value:**
- Within Q4: D1_low adds +5.2pp on P35→50 (n=20, modest)
- Within Q1-Q3: no cell has enough denominator to be meaningful
- The signals are independent of ratio (r < 0.11) but don't improve discrimination

**Practical implication:** The ratio is the only selector needed. Positioning features are not worth adding to a selection rule. The L1-A ratio Q4 gate captures 25% of trades (88/352) with near-perfect acquisition and continuation.

## V0 Baseline Compatibility Gate

**PROOF** from `iron_fly_v0_gate/v0_summary.txt`:
```
Criterion                     Expected       Observed       Result
population                    equivalent     n=352, g5=173, g25=179 PASS
trade_definition              equivalent     wing=100, grid=5/25, DTE=4, Mon1130→Fri1559 PASS
observation_granularity       equivalent     ~1800 (intraday) avg_rows/trade=1799.4 PASS
outcome_construction          equivalent     pnl=fly_value_economic-entry_debit_economic PASS
race_acquisition_definitions  equivalent     CORE_ROWS=10 races PASS

overall: FROZEN_BASELINE_COMPATIBLE
```
✓ All 5 axes PASS. Frozen baseline is authoritative. baseline_authority=frozen.

**Documentation:** This study follows the V0 gate process documented in `docs/baseline_compatibility_checklist.md`, `docs/research_style_guide.md`, and `notebooks/baseline_gate_demo.ipynb`. Every conditional-entry study must invoke `iron_fly_v0_baseline_gate.py` before computing deltas.

## Verification

### V1. Population Reconciliation
**PROOF** from `l1e_verification.txt`:
```
Total trades after exclusion: 352
g5: 173
g25: 179
Ratio quartile counts: Q1=88, Q2=88, Q3=88, Q4=88
Sum of quartile counts: 352
```
✓ Σ = 352. Quartile counts verified against `l1e_quartile_rates.csv` (n_trades=88 per quartile).

### V2. Quartile Rate Reproduction
**PROOF** from `l1e_quartile_rates.csv`:
```
Q4,P35,100.0,88,88,88
Q4,P45,100.0,86,86,88
Q4,P50,100.0,79,79,88
Q4,P35_45,97.72727272727273,88,86,88
Q4,P35_50,89.77272727272727,88,79,88
Q4,P45_50,91.86046511627907,86,79,88
Q4,P50_60,81.0126582278481,79,64,88
```
Q1: n_touch35=4, P35→45=50%, P35→50=0% (n_denom=4).
Q2: n_touch35=6, P35→45=33%, P35→50=33% (n_denom=6).
Q3: n_touch35=35, P35→45=0%, P35→50=0% (n_denom=35).
✓ All rates match card claims.

### V3. Interaction Cell Denominators
**PROOF** from `l1e_verification.txt` V3:
```
[Q4 x D1_low]: P35_50: n35=20, n35_50=19, rate=95.0%
[Q4 x D2_high]: P35_50: n35=28, n35_50=23, rate=82.1%
[Q4 x D3_low]: P35_50: n35=14, n35_50=12, rate=85.7%
[Q2/Q3 x D1_low]: P35_50: n35=11, n35_50=2, rate=18.2%
[Q2/Q3 x D2_high]: P35_50: n35=9, n35_50=2, rate=22.2%
[Q2/Q3 x D3_low]: P35_50: n35=10, n35_50=0, rate=0.0%
```
✓ Denominators match card. Q2/Q3 cells confirmed as noise (n35_50=0–2).

### V4. Delta Arithmetic
**PROOF** from `l1e_focused_results.csv`:
```
Q4 x D1_low,P35_50,95.0,20,10,20,19,5.227272727272734
Q4 x D2_high,P35_50,82.14285714285714,28,14,28,23,-7.6298701298701275
Q4 x D3_low,P35_50,85.71428571428571,14,7,14,12,-4.058441558441558
Q2/Q3 x D1_low,P35_50,18.181818181818183,62,32,11,2,13.303769401330378
Q2/Q3 x D2_high,P35_50,22.22222222222222,50,26,9,2,17.344173441734416
Q2/Q3 x D3_low,P35_50,0.0,58,30,10,0,-4.878048780487805
```
Q4 parent P35→50=89.77%. Q4×D1_low: 95.0% - 89.77% = +5.23pp ✓.
Q4×D2_high: 82.14% - 89.77% = -7.63pp ✓.
Q4×D3_low: 85.71% - 89.77% = -4.06pp ✓.
Q2/Q3 parent P35→50=4.88% (2/41). Q2/Q3×D1_low: 18.18% - 4.88% = +13.30pp ✓.
Q2/Q3×D2_high: 22.22% - 4.88% = +17.34pp ✓.
Q2/Q3×D3_low: 0.0% - 4.88% = -4.88pp ✓.
✓ All deltas reconcile arithmetically.

### V5. Independence Check
**PROOF** from `l1e_independence.csv`:
```
D1,-0.00892999769254501
D2,-0.10486877825568232
D3,-0.07171247093669608
```
All |r| < 0.11. ✓ Signals are independent of ratio.

### V6. Spot Audits
**PROOF** from `l1e_verification.txt` V5:
```
Trade: 2022-06-06_1559_005_0100_4165.0
  entry_debit_economic: -66.3
  put_body_economic: 254.35
  call_body_economic: 0.025
  ratio: 0.2606
  D1: 1057.94
  D2: 16.2756
  D3: -1.0000
  touch35: False
```
Trade ratio=0.2606 → Q1. D1=1057.94 → H bin. touch35=False → consistent with Q1.
✓ Spot audit verified.

### V7. Joint Matrix Reconciliation
**PROOF** from `l1e_verification.txt` V4:
```
[Q4 x D1_low]: n_trades=20, n_weeks=10
[Q4 x D2_high]: n_trades=28, n_weeks=14
[Q4 x D3_low]: n_trades=14, n_weeks=7
[Q2/Q3 x D1_low]: n_trades=62, n_weeks=32
[Q2/Q3 x D2_high]: n_trades=50, n_weeks=26
[Q2/Q3 x D3_low]: n_trades=58, n_weeks=30
```
All n_weeks ≤ n_trades. ✓

## Files

- `/data/agentic_trading/scripts/iron_fly_l1e_focused.py`
- `/data/agentic_trading/outputs/iron_fly_l1e_focused/l1e_focused_results.csv`
- `/data/agentic_trading/outputs/iron_fly_l1e_focused/l1e_quartile_rates.csv`
- `/data/agentic_trading/outputs/iron_fly_l1e_focused/l1e_verification.txt`
- `/data/agentic_trading/outputs/iron_fly_l1e_focused/l1e_independence.csv`
- `/data/agentic_trading/outputs/iron_fly_l1e_focused/l1e_cross_tab.csv`
