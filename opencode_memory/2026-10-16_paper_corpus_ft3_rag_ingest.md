# 2026-10-16 — paper_corpus: ingested 3 missing fine-tuning papers into the model_tuning bank (:8090)

**Thread:** continuation of the Qwen3.8 fine-tuning reference thread (see
`2026-10-15_qwen38_finetuning_research_and_adapter_audit.md`) using the
paper_corpus claim-bank pipeline (see `2026-10-14_paper_corpus_claim_gates.md`).

## What was built
The lit-review RAG (`papers_corpus` bank, port **:8090**, LanceDB `claims` table,
`model_tuning` domain) was missing 3 of the 9 fine-tuning reference PDFs saved to
`/data/agentic_trading/.ai/reference/papers/fine_tuning/`. Ingested the missing 3
through the full Phase-6 hybrid pipeline (parse → extract → gate → resolve → judge →
merge → metadata → validate → ingest → restart → registry → acceptance):

| paper_id | paper | claims | 4c flags → resolved | verdicts (sup/weak/unsup) |
|---|---|---|---|---|
| `lora_hu_2021` | LoRA: Low-Rank Adaptation of Large Language Models (Hu et al. 2021) | 39 | 12 → 12 (11 requote / 1 rewrite) → 0 | 16 / 23 / 0 |
| `lima_zhou_2023` | LIMA: Less Is More for Alignment (Zhou et al. 2023) | 30 | 0 | 4 / 26 / 0 |
| `star_zelikman_2022` | STaR: Bootstrapping Reasoning With Reasoning (Zelikman et al. 2022) | 32 | 0 | 15 / 17 / 0 |

**Bank state now: 14 model_tuning papers / 4022 rows at :8090** (was 11 / 3921).
`paper_domains.json` 93→96 keys (14 model_tuning); `domain_registry.json`
model_tuning `n_papers` 11→14. All 101 new claims fully metadata-tagged
(subject/object/direction sidecars) and validate clean.

## Pipeline (delegate-guard-compliant — the sanctioned pattern)
Model work (extraction / 4c-resolution / judging / metadata) = **qwen38-collab
native sessions** (qwen3.8-27b-fp8), each a file-write-protocol deliverable under
`/tmp/ingest_20261015_ft3/`. Main seat = **pure deterministic ops**: `run_gates.py`
(4a verbatim / 4b span / 4c entity-consistency), `merge_verdicts.py`,
`validate_sidecars.py`, `ingest_claims.py` (embed via live :8765, backup→temp→swap→
post-verify), rule-11 pid-only :8090 restart, registry edits, acceptance.

- **Ingest receipt** (verify-run): `/data/agentic_trading/verify/bank-8090-ft3-acceptance.20261016T104326Z.txt`
  — table 4022 rows (lora 39 / lima 30 / star 32), 3 live :8090 queries each
  top-retrieving its own paper, exit 0.
- **LanceDB backup**: `/data/parquet/papers_corpus/indexes/claims.lance.bak-preingest.20261016T104208Z`.
- Canonical claim files: `/data/parquet/papers_corpus/claims/<slug>.jsonl` (18 cols, vectors 2560-dim).
- Verdicted side artifacts: `/data/parquet/papers_corpus/claims/verdicts/<slug>_verdicted.jsonl`
  (+ `_entailment_report.json`, `_curation_queue.jsonl` — all 3 queues empty).
- Metadata sidecars: `/data/parquet/papers_corpus/metadata/<slug>{.json,_claim_tags.jsonl,_claim_tags.state.json}`.

## Key facts settled
- **The 6 other fine-tuning papers were already banked** (instructgpt, tulu3,
  agenttuning, lora_learns_less, rlhf_book, lora_without_regret + llama3_herd +
  deepseek_r1 from Phase 6) — only LoRA/LIMA/STaR were the gap. The 9 PDFs on disk
  map to: 6 already-claimed + 3 newly-ingested.
- **Judging is advisory, over-flagging by design**: "weak" = field + report only,
  nothing dropped (hence 23/26/17 weak with 0 unsupported is healthy, not a defect).
  The 4 principled judge rules (restrictions/quantifiers, unasserted causation,
  subject identity, direction) catch extractor over-qualification that the 4c
  entity gate (named-model-only) does not.
- **4c flags concentrate on the GPT-3/GPT-2 scope**: LoRA's 12 flags were all
  "claim names GPT-3/GPT-2, quote doesn't" — resolved by requote (widen span to
  include the model name) or rewrite (drop the ungrounded entity).

## Ops discoveries (scored)
1. **qwen38-collab extraction can hit the per-run output token limit while composing
   a large claims JSON as chat text** → "run hit the output token limit before
   producing any text", deliverable never written (STaR, first attempt, 7 reads then
   died). **Fix: resume the same agent + mandate chunked file writes** (write first
   ~10 claims, append the rest in 2–3 python load/extend/dump steps, never emit JSON
   as chat text). Resume worked — STaR landed 32/32 verbatim on the retry.
2. **A completion notification can be premature / the final message can pre-empt the
   file write** (LoRA: pinged "WROTE 25 / passed 25/25" while still running, file
   absent). **Fix: never trust the completion text — verify the deliverable on disk
   (parse + substring re-check) before gating.** This is the "delegate reports are
   not evidence" rule applied to the new file-write protocol.
3. `ingest_claims.py --dry-run` gives a zero-write plan (existing/projected rows,
   papers to add/skip/replace) — use it before every real ingest. New papers need
   **no** `--replace`; `--replace <slug>` is only for re-ingesting an existing paper.

## Next / open
- (none blocking — bank complete and live).
- The 3 new papers are now retrievable reference for the Qwen3.8 fine-tuning work
  (LoRA r/α/calibration, LIMA data-efficiency, STaR self-training).
- aagent's DeltaNet smoke (from the 10-15 thread) — fold results into the
  fine-tuning card when posted; **do not launch competing training runs**.
- Fine-tuning reference PDFs on disk remain **uncommitted** to the agentic_trading
  repo (user can request a commit); the bank artifacts live in the corpus data area
  (`/data/parquet/papers_corpus/`, not git).
