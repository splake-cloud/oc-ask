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

## Open / next

- Both reports committed (records `37f0571f`; contrasts `09c383cc` + revision-2 precision pass `a41d7c90`); nothing pushed (no remote for this lane).
- E2 (validator over-engineering) is ruling-grounded, not transcript-grounded — a dedicated session
  sweep could firm it up if the study proceeds.
- B1 counterexample is NOT FOUND in the corpus — a gap, not a verdict.
- Session-transcript evidence for D1/D2 remains unrecoverable (store gaps); if those sessions surface
  (opencode backup rotation), the two repo-grounded records should be re-verified against them.
