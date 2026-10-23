# 2026-10-17 — public_evidence set 2: disjoint 50-packet evidence-judgment set, COMPLETE

## What was built

Second, **disjoint** 50-record evidence-judgment SFT set (same methodology as the
parallel process's `public_evidence_20261017`), to increase training volume for the
Qwen3.8-27B LoRA pilot. **Deposited in a separate lake: `/data/parquet/public_evidence_set2_20261017/`**
(13 files, marketdata group, g+rX; staged→verified→swapped per gamma_lake_sync.sh convention).
Working dir: `/data/agentic_trading/training_data/derived/public_evidence_set2_20261017/`.

## Final state

- **40 sft_ready** (reasoning-bearing, TRL-checked) — parallel set had 35 (+8).
- **10 manually corrected answers** (`answer_content_candidate_only`, sft_ready=False,
  pending PM disposition: accept as answer-only or regenerate).
- **1 replacement**: SCIFACT-980 → SCIFACT-789 (reserve, same gold bucket, disjoint).
  980's claim necessity-wording exceeds the abstract's ability evidence — the parallel
  curation independently removed this same packet for this same reason.
- Labels: SUPPORTED 23 / CONTRADICTED 22 / NOT_ESTABLISHED 5 (same quotas as parallel).
- TRL receipt **pass**: 40 records, 0 errors, 30,688 total / 12,744 supervised tokens,
  real DataCollatorForLanguageModeling check, per-packet payload sha256.
  Same kwargs as parallel receipt (`enable_thinking: true, reasoning_effort: low`).

## Pipeline (all same as parallel)

harvest2 protocol (verbatim re-implementation, disjoint draw) → DataDesigner 0.9.4
answer generation (qwen3.8-27b-fp8 @:8011, temp 0) → separate-model answer review
(qwen3.6-35b-a3b-q8 @:8081: 35 PASS / 15 FAIL) → separate-model reasoning review
of admitted (35 PASS / 5 FAIL) → **manual admission audit of all 50** (authoritative)
→ TRL batch receipt → lake deposit.

## Key findings / scored items

1. **Audit confabulation (scored)**: two first-pass audit notes (FEVEROUS-55669,
   -59508) + partial -86629 were written from memory, not the deck (55669 was
   misread as Rhinelander; 59508's sea snail misread as a Latvian actor).
   Caught via reviewer disagreement; **full re-read of all 50 packets** performed;
   corrected notes + confabulation flags in `admission_review.jsonl`.
   Lesson: audit notes must quote deck text; reviewer disagreement is the canary.
2. **Reviewer override pattern**: 5 answer-review + 5 reasoning-review FAILs
   overruled by manual audit (documented per row). Reviewer's recurring failure
   mode = non-canonical "partially supported" framing vs the 3-label convention;
   plus one arithmetic error (1908–1917 called "over one decade") and one
   wrong-direction completeness argument (≥8 players still contradicts "five").
   7 reviewer FAILs independently confirmed the audit's corrections.
3. **TRL check script had 2 span-boundary bugs** (fixed, not weakened): in the
   pinned template the generation prompt ends INSIDE the thinking scaffolding
   (think_open + '\n' are prompt; boundary b = o+2), so (a) the
   reasoning-supervision scan must start at max(o+1, b), and (b) the answer span
   starts at c+1 (after the think_close token). Also a status-aggregation bug
   (`not all_errors` tested container list, not error count).
4. **DataDesigner config gotcha**: `create <config> -n 1` re-reads the config's
   seed path — a 1-record rerun silently used the 50-record seed (first row).
   Fix: per-run config with its own seed path. Also: run dirs are root-owned;
   JSONL must be exported from parquet by hand; a stale run dir of the same
   name poisons reruns (use a fresh dataset name).
5. **Strict-vs-gold admissions** (6 admitted + 4 of 10 corrections diverge from
   publisher gold): the data trains packet-scope judgment, not gold matching.
   Documented per row in `admission_review.jsonl`.

## Open / next (PM)

- **Registration DONE (PM ratified 2026-10-17)**: POOL_LEDGER entry
  (`docs/data_pools/POOL_LEDGER.yaml`, status `PM-RATIFIED (2026-10-17)`,
  accrual FROZEN, 13-file contents manifest, TRL + audit verification record;
  YAML-validated, path existence checked). data_catalog deliberately NOT
  registered — checker readers support parquet/parquet_glob/csv only, pool is
  JSONL (documented in the ledger notes). Lake README registration block
  updated to match.
- Disposition of the 10 corrected answers (answer-only vs regenerate) still open.

## Evidence

- Lake: `ls /data/parquet/public_evidence_set2_20261017/` (13 files)
- TRL: `TRL_SET2_LABEL_CHECK_20261017.json` (status pass, 40/40)
- Audit: `admission_review.jsonl` (51 rows: 40 ADMIT / 10 CORRECT / 1 REPLACE)
- Candidates: `answer_content_candidates.jsonl` (50 rows, 40 sft_ready)
- Working dir: configs, seeds, audit deck, trl_label_check.py, raw run exports
