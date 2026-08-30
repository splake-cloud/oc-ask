# 2026-08-30 — Iron Fly L2-E premium/wing study: built, 3 output defects fixed, banked

Resumed after a mid-flight reboot killed the first build dispatch. This session
`ses_fabec1502ffeehxAP14Y11aDp4` oriented from opencode_memory, re-dispatched the build,
caught 3 implementation defects on independent review, fixed them, and banked.

## What L2-E is
"Premium / wing width in the frozen 100W baseline": `P_W = entry_credit / 100`. Within the
fixed 100W baseline it is just entry credit rescaled by 100 (no new ranking of the 352); its
value is (i) IV-sensitive economic interpretation and (ii) portability to 75W/100W/120W.
Central question = monotonicity of target attainment / P&L as P_W rises; explicit PM
incremental question = does P_W add information **inside the frozen R-qualified population**?
Spec RATIFIED 2026-08-30 (all 6 Appendix-A decisions + Strategy B data access), preflight
exhaustive re-derivation 474/474 exact.

## Build provenance
- **First build KILLED by reboot** (dispatch `ses_fac0c0b82ffeqsRL44hd43XmWW`, ~18:28; last
  activity 18:38:44 with the script `write` still pending — zero artifacts landed, clean restart).
- **Re-dispatch** `ses_fabe89344ffeZXqPd5bRb0Q37O` (qwen-coder): 1639-line script, all 6 proof
  gates PASS, G6 290/290 exact, deterministic.
- **Independent review caught 3 bounded implementation defects** (NOT study-design changes),
  fixed by EDIT dispatch `ses_fabd30dbbffeN7YpT1tps71G1S` (7-line diff):
  1. **A7 contrast used wrong boundaries (material).** `main()` bound the full-352 (A1) bounds
     to a var named `a2_bounds` and passed it to `run_a7` → 288-trade pop binned with A1
     bounds → contrast 18.22. Fix `run_a7(trades, a2_results["bounds"])` → **5.71** (Q1 n=74
     mean 10.57, Q4 n=70 mean 16.29).
  2. **Spearman p not clamped** → P45_reach p = 1.1062 (impossible). Fix `min(max(p,0,1))` → 1.0
     (ρ≈−0.008 null unchanged).
  3. **A2 report boundary label** printed A1's 0.51/0.61/0.69 instead of within-290. Fix →
     A2 prints `a2_results['bounds']` 0.50/0.57/0.64; A1 unchanged.
- Headline verdicts **recomputed from corrected outputs, unchanged**.

## Result (banked)
| Verdict | Result | Evidence |
|---|---|---|
| MONOTONICITY (R≥0.70) | **PARTIAL** (1/3) | reach non-decreasing FAIL, mean TP50 P&L non-decreasing FAIL, contrast PASS (11.98, p=0.0236) |
| ROBUST (R≥0.80) | **PARTIAL** (2/3) | reach FAIL, mean TP50 P&L PASS, contrast PASS (13.59, p=0.0261) |
| INCREMENTAL BEYOND R | **ADDS** | survives R-band [0.70,0.90) (9.91, p=0.0048) AND residualization (12.91, p=0.0233) |

**Interpretation:** the mean-P&L ordering holds (Q4 beats Q1 significantly, R-robust) but the
reach-rate ordering does NOT (A2 P45 drops 0.689→0.620 at Q2; mean TP50 dips Q1→Q2). Spearman
ρ(P_W, reach)≈0 but ρ(P_W, TP P&L) positive+significant (TP35 +0.299) — P_W tracks *how much*
is won, not *whether* they reach.

**PM RULING (banked, 2026-08-30, verbatim):** "Within the frozen 100W structure, premium/wing
does not exhibit a fully monotonic relationship with outcome, but higher premium/wing
materially improves TP50 economics at the distribution extremes and retains incremental
explanatory value after R conditioning. Therefore entry_credit / wing_width is **retained** as
a material structure-quality variable for the forthcoming wing-width comparison." → P_W is
RETAINED (not a standalone entry gate; R stays the entry conditioner), scoped to the 75W/100W/120W
comparison. This supersedes the draft "not adopted" wording. Does not change the L2-D headline
(0 PASS / static TP35/TP45 stands).

## Verification (all via verify-run, deposited)
Corrected-build path: `verify/l2e_fix_v1_py_compile.…193933Z` (exit 0),
`verify/l2e_fix_v2_first_run.…193951Z` (exit 0, G1–G6 PASS),
`verify/l2e_fix_v3_second_run.…194141Z` (byte-identical 8/8), V4 `grep -c FAIL`=0.
Independent recompute reproduced corrected A7 contrast **5.711544** exactly from
`l2e_trade_outcomes.csv` (exact-float 290-derived bounds 0.501500/0.57325/0.637000,
`max_risk>0`, ties→lower). All p-values in [0,1].

**Trap (self-inflicted, recorded):** my own intermediate recompute gave A7 contrast 6.13 /
Q1 n=72 because I used **rounded 2-decimal boundary literals** (0.50/0.57/0.64) instead of the
exact floats — the spec-correct value is **5.71 / Q1 n=74**. The delegate's "deviation note"
claiming 5.71 was the rounded-label value was BACKWARDS; the code uses exact floats and 5.71
is correct. Always recompute boundaries from the actual population, not from printed labels.

## State
- **CLOSED & committed** — receipt `studies/iron_fly_weekly/receipts/l2e_premium_wing_100w.md`
  (L2-D1 freeze format: verbatim conclusion, defect+fix provenance, verdict table, verify
  transcripts, SHA256 of all 10 artifacts, session IDs).
- Committed: script + spec + 8 outputs + receipt + verify transcripts (see commit).
- Frozen inputs untouched (G5 PASS). No new warehouse artifact; substrate read-only.

## Files
- Script: `studies/iron_fly_weekly/scripts/iron_fly_l2e_premium_wing_100w.py`
- Spec: `studies/iron_fly_weekly/specs/iron_fly_L2-E_premium_wing_100w_scope.md`
- Outputs: `studies/iron_fly_weekly/outputs/l2e_premium_wing_100w/` (8 artifacts)
- Receipt: `studies/iron_fly_weekly/receipts/l2e_premium_wing_100w.md`
