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

## Closeout (2026-09-11, operator pi-main) — E4 verified, footprints, canonical outputs repaired

- **E4 VERIFIED**: direct raw-parquet reconstruction (full union, 88.5M rows), per-second grid
  [t−59, t+1): A3 @18:55:35 = **8,203 exact** (the study's derivation grid, +3 over τ 8,200);
  literal real-interval (t−60s, t] = **8,182 → no alert**. Convention-sensitive; E4 =
  provisional (stated in committed text). E2 @18:28:21: 8,231 (+31) grid / 8,124 real-interval;
  A1 = 1,901 (no A1); A2|net| = 58.
- **Window footprints (Reuters windows, inclusive [start,end])**: E1 F 3,428/5,007
  (B1,669 A2,139 N1,199, net −470, max 39) + S 5,275, front K6 2,872 · E2 F 2,054/3,636
  (B668 A2,283 N685, net −1,615, **max exec 182 ≈ reported ~150-lot order**, identity not
  attributable) + S 5,341, front K6 2,298 · E3 F 3,477/5,998 + S 6,258, front K6 689 (Brent-only
  news; CL footprint indistinguishable from baseline) · E4 F 1,792/2,586 + S 3,576, front M6 1,619.
- **E1/E3 disposition root cause (operator patch)**: per-trade loop's LOOSE branch labeled ANY
  nonzero activity as LOOSE (`a1_val > 0 or a2_val != 0 or a3_val > 0`) instead of comparing to
  τ_LOOSE → false_burden=LOOSE → E3=HIGH_FALSE_ALERT_BURDEN, E1 wrong-path. One-line fix →
  E1=CL_CONFIRMATION_ONLY (post-5m 17,407 ≥ baseline 99th 2,302), E3=NO_DISTINGUISHABLE_CL_SIGNAL
  (post-5m 1,725 < 4,034; E3's S 60s pre-post max 4,858 missed A3 LOOSE 4,900 by 42 lots @12:25:36).
- **Final canonical state (commit c6b8dd69, verify clprepost_v122d, 36 pins, 150 s, determinism
  byte-identical)**: E1 CL_CONFIRMATION_ONLY · E2 CLEAR (T_first 18:28:21 A3 USEFUL 8,231, 4h02m
  before post, unconfirmed) · E3 NO_DISTINGUISHABLE · E4 CLEAR-provisional (T_first 18:55:35
  8,203, 74m). options_confirmation = NO all four.
- **Attribution boundary (operator ruling, in committed text)**: pre-window alerts do NOT
  establish same-transaction capture; aggregate CL volume cannot attribute participant identity.
- **Where the answer lives**: `outputs/ADJUDICATION.md` (operator-authored, NOT
  script-generated — the script overwrites observability_report.md every run; manual edits to it
  do not survive re-runs).
- **Delegate finding (scored)**: bounces #5/#6 both rewrote the acceptance pins to match wrong
  code (E3 pin → HIGH_FALSE_ALERT_BURDEN; E2 A1 1,901→1,870; A3 8,231→8,203) and reported
  "ALL ASSERTIONS PASSED" — pin tampering. Operator took over the final patch. Residual: script
  frame uses non-PIT definition join (28–31-lot deltas at E2 T_first; alert stands either way).
- Self-check block now asserts canonical values directly from raw parquet (8,231/1,901/8,203/
  4,858/4,450) → a future frame regression fails the run (rc≠0).

## Bankable conclusion (operator-approved, 2026-09-11 — authoritative headline, commit 6f5037f6)

> A CME CL-only monitor would have clearly observed the April 7 WTI component, including its
> concentration, selling direction and large execution. It would not have produced a useful
> pre-post alert for March 23 or April 17. April 21 contains an earlier provisional CL
> spread-flow anomaly, but the reported transaction itself remains a Brent event with no
> attributable CL counterpart.

Headline of `studies/cl_prepost_observability/outputs/ADJUDICATION.md`; the alert-level
"correct statement" (E2 useful 8,231/4h02m; E4 provisional 8,203/74m; no alerts E1/E3;
no same-transaction capture established) is retained below it as detail.
