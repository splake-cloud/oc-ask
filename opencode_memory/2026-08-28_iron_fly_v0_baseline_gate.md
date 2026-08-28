# Iron Fly V0 Baseline Compatibility Gate — Implementation

## What was built

Implemented a mandatory V0 Baseline Compatibility Gate for the iron fly 100W study pipeline. The gate determines whether a study may use the canonical frozen baseline or must derive a study-local baseline.

## Files created

1. **`/data/agentic_trading/scripts/iron_fly_v0_baseline_gate.py`** — V0 gate script (827 lines)
   - Loads frozen baseline from `/data/agentic_trading/outputs/iron_fly_100w_baseline_economic/`
   - Loads study population from substrate with exclusion list
   - Runs 5 compatibility axes: population, trade_definition, observation_granularity, outcome_construction, race_acquisition_definitions
   - Outputs: v0_results.csv, v0_summary.txt, local_baseline.csv (if V0 fails)

2. **`/data/agentic_trading/scripts/iron_fly_v2_local_baseline.py`** — Local baseline generator (302 lines)
   - Uses same substrate query, exclusion list, and outcome engine as frozen baseline
   - Computes all 7 metrics: P35, P45, P50, P35→45, P35→50, P45→50, P50→60
   - Shows numerator/denominator explicitly for every probability

3. **`/data/agentic_trading/scripts/iron_fly_v0_regression_tests.py`** — Regression tests (500+ lines)
   - Test A: Compatible Baseline → 5/5 PASS, FROZEN_BASELINE_COMPATIBLE
   - Test B: Incompatible Granularity → observation_granularity FAIL, LOCAL_BASELINE_REQUIRED
   - Test C: Population Mismatch → population FAIL, LOCAL_BASELINE_REQUIRED
   - Test D: False Compatibility Guard → population FAIL (different dates), LOCAL_BASELINE_REQUIRED

4. **`/data/agentic_trading/outputs/iron_fly_v0_gate/`** — Output directory
   - v0_results.csv, v0_summary.txt, local_baseline.csv, regression_tests.csv

## Key findings

- Current substrate: 352 trades (173 g5 + 179 g25), date range 2022-06-10 to 2026-08-21
- Grain: ~1,799 rows/trade (intraday, 5-min snapshots)
- V0 gate result: FROZEN_BASELINE_COMPATIBLE (5/5 axes PASS)
- Local baseline metrics: P35=0.685, P45=0.605, P50=0.560, P35→45=0.884, P35→50=0.817, P45→50=0.925, P50→60=0.817

## Verification commands

```
cd /data/agentic_trading && python3 scripts/iron_fly_v0_baseline_gate.py
cd /data/agentic_trading && python3 scripts/iron_fly_v2_local_baseline.py
cd /data/agentic_trading && python3 scripts/iron_fly_v0_regression_tests.py
```

All three commands execute successfully.
