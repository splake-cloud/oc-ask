# 2026-09-01 — OPEX Weekly Layer L1: built, executed, CLOSED (all four primaries NO-GO)

## What happened
- PM ratified the **weekly** layer as distinct from the closed daily study
  (`studies/opex_week/`), with four spec tightenings: (1) separate layer
  `opex_weekly_L1`; (2) exactly four pre-specified primaries (signed weekly
  return, |R|, within-week RV, positive-week frequency) with tails/magnitudes/
  decomposition demoted to secondary; (3) one non-overlapping Friday-bracketed
  weekly spine built BEFORE OPEX assignment, holiday expirions use the actual
  final trading session, prior-Friday anchor retained, session count recorded,
  short weeks reported separately + session-count-matched; (4) explicit
  identification limit (third-Friday calendar confound — SPX-only evidence
  identifies a calendar signature, not option-expiration causation) + exact
  brackets: prior-Fri→Wed, Wed→exp-session, exp-session→following Friday (D3
  never enters OPEX-week stats), plus the full pre-expiry bracket.
- Executed by `pi -p` child on jett-8011 (11.5 min) with fan-out authority to
  qwen-coder :8081 (child exercised it 0 times — judged in-seat sufficient;
  pattern is banked and worked). G0–G4 all PASS.
- Main-seat verification: 40/40 sampled weeks recomputed exactly from source;
  composition identity (1+D1)(1+D2)=(1+D_full) at 1e-16; arm means reproduce.

## VERDICTS (full sample: 437 OPEX — 2 quad-witching excluded per S6 — vs 1,468 non-OPEX)
- **P1 signed weekly return: NO-GO** — +5.43 bp (floor 10), CI [−19.5, +30.1], holdout disagree
- **P2 |R|: NO-GO** — +3.11% rel (floor 5%)
- **P3 within-week RV: NO-GO** — −0.86% rel (opex weeks if anything *calmer*)
- **P4 positive-week frequency: NO-GO** — +1.17 pp (floor 2), Fisher p=0.70
- Secondaries (S1–S6, no verdicts): decomposition, decade blocks, year-matched,
  session-strata, quad-witching note — in outputs/.

**Bottom line: the expiration-week calendar signature is null at weekly grain
too.** The classical opex-week hypothesis (bigger moves, more often up) is
unsupported in SPX 1990–2026 at both session and week grain. What remains
open: the identification limit (calendar confound) and the L2/L3 vol/OI layers.

## Commits
- `af60d312` blueprint + build spec v1 (the four tightenings in the contract)
- `a1fd1393` layer closed: spine (1,907 weeks, 439 OPEX, 328 short), scripts,
  outputs, receipts, staging + transcript

## Process findings (bank)
- **Envelope defect (my side):** first dispatch reused the DAILY mission's TASK
  text in the driver — child detected the mission-vs-envelope contradiction,
  refused to improvise, re-ran the (already closed) daily gates, and flagged it
  in NOTES. That is exactly the honest-exit behavior the doctrine wants. Fix:
  driver TASK text must restate the SAME anchor as mission.md, never a second
  study's spec. Bounce cost: 2.3 min.
- Out-of-scope write to the closed daily layer (13-line re-verify addendum)
  was reverted (`git checkout`) — closed layers stay byte-clean.
- Spec authoring lesson: my first draft of the spec doubled up sections under
  edit pressure — full rewrite beat patching. Keep specs single-authored-in-one-pass.
- Power reality: 439 opex weeks → ~2.5-SE bar on the 10 bp floor; MARGINAL was
  the likely outcome class. Result came in cleanly NO-GO with wide CIs — report
  the CIs, not just the verdicts.

## Open (PM)
- L2 (IV/vol state of the expiration week, 2021+ substrate on box) — natural
  next layer; decision: build or not.
- L3 (OI/gamma/auction micro-structure) — data acquisition, unchanged.
- Monday-exploratory flag from the daily layer — still unadjudicated.
- fly-gap-horserace re-run (pre-v2 flag) — RESOLVED 2026-09-01, commit `b0dcbe9b`
  (opex flag now sourced from pattern_opex_week v2; label fix only, no statistics
  moved; sample advanced 2026-08-07→2026-08-31 via upstream input extension).
