# 2026-10-20 — Form-T public tranche (three-state SFT, 113 packets)

Built the three-state (ESTABLISHED / AFFIRMATIVELY_NEGATED / NOT_ESTABLISHED)
public-data SFT tranche per the mission spec. Committed on master as
`40678bdce` (Agent-Print: jett-8011 qwen3.8-27b-fp8).

## What was delivered

- `/data/agentic_trading/training_data/derived/formt_public_tranche_20261020/`
  - 130 authored packets → **113 final** (103 train + 10 eval)
    = 42 not_established / 43 established / 28 affirmatively_negated
    (CNLI 54, AVeriTeC 36, VC 23 = 11 contrastive pairs + 1 solo row)
  - `training_rows.jsonl` (103, train only), `packets.jsonl` (leakage-checked:
    no state/key/publisher-label), `answer_keys.jsonl`
  - `shortfall_report.md` — full funnel + adjudication of all 17 rejections
- `/data/agentic_trading/training_data/derived/formt_eval_freeze_20261020/`
  - frozen 10-packet eval (5 NE / 3 E / 2 AN), source-disjoint from train
    (verified in `freeze_manifest.json`), mirrors the 20261017 freeze format

## Key facts settled

- **Round 1 of the independent re-key is INVALID** — batch files carried
  `label_source`/`publisher label` in provenance; publisher label == authored
  state on most rows by construction, so the keyer wasn't blind. Preserved
  unused in `rekey_round1_invalid/`. Round 2 ran on label-stripped
  `packets_all130.jsonl` (verified leak-free); 113 PASS / 17 REJECT.
- Evidence the leak was real: 3 of the 4 round-2-only disagreements
  (FT-C251-nda-7, FT-C179-nda-13, FT-A2984) were PASS in round 1 (label visible)
  and split in round 2 (label removed).
- Adjudications: of the 17, 1 are authored-key errors caught by the re-keyer
  (FT-A2984: CVD deaths ≠ heart-disease deaths — authored C had leaked the
  publisher R-label), 2 are "keyer likely correct, authored key over-strict"
  (FT-C251-nda-7, FT-C179-nda-13), 14 are genuine keyer/keyer splits (notable
  systematic clusters: "all copies shall be returned" → C vs NE ×5;
  "may maintain/retain one copy" → E vs NE ×2; access-vs-use ×1;
  "no evidence that X" → AN vs NE ×1 (Form-T says NE wins);
  VC anaphoric "this constitution" ×2; VC lower-bound "more than 6.2M" ×1).
- **Lesson: strip all label-correlating metadata from any file a blind
  reviewer/model sees — provenance is not "just metadata" when it encodes
  the answer.** (Also applies to future screening envelopes and eval freezes.)
- VC final shape: 11 intact pairs + 1 solo (WANEGBT "7 million" negation;
  its S-row partner rejected as a lower bound).
- Raw downloads (381M) + 137M VC pair intermediate are .gitignored;
  reproducible from `raw/` via `prefilter.py`.

## Open / next

- Tranche is training-ready; no further work authorized.
- If a future round wants the 17 rejected packets back: the nda-20
  return-all cluster and the maintain/retain-one-copy cluster are the two
  biggest recoverable pools — they'd need a PM ruling on which reading is
  canonical before re-admission.
