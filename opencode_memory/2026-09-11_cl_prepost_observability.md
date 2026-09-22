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

## Detection latency, Apr 7 burst (operator-approved canonical, 2026-09-11, commit 23a02da2)

Corrected latencies (per-second A2 trigger at 19:45:50, front 5-min rolling |A−B| ≥ 1,100 with
A/(A+B) ≥ 0.6): **50 s from reported window open (19:45:00); ≈72–80 s from earliest observed
selling (19:44:30–38); same grid interval from the 182-lot execution (19:45:49)**. Trigger was
rolling net-selling (|A−B| = 1,164, dom 92.7%), not cumulative A-side alone; pre-window 5m |net|
was 96 (normal). 182-lot print consistent in size with reported ~150-lot order; identity not
establishable. Canonical wording banked: LOOSE-setting per-second monitor = sub-minute detection
(50 s from window open), USEFUL not cleared. Full table in ADJUDICATION.md.

## CL unusual-flow monitor — design spec v1.0 banked (2026-09-11, commit c1034ab6)

`studies/cl_unusual_flow_monitor/idea.md` — revised draft, freeze ruling pending. Objective:
notify on off-scale bursts of the Apr 7 type, ranked by unusualness. Channels: LOOSE =
rate-limited low-priority flag; USEFUL = high-priority push; STRONG = push + auto
event-study pin. Key architecture: signals S1 |A−B| net flow (dual gates max(A,B)/(A+B)≥0.6
AND (A+B)/(A+B+N)≥0.6, direction a label) / S2 gross (60s+5min) / S3 S-class / S4 print size
(empirical, no z) / S5 rate; ranking = level > empirical q > exceedance tag (value/baseline_max,
labeled exceedance NOT percentile); duration reported, never multiplied; calibration on the
UNION of merged episodes (≤1/session, ≤1/5, ≤1/20); baselines per TOD × catalyst regime
(R1 EIA / R2 other scheduled / R3 ordinary) × roll state; front frozen at session open (5
completed sessions, no lookahead), dual-track at roll, roll = tagged + roll-matched baseline
(no demotion); feed gaps on transport evidence only; exchange calendar per-date TZ (CME halt
04–05 UTC CDT / 03–04 UTC CST — never hard-coded); E3 negative case = no monitor-level USEFUL
episode (not per-stat LOOSE); P0 replay calibration on cl_tick_v1 → P1 shadow (live, no alerts,
after TBBO-vs-MBP-1 field-parity proof) → P2 live. Cost: unresolved pending plan/licensing/terms.

## Successor: CL unusual-flow monitor — spec FROZEN v1.0 (2026-09-11, commit 12b5f3ea)

`/data/agentic_trading/studies/cl_unusual_flow_monitor/idea.md` — FROZEN per operator ruling.
Ranked all-session detector for off-scale CL flow (Apr 7 class), direction-agnostic (G1
max(A,B)/(A+B) ≥ 0.6 + G2 (A+B)/(A+B+N) ≥ 0.6; direction = SELL if A>B else BUY). Signals S1–S5
(each with own gate); baselines = 60-day same-TOD × catalyst regime (R1 EIA/R2 scheduled/R3
ordinary) × roll state; rank key = level → q → exceedance (E = value/baseline_max, above-max
labeled, no inferred percentiles; no persistence or consistency multipliers); LOOSE/USEFUL/
STRONG calibrated on the UNION of merged episodes (≤1/session, ≤1/5, ≤1/20); front frozen at
session open from prior 5 completed sessions, dual-track across rolls (no look-ahead, no
automatic demotion — roll-matched baseline instead); feed gaps only on transport evidence;
CME calendar with per-date TZ (no hard-coded UTC halt). Notifications: LOOSE = rate-limited
desktop flag; USEFUL = push; STRONG = push + automatic event-study pin. Cost UNRESOLVED
(excluded from freeze). E2 trigger pinned from raw data: 5-min (19:40:50,19:45:50] A=1826
B=662 N=197, |A-B|=1164, G1=0.734, G2=0.927; 182-lot print @19:45:49 verified in-window
(S4 anchor). E3 acceptance = no monitor-level USEFUL (individual floors not pre-declared).
Live-parity gate (TBBO vs live MBP-1 field-level) before P1. **P0 authorized** (no new
funding): anchors + union thresholds + false-alert burden + replay acceptance on cl_tick_v1,
before any live build.

## P0 rolling calibration: built, dry-run STOPPED on a data fact (2026-09-13, commit 25aa37c1)

P0 (replay calibration) went through: bounce-#1 (union calibration never ran) → bounce-#2
(nested floors + self-checks, 13/13 acceptance, verified — core preserved as
`scripts/p0_replay_calibration.py.bak`, md5 23479cdb) → bounce-#3 (delegate "caching
optimization" CORRUPTED the stat engine; preserved as `.broken3`, never build on it) →
qwen-coder :8081 aborted 4× → build sent to **qwen38-collab :8011** after the envelope was
red-team reviewed by **qwen38-reviewer :8012** (verdict GO-WITH-AMENDMENTS; 8 amendments:
S4 monotonicity DISPROVEN under gap-merge — a removed bridging second splits a cluster, so
ascending scan over distinct in-window values, never binary search; warm-start ratchet hole
→ bidirectional search; baseline look-ahead → per-day causal baselines; one pinned
cross-stat merged-union definition + golden bridging vector; vectorized union count;
determinism spec; inherited deviations documented).

**Phase-0 dry-run gate STOPPED the build (exit 3, verified in verify/clp0_phase0.*):**
under causal rolling-60 floors (window 2026-01-08→04-06), the Apr 7 19:45:50 burst is NOT
an episode at any level — all 7 stats below that day's LOOSE floor (S1-5min 1160<1952,
S1-30s 1156<1342, S2-60s 1776<6439, S2-5min 2673<14522, S3-60s 3574<19340, S4 182<2849,
S5 4114<10379; max ratio 0.59). E3 (04-17) = 0 USEFUL+ (holds). **Data fact: a
burden-budget-calibrated (≤1/1, ≤1/5, ≤1/20) causal monitor does not alert on the Apr 7
19:45 burst** — the earlier "STRONG under calibrated floors" claim was an artifact of the
FIXED-window floors, which were sub-budget (LOOSE 61/60, S1-30s floor 750); the causal
floors that hit the budget sit at S1-30s 1342 and drop it. Second data fact: USEFUL ≤12 is
INFEASIBLE on the 04-07 window (union bottoms at 13 with S4 maxed).

Grid vs real-time convention (red-team hand verification): grid [t−300,t) = 1818/658/197,
|A−B| 1160, G1 0.7342, G2 0.9263; operator real-time (t−300.5,t+0.5] = 1826/662/197, 1164.
Self-tests pin grid values. S3 pins exact on grid: 8231 @18:28:21, 8203 @18:55:35.

OPEN operator rulings (P0 cannot bank past Phase 0 until resolved):
1. E2 acceptance line: (a) accept "monitor misses Apr 7" as a tested, banked property;
   (b) add an absolute-scale tier independent of the relative budget (8,231 lots/60s is
   off-scale absolutely); (c) loosen the LOOSE budget (runs pinned at 60/60d — saturated).
2. Per-day UNMET on infeasible windows: documented non-blocking, or budget 12→13.
My recommendation was (1a)+(1b) as separate tiers and (2a); operator has not ruled.

Banked: 25aa37c1 (build script + verified core .bak + phase0_gate_stop.md + receipts;
517 MB replay_persecond/ gitignored as regeneratable). Frozen spec: 12b5f3ea.

## Two-lane monitor: spec v1.1 DRAFT banked (2026-09-13, commit afe87e44)

Operator confirmed the finding is a monitor-calibration issue, not data access (feed is
sufficient — all pins verified). Advisor's two-lane design adopted: Lane 1 = relative
anomaly (frozen, its E2 acceptance rewritten to PIN the miss — "relative lane misses
Apr 7" becomes a tested property); Lane 2 = material flow, absolute thresholds (M1:
S1-30s |A-B| with G1/G2 gate, test point 1,156 grid SELL; M2: S3-60s gross, 8,231; M3:
S4 per-print 182, droppable), thresholds chosen by full-pool burden replay INCLUDING
autumn-2025 regime (operator picks tolerable burden; test points are starting values,
not contracts), MATERIAL/EXTREME levels, independent of the rarity budget. No new data
access — Phase-1 arrays suffice; one small build cycle. Open freeze items: per-day
UNMET (USEFUL-13) treatment, M3 in/out, EXTREME burden target, Lane-2 channels.

## Two-lane monitor: spec v1.1 DRAFT banked (2026-09-13, commit afe87e44)

Operator question "monitor or data access?" — committed answer: **the monitor (calibration),
not data access** (pool captured all Apr 7 activity; pins verified). Advisor review adopted
with one number correction: 1,156 = 30-s GRID |A−B| (real-time 30-s = 1,043; 5-min = 1,160
grid / 1,164 real-time).

Spec §15 (v1.1 DRAFT, pending freeze ruling): Lane 1 (relative anomaly, frozen S1-S5 +
rolling-60 budget) unchanged — acceptance (a) rewritten to PIN the data fact that the
relative lane misses Apr 7 (value/floor table as pin). Lane 2 (material flow): absolute
thresholds independent of the rarity budget — M1 S1-30s |A−B| with G1/G2 concentration gate
(test point 1,156, SELL), M2 S3-60s gross (8,231), M3 S4 per-print (182, droppable);
thresholds selected by full-pool burden replay INCLUDING autumn-2025 regime (test points ×
{0.5…2.0} are starting values, not contracts); MATERIAL (push) + EXTREME (push + auto
event-study pin, ≤1/quarter proposed) levels; lanes independent, higher tier wins on
overlap. No new data access — Phase-1 arrays suffice. Build = one small cycle (burden
curves + threshold selection + Lane-2 artifacts).

Open freeze items: (1) Lane-1 per-day UNMET on infeasible windows (USEFUL-12 bottoms at 13
on 04-07 window) — doc-only vs budget 13; (2) M3 in/out; (3) EXTREME burden target; (4)
Lane-2 channels. NOTE: my push of afe87e44 also shipped another seat's local commits
(355999d1 et al.) that sat unpushed on shared master.

## Lane-1 full rolling build: FROZEN spec -> mechanism fix -> timeout -> OPTIMIZED + VERIFIED (2026-09-14/15)

Spec v1.1 FROZEN (cebcfb0c) with operator rulings. Lane-2 burden build (4e7f4aef; ST2
adjudication: duckdb `::BIGINT` epoch cast rounds to nearest second, not floor — 1,156
grid pin valid). Lane-2 thresholds FROZEN (b6ccd563): M1=1,043 / M2=24,693 (raised from
16,462 by the combined-union gate: M1+M2 union 39/248 sessions = 15.73% <= 20% PASS);
M3 OUT; EXTREME off-diagonal 2,400/32,700.

Lane-1 rolling build authorized (0c83e6ac). The 27-hour hang (PID 3474782) CLOSED as
external (contention/one-off): same script+pool completes ~3 min quiet (receipt
e07c65bc); residual in-script defect = concurrency-unsafe startup stale-cleanup (fix
mission spec'd, pending approval).

**Pin adjudication (cf0569a1, :8012 read-only card): VERDICT B** — search is
seed-dependent (not a window function); WARM (rolling) vector VIOLATES the USEFUL budget
(18 > 12) and is a locally-stuck infeasible fixed point; two mechanism defects proven
(hill_climb stops at first feasible point; UNMET kept the stuck floor instead of
strictest+flag). Operator ruling A: keep banked pin as contract + mechanism fix.
Causal-satisfiability correction: the old banked 21 values are UNREACHABLE from causal
seeds. **Pin provenance ruling (2026-09-15)**: acceptance pin must not originate from
the implementation state it tests -> `ADJUDICATED_0407` = literal from the independent
adjudication transcript (verify/lane1_pin_adjudication.20260914.txt, sha256
726a9e5d...). Mechanism fix + pin + **§15.9 SELECTION RULE FROZEN** (two independent
paths per window; post-nesting feasibility; both->backstop, backstop-only->backstop,
primary-only->primary, neither->UNMET strictest+flag; no carry-forward) = commit
5a53fe3f.

**--full verification run TIMED OUT** (exit 124 at 15:00, 120/188 days; environmental
1.6-2.2x slowdown, two catalog jobs) — reported per operator instruction (no pin/floor/
selection/criteria changes). Deposit verify/lane1_full_final.20260914T211618Z.txt.

**RUNTIME OPTIMIZATION COMPLETE (2026-09-15, commit d879c66a, pi seat)** — operator
authorized the optimization + the single deposited --full. Profile first (mandated):
bottleneck = s4_sweep CPU (88% of search), NOT parquet I/O (496 reads = ~20s); per-day
3.36s (quiet baseline from lane1_full_fixed deposit). Changes (all equivalence-proven,
semantics frozen): (1) s4_sweep vectorized — monotone-stack pred/succ -> sparse-table
range-max binary descent (suffix-max prefilter, -1-padded sentinels; pred = mirror on
reversed array, non-strict) + K x 60 batch pointer loop -> per-second three-term delta
reduced by np.bincount over ranks; 3.28x worst-window, bit-identical (distinct, C)
(60 random multi-day trials + 6 edges + 20k-element stack differential + frozen
self-test); the first vectorization attempt (jump-pointer doubling) was WRONG (chain
heads don't compose under doubling) — caught by the differential before any run.
(2) full_load_once: single pass over the 248 parquets (day derivation + store in one
read; 496->248 reads); 5208/5208 store arrays verified equal to two-pass.
(3) union_count_ws memoized per (id(vs), floor tuple) — build_window clears it (CPython
id reuse of a dead vs list); EVAL_COUNTER lock-protected (deterministic total; the
report's day-10 eval count is a call count, unchanged by memoization).
(4) search_day backstop in a worker thread (pure function of (win, INITIAL_FLOORS);
join before the unchanged §15.9 merge). Equivalence driver (90 scoring days
2025-12-05->2026-04-17, old vs new module): ALL IDENTICAL — starts/nested/postnest/met/
per_level/c_day/episodes + all 516 s4 C-arrays. **--full: exit 0, 50/50 acceptance
(12 grid pins + a1-d3b + abn1-2 + E2 zero-episode/all-7-below-LOOSE + E3 zero USEFUL+
04-17 + 21/21 ADJUDICATED_0407), 342s (was ~13 min quiet / 15:00 timeout contended);
verify-run auto determinism re-run 343s, all 4 output files BYTE-IDENTICAL** (receipts
verify/lane1_full_opt.20260914T223100Z.txt + lane1_full_opt_determinism.20260914T223656Z.txt).
Canonical outputs committed (lane1_rolling_{floors,burden,top10}.csv + report.md —
true outputs of the committed code; the 20:45 untracked outputs were the delegate's
fixed_v2 iteration, whose day-10 eval count 51,185 differs from the committed code's
39,636/10d — code-version difference, not a regression).

Open: (1) cleanup-fix mission (flock + scoped startup cleanup for the stale-cleanup
defect) spec'd, awaiting approval; (2) P1 shadow run (live-parity gate: TBBO vs MBP-1
field equivalence; Lane-1 grid-vs-real-time reconciliation); (3) cost question (Databento
plan + CME licensing for live GLBX.MDP3 + IFEU); (4) IFEU definition pull ($77) if
funded.

## 2026-09-16 — cost-gate correction, concurrency fix applied, shadow-run scope DRAFT

**Cost-gate correction (operator challenge, settled).** The "Databento plan + CME
licensing gate" was STALE for the monitor's core. What is actually running:
- `cl_tick_ingest.timer` — daily 21:00 UTC T-1 ingest of TBBO CL.FUT + LO.OPT
  from Databento GLBX.MDP3 -> `/data/parquet/cl_tick_v1` (the monitor's pool;
  verified current: last run 09-15 21:05 OK, next 09-16 21:00; latest
  partition ingest_utc_date=2026-09-14 = T-1 semantics).
- `cl_tick_live.service` — continuous live TBBO CL_FUT + LO_OPT ->
  `/data/parquet/cl_tick_live_v1` (best-effort; gaps recorded in
  `cl_tick_live_v1/gaps/`; live bytes never enter frozen study tables,
  INV-L3/L7). Verified streaming same-day (15:49 UTC flushes).
- Entitlements (09-09 card): CL futures trades+MBO, CL options
  trades/mbp-1/ohlcv all OK. Genuinely unresolved cost items are EXTENSIONS
  only: CL options MBO (L3; the one real entitlement denial), ICE Brent/IFEU
  (separate venue; ~$4.9k/$20.9k one-shot quotes), deep historical MBO
  (402 = per-request budget cap, not entitlement).
- Consequence: the binding constraint on going live is the P1 shadow run
  (engineering), not money. And the pool grows nightly, so the calibration
  is a living object: ingest -> 5.7-min --full rebuild keeps floors causally
  current with zero manual work.

**Concurrency fix APPLIED (PM-approved), commit e31bcd9f.** The default-path
startup cleanup deleted EVERY outputs/ entry except catalyst_calendar.csv
(wiped Lane-1/Lane-2 artifacts + phase0_gate_stop.md twice, restored from
git both times) and there was no instance lock. Fix in
`scripts/p0_replay_calibration.py` (frozen region 88-273 untouched; gate
PASS):
- `acquire_run_lock()`: non-blocking exclusive flock on
  `studies/cl_unusual_flow_monitor/.run.lock` (OUTSIDE outputs/ so no
  cleanup can touch it; gitignored). Holder pid+start written for
  observability; second instance exits 2 with holder identity; kernel
  releases on death -> no stale-lock mode. Wired into `__main__` before
  lane1_full()/main() dispatch.
- `stale_cleanup()` + `STALE_RUN_ARTIFACTS` closed list (11 names:
  rolling_floors/episodes_rolling/burden_rolling/false_alert_burden/
  episodes_all/floor_table/.run_fingerprint/acceptance_report/
  calibration_report/day10_checkpoint_stop/phase0_gate_stop): only this
  run's own artifacts are removed; everything else preserved.
  `replay_persecond/` is NOT wiped (fixed 248-day range = deterministic
  per-day in-place overwrite; the --full input is never destroyed mid-run).
- `import shutil` removed (now unused); report line updated to the scoped
  description.
Verification: unit lock test (holder/challenger exit 2/post-death re-acquire
OK); cleanup-scope fixture (11/11 stale removed, 10/10 sentinels +
replay_persecond preserved); REAL contention (second --full during first:
exit 2, deposit verify/lane1_lock_contention.20260916T163912Z.txt); two
deposited --full runs (verify/lane1_full_lockfix.20260916T163902Z.txt 323s
+ lane1_full_lockfix_determinism.20260916T170409Z.txt 322s), both exit 0
50/50, all 4 outputs BYTE-IDENTICAL to the committed canonical (d879c66a)
— cross-version identity, stronger than run-to-run.

**P1 shadow-run scope — DRAFT §15.10 banked in idea.md (same commit), AWAITING
PM RATIFICATION (nothing built).** Focus per operator: objectives / runtime
strategy / success-failure metrics.
- Objectives: (1) §11 live-parity gate (archive-TBBO vs live-TBBO field
  equivalence + TBBO-vs-component-streams cross-check; binding, no P1
  scoring without it); (2) grid-vs-real-time reconciliation (§15.2a/§15.8;
  M1 Apr-7 1,043 real-time vs 1,156 grid is the known instance); (3)
  out-of-sample burden observation vs frozen budgets (LOOSE 1/session,
  USEFUL 1/5, STRONG 1/20; notifications suppressed, telemetry+EOD rank
  only); (4) production feed-integrity (gap frequency + INV-L3/L7 repair
  loop).
- Runtime: two existing pools (cl_tick_live_v1 live best-effort +
  cl_tick_v1 T-1 authoritative; overlap ~3-4 trading days, +1/night; no new
  data acquisition). Stage A = offline parity + dual-convention scoring on
  the overlap (read-only, completes now, gates B). Stage B = nightly batch
  shadow after T-1 ingest (proposed 21:30 UTC): causal floor refresh ->
  score both lanes -> §15.9 merge -> telemetry+EOD rank to outputs/shadow/,
  channels suppressed. Duration proposed >=40 trading days.
- Metrics: Gate 1 parity (trade rows 100% on intersection; quote rows
  >=99.9% with every mismatch inside a recorded gap window; mapping 100%;
  ns precision 100%; FAIL = any unexplained mismatch -> no P1 start).
  Gate 2 grid-vs-real-time (corpus pins reproduce real-time; USEFUL+ set
  equality across conventions; material delta = PM decision point, never a
  silent adjustment). Gate 3 burden (realized <= budgets; sustained breach
  >=5 consecutive days = FAIL signal -> PM: accept/re-anchor/amend).
  Standing daily: exit 0, causal truncation checks, byte-identical
  re-score, zero notification leakage.
- Open questions for PM: Q1 batch-on-T-1 vs real-time socket shadow
  (proposed: batch; real-time latency is a P2 concern); Q2 floor refresh =
  5.7-min full rebuild (proposed) vs incremental day-append (new code, own
  spec+proof); Q3 auto-pause on sustained breach vs PM-review-only;
  Q4 horizon (proposed >=40 trading days); Q5 Gate-1 parity-day count
  (proposed 5 incl. >=1 roll day).

**Governance ruling (PM, 2026-09-16): the flow monitor does NOT use the
research_agent apparatus.** The PM asked whether the flow monitor's intent
follows the semantic objectives of the research_agent idea.md template
(`/data/research_agent/prompts/idea.template.md` + transport `prompts/idea.md`,
which governs `/data/research_agent/studies/<study>/idea.md` gate artifacts).
Answer settled: NO — the template's semantic objective is hypothesis-driven
research (open question -> candidate causal/economic explanation -> material
alternatives A1.. with distinguishing observables -> decision-relevance
thresholds; §3 is the core and cannot be stubbed). The flow monitor is a
contract-verification / instrument-conformance program: its semantics were
fixed by two months of operator adjudication (FROZEN spec v1.0 + §15.7–15.9),
and the P1 shadow run's outcome changes beliefs about the INSTRUMENT (parity,
out-of-sample burden, convention fidelity), not about the market. Its "idea
phase" was already performed by the frozen monitor spec itself. Consequence:
the P1 shadow-run scope stays in `studies/cl_unusual_flow_monitor/idea.md`
§15.10 as its single home (DRAFT, awaiting PM ratification, Q1–Q5 open); do
NOT create a `/data/research_agent/studies/` entry or a grounding receipt for
it, and do not re-propose the research_agent machinery for any flow-monitor
phase. (The research_agent machinery remains the right form for genuinely
open research questions, e.g. the SPX/gamma studies.)

**2026-09-16 (later): scope RATIFIED + 8011 review instructed + maintenance
restart.** PM ratified the §15.10 scope (commit 6178d348, pushed); Q1–Q5
remain open. PM then instructed: send Q1–Q5 to the 8011 seat (pi agent
`qwen38-collab`) for A/B + COT reasoning + recommendations → deliverable
`studies/cl_unusual_flow_monitor/outputs/shadow_q1q5_8011_review.md`. The
dispatch was NOT fired — workstation restart for maintenance pre-empted it
(firing a multi-minute delegation seconds before a restart risks an orphaned
half-run). **Resumption brief: `/data/agentic_trading/RESUME_2026-09-16.md`
(commit a9b97472, pushed)** — contains the full dispatch envelope verbatim,
verification commands, standing orders, and the resumption protocol. On
resumption: fire the dispatch, verify, report the five recommendations to the
PM. Shadow build stays gated on the Q1–Q5 rulings (and a separate PM go for
the build itself).
