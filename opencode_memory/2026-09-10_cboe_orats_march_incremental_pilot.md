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
- **Blueprint (the node-field follow-up) — CANONICAL PATH + TRUE STATE (verified from disk 2026-09-10):**
  **`/data/agentic_trading/analysis/sml_fly_verify/gamma_topology/SPEC_node_body_persistence_blueprint.md`**
  (git-tracked; sha `57fa4fb5`, 359 lines). A STALE copy also exists at
  `/tmp/opencode/investigation1/SPEC_node_body_persistence_blueprint.md` (sha `1865dbc7`, 331
  lines, mtime 05:19:30) — **do NOT red-team or cite the /tmp copy; the repo file is canonical.**
  - **Provenance — the original session DIED but a RESUME session continued it:**
    `ses_f77e3263cffezxRRT9eIeWJRNG` ("Gamma data run mid-session evaluation") died at
    compaction 01:45:48 (ContextOverflowError). Resume session
    `ses_f7700aaebffeUYiBobVVSbCftC` ("Resuming blocked session after context overflow",
    started 01:47:09) picked it up and drove the blueprint through **3 committed rewrites**:
    `6ed9d7cb` (v1.0 body-node, red-team pass applied) → `d096bf6f` (v2.0 fixed-fly-body) →
    `ecc59036` (v3.0 re-anchor to the UW node field, drop the fly). Then **uncommitted edits**
    (`git status` = ` M`) at 05:45–05:46 added the **paired in-sample readout**.
  - **v3.0 object = the UW signed-gamma NODE FIELD (NOT the fly body).** v1.0 conflated the
    dominant positive node with the fly body; v2.0 re-anchored to the fixed fly body — both
    REJECTED by PM. The fly belongs to the separate node-materiality/fly-runner study and is
    OUT of scope. Primary population = all 22 March days, all 804 captures. Metrics = N1–N8
    node-field estimands (pos/neg-node detection, dominant-pos/neg identity, rank of true
    nodes in predicted surface, top-K retrieval, strike-location error, signed magnitude &
    prominence, node persistence through time). Success states NODE-CONFIRMED / NODE-MARGINAL
    / NODE-NULL / NODE-INDETERMINATE. Models M1′/M2-U/M2-S REUSED VERBATIM from the pilot.
  - **In-sample readout (committed in v3.1 `ca598592`):** the study produces the in-sample fit
    (the diagnostic that bounds the OOS gap: variance vs missing information) alongside the OOS
    verdict. D1 persists it as `predictions_v1_insample.parquet` (~10.46 M rows, required
    diagnostic); the in-sample file is wall-offed from the learned decision rule (D6-B is
    OOS-only). (Was uncommitted in the resume session; folded into the v3.1 commit.)
  - **RESUMED + APPLIED (2026-09-10, this session):** the resume session
    `ses_f7700aaebffeUYiBobVVSbCftC` was ALSO cut off mid-turn (05:46:28, empty final message)
    before applying its last user instruction (05:46:25):
    > *"the corrected study should report both: **Untrained reconstruction**: raw Cboe×ORATS
    > node fidelity over all March. **Learned reconstruction**: day-held-out incremental
    > fidelity versus ORATS alone. The first answers whether the primitives directly
    > calculate the nodes. The second answers whether UW can teach a mapping suitable for
    > historical backfill."*
    I applied it as **v3.1** and committed+pushed **`ca598592`** (just the blueprint file,
    Agent-Print trailer). v3.1 = the in-sample readout (from the resume session, previously
    uncommitted) **+ the untrained readout**: §1 mission reframed to **three required readouts**
    (untrained / learned-OOS / in-sample); new §5.0 untrained (model-free, raw `orats_agg_gamma`
    ± Cboe flow, no learner/CV) definition; §3/§5.4 carry it; D1 third artifact
    `untrained_surface_v1.parquet` (166,164 rows); **D6 split into two verdicts** — D6-A
    untrained (UNTRAINED-DETECTABLE / NOT-DETECTABLE, model-free) + D6-B learned (NODE-CONFIRMED
    / MARGINAL / NULL / INDETERMINATE, OOS-only); D7/D8 carry the untrained artifact; new **G11**
    gate (untrained integrity: model-free re-derivation); §9 scale + v3.1 changelog +
    seven→eight count fix. **The two verdicts read together:** the backfill question (D6-B) is
    only interesting if the untrained baseline (D6-A) is NOT already sufficient.
  - **RED TEAM v3.1 (2026-09-10, :8011 gpu0 Qwen3.8-27B, clean run, finish=stop):**
    transcript `/data/agentic_trading/.ai/staging/cboe_node_field_redteam/redteam_8011_canonical_response.json`.
    **VERDICT = NEEDS-REVISION — 1 BLOCKER + 7 MAJOR + 4 MINOR + 1 RESOLVED + 3 SOUND.**
    - **BLOCKER-1 (D1/G1):** `pred_gamma` (the node field's load-bearing object, defined by
      `pred_gamma>0`/`<0`/argmax/argmin) is **never defined**; the pilot emits `y_pred_sign`
      (classifier) + `y_pred_mag` (regressor) separately and no `pred_gamma`. G1(b)'s
      per-strike value-identity is on an undefined object ⇒ the "pure target change, not a
      re-fit" proof is vacuous; the node field could be driven by the regressor's sign (not the
      classifier's sign the pilot validated). FIX: define `pred_gamma` (e.g. = `y_pred_mag`)
      and re-point G1(b) at the pilot's actual `y_pred_sign`+`y_pred_mag`.
    - **MAJOR-2 (D6-B):** decision rule not exhaustive — `Δ_sign≥floor AND Δ_Cboe≤0 AND
      CI-excl-0 AND stable` falls through all four states. FIX: add NODE-SIGN-ONLY or fold
      into MARGINAL.
    - **MAJOR-3 (D1/D7/G8):** the in-sample file (~10.46 M rows) has **no integrity gate**
      (no row-count, no fold-composition assert = complement of G10) and G8 lists it as a
      declared input, so the "never used in the verdict" wall-off is prose-only, not
      gate-enforced. FIX: add G12 (in-sample integrity) + a gate that the D6-B computation's
      inputs exclude the in-sample file.
    - **MAJOR-4 (D6-B/N8):** the six floors' conjunctive-vs-disjunctive is unspecified; if
      disjunctive, N8 persistence agreement can carry a stable-wrong NODE-CONFIRMED (a model
      always predicting the modal wrong strike scores ~81.3% on N8 = same as a correct model).
      FIX: make floors conjunctive AND require N3/N1 accuracy to accompany N8.
    - **MAJOR-5 (N3/§4):** the dominant node persists 81.3% ⇒ N3 is low-entropy, near-constant;
      a single-fixed-strike predictor scores ~80% without reconstructing. FIX: report N3
      conditional on the true node changing, or a margin-aware (top-2 overlap) measure.
    - **MAJOR-6 (D6/§10):** the 1pp recall floor is tuned between the pilot's observed
      sign_acc Δ (0.786pp, below) and pos_recall Δ (2.175pp, above) ⇒ calibrated to make
      CONFIRMED reachable, not from a pre-declared MDE. FIX: derive from MDE + power on n=22.
    - **MAJOR-7 (§5.0/G11):** the untrained baseline uses only `orats_agg_gamma` (1 of 12 ORATS
      features) ± Cboe, so the learned-minus-untrained gap is confounded by the 11 features the
      learner adds — it answers "does the quoted-gamma column alone detect nodes?", not "do the
      primitives (all 12 + Cboe)". FIX: re-scope the claim, or build the untrained surface from
      all 12 features model-free.
    - **MAJOR-8 (G1(b)):** the "reference re-run of the frozen pilot" is **not hash-pinned**
      (the frozen `run_model_comparison.py` discards per-strike predictions in-memory), so
      G1(b) compares against an un-pinned modified script ⇒ circular. FIX: pin the reference
      script by sha256, or re-point G1(b) at `y_pred_sign`/`y_pred_mag`.
    - MINOR: (9) n=22 clusters is below the bootstrap-CI reliability threshold (~40-50);
      (10) "node field" is really the sign field (53.5/59.5 strikes) + 1 dominant node — rename
      N1/N2 to sign-field detection; (11) the 10.46M+498k prediction artifacts are reusable
      substrates despite "not a layer"; (12) the §5.4 concentration ratio is
      regressor-vs-classifier-driven, not like-for-like.
    - **RESOLVED:** the v3.1 in-sample readout DOES produce the diagnostic that bounds the OOS
      gap (variance vs missing information) — that prior concern is resolved (but the wall-off
      gating in MAJOR-3 remains). SOUND: G10 (OOS purity), G11 (untrained integrity), D1
      three-artifact separation.
  - **NEXT (awaiting operator ruling):** resolve the BLOCKER + 7 MAJORs in v3.1 — (1) define
    `pred_gamma` + re-point G1(b) at `y_pred_sign`/`y_pred_mag` (BLOCKER-1, MAJOR-8); (2) make
    D6-B exhaustive (MAJOR-2); (3) add G12 in-sample integrity + gate-enforce the verdict
    wall-off (MAJOR-3); (4) conjunctive floors + N3/N1 accuracy precondition for N8 (MAJOR-4,5);
    (5) MDE-derived floors (MAJOR-6); (6) re-scope or enrich the untrained surface (MAJOR-7);
    then transcribe the ruling into the frozen spec and dispatch D1→D2→D3 → KASA.
- Pilot STOPPED at the purchase verdict per PM (SIGNED_FLOW_ADDS, sealed P&L).
- The 0DTE key-mapping 22-day frozen run remains staged (run_22day_frozen.sh, logic hash
  75c9d62f…) but is explicitly not the pilot's answer — launch only if PM wants the
  0DTE key-mapping adjudication extended to all 22 dates.
- If PM wants a stronger Cboe signal: the increment is minor; candidates are (a) more
  Cboe months (the CV is within-March because Cboe is March-only — more months would allow
  a cleaner leave-one-month-out and test regime stability), (b) richer Cboe features
  (per-expiry flow, OI changes, price/quote fields), or (c) a different target (magnitude
  rank rather than sign). None started.
