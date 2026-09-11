# 2026-09-11 — CL pre/post-announcement observability study (4 Reuters episodes)

Thread: pi session, `studies/cl_prepost_observability/`. Spec v1.2 (frozen, amendments in-file) at
`/data/agentic_trading/studies/cl_prepost_observability/idea.md`.

## Built / decided

- Deliverables complete: `scripts/analyze_prepost_events.py` (qwen-coder, 3 bounces), `outputs/`
  (4 files), `verify/verification.md` (operator CLAIM|METHOD|PROOF), execution receipt
  `verify/clprepost_v121.20260910T181057Z.txt` (exit 0, SELF-CHECK PASS, 60.7 s, 43.5M CL_FUT rows,
  deterministic re-run byte-identical).
- **Committed, independently-verified answer:**
  - **E2 (04-07, ~2,400 WTI + 6,200 Brent)**: CL pre-post signal — A3 S-class 60s-gross USEFUL
    alert **18:28:21** (8,231 ≥ 8,200) → **4 h 02 m before the 22:30 post**, 77 min before the
    reported window. Largest exec 182 lots ≈ Reuters ~150-lot order. Unconfirmed (T_confirmed null).
  - **E4 (04-21, Brent-reported 4,260)**: A3 USEFUL **18:55:35** (8,203, margin 3 lots,
    operator-unverified) → 74 min before post. WTI legs active despite Brent-only report.
  - **E1 (03-23, 5,100 Brent+WTI)**: no pre-post alert (max A1 2,385 / A3 4,432 / A2|net| 714,
    all < LOOSE). CL_CONFIRMATION_ONLY: post-5m 17,418 ≈ 16× baseline max.
  - **E3 (04-17, Brent-only +100% surge)**: NO_DISTINGUISHABLE_CL_SIGNAL (post-5m 1,725 <
    baseline max 1,877). Brent-only ⇒ invisible in the CL pool.
  - Portfolio: CL-only USEFUL-burden monitor (≤1 alert/5 sessions) alerts pre-post for WTI-active
    events (E2, E4) only; **blind spot = Brent-only episodes**. LO_OPT corroborated nothing.

## Key facts pinned (reusable)

- Episode-budget thresholds (60 baseline trading days): A1 front-60s 8,100/15,400/23,500;
  A2 front-5m|net| dom≥0.6 1,100/2,000/3,000; A3 S-60s 4,900/8,200/19,600 (LOOSE/USEFUL/STRONG).
- Liquid front = F-class max gross, 5 most recent trading days (NOT expiry rank): E1/E2/E3 = CLK6
  (1,680,485 lots/5d vs M6 416,492), E4 = CLM6. **CLJ6 expired 2026-03-20 18:30 UTC** — impossible
  as front on all four event days (bug in bounce #2's "fix").
- Trading day = data in [00:00,01:00) AND [20:00,21:00) UTC; PARTIAL-TRAIL exclusion Mon–Thu only
  (Fridays close ~21:00 UTC); Good Friday 2026-04-03 has no partition (holidays just absent).
- Confirmation paths (frozen v1.1): (a) second stat ≥LOOSE same t, (b) rank-2 F net ≥0.5×gross2
  same sign, (c) LO_OPT 60s ≥ own USEFUL.
- CME Globex session structure: opens Sun–Thu 22:00 UTC CDT / 23:00 UTC CST; no Saturday partitions.

## Residual defects (documented in verification.md, unfixed — bounce budget exhausted)

1. E1/E3 disposition label in CSV (says HIGH_FALSE_ALERT_BURDEN; correct: CL_CONFIRMATION_ONLY /
   NO_DISTINGUISHABLE). 2. `confirmed_by=A1&A2` overstated (E2 proven false: A1=1,901, A2|net|=58
   at 18:28:21). 3. Missing E2 A2-LOOSE alert row (285 s around 19:46–19:51). 4. Percentile 100.8
   display. None affect the verified numbers.

## Next (if resumed)

- Small in-script fixes for defects 1–4; independent check of E4 18:55:35 (3-lot margin);
  optional Brent-side twin study (ICE pool) to complete the complementarity picture.
