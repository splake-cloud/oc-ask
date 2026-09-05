# 2026-09-04 — SPX 0DTE put fly: when is a loser unlikely to turn around (MAE / cut study)

**Session ID:** `01a06d8f-6e98-712a-b5bf-4ad157ff5c45` (pi seat, qwen3.8-27b-fp8) ·
**Status at close:** all 5 phases + repeatable-setup verdict complete, artifacts committed
(`2bf7be57`, `e729c983`), study consolidated in `studies/0dte_fly/`; PM rebooted for
maintenance — see "Resume on reboot" section at the bottom of this card.

**Mission (PM):** statistically, when does a losing daily butterfly (0DTE put fly) stop being likely to
recover? "First cut is simply a distribution of losses that shows probability of recovery." Data-read
exercise, not a build. Pi seat, qwen3.8-27b-fp8.

## PM rulings (this session)

1. **Far-OTM legs on expiry day are marked 0.** Vendor quotes there are derived values, not market
   values (don't reflect order-book depth). **Max loss is limited to the debit paid** → structure mark
   floored at 0. (Red flag raised by PM: my first two passes marked the body back at ASK with dead
   wings at 0, producing return < -100% "losses" — decomposition artifact, refuted.)
2. **First-pass mark = mid** on all legs (`GREATEST(lower_mid + upper_mid - 2*body_mid, 0)`, dead leg
   bid&ask=0 contributes 0, body mid NULL excludes bar). **PM will impute the bid/ask spread later** —
   this pass deliberately bakes no spread in.

## Data source (PM red flag, corrected)

- **Do NOT use `outputs/fly_trades_nearest25.parquet` / `fly_paths_nearest25.parquet`** — legacy
  builder outputs, stale (last bar 2026-08-05). RAG card is explicit: *"Read the SQLMesh model, not
  the legacy parquet output."*
- Canonical: `/data/warehouse/warehouse.duckdb` → `warehouse.warehouse.fly_trades` (17,271 rows) /
  `warehouse.warehouse.fly_paths` (2,658,751 rows), `body_selection_method='nearest_25'` = 8,635
  trades, 2021-05-14 → 2026-09-03, daily accrual. (Ambiguity: catalog `warehouse` + schema
  `warehouse` — qualify 3-part; attach-as-other-name breaks the `warehouse` schema lookup.)

## Results (mid mark, dead legs 0, floor 0; nearest_25, 8,635 trades)

- Hit rates: first +50% touch **46.2%** (mid mark) vs **34.9%** canonical liquidation label —
  mid mark is easier; spread imputation expected to tighten toward canonical.
- **Turn-around is a late-day event.** Median first +50% hit **15:26** (p25 15:00, p75 15:45);
  10.3% of hits by 14:30, 25.1% by 15:00, 75.8% by 15:45.
- **Recovery curve** P(reach +50 | mark first touched L): −15: 42.0%, −20: 39.6%, −25: 37.0%,
  −30: 34.5%, −40: 30.3%, −50: 26.1%, −60: 22.6%, −75: 18.6%, −90: 15.5%, −100: 16.0%.
  **Flattens below −75%** — depth stops being informative; a trade marked zero still ends +50 in 1 of 6.
  P(ever back to breakeven): 87% (at −15) → 67.5% (marked zero).
- **EV cut vs hold** (hold terminal = 15:55 mark or +50 if hit first):
  - First-touch basis (state = first time mark reached L, all times mixed): holding ≥ cutting at
    EVERY level (gap −0.9 at −15 → −29.2 at −100). This is the "early cutting freezes losses" side.
  - Same-clock basis (state = mark at time t — the live decision):
    - ≤11:45: hold wins everywhere.
    - 12:00–13:00: cut +EV at −10…−50; −75 still hold.
    - ≥13:30: cut +EV at every level −10…−75, gap widens with the clock (up to +43 at −10 by 15:45).
    - −100 floor row: "hold" on paper is a dead-legs-re-quote-at-15:55 floor bounce (artifact);
      treat marked-zero as binary dead/alive.
  - P_hit at −50 by clock: 26% (12:30) → 16% (13:30) → 13% (14:30) → 12% (15:00) → 10% (15:30).
- **Bottom line:** it's a *time* question, not a *depth* question. "Statistically unlikely to turn
  around" ≈ **after ~13:30 with mark below ~−30%** (P_hit < 26%, EV_hold < −50); after 15:00 cut
  any loss down to −75. The turnaround window IS the last hour.

## Phase 2 (same session): competing-policy simulation — immediate cut vs hold-to-close vs time-decaying salvage

> **CORRECTED in Phase 3:** the "+2.7 D" headline below was a credit-convention artifact — P0 was
> credited a flat +50 at the target while P3 credited the crossing bar's mark (which averages
> ≈ +60…+80). Under a consistent convention the honest mid-mark edge is +0.1…+0.3 D, and the
> spread ruling removes it. Phase 2's structural findings (channel decomposition, hard-stop harm,
> later-step-better ordering, bounce-back rates) all survive.

**PM hypothesis:** the breakeven-recovery gap (68–87% of touched losers revisit breakeven vs 16–42% reach +50)
means a third policy may dominate both binary extremes: don't crystallize early adverse marks; after a touch,
exit on recovery near scratch; tighten the recovery exit as the session progresses; stop demanding +50 once its
probability has collapsed.

**Policies** (all take +50 whenever it comes first; differ only in loser management after first touch of −L;
mid mark, dead legs 0, floor 0, nearest_25):
- P0 = hold to 15:55 (study rule) · P1 = cut at touch · P3 = salvage: keep demanding +50 until 15:30,
  then exit at 0 (scratch) 15:30–15:45, then at −10 after 15:45, else 15:55 (best variant = "B3").

**Full book (8,635), mean % of debit:** P0 −7.78 | P1 −10.6/−10.8/−11.2 (L=−30/−50/−75) |
P3_B3 −4.80/−4.96/−5.03/−5.26/−5.83 (L=−20/−25/−30/−40/−50). **P3 dominates both extremes everywhere**
(+2.0…+3.0 D vs P0; +5.5…+6.4 D vs P1). Loser subpopulation: at −50 touch (4,587): P1 −56.4, P0 −50.8,
P3 −47.4 (median exit −68 → the salvage channel carries it).

**Decomposition (−30 touch, P3):** target channel 5.6% of losers (mean +81), **salvage channel 51.9%**
(mean +6.2, median exit 15:21), close channel 42.5% (mean −85). The gap IS the policy.

**Sub-findings:**
1. **Hard stop DESTROYS the policy** — a −85 stop costs −6.2 D (L=−30) to −12.5 D (L=−75) vs no stop:
   floor-marked trades revisit scratch ~2/3 of the time. "Do not crystallize early adverse marks" is
   quantified, even at −85.
2. **Step timing beats target-reduction**: 50/0/−10 @1530/1545 > @1500/1530 > gradual 50→25→0→−10.
   Lowering the target to +25 does NOT beat keeping +50 until 15:30 then taking scratch.
3. Trigger level insensitive: L ∈ −20…−50 all in the −4.8…−5.8 band; earlier marginally better.
4. Robustness: Δ vs P0 positive in all 3 periods (A +3.74, B +1.04, C +3.15) and all 7 checkpoints
   (+1.67…+4.64; biggest at 13:30+ — less time left to target, salvage engages more).
5. Risk profile: P3 keeps the full −100 tail (p10 −100 vs P1's −40…−90); it trades tail for EV. Floor
   rate barely moves (8.6% → 7.6%).

**Caveats:** mid mark (salvage rate at the floor may be inflated by dead-leg quote artifacts — spread
pass will compress it); unconditional pool; salvage exits near 15:45 execute against derived quotes on
potentially dead wings (execution-reality flag for the spread pass).

## Open / next

- **PM imputes bid/ask spread** → re-run the full matrix AND the whole policy grid (marks tighten;
  hit rate and loss levels move toward canonical; floor-level salvage rate likely compresses).
- Entry-conditioned policy grid (study's canonical hostile cells — expensive premium × low IV at 14:00+
  — shift P_hit and the salvage rate for those entries; all numbers here are the unconditional pool).
- nearest_5 arm not analyzed.
- `recovery_probability` stays hypothesis tier (LOW, unowned) in L3 unless PM formalizes a rule;
  the P3_B3 salvage rule is the natural candidate if PM wants a consumable management rule.
- L3 amended + committed (`804d2341`) recording the mark ruling; L4 evidence-archive note still to
  be written when the spread-imputed numbers land.

## Phase 3 (same session): PM spread ruling — $0.30 fixed package — policy re-run + adjudication

**Ruling (specified research assumption):** fixed $0.30 package bid/ask on the structure; executable
sell value = max(0, structure_mid − 0.15); recorded entry debit unadjusted (already actual); NO
constant-% deduction (effect is per-dollar: 15% of a $2 debit, 10% of a $3). All levels (+50,
scratch, −10, triggers) on the executable P&L scale M_t = 100·(exec_value_t/debit − 1).

**Adjudication: P3's edge does NOT survive.**
- Convention-check first (exit credited at bar mark, identical across policies):
  - MID:  P0 −3.82 | P1 −10.58/−9.27/−8.65 (L=−20/−30/−50) | P3 −3.71/−3.73 → Δ +0.11/+0.09
  - EXEC: P0 −6.45 | P1 −13.97/−12.84/−12.07 | P3 −6.65/−6.47 → Δ −0.19/−0.02
- Step grid (exec, L=−30) monotone in T1: 1515 → Δ −0.64…−0.77; 1530 → −0.18…−0.24;
  1545/1550 corner → −0.02…−0.05. Best cell (1545,1550,−10): Δ −0.02. Mid grid same shape:
  best +0.26 (1545,1550,−15). Spread cost to the best cell ≈ 0.30 D; break-even round-trip ≈ $0.28.
- Best exec cell by period: A +0.71, B −0.85, C +0.08 → sign-flips, not consumable.
- Channel decomposition (exec, L=−30 losers): target 13.0% mean +67.4 (med 15:09), salvage 40.4%
  mean +10.0 (med 15:33), close 46.6% mean −85.8. P3 −27.18 vs P0 −26.91 on the affected group.
- Bounce-back survives the spread (slightly compressed): P(revisit scratch | touch −30/−50/−75) =
  0.80/0.74/0.67; P(+50|touch) = 0.30/0.19/0.10. Zero-marked: P_be 0.616, P_hit 0.149.
- Hit rate: 44.2% exec vs 46.3% mid vs 34.9% canonical liquidation.
- P1 (immediate cut) decisively dead: −12.1…−14.0 vs P0 −6.45 (exec trigger fires deeper/more
  often because the exec mark sits below mid).

**Why the gap fails economically:** the salvage exit "at scratch" means M_mid ≥ D + 0.15 — the
revisit must climb the half-spread just to exit at breakeven. Revisit rate (67–80%) is real but its
monetization was only +0.1…+0.3 D before the spread; the 0.15 exit drag removes it.
**Verdict: P0 (first +50 else 15:55) remains the standing management rule.** The stable shape
ordering (demand +50 as long as possible, step down only at the last minutes) is preserved, and its
limit IS P0 — 15:30/15:45 was a point on a slope that flattens into the baseline, not a stable
optimum.

L3 updated + committed `4545b927` (spread ruling + verdict recorded in the PM Ruling section).

## Phase 3 open items

- Entry-conditioned policy grid (salvage value may differ in hostile cells — the pool here is
  unconditional).
- nearest_5 arm.
- If PM ever prices the actual 0DTE fly package round-trip below ~$0.25, the salvage policy
  breaks into marginal +EV — worth re-testing at that spread.

## Artifacts

- L3 addendum in `STUDY_SPX_0DTE_FLY_CANONICAL.md` §C ("PM Ruling — 2026-09-04"), commit `804d2341` (master, Agent-Print pi (qwen3.8-27b-fp8)).
- No files built (read-only exercise); all tables computed ad hoc from warehouse via duckdb
  (simulation is a pure-Python path loop over `warehouse.warehouse.fly_paths`, ~1.3M bars).
- L3 spread ruling + verdict: commit `4545b927` (master, Agent-Print pi (qwen3.8-27b-fp8)).

## Phase 4 (same day) — rulebook + decision card

PM asked what trading rules the numbers support, then scoped the actual practice:
entries at 11:30/12:30, premium < 30% of wing, ideally R3/R4; afternoon cells also in scope
(the current practice is what it is — not a filter).

**Full-pool re-cut on warehouse (nearest_25, entry_quoteable, 8,635 trades):**
- The practice quadrant (1130/1230, prem<30, R3/R4) = 978 trades, ~50–57% canonical hit vs
  34.9% full pool. R4 ≈ R3 there (1130: R4 48.2 > R3 43.8; 1230: R3 42–46 > R4 38–40).
- IV tercile boundaries stable across all checkpoints: body-IV low ≤ ~17, mid ≤ ~27, high above.
- Per-cell P0 expectancy (executable $0.30 marks): spans −0.9…+0.35 D; full book P0 = −0.33 D,
  median +1.02 D, hit 44.2%. Best cell 1230_20W×cheap×mid (+0.35 D, 64.5%, n=76).
  12:30×20W clearly beats 12:30×15W. 15:00 has NO +EV cell (best −0.15 D).
  P≥30×IV-low cells are the consistent losers (−4 to −18% of premium) = the hostile-cell set.
- Dollar EV is compressed vs hit-rate gaps (25 pp ≈ 0.5–1.5 D); median positive in 33/42 cells.

**Deliverable:** `studies/0dte_fly/SPX_0DTE_FLY_DECISION_CARD.md` (created under `docs/`,
moved to the study dir by PM, commit `2bf7be57`) — entry matrices (P<30 / P≥30 blocks ×
IV low/mid/high × 6 checkpoints → ENTER/HALF/NO with hit%), fixed exit protocol (first +50
cross of executable mark else 15:55; no stop, no salvage, no floor-liquidation), sizing
(1-in-12 full-premium tail), full 42-cell appendix. Content committed `38bee015`; L3 `premium_pct` source fix committed `ae9de0f2`. Session-level tier,
explicitly not a canonical finding. M3 mission deliverables (report, spec, scripts, outputs)
committed alongside in `studies/0dte_fly/` (`2bf7be57`).

**Regime split (PM, recorded in the card):** the box is split. Claude Code's spring study →
R3 best; recent local-model finding disputes. This session's data: R3 best of big-4 from 13:30
on (41.0 vs 31–36 at 1330; 23.7 vs 20–22 at 1500) but R4 wins 11:30 (48.2 vs 43.8) — so the
data supports "R3-best in the afternoon", is mixed in the morning, and keeps regime OUT of the
gates while the split is open. spans_both = consistently weak afternoon regime. Cross-agent
consensus lever: premium% of wing (direction-consistent 7/7 checkpoints).

**New open items:** formalize card as findings_update packet (per-period q's); entry-conditioned
management grid; live-drift check of the 17/27 IV thresholds; nearest_5; N-blocks on hostile
cells #1/#5 may already clear (warehouse has ~5 more months than the study sample).

## Phase 5 (same day) — repeatable-setup mission (full protocol)

PM mission: find ONE live rule (entry-known vars only, no time predicate, all regimes eligible,
P0 + $0.30 exec marks) that maximizes +50 probability with acceptable P0 EV, tradeable whenever
it appears from 11:30 on. Pre-declared bounded family: 72 candidates (T∈{20,25,30,35} × IV
cond {none, IV≥17, IV/RV-low} × scope {all,R3,R4,R5,R3R4,R3R4R5}), dev=A+B, holdout=C,
BH-FDR, EV veto.

**Verdict: B — REGIME-SPECIFIC SETUP FOUND.** Rule: day regime R3 (top_overhang) AND entry
premium ≤ 25% of wing → enter at any checkpoint ≥11:30, take every occurrence, P0 exit.
n=548/210 sessions/5.34yr (103 trades/yr, 39 days/yr); hit 57.3% (first-day 58.6%); EV +0.172 D
every-opp (+5.5% of prem) vs −0.329 book; +13.1pp vs locked pool, +7.5pp/+0.39D vs R3-alone
nested. Positive hit-lift at all 7 checkpoints; leave-one-period/ckpt-out all +EV. Periods:
A +0.184 / B −0.020 (flat, the weak spot) / C +0.212. Floor rate 25.2% (1-in-4 full-premium
loss, small ~$3.1 debit). ALL 72 family candidates: 0 pass the full gate; T≤30 all-regime
(decision-card rule) fails the EV veto (−0.29 dev).

**Material caveats (in the report):** (1) clustered 95% CI on EV crosses zero (−0.19…+0.54);
first-per-day EV = −0.070 (zero) — every-opp EV depends on same-day re-entry (2.61 signals/day).
(2) **Regime timestamp finding:** es_regime is a DAY-level label (R3 ⇔ day high > prior high,
88.9%); only 2.9% of winner trades were "live R3" at entry (1-min cum-high check); the edge
sits in the not-yet-live subset — study-wide convention, flagged. (3) 1500 slice EV −0.213
(hit still +5.5pp). (4) T≤20×R3 sibling (61.9%, +0.238, 37/yr). Nonqualifying: T25×spans
(+0.228, n=87), IV/RV-low×R4 (period-unstable), IV/RV-mid substructure (n=182, display).

Self-checks all passed: baseline repro (44.2%/−0.329), 8,635→7,275→548 reconciliation,
independent SQL recompute 548/548 max diff 0.00, hostile∩winner=0, boundary discontinuity
(57.7%/+0.205 below-25 vs 43.5%/−0.308 above), holdout never used for selection.
During the mission no repo files were touched (card edits forbidden by the mission);
AFTER the verdict, PM directed the study's files to live in `studies/0dte_fly/` (workstation
files, not `docs/`): the decision card was moved there and the M3 deliverables committed
(report `repeatable_setup_m3_report.md`, spec, 3 as-run scripts — re-verified to reproduce
the baseline, family table and winner 548/548 diff 0.0 — and `outputs/m3_repeatable_setup/`);
commit `2bf7be57`, no parquet in git (regeneration recipe in the outputs manifest).
Follow-up (PM: /tmp is not reboot-safe): working parquet moved to durable
`studies/0dte_fly/scratch/fly_setup.parquet` (424 KB, gitignored, regenerates in <1 s),
all scripts + manifest updated, stale /tmp copy removed — commit `e729c983`.

---

## Final Q&A with PM (2026-09-04, after save) + resume-on-reboot

**PM re-statement adjudicated (NO):** "regimes 3,4,5 with premium ≤25" does not work —
T≤25 pooled: R3 57.3%/+0.172 vs R4 50.3%/−0.260, R5 50.9%/−0.072, R3+R4 53.4%/−0.067,
R3+R4+R5 52.7%/−0.069. The rule is **R3-only**. (R5's holdout-C-only +0.144 noted;
not promoted — protocol forbids holdout-driven selection.)

**"Every occurrence" semantics (confirmed with PM):** each checkpoint is its own trade —
premium computed from THAT checkpoint's nearest_25 body (`entry_debit ÷ wing_width` at
the checkpoint), ≤25 on an R3 day = new position. It is **pyramiding**, not top-up: an
open 11:30 position does not block a qualifying 12:30 entry (up to 7 same-day positions,
each with its own P0 exit and ~1-in-4 full-premium floor). Capping at 1/day zeroes the EV.

**One-line live rule (PM's requested format):** R3 day (top-overhang) + premium ≤25% of
wing → enter at any checkpoint ≥11:30, every occurrence, P0 exit (first +50 cross of
executable mark `max(mid−0.15,0)` else 15:55). 57.3% hit / +0.17 D (103 trades/yr);
stricter sibling T≤20: 61.9% / +0.24 D / 37 trades/yr.

## Resume on reboot (PM system maintenance 2026-09-04)

Everything is durable; nothing lives in /tmp anymore:
1. **This card** (`~/oc-ask/opencode_memory/INDEX.md` → `2026-09-04_fly_loss_cut_mae.md`).
2. **Study dir** `/data/agentic_trading/studies/0dte_fly/` — decision card, M3 report
   (full verdict + 72-row family), spec, 3 as-run scripts, `outputs/m3_repeatable_setup/`,
   and the working parquet at `studies/0dte_fly/scratch/fly_setup.parquet` (gitignored,
   regenerates <1 s via `scripts/m3_build_dataset.py`).
3. **Commits:** `2bf7be57` (study consolidation + M3), `e729c983` (scratch parquet move)
   — both on master, both with Agent-Print trailer; study tree clean at shutdown.
4. **L3** `STUDY_SPX_0DTE_FLY_CANONICAL.md` (mark rulings, P0 verdict, premium_pct source
   fix). Note: an unrelated uncommitted modification to it was present at shutdown
   (another seat's work — do not assume it is this thread's).
5. **Open items (unchanged):** findings_update formalization packet (PM's call),
   entry-conditioned management grid inside the winner population, nearest_5 arm,
   17/27 IV-threshold drift check for live use, regime-timestamp resolution (day-level
   label; strictly-live R3 proxy is NOT the edge).
