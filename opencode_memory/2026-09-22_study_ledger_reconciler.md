# Study-ledger reconciler — one-way non-blocking projection (built, verified, partially committed)

**Session:** opencode, qwen3.8-27b-fp8, `/data/agentic_trading` (2026-09-22).
**Trigger:** user asked why the 7-state study ledger was stale (credit_fly stuck at
AUTHORIZED while the Research Agent was at BUILD_SPEC_RATIFIED).

## Why the ledger was stale (root cause, from source)
1. The ledger machine (`ontology_lab/actions/ontology_actions.py:30-37`
   `STUDY_TRANSITIONS`) has only 7 states; the Research Agent workflow runs 11
   (`ontology_dev/vocabulary.json` adds NONE, BLUEPRINT_CANDIDATE,
   BUILD_SPEC_CANDIDATE, BUILD_SPEC_RATIFIED). The ledger was written to
   AUTHORIZED on 09-20 and no BLUEPRINTED call was ever made.
2. The two state systems are decoupled by design: Stage 9 `state_log.py`
   (`/data/research_agent/telemetry/state_observations.jsonl`) is append-only,
   non-enforcing, and "never writes to the target-workspace ledger." The enforced
   ledger's sole writer (`ontology_lab/study_ledger.py`) is never invoked from the
   research_agent workflow path. No cron / commit-hook / transport wires them.

## The ruling (PM, verbatim intent) — "the hybrid"
Treat the 7-state ledger as a **coarse canonical milestone projection** of the
11-state workflow. Synchronize **one-way** from authoritative workflow evidence
through a **non-blocking** reconciler. Do NOT expand the ledger to 11 states; do
NOT use "max observed state" literally (evidence governs, not labels); do NOT wire
direct `study_ledger.py` calls throughout transports — instead a **generic
projection hook** fired automatically after relevant state observations;
**sidecar failure never blocks research**.

## What was built (4 files)
- **`/data/agentic_trading/ontology_lab/study_ledger_reconcile.py`** (BUILD,
  qwen-coder) — `study_ledger_reconcile.py <study> [state]`. Reads the latest
  *usable* state observation, which **identifies the candidate workflow
  milestone** (maps 11→7 via a fixed table). The observation is a pointer, NOT
  the authoritative workflow state by itself. **Governed evidence establishes
  projectability**: the ledger advances one legal 7-state step at a time via the
  governed `change_study_state` (same precondition machinery as study_ledger.py
  — no direct SQL, no machine/enum change), and projects only the sealed
  sha-verified entities a precondition gate requires. A milestone that lacks
  projectable evidence is not advanced (STOPPED finding). Always exits 0 (except
  study-not-found); never retreats. `state` subcommand prints the 3-line
  Research-Agent / milestone / ledger drift surface.
- **`/data/research_agent/tools/state_log.py`** (EDIT, qwen-coder) — post-emit
  hook: after a real-study `emit` (not `_station`), spawns the reconciler
  (subprocess, 120 s, stdlib-only, stderr-only). Emit stdout/exit unchanged.
- **`/data/agentic_trading/ontology_lab/specs/study_ledger_reconcile_spec.md`**
  (spec, this seat) — the frozen PM ruling + 12 binding clauses.
- **`/data/research_agent/studies/credit_fly/specs/ledger_methods.yaml`** (data)
  — declares the one method the BLUEPRINTED gate needs
  (`day_clustered_bootstrap v1 APPROVED`, from build_spec F-09/I7).

## Key design facts (settled, from source)
- BLUEPRINTED precondition (`ontology_actions.py:219-244`) needs ≥1
  STUDY_USES_METHOD + ≥1 SPECIFICATION artifact. credit_fly had **neither**
  registered (0 methods, 0 artifacts) — so the reconciler must *project* entities
  from sealed evidence before it can advance (it did: blueprint.md as
  SPECIFICATION w/ seal sha `2245ad7f…`, method link to existing
  `day_clustered_bootstrap`).
- Milestone map: BLUEPRINT_CANDIDATE→AUTHORIZED (candidate ≠ ratified),
  BUILD_SPEC_RATIFIED→BLUEPRINTED (still pre-implementation). Self-limits: can
  only prove what the ledger's own preconditions prove; VALIDATED/CLOSED are out
  of reach by design (need content judgments it refuses to synthesize → STOPs).
- `day_clustered_bootstrap` already existed in the ledger (APPROVED), so
  projection *linked* it rather than registering.

## Verified (verify-run, this seat)
- credit_fly `AUTHORIZED→BLUEPRINTED`, exactly one audit row, actor
  `reconciler (evidence: SO-00021)`.
- Entity projection: `blueprint.md SPECIFICATION 2245ad7f…` + method APPROVED.
- Idempotent NOOP (2nd run, 0 new rows); no-retreat (CLOSED stays CLOSED);
  drift surface correct.
- Hook non-blocking — PROVEN ON THE WORKING TREE (scratch `--log`), not the
  authoritative repo: emit stdout=JSON only (json.loads OK); `_station` exempt;
  real-study emit fires the reconciler, ledger untouched. End-to-end auto-sync
  is PENDING the hook's commit to research_agent.

## Fix applied this session (2nd request): log path from DB dir
The first build hardcoded `RECONCILE_LOG` to the live dir, so copy-DB dev tests
contaminated the live `reconcile_log.jsonl` (18 lines, several re-claiming the
transition — telemetry only, `audit_log` clean). Fix: `_write_reconcile_log` now
derives the log from `os.path.dirname(db_path)` at write time (threaded
`db_path` through all 8 call sites in `_cmd_reconcile`). Proven: copy DB →
copy-dir log; live log unchanged. Live `state` surface still correct.

## Commit / push (3rd request) — PARTIAL, one hard blocker
Committed + pushed **`08c7dc4f`** to `master` (origin market_data): the two
`/data/agentic_trading` files (`study_ledger_reconcile.py` +
`specs/study_ledger_reconcile_spec.md`), Agent-Print trailer present, verified
on the remote (FETCH_HEAD == 08c7dc4f).

 **Deployment-incomplete (NOT conceptually unresolved) — 2 files, this seat
lacks repository authority:** `/data/research_agent` is a SEPARATE git repo and
this seat's git permission is denied there (allowlist = `git -C /data/agentic_trading`
+ `git -C /home/user/oc-ask` only). The two research_agent changes are complete
and verified in the working tree; they are simply not committed to the
authoritative repo. Committing them needs a seat with research_agent git access
(or a PM widening the allowlist). Distinguish the states explicitly:

```
RECONCILER
  implementation: LIVE          (study_ledger_reconcile.py, committed+pushed 08c7dc4f)
  live manual proof: PASS       (credit_fly AUTHORIZED->BLUEPRINTED via SO-00021)

POST-EMIT HOOK
  local working tree: PRESENT   (tools/state_log.py edited + verified)
  authoritative repo: NOT YET COMMITTED  (research_agent, no git authority here)

END-TO-END AUTO SYNC
  activation: PENDING           (fires only once the hook is committed/deployed;
                                 until then the reconciler runs on manual invocation)
```

The first two lines are the same synthetic/live conflation class corrected
elsewhere: the local working tree is NOT the authoritative repo.

## RAG card updated (4th request, 2026-09-22) — DONE, live both roots
Amended the `study-state-ledger-lifecycle` card source
(`/data/agentic_trading/scripts/rag_verifier/harvest_lifecycle_contracts.py:333`):
- "study_ledger.py is the SOLE runtime writer" → **TWO writers, both governed**
  (decision-point writer (a) + the one-way non-blocking reconciler (b)); NEITHER
  direct-SQL-updates study.status; reconciler is the **LIVE TRIGGER** via the
  state_log.py post-emit hook; spec path cited.
- Self-heal now **CODE-driven as well as prompt-based**.
- STATION section: corrected the pre-2026-09-22 "the station never writes to the
  ledger" → the station's latest state observation IDENTIFIES the candidate
  workflow milestone; the ledger's own governed evidence preconditions ESTABLISH
  projectability; the 7-state ledger is a COARSE PROJECTION synchronized one-way;
  the write only advances forward, one legal step, as far as evidence
  preconditions allow, never retreats/skips/overrides.
- triggers + citation_refs + severity_hint updated (governed-trigger wording).
Pipeline: scan-stage --groups lifecycle_contracts → seed full
(--remote-embed on live 8B, GPU-floor would have refused) + seed small (local
0.6B) → status full=live small=live. Verified: live :8765 top-1 serves the
corrected text. Committed + pushed `752b97dc`.

## Wording tightening (6th request, 2026-09-22)
PM: the state observation is NOT by itself the authoritative workflow state.
Corrected the distinction in all four locations (spec §2, reconciler docstring,
RAG card, memory card): the observation **identifies the candidate workflow
milestone**; **governed evidence establishes whether that milestone is
projectable**. The observation is a pointer, not the proof.
Also reframed the 2 research_agent changes: they are **deployment-incomplete**
(this seat lacks repository authority), NOT conceptually unresolved. Three-state
observability block added (RECONCILER / POST-EMIT HOOK / END-TO-END AUTO SYNC).

## Open / next
- Commit + push the 2 research_agent files (needs authorized seat) —
  deployment-incomplete, not unresolved.
- Commit + push the wording-tightening edits (spec, reconciler docstring, RAG
  card harvester source) — agentic_trading, this seat CAN commit.
- Ruling noted: the live `reconcile_log.jsonl` retains 18 pre-fix lines (incl.
  5 that re-claim the transition) — append-only, left as-is.
- credit_fly build dispatch is the next real step (ledger now correctly at
  BLUEPRINTED; it will advance to BUILT only when a SUCCEEDED-run observation +
  code evidence exist).
