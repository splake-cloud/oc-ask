# 2026-08-31 — Iron Fly L4-B R×P_W interaction: CLOSED NO GO

Session `ses_fabec1502ffeehxAP14Y11aDp4`. PM asked for a build spec for the
R×P_W interaction **if the L4-A secondary grid showed stable structure worth
promoting**. I re-examined the actual L4-A secondary grid (single median P_W
split per R band, gated-290) before drafting, and the conditional did not
fire. **PM ruled L4-B = NO GO (2026-08-31). No build. Blueprint retained as
the decision record of why the branch was not pursued.**

## Evidence (this seat, verify-run `l4b_pw_grid_probe` / `l4b_pw_gap_ci`)

| R band | P_W-low (n/wks) | P_W-high (n/wks) | low vs high mean TP50 PnL | week-cluster 95% CI on gap |
|---|---|---|---|---|
| B1 [0.70,0.80) | −2.54 (17/9) | +14.23 (89/49) | −16.76 | **[−11.47, +38.53] crosses 0** |
| B2 [0.80,0.90) | +14.43 (56/34) | +17.68 (52/32) | −3.25 | [−16.58, +16.08] crosses 0 |
| B3 [0.90,1.00) | +8.00 (66/35) | −36.73 (2/1) | +44.7 | high cell n=2, tiny, non-interpretable |
| B4 [1.00,∞) | 6/4 | 2/1 | — | both tiny-cell |

- Only candidate: **B1 × low-P_W** (mean −2.54, 8/17 negative) vs B1
  high-P_W (+14.23) — n=17/9 weeks, CI crosses zero. NOT stable.
- No monotone direction across bands (B1 low negative, B2/B3 low positive).
- B3's large gap = 2-trade/1-week artifact (L4-A OQ3 tiny-cell ban).
- 2 P_W cells is not a gradient. L4-A's P_W check was a confound-exclusion,
  not a signal finder — it did its job and surfaced no promotable structure.

## Artifacts
- Blueprint (CLOSED NO GO): `studies/iron_fly_weekly/specs/iron_fly_L4-B_R_x_pw_interaction_scope.md`
  — §1.1 = the NO GO decision block (PM verbatim); §1.2 = the evidence;
  §3–§11 = the design that would have resolved it (4×4 grid, fixed house-level
  P_W boundaries 0.50/0.70/0.90, confound-vs-interaction discriminator,
  B1×low-P_W cell isolated). **Not iterated — it is a decision record now.**
  Uncommitted.
- Defect caught in my own draft: L2-F SHA256 was truncated to 52 chars (would
  have silently broken G0); fixed + verified 64-char exact
  (verify-run `l4b_spec_hash_check`, HASH_MATCH, 2 occurrences).

## Research priority reset (PM, 2026-08-31)
Premium-quality refinements are EXHAUSTED:
- R level above gate (L4-A) → MIXED / no slope
- R × P_W (L4-B) → no promotable structure (NO GO)
- FOMC exposure (L5-A) → real environment difference, uncertain rule value
**NEXT (highest-value actionable branch): entry-known realized movement /
range state within the frozen R-qualified population.** Intuition to test:
two trades can both have acceptable R, but one may be entered while SPX is
already traversing an unusually large amount of space relative to the
100-point structure → may reduce TP50 completion even when the premium looks
attractive. Genuinely untested interaction with the current completion decay.
**Not yet scoped — no spec, no card for it yet.**
