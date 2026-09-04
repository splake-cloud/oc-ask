# 2026-09-03 — SPX 0DTE fly gamma-topology → opportunity map + ranked ledger (discovery)

**Committed + pushed** (`e586c382` Phase-0 substrate, `bbf0ee2f` Phase-1 ledger; Agent-Print:
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
- **9/3 reconstruction (descriptive only):** 7750 unremarkable at open (rank 9-12, ~300 gamma), first
  LARGEST dealer-long node 09:40 (SPX 35 pts away), lapsed rank 2-7 during the 10:00-11:00 dip (7694),
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
- **9/3's signature (A1_EMERGENT) RECURS: 2026-03-13 + 2026-05-01 (2/111) + 9/3 (worked example) = 3.**
  **ALL THREE LOSE (−0.5)**: the fly touches LATE (~13:30, ~2h after entry), deepens below the entry
  (min fly_mult 0.60/0.33/0.99), and trips the 1.0D floor BEFORE the 2.5D target — even though it
  recovers in value (max_fly ~2.2–2.7). So the impulse-to-dominant-node pin is a real recurring state
  but a LOSING one as traded (2.5D-vs-1.0D first-passage).
- **The "expensive fly that monetizes cleanly" hypothesis is REFUTED**: the aligned EXPENSIVE flies
  (b28_32+gt32, 7 days) NEVER hit the 2.5D target (0/7); the aligned cheap (le28, 5) hit it 2/5. Across
  the book, >32 is the WORST monetizer (2.5D hit 1/34), le28 the best (22/60) — premium and clean
  monetization are NEGATIVELY related.
- Catalog-size (A1 n=3, aligned n=12, aligned-expensive n=7): descriptive, not a test. All A1 are
  all_expiry; no 0dte A1 yet. 9/3 is a raw reconstruction (P&L book ends 8/31); its −0.5 inferred from
  the 11:32 floor (fly_mult 0.992) preceding the later 2.5× touch.
- Files: `cohort_alignment.parquet` (111×35), `cohort_map_builder.py`, `verify_cohort.py`,
  `COHORT_MAP_ENVELOPE.md`, `COHORT_ALIGNMENT_REPORT.md`. No registration/live change.
