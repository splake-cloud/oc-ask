
## 2026-10-10 (later) — tierA_wave1 built (commit 48024a0a)

PM adjudicated the plan's open questions: (1) 8 Tier A cards approved, O26 joins the O32
family (not a new one), start with O36/O12/O17/O28 for breadth across 4 classes;
(2) all 6 pilot03 records assigned to training; O15 groups with RA07/RA08 (BPV-00020
work item); RA04 crosswalked against N4/N6 (same incident family, N4/N6 unused);
(3) O18+N13 one conservative family; N15 stays out; (4) /var/tmp evidence persisted to
`training_data/fixtures/source_snapshots/` (17 files, split-separated, hashed);
(5) accounting corrected to 23 pairs/3 SFT; (6) evaluation tightening adopted.

Steps executed: (a) source_snapshots persisted + verified (O12 pre-image 442 lines; O38/O41
code+inputs; O39/O40 evidence extracts with source_line_ranges); (b) split file v2
(pilot03_assignment, conservative_groups, dataset_accounting); (c) tierA_wave1 built:
`training_data/derived/tierA_wave1/` = 4 SFT trajectories + 4 preference pairs + 11 replay
fixtures + 10 verbatim fixtures + manifest + README + check_and_replay.py (PASS).

Key evidence facts: O36 draft has 7 stubs (L147,156,179,187,193,198,204) + "Pin it" at L171.
O12 config.ts diff section = 4 small hunks + `@@ -0,0 +1,1362 @@` at L42; 1373 '+' lines;
1362+1372=2734 matches the measured doubling. O17 = corrected verification doc (permission
deadlock per opencode#14473; poll hit non-directory-scoped route). O28: live data reproduced
both values exactly (MAX=6059.27, spot@1559=6026.73, n=73910, last_hhmm=1559).

Accounting after wave1: 27 preference pairs, 7 SFT trajectories, 0 dev, 0 final.

Next (PM-directed): Tier A wave 2 (O13, O12-remainder? — PM said start with the first four;
remaining Tier A = O13, O26, O30), then Tier B (16 text cards), dev set (7 families), final
set (10 families + freeze).

## 2026-10-10 (later): dev set + tierA_wave2 built

- **Dev set COMPLETE + pushed (ad960d44)**: 7 cases, one per dev family, under
  `training_data/derived/dev_set/`. 3 executable (O38 repair, O41 slice-probe, O39
  diagnosis — deterministic checks in check_dev.py) + 4 semantic (O40 honest-fail, O2
  taxonomy, O7 era labels, O10 rollout report — required/forbidden element rubrics in
  dev_scoring.md). Three scoring layers kept distinct: PERFORM / INTERPRET / COMPLETE;
  equivalent commands accepted. `--sanity` PASS (environments discriminate; O39
  reproduces the historical FAIL verbatim); historical post-repair artifacts pass all
  deterministic completion checks. O38 needs a synthetic input parquet (labeled); O41
  uses the historical 9,196-row probe input; O10 env is a labeled reconstruction (v1
  receipt never committed — every fact verbatim from the corrected receipt).
- **tierA_wave2 COMPLETE + pushed (ce03f09e)**: 4 cards (O13 sealed-target FAIL, O19
  watchdog elimination, O26 volume-vs-OI data check, O30 KA at ratified grain). Same
  contract as wave 1; preference format v2 (messages_prefix + chosen/rejected +
  split_index). Env snapshots of persistent density data (labeled): density_long 2024
  first 25 days (O26), concentration_paths year=2024 full (O30). O30 counts
  replay-verified: 37,836 ratified 5-min / 189,205 1-min (at-time 38,098/193,255 on the
  2026-08-09 data state — pool drifted slightly; lesson is integer-independent).
  check_and_replay.py all PASS.
- **Dataset accounting now**: 31 preference pairs (12 pilot01 + 5 pilot02 + 6 pilot03 +
  4 wave1 + 4 wave2), 11 SFT (3 pilot02 + 4 wave1 + 4 wave2), 7 dev, 0 final.
- **Next**: Tier B (16 text-comparison cards) → final set (10 families) + freeze.

## 2026-10-11: Tier B built + FINAL SET built + FROZEN (commit c8f52f2b, pushed)

- **tierB COMPLETE + pushed (adf391c7)**: 16 text-comparison cards (bank/receipt/
  session-grounded) in `training_data/derived/tierB_text_comparisons/`; corpus-field
  identity verified (7 fields × 16 records vs organic_seeds_v2.jsonl). Accounting:
  47 preference pairs total.
- **FINAL SET COMPLETE + FROZEN (c8f52f2b)**: `training_data/derived/final_set/` —
  12 final-split cards → 10 families, one original-context case per family. 5
  deterministic completion checks (check_final.py: o22_o25 4-row join/no-1399,
  o27 forward-ASOF gap slice, o31 vacuous-gate empty=REFUSED, o33 183/189 population
  check, o37 fail+{doctrine,hypothesis}) + 5 semantic (o8 confounding, o11 finding6,
  o23 scope-vs-trace, o35 verify-or-label, o42_o43 config scope + running-process
  diagnosis). At-time boundaries enforced: o42_o43 env excludes the verification
  POSTSCRIPT; o37 expected verdict withheld; o35 resolved DOI withheld (provenance
  only). --sanity PASS (5 environment-discrimination proofs; reference solutions pass
  their own checks; the defective backward-ASOF and legacy vacuous gate FAIL theirs).
  Verify: verify/final_set_final.20261011T012326Z.txt.
- **FREEZE recorded** in organic_seeds_split_v1.json evaluation_record (version 3)
  BEFORE any model result inspected: case list (family/card/case id/input hash),
  scoring criteria verbatim, criteria_hash c30f3967..., frozen_at 2026-10-11T01:26Z.
  Held-out but NOT blind (PM has seen incident summaries; freeze stops criterion drift).
  input_hash = sha256 over env/<case>/ files EXCLUDING reference_solution/ (answer key
  hashed separately as reference_solution_hash).
- **O35 fwg evidence resolved**: card cited host-side /data/seat/fwg/piagent/sessions/;
  in-container path is /fwg/piagent/sessions/ (same store, different root) — verified
  from host vantage (docker exec seat-fwg), L155-166 extract snapshotted to
  training_data/fixtures/source_snapshots/final/O35_fwg_doijoin_resolution/ (404 on
  guessed DOI 02091 + self-catch at L158-159 + resolved record 02072 at L161-163).
- **source_snapshots/ committed** (previously untracked gap, 828K/22 files): prior
  training/development snapshots (O12, O38/O41, O39/O40) built 2026-10-10 but never
  committed + final/O35 + manifests.
- **Delegation**: final_set build dispatched to qwen-coder (BUILD envelope over the
  construction spec .ai/final_set_construction_spec_20261011.md) + 3 follow-on EDIT
  missions (case-id alias fix; 2 dropped env files: o37 review_rubric.md + o42_o43
  next_use.md; 2 byte-level defects: o11 reconcile excerpt 'last error:' colon — my
  spec typo, delegate copied it faithfully; o31 environment_files dir-as-file). All
  bounces verified by me via verify-run; 6 verify transcripts committed.
- **Dataset accounting now (split file v3)**: 47 preference pairs, 11 SFT trajectories,
  9 dev cases (7 original + 2 restored O24/O34), 10 final cases (frozen). Construction of the full pilot corpus is
  COMPLETE for all three splits.
- **Next (PM-directed, from 2026-10-10)**: checkpoint/template conversion check BEFORE
  training, once the exact training model is selected (does not require occupying all
  three GPUs). SFT training prep is a parallel thread (see
  2026-10-11_qwen38_27b_sft_training_prep.md — canary built, GPU naming by hand).

## Pre-training gate (2026-10-11, session resumed after the 01a122b5 death)

- **Model selected + downloaded** (stale "once the model is selected" gates
  unblocked): Qwen/Qwen3.8-27B @ 1d4bf0f2ff6012fd82039f2fa52739d0dd7c60c0 at
  /data/models/qwen3.8-27b-bf16 (prep thread).
- **TMPLATE CONVERSION GATE COMPLETE + VERIFIED (commit 2568267ab)**:
  training/template_conversion_check.py — per-token loss-mask gate over ALL 58
  training records (11 SFT + 47 pairs incl. the 12 pilot01 text pairs) via
  CHUNKED TEMPLATING + PARTITION IDENTITY (spec v2: .ai/template_conversion_check_spec_v2_20261011.md)
  against the checkpoint's actual chat template. GATE: PASS, 0 violations,
  R1 7/7 exact vs the 7-record reference, T3 781/781 argument round-trips, no
  truncation (max 4325 < 8192). Key template facts discovered: assistant
  generation prompt = 7 tokens emitted between messages (belongs to the
  assistant span); template is linear (partition holds exactly); mask tokens
  = assistant spans only (e.g. binding: full 4325, mask 1593, user 621, tool
  2111). Independent verification: my own hand-rolled chunked template for
  pilot02_o20_binding matched the report's spans token-for-token.
  Verify: verify/final_set_conversion_gate{,_v2}.* (3 transcripts).
- **v1 spec mechanism withdrawn**: blanking-diff + LCP/LCS span capture is
  unsound for this template (over-captures structural tokens; all-blank sum
  cross-check can't hold). v1 spec kept on disk as superseded.
- **wave2_o26 defect caught by the gate + repaired**: DESCRIBE tool result
  (SFT msg3 + pair chosen msg1) stored as JSON list of 9 column names instead
  of the verbatim stdout string → TemplateError. Repaired by re-running the
  recorded command on env/O26/density_long_2024_sample.parquet (elements
  asserted identical); git diff surgical (exactly 2 lines); documented in
  tierA_wave2/README.md §Defect repair. Full-field scan of all 6 batch files:
  no other non-string content.
- **M-d amendment**: the gate's strict mask check surfaced
  pilot02_o20_probe_recovery msg1 (failed probe, assistant, mask=False) —
  INTENTIONAL, documented in training_pilot/README.md ("the already-failed
  probe in the recovery prefix is also masked"). Spec M-d amended: direction 1
  strict (loss ⇒ assistant), direction 2 = documented-exception set
  {(recovery,1)}; reported informational, not a violation.
- **TRAINING MANIFEST (training_data/derived/training_manifest.json)**: all 58
  records enumerated with per-line sha256 (58/58 verified), 41 families,
  SFT↔preference overlap map: pilot02 pairs = single-step extractions (chosen
  byte-identical to a parent SFT assistant message; prompt = SFT msg0), wave1
  pairs = exact SFT splits at msg1, wave2 pairs = exact prefix (SFT[:si]) +
  labeled non-verbatim continuation; cross-batch family overlaps (aug11
  density episode O32↔O26; 0dte-density O29/O28/O30; O20; sep29 O18+N13;
  bpv00020 O15/RA07/RA08; idea_review RA04/N4/N6); dedup rule = families are
  the independent units; dev (7) + final (10, frozen) explicitly excluded.
- **qwen-coder performance note** (diagnosed 2026-10-11, 4 dispatches):
  runs 1–2 bailed mid-diagnosis when the mechanism they were given was
  self-contradictory (my spec defects: v1 M-c unsound; v2 generation-prompt
  ownership prose-vs-formula contradiction); run 3 (patch-level spec + numbered
  acceptance criteria) delivered exactly; run 4 (one-line fix) exact. Lesson:
  this model's envelope = fully-determined, mechanically-checkable chunks;
  the debugging loop stays with the main seat. It never fabricated a PASS or
  touched the corpus.
- **Canary step: PASSED (bf16, GPU1, 2026-10-11)**. Sequence: PM cleared GPU1;
  4-bit run loaded fine (18.6GB) but OOMed at step 1 (4325 tokens, 94.9/94.97GB)
  — receipt `training/canary_result_4bit_oom.json` (sha256
  2d5d7d74b35f…). **DIAGNOSIS CORRECTED (PM)**: this does NOT establish a
  Blackwell/bnb incompatibility; the 54GB-upcast explanation was retracted as
  speculation. Missing gradient checkpointing + use_cache enabled are ESTABLISHED
  CONFIGURATION DEFECTS in the canary; their exact contribution to the 4-bit OOM
  is NOT isolated by the bf16 retry (precision changed too), and the 94.9GB must
  not be labelled entirely as saved activations. After the
  fix (checkpointing ON + use_cache=False, asserted in `config_verification`;
  OOM handler now captures full traceback + memory_summary + requested alloc),
  the **bf16 canary PASSED**: 10/10 steps, peak 58.28GB (≈36GB headroom on
  96GB), 427 tok/s, ADAPTER_UPDATE PASS (fraction_changed 1.0,
  grad_norm_step0 1.57), SAVE_RELOAD PASS (CPU tensor_compare max_diff 0.0;
  real-reload forward loss_diff 0.0). Receipt `training/canary_result.json`
  (sha256 912cdbca4f33…), log `training/canary_run5.log`, asserts deposited
  via verify-run. Two latent device-placement bugs found+fixed on the way
  (CPU tensors → CUDA model; disk adapter CPU vs GPU compare — now compared on
  CPU per PM spec). Also fixed: canary's NameError (`batch_size` scope) +
  assertion path now writes result JSON. NOTE: the 4-bit result's
  `total_params` 15.03B is a bnb storage-numel artifact; the model is the
  full 27.44B VLM in both runs. Real-SFT config decision (dtype/steps/lr)
  still PM's; bf16 single-GPU sufficiency is now measured, not assumed.
- **Checkpoint relationship + serving install (2026-10-11, CPU-only)** —
  `docs/model-kb/qwen38_27b_checkpoint_relationship_and_vllm_lora_20261011.md`:
  bf16 = Qwen/Qwen3.8-27B @ commit 1d4bf0f2 (pinned in .cache metadata);
  fp8 = Qwen/Qwen3.8-27B-FP8 UNPINNED (main, 2026-08-22), publisher README
  declares `base_model: Qwen/Qwen3.8-27B`. Structural compatibility proven
  (text_config byte-identical; 1199/1199 tensor names match, fp8 adds exactly
  407 weight_scale_inv for 128×128 blockwise e4m3/dynamic; 7/7 shape
  spot-check; tokenizer vocab+special tokens+chat_template identical); NOT
  identical ancestry (unpinned download, lossy quant). Serving: BOTH :8011 and
  :8012 now run vLLM **0.30.0** (`.venv-vllm-0.30.0`, verified from live pids
  + drop-ins; :8011 moved 2026-10-11 after 3rd Xid-31 on 0.20.2); legacy 0.20.2
  env serves nothing but is still the bare-launch default. vLLM 0.30.0 source:
  Qwen3_5 supported (SupportsLoRA + packed mapping incl. in_proj_qkvz),
  blockwise FP8 handled by Fp8LinearMethod, LoRA wrappers delegate to the
  quant method's apply + punica delta post-quant (correct for fp8 dynamic
  act); VLM name-mapping machinery present. **Serving compat test PASSED
  2026-10-11**: vLLM 0.30.0 (explicit .venv-vllm-0.30.0 interpreter),
  reserved GPU1, temp port 8911, the 8011 deployment config + --enable-lora:
  FP8 blockwise checkpoint + canary LoRA adapter + MTP k=3 all coexist.
  Adapter targets map without unmapped-target warnings; application PROVEN
  at serving time (temp-0 greedy divergence at token 27, paired logprob
  diffs, base determinism control identical, _lora_shrink/expand kernels
  JIT'd during inference); tool-call request through the adapter returns a
  well-formed tool_call. 8011 config ratified as intended deployment config,
  subject to the substantive adapter passing the same test. FP8 copy pinned
  by full 81-file sha256 manifest (training/fp8_checkpoint_manifest.sha256);
  fp8<->bf16 ancestry still unresolved (operational compatibility, not
  ancestry). Real-SFT config stays provisional until the full manifest +
  token-mask report; working points (bf16, r16, mb1, checkpointing ON,
  cache off) preserved. Receipt: dev_set/serving_compat_20261011/receipt.md.
- **Dev baseline (step 4) EXECUTED** `baseline_20261011` (2026-10-11, commit
  d72b6a70d; O24/O34 restored same day): 9 dev cases vs untrained Qwen3.8-27B on
  the :8011 fp8 endpoint (PM-ratified deployment config; serving_compat pin).
  **Result: deterministic 3/3 PASS** (o38 a/b/d, o41 a, o39 a/b/c — all exit 0);
  **semantic 4/6 PASS** (o2, o7, o24, o34; **o40 + o10 FAIL on forbidden
  elements** — distinct observed errors, underlying cause UNPROVEN (do NOT label
  "calibration vs knowledge" — the run does not establish the cause): o40 =
  completion-judgment failure (verification failure treated as blocking report
  delivery); o10 = evidential overclaim (overlap inferred from same-second
  timestamps). Both within training objectives. PM: this single run = initial
  MEASUREMENT, not a precise success-rate estimate. **O24 + O34 restored** (was
  an omission — the planned dev set was 9 cards / 7 families; the built dev_set
  silently dropped them with no rationale). Built original-context (verbatim
  source; spec .ai/dev_o24_o34_construction_spec_20261011.md), run on the same
  pre-training model, **both PASS** (o24: re-check disk → report absent decisions
  file with path, no fabrication/self-derived KAs; o34: enumerate + mechanical
  count 27, correct receipt 26→27, core 27≠46 preserved). Scoring in
  rubric_sheets_o24_o34.md (same seat + method). **Split reconciliation (PM
  ruling 2026-10-11, verified 07299153d):** the earlier "overlap caveat" was a
  MISCHARACTERIZATION — O24/O34 were NEVER in active training. Verified: training
  split = 37 cards (no O24/O34); 37-pair export == that split exactly; manifest
  families_used_in_training (41) excludes them; every serialized SFT/DPO file +
  synthetic descendants clean by label AND content marker; canary (O20/O36/O20/O1)
  + FP8 serving-compat adapter clean. O24/O34 exist ONLY in organic_seeds_v2.jsonl
  = the 58-card "source cards unchanged" reference (provenance, not training) -> left
  intact. "47 -> 45" premise does not hold (active total unchanged). Forward: substantive
  SFT on a FRESH adapter over the untouched base. Restored o24/o34 = the SUPPLEMENTAL
  baseline wave (2-case concurrency, distinct from the 7-case wave) for runtime
  comparison. Receipt: .ai/o24_o34_split_reconciliation_20261011.md. **PERFORM 9/9.**
  These two failures are exactly what the recovery/probe training families
  target — the post-SFT delta against this table is the training signal.
  Scoring: qwen-coder (Qwen3.6-35B-a3b, :8081) — separate model from the
  running seat; the usual reviewer endpoint (qwen38-reviewer / :8012) was
  DOWN (http 000) and sits on a GPU the PM keeps clear (PM: don't use it).
  Author/reviewer separation preserved by model. Harness wrapper documented
  in run_metadata.json (identical preamble → post-SFT run replicates it).
  **GPU placement record correction** (discovered during scorer switch):
  :8011 = GPU0 (91.6GB active); GPU1 = EMPTY (2 MiB, the cleared GPU);
  the 2nd vLLM is on GPU2 (with RAG) and :8012's API is down — the
  2026-09-10 launcher header's ":8012 on GPU1" mapping is STALE.
  Receipt: training_data/derived/dev_set/baseline_20261011/ (README.md,
  baseline_table.md, rubric_sheets.md, rubric_sheets_o24_o34.md,
  comparison_anchor.json, per-case transcript+summary+check output, run_metadata
  .json). Final-set exclusion verified; no mid-run intervention. Final set +
  answer keys stay out of training and dev iteration.
- **GPU vantage fact (this pi seat)**: NOT sandboxed — net:[4026531833] host
  namespace, Seccomp 0, /dev/nvidia* present, nvidia-smi works directly. The
  bwrap/excludedCommands machinery in AGENTS.md describes the opencode seats.

## 2026-10-11: FP8 + LoRA adapter + MTP k=3 serving-compatibility test — PASS (commit 32b08fd65)

PM-directed **engineering** test (not adapter-quality): before substantive SFT, prove the
FP8 base + LoRA adapter + MTP k=3 coexist and serve on the production vLLM 0.30.0
combination. Reserved GPU1, temp server on port 8911 derived from production :8011 (only
+LoRA +port +GPU changed; context/concurrency/parsers/generation-config preserved). Receipt:
`training/fp8_lora_mtp_test_20261011/receipt.md`. All 5 PM items established:
1. **Full 256/256 adapter attachment, 0 skipped, 0 unexpected, dims match checkpoint.**
   Static (CPU, `verify_adapter_attachment_static.py`): resolve all 256 targets through the REAL
   vLLM `Qwen3_5ForConditionalGeneration.packed_modules_mapping` (qkv_proj/gate_up_proj) + the
   `model.language_model.` VLM prefix, validated against the actual FP8 checkpoint dims.
   Runtime (server load log): adapter loaded, **no unmapped-target warnings**. NOTE: the hybrid
   full-attn q_proj out=**12288** (48×256), not the naive NH×HD=6144 — a trap; dims must be read
   from the checkpoint, not the config formula.
2. **Adapter selection changes computation (PROVEN):** 3 synthetic prompts, greedy temp 0,
   logprob values differ at identical token positions (short 255/256, coding 21/21, ordinary
   29/29; max Δ 1.49/0.117/0.095), base-to-base repeat **bit-identical** (determinism control →
   the effect exceeds the base-to-base floor, which is zero). `prompt_logprobs` not returned by
   vLLM 0.30 `/v1/completions`, but the preferred identical-token-position comparison was achieved.
3. **Text + tool-call protocol PASS:** reasoning/content separated; `get_price` tool call parsed
   (`{"ticker":"AAPL"}`), content=null on the call turn, final response stop.
4. **MTP executes on adapted requests (PROVEN):** spec-decode counter delta on adapter-MTP =
   1168 drafts / 3504 draft-tok / 1902 accepted (per-position acceptance present).
5. **MTP speed benefit MEASURED = 2.01×:** adapter+MTP 83.89 tok/s vs adapter+MTP-off 41.80
   tok/s (base+MTP 89.42 reference; adapter adds ~6% overhead vs base, expected for rank-16×256).

Benign warnings recorded (not acted on): "no KV cache group identified as draft model's" (MTP;
still drafts/accepts), "Using default LoRA kernel configs". GPU1 restored to 2 MiB; production
:8011/:8013 unaffected throughout. 8011 config unchanged.

**De-risks serving the substantive-SFT adapter** with the same path (FP8 + LoRA + MTP) after
training. Method note: the standalone full-model LoRA-manager introspection HUNG (V1 multiproc
executor → process-boundary getattr deadlocks); the fast rigorous path is CPU static resolution
+ runtime log corroboration, not in-process model introspection. The 318MB canary adapter is now
in .gitignore (was untracked). Master now `32b08fd65`.

**Serving-side gates now cleared.** Remaining gate before substantive SFT: the **token-mask
report** (full deduplicated SFT examples + supervised-token counts) to fix the still-provisional
real-SFT config (accumulation/lr/total updates). Then: fresh adapter over untouched base →
post-SFT dev run (hash-check comparison_anchor inputs) → post-SFT serving smoke (this same
test with the trained adapter) → frozen final set.

## 2026-10-11: Full training manifest + token-mask report (commit 0ebe2acca) — the LR/batch/update-budget numbers

Read-only analysis over the frozen 58-record pool; establishes the 4 PM items to finalize the
real-SFT config (LR / effective batch / update budget). Report:
`.ai/full_training_manifest_and_token_mask_report_20261011.md`; spec
`.ai/token_mask_report_data_spec_20261011.md`; driver `training/token_mask_report_data.py` +
data `training/token_mask_report_data.json`. Reuses the PROVEN conversion-gate chunked-templating
(`derive_spans_chunked`; M-c' partition complete for all 58) — the tokenization is the one the
trainer will use, not a re-derivation. Independently re-run + invariants via verify-run
(`verify/token_mask_final_dists.*`).
1. **Clean split PROVEN** (3 levels: card + manifest-family + raw record content): zero dev/final
   leakage into any of the 9 training files. (9 training files carry 47 raw family labels vs the
   manifest's 41 independent families — grouping, not a violation.)
2. **SFT composition: 11 tool trajectories + 47 chosen-text = 58 examples, 41 families.** Hot
   families O20=6, O29=4, eight families =2, rest =1. 13 SFT-counterpart pairs (5 pilot02 sub-span +
   4 wave1 full-split + 4 wave2 non-verbatim); the 4 wave1 pairs are content-identical to their
   trajectories → dedup 58→54. The 9 pilot02/wave2 same-incident pairs = a WEIGHTING decision, not
   a byte-dedup. (Data detail: wave2 SFT record + wave2 pair SHARE the same record id, e.g.
   wave2_o13 — build id-keyed maps separately for SFT vs pairs.)
3. **SFT token accounting:** total supervised **14,247** (raw) / **12,724** (dedup); max full-seq
   **4363** (thinking-on) → NO truncation at max-seq-len ≥ 4400 (canary used 8192). Tool-call tokens
   included in supervised; tool results + failed-probe prefix masked (known-answer
   pilot02_o20_probe_recovery full=2692/supervised=602 = recovery msg3+msg5, not the 410-token
   failed probe msg1). Thinking-on adds only wrapper overhead to full length, NOT supervised
   (authored trajectories have no reasoning content).
4. **DPO accounting (47 pairs):** chosen branch total 9,792 (max 1,085) vs rejected 2,279 (max 89) =
   4.3× asymmetry (correct full action-tail vs brief wrong claim); continuation-only masks; DPO
   pair max-length must be ≥ 1,085 (chosen arm).

**Pair-mask BUG found + fixed (delegate EDIT):** pilot02 pairs store chosen/rejected as bare
assistant messages with NO `loss` field (unlike wave1/wave2) → the script's over-strict
`loss is not None and loss` counted them 0 supervised. Fix: `loss is None or bool(loss)` (supervised
by role unless explicit loss=False); wave1/wave2 unchanged. Caught because SFT chosen-text supervised
min was 0 (a red flag) — the update-budget total would have been undercounted.

**Config implication (the point of the report):** a SMALL LoRA SFT set (~13–14K supervised
**tokens/epoch**). → moderate-low LR (avoid overfitting), gradient-accumulation to set effective
batch (raw total / (eff_batch × seq_len) = updates/epoch ≈ 2 at 1×8192; grad-accum → effective 8×8192
≈ 17–20 updates/epoch), low epoch count (2–3), monitor the DEV set (not final) each epoch. Master now
`0ebe2acca`. Remaining gate: PM sets LR/batch/epochs on the token counts → SFT on a FRESH adapter
over the untouched base (canary stays an engineering artifact).
