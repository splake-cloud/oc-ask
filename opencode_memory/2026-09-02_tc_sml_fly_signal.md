# 2026-09-02 — TC "Strongest Morning Line" as a conditional signal for the SPX 0DTE put-fly

Topic: does the Discord channel author's **SML (Strongest Morning Line)** / **SAL (Strongest Afternoon Line)**
carry edge for the desk's SPX 0DTE long-put butterfly as a condition on the convergence tree
(premium% gate → SML side)? Plus a re-derivation of the "gold cell" peel/runner.

**STATUS (after four audits + selloff-rule disposition): the line-specific tradable structure
largely did NOT survive.** The only robust findings are the **premium% entry gate** (not line-related)
and the **SML morning price-magnet** (a price-path effect, not a fly P/L signal). The SML *direction*
entry edge, the **SML "ceiling"/exit (F3)**, the gold-cell×SAL hold finding (F6), **the F9 "SAL
alignment→stability" (retracted as a premium-composition artifact)** were each **retracted or
downgraded**. The **"selloff into 11:30 → +50%" momentum candidate is a NO-GO** (+21pp was a
SML-print-time subset artifact; true line-free effect +7.5-9.5pp, and NEGATIVE inside the ≤28%
premium gate where you actually trade — no implementable edge, no forward test). Full detail in
`/data/agentic_trading/analysis/sml_fly_verify/TECHNICAL_REPORT.md` (17 sections)
+ **11** verify scripts (verify_07–11 are the five audits).

## Constraints (stated once — professional desk, don't re-qualify small-n every message)
- **Fill data excluded** — ORATS bid/ask worst-fill is too conservative; ALL analysis on **mid** marking.
- **ES is the live anchor**; **SPX is a hand-waved estimate** from the ES-SPX spread. Fly test is vs
  **SPX**; repaired rows snap SPX to the true `spx_1min` index level.
- **SML is a MAGNET** (price migrates toward it). Direction (above/below body) is the tested axis;
  proximity-to-body is NOT the signal.
- **POINT-IN-TIME-SAFE joins** (decisive, from audit #1): the reference line = the most recent line
  printed **at or before** the decision time; if none, no line (entry → side='none'; hold → drop the
  row). The earlier "first line of the day regardless of print time" **leaked** on ~30% of entry days
  and 20/21 gold-cell×SAL rows.

## Data built
- `data/discord/strongest_lines.parquet` — **600 rows** (336 SML, 263 SAL, 1 GENERIC) from the
  VolSignals.com Discord export (`~/discord-export`). 2025-02-13→2026-09-01 (326 SML days). SML
  first-print spans 9:49–15:30 (only 32% before 11:00, 30% after 11:30 — *not* "always before 11").
  SAL first-print spans 11:55–15:56 (249/263 in 14:00–15:59).
- Repairs: 14 SPX backfilled, 9 ES digit-garbles fixed, 16 SPX snapped. 600/600 coverage.
- Do NOT use `es_continuous_databento close − cumulative_offset` as ES ground truth (roll-seam artifact,
  ~50-70pts off on a subset; ES ends 2026-08-31).

## FOUR AUDITS (the load-bearing part of this thread)
Each audit was prompted by a valid critique, confirmed empirically, and removed a claimed piece.

1. **POINT-IN-TIME audit** (`verify_07_pit.py`, report §2.1) — look-ahead on the line joins.
   - **F6 gold-cell×SAL: RETRACTED** (n collapses 21→1; the SAL printed 17–133 min *after* the +50%
     touch — the "SAL aligned → 100% reach 2x" was reading the afternoon path back into the morning).
   - **F9 hold: survives only as *afternoon-only*, smaller** (n=342; was n=525 leaked).
   - Entry SML leak was **conservative** (removing it *strengthened* the 11:30 tilt).
2. **CLUSTERING / pseudoreplication audit** (`verify_08_cluster.py`, report §2.2) — pooled 3
   checkpoints (~3 rows/day, within-day win corr 0.63) and tested as independent.
   - **Premium% GATE survives valid (day-level / cluster-robust) inference** (cheap-vs-exp p≈0.000).
   - **SML-direction cheap-cell REFINEMENT does NOT** — valid p 0.135–0.320, not the claimed ~0.02
     (the p=0.017 pooled was the understated SE — exactly as predicted).
   - **SML direction is only a *marginal 11:30* tilt** (all-premium, p=0.039, one row/day); 12:30 has
     none. NOT an established edge.
   - **REFINEMENT (2026-09-02, `sml_spot_weighted.py`): the SML-vs-CURRENT-SPOT signal is STRONGER than
     vs the body** — above-spot 63.9%(n108) vs below 40.4%(n104), **+23.5pp, p=0.0009, CI[+10.3,+36.6]**,
     and MORE robust to the SPX estimate than the body: **boundary-exclusion sweep — significant through
     2pt exclusion (+18.7pp, p=0.0161), n.s. only at 3pt (+12.7pp, p=0.1149)** (body F1 is the fragile one,
     p 0.039→0.118 at 1pt). It is NOT "fragile at 1pt" — do not carry that. See the Canonical statement
     below for the precise close. Body is just a
     25-pt snap of spot (|body-spot| med 6pt; 75% agreement). **SML vs any WEIGHTED AVERAGE is DEAD**
     (prev close / intraday time-avg / 5-10-20d MA all n.s., several negative) — the magnet is relative to
     the CURRENT price, not an average. '0-5 below spot' is the worst bucket (30%): a line just under spot
     pulls spot down (magnet) away from the fly. Still entry-only, single-checkpoint, SPX-estimate-dependent.
   - **DECOMPOSITION (2026-09-02, `sml_spot_vs_drift.py` + `sml_momentum_returns.py`): the SML-vs-spot
     split is MOSTLY LINE-FREE MOMENTUM.** Identity gap1130 = (SML-spot@print) - drift, and the line prints
     ~AT spot (med -0.2pt, 88% within 5pt), so gap1130 ≈ -drift (corr(gap,-drift)=+0.966). A pure "SPX fell
     vs rose over the last N min" rule (NO line, same 212 days) reproduces the split at EVERY lookback:
     +15.5pp/15m (p=0.028), +11.5pp/30m (p=0.101), +15.4pp/45m (p=0.028), **+21.0pp/60m (p=0.0025)** — best
     line-free (60m) within ~2.5pp of SML-vs-spot (+23.5pp). So the line is a NOISY TIMESTAMP of recent SPX
     drift, not an independent signal. ~~"The cleaner rule: a SELLOFF into 11:30 raises P(+50%)"~~ **NO-GO —
     RETRACTED 2026-09-02, see disposition below.**
   - **DISPOSITION — SELLOFF RULE: NO-GO (2026-09-02, `sml_forwardtest_spec.py`, n=1217 line-free 2021-2026).**
     The "selloff into 11:30 → +50%" candidate does NOT survive grounding on the clean line-free population
     (all 1130_20W entries, one/day — the population a line-free forward test would actually use):
     - **+21.0pp (p=0.0025) was a SUBSET ARTIFACT** — it was computed on the 212 days where the SML was
       printed BEFORE 11:30, not a line-free rule. The SML print timing is a strong confound: printed
       before 11:30 → +21.0pp (p=0.0025, n212) vs printed only AFTER 11:30 → **−21.9pp (p=0.040, n97)** —
       a mirror image. So the "momentum" was entangled with the line's timing all along.
     - **True line-free effect is modest and marginal:** unconditional +7.5pp (p=0.009) full 2021-2026 /
       +9.5pp (p=0.077) 2025-02-13+ — below the ~15pp entry-threshold, and p not robust.
     - **The "particularly when premium is favorable" clause is CONTRADICTED:** within the ≤28% entry gate the
       60-min selloff effect is NEGATIVE and n.s. in every population (−2.3 to −4.0pp, p>0.6). It is only
       (weakly) positive in the mid/expensive buckets the premium gate already rejects. No implementable edge.
     - **Decision: NO-GO.** No forward test. Keep the observation (a morning selloff mildly raises the
       unconditional +50% rate off-sample), not a rule. Durable factors unchanged: premium% gate (entry),
       F7 morning-revisit/fade (interpretive), SML direction/position = proxy of SPX drift (retracted as
       independent info), no SML hold/exit.
   - **CANONICAL CLOSING (2026-09-02, final — banked).**
     **Decisive evidence = the WITHIN-GATE result** (premium ≤28%, where the strategy actually trades):
       - SML-versus-spot: **+14.5pp, p=0.180** (n.s.)
       - Selloff-vs-non-selloff: **−2.6pp, p=0.68** (negative, n.s.)
     The SML classification is largely another representation of the same recent-SPX-drift variable
     (corr 0.966), not a distinct line effect.
     **Precision — two corrections to any prior statement:**
     1. The +23.5pp spot result does NOT "die at ~1pt SPX error." Boundary-exclusion sweep (drop rows
        within X pts of the above/below line): **excl ≤2pt → +18.7pp, p=0.0161 (still significant);
        excl ≤3pt → +12.7pp, p=0.1149 (n.s.)**. It dies as an INDEPENDENT LINE effect once decomposed
        into (original line placement at print) + (subsequent SPX drift) — the line prints ~at spot, so
        the residual line content is small.
     2. The two "selection" issues are DISTINCT:
        - **+23.5pp** = a valid association within the 212-day SML-era sample, but primarily a DRIFT PROXY
          (not inflated by selection per se).
        - **+21pp** = genuinely INFLATED by selecting days when the SML printed before 11:30 (SML-print
          timing confound); the full line-free estimate is **+7.5pp**.
     **Canonical statement (verbatim):**
     > SML position and recent SPX drift exhibit statistically significant associations with target
     > attainment in selected or unconditional populations. They represent substantially the same
     > underlying drift condition. Neither provides a statistically reliable or sufficiently large
     > incremental effect within the premium-qualified population where the strategy trades. Therefore,
     > neither becomes an entry rule; premium% remains the only surviving entry filter.
   - **TESTED & NO-GO (2026-09-02): "settled vs transiting at the body"** (`sml_settle_transit.py`,
     verified 0-mismatch, `88340adf`). The best remaining LINE-FREE idea: within the ≤28% gate, does SPX
     *dwelling/oscillating around the body* at 11:30 (vs a *single efficient sweep through it*) raise
     P(+50%)? Frozen + outcome-blind + PIT-safe + 3-way cross-state (none/single-pass/multiple) +
     30-min window. **NO-GO, fails all 5 pre-set bar criteria**: gate lift +6.25pp (p=1.0, <15pp);
     TRANSIT **n=4** (only 4 of 58 single-pass days have eff≥0.5 — the "single efficient sweep" is too
     rare to evaluate, and relaxing the def to reach n=40 is the pinned forbidden search); sign unstable
     (gate +6.25 / full −11 / 2022 +22 / 2025 −47); SETTLED (n48)=56.25% ≈ gate base. Choppiness around
     the body buys nothing over the premium gate. Do not re-run without a materially different def.
   - **ADJUDICATION (2026-09-02): two "softened settings" what-ifs.** (a) Premium gate 28%→32%,
     (b) target +50%→+40%.
     - **32% gate = SUPPORTED as a capacity tradeoff** (measured on the TRADED nearest-25 11:30 pop):
       +50% edge vs rejected PRESERVED (+14.6→+14.5pp), entry hit 54.2→52.1% (diluted by the 28-32 band
       at 47.4%), entry days +44% (391→562). Pure more-trades-at-marginally-lower-quality; the gate still
       discriminates.
     - **+40% target = UNADJUDICATED; keep +50% until nearest-25 FORWARD data can measure it.** The +40%
       result was measured ONLY on the related grid (gold-cell) population (zero trade-ID overlap with
       nearest-25; different +50% baseline: grid-1130 +10.2pp vs nearest-25 +14.6pp). On the grid, +40%
       compressed the premium contrast (≤28 edge +10.2pp p=0.001 → +5.8pp p=0.067). TWO reasons, not just
       ceiling: (1) MECHANICAL — target=(1+X)·D, so 1.5D→1.4D cuts the required mark by 0.1D, a LARGER
       ABSOLUTE drop for high-debit flies (a 45% fly's bar falls 2.25× more than a 20% fly's) → expensive
       flies catch up; (2) ceiling — cheap flies already near the top. DO NOT reject +40% on the grid's
       p≈0.06, and DO NOT adopt it from the grid proxy. The target is a TRADE parameter (peel point); judge
       it on EXPECTANCY at 1.4×D vs 1.5×D, NOT on whether premium% stays significant (an earlier peel can
       improve P&L and soften the gate at once — not a conflict). NO gold-cell peel re-run to answer the
       nearest-25 target question (different conditional population). Settling it needs max_return≥40 on the
       nearest-25 path = the blocked forward rebuild.
     - **Phrasing fix (do not carry "both knobs are now measured"):** the GATE change (28→32) is measured;
       the TARGET change (+50→+40) has a directionally-relevant PROXY result only.
   - **FROZEN CHECK — EXECUTED & SETTLED (2026-09-02)** (`nearest25_path_extend.py` + `frozen_check_40pct.py`,
     `711aee3e`). The blocked forward rebuild is DONE: validated standalone re-impl of fly_trades+fly_paths
     1130_20W/nearest_25 (bit-exact vs existing grid: 22/22 days max|diff|=0.0, target agreement 1.000) →
     built max_return_pct_to_1555 for the FULL nearest-25 pop (1237 days, 2021-05-14..2026-09-01, incl 19 new
     days). Consistency lock (max_return_pct>=50)==target_hit = 1.0000.
     RESULT — the premium% gate is **ROBUST to the target choice**:
       +50%: <=28 +14.3pp (p=0.0000), <=32 +14.0pp (p=0.0000).
       +40%: <=28 +8.2pp (p=0.0086), <=32 +8.5pp (p=0.0036) — compressed ~half (ceiling+mechanical), still robust.
     The grid proxy's "gate falls to p~0.06" was an ARTIFACT; on the real pop the gate HOLDS at +40%. 28-32 band
     (n173): 47.4% (+50%) / 53.8% (+40%), above rejected at both. OOS 19 new days: base 68-74% (strong recent
     regime), gate n too small to measure. **The peel-POINT P&L decision (exit at 1.4D vs 1.5D) is now COMPUTABLE
     (max_return_pct in hand for all days) but is the separate expectancy calc (peel-all vs runner), per the
     adjudication — NOT settled by hit rates alone.** Retain +50% as the default; +40% is a live option, gate
     intact either way.
     **PEEL-POINT EXPECTANCY — DONE & SETTLED (`peel_expectancy.py`, `3cba6ecf`).** Answer: **keep +50% (1.5D),
     peel 100%, NO runner.** Primary <=28% (n393): paired diff (1.4D-1.5D) = -1.95%D/trade, Wilcoxon p=0.0000,
     1.5D better 54.7% of days vs 1.4D 2.3%. Conversion P(reach 1.5D|reach 1.4D)=**0.955** — 95.5% of 1.4D touches
     also hit 1.5D, so peeling at 1.4D surrenders +0.1D on 214 reach-both trades (+21.4D) to save giveback on only
     10 reach-1.4D-only trades (+13.7D); net 1.5D ahead by 7.7D. Same direction at <=32% and no-gate (all Wilcoxon
     p=0.0000; t-test n.s. everywhere = crash tail swamps the mean). **Runner variants (75/25, 60/40) are STRICTLY
     dominated by 100% peel** on mean P&L and win rate (fly gives back after the touch). Best single config = 100%
     peel @1.5D. Caveat: absolute P&L is liquidation-marked (bid/ask, matches grid target_hit) -> negative MEAN from
     the crash tail (min -663%D) but positive MEDIAN (+40/+50%D); the peel-point difference is robust (tail cancels).
     **RUNNER-CONTINUATION AT THE +50% TOUCH — DONE (`9c2329fd`; spec+report RUNNER_CONTINUATION_*.md, midpath build).**
     Correct substrate = nearest-25 11:30 20W, <=30% premium, first reach 1.5D on the MID mark, n=287 days
     (NOT the gold cell's body_method_grid). P(2.0D|1.5D)=**65.5%** (97.9% genuine continuation, not overshoot).
     **Continuation is BINARY not progressive**: reachers +0.49D / non-reachers -0.73D. **Baseline runner value
     E[exit-1.5] = +0.067D, CI [-0.058,+0.190] = WASH on the MID mark.** reaches_2.0D case-control (466 rules searched)
     mostly FAILS as a runner signal: 7 top rules hit the PEAK-VS-EXIT trap (P20>base but E[run]<0, e.g. early-touch
     n_post>=115: P20=73% but E[run]=-0.105) and the best rule's lift collapses 18pp->1.6pp under CENSORING reweight
     (31% of non-doubles were rising at 15:55). **Best runner-positive state** = body_dwell>=0.57 AND gentle
     touch_overshoot<=0.02 (SPX dwelt near the body + clean touch), **17% of touches**, E[run]=+0.295D but bootstrap
     CI [-0.003,+0.568] STRADDLES 0 = NOT confirmed. **Answer: no robust runner-positive state; one weak suggestive one.**
     Mark-dependent (the key tension): mid=WASH, liquidation=-0.10D (runner dominated). Runner value sits in the spread.
     **ACTIVE-RUNNER FIRST-PASSAGE — DONE (`57ebe304`; supersedes the passive wash/trap framing).** The runner is
     ACTIVELY MANAGED (limit at profit target, stop at protective floor, time-stop 15:55); payoff = first passage,
     NOT the 15:55 mark (a 2.0D limit fills at the touch; later giveback irrelevant) — the passive-hold wash was the
     wrong object. Pop 11:30 nearest-25 20W, first mid 1.5D, <=28 (n242)/<=32 (n333), no gold/regime/SML/<=30
     intermediary. P(2.0D before 1.0D)=**0.508**(<=28)/0.514(<=32), model-independent. **ALL 12 target x floor cells
     POSITIVE, both gates, both exec models** (level-fill +0.015..+0.097; stable neighborhood, not isolated). Headline
     (2.0,1.0) mean incr: level-fill +0.043/+0.058 D, market-fill +0.070/+0.072 D; win ~55-57%. Level-fill (user's
     framing, +0.5/-0.5) central; market-fill (cross-value) = slippage bound (higher: target overshoot dominates). Best
     cell (level) = higher target+floor (2.5,1.40) but low win rate; (2.0,1.0) is the balanced cell. Year ~3-4/6 positive.
     25%/40% runner scales linearly. Caveats: discrete-bar first-passage (intra-bar order unresolvable), exec-model
     (best-target direction reverses), composite 3-leg fill simplification. The FLOOR's real win = capped downside.
     **CORRECTION (n_post leak).** n_post (count of post-touch quoteable bars) is a CENSORING var, not a predictor —
     it encodes the observation window to hit 2.0D and was in 160/466 of the old price-path rules -> those are invalid
     live classifiers. touch_time also fixed: minutes-since-midnight (the old numeric percentiles of HHMM, e.g. 1483, are
     not valid times). Manifest: RUNNER_CONTINUATION_FEATURE_MANIFEST.md (12 rule-input features; crossing_pattern +
     regime_id were computed but NOT in the 466 rules).
     **V2 FEATURE SET + COVERAGE GATE (`ab8242db`).** Corrected PIT-safe baseline (ONE touch-time var, signed+abs
     SPX-body dist, body dwell, crossing_pattern, pre-touch efficiency, touch overshoot, entry premium + regime
     controls) + NEW families from the full stg_spx_options chain (IV pre-computed, no BS back-out): body/wing/OTM/
     skew/curvature IV + IV change; IV/RV + implied-remaining-vs-realized (RV from dense stockPrice); 0DTE put
     vol/OI/liquidity concentration at body. 287 touch-days, 37 markers. Coverage: baseline/RV/strike 100%; body_iv
     92.4% (17 days source putMidIv=0.0, 2022 cluster, NOT patched); derived IV 89.9%. IV spot-verified 3/3.
     **V2 BROAD MARKET-STATE SEARCH (`7ddeb0b0`) -> NO MARKER SURVIVES multiple-testing.** Primary outcome = per-day
     incremental of the FROZEN (2.0/1.0 level-fill) runner + P(target_before_floor); reaches_20D demoted to
     diagnostic; 1.75/2.5/MFE/time-to-2.0D descriptive. 320 candidates (IV on 270 CC, non-IV on 287; 3 weak markers
     dropped to descriptive; log(iv_rv_ratio) + implied_vs_realized_diff, raw 176x ratio forbidden). 116 clear +0.03D
     runner lift, NONE survive Bonferroni (0.2725>max 0.1833) or FDR (top q 0.12-0.29); ~96/320 clear by chance.
     Top in-sample: low IV surface + low body_iv_entry (n34, +0.249D, p~0.01 standalone) -> follow-up candidate
     (uniform-IV recompute on all 287 + OOS), NOT validated. No peak-trap. 65.5% continuation days have NO
     identifiable market-state profile (body_dwell the only mild tilt, non-surviving). 17 excluded IV days: no
     material selection (7pp reach20D, n.s.). **Verdict: the runner's +0.065D (P tbf 51.9%) is a STRUCTURAL
     first-passage asymmetry (51.9% target vs 42% floor), not a state-conditional edge to condition on.**
     **FINAL TRADEABLE RULING (2026-09-02, supersedes all runner-conditioning).** After a qualifying fly hits 1.5D,
     run the SAME active 2.0D-target / 1.0D-floor runner (15:55 time-stop) on EVERY qualifying touch, WITHOUT any
     decision-time filter (no IV / IV-RV / body-path / regime / strike-structure). No tested decision-time state
     reliably improves expectancy; the edge is the flat structural asymmetry. Upstream premium% ENTRY gate
     (<=28 primary / <=32 supported) is separate + unchanged. **Low-IV rule = FROZEN HYPOTHESIS**
     (RUNNER_LOWIV_FROZEN_HYPOTHESIS.md): recorded, NOT investigated further in-sample; prospective/held-out
     confirmation ONLY (new forward touches, pre-specified n + threshold, no re-mining). TWO CORRECTIONS: (a)
     uniform-IV recompute on the SAME 287 is measurement-consistency, NOT validation (the rule was selected from
     those obs; real confirmation needs new/held-out trades); (b) do NOT overstate the mechanism — the +0.5 (2.0D)
     and -0.5 (1.0D) barriers are equidistant from 1.5D, so low IV does NOT mechanically favor the upper barrier;
     the in-sample lift has no established mechanism. **Gamma (L3/UW) stays a separate study.**
     **V3 OPTION-STATE PASS (`c355b8b6`) - what PRODUCED the gain, not the vol environment.** Final bounded pass
     before gamma. Features (637 reached-1.5D-mid, -> <=28 242 / <=32 333): (1) leg-level attribution entry->touch
     (dFly=dL-2dB+dU, leg contribs/debit, % from short body, wing asymmetry, single-leg concentration, fly change
     final 5/15min); (2) DYNAMIC smile entry->touch (dIV/strike, dskew, dcurvature, body-vs-wing compression);
     (3) payoff-relative geometry (|SPX-K|/implied move, wing width/implied, dist-to-wing/implied, remaining implied
     move vs move-required-for-2.5D via BS revalue, composite fly spread). CORRECTED TARGET: reach 2.5D before 1.0D
     (first-passage), (2.5/1.0) runner incremental, continuous additional_MFE. P(reach25_before_10): <=28 24.0% / <=32
     19.8% / all 10.7%. **STRUCTURAL FINDING: ~90% of 2.5D outcomes are VOL-driven** (of the 58 <=28 big-fly days
     only 6 are move-reachable holding IVs) -> implied_vs_25D only 11% coverage, descriptive-only; the vol surface
     (not SPX position) is the right lens. **SEARCH: 165 candidates (120 single + 45 pair), 50 clear +0.05, 0 survive
     Bonferroni/BH-FDR.** STRONGEST in-sample signal = DYNAMIC-SMILE CURVATURE FLATTENING: dcurvature<=25pct /
     body_wing_compression>=75pct (body IV compressing relative to wings) -> P(reach25) 0.327 vs 0.240, mean runner
     +0.206 vs +0.053, n=55, consistent P28/P32, NOT a peak-trap = the user's 'genuine curvature development'
     hypothesis (vs underlying crossing the body). Top-by-lift_tbf (wing_asymmetry) IS a peak-trap (raises peak +0.145
     > tradable +0.088). No decision-time option-state marker reliably improves the tradable outcome -> CONSISTENT
     with the flat-runner ruling; the dynamic-smile curvature signal is a FROZEN-HYPOTHESIS candidate for prospective
     confirmation (strongest signal in the whole study, in-sample only). NOTE: the 0.086 leg-attribution 'identity
     dev' is the touch-overshoot + entry-mid-below-quote-debit (contributions sum to the actual 0.65, not the 0.5
     nominal) - not a bug. (Recurring: my commits land in concurrent L3/OPEX commits due to the shared master tree;
3. **GEOMETRY / exit audit** (`verify_09_geometry_exit.py`, report §6) — the old F3 "SML ceiling."
   - **F3 RETRACTED** as both a ceiling test and a live exit. It was (a) **outcome-on-outcome**
     (15:55 close → 15:55 target), (b) **butterfly payoff geometry** (distance from the body;
     corr(close−body, close−SML)=0.89; SML is body+gap, median gap 10), and (c) **temporally
     impossible** ("cut if SPX closes above the SML" = the day is over).
   - Live "cut at SML+25" test: the fly is **already worth ~0** at the cross (past the upper wing,
     body-distance ~40) and holding was **never worse** (0/88). The "ceiling exit" is the payoff,
     observed after the fact.
   - Small residual (SML-near vs far at same body-distance: 74% vs 31%, p=0.00) but axes are
     collinear → NOT cleanly separable from geometry; not established.
4. **COMPOSITION / confounding audit** (`verify_11_robustness.py` regime+boundary,
   `verify_06_2factor.py` F9 stratification, report §12/§14) — prompted by "the marginal
   ALN-vs-FAR dip difference is composition-driven" + "regime was dropped without a test" +
   "the ES→SPX classification is fragile near the boundaries."
   - **F9 "SAL alignment→stability": RETRACTED as an alignment effect.** The marginal "ALN dip
     13% vs FAR 35%" is a **premium-composition artifact**: SAL-ALN is 56.7% expensive-premium
     (dip% mechanically small — the denominator is the fly value at touch), SAL-FAR is 27.9% cheap.
     **Within** each premium bucket the ALN-vs-FAR dip difference is ≤17pp and **inconsistent in
     sign** (cheap +17, mid −7, exp −13). No robust line-based hold signal.
   - **Regime 3/4: tested, adds NOTHING.** Main effect small and **negative** (49.7% vs 58.0%,
     p=0.305; within cheap 62.3% vs 66.7%, p=0.812); n.s. in every premium×SML stratum.
   - **ES→SPX boundary sensitivity: the F1 +15pp tilt is FRAGILE.** 10–21% of rows within 3pt of
     the side boundary; a 1pt worst-case SPX error drops the lift p 0.033→0.118 (n.s.). The
     premium% gate (F8) doesn't use the line and is unaffected.
   - **F7 fade: survives the CORRECT paired test.** The report used unpaired Mann-Whitney
     (p~1e-55); the paired Wilcoxon signed-rank (same 326 days) gives **p=1.75e-42** and **9/9
     AWAY×TOL combos keep AM>PM**. The "SAL PM magnet" is **downgraded**: same-day same-window the
     SAL line attracts more (1.30 vs 0.65/day, paired p=3.31e-13) **but it is freshness-confounded**
     (fresh afternoon SAL vs stale morning SML) — "magnet" not established.
   - **F4 empirical modulo null:** SPX price-endings are **uniform** (each digit 9.7–10.4%), so the
     uniform null is empirically justified; the 1.64× round-5 excess (ES space) is real but mild.

## WHAT SURVIVES (defensible) vs WHAT DIDN'T
**Defensible (robust under valid inference, not geometry):**
- **Premium% is the entry gate** (not line-related): cheap ≤28% ≈ 53-60% vs expensive >45% ≈ 15%;
  monotone; survives day-level clustering (cheap-vs-exp p≈0.000; GEE OR 0.15). **The only robust
  entry factor.**
- **SML attraction fades AM→PM** (F7, **paired** Wilcoxon p=1.75e-42, 326 days, 9/9 param combos)
  — a *price* effect: SML pulls SPX toward it in the morning (2.27 approaches/day) and stops
  pulling by the afternoon (0.67). The old "SAL is the PM magnet" is **downgraded**: same-day
  same-window the SAL line attracts more (1.30 vs 0.65/day) **but freshness-confounded** (fresh
  PM line vs stale AM line) — "magnet" not established.
- **The line is a specific, real, idiosyncratic tick** (F4): 16.4% on round-5 (empirically-
  justified uniform null 10%), ~1.64× → an arbitrary tick with a *mild* round-5 preference, not a
  generic round number.

**Suggestive (NOT capital-grade):**
- **SML-above at 11:30 → marginal +15pp tilt** (all-premium, p=0.039, one row/day); cheap-cell
  refinement not significant, **and fragile to a ~1pt SPX estimate error** (p 0.033→0.118 n.s.).
  Secondary tilt, not an edge.
- **~~F9 (afternoon-only): SAL on the body → steadier remainder~~ — RETRACTED as a premium-
  composition artifact** (within-bucket dip difference ≤17pp, inconsistent sign). See audit #4.
- **F2 path quality:** SML-above = rough path (MAE ~1.85 wings) but small-n (n=43).

**RETRACTED:** F3 "SML ceiling/exit" (geometry), F6 gold-cell×SAL (look-ahead, n→1), **F9
"SAL alignment→stability" (premium-composition artifact)**. **There is no robust line-based
hold or exit.**

## Gold cell (peel/runner) re-derivation — unchanged by the audits
- Source: `verifications/artifacts/2026-08-14_fly_hold_cut_surface_v1/`. 4 conditions:
  premium_at_touch≤26.5%, checkpoint∈{1130,1230}, regime=3, first_touch<14:30, threshold=1.50×.
- **n=52, 39 days, 2022-03→2026-08 (~12/yr)** — the spec's "40-70/yr" was wrong.
- **⛔ THE CITED "+6.9% mid (CI[−14.1,+27.9]) / −12.9% worst-fill" IS UNSUPPORTED — DO NOT USE** (see below).
  It was the original sizing basis for "peel 60-75% / keep 25-40% runner"; that basis is void.
- **⚠ 2026-09-02 reconciliation (`2026-09-02_f5_grid_reconcile_v1/`): the gold cell is UNCHANGED on the
  current grid (n=52, 52 retained, 0 entered/exited).** `touch_events.exit_1555_mid` is the SAME continuation
  % as path_panel (max|diff|=0.000; it is a %, not an absolute — an earlier "corrupted" note was WRONG).
- **⚠ 2026-09-02 CONTINUATION AUDIT (`2026-09-02_f5_continuation_audit_v1/`)** — pinned the estimand and
  bounded the +6.9%:
  - **Estimand (as-implemented):** decision = first_touch_time_mid (mark hit 1.5×debit, the +50% touch);
    exit = **15:55**; num = fly_value_mid[15:55] − fly_value_mid[touch]; denom = fly_value_mid[touch] (=V_touch,
    ~1.5×D); per-trade then arithmetic mean; population = gold cell WITH a 15:55 mid quote; missing **dropped** →
    n=24. (fly_value = GROSS mark, valid bounds [0, W].)
  - **24-observed robust stats:** mean +48.55% (CI t[+15.6,+81.5]), **median +69.6%**, 10%-trimmed +53.1%,
    **pos 79.2%**, p05 −80.2% / p10 −64.9% / p25 +12.6%, **date-clustered 95% CI [+7.1,+81.7] (17 days)**.
  - **The 28 missing (no 15:55 mid) are NOT random:** two drivers — (a) **era/data-coverage** (2022: 1/11,
    2023: 0/1 observed vs 2024-26 17/40) and (b) **liquidity** (last mid quote median 1546, all <1555; losers drift
    off the body and go OTM, then stop being quoted). Missingness associates with LOSERS: 19/28 at/below the touch
    level at last quote; settlement-winners 4/28 (missing) vs 16/24 (observed).
  - **Partial-ID bounds (all 52, value in [0,W]):** all-52 MEAN continuation identified only in
    **[−30.9%, +127.0%] (~158pp wide)** — does not single out +6.9%.
  - **Settlement/intrinsic proxy (SEPARATE, complete all-52, close SPX):** mean **−11.4%**, median **−61.2%**,
    pos **38.5%** — the typical gold fly gives back most of the +50% gain by the close. This is the only
    fully-identified continuation; it is negative, supporting PEELED (not hold-all).
  - **CONSEQUENCE:** the 60-75% peel / 25-40% runner was sized against an unproducible number. **Re-size against
    (a) the 24-observed robust stats (median +69.6%, pos 79%, but survivorship-biased recent-year winners) and
    (b) the settlement proxy (complete, mean negative) — or a prespecified, saved estimand with the missingness
    handled explicitly. Do not act on +6.9%/−12.9%.**
- The gold cell is a **peel/runner, not a hold.**

## "What is the line?" — unverifiable by design; behavior (magnet) is real
- Author's claim: a standing dark-pool spot order "from swaps." No terminal shows a standing dark
  order; swaps flow is private; DTCC is EOD. **Origin = the author's narrative, cannot be
  corroborated** (expected, not evidence against). Stop chasing it.
- **Net:** whatever the level is, its robust tradable content is the **morning price-magnet (F7)**
  and, weakly, the 11:30 direction tilt. It is **not** a fly ceiling/exit (F3 retracted).

## Files / substrate
- `/data/agentic_trading/data/discord/strongest_lines.parquet` (the SML/SAL table).
- `/data/agentic_trading/outputs/fly_trades_nearest25.parquet` (8488×80; key cols `tradeDate,
  checkpoint_label, body_strike, entry_debit, wing_width, regime_id, target_hit_by_1555,
  entry_quoteable`). Body = `FLOOR((stockPrice+12.5)/25)*25`. Premium% = `entry_debit/wing_width*100`.
- `spx_1min` in `research.duckdb` (SPX index 1-min, 11:00-16:00 ET).
- **Report + 11 scripts:** `/data/agentic_trading/analysis/sml_fly_verify/` — `TECHNICAL_REPORT.md`
  + `verify_01..11`. verify_07 (PIT leak), verify_08 (clustering), verify_09 (geometry/exit),
  verify_10 (substrate lineage), verify_11 (composition/robustness: regime + boundary) are the
  **five audits** — read all five. All read-only, all rc=0.
- Python venv: `/data/agentic_trading/.venv/bin/python` (pandas 2.3.3, pyarrow 25.0.1, duckdb 1.5.5,
  scipy, statsmodels).

## Open / next
1. **PM: gold-cell peel fraction** (60-75% peel / 25-40% runner) — live position decision.
2. **Forward test** — out-of-sample / live tracking of the **premium% gate** (the one robust entry
   factor). There is **no line-based exit or hold** to forward-test (F3 ceiling retracted; F9
   line-hold retracted). This is the actual gate before capital.
3. **~~F9 confound control~~ — DONE: F9 retracted** as a premium-composition artifact (audit #4).
4. **Magnet-depletion test** — does the SML's *attraction* (F7) deplete after repeated same-day
   touches? (failure mode; test the *magnet*, not the retracted ceiling.)
5. **Establish the SML direction validly** — only a marginal 11:30 tilt (p=0.039), **fragile to a
   ~1pt SPX error** (verify_11); needs more line history, a prespecified multi-checkpoint
   day-level design, or a tighter ES→SPX estimate.
6. **~~Re-derive the gold cell (F5) on the current 7,912-row grid~~ — DONE (2026-09-02,
   non-mutating, `verifications/artifacts/2026-09-02_f5_grid_reconcile_v1/`). Result: **gold cell
   UNCHANGED** (n=52, 52 retained, 0 entered, 0 exited). Current grid is a strict SUPERSET
   (7,821 common / 0 old-only / 91 new-only = 13 days 2026-08-14→09-01 × 7 cp; 0 dupes).
   regime_id (only grid col in the predicate) unchanged on all common keys; body/wing unchanged;
   5 entry_debit changes are 2026-08-13 regime-5 (non-members). **STOP-gate:** 91 new keys have NO
   touch/path (artifacts end 2026-08-12); 3 grid-eligible candidates (regime 3, cp 1130/1230, all
   2026-08-25) EXCLUDED as unconfirmable. **SUPERSEDED by the continuation audit (see the
   continuation-audit block above): +6.9%/−12.9% is UNSUPPORTED — DO NOT USE**; the 28 missing are
   not random (era + liquidity), the all-52 mean is only partially identified in [−30.9,+127.0], and
   the complete settlement proxy is negative (mean −11.4%). (CORRECTION: `touch_events.exit_1555_mid`
   is NOT corrupted — it matches path_panel exactly.) The 13 new days still need a touch/path
   REBUILD (forward to 2026-09-01) to be included.
7. **Hygiene:** change Discord password (invalidate token) → delete `~/discord-export/token`; add
   `data/discord/` to `.gitignore`.

## NOTES
- **Payoff/risk correction (4th fix):** the report + verify_02 originally misstated the
  long-debit put-fly payoff. Correct: **max net profit = W − D; max net loss = D (the full
  debit, BOUNDED)** reached at/beyond the **outer wings**, which are **ONE wing-width from the
  body (not two)**; intrinsic payoff = 0 at ±W, W at the body. So `premium% = D/W`, reward/risk
  = (1−prem)/prem (a 28% fly risks 0.28W to make 0.72W), and `MAE_frac = 1.0` = max loss (not
  2.0). No finding changed — risk/MAE interpretation only (the trade was LESS risky than the old
  prose implied). verify_09's payoff function was already correct.
- DuckDB reserved words on this box: `first`, `last`, `days` — alias them.
- Pandas precedence trap: parenthesize each comparison (`(f.a==x) & (f.b==y)`).
- HHMM vs total-minutes: `first_touch_time_mid` is HHMM (1424=14:24) but the line `time` is total
  minutes (856=14:16) — convert before comparing.
- Merge on a non-unique key (e.g. `ym`) makes a Cartesian product — assign by position.
- `verify_01_sources.py` ends with `sys.exit()` — do NOT import it from other verify scripts
  (define REPO/ERA directly).
