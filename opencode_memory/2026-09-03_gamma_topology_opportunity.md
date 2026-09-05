# 2026-09-03 — SPX 0DTE fly gamma-topology → opportunity map + ranked ledger (discovery)

**Committed + pushed** (through `c2b90cdf` + D4 correction pass; D4 ratified 2026-09-04 target-first +1.0D; Agent-Print:
author qwen3.8-27b-fp8). Separate **discovery branch** from the frozen adjudication registration
(`feaceb12`, untouched). Objective: **opportunity discovery + market-state characterization**, not
"prove most states unusable." Significance = evidence metadata, not a gate; 6-class classification.

## What was built
- **Corrected Phase-0 substrate** (`gamma_topology/gamma_topology_phase0.parquet`, 637×268): robust
  materiality (dom_mat_log / pctile / comparator_support, null semantics) replacing the degenerate
  `W_dom/median(W)`~1e12; 6-way location (distinct below/above-wing); **mechanical raw-gamma vs
  OI-weighted** profiles + `excess_conc = oig_share − raw_gamma_share`; top1_share (node-level) vs HHI
  (strike-level) both kept (same mass `total_gw`); R5 two-sided decay vs `elapsed_min` (R²=0.207 →
  ~80% is change beyond the clock, not a time artifact). Independently verified: 0 recompute
  mismatches (5 days × 19 feats), real-rebuild md5-identical, outcome-blind.
- **Phase-1 opportunity map** (`phase1_opportunity_map.py` + `phase1_combos_evidence.py`): join to
  outcomes (PIT), 7 families × 24 features × 4 books + 5 motivated combos = **240 states**, case
  bootstrap (block-by-year, B=10000, SEED=42). Verified: baseline + 8 family bucket tables 0
  mismatches; bootstrap CIs reproduced exactly.
- **Ranked ledger** (`PHASE1_LEDGER.md`): 8 questions per state + 6-class classification +
  conclusions.

## The honest central finding
The strongest raw "topology" signal, `raw_gamma_atm_share` (r=+0.189), is a **premium-band proxy**:
partial(|premium)=+0.020, corr(premium)=+0.848, corr(premium,P&L)=+0.211. **Reframed as a premium
effect, NOT gamma topology.** This is the ledger's headline caveat (the delegate's console had also
mislabeled a two_sided bucket — the parquet was correct; read the verified parquet, not the console).

## Genuine signals (survive premium control) → classification
- **SUPPORTED:** OI concentrating into the touch (`excess_conc_dom_delta` Q4, lift +0.19 CI
  [+0.02,+0.36], era-stable 6y, partial +0.120); node **below the body** = avoid (`dom_dist_body` Q1,
  6/6y negative, partial +0.106); OI-concentrates × tall-hump combo (lift +0.21 CI [+0.05,+0.38],
  UW-stronger, carries the premium).
- **PROMISING:** two-sidedness collapses into touch (lift +0.17, but redundant w/ `elapsed_min`
  r=−0.36); node-at-body × prominent (n=22, CI crosses 0).
- **RARE-CONVEX:** below-lower-wing × low-prominence skip (n=9, lift −0.39, UW-worse).
- **REGIME-SPECIFIC:** long-time-to-touch (era proxy — pre-UW touches later, median 205 vs UW 154 min).
- **DESCRIPTIVE/flat (no differentiation):** asym, two_sided_entry, top1_share, n_nodes,
  comparator_support.
- **CONTRADICTED (as topology):** raw_gamma_atm_share / raw_gamma_hhi (they are the premium).
- Book note: **band 28–32 (n=91) mean P&L +0.173 > primary ≤28 +0.053** (via its time-stop value
  +0.485). The edge is in sizing/skipping + the band book, NOT a different target/floor.

## Open / next (PM calls)
- Premimum *level* (not just band) within-band re-test to firm up "genuine topology."
- `elapsed_min` / two-sided need a within-era (UW-only) re-test (they are era/clock-entangled).
- Leg-level mechanism (which fly leg does the work) to upgrade "supported" → "mechanistically grounded."
- Prospective out-of-sample confirmation (Phase 1 is discovery; live use is a subsequent decision).

## Record correction (2026-09-03) — Phase 1 used NO UW data
Phase 1 used **only the ORATS opening-inventory (oig_) substrate**. The “era” split
(`tradeDate ≥ 2025-12-12`) is a **date boundary on ORATS**, NOT the UW signed substrate — the earlier
“UW-era / UW-stronger / pre-UW” labels were misattributed. Relabeled to post-/pre-2025-12 ORATS-era
(pure relabel, data unchanged, joined frame byte-identical). Pushed `0866cde2` (SUBSTRATE note added to
the ledger; era keys pre_UW/UW → pre_2025_12_orats/post_2025_12_orats).

## Phase 2 — UW SIGNED dealer-exposure topology (the omitted arm) — pushed `e5b981fd`
Built + independently verified. Reads `gamma_intraday` **THROUGH the `gamma_research_active` view**
(research_v2.duckdb) — UW’s **dealer-signed MM exposure** (+ dealers long / − short; finished vendor
black-box, NOT OI-weighted, different units; describe only as “UW’s dealer-signed exposure”, not
independently-verified live positioning). **Two SEPARATE arms** (expiry break 2026-06-30): ALL-EXPIRY
(n=86) + 0DTE-ONLY (n=25). States: entry (latest slice ≤11:30, lag 0) + latest PIT-safe at touch (lag
med 4). **Coverage 111/111**; missing-close matters only for **10 regime-A (≤2026-03-06) ALL-EXPIRY
days** (touch 30–65 min pre-touch, flagged). Verified: Part A 0/184-field recompute mismatches (3
regimes, 2 arms); Part B 16/16 agreement cells + a reproduced block-bootstrap CI (exact).

**Headline (ALL-EXPIRY, CI≈excludes-0, year-consistent):** the **net-gamma SIGN axis** — dealers
**SHORT** gamma at entry + touch → size up (net_e Q1 +0.511 tgt .54; net_t Q1 +0.429), dealers **LONG**
at entry → skip (net_t Q3 −0.237 flr .81). Also: **concentrated dominant long-gamma node at entry**
(+0.539 CI[+0.185,+0.841]) + **concentration building into touch** (+0.521) → size up (agrees with
Phase-1 S1 “OI concentrates”). Low corridor exposure at touch (−0.273) + two-sidedness building (−0.208)
+ dispersed at entry (−0.192) → skip. **0DTE arm: direction-consistent but underpowered** (n=25, no CI
excludes 0) — retained, not discarded.

**Agreement (UW signed × ORATS inventory):** **CONFIRMS** on concentration (both high +0.213) +
two-sidedness (both +0.236) → the two substances are complementary/non-redundant on those axes. **DOES
NOT transfer** on node-position: the oig_ “node-below-body = avoid” (Phase-1 S2) fails on the signed
substrate (UW “below” = the dealer short node, a different object).

**Large-lag re-test (`a603fd3a`, `uw_exclusion_retest.py`, `verify/fly-topo-uw-excl-retest`):** keep each
headline state's 86-day definition, drop its 10 `large_touch_lag` members. Result — **no headline depends
on the 10:** net-gamma-touch Q1/Q3 have **0** large-lag days (byte-identical); concentration-delta's 4
large-lag days *dilute* it (non-lag core n=5, +0.669, stronger); corridor direction held; entry states
essentially unchanged (<=2 large-lag each). Every positive headline gets slightly STRONGER with the 10
removed (they average weaker than each state's core). Cost: concentration-delta non-lag core n=5.

**Open (PM calls):** prospective out-of-sample confirmation; re-test the 10 large-lag regime-A days
(exclude them); leg-level mechanism; accumulate the 0DTE arm. No live rule / registration change.

Files: `analysis/sml_fly_verify/gamma_topology/` (PHASE0_REPORT, REFINE_SPEC, PHASE1_*, PHASE2_UW_LEDGER,
UW_COVERAGE_REPORT, UW_PHASE_A/B_ENVELOPE, phase2_uw_topo.py, phase2_uw_opportunity.py, verify_*).

## Phase 2C — joint signed-gamma map (`51f5e998`) — 2026-09-04
PM asked: is short net-gamma sufficient, or does the positive-node location/concentration condition
whether short gamma -> fly expansion vs escape/stop-out? Builder `phase2c_uw_joint_map.py` (dispatched to
qwen-coder, independently verified: states/CI/leg-identity/MAE all 0-mismatch, deterministic).

**Answer (ALL-EXPIRY): short net-gamma is necessary but NOT sufficient.** Within the 54 net-short touch
days, the (in-corridor x prominent) 2x2 of the dominant pos node:
- **S1 (prominent pos node INSIDE the corridor): n=5, mean -0.140, target 0.00, floor 0.40** <- the ONLY bad cell
- in-corr not-prom n=22 +0.174; prominent OUTSIDE n=4 +0.382; no-local n=23 +0.117
- **S2 (other 3, no prominent local wall): n=49, +0.164, target 0.286**
A concentrated dealer long-gamma wall inside the corridor pins SPX back to the body -> fly floors. S1 is
n=5 (rare, mechanism-generating, not a sizing rule).

**Attribution (5 mechanisms, net_short vs net_long):** works by (a) PRESERVING THE SHORT-BODY GAIN
(pct_from_short_body_diff +2.64 = best separator; body_leg +1.32) + (e) TIGHTER FLY (move_required_25D
8.7 vs 30.1 pts, ~3.5x closer) + SPX moves more (stay-in-corridor 0.835 vs 0.906). NOT wing-cushion, NOT
"keep SPX inside" (opposite), NOT IV/smile.

**4 lead states** S1-S4 per arm (never pooled), with support/P&L+CI/target/floor/tstop/MFE-MAE/transitions.
ORATS agreement overlay: UW + ORATS AGREE on concentration (bad S1 = wing-concentrated opening inventory;
good S2 = two-sided/balanced). 0DTE arm (n=25) is directionally DIFFERENT (net-short + at-body is GOOD
there) - do not transfer AE cell-signs. net_gamma_touch = principal supported axis. No registration/live change.

Also: closed the large-lag issue as RESOLVED + corrected summary language to "all 10 observations with
30-65 minute touch-snapshot lag" (measured 31-65 min) (commit `e7455cfa`). NOTE: the push to origin
carried a concurrent session's commit `3d95bed4` (rag_verifier, Claude Opus 5) that was local-only + in the
ancestry of my work - linear history, valid complete commit, no uncommitted work affected.

## Phase 2D — net-gamma INDEPENDENCE adjudication (`67a963c5`) — 2026-09-04
PM asked: does short net-gamma INDEPENDENTLY improve runner economics, or does it merely identify touches
with already-favorable geometry (the 8.7-vs-30.1 close-target gap)? Restricted to reporting + the geometry
confound + PIT + 3 ledger fixes. No search/registration/live change. Builder `phase2d_netgamma_adjudication.py`
(qwen-coder, verified); `PHASE2D_ADJUDICATION.md` + `PHASE2D_ENVELOPE.md`; `gamma_topology_uw_phase2d_*.parquet/json`.

**VERDICT: net-gamma is a touch DESCRIPTOR, not an independent sizing signal.**
- **The traded (<=28) book shows NO net-gamma edge** (the decision-relevant answer): raw net_long +0.127 >=
  net_short +0.089 (net-long slightly higher); geometry-adjusted dR^2 = 0.000 (net-short coef 0.004).
  S2 also not better than remaining in <=28 (0.088 vs 0.125).
- The net-short "advantage" is an ALL-population / **28-32 band** phenomenon (band raw +0.098, n=13/4),
  NOT the <=28 book. Across pops, net-short adds <=1.4% R^2 beyond the 6 touch-geometry covariates
  (entry_premium, touch_time, |SPX-body|, implied_move, dist_upper/lower), none significant.
- **The close-target confound is untestable at scale**: `move_required_25D` is defined for only **7/111
  UW-era days** (5 net-short + 2 net-long). The Phase 2C "8.7 vs 30.1" was these 7 days (overstated). The 7
  days sit in the fly-tight/low-vol regime (implied_move med 8.1 vs 19.1 for the 104 NaN days). In those 7,
  net-long DOES have far targets (med 30.1 vs 7.4) - confound present but n=2 net-long is tiny. The measurable
  geometry (implied_move/dist-to-wings/reaches_25D) does NOT differ between net-short/net-long, so the net
  effect is not explained by measurable geometry - it's an UNRESOLVED descriptor.
- **Planning vs governance:** net-short state is favorable at BOTH entry (11:30, P&L 0.198) + touch (0.169);
  entry (planning) slightly stronger.
- **PIT ruling:** `move_required_25D` is PIT-safe (touch-time IVs + SPX + T + entry geometry; NO future
  data) + a valid live input, but SPARSE (7/111 days; only when fly below 2.5D target at touch + IVs valid).
- SIZING: do NOT size the <=28 book on net-gamma (adds no info). Descriptor only. No live/registration change.

Also: corrected 3 Phase-2C ledger lines ("necessary"->"FAVORABLE but not sufficient on its own"; S1
"pinning mechanism"->"rare conflicting pattern, NOT a demonstrated mechanism"; "tighter fly"->"the 2.5D
target being closer in SPX-space") + corrected the record that the 8.7/30.1 was 7 days. Frozen registration
+ live rule byte-identical to `feaceb12` (verified).

## UW substrate update-through-9/3 verification + 9/3 reconstruction (`3dd2e2c6`) — 2026-09-04
Substrate-and-inspection task (no hypothesis tests/rule search/registration/classification). Verified the
live-feed re-ingest (2026-09-03 20:55Z) that brought the canonical UW Periscope SPX dealer-gamma substrate
(`pools/uw_gamma/`) through 9/3. **PASS on all 10 points, no STOP triggered.**
- old max 2026-09-01 (180 dates, 7,261 snaps, 1,587,919 rows; git blob e9c6912b) -> new max 2026-09-03
  (182 dates, 7,347 snaps, 1,607,478 rows). Appended 9/2 (9,735) + 9/3 (9,824) = 19,559 rows, 86 snaps.
- 43 captures/date (09:00-16:00 ET, 42 on-sched + 1 off-sched 20:00Z rejected). 9/3 = `0dte` (0DTE-only,
  expiry_raw=2026-09-03), consistent with 8/21-9/2 (regime flipped all_expiry->0dte ~2026-06-16/29).
  0 dup keys, 0 null/0 sign-mismatch, raw supplier units (gamma -51842.6..89087.2). 152 non-flat strikes,
  7200-7960; 7750/7730/7770 dense 5-pt.
- Pre-update unchanged via PM-approved equivalence class (re-run independently): C1 per-strike+snapshot
  bidir EXCEPT=0 vs git blob; C2 accepted_rejected byte-identical 7262-line prefix (+86 new); C3 manifest
  360/360 content-equiv (sha drift = re-ingest). Independent recompute 9/2+9/3 (DuckDB SQL over raw lake
  parquet): max abs diff 0.0 (per-snapshot + per-strike).
- **9/3 reconstruction (descriptive only):** 7750 unremarkable PRE-OPEN (rank 9-12, 09:00-09:30, no spot,
  gamma ~270-370), already LARGEST dealer-long node at first spot capture 09:40 (SPX 35 pts away), lapsed
  rank 2-7 during the 10:00-11:00 dip (7694),
  durable rank-1 from 11:10 through close (share->0.97, gamma->89,087) as SPX pinned at the 7750 body.
  Gamma takeover: 09:40 rank-1 was TRANSIENT (lapsed 10:00-11:00 dip); durable rank-1 from 11:10, COINCIDENT
  with the SPX impulse onset (11:10->11:30), price arriving ~20 min later (11:30). No clean lead (corrected
  from an earlier 1.5-2h over-claim). SPX overshoot +6.30 (14:16), ~4h within 10pts. 7750/7730/7770 PUT fly (putMid(7730)-2putMid(7750)+putMid(7770), 0DTE) entered 11:30 for
  $6.25 = 31.25% prem (28-32 band, ABOVE the <=28 primary book); +40/+45/+50 at 12:30/12:52/12:56; max
  +168% at 15:58; adverse dip -0.8%. Reconciles w/ trader's obs (7750 green/dealer-long, largest by ~11:00)
  - NO discrepancy (durable rank-1 from 11:10). No generalization, no cohort design.
Files: `analysis/sml_fly_verify/gamma_topology/` (UW_SUBSTRATE_903_VERIFICATION.md, UW_903_RECONSTRUCTION.md,
uw_903_capture_table/gamma_grid/fly_1min.csv). Frozen reg + live rule byte-identical to feaceb12.

## Cohort map — 11:30 gamma-body alignment (`529cb1ce`) — 2026-09-04
Built the descriptive cohort map (dispatched to qwen-coder, independently verified) over the **111 UW-era
study days** (P&L book ∩ gamma dates, 2025-12-12→2026-08-31). For each 11:30 fly: the 11:30 dominant
positive-gamma node + the body's pos-gamma rank history, 5 node-history groups, temporal order, the
continuous profile (rank/share/margin/distance/arrival/overshoot/pre-entry-dwell, no frozen threshold),
+ the fly/SPX outcomes (+40/45/50, time-to-target, adverse excursion, max fly return 15:55, afternoon
body dwell, settlement), split by premium band + expiry regime.
- **The body IS the 11:30 dominant node on only 12/111 days (10.8%)**: A1_EMERGENT=2, A2_PERSISTENT=9,
  +1 T blip. Full partition: T_TRANSIENT=34, E_ELSEWHERE=21, N_NEVER_ABSENT=45.
- **CORRECTION (re-verified 2026-09-03): 9/3 is A2_PERSISTENT, NOT A1_EMERGENT** — the "rank 9–12"
  values were the PRE-OPEN 09:00–09:30 snapshots (no spot); at the first spot capture (09:40) 7750 was
  already rank 1, so its best open-window rank (09:40–10:10) is 1. The durable-dominant-node pin still
  RECURS: A1_EMERGENT n=2 (2026-03-13, 2026-05-01, book) + 9/3 raw as the A2_PERSISTENT 0dte variant.
  **Outcome-mixed (D4 ratified 2026-09-04):** the two book A1 days LOSE (−0.5 floor-first; touch
  LATE ~13:30; min fly_mult 0.60/0.33; 1.0D floor trips before the 2.5D target; recover in value
  ~2.2–2.5× but lose as traded). **9/3 is the opposite shape: +1.0D, subsequently
  2.5D-target-first** — touched 12:56 (mid convention) after a shallow 0.992 PRE-TOUCH dip at 11:32
  (an acquisition-path observation only, not a floor event), never fell to the post-touch floor,
  crossed 2.5D.
- **The "expensive fly that monetizes cleanly" hypothesis is REFUTED on the book days**: the aligned
  EXPENSIVE BOOK flies (b28_32+gt32, 7 days) NEVER hit the 2.5D target (0/7); the aligned cheap (le28,
  5) hit it 2/5. Across the book, >32 is the WORST monetizer (2.5D hit 1/34), le28 the best (22/60) —
  premium and clean monetization are NEGATIVELY related. **9/3 (raw, 31.25% mid, aligned
  lapse-and-reclaim, +1.0D) is the first raw counterexample candidate — one day.**
- Catalog-size (A1 n=2 book, A2 n=9 book + 9/3 raw, aligned n=12, aligned-expensive n=7): descriptive,
  not a test. All A1 are all_expiry; no 0dte A1 in the book (the 0dte pin variant exists only as raw 9/3,
  A2_PERSISTENT). 9/3 is a raw reconstruction (P&L book ends 8/31); its runner is **+1.0D
  target-first** under the frozen post-touch contract (D4 ratified 2026-09-04); the 0.992 dip at
  11:32 is pre-touch, an acquisition-path observation.
- Files: `cohort_alignment.parquet` (111×35), `cohort_map_builder.py`, `verify_cohort.py`,
  `COHORT_MAP_ENVELOPE.md`, `COHORT_ALIGNMENT_REPORT.md`. No registration/live change.

### 182-day complete population: path fields + subtypes (2026-09-04, committed c2b90cdf)
PM task (full text in transcript): add 7 outcome-blind path fields to the complete 182-day
acquisition population; recompute group counts on the full population; report acquisition
outcomes by path subtype with runner separate; confirm 9/3 A2.

- **Deliverables** (topology dir): `ACQ_PATH_FIELDS_ENVELOPE.md` (S1–S13, 3 revisions),
  `acquisition_scorer.py`, `verify_path_fields.py` (V1–V5), `acquisition_scores.parquet`
  (182×41), `ACQ_PATH_SUBTYPES_REPORT.md`. Plus first-round files committed this time:
  ACQUISITION_ENVELOPE.md, acquisition_scorer.py (orig), verify_acquisition.py,
  acquisition_scores.parquet (orig) — the 4 previously-untracked acquisition files.
- **Groups (full population, NOT book-inherited):** A1=3 (book's 2 + **2026-04-24**, a
  non-touch A1 day the touch-conditioned book never saw), A2=16, T=56, E=38, N=69.
  111 overlap days reproduce the book cohort exactly (A1=2, A2=9, T=34, E=21, N=45).
- **Subtypes:** NEVER_DOMINANT 107, TRANSIENT 53, LATE_EMERGENCE 14, LAPSE_RECLAIM 7,
  CONTINUOUS 1 (the single day dominant from first spot capture through close). Invariants
  verified (CONTINUOUS⊆A2, LATE_EMERGENCE⊆{A1,T}, NEVER_DOMINANT⊆{E,N}, LAPSE_RECLAIM⊆{A1,A2,T}).
- **Acquisition read (descriptive):** premium band dominates (le28 ≈ 76–100% at 150%,
  gt32 ≈ 38–67%); within band, dominance-path subtypes acquire cleaner/earlier (LATE_EMERGENCE
  median t150=206 min vs NEVER_DOMINANT 299; TRANSIENT deepest adverse excursion, min-fly 0.39).
  No sweeps/tests — fixed cells only.
- **Runner reported separately** (frozen post-touch contract): rebuilt in Revision 2 after
  finding the original `runner_floor_first` was structurally ≡1 (ask/bid debit ⇒ every day
  starts <1.0×, floor fires at bar 0). New columns `runner_reach_25_before_10` /
  `runner_incr_25_10`; 111/111 exact vs runner_features_v3 (delegate V5 + my own independent
  first-passage from nearest25, 0 mismatches).
- **9/3 confirmed A2_PERSISTENT / LAPSE_RECLAIM:** pct 4/15, streak 30 (11:10→16:00),
  lapses 1, takeover 11:10, cont 0, lr 1, le 0. Book-faithful row: debit 6.50, 32.5% (gt32),
  t140/145/150 = 122/126/176 min, min-fly-before-150 0.954, max 2.5115×. Ratified mid-convention
  status (31.25%, 28–32 band, 12:30/12:52/12:56) reported alongside; gap = leg spread.
- **D4 RATIFIED (2026-09-04, target-first, +1.0D):** 9/3 touched 1.5D at 12:56 (mid convention),
  never fell to the post-touch floor (post-touch min 1.32 mid / 1.75 ask-bid), crossed 2.5D →
  **+1.0D, subsequently 2.5D-target-first** (NOT −0.5D). Every "subsequently floor-first" narrative
  corrected; the 11:32 dip (0.992) preserved only as an acquisition-path observation. **MID
  convention = primary study result; ask/bid = labeled execution comparison** (not the governing
  research mark). Corrected characterization (PM wording): "A 31.25%-premium fly entered during a
  lapse-and-reclaim body-node state reached +40%, +45% and +50%, suffered almost no meaningful
  acquisition drawdown, never hit the post-touch floor, and subsequently reached 2.5D." Decision
  table (premium band × path subtype, +45%-leading: n / +40 / +45 / +50 / median t→+45% /
  pre-target min / 2.5D runner) extracted from the existing 182-day file into
  ACQ_PATH_SUBTYPES_REPORT.md §5 (no new search); 9/3 = cleanest acquisition in the file (fastest
  t145 in its band, best pre-target min in its cell) and the first raw counterexample to the
  book-days refutation. Candidate (coherent, n=1, needs accumulation): a wider-premium fly with
  favorable body-node evolution may acquire cleanly and still retain runner value. Correction pass:
  D4_CORRECTION_ENVELOPE.md (sections A–E) applied to ACQ_PATH_SUBTYPES_REPORT.md +
  COHORT_ALIGNMENT_REPORT.md + both correction envelopes; UW_903_RECONSTRUCTION.md needed no change
  (its 0.992 dip was already acquisition-framed). 2026-09-04 table correction (PM ruling): §5
  regenerated in the governing MID convention (current raw pool, uniform 182 days): 25 days
  re-band; the 28–32×lapse/reclaim cell is **9/3 itself** (t145 = 82 min @12:52, pre-target min
  0.992, +1.00 target-first — the expected anchors); the old cell's 205/0.89/0/1(+0.97) was
  **2026-02-11's ask/bid row** (29.0%; re-bands to ≤28 at 26.5% mid; 205 = first 1.45× at 14:55 on
  the file's nearest25-era path — minutes from 11:30, correctly labeled; 0.89 = its ask/bid
  mfb145; 0/1(+0.97) = that day's frozen-book time-stop runner, internally consistent). Strongest
  rows in the governing numbers = **late emergence**: ≤28 LE **8/8 reach +50%** (t145 median 93
  min, fastest in table); >32 LE 3/4 at +45 and +50 (direction unchanged from the ask/bid display
  5/6, 4/6). 02-11 source-divergence flag (future audit): file row (nearest25 book-era path)
  vs current raw pool differ mid-afternoon (first 1.45× 14:55 vs 13:35; same 15:55 exit
  2.4698×); other spot-checked book days (04-06, 12-17, 07-14) match exactly. Numerators
  independently re-verified from row-level flags; both singleton cells traced to source rows.
  Refutation wording corrected (cohort report + memory): "Among the seven previously examined
  aligned expensive touchers, none reached the 2.5D runner target under that analysis."
- **LATE_EMERGENCE FROZEN for forward accumulation (2026-09-04, LATE_EMERGENCE_FROZEN.md +
  late_emergence_14_inspection.csv):** definition frozen at S11 (first rank-1 > 1010 AND 16:00
  capture rank-1; invariants S12/S13). 14-day inspection: **the state is a late-afternoon
  dominance state, NOT an entry-time state** — 13/14 days body NOT rank-1 at 11:30 (9/14 body
  gamma NEGATIVE at 11:30); takeover START vs +45%: BEFORE on 3 (03-13 10:20, 03-25 12:40,
  08-14 11:50), AFTER 10, MISS 1 (04-15); but the live 3-capture CONFIRMATION (the actionable
  timestamp — a start is not knowable live) gives **2/11/1**: only 03-13 (10:40) and 08-14
  (12:10) confirm BEFORE the day's +45%; 03-25 flips (confirm 13:00 > +45% ~12:47); 6 S11 days
  have NO confirmation at all (body rank-1 in exactly one capture). **Verified actionable
  anchors = 03-13 + 08-14 only.** Guardrail (PM): S11's 16:00-conditioned success rate is NOT
  the live event's expected performance. Gamma FOLLOWED price
  on 13/14; **on 2026-03-13 it LED ~43 min** (takeover 10:20 with SPX 41pt away; first ≤10pt
  arrival 11:03; never ≤5pt pre-11:30) — the only lead, and the only day the state was known at
  11:30 (rank-1, 2.81x, streak 34). Dist at takeover: 13/14 ≤13pt; 03-13 = 41pt, 06-09 = 25pt.
  Afternoon bimodal: pinned vs wander (06-09 max 82pt) — all 14 end day with body dominant.
  CHECK A: both regimes (all_expiry +45 10/11; 0dte 3/3). CHECK B: within band x 11:30-distance
  cells LE still outperforms (e.g. >32 ≤5pt 4/5 vs 16/36) BUT the entry-time difference is
  DISTANCE (LE median 3.6pt vs 6.1pt), not gamma — on 13/14 the state is an intraday
  confirmation, not an entry signal. **Corrections (PM review, logged in doc §6):** original
  table said "followed on all 14 / ≤25pt / 12-of-14 before takeover" — all three wrong, caused
  by a minutes-vs-HHMM bug in the rel/timing logic for the 5 durable-run days (takeovers
  rendered as 17:00/20:40/25:10/23:50/22:20); re-derived from raw captures. Frozen hypothesis
  (PM wording): body becomes durable dominant pos-gamma node after the opening window -> higher
  prob +45-50%; ≤28 preferred, 28-32 candidate extension; no runner-policy override until
  continuation accumulates. Accumulation protocol: log BOTH timestamps (takeover start +
  durable confirmation) + takeover-time strata + dist_1130 + band + mid attainment +
  frozen-contract runner separately. No live/registration change; definition frozen (change =
  new label).
- **LIVE TAKEOVER EVENT CATALOG (2026-09-05, LATE_EMERGENCE_FROZEN.md §4 +
  live_takeover_catalog.csv):** all real-time confirmed body-node takeovers (3rd consecutive
  rank-1 capture of a >=3 run; NO 16:00 condition) across the full 182-day population:
  **82 events / 60 days (33%)**; 16 days >=2 events; S11's 14 days hold only 8 of them.
  Each event reprices the centered 20W fly from its confirmation bar (pre-11:30 events from
  pre-11:30 pool bars — first build bug: all repriced from 11:30, 03-13 shown $3.15/5.4pt
  instead of $1.50/49.5pt; corrected, `reprice_bar` column prints the bar). Categories:
  **A pre-arrival (prospective entry) 25: 100% reach +45/+50, med close 2.13x, p25 0.38**
  (bimodal: many 2-5x + several total losses; robust to dropping 5 sub-$2 events 21/21);
  B near-body 42 (52%); C post-11:30 45 (42%); C2 17 (53%); D after-45 20 (45%). Strata:
  pre-11:30 36/38 + 1.74x med; 11:30-13:30 8/17 + **0.13x med** (worst); >13:30 10/27 + 0.84x.
  LE-S11 events: med 1.47x, p25 1.00 (no sub-1.0 close) vs non-S11 1.03x/0.15. Anchors:
  03-13 (10:40, $1.50 -> +45 @10:46, +50 @10:47, peak 5.82x, close 2.03x); 08-14 (12:10,
  $7.28 -> +45 @13:36, close 1.49x). All timestamps minutes-since-midnight; HHMM display
  only (PM mandate after the HHMM-vs-minutes bug class).
- **Revision 3 (my spec defect, caught by my own verification):** `late_emergence` originally
  gated at first rank-1 > 11:30, which mislabeled A1 days emerging in (10:10, 11:30] and ending
  dominant (fell to TRANSIENT). Boundary = after the open window (>1010). 9/3 unaffected.
- **View state note (D5, resolved):** the `gamma_research_active` catalog was redefined mid-task
  by the concurrent data-catalog session (16:05; api-1.0 schema, 26 cols, `underlying='SPX'
  AND is_flat=false` filters, 759,054 rows; 9/3's four pre-open no-spot rows no longer in view,
  same 39 spot captures + identical gamma values). The deliverable was built AFTER the rebuild
  and fully re-verified against the current state: exact-algorithm parity 182/182 × 8 fields,
  0 mismatches. `UW_903_RECONSTRUCTION.md`'s 43-row table (pre-rebuild view) remains valid for
  the 39 spot rows; the 4 pre-open rows are substrate-only.
- **Environment:** qwen-coder handled all 3 build revisions cleanly; its V5 anchor (111/111)
  passed. My independent parity script (`/tmp/verify_path_parity.py`, untracked scratch) —
  note: my first attempt had 4 bugs of its own (HHMM-vs-minutes threshold, spot filter, tie
  handling, groupby-apply iteration); the committed evidence is the fixed exact-replica.

## Session closeout (2026-09-05, maintenance shutdown)

**Commit train this segment (all pushed, Agent-Print present):** `8335cb39` (LE frozen +
14-day inspection) → `56c72290` (PM correction round 1: 03-13 LEAD, distances, 3/10/1) →
`4138bdce` (confirmation-as-actionable 2/11/1 + 182-day live catalog + pre-entry repricing fix).
Deliverables: `LATE_EMERGENCE_FROZEN.md` (§4 live catalog, §7 correction log items 1–5, §6
protocol logs both timestamps + catalog fields), `late_emergence_14_inspection.csv` (dual
timestamps), `live_takeover_catalog.csv` (82 events × 33 fields).

**Open / next session:**
1. **Forward accumulation** is the standing task: per-day logging begins (S11 state +
   confirmation/start timestamps + confirmation-time strata + dist_1130 + band + mid
   attainment + catalog fields + frozen runner separately). The catalog says the interesting
   question is confirmation-time strata + category A (pre-arrival) recurrence, not the S11
   rate itself.
2. **02-11 source-divergence audit** (flagged, not urgent): nearest25 book-era path vs current
   raw pool disagree mid-afternoon (first 1.45× 14:55 vs 13:35; same 15:55 exit 2.4698×);
   other book days match exactly.
3. **2 untracked leftover files** in `analysis/sml_fly_verify/adjudication/`
   (`final_pnl_extract.py`, `verify_bsm.py`) — scope deviation to commit or remove.
4. Category A (pre-arrival, 25 events, 100% reach +45/+50, bimodal closes) is the strongest
   live-event cell so far — n=25 is still small and the p25 0.38× left tail is real;
   accumulation should track it explicitly (it is a pre-entry, not hold/add, category).

**Standing facts for re-entry:** registration frozen at `feaceb12`; S11 definition frozen
(change = new label); no runner-policy override from LE state (PM); mid convention governs;
minutes-since-midnight discipline for all time comparisons (bug class bit twice:
HHMM-vs-minutes, then 11:30-path reprice); anchors 03-13 + 08-14; scratch scripts
(`/tmp/le_events.py`, `/tmp/le_catalog.py`, `/tmp/fly_path_full.parquet`) are untracked and
regenerable.
