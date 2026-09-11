# 2026-09-11 — CL pre/post-announcement observability study (4 Reuters episodes)

Thread: pi session, `studies/cl_prepost_observability/`. Spec v1.2 (frozen, amendments in-file) at
`/data/agentic_trading/studies/cl_prepost_observability/idea.md`.

## Built / decided

- Deliverables complete: `scripts/analyze_prepost_events.py` (qwen-coder, 3 bounces), `outputs/`
  (4 files), `verify/verification.md` (operator CLAIM|METHOD|PROOF), execution receipt
  `verify/clprepost_v121.20260910T181057Z.txt` (exit 0, SELF-CHECK PASS, 60.7 s, 43.5M CL_FUT rows,
  deterministic re-run byte-identical).
- **Committed, independently-verified answer (correct statement, operator 2026-09-11):** A CL-only
  monitor produced a **useful pre-post alert on E2** and a **provisional alert on E4** (3-lot
  threshold margin, independently unverified). It produced **no pre-post alert on E1 or E3**.
  The E2/E4 alerts occurred **materially before** the Reuters-reported transaction windows (77 min
  and 58 min), so **the current evidence does not establish that those alerts captured the same
  transactions described by Reuters** — aggregate CL volume cannot attribute participant identity,
  and pre-window alerts may reflect other flow on the same news.
  Supporting facts: E2 A3 S-class USEFUL 18:28:21 (8,231 ≥ 8,200, 4h02m before post); E4 A3 USEFUL
  18:55:35 (74m before post); E1 CL_CONFIRMATION_ONLY (post-5m 17,418 ≈ 16× baseline max, no
  pre-post alert — maxima A1 2,385 / A3 4,432 / A2|net| 714 all < LOOSE); E3 NO_DISTINGUISHABLE
  (Brent-only +100% surge; CL footprint ≤ baseline). WTI-leg pattern holds (alerts only where WTI
  legs were active) but is an observation, not a capture claim. LO_OPT corroborated nothing.

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
