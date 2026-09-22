# 2026-09-17 — Ontology Lab Phase 11a + research_agent backfill

## What was built/decided

Continuation of the Research Ontology Lab build (session
`ses_f5acd11ffffeQ8GjFlVmSqLoSN`, resumed after ctx overflow). Four things
landed and were verified:

1. **Phase 11a — reconcile manifest** (the "important seat" prereq). The
   per-study `reconcile.yaml` now drives **three** things, not one: source
   paths, decision parsing, and claim-verdict derivation. This was the fix
   for the load-bearing gap found when reviewing the Phase 11 design: the
   original 11a only parameterized paths, which would have failed on the
   pilot study (no `claim_verdicts.parquet`, no `### DECISION:` line, verdict
   `INDETERMINATE`).
2. **PM decision D1 (option a)** — extended the claim-status vocabulary with
   `INDETERMINATE`.
 3. **research_agent backfill** — all 4 studies brought into the ontology at
    their faithful states.
 4. **RAG card for the study-state ledger** — an authored card
    `study-state-ledger-lifecycle` added to the `lifecycle_contracts` well
    (the best fit: the study state machine is a lifecycle), documenting what
    the ledger is, how it works, and what initiates it.

## Key facts settled (with paths)

- **Amended 11a spec (source of record):**
  `ontology_lab/specs/phase11a_reconcile_manifest_spec.md`. Pins the three
  drivers, the label-normalization rule (forbids greedy `(.+)`; applies to both
  `line_prefix` and `pattern` extract modes), the correct default manifest path
  (`<raw_dir>/specs/reconcile.yaml`, NOT `<raw_dir>/studies/<name>/specs/...`),
  and S3's representative-markdown test input.
- **`reconcile.py`** (EDITed): `reconcile_study(db, raw_dir, study,
  pre_closure=False, manifest_path=None)`; `_normalize_label()` helper;
  `_claim_verdict_multiset_{parquet,pairs,none}`; `_decision_consistency_manifest`
  (INDETERMINATE gated like NO_GO: `judgment_ok AND status_ok`); `manifest_exists`
  fact (ERROR blocks closure); `--manifest` arg. spx_0050 regression
  byte-equivalent (15 facts, CLEAN).
- **INDETERMINATE claim status**: `schema.yaml:430` (claim_status enum) +
  `actions/ontology_actions.py:44` (`VALID_CLAIM_STATUSES`), 8 values. The live
  `ontology.duckdb` (gitignored) was **rebuilt** so the baked-in
  `CHECK(status IN (...))` admits it — DuckDB can't extend a CHECK in place.
- **Backfill states** (live `ontology.duckdb`, now 4 studies):
  - `spx_0050_gamma_magnet` → CLOSED (seeded, untouched)
  - `spx_0050_magnet_longhorizons` → IDEA (NOT READY, D1–D3 open)
  - `gamma_large_node_corridor` → IDEA (bare idea.md)
  - `gamma_node_price_pull_discovery` → **EXECUTED** (2 datasets, 5 methods,
    3 artifacts, 5 runs C0–C4, 5 claims, 2 judgments). Datasets: `spx_1min v1`
    (reused, same sha256) + `uw_gamma_per_strike_certified v1` (registered under
    a distinct name — it's a DIFFERENT file, sha256 `3772fd41…`, than the seeded
    `uw_gamma_per_strike v1`).
- **Gamma reconcile.yaml** (new, the only file written under `/data/research_agent/`):
  `/data/research_agent/studies/gamma_node_price_pull_discovery/specs/reconcile.yaml`
  — `claim_source.kind: pairs` (no-parquet case), `decision_rule.extract.pattern:
   "JOINT D1 = ({label})"`. Reconcile on the real study: claim multiset MATCH,
   decision INDETERMINATE, decision_consistency DRIFT on `status=EXECUTED`
   (**expected** — mid-flight, flips to MATCH at VALIDATED).
- **RAG card** `study-state-ledger-lifecycle` (authored, in the well's SOURCE
  `scripts/rag_verifier/harvest_lifecycle_contracts.py`, so it survives
  re-stage): documents the study-state ledger — what it is (`study.status` +
  `audit_log`, 7-state machine in `ontology_actions.py` `STUDY_TRANSITIONS`),
  how it works (evidence preconditions per transition, audit append per step,
  reconcile soft convergence meter → hard closure gate), what initiates it
  (`study_ledger.py` trigger = sole runtime writer; seed is bootstrap). Staged
  (42 cards), seeded BOTH roots — full via `--remote-embed` on the live 8B
  (:8765, no GPU floor), small local 0.6B. Verified: both roots missing=0/
  stale=0/zero_vectors=0, card live, retrieves top-1 (score 5.625) on the live
  service.
- **Backup** pre-backfill DB: `/tmp/opencode/ontology_pre_backfill.duckdb` (1 study).

## Commits (agentic_trading, master)

- `407c00c9` — Phase 11a reconcile manifest + INDETERMINATE claim status
  (5 files: reconcile.py, schema.yaml, ontology_actions.py, specs/spec,
  specs/fixtures/spx_0050.reconcile.yaml). Pushed.
- `39c7be80` — RAG card source: the `study-state-ledger-lifecycle` card added
  to `scripts/rag_verifier/harvest_lifecycle_contracts.py` (1 file, +23).
  Pushed. (The staged JSONL + indexes are in the RAG's gitignored working area,
  not committed.)
- The backfill itself is **not committed** in agentic_trading: `ontology.duckdb`
  is gitignored, the backfill script is in `/tmp/opencode/backfill_gamma.py`.

## Open / next

- **`reconcile.yaml` commit — RESOLVED (user committed, 2026-09-17)**: it lives in
  `/data/research_agent` (a separate git repo this seat's git permission can't
  reach), so the user committed it directly. All three repos now committed.
- **`verify.py` now 48/11** — the 11 failures are the obsolete "seed-only global
  count" assertions (`seed/verify.py:57-63,74`: exactly 1 study, 3 datasets,
  …). They assumed the DB holds only spx_0050; no longer true after backfill.
  NOT invariant violations (the 5 real invariants pass cross-study:
  birth-row-per-study, legal-transitions, supported-has-evidence,
  dataset-sha256-nonnull, no-orphan-edges). Fix = make verify.py
  multi-study-aware. Not done (separate change).
- **Gamma study is at EXECUTED, not CLOSED** — final adjudication not yet done;
  advancing to VALIDATED→CLOSED is a governance claim (not invented). When it
  happens: `study_ledger.py --study gamma_node_price_pull_discovery validate`
  then `close` (closure gate should go CLEAN then).
- **Phase 11b** (AGENTS.md + 6 prompt wiring into the research agent) and
  **11d** (ledger-guard) still scoped, not built — both PM-gated.
- **agentic_trading/studies** (15 studies) NOT backfilled — different layout,
  no decision memo / claim verdicts; a separate PM scope decision.

## Amendment — 2026-09-19: card location fix (pi seat)

The card's location text was misleading: it used relative `ontology_lab/...`
paths next to "/data/research_agent" (the wiring repo), so a reader (and a
fresh session) could place the code + DB under /data/research_agent. They do
not live there. Fixed in `scripts/rag_verifier/harvest_lifecycle_contracts.py`
(entry `study-state-ledger-lifecycle`): absolute paths for the code
(`/data/agentic_trading/ontology_lab/`), the ledger DB
(`/data/agentic_trading/ontology_lab/ontology.duckdb`, DEFAULT_DB in
study_ledger.py), the one-shot seed (`seed/seed_spx_0050.py`), plus an
explicit "WHERE IT LIVES" sentence stating /data/research_agent holds only
the phase-transport wiring (commit 7f9dac4 — verified, that claim was
already correct). Edit dispatched to qwen38-collab (qwen-coder's :8081 was
down); refresh via documented pipeline (scan-stage → full root
remote-embed :8765 → small root CPU); both roots missing=0/stale=0/
zero_vectors=0; live service retrieves the corrected card (score 5.06).
Verify receipts: verify/ragcard-edit-{diff,compile,harvest}.20260919T1134*.txt,
verify/ragcard-live-retrieval.*.txt.
