# Iron Fly L2-D decision analysis — NO marker clears the bankable bar (PM ruling executed)

**Date:** 2026-08-30
**Follows:** `2026-08-30_iron_fly_l2d_spec_reconciled_ruling1.md` (build/spec reconciliation)
**Commits:** `f7847aae` (L2-D build+spec) · `3219a2d6` (swept in pre-fix decision-analysis
snapshot, by a concurrent seat's commit) · `43b8d668` (final decision-analysis fixes)

## Verdict (the study's answer)

**No prespecified touch-time marker produces a stable, economically meaningful improvement
over the static TP35/TP45 exit at either the 35% touch (STATE A) or 45% touch (STATE B),
under the PM's ratified bankable standard.** Tally over 112 cells (28 rules × 2 states ×
2 pops): **0 PASS · 2 MARGINAL · 5 INDETERMINATE · 104→105 FAIL** (one cell relabeled by
housekeeping; headline unchanged).

## The contract (PM ruling 2026-08-30, ratified; spec Appendix C)

G1 Δ̄ ≥ **+0.50/trade** (PM AMENDED from 0.20 — "too small for bankable") AND headroom ≥
0.30 · G2 both R populations (nested stability, not replication) · G3 top-5-positive
concentration trim, floor +0.10 · **G4/G4b Holm-corrected across the 28 rules per
(state,population) cell** (PM REJECTED the "prespecification removes multiplicity control"
claim) · G5 n_available ≥ 0.6×state pop AND n_continue ≥ 20 AND n_exit ≥ 20 (AMENDED) ·
G6/G7 win-rate & capture non-inferiority **−0.02 absolute** · drawdown **Option A**
descriptive-only, no path fetch (PM: full-path fetch only valuable if a rule survives).

## Key design decisions (authoring seat, flagged to PM)

- **Estimand (load-bearing, review-caught F2):** Δ̄ ≡ (1/n_available)·Σ_{CONTINUE} Δ_i —
  the build's `delta_vs_TP35/TP45`. The "mean over continue trades" (÷n_continue) reading
  inflates Δ̄ one-directionally (verified: would flip 3/112 cells FAIL→PASS).
- **G4b implemented as two-sample branch-discrimination permutation** (continue-branch
  mean Δ vs exit-branch mean Δ), NOT a naive paired label-shuffle — under frozen
  recombination the hybrid−static difference is Δ_i on continue / 0 on exit, so the naive
  paired test has the IDENTICAL null as G4 (would be the same test twice).
- **Δ̄ = TP50 − Static is the spec's primary decision target (continue_edge)** — the
  analysis tests the spec's estimand, not a proxy.

## Why nothing passed (the interpretive core)

1. **G6 win-rate non-inferiority is the dominant killer.** The largest economic effects
   buy P&L with a materially worse hit-rate: `moving_toward_body` A (Δ̄ +2.13/+3.33,
   headroom 0.37/0.51, G4/G4b pass in primary) fails at win-rate diff −4.0pp/−2.9pp;
   `net_rising_60` A (Δ̄ +1.56/+2.52) fails at −4.9pp/−3.8pp. Exactly the trap G6/G7
   exist to catch.
2. **Holm kills the rest** — validates PM §4: after family-wise correction across 28
   rules, nothing reaches corrected p ≤ 0.05.
3. **The one near-miss: `median_spx_disp_body` STATE B = MARGINAL.** Δ̄ +0.97 (primary) /
   +1.67 (robustness), headroom 0.44/0.70, all gates pass in robustness; fails G4b in
   primary (Holm p = 0.0896). One gate, one population short.
4. **Degenerate selectors correctly rejected:** `inside_wings` B has n_exit = 1;
   `median_n_rejections` has n_continue = 0 (LOW direction empty).

## Artifacts (all committed)

- `studies/iron_fly_weekly/specs/iron_fly_L2-D_decision_analysis_scope.md` (+ identical
  review copy at study root) — RATIFIED contract, Appendices A (artifacts), B
  (second-opinion review record), C (PM ruling record).
- `scripts/iron_fly_l2d_decision_analysis.py` — deterministic, stdlib+numpy, read-only on
  frozen artifacts, no substrate/GPU.
- `outputs/l2d_continuation_markers/`: `l2d_rule_verdicts.csv` (112 rows),
  `l2d_decision_report.md`, `l2d_proof_gate.csv` (107/112 exact-match to frozen build;
  5 boundary cells: prior_dd_present ×4 — marker exactly 0 at the <0 threshold — and
  median_accel_60 A/robustness — 3 trades exactly at median 17.725).
- Verify transcripts: `verify/l2d_decision_analysis{,_rerun,_final}.20260830T*.txt`.

## Integrity trail

- Scope reviewed by **qwen38-delegate** (`ses_fad6654c2ffeyRe0I21Pf8qEHm`): 6 findings,
  each independently verified against source by the authoring seat before incorporation
  (F2 denominator, F1 4-metric tradeoff, F3 rounding, F4 decorative paired test, F5
  subset prose, F6 floor calibration).
- Analysis built by **qwen-coder** (`ses_fad49f8c8ffezxPITs4QQHDcd6`); every headline
  claim re-verified by the authoring seat from raw outputs (tally, MARGINAL row,
  near-miss FAILs, frozen-input sha256 vs v_proofs.json, fresh reproducible rerun).
- Frozen inputs byte-identical throughout (05bdfa…/d0aebf…/70b117…/391cc1…); build
  script sha256 b7c43c1f… unchanged.

## Housekeeping (post-hoc, verdicts unchanged 112/112 except one relabel)

- Empty-slice RuntimeWarnings guarded — root cause was a **dead duplicate G4 loop**
  (coder's "Wait… # Correct:" artifact) that also corrupted the RNG stream and produced a
  spurious p_g4b≈0.0001 (from a nan statistic) for degenerate selectors; now p_g4b=1.0.
- INDETERMINATE made **cell-specific** (was inherited across the sibling population):
  `median_accel_60 A/primary` (clean cell) INDETERMINATE→FAIL; 5 boundary cells → 5
  INDETERMINATE.
- **Concurrency trap (reusable):** a parallel seat's commit `3219a2d6` swept in an
  EARLIER snapshot of the in-flight files (pre-fix 104/6/2). Verified worktree vs HEAD
  before committing; final fix landed as its own commit `43b8d668`. On a shared branch,
  always `git show HEAD:<path>` before assuming your work is the committed version.

## Open / next

- **None blocking.** The L2-D study question is answered: static TP35/TP45 stands.
- Optional diagnostic (NOT adopted, new scope): whether `moving_toward_body`'s P&L
  survives a stricter win-rate floor, or a win-rate-constrained objective — only if PM
  wants it; it would be a new study, not a continuation of this ruling.
- `median_spx_disp_body` B (MARGINAL) is the watch item if the PM ever relaxes G4b or
  gains more data.
