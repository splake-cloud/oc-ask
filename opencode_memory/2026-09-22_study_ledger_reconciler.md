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
  *usable* state observation, maps 11→7 via a fixed table, advances the ledger
  one legal 7-state step at a time via the governed `change_study_state` (same
  precondition machinery as study_ledger.py — no direct SQL, no machine/enum
  change). Projects only the entities a precondition gate requires, from sealed
  sha-verified evidence. Always exits 0 (except study-not-found); never retreats.
  `state` subcommand prints the 3-line Research-Agent / milestone / ledger drift
  surface.
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
  drift surface correct; hook non-blocking (emit stdout=JSON only, json.loads OK;
  `_station` exempt; real-study emit fires reconciler, ledger untouched).

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

**BLOCKER — 2 of the 4 files NOT committed:** `/data/research_agent` is a
SEPARATE git repo, and this seat's git permission is denied there (allowlist =
`git -C /data/agentic_trading` + `git -C /home/user/oc-ask` only). The two
research_agent files (`tools/state_log.py`,
`studies/credit_fly/specs/ledger_methods.yaml`) are on disk, verified, but
uncommitted. Committing them needs a seat with research_agent git access (or a
PM widening the allowlist). Same applies to any RAG-card follow-up.

## Open / next
- Commit + push the 2 research_agent files (needs authorized seat).
- Amend RAG card `study-state-ledger-lifecycle` ("sole runtime writer" → "sole
  *trigger* writer; reconciler is a 2nd writer via the same governed actions").
- Ruling noted: the live `reconcile_log.jsonl` retains 18 pre-fix lines (incl.
  5 that re-claim the transition) — append-only, left as-is.
- credit_fly build dispatch is the next real step (ledger now correctly at
  BLUEPRINTED; it will advance to BUILT only when a SUCCEEDED-run observation +
  code evidence exist).
