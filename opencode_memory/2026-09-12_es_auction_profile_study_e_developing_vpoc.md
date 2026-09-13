# Study E (developing-VPOC migration) — build chain + KASA — 2026-09-12

Thread: operator authorized D1→D2→D3→KASA after all D-items were ruled (D7/D8 AMENDED, T5
RATIFIED 2026-09-11; D1–D6/D9/D10 RATIFIED as REV-6 2026-09-12).

## What happened
- **Spec v11**: repaired draft (13 issues, 5 mechanical fixes), 24/24 mechanical checks
  (9 census + 15 fixtures), FROZEN at `0705bc6c`; two post-freeze mechanical typo corrections
  (both caught by D1 selftest: 5-param vs 4-param signature, 1350→1380) committed `28d7b8fa`.
- **D1** (`scripts/study_e_core_v1.py`, qwen38-collab :8011): 7 pure functions + selftest F1–F8.
- **D2** (`scripts/build_study_e_v1.py`, qwen-coder :8081): 2 bounces — (a) 24 NULL-contract
  violations (ctrl fields 0 instead of NULL on 12 infeasible rows); (b) 3 contract deviations
  caught by D3: twin treatment zeroed on 5 twin-infeasible rows, T4d computed over twin
  corridor instead of volume corridor, 20th VAP part pin (04-28) missing. All fixed + PM-verified.
- **D3** (`scripts/check_study_e_v1.py`, qwen38-collab :8011): G0–G10 PASS, X1–X6 OBSERVED-FAIL,
  verdict **NO** (all 6 subclaims; FLOOR=12 met exactly; 0/57 ties). One small EDIT bounce for
  two stale evidence strings (now state-dependent).
- **KASA** (pi seat, own re-derivation, no production imports): 04-16 hand trace S1–S7 all pass.
  Ledger: **0 BLOCKER / 1 MAJOR**. Commits: `1398f4dc` (scripts + kasa11 receipt),
  `d3aed6c9` (outputs).

## MAJOR-1 (pending operator disposition)
Bar-file pin coverage: build opened 21 bar files; study manifest re-lists only the 19 asof-date
pins. 04-28 (outcome for 04-27) and 05-11 (outcome for 05-08) are pinned **transitively** via
input 6 (study B manifest, sha-verified) — no content gap. G0 evidence prose misstates the pin
set ("20 pinned … 04-29 unpinned"); G0's mechanical check lacks a read-set pin-completeness
assertion. Frozen spec is internally inconsistent on pin count (L74 "19" vs L76 "20").
Options: waive (transitive pinning suffices) or bounce D3 for a G0 completeness check + string fix.

## Key facts that cost time (keep these)
- **04-28 is REFUSED** (NO_COMPLETE_NEXT_SESSION, spec L115) → never an asof; 04-29 is an asof
  and its file is never an outcome source (no row has next_session 04-29); 04-27's outcome
  comes from the complete 04-28 file (spec L76).
- Bar pool: partition dirs dashed (`trade_date=2026-04-15`), files undashed
  (`ES_ESM6_20260415.parquet`). VAP bins are raw-price units; event POCs are ×4.
- 05-08's outcome comes from the 05-11 file (05-11 exists in pool; 05-11 VAP part partial/refused).
- Scripts live in `studies/es_auction_profile/scripts/` — `python3 -c` needs
  `sys.path.insert(0, 'scripts')` (or cwd=scripts).
- Event column is `next_session` (not next_session_date). `d.asof` is a DataFrame method —
  bracket access only.
- KASA units gotcha: VAP `price_bin_native` is raw (7069.25), event POCs ×4 (28277).
- S1 near-miss observation: on 04-16 the end<=cut vs start<=cut boundary is non-discriminating
  (F7 fixture proves it CAN matter).

## Deposits (verify/)
spec freeze T010307Z · D1 selftest T010926Z · D2 build + nullcontract T013033Z ·
D3 gates T024614Z · D2 fix2: T025210Z/T025223Z + PM targeted T025443Z + PM independent T025610Z ·
D3 strings fix T025955Z/T030011Z · D3 final canonical T030100Z · KASA T030950Z (v2).

## Next
Operator: (1) MAJOR-1 disposition; (2) Study E closure ruling (verdict NO banked) or follow-up
study from the readout (T4 twin profile, CONDITIONAL splits). Study D remains CLOSED/NO.

## Cont. — MAJOR-1 cleared + CLOSED/NO (same day)
Operator ruling: D3 narrow pin-completeness fix → targeted KASA clearance → close. Executed:
spec erratum e139203f (operator-authorized mechanical; input-6 = 19 next-session pins incl
04-28+05-11; contract = 21 direct pins; G0 mandates mechanical 21/21, no transitive) → D2
(21 direct pins; event byte-stable) → D3 (G0 additive completeness assertion, liveness-proven;
prose fixed) → canonical re-run (11 PASS/6 OBSERVED-FAIL, NO) → targeted KASA 13/13 →
**ledger final 0B/0M → Study E CLOSED/NO** (receipts/study_e_closure_ruling.md).
**Queue A–E exhausted**: A NO → B NO → C YES(completion) → D NO (reach banked) → E NO.
Next = new operator decision (banked candidates: D reach replication; E T4-twin / CONDITIONAL
readouts). Deposits: d2_pins_rerun T031857Z/T031903Z, d3_g0_pins T032258Z, d3_canonical_pinfix
T032551Z, pm_pincheck T032608Z, kasa_pinfix_clearance3 (13/13).
