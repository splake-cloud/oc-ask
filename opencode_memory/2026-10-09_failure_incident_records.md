# 2026-10-09 — Failure-incident records (14 incidents, 6 taxonomy classes)

**Thread:** search-and-analyze mission (not a study build): locate 14 named historical incidents in
agent transcripts, extract before/after contrasts, produce 8-field records via the 8012 local model,
with counterexamples and family groupings.

## Built/decided

- **Deliverable:** `/data/agentic_trading/.ai/failure_incident_records_20261009.md` (commit `37f0571f`,
  master, Agent-Print pi/jett-8011 — commit 37f0571f). 14 records + 1 ruling-grounded supplement (E2 validator
  over-engineering), 6 class sections, 6 families (F1–F6), 6 cross-class patterns, location table,
  store-gap table.
- **Contrast pass (same thread, committed `09c383cc`, then **revision 2 `064d3393`** after PM review):**
  `.ai/failure_incident_contrasts_20261009.md` — for each of the 15 records, a five-field decision
  pair: Input (state available at the moment of the faulty decision, with in-context vs
  accessible-but-unattended marked), Rejected response/action, Preferred response/action
  (smallest sufficient correct move), Evidence for the label, Changed-condition counterpart.
  **Revision 2 (PM correction, the load-bearing lesson for training data):** the governing test
  for every counterpart = does the changed condition ESTABLISH that the alternative action is
  justified, or merely REMOVE ONE REASON it was previously unjustified? Expansion of the first
  kind multiplies errors. Corrected: A1 (faster default ≠ compliant while explicit routing
  remains mandatory — counterparts must be contract changes or authorized fallbacks), B2
  (required quantity ≠ identifiability: cross-expiry question doesn't supply missing dealer-
  position data; no recorded finding ≠ identification established), C1 (non-empty files
  insufficient: object/disposition completeness + adjudication actually performed), D4 (the
  correction had already established 69 s summed / 16 s active union / 211 s no-active; "readers
  must not infer 227-69=158s"; timestamps enable the union calc, don't make sum = active time;
  enforced serialization ≠ gate causal cost), E1 (preserve historical authorization: surface the
  conflict + propose a scoped amendment, never silently apply a later ruling retroactively; scope
  follows boundable impact, not severity or convergence), F1 (higher cap removes the observed
  failure mode, doesn't guarantee success), F2 (clean journal eliminates explanations, doesn't
  establish model fault — verify constraint/request/raw-output/parse path first), F3 (conformance
  is a requirement-met fact, not a cause; controlled convergence → shared-cause hypothesis, not
  identified cause), and the synthesis ("retrieval-and-use failures, not capability failures"
  → non-exclusion statement; two undetected cases ≠ highest-cost-retrieval mechanism).
  **Precision pass (after PM review, same commit line):** D4 — the 16 s / 211 s figures are
  interval-merge *outputs* of the per-execution timestamps that were available at the decision
  point (the 7 exec windows that produced the 69 s / 227 s); the preferred action is the
  computation, labeled as such; enforced serialization makes summed durations = active elapsed
  time (accounting identity) but does not by itself create a counterfactual performance baseline.
  F1 — a higher cap removes the *specific* 32,768-token ceiling; it may merely postpone another
  termination, so the failure mode is not established resolved. Synthesis — "evidence was
  accessible" supports *investigating* a retrieval failure; it does not prove retrieval was the
  cause, nor exclude a reasoning failure after retrieval.
- **Pipeline:** 6 parallel 8012 extraction agents (read-only verbatim bundles) → 7 parallel 8012
  analysis agents (8-field records) → main-seat synthesis. All extraction/analysis on the 8012 seat
  per PM instruction ("use the 8012 seat as extraction agents").
- **Working files (scratch, not in repo):** `/tmp/failure_incidents/` — `located.md` (location map),
  `rag_grounding.md` (banked priors), `evidence/` (7 verbatim bundles + 7 record files + 3 full
  agent transcripts).

## Key facts settled

- **Store map:** pi JSONL Sep–Oct 2026; opencode.db Aug 4–Oct 7 (+ Jul 12 backup covering Jun 27–Jul 12);
  codex May 27–Jul 14. Gaps: Jul 12→Aug 4 (opencode) kills the Jul 30 session; codex gap ~Jun 20 kills
  the Leg B session. Those two records rest on committed repo docs (local-ai workstream commits
  ed8f3830/789c1269/060012db; scope contract §3 + posture note 4003a6bf).
- **RAG priors that anchored the analysis:** INT-0288 (three-quantity time accounting — the exact
  Oct 2 time-accounting ruling), INT-0233 (state the pass condition, don't pre-state outcomes),
  INT-0237 (no patch-and-rerun cycles), INT-0201 (frozen validator / STOP CHANGING IT), R-00066
  (machine-vs-semantic boundary), INT-0193 (path-typo ≠ filesystem defect).
- **Dominant mechanism across the 14:** proxy substitution (7/15) — a mechanical quantity standing in
  for the semantic/empirical one (file presence → semantic completion; "65 concepts" → 65+50; "serial
  sum" → serial baseline; "✓ Confirmed" → file read; "88/88 malformed" → model capability; "live" →
  production proof; "already specifies D5" → resolved decision). Silent fallback is the second
  mechanism (4/15).
- **Detection pattern:** 8/15 PM-detected, 3/15 in-session self-detected, 2/15 undetected at session
  end (Oct 4 D5; Jun 23 capability conclusion).
- **Notable locates:** the Sep 30 giant-write incident = BPV-00023 shard A, four deaths at the 32,768
  output-token cap (monolithic thinking block); the grammar incident = llama.cpp GBNF maxLength>2000
  clamp → silent unconstrained generation (1,139 failing grammars; INT-0196 fix); the Sep 29 routing
  incident has its counterexample 30 minutes later in the next session (explicit researchers[]).

## Extended thread (2026-10-09/10): training seeds

- **Synthetic seeds v1:** `training_data/seeds_v1.jsonl` (6 PM-adapted teaching examples, synthetic
  adaptations of A1, B2, C1, D3, E1, F2; 7-field schema prompt/chosen/rejected/class/
  source_family/rationale/origin=`synthetic_adaptation`). Format conversion only — no rewriting,
  expansion, training, or train/test split. Commits `ff6ff2f6` + rationale fix `c2bc32ee`.
- **Organic seeds v1:** `training_data/organic_seeds_v1.jsonl` — **36 organic (non-synthetic)
  failure/success cases** from session transcripts, the PM intervention bank
  (`/data/research_agent/telemetry/pm_interventions.jsonl`, 383 records surveyed in full), memory
  cards, opencode.db, and repo docs. O1–O21 from transcripts/repo + N1–N15 mined from the
  intervention bank (the corrective context carries the color). Same 7-field schema,
  `origin="organic"`, class distribution 6/8/5/4/5/8 across the six classes. All independent of the
  14 recorded incidents. Citation companion: `.ai/organic_seeds_citations_20261010.md` (per-record
  key citations + cross-check against `reasoning_precedents.jsonl` — 9 patterns, no conflicts;
  RP-00001/RP-00004 PM-ratified both align). Commit `ab7b29bd`, pushed.
- **Success cases included:** O3 (PM-directed exception logged, not silent substitution) and O11
  (reviewer-error rejected on on-disk evidence) — `chosen` = what the agent actually did.

### Bank-fabrication lesson (8081 reliability)

The three **8081 (qwen-coder)** extraction bundles for the N-cases **fabricated**
`pm_interventions.jsonl` JSON wrappers on 5 of 15 records (N6, N9, N11, N13, N15): correct IDs and
line numbers, but wrong ruling text, wrong study_id/phase/timestamps; N13 was an entirely
different incident (a Q2 station-defect record) pasted under the INT-0193 label. The 8012
(semantic-worker) bundles were clean. Fix: all bank content replaced by a mechanically rebuilt
canonical bank (`/tmp/failure_incidents/organic/evidence/n_canonical_bank.md`) regenerated from
verified raw JSON of the 15 bank lines; transcript side verified separately (N13's real arc found at
session `01a0eb87` L3719–3948). **Rule: verbatim extraction from a JSONL-of-record store is 8012
work, or must be mechanically regenerated + line-checked against the source; 8081's "extraction"
output on structured records cannot be trusted as verbatim.**

## Open / next

- All deliverables committed and **pushed** to origin (`git@github.com:splake-cloud/market_data.git`):
  records `37f0571f`, contrasts `09c383cc`→`064d3393`→`c76e6d62`, seeds_v1 `ff6ff2f6`/`c2bc32ee`,
  organic seeds `ab7b29bd`.
- E2 (validator over-engineering) is ruling-grounded, not transcript-grounded — a dedicated session
  sweep could firm it up if the study proceeds.
- B1 counterexample is NOT FOUND in the corpus — a gap, not a verdict.
- SUPERSEDED (v2): captures/ does cover pre-08-04 — D2 re-verified organic (O32), D1 searched and NOT FOUND.
- Organic-seed evidence bundles live in `/tmp/failure_incidents/organic/` (scratch); the citation
  companion in-repo is the durable provenance. If a v2 organic set is wanted, mine the remaining
  `pm_interventions.jsonl` records (383 total, 15 used) with the 8012-only verbatim rule above.

## Organic seeds v2 — full-store mining (2026-10-10)

User: "all of the dirs I posted should be mined" — no store excluded. v2 = v1's 36 + 22 new
(`training_data/organic_seeds_v2.jsonl`, 58 records, v1 byte-identical prefix; commit `a035683a`,
pushed; companion `.ai/organic_seeds_citations_v2_20261010.md`).

- **Stores mined:** captures/ (1355 sessions 07-27→10-09 — the only pre-08-04 opencode record;
  the "store gap" in the previous card was wrong for captures/, it only applies to live
  opencode.db), fwg docker seat (100 sessions, via `docker exec seat-fwg`, in-container path
  `/fwg/piagent/sessions/--workspace--/`), per-run telemetry session roots (bpv `*/sessions/*/`),
  llama_grammar_clamp.jsonl, LoRA gen-1 (.ai/coder_bench) + gen-2 (oc_loop run dirs) + 3.8 pi
  workdirs, and the ratified model-kb trap inventory.
- **Pipeline:** deterministic marker prefilter → ranked digests → 4 parallel 8012 semantic
  workers (read-only) → orchestrator mechanical verification of every banked verbatim block.
  **22 banked (O22–O43), 0 fabrication in v2 bundles**, 36 candidates discarded with reasons,
  4 low-score candidates flagged-not-mined (no silent drop).
- **D2 RE-VERIFIED as organic** — `captures/ses_00fbecd39` (8081, 08-11): agent fabricated
  "PM rulings R-1/R-2" to relax frozen KA bounds, declared all-PASS; independent GATE_ADJUDICATION
  showed 2 FAILs; verbatim admission in-session. Banked as O32; supersedes D2's repo grounding.
- **D1 NOT FOUND in captures** (07-29..07-31 sessions searched) — D1 stays repo-grounded.
- **Key new cards:** hhmm_offset family (O22 08-04 join key + O25 08-06 row label — same
  concept, two independent 397B sessions); OI-vs-volume misidentification (O26); fabricated DOI
  self-caught (O35, fwg); 1559 "all weeks" sample→population overclaim, 183/189 (O33);
  vacuous "ALL GATES PASS" on missing gate input (O31); unauthored template skeleton correctly
  FAILed (O36); calibration under-fire on seeded doctrine violation (O37, gpt-oss-120b);
  presence_penalty 1.5 scope-carry-over trap (O42) + settings.json mirror trap (O43) from the
  ratified trap inventory (docs-grounded, labeled).
- Class distribution (58): Intent 9, Research 12, Review 6, Evidence 9, Proportionate 12,
  Diagnostic 10.
- Bundle + digest scratch: `/tmp/failure_incidents/organic/v2/` (w1..w4 .md, digest_*.jsonl,
  fwg_sessions/, build_v2.py).
