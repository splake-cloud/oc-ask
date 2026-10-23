# 2026-10-21 — Training Runtime Playbook built from full log mining

## What was built

`/data/agentic_trading/docs/TRAINING_RUNTIME_PLAYBOOK.md` (~1,480 lines) — the
living reference for running future tuning on this box. Sections:

1. Machine/roles/containers (GPU map, model roles, docker inventory incl. the
   idle `unsloth/unsloth:latest`)
2. Both RAGs (`:8765` system, 31 collections via `scripts/rag-search`;
   `:8090` lit-review, 14 model-tuning papers / 4022 claim rows)
3. DataDesigner 0.9.4 reference (docker `create` form + the 10-12→14 step-rail
   variant + 26-run inventory + 7 gotchas)
4. Known prior failures with verbatim evidence (serving crashes, training
   crashes, data-gen failures ×15, leakage, hash drift, seat/ops ×14,
   harness/tooling ×8, the 14-incident taxonomy, dev-eval baselines)
5. Errors/mistakes ledger (keys = Form-T re-key campaign, leakage, OOM,
   crashes/resume, hash drift, ops)
6. Working runtime recipes (configs by era with numbers, the :8911 rig
   verbatim, eval protocols, receipt schema, timings)
7. Affirmative checklist — 27 gates in 5 phases, each naming the failure it
   prevents
8. `tune_state` ontology design v0 (SFT/DPO/KTO/RL/STaR method dimension;
   NONE→…→★RUN_PLAN_RATIFIED→…→★ADJUDICATED→CLOSED; 5 candidate invariants;
   failure→gate mapping; shadow→ledger→enforce rollout)
9. Open ends (16 items) + appendices (receipt map, evidence base)

## Key facts settled (with sources in the doc)

- **"many keys" = the Form-T answer-key re-keying campaign** (rekey8012 73
  rows, gate113 113 packets, borderline C503/C623) — NOT key bloat, NOT API
  keys. Standing standard: "AN requires a record that explicitly contradicts;
  a related-but-different fact is NE."
- **R1 EngineCore crash true root cause** (independent audit 10-12):
  `Qwen3_5ForConditionalGeneration` declares `embedding_modules =
  {embed_tokens, lm_head}`; with `target_modules=None` vLLM wraps lm_head
  weightlessly → Surface 1: MTP drafter `lora_expand` on embed_tokens → Xid 31
  (XQA OOB); Surface 2: `lm_head lora_shrink` → Xid 43. The seven-target
  `--lora-target-modules` flag is the fix (tells vLLM the real targets),
  grounded at `qwen3_5.py:313-316`; "same code paths in 0.31.0".
- **Two 9-case dev evals, do not conflate**: adjudicated epoch-3/prior-45
  = 5P/1PART/3F (baseline 7P/2F); NEW-65 on repaired server = 8P+1PART
  (Base 6P/1P/2F; Prior-45 column matches).
- **PM binding verdict on the R1 harness** (10-12): harness failures
  (mis-selection, parser dup, false health, production kill, dead watchdog) +
  narrative-ahead-of-evidence diagnosis were "avoidable and not an acceptable
  baseline for a pilot"; 4-part protocol, headline check: "does the evidence
  prove the harness OUTPUT, or that the harness is VALID?"
- **step-8 D1 field drop**: recon rebuilt messages as {role, content} only →
  supervised 734,161 → 57,854 (12.7×, ~92%); all downstream recon void.
  D2 judge-view cap (120k = 90k head + 29,940 tail) truncated 110/127
  official views (min visible-task 0.09); "cap design must be per-window, not
  the flat 120k".
- **bf16 is the working training dtype** (4-bit canary OOM'd at step 1,
  reserved 101.179 GB); bf16 TRL path is NOT bit-reproducible (real17 _01/_02
  same seed/data/adapter → different final weights).
- **No checkpoint has ever been promoted**; production seats serve base.
- Adapter estate: **23 adapter_config.json live** (RAG card's "13" stale);
  all adapters freeze the 48 DeltaNet layers' projections.

## Method

6 parallel mining agents (pi 10-09/11, 10-12/14, 10-15/20, codex+receipts,
claude-code, memory-cards+derived-tree) + host-vantage live checks. R4's
handle was cleaned up mid-look but its transcript (and later its final
report) carried the 10-12/14 evidence; one contradiction (dev-eval numbers)
was settled against `HANDOFF_20261012_current.md` directly.

## Continuation re-verification (2026-10-21, continuation agent)

Cold-start continuation re-verified every load-bearing claim of the handoff
brief (`docs/HANDOFF_training_runtime_playbook_20261021.md`, `6c43aaf41`) against
disk — state matches; nothing moved since handoff:

- 3 commits + Agent-Print trailers intact; playbook is **1,593 lines on disk**
  (brief's 1,485 is at `8ce3aeb96`; +144/−36 from the v0.1 fix reconciles
  exactly); §8.3b/§8.5 carry all three v0.1 deltas verbatim.
- `ontology_dev` is under **`/data/research_agent/`**, not the repo: vocab
  v0.30.0 (27 categories; `StudyState` reference, `SPECIALIZES` substrate
  already minted), `study_transition` machine v1.1.0 (single-machine-per-file,
  dict keyed by state, "candidate (shadow-mode only)"), `routing_policy`
  v1.0.0 SHADOW. Files untouched since Oct 7 — no shadow work started (correct:
  blocked on PM sign-off).
- `ontology_lab` holds both reconcile classes (`reconcile.py` read-only,
  `study_ledger_reconcile.py` one-way advancer) + `actions/`
  (`STUDY_TRANSITIONS`, `RATIFY_BOUNDARY_TARGETS`) — shadow/ledger patterns
  confirmed in place.
- Live: 23 `adapter_config.json` under `/data/agentic_trading/training` (2 in
  HF cache, excluded); RAG :8765 healthy (host vantage, netns 4026531833);
  ~1,391 dirty entries — the `add -A` trap is live.

New detail to settle at shadow step (do not guess): brief says "tune_transition
machine **1.2.0**" but `study_transition` is v1.1.0 in a single-machine-per-file
format — a *new* machine starting at 1.2.0 is odd versioning; resolve as either
a file-level version or a new machine file at 1.0.0.

## Pending PM answers (tracked as OPEN pending_decisions since shadow step, 2026-10-21)

Per design **v0.2** (same day, PM review input #1): these open as tune-domain
`pending_decision` records at shadow rollout (INT-0068's promoted control
primitive, `tools/pending_decision_log.py` machinery; DEFER = OPEN stays
first-class) — this card is the prose shadow, the pending_decision log is the
authoritative tracking home. The five training-side calls gate the first real
run at its ★ boundaries; the design sign-off (kind `DESIGN_RATIFICATION`) gates
the rollout itself.

1. **Form-T training gate** — train on what? batch3's 31 admitted pairs (the
   standing ask: regenerate the 5 content failures OR replace the 2
   underdetermined source questions; "do not start another training pass from
   this content review alone"); set2's 40 `sft_ready` TRL-checked but
   unconsumed.
2. **real17 deck** — train or no-train on the adjudicated SFT export (24 tasks
   tie 5/5; E07 invalid; A10 favors trained arms); plus commit/push strategy
   for the `adjudicated-sft-export-20261019` branch.
3. **Five-window corpus scope** — scope + exposure budgeting (GPU work Paused;
   "serialization sample for verification — not an agreed training corpus");
   sub-questions: recon re-judge scope/seat, per-window length-pruning design,
   W1+W2+W4 (70,360-token) selection ruling.
4. **Training venue** — unsloth container (GPU pass-through through Docker
   untested, image idle since 2026-05-31) vs native `.venv-training` (path of
   record).
5. **Activity-log incident holdout** — still needed to test the original
   operational goal; distinct from the frozen public holdout (2026-10-21) —
   do not conflate.

All five are now durable: OPEN in `telemetry/pending_decisions.jsonl`
(DECISION RECORDS: see `list --kind CONTENT_ADMISSION` etc.; studies
`tune_formt_training_gate`, `tune_real17_deck`, `tune_five_window_corpus_scope`,
`tune_training_venue`, `tune_incident_holdout`), plus 8 backfill
ADJUDICATIONs (study `tune_<run_id>`). The five do NOT block the ontology
shadow work — they block future training runs, which is exactly what the
★RUN_PLAN_RATIFIED boundary exists to formalize; each answer lands as a
RESOLVED record + R-####.

## Ledger build + ingest (2026-10-21, same day — commit `e8ab6fce6`)

Scope called up front: **ledger + ingest only** — the live advancer
(`tune_ledger_reconcile.py`) and read-only `reconcile` deferred (no live tunes
emit observations yet), `ontology_dev` untouched (still gated on v0.4 sign-off),
no ENFORCING.

- `ontology_lab/tune/` (mirror of the study-ledger architecture as a sibling):
  `tune_actions.py` (TUNE_TRANSITIONS per §8.3 v0.4: NONE→SOURCED→ACQUIRED→
  CLEANED→PREPARED→FROZEN→★RUN_PLAN_RATIFIED→TRAINED→EVALUATED→★ADJUDICATED→
  ATTACHED|CLOSED; **no BLOCKED** per INT-0068; SHADOW evidence preconditions
  = PENDING/MISSING facts + WARN, never block; machine legality always enforced),
  `tune_ledger.py` (CLI sole writer: birth/8 transitions/step/state/list;
  exit 0/1/2, TUNE_NOT_REGISTERED), `schema_tune.yaml` (tune_run + append-only
  tune_audit_log + tune_step_log; TuneState 11 / TuneMethod 5 / ObjectiveKind 3),
  `seed/init_tune_db.py`, `seed/ingest_tune_backfill.py` (one-shot idempotent).
  DB: `tune_ledger.duckdb` (gitignored, like ontology.duckdb — code + JSONL are
  the tracked artifacts).
- **Ingest result**: 8 tune_runs from `inventory.jsonl`, all at EVALUATED
  (true position), provenance HISTORICAL_BACKFILL throughout. 64 audit rows
  (8 births NONE→SOURCED + 8×7 transitions), 56 step rows; 6 MISSING facts
  (FROZEN manifests absent — pre-repair lineage) + 15 PENDING facts (receipts/
  manifests/train_state gaps, dirty-by-design). Canary artifact excluded
  (NOT_A_TUNE_RUN — it is gate evidence, not a run).
- Bounce caught on independent verify: first build attached the checkpoint
  `adapter_model.safetensors` hash under the `adapter_config.json` path for the
  6 manifest-MISSING runs (hash real, URI wrong, semantics wrong — weights are
  TRAINED output, not a frozen manifest). Fixed: FROZEN now 3-case (file-hash
  resolve / JSON field value / MISSING marker). Re-verified 14/14 stored shas
  against cited files, incl. `launch_manifest.json` = 35eba5e3d6478bed and
  `TRAIN_FREEZE.json` export_sha256 field = b29439f878b7dba0 (pair_count 99).
- Receipt: `verify/tune-ledger-ingest-20261021.txt` (counts, FROZEN rows,
  sha re-verify, idempotency: re-run exit 0, 0 new rows).
- **PM call still open (do not self-decide)**: the 8 ADJUDICATION
  `pending_decision` records are NOT yet opened. Form is a PM ruling: OPEN
  (awaiting real adjudication — my recommendation; receipts' "no promotion"
  prose is a finding, not a PM ruling, and the machine's ADJUDICATED step
  needs a ruling ref) vs RESOLVED-citing-receipts. Command ready: `python3
  /data/research_agent/tools/pending_decision_log.py open --study tune_<run_id>
  --kind ADJUDICATION --question ...` ×8.

## Rollout step 1 (shadow) — DONE 2026-10-21 (PM ratified v0.4)

- **Ruling banked**: `pm_ruling_tune_state_v04_ratification_20261021.md`
  (ontology_dev); **PD-00160** DESIGN_RATIFICATION RESOLVED [DECIDED].
- **ontology_dev 0.31.0** (research_agent repo, commit `8c69105d`,
  append-only, verified additive): PendingDecisionKind +7 (now 13;
  `tools/pending_decision_log.py` derives its kind whitelist from this
  vocabulary — new kinds became usable automatically); new categories
  TuneState (12 incl. NONE sentinel), TuneMethod (SFT/DPO/KTO/ORPO/RL/STaR),
  ObjectiveKind (3); `objects.json` 1.8.0 with `tune_run` (OC-003);
  new `tune_transitions.json` machine file.
- **Machine-version detail settled + banked in the ruling**: new machine
  file starts at **1.0.0** (single-machine-per-file format; the handoff
  brief's "1.2.0" was a versioning slip against study_transition's 1.1.0).
- **14 pending_decisions opened** (all OPEN) + the resolved ratification:
  5 training-side calls — Form-T gate (CONTENT_ADMISSION), real17 deck
  (CONTENT_ADMISSION), five-window corpus (CORPUS_SCOPE), venue (VENUE),
  incident holdout (EVAL_HOLDOUT) — + 8 backfill ADJUDICATIONs
  (one per run; the receipts' "no promotion" is a finding, not a ruling →
  OPEN, dirty-by-design; PM can resolve any via the log tool).
- **NOTES (follow-up, not done — no PM ask):** the ledger's TuneMethod enum
  (`ontology_lab/tune/schema_tune.yaml`: SFT/SFT_MULTI_TURN/DPO/GRPO/
  SFT_MULTI_TURN_DPO) diverges from the ratified design values
  (SFT/DPO/KTO/ORPO/RL/STaR). Latent — all 8 ingested runs are SFT. Fix =
  enum align + db rebuild (fast); do with the first non-SFT run or on PM
  ask. Also: `test_ontology_dev.py` baseline gap is pre-existing (0.30.0 was
  never baselined; test asserts vs last baseline) — untouched by design.

## Next-step read view (blocker joined at read) — DONE 2026-10-21 (commit `31cba1c20`)

PM requirement (verbatim): "if a training or eval run is stopped at a PM
decision, the outstanding decision should be reflected. I should be able to
pull the training state engine and pull up an inflight training or eval and
know where it is and pick it up based on what is registered."

- `tune_ledger.py next` (+ compact gate lines in `state`): position /
  registered (objective, run_facts, per-stage evidence with PENDING/MISSING
  gaps) / next step (next legal edge) / gated by (the joined
  pending_decision — live status, verbatim question, exact resume commands)
  / missing decision → exact `pending_decision_log.py open` command.
- Join is **at read** (design §8.3: "position and blocker are orthogonal…
  separate record joined at read"): `study_id == 'tune_' + run name` + kind
  per boundary; latest line per decision_id wins; no stored pointer, no
  commit ref (provenance lives in resolution_ref / audit authorization_ref).
- All 8 backfill runs now render: EVALUATED → next ADJUDICATED, gated by
  their PD-0016x (OPEN). Read-only verified (sha256 before/after).
- **Behavioral rule settled with PM (this is doctrine now):** outstanding
  points are STATE the system holds — do NOT surface them to the PM as a
  standing "answer these" list. A decision reaches the PM only when a
  concrete next step is blocked by it (one decision, evidence +
  recommendation); derivable ones (e.g. venue → path of record) get
  derived + recorded, not asked. "Pull up a run, know where it is" is a
  query against state, not a conversation.
- **Two bounces on this mission (scored findings, both mine or spec's):**
  (1) first build auto-advanced boundary commands through intermediate
  states to satisfy my own buggy V6 test (which called `ratify` from
  PREPARED) — write-path machine-semantics change beyond closed spec;
  reverted, single-step restored (illegal jump refused
  TUNE_STATE_TRANSITION_NOT_ALLOWED, verified on a real run). Lesson:
  when my test contradicts the spec, the test is wrong — delegate must
  bounce the contradiction, not adapt the machine. (2) evidence line lost
  stage names (`STEP=COMPLETED` ×7 → fixed to `ACQUIRED=COMPLETED, …`).
- Receipt: verify/tune-next-view-20261021.txt.

## Current gate state (as of 2026-10-21, post-next-view)

- Rollout: shadow **DONE** (above) → ledger **DONE** (commit `e8ab6fce6`)
  → backfill ingest **DONE** (source `ff3e79ec9`) → **enforce LAST**
  (flip invariants blocking at the ★ boundaries; still needs the 5 open
  training-side answers to be meaningful, since those gate the first real
  run at its ★RUN_PLAN_RATIFIED).
- Deferred: `tune_ledger_reconcile.py` advancer + read-only reconcile (no
  live tunes emit observations yet — they fire with the first live run),
  the 5 training-side PM calls + 8 ADJUDICATIONs (OPEN in the log).

## Open / next

- Playbook is a living doc — amend as runs land (Form-T training is the next
  likely run; the §7 checklist is the gate sequence for it).
- **tune_state design v0.1 (same day, after PM review of v0):** three design
  defects resolved in the doc — (1) ADJUDICATED is now the FORK before
  ATTACHED (REJECT → CLOSED, no attachment of any kind; isolated serving
  smoke lives in EVALUATED on the :8911 eval rig only; §7 gate 27 split into
  27/28/29); (2) reconcile split into the read-only drift check
  (`reconcile.py` class: "It is read-only… opened read_only=True") vs the
  one-way non-blocking advancer (`study_ledger_reconcile.py` class: "Advances
  the ledger one legal 7-state step at a time via the governed action… Never
  retreats") — v0 had conflated them; the tune design mirrors as
  `tune_ledger.py reconcile` + `tune_ledger_reconcile.py`; (3) new §8.3b
  per-method transition evidence (DPO: pair provenance + direction/swap-rate
  audit + ref-policy pinned by hash; KTO: label-mix audit; RL: reward pinned
  by hash + KL/length guards + guard-halt audit; STaR: rationale provenance
  + verified-correct-answer filter + reasoning-behavior check). Shadow
  rollout is gated on §8.3b for non-SFT methods. PM verdict: "suitable as a
  design basis and an immediately useful checklist; not yet a validated
  tuning state ontology or an enforceable runtime gate."
- tune_state design v0.4 needs PM review before the ontology_dev append
  (shadow mode first per §8.5). Ledger + backfill ingest already landed
  independently of it (see "Ledger build + ingest" above) — the append
  formalizes the vocabulary/machine in `ontology_dev`, the ledger implements
  the same machine as working SHADOW code.
- RAG: DataDesigner runbook card + adapters-card refresh (13→23) still owed.
  **tune-state card DONE 2026-10-21**: `tune-state-ledger-lifecycle` in the
  `lifecycle_contracts` well (AUTHORED list in
  `scripts/rag_verifier/harvest_lifecycle_contracts.py`, commit `cd1dd0fa4`);
  44→45 cards, full/mid/small live, retrieves #1 for tune-state phrasings.
  **Accuracy fix same day (PM: "a right there are 3")**: study card opening
  TWO→THREE ontologies, labels now (1) DOMAIN-STUDY / (2) DOMAIN-TUNE / (3)
  STATION (commit `8f88bcc13`), both cards reseeded all roots.
- Scratch: /tmp/playbook_synthesis_notes.md, /tmp/r4_report.md, /tmp/r6_report.md.
