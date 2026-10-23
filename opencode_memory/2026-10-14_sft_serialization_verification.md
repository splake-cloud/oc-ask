# SFT serialization verification + PM corrections C1–C6/W5/A1–A2 (2026-10-14d)

**Session:** pi seat jett-8011 / qwen3.8-27b-fp8, resumed from `HANDOFF_20261014d.md`
(`training/sft_trainer_repair_20261014/`). All CPU-only.

## Done this session

1. **C3 role-assignment proof COMPLETE — ALL PASS, all five windows**
   (`verify_labels.py`, transcript
   `verify/sft_serialization_c3_proof_20261014d.20261013T055537Z.txt`):
   - P1 from-scratch char-level re-derivation of the pinned
     `chat_template.jinja` is **byte-identical** to the tokenizer's full render
     (W1–W5); P2 `encode(render) == render_ids`; P3 merge-local role
     assignment (no foreign token inside any role span, no uncovered block
     material, **0 boundary-straddler tokens**); P4 recorded label spans ==
     from-scratch LCP spans message-by-message.
   - The 84 "boundary merges" (26/31/3/18/6) are **template conditionality,
     not BPE**: the tool block closes with im_end+newline only when
     `(not last and next != tool) or last`; a prefix ending at a tool message
     carries a closing the full sequence lacks. Full render stays correct;
     spans tile; displaced tokens stay in-tool-role.
   - Three transcription bugs found+fixed via char-level ord dumps: (1) the
     tool-call open control token precedes the `<function=...>` line in
     **every** tool call (all three prefix variants); (2) tool-response
     wrapper tags were missing angle brackets + closing `>`; (3) non-string
     tool-call argument values use the template's `tojson` = `json.dumps`
     **default separators + `ensure_ascii=False`** (compact/ascii dump was
     wrong).
   - Part B: 0/197 assistant turns carry `reasoning_content` (vacuously
     identical). Part C (TRL 1.15.0): pinned template has no
     `{% generation %}` markers, is string-equal to TRL's canonical qwen3_8
     template, `is_chat_template_prefix_preserving=True`; with the unpatched
     template `assistant_masks` sums to 0 → **all labels -100** (nothing
     supervised) if `assistant_only_loss` is used; `get_training_chat_template`
     patches the template (adds markers, warns at tokenize time);
     `DataCollatorForLanguageModeling` consumes pre-built labels as-is (pad
     -100 right); TRL prompt-completion boundary on W3 leaves the final
     assistant turn's opening scaffolding (16 tokens) unsupervised.

2. **W5 review COMPLETE.** Range 238–353 verified against the raw session
   (sha256 `1ffb2cb7…`): #238 = R1 task (line 241), #353 = "R1 complete —
   committed f079b0dd8" (line 358), #354 = next user msg (the **R1c** base
   control — the packet's "R1b task" label is a misnomer; memcheck R1b ran
   after R1c). 116 msgs = 1 user + 55 assistant + 60 tool; **single real user
   message** (handoff watch item closed). Superseded diagnoses flagged (all
   supervised turns): **S1** "faulting op is not a regular kernel launch —
   async D2D memcpy" (#330/#335/#347/#353) — superseded by R1b (XQA
   `kernel_mha`, MTP drafter propose path, 136 invalid 16B reads at garbage
   paged-KV offset); **S2** "GDN/mamba prefill state handling" (#339/#347/#353)
   — superseded by R1b; **S3** "#353 R1c disjunct: no crash ⇒ LoRA/punica
   input-prep path" — partially superseded (fault is in XQA decode kernel
   path; mechanism still unidentified per R1b PM qualification). NOT
   superseded: byte-exact 12,568 reconstruction, fallback/JIT refutation,
   latched-fault semantics (step-1 = first 9600-tok chunk incl. drafter),
   index-driven OOB pattern. New post-window findings (not supersessions):
   R1d (XQA-off completes single request), R1e (second fault surface
   `lora_shrink` on LoRA lm_head logits path at ~20.6K; workaround necessary
   but not sufficient).

3. **C4 table + 2026-10-14e CORRECTION (load-bearing):** the 2026-10-14d
   finding "pi never persists assistant reasoning" is **RETRACTED — it was a
   serializer bug, not a harness fact**. pi records thinking under each
   thinking block's `thinking` key (2560/2560 pool blocks); the 2026-10-14c
   serializer read the block's `text` key (empty) and silently dropped it
   (`serialize_windows.py:130`). All five windows re-serialized with recorded
   reasoning restored (W1 41,699 / W2 58,939 / W3 0 / W4 7,772 / W5 879,145
   thinking chars; pool 37/40 sessions, 6,234,689 chars). Effort line first
   followed the RECORDED level (instructions-as-recorded; W1–W4 medium, W5
   mixed) — **REVERTED 2026-10-14f** (item 5 below). P1–P4 + reasoning
   byte-identity re-verified (transcript
   verify/sft_serialization_rethink_20261014e.20261013T061358Z.txt, exit 0).
   Part C2 "16-token" offset decomposed: effort-line delta + 4 genuine
   gen-prompt scaffolding tokens. **W3 window-level:** cross-model
   (qwen3.6-35b-a3b-q8, not the base) + that model emits no thinking → all
   28 turns supervise an empty-think scaffold the model never produced. **W5
   EXCLUDED from initial training candidates** (PM decision 2; serialization
   test only). **W1–W4 turn-level review COMPLETE**
   (`SUPERVISION_REVIEW_W1W4.md`): 142 turns, 13 masked (17,120 tokens: 2
   atomic-batch edit failures, 7 CLI-schema guesses after self-truncated
   help, 3 self-authored code bugs), 1 FLAG (W2 T56 "not a blocker" reconcile
   dismissal, 449 tok). Every failure self-detected ≤2 turns and recovered.
   PM decisions of 2026-10-14e recorded in REPORT §8.6.

5. **2026-10-14f: effort REVERT to the wire value + content rulings** (PM
   message). The seat's original hard-coded `low` was the value **as recorded
   at the wire** (frozen serving config `reasoning_effort: low`); the
   per-message client `thinkingLevel` (medium/high) is a client-side record
   that **never reached the server**. Reverting matters because the pinned
   template renders **no** instruction sentence for `medium` at all
   (chat_template.jinja: only xhigh/low branches) — so the 2026-10-14e
   `medium` render had DELETED the sentence in every prefix the model actually
   saw. All five windows re-rendered at `low` (W5 unchanged); W1–W4 totals
   +26 each. Training@serving@`low` agree; the mismatch warning + the W5
   mixed-level limitation are moot. C3 proof re-run (transcript
   verify/sft_serialization_lowrevert_20261014f.20261013T063742Z.txt, exit
   0). Final totals: 71,232 / 123,166 / 43,299 / 53,935 / 121,969; supervised
   165,808 of 413,575 (the 2026-10-14e §3 total was mistyped 313,538; the
   sums give 413,497 medium / 413,575 low). **Content rulings:** W2 T56 →
   MASK (reconcile output names no facts — unevaluable; completion claims
   stand on independent evidence: report persists, SEMANTIC_KASA step in
   ledger, study BUILT→EXECUTED→VALIDATED→CLOSED with PM ratification); W3
   held out of the first reasoning-preserving slice for the
   empty-think-scaffold form ONLY (cross-model is NOT grounds —
   distillation-compatible), preserved for a separately validated
   non-reasoning representation. **Label verification** (`verify_turn_masks.py`,
   transcript verify/sft_turnmask_labels_20261014f.*.txt, exit 0): the 14
   masked turns are -100 in the actual label tensor, recovery/target turns
   still supervised. **Final numbers (post-mask):** W1–W4 target-only
   82,448/100,017 (82.4%); initial candidate set W1+W2+W4 = **70,360**
   (70,809 − 449). Every aggregate now labeled with window scope +
   pre/post-mask.

4. **REPORT.md amended** (originals preserved in §7 amendment block;
   2026-10-14e adds §8): C1 (100 steps = 50 passes, not 80 — transformers
   5.19.0: `num_update_steps_per_epoch = 1 + (5%4>0) = 2`), C2 (32,768 = output
   allowance `max_completion_tokens`; context limit = `max_model_len: 262144`),
   C3 (§7.3), C5 (the 19 tool trajectories DO carry schemas — bash ×18,
   bash+read_file ×4; my claim checked the wrong artifact; F14 census
   correct), C6 (memory labels "plausible/at the edge" withdrawn until
   canary), W5 (§7.5), A1 (mid-segment chunking retracted as an option;
   complete segments, drop-and-report windows that don't fit), A2 (five
   windows = serialization **sample**, not agreed training corpus), §7.9
   (C4 finding — RETRACTED by §8.1), §8.7 (masked-column + remainder-policy
   corrections).

## Step 7 — datadesign independent verification of the five windows (2026-10-13 run)

PM spec (step-7 of the datadesign pipeline): independent verification of the
seat's W1–W5, label-encoding check with persisted label artifacts, labeled
accounting, W2 structural evidence, segment-inventory redo, superseded
adoption plan. Authoring+execution by this seat (the plan's "Claude authors,
seat reviews and runs" split was inapplicable — the PM addressed the whole
step to the seat; independence is via re-derivation, PM review follows).

- **Run PASS:** `training/datadesign/runs/step7_20261013T074631Z/`
  (RECEIPT overall=PASS: 5 scripts rc=0, leak 0, manifest sha unchanged,
  scope gate clean). Commits: `ee343e084` (step) + `3c2db47ee` (step log).
  No push.
- **Verification (5 windows re-derived from raw, 10/10 agreements each):**
  render bytes (A1), per-message spans (A2), totals, by-class, prefix/supervised,
  system-text hash, tool-schema hash, source range, held-out fence — all equal
  the committed packets. F1 confirmed fixed; F2/F3/F4/F8 open as documented;
  F5 moot-with-record (1 in-window compaction in W5, 10,365-char summary,
  silently dropped by raw_to_openai); F6/F7 partially addressed.
- **NEW finding (independent):** the "byte-verified against R1" claim is
  UNMET for the full string (28,015 vs 27,892). Decomposed exactly:
  (a) recorded-only — the AGENTS.md control-token-rule paragraph + its
  2026-10-12 comments (added after request A was captured); (b) R1-only tail
  — sub_agent_context + active_agent(general-purpose) + Environment block
  (request A was a sub-agent invocation; the W5 replay session is the main
  seat). Content difference between two sessions' system prompts, not a
  reconstruction-rule failure (A6 covers the join rule).
- **NEW finding (F4, made real):** pi stores parentSession as a file PATH —
  the seat's `held_out_check` parent regex is vacuous on paths too.
  Rederived parents: W1 01a11e53, W2 01a11845, W3 01a12d18, W4 01a11738,
  W5 none — none in the exclusion fence (outcome correct, now by check).
- **W5 user-turn re-review: exactly ONE user message in 238–353** (the R1
  task, 625 chars, at the window boundary). Confirms the earlier "single real
  user" finding.
- **Label check PASS** (`step7_verify_labels.py`): masks parsed from
  SUPERVISION_REVIEW_W1W4.md (14 rows incl. T56, table==summary cross-check);
  14 masked turns −100 (was supervised pre-overlay), all TARGET turns
  supervised; ratified 70,809/70,360/82,448/T56=449; low-effort sentence in
  each slice prefix; think blocks byte-identical (26/56/32); **artifacts
  persisted** (gitignored) — W1 sha256 3001c5af…, W2 e57fe611…, W4
  405267fb… — the bytes a trainer must consume; receipt records the hashes.
- **Accounting PASS:** 413,601 (5-win, low era) / 291,632 (W1–W4, low);
  413,497 / 291,528 (medium era, labeled superseded); 165,808 / 100,017
  pre-mask supervised; 70,809 / 70,360 candidate target-only. **Flagged in
  REPORT.md (reported, not fixed, per scope):** 413,575 → 413,601 (the +26
  revert delta was applied 3× instead of 4×), 247,767 → 247,793.
- **W2 structural evidence:** 56 turns, 86/86 call-result pairs, 5 raw error
  results, 7 artifact-write turns, final turn pure text (complete); no text
  committed — T56's completion support is now judgeable from the pairing.
- **Segments redo PASS:** 144/118/51 reproduced exactly with per-session
  system-text prefixes (seat recovery) on raw files. Prefix median 5,680
  tokens (vs 12,010 for the R1 capture) → fit beside median prefix:
  60/82/115 at 16,384/32,768/65,536 (was 26/77/112); recovery 6/15/31.
  Token estimates slightly lower (median 18,912 excl. prefix vs 19,707).
- **Deliverables:** packets step_7.md/step_7_seat.md; 5 step7_*.py +
  run_step7.sh; superseded/adoption_plan_20261012.md (PM-noted contradictions
  at head: "charter is actually backward" + triage-order ruling + superseded-
  fixtures redirect, all quoted verbatim; plan text reconstructed from
  session ce4296e2 — the original plan file was overwritten); README
  step-log row + reader-limitation note; INSTALL_CONFIRMATION note.
- **Verifier-bug lesson (mine):** Python text-mode `open().read()` applies
  universal-newline conversion — W5's 111 tool-output carriage returns
  (95 CRLF + 16 lone) were silently normalized, faking a 95-char render
  mismatch. Byte-faithful comparisons read binary. The seat's render is
  byte-exact (git blob == disk == re-derivation, 111 CRs).

## Step 8 — bounded lake harvest on the 40 copied sessions (2026-10-13 run)

PM spec: apply the ratified serialization at lake scale — smallest reviewable
candidate set, every PM rule exercised, CPU-only, nothing new read from the
live lake. Authoring+execution by this seat (as step 7).

- **Run PASS:** `training/datadesign/runs/step8_20261013T082219Z/`
  (RECEIPT overall=PASS: harvest/labels/digests rc=0, judge off, leak 0,
  manifest sha unchanged, scope gate PASS; 58 s wall, 16-worker pools).
  Commits: `6de64375c` (step) + `350d544e0` (step log). No push.
- **Result: 144 segments → 127 windows + 17 excluded** (all
  `state_lost_to_compaction`; ledger closes). Aggregates: **5,722,393 total
  tokens / 1,893,158 supervised pre-mask / 1,831,372 post-mask**; 72
  first_attempt masks (each with evidence); completion 105 verified / 10
  completed-then-interrupted / 12 unresolved.
- **Seat cross-check (in label_check.json, asserted):** W1/W2/W3/W4
  whole-session windows reproduce the ratified 2026-10-14f totals exactly
  (71,232/123,166/43,299/53,935) and pre-mask supervised (20,029/47,990/
  12,756/19,242); the W5 window (238–353) is excluded with the F5 compaction
  reason. 5-window sample re-derived from raw: file/message/label hashes OK.
- **F2/F3/F4/F8 closed at source** (in the harvest code, not patched in the
  seat dir): per-message loss on every message; tool schemas verbatim in the
  record; working parent-path fence check (pi stores parentSession as a file
  path); exclusion ledger with a reason per rejected segment.
- **First-pass mask rule as code:** assistant turn with an isError tool
  result + a corrected call (same function name, different normalized args)
  within 2 assistant turns → `first_attempt`, loss 0; corrected call and
  completion turn targets; everything else target pending review. Deterministic,
  evidence per mask, review-overridable.
- **Completion evidence (structural, documented in code):**
  verified_completion = last msg assistant+text+no tool calls;
  completed_then_interrupted = last assistant turn has BOTH text and tool
  calls; unresolved = anything else.
- **NEW gray zone surfaced (PM ruling pending): 52 windows flagged
  `context_fidelity: post_compaction_summary_omitted`** — segments that
  START after a session compaction. The PM's in-range rule doesn't fire for
  them (the compaction entry isn't inside the segment), so they're kept,
  but the serialization omits the compaction summary the model actually saw.
  Flag is per-window in the record/manifest/INDEX for corpus-selection
  adjudication. 6 sessions carry compactions (17 segments excluded in-range,
  52 flagged after).
- **NEW finding: 3 session pairs share an 8-char (UUIDv7 timestamp) prefix**
  (01a11cdc, 01a120a3, 01a122d6 — parallel launches, same ms). Window ids use
  the first 13 session-id chars; the harvest aborts on any id collision.
- **Vantage note:** renders must run under the pinned training venv
  (transformers 5.19.0). The system venv (5.12.1) renders W2 +1 token
  (123,167 vs 123,166) — caught by the 5-window sample re-derivation;
  re-run under the pinned venv: all 6/6 OK.
- **Judge pass built, default OFF** (`STEP8_JUDGE=1`): Data Designer harness,
  step-4 settings (:8011, qwen3.8-27b-fp8, effort low, 16000 max tokens, par
  2), 6-dimension 0–5 rubric, capped judge input (120K chars, cap recorded),
  prompt/raw output/config captured. Scores sort the review queue; never
  decide inclusion.
- **Deliverables:** step8_{harvest,labels,judge,digests}.py + run_step8.sh +
  packets/step_8{,_seat}.md; run dir: harvest_manifest.json, exclusions.json,
  label_check.json, digests/ (127 counts-only digests + INDEX.md review
  queue), RECEIPT.md (127 label-artifact sha256s = the trainer's binding);
  artifacts/ (windows.jsonl 21 MB, renders, 127 label files) gitignored.
- **Expected scale check:** plan said "on the order of a hundred windows" —
  got 127 (144 − 17 compaction). Consistent.

## Step 8 v2 + recon — window-unit change + PM 2026-10-13 rulings (2026-10-13 runs)

Supersedes the v1 step on the window unit only (segmentation/exclusions
unchanged). Commits: `138a349f7` + `e1087eb70` (v2 official run + log),
`2d8da217b` + `86a390fbb` (recon run + log). No push.

- **v2 window unit (PM spec v2):** window = [system] + msgs[fu..e] — one
  task WITH its full prior context; prior-task assistant turns carried at
  loss 0 (`prior_task_context`), only the task's own assistant turns are
  label candidates. Official run `runs/step8_20261013T160505Z/` PASS
  (harvest 125/127 → labels → digests → judge → guards; 16-worker pools;
  ~2.5 h wall). Aggregates: **35,938,874 total / 18,711,601
  prior-task-context / 1,893,158 supervised** (pre==post); completion
  105/10/12; fidelity 75 full / 52 flagged. Seat cross-check exact (W1–W4
  ratified totals, n and pre-mask); leak 0; scope PASS.
- **Mask gate FAILS as specified → zero first_attempt masks** in the v2 run
  (per the gate, no rule-derived masks anywhere; every task assistant turn
  is a target pending review). Pre-scan: the rule reproduced 8/13 of the
  known review masks; a second candidate rule (PM formulation) got 11/13
  + 21 extras (step8_gate_rule2.json, of record).
- **PM rulings 2026-10-13:** (a) W3 T14 UNMASKED → corrected review set =
  12 (T14 is a *target*: the corrected call of T12); (b) rule =
  **recall-only episode flagger, review decides** — the gate is diagnostic,
  not an application gate. Re-based verdict (step8_gate_corrected.json):
  own-result trigger **10/12** (W2 T18/T37 unreachable — the authoring turn
  carries no failure signal; the signal sits on the run turn one later),
  own-or-next trigger **12/12 + 32 extras**. `step8_flags.py` implements
  the flagger: **550 flagged task turns (398 recovered) across 81/127
  windows**, carried in records, digests (`[EPISODE ...]` lines) and INDEX
  (episodes column); zero loss/label changes (asserted byte-identical).
- **Judge ON (spec v2), first-ever live run, 127/127 scored** (qwen3.8-27b-fp8
  @ :8011). Contract history (receipt addendum): v1 prompt → 44 valid / 83
  malformed (empty responses + the model ACTING INSIDE the trajectory
  instead of reviewing it); v1 retries → 64/127; v2 prompt (explicit
  external-reviewer role + JSON-only contract) → all 63 stragglers valid in
  one attempt. Triage only — scores sort, never decide (PM rule). sft_value
  0–5 (median 3), completion 0–5 (median 4); rich flag vocabulary
  (instruction-violation, ungrounded-claim, overlong, mid-task-truncation…).
  Judge infra gained resume + retry (per-window re-queue on malformed).
- **Fidelity definition (ruling of record):**
  `post_compaction_summary_omitted` = context-accuracy flag, NOT a
  correctness check: the window's prior context begins after a compaction
  record and the serialization omits the compaction summary the model saw.
  Re-parse is separate (127/127 PASS).
- **Wire fact (pi 1.0.2 source) + version check:** the compaction entry is
  FIRST in the post-compaction context and projects to [systemMessage,
  summary] — the summary is a **user-role** message at position 1 =
  `The conversation history before this point was compacted into the
  following summary:` + `<summary>` + `</summary>`; systemMessage = the
  compaction-time system snapshot (text in `sections`). Version check:
  all 40 seed sessions header `version: 3` = pi 1.0.2
  `CURRENT_SESSION_VERSION = 3` → **MATCH**. Source-derived (no live
  post-compaction wire capture exists in the repo; R1/R1c first-request
  only) — the only untested layer.
- **Recon run (PM-approved closed form):** `runs/step8_recon_20261013T191140Z/`
  — 52/52 flagged windows reconstructed (step8_recon.py): splice in the
  compaction-time system snapshot (asserted byte-equal to session system
  for all 15 compactions in the 6 sessions) + user-role summary at the
  compaction position, kept entries from firstKeptEntryId, pre-compaction
  raw dropped, older in-range compactions project to nothing, context_edit
  with null replacement omits its target. All carry fidelity
  `summary_spliced`; **task tails byte-identical to the v2 run** (message by
  message). Labels recon-mode (seat cross-check inapplicable — the
  byte-identity assertion substitutes): **57,854 supervised tokens**
  (per-window 36,803/74,756/107,337); episode flags 191/137; digests.
- **Recon judge on qwen3.6 (PM offload):** mechanical triage runs on the
  smaller model — qwen3.6-35b-a3b-q8 loaded on **gpu1** via
  `CUDA_VISIBLE_DEVICES=1 scripts/launch_qwen36_35b_q8.sh --mode coder
  --no-think --parallel 2` (NOT the service: the unit pins gpu2 and qwen3.6
  was not on gpu2). **52/52 scored** (prompt v2); 5/52 needed ≥1 retry — qwen3.6 JSON-contract compliance < qwen3.8's; **8012 independent review PASS-WITH-NOTES** (REVIEW_8012_20261013.md: scores genuine/mapped/rubric-faithful 9/10 sample audit; corrected the 7→5 retry count; retry-seed filename collision fixed in step8_judge.py). Documented: recon and
  official runs use different judge models; per-run review queues are read
  within their own run.
- **Deliverables:** step8_{flags,recon,receipt_addendum}.py +
  step8_gate_corrected.json + run_step8_recon.sh + updated
  step8_{harvest,labels,digests,judge}.py + packets v2.1; receipt addenda
  in both run dirs (all values read from JSON, no hand-written figures).

## Invariants (unchanged)

Run 2 dir FROZEN; incident dir `training/sft_run2_incident_20261014/`; data
verification `training/data_verification_20261014/` (3259d6502); GPU paused
per PM, GPU1 idle, canary awaiting PM authorization; five windows committed
at b80cc1c49. venv `.venv-training` (transformers 5.19.0, trl 1.15.0,
torch 2.11.0+cu128). Base `/data/models/qwen3.8-27b-bf16` rev `1d4bf0f`.

## Open / next

- **PM verification against raw** (after official run + flag pass + commits
  landed — DONE this session): suggested 5-window check — re-render from
  raw under the pinned venv, compare task tails + loss fields; episode
  flags vs session jsonl (failure signal + same-target recovery); recon
  summary splice vs the session compaction record (prefix/suffix verbatim);
  aggregates from the manifests (35,938,874 / 18,711,601 / 1,893,158;
  recon 57,854). Judge: judge_summary.json review_queue.
- **Corpus selection** from digests/INDEX.md (+ judge review queues) — 179
  windows now available (127 full-context + 52 summary_spliced); the first
  reasoning-preserving slice is the 75 full-fidelity windows of the v2 run.
- **Post-canary length pruning** — per-window lengths recorded; prune after
  the GPU canary, recording each pruned window with its length.
- **Corpus selection (A2) — RULINGS APPLIED 2026-10-14f:** initial reasoning-
  preserving candidate set = **W1 + W2 + W4 = 70,360 target-only tokens**
  (post-mask). W5 out (serialization test only). W3 held out of the
  reasoning-preserving slice (empty-think-scaffold form) but preserved for a
  separately validated non-reasoning representation. W2 T56 masked.
- **GPU canary** (memory fit for 43K–123K; labels withdrawn) — awaiting PM
  authorization.
- **W3 non-reasoning representation** — separately validated, not started.
- **Live wire capture of a post-compaction request** — optional; would
  close the only untested layer of the wire fact (source-derived, version
  check MATCH).
- Committed 89b0f5d9b (2026-10-14d); 2026-10-14e re-serialization + review;
  2026-10-14f effort revert + content rulings + label verification. No push.

## Harness note (this session)

Raw chat-template control tokens in **my own tool-call payloads** corrupt
the transport (truncated bash commands; text turns parsed as fake tool
calls — "Tool command not found"). Tool *output* is safe. Keep raw markers
out of commands/edits/text: build them at runtime from tokenizer decodes or
string concatenation, write escaped forms in prose (AGENTS.md rule 10, now
with a measured mechanism).
