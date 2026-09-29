# credit_fly — Session Receipt (2026-09-22)

**Study:** credit_fly (short 0DTE SPX put butterfly credit-harvest)
**Date:** 2026-09-22
**Terminal state:** `claim not established` (entry timing undetermined)
**Pipeline:** idea → blueprint (ratified) → build spec (ratified) → build (COMPLETE)
→ independent KASA (dispatched) → Period C (opened per PM ruling) → **CLOSED**

## What was built

The full research_agent pipeline was executed through both ratification boundaries
(blueprint + build spec) and into the build + Period C. The study tested whether the
credit-harvest strategy (short 0DTE SPX put butterfly, selling the fly for credit)
produces a replicable edge, re-optimizing over the debit program's identified variable
space under the harvest objective (warm-started from the debit M3 solution).

## Key findings

1. **The C4 economic-feasibility gate did NOT fire** (Zone C) → NO-GO was never in scope.
2. **The optimized configuration (Period A) had a positive EV** (+0.465 D ≥ +0.10 D
   floor) and moved off M3 with a frontier improvement (M3 EV −1.299 → final +0.465).
3. **A2 (win-rate inversion) VACUOUS** — credit win rate (0.5044) < debit win rate
   (0.6741 MID) on all 3 scales. The "credit produces a higher win rate" hypothesis is
   false; harvest reduces to a pure EV question.
4. **Period B: the edge PASSED** (EV +0.4590 D, win rate 0.6667, N floor PASS). The
   **only** check that failed was the T*(state) replication (11/45 evaluable states).
5. **PM ruling (2026-09-22):** the T*(state) (entry-timing marker) was a design artifact
   — it should have been a conditional variable (state dimension), not a selection
   variable. Period C was opened.
6. **Period C: the edge FAILED** (EV −0.6914 D, CI entirely below 0, win rate 0.4731).
   C1 NOT ESTABLISHED (all 4 rules fail). The A/B edge did NOT carry into 2024+.

## Corrected framing (PM ruling)

**The study did NOT establish that the entry timing is "noise" or that the A/B edge is
a "sample artifact."** The correct framing:

- **The target market state is undetermined on entry timing.** The study did not
  identify a stable entry-timing marker. This is an **open question**, not a refutation.
- **The entry timing is empirically likely different from the debit fly program** (which
  used a fixed entry, not an optimized T*).
- **If a derivable program exists, entry-timing identification is the subject of a
  future study (if there is to be one).**

## Follow-up study item (if there is to be one)

**Entry-timing identification for the credit fly.** Treat the checkpoint (entry timing)
as a conditional variable (state dimension), not a selection variable. Determine how to
identify the entry point to maximize the edge. The T* argmax (median captured credit)
is one candidate but did not replicate out-of-sample.

## Artifacts

- Blueprint (ratified): `specs/blueprint.md` (sha256 `2245ad7f…`)
- Build spec (ratified): `specs/build_spec.md` (sha256 `2a5e3217…`)
- Manifest (sealed): `specs/method_applicability.yaml` (sha256 `3772f28e…`)
- Build report: `receipts/build_report.md` (RESULT: COMPLETE, all 15 assertions PASS)
- Decision artifact: `outputs/s8/decision_artifact.md`
- PM ruling (continue to C): `receipts/pm_ruling_continue_period_c_2026-09-22.md`
- S6C receipt (Period C): `receipts/s6c_receipt.md`
- Phase 1.a snapshot: `outputs/s3/phase1a_snapshot.parquet` (sha256 `2f666136…`)

## Pipeline position

`idea (ratified) → blueprint (ratified) → build spec (ratified) → build (COMPLETE)
→ independent KASA (dispatched) → Period C (opened per PM ruling) → CLOSED`

The study is **CLOSED** with the terminal state `claim not established (entry timing
undetermined)`. The KASA (independent verification of A01, A07, A09, A10) was dispatched
and is in progress; its verdict does not change the terminal state (the edge failed on
C regardless of the KASA verdict).
