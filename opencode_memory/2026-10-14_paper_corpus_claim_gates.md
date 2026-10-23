# 2026-10-14 — paper_corpus claim gates: entity consistency, resolution round, integration

Thread: web→PDF→claim-extraction pipeline for practitioner frontier-model content (GPT-6 family articles), hardened into the paper-corpus pipeline. Four stages shipped + committed to `master` of `/data/agentic_trading` (GitHub `splake-cloud/market_data`).

## What was built (all Agent-Print: pi (qwen3.8-27b-fp8))

1. **Stage 4c — entity-consistency gate** (`d19bb5c41`): `quote_gate.claim_model_tokens` + `claim_quote_consistency` — flags claims whose named model entities are not grounded in their own verbatim quote. Detection-only (flags, never drops). Rule ii'' (version-conflict semantics): co-mention of other versions passes when the claim's own version is grounded; conflict = quote discusses the family exclusively at another version. 29 unit tests.
2. **Stage 4d — model resolution round** (`192a496ef`): `scripts/paper_corpus/resolve_claims.py` — one :8012 call per flagged claim, id-keyed (mismatched id is unappliable — excludes the positional match-back bug class), three actions each gate-judged: `rewrite` (must pass 4c vs unchanged quote), `requote` (must pass the same 4a/4b verbatim machinery + 4c), `reject` (→ quarantine sidecar, `reason_code: claim_quote_entity_mismatch_model_reject`, original preserved in `resolution.original`). Gate failure = no application, claim byte-identical + `resolution.accepted=false` (terminal for curation). No iterative loop (delta §3.3). AC-4 raw record per call.
3. **Stage 5 — entailment/quality verdict tier** (`32db31857`): `scripts/paper_corpus/entailment_verdict.py` — per-claim judge call (default qwen3.6-35b-a3b on :8081, cross-model, endpoint/model per-run CLI params), single-shot, id-keyed, T=0, AC-4 raw. Verdict `supported|weak|unsupported` (quote-scoped — no paper text) + fidelity `full|partial` for resolved claims (always-present `na` convention). Advisory only: `entailment` field + curation-queue rows (`entailment_unsupported`, `resolution_low_fidelity`); `weak` = field+report only; nothing dropped/rewritten. 32 tests. **Eval (15-pair adjudication, 2 rounds):** round 1 missed the hard bar (flagship availability-inversion judged "supported" — quantifier inversion; judge rationale correct-but-mis-mapped on unasserted causation; agents↔users subject shift missed) + fidelity axis absent (model omitted conditional field 3/3 AND the stage silently accepted it — spec violation, fixed: required-field omission = failed verdict). Round 2 (4 principled prompt rules: restrictions/quantifiers, unasserted causation, subject identity, direction — general, not 15-case patches): **hard bar PASS 3/3, under-flag bar PASS 0, yes-recall 6/9** (all 3 misses conservative over-flags with defensible rationales), fidelity 2/3 full + 1 safely unattributed. Profile: strict over-flagger, ~33% review-row cost, 100% harmful-class recall on this paper.
4. **Integration** (`f69ff6a03`): `extract_claims.py` now runs the resolution round in-memory when `four_c_flagged > 0` (one command end-to-end); `--no-resolve` escape; zero-flag papers make zero extra calls; failure never aborts extraction (WARN + `resolution.error`). `resolve_flagged_claims` gained `out_path=None` (standalone CLI unchanged). Report semantics: `final_count` == file line count post-resolution; `four_c_flags` = still-flagged-after set; full flagged set in `resolution.per_claim`.

## Key facts settled

- **Adjudication-as-oracle discipline** (user critique, honored throughout): expected outputs in specs come from independent adjudication, never the designer's precomputation. Pilot oracle: `/tmp/web_smoke/adjudication_macrumors.json` (15-row independent label set; 6/15 had support defects invisible to all deterministic gates).
- **Pilot evidence**: stage 2 pilot 3 flags → 2 requote + 1 rewrite, all gate-accepted; integration live pilot (seed-deterministic, reproducible lineage sha `e9cf5d30…`) 23 valid → 5 flagged → 1 rewrite + 3 requote + 1 reject (quarantined).
- **Latent Stage-1 crash bug found by integration tests**: `four_c_flags` read `c["claim_id"]` before span-derived ids are assigned — would crash any extraction with a 4c-flagged claim; never fired because the pilot extraction predates 4c. Fixed in `f69ff6a03`.
- **Gate-accepted ≠ curation-approved** (the `2bb540cf` finding): a rewrite passed every gate but preserved the defective claim's double-negative frame and dropped the subject — entailed, weak. This is the first concrete mandate for Stage 3's fidelity axis.
- **Near-duplicate survival**: two semantically near-identical claims on the same span survive span-based dedup — candidate future task (noted, not acted on).
- Delegate's ":8012 unavailable" was a sandbox netns vantage artifact; host vantage (`net:[4026531833]`) confirmed serving — ran pilots from host side.

## Phase 4 — model_tuning bank (same day, PM ruling: "model tuning is the domain → lit-review RAG, not the general system/data RAG")

- **Domain registered** (corpus data area, not git): `domain_registry.json` → `model_tuning` (asset_class `ai_model`, vocab_status `built`, n_papers 3, vocab file-based); `vocab/model_tuning.json` (5 axes: topic/construct/comparison/scope/source_type, all allow_other); `paper_domains.json` +3 entries. Coder-built, asserts-verified (pre-existing bytes unchanged).
- **80 claims banked**: macrumors_gpt6_sol_luna_2026 (14), lindy_gpt6_explained (34), aitoolsreview_gpt6_sol_astra_luna (32) — parsed/ + claims/ (+raw, lineage, report) in `/data/parquet/papers_corpus/`, fresh extraction runs (run-tag `bank_20261014`, 0 4c flags across all three; note: bank run drew 15 raw for macrumors vs 29 in the earlier /tmp pilot — seed does NOT guarantee cross-time resampling, AC-4 replayability is from stored raw, not seed).
- **Index gap found + bridged**: `reembed_claims_4b.py` is a DIM-MIGRATION tool (re-embeds from the existing table, not the claims files) — the corpus has NO first-class "add new claims" tool post-4B-cutover; `embed.py` loads a local 8B (wrong vector space). Bridged with a one-shot incremental merge: keep 3537 existing rows verbatim, embed 80 new via :8765 document path (4B/2560, L2-normalized), backup→temp→swap→post-verify (row 3537→3617, per-paper counts verified). Script preserved as uncommitted scratch: `scripts/paper_corpus/bank_ingest_20261014.py`.
- **Service restart (rule-11 clean)**: the running :8090 worker had pinned the pre-swap dataset version (lance data-file NotFound); killed pid 636351 (ss port-owner + /proc cmdline cross-check: `serve_retrieval.py --port 8090 --lance-dir /data/parquet/papers_corpus/indexes`, up 7d) → relaunched via `launch_retrieval_service.sh` (pid 4085400). Acceptance: `verify/bank-8090-acceptance.*.txt` — "GPT-6 Sol pricing and availability tiers" returns all 3 papers, verbatim quotes, top-5.
- **Verdict pass over banked claims** (advisory layer): 73 judged / 11 unattributed — 45 supported, 15 weak, 14 unsupported → 19 curation-queue rows (`claims/verdicts/<paper>_verdicted*`). The :8090 table serves the canonical (unannotated) claims; verdicted files sit alongside.
- **Stage-5 CLI defect found + fixed** (uncommitted): CLI summary printed `result['judged']` — a key only in the on-disk report, never in `verdict_claims()`'s return → every successful CLI run ended `Error: 'judged'` + exit 1 (pilot evals called the function directly, so the CLI path was never exercised). One-line fix (`len(result['per_claim'])`), 32/32 tests, `verify/entail-cli-fix-tests.*.txt`. Commit pending with the rest.

## Phase 5 — metadata + ingest + judge seat (same day, continued)

- **`ingest_claims.py` shipped** (commit `7ca8877f4`, 18 tests) — the permanent claims-ingest tool (the corpus had none: `reembed_claims_4b` is a dim-migration tool, `embed.py` loads a local 8B). argv-driven, idempotent, `--replace`, metadata sidecar join (corpus-root derivation per embed.py — a first build had it one level wrong, caught + fixed), :8765 document-path embedding, backup→temp→swap→post-verify. Production run: 3537→3617 (fresh), then 3617→3617 with `--replace` + metadata join. One-shot `bank_ingest_20261014.py` deleted after being superseded.
- **model_tuning metadata pass shipped** (same commit, 29 tests) — domain dispatch via paper_domains.json (fail-closed on unknown domain), prompts built from `vocab/model_tuning.json`, model-name canonicalizer (GPT-6 Sol→gpt6_sol, en-dash safe), tuples map onto existing table columns (subject_variable=model, object_variable=construct, direction=comparison; finance fields null). Finance path unchanged. **80/80 rows tagged** (14+34+32), `other:` fallbacks working as designed for multi-model/no-single-comparison claims.
- **Judge seat moved to :8012** (PM ruling: "8081 is not the right model to do anything semantic. it is a no thinking model") — default endpoint/model in `entailment_verdict.py` changed; the :8012 seat needs its registry tune (T=0.8/top_p=0.95/enable_thinking/rp=1.0/top_k=20, max_tokens 2048) — the :8081-era shape (T=0, max_tokens=500) returns empty content on that seat (bare T=0 trips llama_decode ret=-3; thinking burns a 500-token budget). 34 tests.
- **A/B data point** (same claims, two judge seats): macrumors :8081 7/2/5 → :8012 4/3/6; lindy :8081 20/4/5 → :8012 14/10/4 (supported/weak/unsupported). The thinking judge reclassifies toward `weak`, similar `unsupported` — both are conservative over-flaggers.
- **Infra findings (both cost hours):**
  1. `172.29.0.1:8012` is a **foreign-container forwarder socket** (backlog 5, ~180s disconnect) that drops long thinking-model calls under load; vllm itself listens on `127.0.0.1:8012` (backlog 2048). From a host-seat vantage, `--endpoint http://127.0.0.1:8012/v1` is the robust path (flag added; noted in module docstring). The :8765 forwarder is fine.
  2. **delegate-guard** intercepts raw calls to the delegate port: ~20:00 onward, judge/metadata calls from the main seat AND from a subagent's CLI run got blocked ("empty content / probe also failed" is the guard's block signature, not a seat fault). PM correction: don't use the direct API for delegate-port work; config probes cap at `max_tokens:1`, missions go through the subagent tool. The 3 papers' metadata + 2 papers' :8012 verdicts all predate the guard engagement (gated, valid).
- **Robustness fixes shipped** (same commit): per-call progress logging in metadata_extract (the 20-min-silent-run failure), unified None-content guard over ALL judge calls (first-call-only guard let a None on call N+1 crash the run via the shared `_parse_single_json` — now routes to unattributed with a `[warn]` line), dry-run projection math fix.
- **Final corpus state**: 3617 rows; 3 model_tuning papers (80 claims) with full metadata; :8090 restarted twice (pinned-dataset staleness after table swaps — rule-11 pid-verified both times); verdicts: macrumors + lindy under :8012, aitoolsreview still under :8081 (its re-judge blocked by delegate-guard — `judged_by` field labels every record honestly).

## Phase 6 — 8-paper model_tuning bank (2026-10-15, hybrid delegate-guard-compliant architecture)

**Mission**: ingest 8 model-tuning papers (arXiv ×6 + rlhfbook.com + thinkingmachines.ai) into the :8090 corpus. **Constraint that shaped everything**: the delegate-guard PM ruling — model work goes through qwen38-collab native sessions (qwen3.8-27b-fp8 on :8011); the main seat does pure deterministic file ops only. No API calls from the main seat, no API calls from subagent CLIs.

**Hybrid architecture** (the sanctioned pattern, reusable):
```
[main seat] fetch PDFs (arXiv / headless-Chrome print-to-PDF) + parse_pdf.py → parsed/<slug>/gate_reference.txt
[qwen38-collab] extraction mission: read gate_reference → 25-40 claims JSON (claim_type, claim_text, evidence_quote)
[main seat] run_gates.py — imports process_round0_claims from extract_claims.py, runs 4a/4b/4c + paging + claim_id
[qwen38-collab, if flags] resolution mission (requote/rewrite)
[main seat] re-gate --resolution
[qwen38-collab] judging mission → verdicts JSON (file-write protocol)
[main seat] merge_verdicts.py → _verdicted.jsonl + entailment report + curation queue (stage-5 shape)
[main seat] ingest_claims.py (:8765 embedding) → Lance table swap → :8090 restart (rule-11 pid)
[qwen38-collab] metadata sidecar missions (3 files per paper)
[main seat] validate_sidecars.py → re-ingest --replace with metadata join → :8090 restart
```
Orchestration tools (ephemeral, `/tmp/ingest_20261015/`): `run_gates.py`, `extract_agent_result.py`, `merge_verdicts.py`, `validate_sidecars.py`. Not in the repo — promote if another subagent-driven bank is planned.

**Operational discoveries**:
- **Per-message output cap ~10.8KB**: Llama 3's 40-claim array truncated across 3 re-emits in the first dispatch. Fix = **file-write protocol**: agent writes the JSON to a given path, verifies by reading back, replies one line ("WROTE N"). Applied to InstructGPT (via steer mid-run) and Llama 3 v2 (fresh dispatch).
- **Scope-carrying steer**: early papers showed pathological weak rates (lora_learns_less 1/29/0 — extractor added scope claims don't carry; judge correctly said weak). Steer sent to in-flight extractors: *prefer evidence quotes that CARRY the scope claim_text states; if only a short generic summary sentence exists, limit claim_text to exactly that sentence.* Later papers: instructgpt 29/6/0, tulu3 19/16/0, book 37/38/0.
- **243-page book**: split at paragraph boundaries into 3 parts (~202K chars each), 3 extraction missions ×25 claims, gated against the FULL book's gate_reference (verbatim matching works since parts ⊂ full text), merged with cross-part span-collision check → 75 claims.
- **arXiv ID lesson**: never guess — verify against the abs page. Tülu 3 is 2411.15124 (2411.01747 = DynaSaur); LoRA Learns Less is 2405.09673 (2405.08798 = a physics paper).

**The 8 papers (304 claims, all gated, 1 4c flag total — instructgpt, resolved by requote)**:
| Paper | Claims | supported/weak/unsupported | Queue |
|---|---|---|---|
| instructgpt_ouyang_2022 (2203.02155) | 35 | 29/6/0 | 0 |
| llama3_herd_meta_2024 (2407.21783) | 40 | 5/35/0 | 0 |
| deepseek_r1_2025 (2501.12948) | 34 | 9/25/0 | 0 |
| agenttuning_zeng_2023 (2310.12823) | 30 | 10/19/1 | 1 |
| tulu3_lambert_2024 (2411.15124) | 35 | 19/16/0 | 0 |
| lora_learns_less_forgets_less_biderman_2024 (2405.09673) | 30 | 1/29/0 | 0 |
| rlhf_book_lambert (rlhfbook.com) | 75 | 37/38/0 | 0 |
| lora_without_regret_thinkingmachines_2025 (blog) | 25 | 6/16/3 | 3 |
| **total** | **304** | **116/184/4** | **4** |

All verdicts by qwen38-collab judging missions (qwen3.8-27b-fp8 family, same family as :8012 judge — consistent with the Phase-5 A/B finding that the thinking family reclassifies toward weak vs :8081).

**Ingest + metadata**:
- First ingest: 304 rows via :8765 document-path embedding (4B/2560), 3617→3921, post-verify (per-paper counts, L2 norms), backup at `claims.lance.bak-preingest.20261014T221017Z`.
- Metadata: 8 qwen38-collab sidecar missions (claim-tags jsonl + paper-level json + state json per paper, exact `ingest_claims` join contract), `validate_sidecars.py` passed 8/8 (id order, key shape, nulls, enums, topics 3-8, state match). Re-ingest `--replace`: 304/304 rows carry subject_variable/object_variable/direction/topics.
- Registry: `model_tuning` n_papers 3→11; paper_domains.json 93 entries (11 model_tuning).
- :8090 restarted twice (pinned-dataset staleness; rule-11 pid-verified both times). Acceptance: 5 domain queries (InstructGPT vs GPT-3, LoRA vs FT, R1-RLVR, Tülu 3 recipe, DPO/KL) — all return the correct paper top-1 with on-topic claims.
- **No repo commits this phase**: corpus lives out-of-repo; the tree's modified files belong to other seats' work (untouched). Code from Phases 1-5 is all in `7ca8877f4` and earlier.

**Final corpus state (2026-10-15)**: 3921 rows in the :8090 Lance table; 11 model_tuning papers (8 academic/practitioner + 3 GPT-6 web), 304 claims fully metadata-tagged, 304 verdicted (4 curation-queue rows); 848 finance-domain claims untouched.

## Commits on master

`d19bb5c41` (4c gate) → `192a496ef` (resolution round) → `f69ff6a03` (integration) → `773e5a99e` (verify transcripts) → `32db31857` (entailment tier) → `7ca8877f4` (model_tuning pipeline: ingest tool, domain-aware metadata, :8012 judge, robustness fixes). Other seats' Pi A/B work committed on top.

## Open / next

- [DONE] **aitoolsreview re-judge** — done via **qwen38-collab native session** (the doctrine-compliant form: model work through a subagent's own session, zero API from the main seat). Result: 18 supported / 14 weak / 0 unsupported, 0 queue rows, stamped `judged_by: subagent:qwen38-collab`. All 3 banked papers now carry qwen3.8-27b-family verdicts (macrumors + lindy under :8012, aitoolsreview via subagent). Judge A/B/C on identical claims: :8081 (no-thinking) is the most aggressive over-flagger (aitools 18/9/4 with 4 unsupported); the qwen3.8-thinking family (both :8012 and native subagent) reclassifies those toward `weak` (18/14/0).
- **Delegate-guard doctrine (PM ruling, absolute)** — the main seat does NOT use the delegate API. Full stop — not for pipeline stages, not for debugging; the guard exists to enforce exactly this, and defending the pipeline's API design was rejected. Sanctioned form for model work: subagent native sessions (qwen38-collab for semantic missions — e.g. the aitoolsreview verdict re-judge went to a qwen38-collab judging mission, output merged deterministically in-seat). The script-based stages (verdict/metadata) remain tools for PM-sanctioned runners, not for the main seat.
- **Entailment queue shape**: PM didn't recognize the question; assistant recommendation stands — keep per-paper queue files separate from the contradiction-pair-shaped `curation_queue.json` (no action).
- **Anaphoric-quote contract**: assistant recommendation (ratify the self-contained bar = current gate behavior, zero code change) awaits explicit PM confirmation.
- **SSD Nodes URL**: PM didn't recognize the item (pre-compaction origin) — dropped unless resurrected.
- **`DEFAULT_INSTRUCTION` generalization** in `retrieve.py` (finance-specific today): deferred, low urgency — bank queries retrieved well without it.
- **Metadata pass for the finance corpus's pending domains** (market_structure et al.): the new domain-aware dispatch is the template; not requested, not done.
- Pilot artifacts are in `/tmp/web_smoke/` (ephemeral): claims, adjudication eval set, resolved outputs, lineage. Commit as durable fixtures if they must outlive a reboot.
- [DONE] **Hybrid orchestration tools promoted to repo** (commit `ba698649d`, PM request 2026-10-15): `scripts/paper_corpus/{run_gates,extract_agent_result,merge_verdicts,validate_sidecars}.py` + `tests/test_agent_ingest.py` (30 tests; 178 passed full suite). Generalized from the /tmp originals: repo-relative sys.path, `--corpus`/`--endpoint`/`--model-id`/`--run-tag` args, argparse per sibling convention; logic otherwise verbatim (the /tmp originals' docstring even had a `key`/`index` mismatch the promotion fixed). Verified live: 9 production transcripts parse with expected counts, truncated Llama-3-v1 output correctly rejected (returns None — the tool is the truncation detector), 2 sidecars OK. The agent-ingest toolset is now the permanent in-seat half of the subagent-native ingestion path.
- **`DEFAULT_INSTRUCTION` generalization** in `retrieve.py` (finance-specific today): deferred, low urgency — bank queries retrieved well at :8090 without it, so no pressure; still a candidate if a model-tuning query ever fails to retrieve.
- **Verdict-tier profile note (8-paper sample, 304 claims)**: 38% supported / 61% weak / 1.3% unsupported. The thinking-family judge is a strict over-flagger at scale; `weak` is dominated by scope-not-carried-by-quote (extraction-side fix: the scope-carrying steer), not by actual contradiction. If the curation review cost becomes a problem, the lever is the extractor's quote selection, not the judge.
- Pre-existing test failure (not ours, do not fix): `test_pipeline_invalidation.py::test_vocab_change_tamper`.
