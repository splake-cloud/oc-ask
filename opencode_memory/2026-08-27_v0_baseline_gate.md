# V0 Baseline Compatibility Gate — Implementation

## Purpose

Mandatory gate that executes before any study-verification sequence. Determines whether a study may use the canonical frozen baseline or must derive a study-local baseline.

## Decision Rule

```
IF all 5 V0 criteria PASS:
    baseline_authority = frozen
    use canonical frozen baseline
ELSE:
    baseline_authority = local
    construct study-local baseline
```

One failed axis is sufficient to prohibit frozen-baseline deltas. No override based on convenience or similarity of headline percentages.

## V0 Criteria (5 Axes)

| Criterion | Requirement | Evidence |
|---|---|---|
| population | Same governed eligible trade population | n_trades, g5/g25 split, date range, exclusion list |
| trade_definition | Same entry, expiry, body/wing construction, trade identity | wing_width, body_grid, DTE, entry/exit times, key format |
| observation_granularity | Same intraday/daily/weekly observation cadence | avg_rows_per_trade, min/max rows, sample timestamps |
| outcome_construction | Same P&L, credit-capture, touch, MFE/MDD | pnl formula, touch thresholds, sign convention |
| race_acquisition_definitions | Same target definitions, barriers, ordering, conditioning | CORE_ROWS, first-passage semantics, conditioning denominators |

## Implementation

### Scripts

- `/data/agentic_trading/scripts/iron_fly_v0_baseline_gate.py` — V0 gate (5-axis check, reads manifest)
- `/data/agentic_trading/scripts/iron_fly_v2_local_baseline.py` — Local baseline generator (7 metrics)
- `/data/agentic_trading/scripts/iron_fly_v0_regression_tests.py` — Regression test suite (4 tests)
- `/data/agentic_trading/scripts/generate_baseline_manifest.py` — Manifest generator (deterministic baseline_id)

### Outputs

Directory: `/data/agentic_trading/outputs/iron_fly_v0_gate/`

| File | Content |
|---|---|
| `v0_results.csv` | One row per criterion with expected, observed, result |
| `v0_summary.txt` | Human-readable V0 report |
| `local_baseline.csv` | Generated local baseline (if V0 fails) |
| `regression_tests.csv` | Regression test results |

### Regression Tests

| Test | Fixture | Expected |
|---|---|---|
| A — Compatible Baseline | Same population, grain, outcomes | V0 5/5 PASS, frozen baseline |
| B — Incompatible Granularity | Weekly 5-row vs intraday frozen | V0 observation_granularity=FAIL, local baseline |
| C — Population Mismatch | 300 trades vs 352 frozen | V0 population=FAIL, local baseline |
| D — False Compatibility Guard | Identical row counts, different dates | V0 FAIL |

## Baseline Manifest

Path: `/data/agentic_trading/outputs/iron_fly_100w_baseline_economic/baseline_manifest.json`

```json
{
  "baseline_id": "f0208fe9caabfba2d3436b7d242beb0fdcb5cea0a0af2b9dfd85390ad616ccd3",
  "baseline_version": "1.0",
  "population_n_trades": 352,
  "population_n_independent_weeks": 173,
  "date_min": "2022-06-10",
  "date_max": "2026-08-21",
  "body_grids": [5, 25],
  "wing_width": 100,
  "granularity": "intraday",
  "authoritative_file_hashes": {
    "baseline_summary.csv": "4ce1d8c8e77b17b5d467f26f3ae1631ed6f0c2d79136e8b344d7cb6a0e978f3f",
    "race_core.csv": "c542f078c805da80642d517eb7800701c6303e8fcbd385378317d97b2ba36c35",
    "continuation_core.csv": "06605556184046faf8a1fb0be576b1736d39bca4d4c268e596aa8c9ec6974672",
    "self_check.json": "ebe0b3e1a27bf85ab3ac3d27175fe37915fda7f15a58fa8214b6a335cf153791"
  }
}
```

**How baseline_id is computed:**
1. Serialize manifest body (all fields except baseline_id) with sorted keys.
2. Concatenate authoritative_file_hashes values (in key order).
3. SHA-256 of the resulting string.
4. Insert hex digest as baseline_id.

**Properties:**
- Any change to an authoritative file produces a new baseline_id.
- Notebook/log file changes do NOT affect the ID.
- V0 gate loads manifest and uses its values instead of hard-coded numbers.

**Regenerating manifest:**
```bash
python3 scripts/generate_baseline_manifest.py
```

## Current Status

**V0 Verdict: FROZEN_BASELINE_COMPATIBLE** (5/5 PASS)

```
Criterion                     Expected       Observed       Result
population                    equivalent     n=352, g5=173, g25=179 PASS
trade_definition              equivalent     wing=100, grid=5/25, DTE=4, Mon1130→Fri1559 PASS
observation_granularity       equivalent     ~1800 (intraday) avg_rows/trade=1799.4 PASS
outcome_construction          equivalent     pnl=fly_value_economic-entry_debit_economic PASS
race_acquisition_definitions  equivalent     CORE_ROWS=10 races PASS
```

The substrate is intraday-granularity (avg 1799 rows/trade), matching the frozen baseline grain. Frozen baseline is authoritative for all conditional studies.

## Delta Authority

Every conditional output row must carry:
```
baseline_authority (frozen or local)
baseline_id
baseline_granularity
baseline_n
baseline_metric
conditional_metric
delta_pp
```

Delta arithmetic: `delta_pp = 100 × (conditional_probability - authoritative_baseline_probability)`

## Failure Semantics

V0 FAIL does NOT mean study failure. It means:
```
frozen baseline rejected
local baseline required
```

The study fails only if:
```
local baseline cannot be constructed,
V2-local cannot verify it,
or another downstream invariant fails.
```

## Governing Invariant

The baseline used to evaluate a conditional must represent the **same estimand as the conditional population**. A baseline is authoritative because its estimand matches — not because it was previously frozen.

## Verification

### CHECK: V0 gate runs and produces correct verdict
**PURPOSE:** Verify the gate correctly identifies frozen baseline compatibility
**EXPECTED:** 5/5 axes PASS, FROZEN_BASELINE_COMPATIBLE
**OBSERVED:** population=PASS, trade_definition=PASS, observation_granularity=PASS, outcome_construction=PASS, race_acquisition_definitions=PASS → FROZEN_BASELINE_COMPATIBLE
**RESULT:** PASS

### CHECK: V2 local baseline generates all 7 metrics
**PURPOSE:** Verify local baseline computation when V0 fails
**EXPECTED:** P35, P45, P50, P35→45, P35→50, P45→50, P50→60 with explicit numerator/denominator
**OBSERVED:** P35=241/352=0.684659, P45=213/352=0.605114, P50=197/352=0.559659, P35→45=213/241=0.883817, P35→50=197/241=0.817427, P45→50=197/213=0.924883, P50→60=161/197=0.817259
**RESULT:** PASS

### CHECK: All 4 regression tests pass
**PURPOSE:** Verify the gate correctly handles compatible, incompatible, mismatched, and false-compatible scenarios
**EXPECTED:** Test A=PASS (compatible), Test B=PASS (granularity mismatch), Test C=PASS (population mismatch), Test D=PASS (date mismatch)
**OBSERVED:** 4/4 tests passed
**RESULT:** PASS

## Documentation

| File | Purpose |
|---|---|
| `docs/baseline_compatibility_checklist.md` | Step-by-step checklist (population, trade definition, granularity, outcome construction, race definitions) with example tables |
| `docs/research_style_guide.md` | Style guide mandating invocation of `iron_fly_v0_baseline_gate.py` at start of every conditional-entry study and use of `baseline_authority` fields in all delta tables |
| `notebooks/baseline_gate_demo.ipynb` | Runnable notebook walking through Test A (compatible) and Test B (incompatible), showing V2-local baseline generation and verification |

A frozen baseline may be used only after V0 proves compatibility across population, trade definition, observation granularity, outcome construction, and acquisition/race definitions. If any criterion fails, the study must construct and independently verify a local baseline using the same analytical pipeline as the study.
