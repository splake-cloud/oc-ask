# 2026-09-10 — All-expiry March Cboe×ORATS incremental-information pilot

Continues the Cboe gamma thread (see 2026-09-09_cboe_orats_uw_0dte_join_adjudication card).
Pivot: PM redefined the pilot. The 0DTE key-mapping 22-day run (staged, not launched) is
explicitly **not** the Cboe pilot's answer. The pilot is: on the same March UW
observations, does adding correctly-constructed Cboe C1 flow to the frozen ORATS feature
set improve OUT-OF-SAMPLE reconstruction of UW's signed strike-level gamma? State
distillation, not inventory accounting. P&L SEALED, stop at the purchase verdict.

## Verdict: SIGNED_FLOW_ADDS
The purchased **signed** MM flow supplies information beyond ORATS **and** beyond unsigned
Cboe activity. Both load-bearing deltas are positive AND their paired-bootstrap 95% CIs
exclude 0 on all four metrics.

## The three locked models (identical observations, folds, learner, ORATS features)
- M1'  : ORATS only (12 FEATURE_COLS from the frozen signed_state_model.py, unchanged) — the
  PAIRED baseline (ORATS-only under the SAME CV).
- M2-U : M1' + UNSIGNED Cboe (abs_flow, gamma_abs, n_series, mapped_frac).
- M2-S : M1' + SIGNED Cboe (net_flow, gamma_net, n_series, mapped_frac).
Δ_Cboe = M2-S − M1'; Δ_sign = M2-S − M2-U.

## Pooled fidelity (22 held-out March days)
| model | sign_acc | mag_spear | pos_prec | pos_rec |
|---|---|---|---|---|
| M1'  | 0.49122 | 0.04869 | 0.54533 | 0.42032 |
| M2-U | 0.49267 | 0.05854 | 0.54751 | 0.41908 |
| M2-S | 0.50053 | 0.09117 | 0.55585 | 0.44083 |

Paired deltas (pooled): Δ_Cboe sign_acc +0.00931, Δ_sign sign_acc +0.00786,
Δ_Cboe mag_spear +0.04248, Δ_sign mag_spear +0.03263. All positive.

## Uncertainty (paired bootstrap, 100k resamples, seed 42)
Both Δ_sign and Δ_Cboe CIs **exclude 0** on all 4 metrics (e.g. sign_acc Δ_sign
[+0.00318,+0.01375], Δ_Cboe [+0.00431,+0.01512]). Verdict is robust, not a bare point estimate.

## Magnitude caveat (honest)
Significant but **small**: sign_acc 0.4912 → 0.5005 (~1pp over a ~49% baseline barely above
chance). Cboe signed flow is a real but MINOR information source for March UW signed
strike-level gamma. Not a dominant predictor, not a P&L claim (sealed). Does NOT answer the
broader Cboe-pilot goal (0DTE key-mapping / inventory).

## CV design (forced by data availability)
Cboe C1 exists ONLY for March 2026 (2772 zips). M2's Cboe features exist only for March, so
all test folds are March with Cboe in BOTH train and test → **leave-one-day-out WITHIN March**
(22 folds). The published M1 (leave-one-month-out, 183 days, sign_acc~0.470, FAIL-SIGN) is
CONTEXT only — different folds, NOT the paired baseline. M1' (ORATS-only, same CV) is the
valid paired baseline.

## Key facts settled (with file paths)
- M1 frozen: `/tmp/opencode/investigation1/signed_state_model.py` (hash f6813985…): 12
  ORATS FEATURE_COLS, GBM(n_est=50, depth=3, lr=0.1, subsample=0.8, seed=42) 3-class sign
  (−1→0,0→1,+1→2) + normalized-magnitude regressor, fidelity_metrics (sign_acc,
  mag_spearman, pos_node_precision, pos_node_recall).
- Matched frame `/tmp/opencode/investigation1/matched_frame_all_expiry.parquet` (hash
  64dddeab…): 166,164 March rows, grain (day, capture_HHMM, strike), carries orats_agg_gamma
  (strike-level sum) + UW teacher (uw_gamma/uw_side/uw_sign). Capture grid 940–1450 (32–38
  captures/day) ⊂ Cboe 10-min grid → exact time alignment, no loss.
- ORATS per-contract `gamma` is a single column per (tradeDate, snapShotEstTime, expirDate,
  strike), shared by call/put at the same strike (put-call parity) — the formula's weight.
  expirDate dashed vs Cboe YYYYMMDD; both strikes in points, ×10000 INT64 join.
- Feature pipeline (Stage A): safe-differenced Cboe interval flow per exact series
  (decrease→clamp 0; 18:00→20:20 reset; NEVER zero-fill a missing cumulative counter before
  differencing), joined to ORATS per-contract gamma, aggregated Σ over (expiry, C/P) to the
  UW strike grain. 6 features: cboe_net_flow_kt, cboe_abs_flow_kt, cboe_gamma_net_kt,
  cboe_gamma_abs_kt, cboe_n_series_kt, cboe_mapped_frac_kt. Mean ORATS coverage 0.981–0.9997.

## Artifacts
- Stage A builder: `/tmp/opencode/investigation1/pilot/build_cboe_orats_features.py`
  (qwen-coder) → `pilot/cboe_orats_features_march.parquet` (hash 150ecb50…, FROZEN input to B)
  + `feature_reconciliation.json`.
- Stage B comparison: `/tmp/opencode/investigation1/pilot/run_model_comparison.py`
  (qwen38-delegate) → `pilot/model_comparison.json` (hash 2ea6eb44…) + `PILOT_REPORT.md`.
- Spec: `/tmp/opencode/investigation1/SPEC_pilot_cboe_orats_march.md`.
- verify-run transcripts: `/data/agentic_trading/verify/pilot_A_feat_indep.*`,
  `pilot_B_main.*`, `pilot_B_indep_refit.*` (M1' re-derived to 1e-9 on all 4 metrics, no
  leak), `pilot_B_bootstrap_ci.*`.

## Verification (primary seat, independent)
- Stage A: 166,164 rows, no UW cols, abs_flow≥|net|, mapped_frac∈[0,1], 22/22 reconciliation
  identities, deterministic (byte-identical).
- Stage B: M1' 2026-03-16 fold re-derived from scratch (frozen functions) matches script on
  all 4 metrics to 1e-9 (no train/test leak); determinism (byte-identical JSON); bootstrap
  CIs exclude 0.

## PM ratification (2026-09-10)
PM ratified the conclusion: **the pilot discovered a real but weak incremental signal.**
Whether it is the *missing reconstruction puzzle piece* remains **UNANSWERED** until that
signal is shown at the **node / body / persistence level**. The strike-level sign-fidelity
increment (the purchase verdict) is only the entry test — it does not establish that Cboe
flow improves reconstruction of the *body node* (the object that carries keeper value in the
node-materiality line: rank-1 node, body/top1, persistence across captures).

## Open / next
- **Blueprint WRITTEN (2026-09-10, DRAFT — D1–D8 PROPOSED, awaiting operator ruling):**
  `/tmp/opencode/investigation1/SPEC_node_body_persistence_blueprint.md` — shape follows
  `studies/es_auction_profile/specs/blueprint_v7_study_a_hvn_attraction.md` (mission/non-
  mission → hash-pinned upstream contracts → pre-registered question → measured baseline →
  proposed design → decision items → gate draft → KASA block → data-access → open
  questions). Load-bearing discovery: the frozen pilot persists ONLY per-fold metrics, NOT
  per-strike predictions — the node test needs them ⇒ **D1 = a hash-pinned prediction-
  persistence extension** that MUST reproduce the pilot's pooled strike metrics to 1e-9
  (G1) before the node target is trusted (proves value-identity, pure target change not a
  re-fit). Body node = rank-1 POSITIVE-gamma strike per (day,capture); 804/804 March captures
  have ≥1 positive (body always defined in-window); 14/22 March days are touch days
  (persistence T4 is touch-only, PIT 3 pre-touch captures, MAX(rank)≤1 not min). Success
  states BODY-CONFIRMED / STRIKE-ONLY / BODY-NULL / INDETERMINATE. Gates G0–G9, KASA S1–S7
  (S1 value-identity + S6 outcome-isolation highest severity). Open: D5 scope (all-22
  primary vs touch-14 primary) + T1-identity vs T4-persistence as the primary.
- **Node/body/persistence-level test (the decisive follow-up, NOT started):** re-run the
  three-model comparison with the target moved from strike-level sign to the BODY-NODE
  state. Concretely: (a) identify the body strike per day (node_materiality.parquet
  body_strike for touch days; the rank-1 positive-gamma strike per capture otherwise),
  (b) derive the body-node state from each model's predicted strike-level signed gamma
  (body sign, body rank among positive nodes, body/top1 ratio, persistence across the
  captures before the touch — the M1/M2/M4 measures), and (c) test whether M2-S improves
  body-node fidelity over M1' / M2-U. The load-bearing question is whether the weak
  strike-level sign increment concentrates on / is visible at the body node — if it does
  not, Cboe flow is not the missing reconstruction piece.
- Pilot STOPPED at the purchase verdict per PM (SIGNED_FLOW_ADDS, sealed P&L).
- The 0DTE key-mapping 22-day frozen run remains staged (run_22day_frozen.sh, logic hash
  75c9d62f…) but is explicitly not the pilot's answer — launch only if PM wants the
  0DTE key-mapping adjudication extended to all 22 dates.
- If PM wants a stronger Cboe signal: the increment is minor; candidates are (a) more
  Cboe months (the CV is within-March because Cboe is March-only — more months would allow
  a cleaner leave-one-month-out and test regime stability), (b) richer Cboe features
  (per-expiry flow, OI changes, price/quote fields), or (c) a different target (magnitude
  rank rather than sign). None started.
