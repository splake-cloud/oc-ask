# Qwen3.8-27B fine-tuning: external research + local adapter target audit

Session 2026-10-15, pi main seat. Two deliverables: (1) tier-1 web search on fine-tuning
qwen3.8-27b (dispatched to `search_agent`, web_search+web_fetch only, all claims sourced);
(2) audit of the 7 local adapters against the research's DeltaNet-target finding.

## Audit finding (the load-bearing one)
**All 7 local adapters leave the 48 Gated DeltaNet layers' attention completely unadapted.**
- Verified from adapter weights, not just config: sft_run2 epoch_3 `adapter_model.safetensors`
  = 512 tensors = 256 A/B pairs = 64 FFN (gate/up/down × all 64 layers) + 16 full-attention
  layers × (q/k/v/o). Zero `linear_attn.*` / `in_proj*` modules.
- Same standard-7 target list in every adapter: sft_run1 epoch_1–3, sft_run2 epoch_1–3,
  `.canary_adapter_check`. All r=16, alpha=32, dropout=0.05, bias none.
- Origin: `discover_lora_target_modules()` in `training/sft_run1_train.py:81` and
  `training/sft_run2_65_train.py:81` (and `smoke_1gpu.py:107`) — leaf-name match against
  {q,k,v,o,gate,up,down}_proj; `in_proj_qkv`/`in_proj_z`/`out_proj` structurally excluded.
- `verify_adapter_attachment_static.py` + `training/adapter_attachment_static.json` KNEW the
  hybrid structure (n_full=16, n_linear=48; vLLM's `in_proj_qkvz`/`in_proj_ba` mappings are
  even listed in the artifact) and printed PROVEN — it validated adapter↔intended-design
  consistency, not design completeness. The gap passed every gate that existed.
- Impact (precise): the adapters adapt the FFN on all 64 layers + full-attention projections
  on the 16 full-attention layers; the 48 DeltaNet layers' projection WEIGHTS are frozen by
  the adapter (not modified). Those layers still compute — their activations and output
  contribution change as the adapted layers change their inputs. "Frozen" = weights only.
  The community's "two thirds untouched" phrasing describes parameter coverage, not
  functional irrelevance of the layers.
- Broader targeting is OPTIONAL, not a defect: adding `linear_attn.in_proj_qkv`,
  `in_proj_z`, `out_proj` is a PM design decision, not a repair. A retrain A/B would need
  FRESH cases (both the 9-case dev set and the 10-case final set are already examined —
  see PM corrections below); neither is fresh held-out evidence.

## External research — key findings
- **Mapping**: qwen3.8-27b = public `Qwen/Qwen3.8-27B` (HF, released 2026-08-13), dense 27B
  native VLM, built on Qwen3.5 architecture: 64 layers = 48 Gated DeltaNet + 16 full-attention
  (every 4th: 3,7,…,63), hidden 5120, vocab 248,320, 262k native ctx, Apache-2.0, thinking
  mode on by default. `model_type: qwen3_5` is shared across Qwen3.5/3.6/3.8-27B; the brand
  pins the generation.
- **No official recipe**: HF model card has NO fine-tuning section (probed). Qwen-recommended
  frameworks: Unsloth, Swift (ModelScope), LLaMA-Factory. Paradigms SFT/DPO/GRPO.
- **Unsloth guide (the de-facto official recipe for this arch)**: transformers v5 REQUIRED
  (we have 5.19.0 ✓); bf16 LoRA 27B ≈ **56 GB** planning figure. Local fit measurements
  (newest first): **P4E fit canary 2026-10-15 — peak PyTorch allocation 73.237 GiB /
  reservation 74.936 GiB** (bf16 base + bf16 adapters, 79,691,776 adapter params, r=16/
  alpha=16, 21,702 input tokens, 4 exposures/1 optimizer step, GPU1; `training/
  p4e_fit_canary_20261015/README.md`). The older 58.28 GB was the 2026-10-11 bf16 canary
  (smaller setup). Added parameter storage is only PART of training memory; the memory delta
  of the extended (400-target) set is UNMEASURED — do not claim "negligible". **QLoRA 4-bit NOT recommended** ("higher than normal quantization
  differences" on Qwen3.5 dense) and one hands-on author reports bnb dequantizing DeltaNet
  `in_proj_z` to the wrong shape; FFT ≈ 4× LoRA VRAM; keep **≥75% of rows reasoning-style** to
  preserve reasoning; `flash-linear-attention==0.4.1` needed for sample packing (Axolotl);
  #1 export gotcha = wrong chat template/EOS at inference; vLLM 0.16 doesn't serve Qwen3.5
  (we run 0.30.0 ✓).
- **Hyperparameters — no consensus**: r ∈ {8 (NeMo), 16 (Unsloth/Yotta/runaihome), 32};
  alpha ∈ {16, 32}; lr ∈ {1e-4, 2e-4}; epochs = 1 near-universal. The hands-on author found
  **exposure count** (up-sampling target items ~6×) moved the score more than any of r/lr/steps;
  94% fidelity on *how* to answer vs ~4% on *what*.
- **Other gotchas** (Medium hands-on write-up): merge can silently return the base model
  (path mismatch; diff merged shards vs base, fail on empty AND unchanged comparison);
  `HF_HOME` must be set before any import; never `enable_thinking=True` in
  `apply_chat_template` during training (duplicate think tags); `dataset_num_proc=1` +
  `dataloader_num_workers=0` (>1 deadlocks after 27B load); **validation loss is inversely
  correlated with accuracy** on this fine-tune → don't `load_best_model_at_end`; it's a
  unified VLM (processor, not tokenizer; use FastModel); same `reasoning_effort` on every row
  inverts the effort ladder post-training.
- **Community sentiment** (r/LocalLLaMA): newer Qwens "very hard not to break"; narrow-domain
  / few-thousand samples works, broad capability doesn't; ~8–10k complex-CoT samples to
  "budge" a 27B, 50–60k to "push it around"; distilling a larger model in made it worse;
  works better from base than from a finished instruct model.
- LLaMA-Factory: Qwen3.8-27B-Instruct support issue #10823 (opened 2026-09-08) now closed;
  resolution not visible in snippet.

## Not established
- FFT VRAM irreconcilable as stated (Axolotl `27b-fft` ~53 GiB vision-frozen vs Unsloth "4×
  LoRA") — different base precision/offloading.
- No Blackwell-96GB *training* report for this exact checkpoint (inference-fit estimates only).
- NeMo recipe (r8/alpha32/lr1e-4) is a smoke test, seen via secondary source only.
- Whether adding the DeltaNet targets actually improves OUR eval — needs the A/B.

## Sources (primary first)
- https://huggingface.co/Qwen/Qwen3.8-27B — model card, 2026-08-13 (primary)
- https://unsloth.ai/docs/models/qwen3.5/fine-tune — 2026-08-13 (primary, framework)
- https://docs.axolotl.ai/docs/models/qwen3.5.html — updated 2026-10-13 (primary, framework; DeltaNet targets, FLA, yaml recipes)
- https://medium.com/@ishaafsalman/fine-tuning-qwen3-8-27b-what-breaks-and-how-to-fix-it-d77dc46e0745 — 2026-09-02 (community, hands-on; the gotcha source)
- https://runaihome.com/blog/fine-tune-qwen38-27b-unsloth-rtx-4090-2026/ — 2026-08-29 (community)
- https://www.yottalabs.ai/post/how-to-fine-tune-qwen-3-8-27b-with-unsloth-2026 — 2026-08-18 (community/vendor)
- https://www.reddit.com/r/LocalLLaMA/comments/1uflcup/qwen_36_27b_glm_52_finetune — ~2026-07 (community)
- https://github.com/hiyouga/LlamaFactory/issues/10823 (community)
- https://docs.nvidia.com/nemo/automodel/model-coverage/vision-language-models/qwen/Qwen3.8-27B (primary, secondary-viewed)
- https://iqilian.com/learn/qwen38-mingzi-yu-qwen35/ — 2026-08-16 (config analysis)
- Serving-side community issues: sglang #27212, mlx-vlm #2186, Soup #514.

## PM corrections 2026-10-15 (binding — amend the above)
1. **Agreement is the finding, not completeness.** The load-bearing property is that
   TRAINING SELECTION, ATTACHMENT VERIFICATION, and SERVING CONFIG must agree (they do —
   that is why attachment is 256/256 clean). A verifier should REPORT per-family coverage
   and ENFORCE the declared target set; it should NOT fail merely because an attention
   family is intentionally frozen. "Design completeness" as a gate is withdrawn.
2. **Memory claim unproved.** Added param storage (~29.1M LoRA params ≈ +36% of the current
   ~79.7M) is only part of training memory; the P4E peak (73.237 GiB) is the latest
   measurement and was not used when "negligible" was claimed. Unmeasured = unmeasured.
3. **Count**: extended set = 256 + 144 = **400** modules (an earlier "399" was arithmetic
   error).
4. **Evaluation baseline is the completed record, not the first dev table.** Completed run2
   record: **adapter arm 27 attempts: 24 PASS / 2 FAIL / 1 GUARD**
   (`run2_eval_repeat_20261012/REPORT.md:116`); final frozen set (10 cases × 2 arms,
   COMPLETE 2026-10-13, `final_eval_20261012/`): adapter 9 PASS / 1 FAIL (o37), base
   8 PASS / 1 FAIL / 1 GUARD (o22_o25). Both guards were later re-labeled **detector false
   positives** (trigger 2: >50% of last 64 chars identical on structural characters —
   markdown table separator / code indentation; `detector_fix_note.md` +
   `guard_cause_note.json`, PM order 2026-10-13). Official outcomes UNCHANGED — cause-label
   correction only. The 9-case "7/1/1" dev table is a stale partial view.
5. **No module-family inference from single failures.** "O40 smells like attention/routing"
   is speculation — a failure does not identify which module family needs adaptation.
   Revisit triggers must be evidence-based (e.g. an A/B result), not module guesses.
6. **The final set is already examined.** It cannot become fresh held-out evidence by
   re-running it. A/B for a retrain needs new cases (or explicit labeling as dev evidence).
7. **aagent is running a smoke addressing the DeltaNet target issue** (2026-10-15); results
   to be posted. Stand by — do not launch a competing smoke/retrain from this thread.

## Next (if PM picks it up) — supersedes the pre-correction list
1. Await aagent's DeltaNet smoke results; fold them into this card.
2. If the declared target set changes: update `discover_lora_target_modules` + static
   verifier expectations (enforce the NEW declared set, report per-family coverage) +
   serving `--lora-target-modules` launch args — the three must move in lockstep.
   If it stays standard-7: document that as the ratified declared set (decision, with
   rationale + revisit trigger), so it is a known decision rather than an inherited default.
