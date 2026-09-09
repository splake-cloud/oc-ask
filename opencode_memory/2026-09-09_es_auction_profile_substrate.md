# 2026-09-09 ES Auction Profile research substrate — Phases 0–3 ALL CLOSED

Study: `studies/es_auction_profile/` (renamed from volume_at_price_distribution).
Operator = qwen3.8 (pi seat); builds = qwen-coder (:8081); KASA = qwen38-reviewer (:8012, read-only).

**Phase status (operator, 2026-09-09):**
- **Phase 1 — CLOSED / PASS.** Canonical true Trade-volume atomic VAP.
- **Phase 2 — CLOSED / PASS WITH KASA.** PIT ES cross-contract coordinate,
  independently adjudicated and remediated (rev 7).
- **Phase 3 — CLOSED / PASS WITH KASA FINDINGS.** Generic PIT
  full-distribution constructor; 384-file battery; independent semantic
  adjudication complete (final: 0 BLOCKER / 0 MAJOR).
- **Historical expansion gate — OPEN.** Acquire deeper ES Trade (T) history;
  before admitting real multi-contract profiles, close Phase-3 N1 (multi-hop
  chain walk) + the banked MINORs + re-run gates + new KASA round.

**What exists now:**
- **Phase 1 `vap_atomic_v1` (CLOSED/PASS, operator):** atomic true-VAP from
  Databento GLBX MBO `action=T` (CME Trade) events — 21 sessions (20 complete
  2026-04-13→05-08 + 05-11 partial), 214,442 rows, ESM6, 0.25-tick, 1-min
  intervals. Exact conservation vs bar layer (delta=0). F (Fill) =
  cross-check only (overcounts 0.94–1.69%).
- **Phase 2 `price_level_v1` (verified, all gates PASS exit=0):** cross-contract
  front coordinate. Front assignment = prev-session volume winner (PIT,
  truncation-tested) over 4,188 sessions (2010-06→present). Roll table: 65
  front-instrument transitions (64 settled + 1 data_gap), 4 dates per roll
  (trigger/effective/settlement/calibration), chained roll offsets.
  Enriched substrate = v1 + {price_front, front_contract}.

**Ground facts that took evidence to settle (all in spec/receipt):**
- Canonical volume = T, not F (T matches bar volume exactly).
- Settlement = 3rd Friday, last bar 09:29/09:30 ET (5/5 anchor verified).
- CME ES does NOT trade Saturday (Fri 17:00 → Sun 18:00).
- Roll count = 64–65, NOT 28 (28 was retracted folklore — my error, corrected).
- **Final-minute settlement artifact:** expiring leg's last print is
  contaminated (2020-06-19: spread −11.5 stable → −54.75 in the last minute,
  expiring leg 3156→3196). ⇒ offset = calibration-window MEDIAN (not
  settlement bar); G3 anchors on S(09:00); all S-metrics exclude last 2 min.
- **Symbol ambiguity:** ESM0 = June 2010 AND June 2020 (two instrument_ids) —
  all roll logic keys on instrument_id.
- Offsets −14.25 pt (2010, zero-rate dividend discount) → +69 pt (2026) = the
  3-month rates path. Effective-boundary divergence (true `residual_eff`,
  rev 7): |·| median 0.75 / p95 3.20 / max 8.50 pt — expected carry drift,
  closed by the §3 live leg (the rev-6 "≤ 1.5 pt" line measured a
  window-start deviation — KASA F1).
- 1 data gap: ESM6-2026 final day (06-19) missing from bar layer (last bar
  06-18 09:29). 4 flagged fat-tail windows (2020-03 crash etc., all G4-pass).

**Gate-lesson arc (4 re-calibrations, all spec-author errors, not delegate):**
fixed tolerances → data-derived; tick-continuity liveness → anchor liveness
(bar data is sparse by design); settlement-bar anchor → 09:00 anchor + median
offset (artifact); G4b hard-fail → flagged diagnostic (carry is a random
walk; G4 is the hard gate). Delegate's one gate-weakening (G5 day-before
relaxation) was REVERTED + data_gap status introduced.

**Canonical transcripts:** `verify/vap_atomic_v1_t_build.20260908T104227Z.txt`
(Phase 1); `verify/price_level_v1_final.20260908T140757Z.txt` (Phase 2).
Commit: `3e771fa7` (Phase 2) + `d2400169`/`b3ac38a3` (Phase 1). Parquet
outputs NOT committed (heavy-binary convention).

**Rev-7 post-KASA remediation (2026-09-09, same day):** KASA adversarial
adjudication (14 independent verification queries, all verify-run; verdict
ADJUDICATED WITH FINDINGS — data layer fully confirmed; F1 residual_eff
mislabeled, F4 trigger_date unreliable, G7 vacuous). Operator rulings, all
remediated by recompute + independently verified:
- **F1:** `residual_eff` = S(effective-session first bar) − offset (true
  quantity; no fallback). Row-level join vs KASA-8 independent all-65:
  **65/65, max |diff| 0.0**. Added `residual_cal_anchor` (G3 quantity,
  separate). G4 = distribution + 6 flagged rolls (med+3·MAD = 2.25) + sanity
  bound only (no small cap); the 8.5 pt max IS the live-leg evidence.
- **F4:** trigger = last session before effective where the specific
  successor *instrument* overtakes the specific outgoing *instrument*;
  1–3 day gaps (weekend straddles), 0 > 30 days (was 357–4015);
  cross-checked against raw bars (2018-12 → 12-14 ✓; 2026-03 → 03-16 ✓);
  `trigger_diagnostic_only = true` on all rows.
- **G7:** real consumer regression (fixture over ESH5→ESM5→ESU5: 4,912 bars,
  vol 769,206 exact, 413 bins bin-exact vs independent mapping, deterministic).
- **G3/G6** reclassified INTERNAL CONSISTENCY / IDENTITY-PLUMBING; receipt
  states gates validate implementation consistency only, independent mapping
  evidence = KASA-4/7/8/14.
Rev-7 canonical transcript: `verify/price_level_v1_rev7.20260908T150859Z.txt`
(fresh rebuild, ALL GATES PASS, exit=0). Spec rev 7 + receipt addendum.
Commit: `058682ec`. Phase 2 is now clean post-remediation (findings closed,
verified).

**Phase 3 `profiles_v1` (2026-09-09 — CLOSED / PASS WITH KASA FINDINGS):**
generic profile constructor on the P1/P2 substrate.
384-file battery = 192 definitions × {native, front}, complete_only; 5 anchor
families (fixed ctd/prior_eth/prior_rth, rolling N∈{2,5,10,20}, calendar
WTD/MTD, developing 10:30/11:30/16:00, event OPEX); 96 documented refusals;
12 gates (P-G0…P-G7 + P-G6c–f); on-demand CLI (asof drives inclusion +
coordinate state; 11-code refusal surface). Key verified facts:
- Conservation 384/384 int64-exact (independently re-derived twice, no
  production imports). Double build 385/385 byte-identical (independently
  reproduced; manifest build_ts is the only permitted diff, spec lines
  39/436/467-468).
- **prior_eth(D) = prior session full extent; prior_rth(D) = prior session
  09:30–16:00** (the round-1 BLOCKER — first build had same-day scope for all
  three anchor types; 76 files were mislabeled duplicates).
- front==native 192/192 (identity window, gate-checked); c_star=ESM6 on all
  192 front rows (single destination at asof T).
- Generation-aware fixed:<instrument_id> references: the 2016 symbol-twin roll
  (ESM6→ESU6, −9.0, settled) provably never selected; 42140870 (2026 ESU6,
  data_gap leg) → REFUSED_NON_PIT outside its life / REFUSED_DATA_GAP in-life
  (KASA3 RK4 ruling: life test first); 2615 (2016 twin) → ASOOF pre-coverage.
- Fixture cases (a)–(g) prove the frozen/live/data-gap/future/no-channel
  mechanics bin-for-bin; gates assert refusal CODES from structured tuples.
- Spec rev 4.1 pinned REFUSED_HORIZON: available = max_window(end,policy) =
  sessions at-or-before the end (end counts; v1 last-end = 20).

**KASA3 arc (3 rounds, `receipts/kasa3_adjudication.md`):** round 1
REFUTED (F1 BLOCKER prior_* scope; F2 generation-blind chain + unreachable
refusals; F3 inert fixture + wrong hand values + no channel; F4 weak gates) →
round 2 ADJUDICATED WITH FINDINGS (F-R1 MAJOR DATA_GAP unreachable; F-R2/R3/R5
minor; F-R6 MAJOR new: CLI ignored --asof — PM-discovered) → round 3
ADJUDICATED WITH FINDINGS: **all MAJOR closed; final 0 BLOCKER / 0 MAJOR.**

**Banked MINORs (operator ruling: NOT remediated before closure; banked in
`receipts/phase3_profile_receipt.md` + navigation with operator framing):**
- **F-R6-1** (life-test death bound for new-only instruments) — latent
  extension constraint; no effect on the current ESM6-only real substrate.
- **F-R7-1** (ANCHOR vs COVERAGE label on the include_partial edge) —
  classification/diagnostic semantics, not profile construction.
- **F-R7-2** (include_partial dry-path out-of-surface code) — non-operative
  interface edge under the current accepted surface, not stored-data
  correctness.
- **N1 (latent)** — multi-hop chain walk returns [] → silent 0.0; GATE on the
  historical expansion (close before real multi-contract profiles).

**Durable process doctrine (banked from Phase 3 — the round-1 BLOCKER is the
clean evidence):** *self-consistent gates prove implementation consistency,
not semantic correctness.* File, registry, and verifier all agreed on the
wrong prior_eth/prior_rth predicate because they inherited it; independent
reconstruction from the declared semantics (KASA's spec-predicate recompute,
no production imports) is what established correctness. Standing rule: PM and
KASA verification re-derive with independent predicates — gate re-runs are not
verification.

**Dispatch lesson (Phase 3):** 9 build/CLI dispatches (build1, build2, cli,
cli2, cli3, r1, r2, r3a, r3b, r3c) — the bounces were all legitimate (gates
sampled not exhaustive; registry schema deviation; c_star vacuous; ID parity
break; out-of-battery crash; event-front lookup; fixed-session asof pinning).
Gate self-consistency (file vs registry) does NOT catch wrong semantics — the
BLOCKER slipped past exhaustive-but-self-referential gates until KASA used
spec predicates. PM verification must re-derive with independent predicates,
never the gate's own.

**Open/next:**
- **Phase 4/5:** VPOC / value-area / encounter studies on the 384-file battery
  (full distributions stored; no derived content in the substrate by ruling).
- **Historical expansion gate (OPEN):** acquire deeper ES Trade (T) history
  (Databento GLBX ES multi-contract T+F beyond the 25 ET days in `es_mbo`);
  before admitting real multi-contract profiles: close N1 + F-R6-1 + F-R7-1 +
  F-R7-2, re-run the full gate battery + a new KASA round, then build the
  live-spread channel on real data.
- SPX cash equivalent: REMOVED from Phase 2 (operator ruling — outside the
  VPOC research architecture, not a Phase-2 re-open, not reserved). May be
  built later as a separate derived-coordinate module only if a future
  explicitly specified study requires a cash-index coordinate.
- `vap_atomic_v1` coverage is 21 sessions (front-month only, 2026-04/05) —
  native-grid studies bounded to that window until tick history is acquired.
