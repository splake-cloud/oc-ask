# 2026-09-03 — SPX 0DTE fly wing-gamma adjudication → STABLE PROSPECTIVE CANDIDATE (P&L/tail)

**Ratified + pushed.** Adjudicated whether the observed `oig_wing_region_entry` wing-gamma
separation in the SPX 0DTE fly-continuation runner study is a stable state / entry-premium
interaction / era-scale artifact / small-sample pattern.

## Decision
**Ruling: STABLE PROSPECTIVE CANDIDATE** (on the **trade-determining P&L** endpoint
`runner_incr_25_10` = 2.5D-target / 1.0D-floor / 15:55 time-stop), **not** the target rate.

- **Target rate: no separation.** ≤32 capacity tradeable P25 = 19.9% vs 19.8% (lift +0.001,
  CI straddles 0). Rejects the "more 2.5D hits / more continuation" hypothesis.
- **P&L: real economic effect, era-consistent.** outcome-blind `T_FROZEN = 381.9129`
  (≤32 capacity median of `oig_wing_region_entry`), day/trade-cluster bootstrap:
  - ≤28 primary: **high − low = +0.143D** CI[−0.029,+0.312]; **pre-UW +0.102D, UW +0.288D (same sign)**.
  - 28–32 band: +0.333D CI[+0.051,+0.597]. ≤32 capacity: **+0.202D** CI[+0.066,+0.336].
- **Framing (per PM):** a *historically stable economic association*; *consistent with fewer
  1.0D stop-outs and better time-stop values* (fail 58.1%→39.8%, tstop 22.2%→40.4%), **not** a
  "clean mechanism," and **not** "confirmation" (in-sample). Practical candidate: high entry wing
  gamma may improve 2.5D runner economics by **protecting the downside, not increasing the hit rate.**

## Files (committed `feaceb12`, Agent-Print: author (qwen3.8-27b-fp8))
- `analysis/sml_fly_verify/adjudication/ADJUDICATION_REPORT.md` — Rev-2 report (ruling + tables).
- `analysis/sml_fly_verify/adjudication/PRE_REGISTRATION.md` — **frozen** prospective test plan.
- `analysis/sml_fly_verify/adjudication/ENVELOPE.md` (v3), `fly_gamma_adjudication.py` (delegate harness).
- Recomputation (source of record): `verify_final.py`, `verify_runner_pnl.py`, `verify_numbers.py`,
  `verify_uw.py`, `bsm_probe.py`.
- Receipts: `verify/fly-adjud-final-pnl.*`, `fly-adjud-verify-corrected.*`, `fly-adjud-verify-uw.*`,
  `fly-adjud-verify-bsm.*`.

## Key corrected facts (vs Rev-1)
- **Primary P25 = tradeable (winners/all incl. time-stop)** — PM Rev-2 restored it as primary;
  Rev-1's `winners/(winners+failures)` was a *framing* error (the delegate's original was right).
- **Trade P&L = `runner_incr_25_10`** (2.5D/1.0D/15:55), NOT `frozen_runner_increment` (2.0D live runner).
- **UW PIT alignment** = latest `gamma_profile_bars` snapshot ≤ 1.5D touch (no nearest/future).
  60/60 aligned, all lags ≥ 0 (median 3.0 min). UW signed gamma still **n.s. at n=20** (unresolved,
  not "adds nothing").
- **BSM**: denominators /54 (4 non-finite-IV 2022 days); `max_fly_mult`→`peak_fly_mult` (path max,
  not exit P&L). Observed fly peak is **never at the touch (0/58)**; observed peak *multiple* is
  actually **higher for low-gamma** (+3.15 vs +2.92) → the gamma effect is the P&L/composition,
  not a bigger fly peak.

## Open / next
- **Await PM ratification of the ruling** (SPC vs UNRESOLVED — the per-year P&L CIs are thin; only
  2025 clearly sig per-year, 2021 n=6 negative).
- Prospective test per `PRE_REGISTRATION.md` (endpoint = `runner_incr_25_10`, hold T_FROZEN,
  per-year + scale check); the **flat 2.0D-target / 1.0D-floor runner is unchanged.**
- Non-blocking: interaction terms (`wing×premium`, `wing×era`) didn't compute (KeyError) — §4
  "unresolved," not "absent." UW source script still uses nearest (adjudication harness uses corrected PIT).
