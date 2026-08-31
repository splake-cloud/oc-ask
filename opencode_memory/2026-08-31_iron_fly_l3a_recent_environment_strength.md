# 2026-08-31 — Iron Fly L3-A recent-environment-strength: scoped, built, verified

Session `ses_fabec1502ffeehxAP14Y11aDp4` (continuation). L3-A = trailing-window
strength of the completely frozen iron-fly trade (100W, Mon 11:30, g5/g25,
R≥0.70 primary / R≥0.80 robustness, TP50 headline / TP35 secondary / TP45
supporting / Friday terminal). Descriptive only — no verdict, no optimization.

## Scope
`studies/iron_fly_weekly/specs/iron_fly_L3-A_recent_environment_strength_scope.md`
— DRAFT authored by this seat, then **RATIFIED 2026-08-31** with PM rulings:
exact calendar-month cutoffs (anchor = frozen max entry_ts 2026-08-17 11:30;
cutoffs 2026-02-17 / 2025-08-17 / 2025-02-17 / 2024-08-17 / 2023-08-17, all
11:30); robustness = same complete metric table; TP45 supporting = reach +
mean PnL only; uncertainty = 95% deterministic **week-cluster bootstrap**
(10,000 resamples, seed 20260831, percentile 2.5/97.5, blank only if
C(T)<2); opportunity frequency = BOTH trade-level R pass rate AND % weeks
with ≥1 qualifying trade.

## Build provenance
- **BUILD** `ses_faa64827cffe34Yza45riexhb4` (qwen-coder):
  `scripts/iron_fly_l3a_recent_environment_strength.py`, 7 artifacts, all
  gates PASS. 4 deviations flagged: (1) join-key format — spec's
  `f"{entry_ts}_g{body_grid}_0100_{body_strike}"` was wrong; actual L2-E key
  is `f"{entry_date}_1130_{body_grid:03d}_0100_{body_strike:.1f}"` — spec
  corrected; (2) **G4 anchor error in MY spec**: 13.9641 is the L2-F A1
  n=280 (COMMON∩gate) value; L3-A estimand is full-352∩gate = 290 →
  **13.9987** (verified by independent recompute: 290→13.9987, 280→13.9641
  exactly). Spec §2/§7 corrected to anchor 13.9987 with 13.9641 as
  cross-population check.
- **EDIT #1** `ses_faa5e4c3cffewIUSHzxfXdHe2J`: G4 now checks the full-290
  anchor (13.9987) AND computes the 280-row check **in-memory** — the build
  had been reading a third CSV (`l2f_a1_per_width_metrics.csv`), violating
  the closed read list.
- **EDIT #2 (bounce)** `ses_faa5ade4affekCi9CvF6jJsPKJ`: build blanked the
  6M-robustness CI after computing it — violated ratified §4.1 ("6M
  robustness cell (n=4, 2 weeks) is **computed** but flagged small_sample";
  blank reserved for C(T)<2). Fixed: CI now −42.7250/28.0125 + flag.

## Verification (all verify-run, deposited)
- `verify/l3a_fix_v1_py_compile.…022844Z` exit 0
- `verify/l3a_fix_v2_full_run.…022844Z` exit 0, G0–G6 ALL PASS
- `verify/l3a_fix_v3_determinism.…022850Z` — 2nd run byte-identical (diff exit 0)
- `verify/l3a_fix_v4_gate.…022850Z` — `grep -c FAIL l3a_proof_gate.csv` = 0
- **Independent recompute (this seat, from frozen inputs only):** 12M-primary
  mean TP50 PnL 10.7524, P50 0.5714, win% 0.6825, 35→50 0.75 (n35=48) — all
  exact; ALL 12 bootstrap CI cells reproduced exactly (shared
  seed-20260831 stream across cells in WINDOW_ORDER — order-dependent by
  construction, deterministic).
- G4 row: `n=290 p50|35=0.8301 n35=206 mean_tp50=13.9987 mean_tp50_ok=True
  a1_mean_tp50=13.9641 a1_mean_ok=True g5/g25=144/146`.

## Result (core table, primary R≥0.70)
| Metric | 6M | 12M | 18M | 24M | 36M | FULL |
|---|---|---|---|---|---|---|
| n trades | 22 | 63 | 86 | 123 | 202 | 290 |
| weeks | 11 | 32 | 44 | 63 | 104 | 149 |
| P50 | .546 | .571 | .500 | .553 | .629 | .590 |
| TP50 win % | .546 | .683 | .605 | .650 | .698 | .669 |
| Mean TP50 PnL | 3.32 | 10.75 | 11.06 | 14.03 | 17.04 | 14.00 |
| CI95 | −18.1/24.8 | 0.2/20.5 | −1.5/26.1 | 4.2/25.2 | 9.4/25.0 | 7.8/20.6 |
| P35 | .682 | .762 | .698 | .740 | .748 | .710 |
| 35→50 | .800 | .750 | .717 | .747 | .841 | .830 |
| Mean R | .749 | .792 | .794 | .804 | .837 | .841 |
| Mean P_W | .625 | .599 | .668 | .642 | .596 | .590 |

Robustness (R≥0.80): n 4/25/37/60/132/184; mean TP50 PnL
−7.36/7.41/16.91/18.64/19.86/15.42; 6M cell small_sample (CI −42.7/28.0).
Full tables: `outputs/l3a_recent_environment_strength/l3a_core_metrics_{primary,robustness}.csv`.

**Observations (descriptive, no verdict per ruling):** mean TP50 PnL rises
monotonically 12M→36M (10.75→17.04) but 6M collapses to 3.32 (CI spans
negative); R pass rate dips at 18M (0.729) vs 12M (0.759); mean abs(MDD)
jumps at 36M/FULL (74.8/59.6 vs ~24–27 elsewhere) — a few deep-drawdown
weeks in the older history dominate the mean (medians stay ~23–33).

## State
- **CLOSED & committed `27eac92c`** (PM ruling "write the receipt and commit
  Analysis A", 2026-08-31). Receipt
  `studies/iron_fly_weekly/receipts/l3a_recent_environment_strength.md`
  (L2-D1 freeze format: verbatim question, core tables both gates,
  provenance incl. the 3 defects + 1 spec correction, verify transcripts,
  SHA256 of all 10 artifacts, session IDs). Commit = script + spec + 7
  outputs + receipt (10 files).
- Frozen inputs untouched (G1 PASS: l2f `4fc3c4a0…`, l2e `3b5e24d9…`).

## Files
- Spec: `studies/iron_fly_weekly/specs/iron_fly_L3-A_recent_environment_strength_scope.md` (RATIFIED)
- Script: `studies/iron_fly_weekly/scripts/iron_fly_l3a_recent_environment_strength.py`
- Outputs: `studies/iron_fly_weekly/outputs/l3a_recent_environment_strength/` (7 artifacts)
