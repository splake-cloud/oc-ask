# 2026-09-08 investigation1_envelopeB_signed_state

## What was built
- `/tmp/opencode/investigation1/signed_state_model.py` — standalone script that:
  - Loads matched frames (all_expiry: 974,500 rows, 0dte: 503,356 rows)
  - Builds 14 outcome-blind features per-day from ORATS data
  - Trains GBM sign classifier (3-class) + magnitude regressor per arm
  - Leave-one-month-out CV (7 months all_expiry, 4 months 0dte)
  - Derives body-level state deterministically from strike-level predictions
  - Evaluates on 113 touch days (86 all_expiry, 27 0dte)
  - Outputs: fidelity_metrics.parquet, touch_day_states.parquet, signed_state_fidelity_report.md

## Key results
- **Decision: FAIL-SIGN** — ORATS-only cannot recover signed dealer position
- All-expiry mean sign accuracy: 0.4697 (threshold ≥ 0.80)
- All-expiry mean magnitude Spearman: 0.0853 (threshold ≥ 0.70)
- Body-level dealer-long-at-body: prec=0.491, rec=0.376 (all_expiry touch days)
- Peak RSS: ~1,075 MB — well within 251 GB host RAM, no cross-date accumulation

## Memory enforcement
- Per-day feature construction, drop raw frame after each day
- GBM fit on subsampled training data (50K rows max)
- No cross-date raw-row accumulation

## Artifacts
- Script: `/tmp/opencode/investigation1/signed_state_model.py`
- Fidelity metrics: `/tmp/opencode/investigation1/fidelity_metrics.parquet` (11 rows)
- Touch day states: `/tmp/opencode/investigation1/touch_day_states.parquet` (113 rows)
- Report: `/tmp/opencode/investigation1/signed_state_fidelity_report.md`
- Verify transcript: `/data/agentic_trading/verify/inv1_envelopeB_signed_state.20260908T084408Z.txt`

## Overridable defaults (PM may adjust)
1. Sign accuracy ≥ 0.80 (PASS)
2. Magnitude Spearman ≥ 0.70 (PASS)
3. Positive-node precision ≥ 0.60 (PASS)
4. Positive-node recall ≥ 0.60 (PASS)
5. Min held-out-month sign accuracy ≥ 0.70 (stability)
6. FAIL-SIGN threshold: sign < 0.70
7. FAIL-ALIGNMENT: sign ≥ 0.70 but body below strike
8. FAIL-BOTH: sign < 0.70 AND body below strike

## Deviations from spec
- **GBM subsampling**: Spec says "fit ONCE per arm from per-day reduced features" but fitting on 974K rows with GBM is computationally intractable on this box. Subsampled to 50K rows for GBM training. The CV evaluation still uses all test rows (no subsampling on test).
- **Smoke run**: Only 1 of 3 smoke days had data (2025-12-12 in all_expiry; 2026-03-15 and 2026-08-15 had no all_expiry data — they are in the 0dte regime). This is a data availability issue, not a script bug.
- **Rank agreement**: All values near 0.0000 — expected given the model performs at chance level on sign, so rank ordering of magnitude is meaningless.
