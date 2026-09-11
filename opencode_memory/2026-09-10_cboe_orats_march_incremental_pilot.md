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
  - **v3.2 — BLOCKER + 7 MAJORs RESOLVED (2026-09-10, committed `246a4f5f`, AWAITING PM
    RATIFICATION):** all eight red-team findings resolved on the blueprint (spec authoring is
    the acting seat's, not routed). Fixes:
    - **BLOCKER-1 + MAJOR-8:** `pred_gamma^m_k = y_pred_mag` DEFINED (the signed normalized-
      magnitude regressor output — the frozen pilot's OWN convention, `signed_state_model.py:394`
      `"pred_gamma": y_pred_mag_full`). New **D9** freezes it (classifier sign + the product
      rejected). G1(b) re-pointed at the pilot's actual `y_pred_sign`/`y_pred_mag` via a
      **sha256-pinned reference re-run script** (circularity closed).
    - **MAJOR-2:** D6-B decision rule made **exhaustive + mutually exclusive** via new
      **NODE-SIGN-ONLY** (Δ_sign material/significant/stable but Δ_Cboe ≤ 0). Five states
      (INDETERMINATE/NULL/CONFIRMED/SIGN-ONLY/MARGINAL) partition the outcome space (first match
      wins); §3 success-states list synced.
    - **MAJOR-3:** new **G12** (in-sample purity — exact complement of G10: every row's day was
      IN its scoring fold's training set, row count 166,164×3×21, 21 folds/row) + **G8** now
      gate-enforces the verdict wall-off (D6-B decision-rule input set excludes the in-sample +
      untrained files, a gate not prose). New G7 tamper tests.
    - **MAJOR-4:** floors **CONJUNCTIVE** (F = every metric floor AND stability); N8
      persistence counts toward F **only if** N3-conditional-identity ≥ base rate (stable-wrong
      node can't carry the verdict).
    - **MAJOR-5:** **N3 made conditional** on the true node changing (flip pairs ~18.7% of 782)
      + top-1/top-2 margin diagnostic; raw identity no longer a floor metric.
    - **MAJOR-6:** floors **MDE-derived** (pre-declared MDE + power analysis on n=22
      day-clusters; if power < 80% declared UNDERPOWERED, NOT floor-lowered), not
      observed-increment-derived.
    - **MAJOR-7:** untrained readout **re-scoped** to "ORATS quoted-gamma column alone (± Cboe)"
      + the **11-feature confound** stated (learned-minus-untrained gap also reflects the 11 ORATS
      features the learner adds); the stronger "all 12 features" question = a new version.
    - MINOR-9/12 folded in: n=22 cluster limitation declared (permutation robustness);
      concentration readout labeled **CROSS-OUTPUT** (not like-for-like).
   - **v4.0 — PM RE-ARCHITECTURE (2026-09-10, committed `5812db4c`, AWAITING PM RATIFICATION):**
     PM rejected v3.2 on three grounds and issued a full re-architecture. v4.0 implements all of it:
     - **Object renamed "node field" → "signed strike field"** (sign classification pos/neg/flat +
       dominant extrema argmax/argmin). "Node" terminology dropped everywhere (was undefined).
     - **`ORATS + λ·CboeFlow` sum DELETED** (dimensionally arbitrary). Direct fields are now
       SEPARATE contract-grain arms compared directly to UW, never summed: F-ORATS = Σ_c Γ^{ORATS};
       F-Cboe-Δt = Σ_c Γ^{ORATS}·Δt(MMbuy−MMsell); F-Cboe-cum = Σ_c Γ^{ORATS}·(MMbuy−MMsell)_{session}.
     - **D10: combined learned field `Γ = y_pred_sign · |y_pred_mag|`** — sign/membership from
       classifier, magnitude/ranking from regressor. REVERSES v3.2's D9 (`pred_gamma = y_pred_mag`).
       Flat-behavior diagnostic required (near-zero ε, frozen in manifest).
     - **Three arms / three questions:** Q1 direct (no UW, absolute-fidelity gate — fixes v3.2's
       invalid relative floor), Q2 learned OOS (transfer; Δ_Cboe=M2-S−M1′, Δ_sign=M2-S−M2-U),
       Q3 extracted topology (concentrations a historical study consumes) via a **frozen,
       parameter-free extractor** (G13) applied identically to UW + each field.
     - **Q1 gate fixed** to a pre-declared absolute-fidelity threshold (not a circular increment MDE).
     - D1–D10, G0–G13, KASA S1–S9 all present. 561 lines, sha `d375911e`.
   - **v5.0 — NARROW EXECUTION SPEC (2026-09-10, committed `69941355`, AWAITING PM RATIFICATION):**
     PM ordered: STOP revising the 561-line blueprint; replace it with a narrow execution spec for
     the EXISTING March OOS predictions. v5.0 (163 lines, sha `e49c1944`) implements exactly that:
     - **One run** on the existing M₁′/M₂-U/M₂-S March OOS predictions (re-derived by re-running the
       FROZEN models — NOT a new learner, NOT a new feature set). The pilot computes per-strike
       `y_pred_sign`/`y_pred_mag` in memory but persists only pooled metrics, so §3 re-derives and
       persists `predictions_v2.parquet` (498,492 rows). Integrity gate G1: pooled metrics must
       reproduce `model_comparison.json` to 1e-9.
     - **Object:** predicted signed strike field `Γ = y_pred_sign · |y_pred_mag|`; truth = `uw_gamma`.
     - **Four node-value metrics** (per (day,capture), within-day mean): M1 top-5 positive overlap,
       M2 top-5 negative overlap, M3 dominant-positive location (identity), M4 dominant-negative
       location (identity), M5 signed-field Spearman, M6 secondary-transition persistence (supporting,
       not verdict-driving).
     - **Paired daily deltas:** Δ_Cboe = M₂-S − M₁′; Δ_sign = M₂-S − M₂-U.
     - **Verdict:** NODE VALUE / DIFFUSE ONLY / AMBIGUOUS (pre-declared, exhaustive, first match wins;
       Maj = 14/22 day-majority floor, NOT tuned to the observed increment).
     - **EXCLUDED (non-goals):** direct-field arm, in-sample build, new learner, feature development,
       production mutation. P&L and fly inputs SEALED.
     - Grounded facts (verified from disk): pilot `run_model_comparison.py` persists only metrics;
       `signed_state_model.py` (sha f6813985) has `derive_sign`/`normalize_magnitude`/GBM(50,3,0.1,0.8,42);
       matched frame (sha 64dddeab) 166,164 March rows / 22 days / grain (day,cap,strike) unique /
       32–38 captures/day / uw_gamma 45.3% zero.
   - **v5.1 — PM REVISION (2026-09-10, committed `e8f7a3b3`, AWAITING PM RATIFICATION):** PM fixed
     three v5.0 defects:
     - **Failed predictions scored, not refused.** A model with no predicted positive/negative member
       scores **0** on M1–M4 (a miss, not a refusal); refusal is reserved for the **truth** being
       undefined (no true positive/negative). §4 "Refusal vs failure" paragraph + the per-metric
       "refused when" column now say "no true positive/negative" only.
     - **M6 (rank-2 transition persistence) DELETED** — PM: it "appeared without rationale, unrelated
       to the dominant concentrations, a seam for argument"; persistence removed entirely (not the
       alternative "secondary dominant transition agreement" — PM recommended removal).
     - **Decision rule made JOINT.** v5.0 counted Δ_Cboe and Δ_sign clearances separately (could
       declare NODE VALUE when 3 metrics beat M₁′ and a *different* 3 beat M₂-U). v5.1: the SAME
       metric must clear BOTH. `cboe_clear(m) = mean Δ_Cboe ≥ 0.05 AND pos_days ≥ 14`;
       `sign_clear(m) = mean Δ_sign ≥ 0.05 AND pos_days ≥ 14`; `joint_clear = #{M1..M4 : cboe_clear
       AND sign_clear}`. **NODE VALUE = joint_clear ≥ 3**; **DIFFUSE ONLY = joint_clear < 3 AND M5
       improves both M₁′ and M₂-U on ≥ 14/22 days**; **AMBIGUOUS** otherwise. Constants: `floor = 0.05`
       (5pp — appropriate, M1–M4 bounded 0–1) + `Maj = 14`.
   - **RUN EXECUTED (2026-09-10) — VERDICT: DIFFUSE ONLY.** Dispatched to qwen-coder (BUILD + run,
     then an EDIT re-run for the M4 symmetry fix). G1 integrity gate PASSED (all 12 pooled metric/model
     comparisons reproduce model_comparison.json to 0.0 delta). Artifacts under
     `/tmp/opencode/investigation1/pilot/field_v2/` (predictions_v2.parquet 498,492 rows; node_metrics_v2;
     daily_deltas_v2; analysis_v2.json; manifest.json g1_pass=true, sealed_pnl=true, fly_sealed=true).
     Per-metric (mean_cboe / pos_days_cboe | mean_sign / pos_days_sign):
     - M1 top-5 pos:  -0.0053 / 10 | -0.0091 / 7   (neither clears)
     - M2 top-5 neg:   0.0787 / 19 |  0.0348 / 16  (cboe_clear only)
     - M3 dom-pos:     0.0673 / 17 | -0.0058 / 13  (cboe_clear only)
     - M4 dom-neg:     0.0355 / 21 |  0.0344 / 17  (neither — under the 0.05 floor)
     - M5 field spear:  0.0268 / 15 |  0.0198 / 15  (m5_improves: pos_days>=14 both)
     **joint_clear = 0** (no node metric clears BOTH comparisons) → **DIFFUSE ONLY** (M5 improves over
     both M1' and M2-U on >=14 days; the nodes do not jointly clear).
     - **M4 symmetry defect found + fixed (v5.1.1, commit `2eff5b4a`):** first run's M4 was structurally
       ZERO — the predicted dominant negative used `argmin |y_pred_mag|` (least-negative predicted), not
       symmetric to the true side's `argmin uw_gamma` (most-negative true). Fixed to `argmax |y_pred_mag|`
       (most-negative predicted). Verdict UNCHANGED by the fix (M4 clears neither comparison under either
       reading). Independently verified from the parquet, not the delegate's report.
     - Verify transcripts: `/data/agentic_trading/verify/field_v2_run.20260910T110232Z.txt` (initial),
       `field_v2_run_m4fix.20260910T110623Z.txt` (M4 fix).
    - **FORMAL RECORD (PM ruling 2026-09-10, CORRECTED post-adjudication):**
      - **Formal verdict: DIFFUSE ONLY** under the frozen ≥5 pp / 3-of-4 joint gate. **UNCHANGED** by the
        M1 fix (independently re-verified: joint_clear=0, m5_improves=True).
      - **Substantive finding (CORRECTED): BOTH-NODE ENRICHMENT (Cboe leg) BELOW/AT FLOOR; SIGN LEG NULL
        ON ALL NODE METRICS.** The original "POSITIVE-NODE NULL" was an artifact of the M1 bug (below).
      - Corrected evidence (post-fix, independently verified): M2 top-5 neg Δ_Cboe +7.9pp/19 (cboe_clear),
        Δ_sign +3.5pp/16; M3 dom-pos Δ_Cboe +6.7pp/17 (cboe_clear), Δ_sign −0.6pp/13; M1 top-5 pos
        Δ_Cboe +3.3pp/13, Δ_sign +2.1pp/13; M4 dom-neg Δ_Cboe +3.6pp/21, Δ_sign +3.4pp/17. So the Cboe
        ACTIVITY leg enriches nodes on BOTH polarities (M2+M3 clear the 5pp floor; M1+M4 below), while the
        participant-side SIGN leg is below the 5pp floor on EVERY node metric (max M2 +3.5pp; M3 negative).
        M5 diffuse field improves over both baselines (Δ_Cboe +2.7pp/15, Δ_sign +2.0pp/15).
    - **ADJUDICATION + M1 FIX (2026-09-10):** Independent adjudication (scratch
      `/tmp/opencode/adjudication_cboe/`, no builder code imported) found the builder's **M1
      (top-five positive overlap) computed WRONG** — a double-permutation at `run_field_v2.py:202–208`
      (`pred_pos_indices[order[sorted_idx[:5]]]`) selects ~100×-smaller magnitudes. Independently
      confirmed: builder M1 pred-top5 wrong on **772/804** captures; month M1 **0.0199 (builder) vs
      0.1716 (correct)**; isolation proved the pred-top5 double-permutation is the sole cause. This made
      the published M1 Δ_Cboe read −0.5pp (should be +3.3pp) and overstated "positive-node NULL."
      - **PM RATIFIED the fix** (M1 pred-top5 → single `np.lexsort((pred_pos_indices, -pred_pos_abs_mag))`,
        mirroring the already-correct M2; PLUS the optional MINOR true-top5 tie-break fix on M1+M2 →
        lexsort smallest-strike instead of unstable argsort).
      - Applied by qwen-coder (EDIT, exact 3-block diff), re-run via
        `verify-run field_v2_m1fix` → transcript `/data/agentic_trading/verify/field_v2_m1fix.20260910T140645Z.txt`.
      - **Independently verified (not the report):** regenerated node_metrics match my independent
        reconstruction at **0.0e+00 on ALL FIVE metrics** (M1 0.0199→0.1716; the true-top5 fix also
        closed the prior M2 0.2 tie diff); predictions byte-identical (model code untouched, 0 diffs /
        498,492); G1 PASS (12/12 within 1e-9); decision rule recomputed → **DIFFUSE ONLY** (unchanged).
     - **NEXT:** thread closed at the verdict (DIFFUSE ONLY, now on correct M1 evidence). If reopened, the
       binding constraint is the 5pp floor on the SIGN increment (max node-metric sign increment +3.5pp);
       a stronger node claim needs more Cboe months (regime stability) or a different node target. None started.
      - **DURABLE RECORD COMMITTED (2026-09-10):** this card committed+pushed `6505645` (oc-ask); the 11
        verify receipts (`pilot_A_feat_indep`, `pilot_B_{main,indep_refit,bootstrap_ci}`, `field_v2_run*`,
        `field_v2_run_m4fix`, `field_v2_m1fix`) committed+pushed `b9ef203b` (main repo, verify/). The
        field_v2 code + heavy parquets live in `/tmp/opencode/investigation1` (local-only repo, no remote,
        not git-operable from the oc-ask seat) — receipts + card are the durable record.
  - **METHODOLOGY CORRECTION v2 (2026-09-10/11) — SUPERSEDES the "DIFFUSE ONLY / needs more Cboe months"
    NEXT above.** Operator-directed adjudication of whether v1 used the Cboe Open-Close data correctly.
    All 4 methodological defects CONFIRMED from the code: (1) stock-vs-flow — all 6 v1 Cboe features are
    10-min interval deltas, no cumulative field; (2) non-nested signed — `CBOE_S` replaced `CBOE_U`
    (abs→net swap), so `M2-S−M2-U` never isolated sign; (3) synthetic field — `sign×|mag|` is a hybrid
    post-model construction; (4) MM-only scope. Corrected features add the **signed session-cumulative
    MM gamma flow** (an **accounting state-change feature** — temporally valid, economically connected to
    position changes; **correlation with UW does NOT establish causality and does NOT recover opening
    inventory**). The cumulative is a state the 10-min interval was structurally blind to.
    - **CORRECTED DISPOSITION (operator ruling 2026-09-11): MARCH DEVELOPMENT PILOT: SUCCESS. APRIL
      FROZEN CONFIRMATION PURCHASE JUSTIFIED.** (Replaces my initial "CORRECTED METHOD MATERIALLY
      STRONGER" — operator narrowed the claim.) **Narrow claim (the only one supported):** March shows
      C1 session-cumulative signed MM flow can **distill the contemporaneous UW all-expiry signed node
      field**; April must determine whether that mapping **transports out of month**.
    - **Result (day-equal, independently re-derived, not from the delegate report):** D3 total
      (M2-US-C−M1-C) top-5 exact **+0.474** / dominant-exact **+0.521** / Spearman **+0.350** / distance
      48.4→21.2 pts; D2 signed increment (horizon controlled) **+0.443**/+0.492/+0.336; D1 unsigned
      cumulative ~0 (+0.003/+0.006); OLD v1 non-nested signed +0.028 (~16× smaller). **Model-free
      readout** (raw `net_session_gamma`, zero learning) already scores top-5 **0.627** / Spearman
      **0.324** (vs ORATS alone 0.129/−0.036) — the signal is in the data, not the learner. M1-C
      reproduces v1 **exactly** (7372/7372 sign, 0.000e+00 mag diff); M2-US-C jump reproduced to 4
      decimals from a from-scratch re-fit.
    - **2 delegate bugs caught + corrected** in `run_nested_model_comparison_v2.py`: (a) `_tolerance_match`
      applied ±5/±10 to index positions, not strike values (overstated pm5/pm10; load-bearing exact/
      dominant/spearman unaffected); (b) `_diff` hardcoded "hybrid" so the stored "direct" comparisons
      were actually hybrid (recomputed correctly). The delegate's "different sklearn version" excuse is
      FALSE (env is deterministic; fresh M1-C matches v1 exactly). 12-item semantic verification PASS.
    - **Deliverables** `/data/agentic_trading/analysis/sml_fly_verify/gamma_topology/cboe_orats_march_v2/`
      (committed+pushed `8212cc1f`): METHOD_AUDIT_v2.md, CORRECTED_MARCH_REPORT_v2.md,
      build_cboe_orats_features_v2.py, run_nested_model_comparison_v2.py, verify_v2_{independent,final}.py,
      nested_model_comparison_v2.json, v2_independent_recompute.json, feature_manifest_v2.json,
      three_series_trace.json, v2_execution_log.jsonl. The 6.9MB `cboe_orats_features_march_v2.parquet`
      stays in `/tmp` (heavy binary, regenerable from the committed builder). v1 preserved byte-for-byte.
    - **NEXT: April frozen confirmation purchase is JUSTIFIED + RECOMMENDED but NOT executed** (no April
      data bought, no production mutation, no live integration in this session). April's job: does the
      session-cumulative→UW mapping transport out of month?
- Pilot STOPPED at the purchase verdict per PM (SIGNED_FLOW_ADDS, sealed P&L).
- The 0DTE key-mapping 22-day frozen run remains staged (run_22day_frozen.sh, logic hash
  75c9d62f…) but is explicitly not the pilot's answer — launch only if PM wants the
  0DTE key-mapping adjudication extended to all 22 dates.
- If PM wants a stronger Cboe signal: the increment is minor; candidates are (a) more
  Cboe months (the CV is within-March because Cboe is March-only — more months would allow
  a cleaner leave-one-month-out and test regime stability), (b) richer Cboe features
  (per-expiry flow, OI changes, price/quote fields), or (c) a different target (magnitude
  rank rather than sign). None started.
