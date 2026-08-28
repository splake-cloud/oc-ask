# 2026-08-27 iron-fly scripts economic field migration

## What was done
Updated 8 iron-fly consumer scripts in `/data/agentic_trading/scripts/` to use the stable view `warehouse.iron_fly_weekly_substrate_v2` and economic field names instead of mid/bidask equivalents.

## Changes per file

### 1. iron_fly_path_study_100w.py
- TABLE: `"warehouse__iron_fly_weekly_substrate_v2__1230283500"` → `"warehouse.iron_fly_weekly_substrate_v2"`
- SQL: `fly_value_mid` → `fly_value_economic`, `fly_value_bidask` → `fly_value_economic`, `entry_debit_mid` → `entry_debit_economic`
- Python dict access: all `row["fly_value_mid"]`/`r["fly_value_mid"]` → `row["fly_value_economic"]`/`r["fly_value_economic"]`; same for `entry_debit_mid` → `entry_debit_economic`
- Sign convention docstring updated
- IS NOT NULL guards updated in main query + V4/V6/V7 self-check SQL

### 2. iron_fly_continuation_100w.py
- TABLE: same hash → stable view
- SQL + Python dict access: `fly_value_mid` → `fly_value_economic`, `entry_debit_mid` → `entry_debit_economic`
- Self-check SQL updated

### 3. iron_fly_race_100w.py
- TABLE: same hash → stable view
- Sign convention docstring updated
- SQL + Python dict access: `fly_value_mid` → `fly_value_economic`, `entry_debit_mid` → `entry_debit_economic`
- Self-check SQL updated

### 4. iron_fly_straddle_overlay_100w.py
- TABLE: same hash → stable view
- Sign convention docstring updated
- SQL + Python dict access: `fly_value_mid` → `fly_value_economic`, `entry_debit_mid` → `entry_debit_economic`
- `"entry_debit_mid"` dict key → `"entry_debit_economic"` in trade_stats
- Self-check SQL updated

### 5. iron_fly_wing_mark_overlay_100w.py
- TABLE: `"sqlmesh__warehouse.warehouse__iron_fly_weekly_substrate_v2__1230283500"` → `"warehouse.iron_fly_weekly_substrate_v2"`
- SQL: `fly_value_mid` → `fly_value_economic`, `entry_debit_mid` → `entry_debit_economic`
- COL dict: `"fly_value_mid": 3` → `"fly_value_economic": 3`
- Output row key: `"fly_value_mid"` → `"fly_value_economic"` (output field name)
- CSV fields list updated
- Note: `fly_value_mid_adjusted` output field names left unchanged (not substrate columns)

### 6. iron_fly_mark_diagnostic_100w.py
- TABLE: `"sqlmesh__warehouse.warehouse__iron_fly_weekly_substrate_v2__1230283500"` → `"warehouse.iron_fly_weekly_substrate_v2"`
- SQL: `fly_value_mid` → `fly_value_economic`, `entry_debit_mid` → `entry_debit_economic`
- COL dict: `"fly_value_mid": 3` → `"fly_value_economic": 3`, `"entry_debit_mid": 4` → `"entry_debit_economic": 4`
- Output dict keys updated to `fly_value_economic`
- classify_mark function: `row["fly_value_mid"]` → `row["fly_value_economic"]`
- Note: inline comments referencing `fly_value_mid` left as-is (not sign convention docstrings)

### 7. iron_fly_v2_raw_rederive.py
- All inline SQL references: `sqlmesh__warehouse.warehouse__iron_fly_weekly_substrate_v2__1230283500` → `warehouse.iron_fly_weekly_substrate_v2` (4 occurrences)

### 8. iron_fly_v2_spot_check.py
- P variable: `"sqlmesh__warehouse.warehouse__iron_fly_weekly_substrate_v2__1230283500"` → `"warehouse.iron_fly_weekly_substrate_v2"`
- No fly_value_mid/entry_debit_mid changes (this script selects raw leg bid/ask, not fly value)

## Verification results
- All 8 files: `py_compile` passes
- No remaining `__1230283500` hash references across all 8 files
- No remaining `row["fly_value_mid"]`/`row["entry_debit_mid"]`/`r["fly_value_mid"]`/`r["entry_debit_mid"]` dict access in files 1-6
- All TABLE/P constants point to `warehouse.iron_fly_weekly_substrate_v2`

## Deviations from spec
None. All 8 spec clauses satisfied.
