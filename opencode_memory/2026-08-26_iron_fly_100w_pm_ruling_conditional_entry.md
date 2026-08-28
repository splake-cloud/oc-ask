# 100W iron fly — PM ruling: from L0 economics to conditional entry (2026-08-26)

**Date:** 2026-08-26 · **Seat:** oc-ask · **Topic:** PM conclusion on the 100W L0 path study; next research direction

Companion to `2026-08-25_iron_fly_100w_path_study.md` (the frozen L0 study this ruling is about).

## The ruling (PM, verbatim intent)
- **Established:** a *frequent gross* opportunity for substantial intraweek profit capture in the
  unconditional (mechanical Monday 11:30) 100W iron fly.
- **NOT established:** net *executable* expectancy. The historical bid/ask in the substrate is an
  **intentionally harsh top-of-book bound** — it does not reflect the execution quality seen in live
  trading. So the executable-frontier collapse (L0 finding) is a lower bound, not the real fill cost.
- **Immediate research priority is NOT execution optimization.** It is **identifying entry-time
  conditions that raise the frequency AND depth of the 35–45% favorable excursion.**
- **Gate for deeper work:** if a sufficiently strong subgroup emerges, execution becomes a *separate
  empirical study* and may justify acquiring **depth / complex-order data** (currently out of scope).

## Why 35–45% (grounded against the L0 output)
The 35–45% credit-capture band sits right at the L0 sweet spot:
- mid take-profit hit-rate: **0.699 (35%) → ~0.66 (40%)** (grid 5 / 25 nearly identical)
- mean policy PnL 5.7 / median ROR 0.41 at 35%
- MFE: median **34.5 pts** (~57% of the ~60 credit), p90 61.8 (~102%) — so 35–45% is a level a
  large majority of trades actually *reach*, not a rare tail.
The "favorable excursion" is the intraweek path moving that far before it decays; the open question
is which entries get there more often / deeper.

## What this means for the next slice (L1: conditional entry)
- **Unit of analysis stays** the weekly iron fly over the v2 substrate; still analysis-layer only.
- **New layer = condition the entry** on Monday 11:30 state, then re-run the path/take-profit frontier
  *within* each condition subgroup vs the unconditional baseline.
- **Candidate entry-time conditions** (to test, not to bless in advance): entry credit level, IV level
  / IV percentile, vol regime, spot-vs-body distance, week-of-month / seasonality, prior-week outcome,
  term-structure skew. The PM did NOT freeze a conditioning set — choosing + ranking it is the task.
- **Readout per subgroup:** hit-rate & depth of the 35–45% excursion, the L0 frontier (mean/median
  policy PnL, give-back, post-touch Friday loss rate), sized against the unconditional 100W baseline.
  A "sufficiently strong subgroup" = one that materially lifts frequency AND depth vs baseline with
  enough trade count to be credible.
- **Non-goals carried forward:** no stop-loss optimization, no 75W/120W yet, no entry-time *rule
  change*, no execution modeling at this stage. Execution is explicitly deferred behind the subgroup gate.
- **Constraint to remember:** do NOT over-condition — the value is finding a *robust* entry condition,
  not fitting the historical path. Watch the trade count per subgroup and avoid post-hoc slicing.

## Status
- L0 (unconditional 100W) is FROZEN: `c64a1d18` + `6d82b3bc` (study) + `4c663e1b` (after-touch rate
  semantics doc). See the study card for the full results + the executable-frontier caveat.
- This ruling does NOT change the substrate, the model, or the L0 outputs. It sets the L1 agenda.
- Before conditionals, two further UNCONDITIONAL slices were completed + frozen (PM sequence):
  - **L0.5 continuation & give-back** — commit `8a5d9724`, card `2026-08-26_iron_fly_100w_continuation.md`.
  - **L0.6 upside-vs-giveback first-passage race** — commit `66cd81c8`, card `2026-08-26_iron_fly_100w_race_frozen_geometry.md`.
    Frozen interpretation (PM-corrected): geometry is STATE-DEPENDENT; exiting the 35–50% zone just
    because "the winner might disappear" is not supported (10-point races resolve upside-first
    64–81%); **60% is the first meaningful continuation FRONTIER, not the exit boundary** (45→60
    63.4%, 50→60 73.1% still favored; only the +15 extension from an early 35% state is ~indifferent,
    50.6%). This race table is the baseline every entry-conditional subgroup must beat.

## Open / next (PM sequence step 4 — entry-time conditionals, NOT started)
1. Propose + rank a small set of Monday-11:30 entry-time conditions; PM picks which to condition on (or approves a
   focused set). Then build the L1 conditional study as a new analysis-layer script over the v2
   substrate (route to coder, verify row-for-row, deposit). RE-SCOPED by the L0.6 conclusion: a
   candidate condition is judged on BOTH (a) acquisition — does it raise the frequency/depth of
   reaching 35–50% — AND (b) continuation — does it improve the race outcomes (P(upside first) vs
   P(giveback first), resolution times) within the 35–50% zone. Per-subgroup readout = the L0.6 race
   table vs the frozen unconditional geometry, plus base-reach rates vs L0.5.
2. Decide the subgroup-strength bar (continuation/give-back lift vs unconditional, min trade count) with the PM before
   declaring any condition "sufficiently strong."
3. Execution / depth-data acquisition stays deferred until a strong subgroup is established.
