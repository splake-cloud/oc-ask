# BPV v8 — Two-lane blueprint-validation control plane (Session Receipt)

**Date:** 2026-09-27 (work spanned 2026-09-25 → 09-27; commit + push 09-27)
**Seat:** pi / jett-8011 (qwen3.8-27b-fp8), workdir /data/research_agent
**Mission (PM):** one complete blueprint validation in ≤10 min (dispatch → sealed
report) without sacrificing fidelity, with **8081 as a genuine second validation
lane** (not a formatting worker) and no stall-based restarts.
**Terminal state:** shipped — commit `7e4d321` pushed to origin/master (23 files,
+7799/−264). v7 retained as the v8 substrate (claim + publish lifecycle reused).

## What was built

**Two-lane model (PM ruling rounds 1–4; receipts `receipts/pm_ruling_bpv_v8_{revisions,r2_twolane,r4_final}_2026-09-26.md`, INT-0136…0160):**
- **8081 scoped lane** — complete disjoint Phase-1 sections + one workload-balanced
  Phase-2 slice + Phase-3B source conformance. Verdicts **PROVISIONAL**.
- **8012 recon lane** — remaining Phase-2 slices (all claim-bearing objects:
  decision transition / evidence-to-licensing / quantity-to-claim /
  verdict-to-action MUST sit here), freeze audit, gapfill, 3A, 2′
  source-discovered objects, Phase-4, final synthesis — **only recon issues the
  three anchored final verdicts**.
- Independence fallback: author == 8012 → **single-lane-8081** (router's 8011
  fallback rejected — shares 8012's model family).
- Stop policy: T1 dropped; one informational status line at 5 min; T2 = runner
  budget 10 min + supervisor outer 11 min = the first and only time-based stop;
  no automatic restart.
- Process discipline: per-child `setsid` groups, registry (pid+pgid+starttime),
  `Popen.poll()` authoritative reaping (zombies = gone), sweep is a **check** not
  the kill mechanism; SIGTERM graceful handler; claim release is **sweep-gated**
  and `RESIDUAL_WRITERS_UNCONFIRMED` makes `recover` refuse (rc 4) until manual
  disposition.
- `--continue` = missing-work-only continuation under the SAME frozen identity
  (claim must be RUNNING and bound to the dispatch dir; completion re-derived from
  on-disk gate artifacts, never progress.json).

**Control plane (8011 authored):**
- `tools/bpv_pipeline_runner.py` — stage machine: phase1 → combiner → freeze →
  **post-freeze** lane split (split needs the frozen register) → parallel slices →
  coverage loop (≤3 gapfill rounds) → 3A/3B parallel + 3C station script →
  conditional 2′ (global ID assignment O-max+1, mechanical register merge) →
  Phase-4 → deterministic merge to draft. Exit codes: 0 published / 1 failed /
  2 budget.
- `tools/detached_supervisor_template_v8.sh` — v7 envelope + 12 fills + runner
  launch + 5-min status + sweep-gated claim release + 11m outer budget.
- `prompts/blueprint_validator.template.md` v8 — 14 tokens; all-key=value machine
  lines (including `id=`); checker-enforced **GATE** (objects = verdicts = VERDICT
  count; partitions = PART; minimums = MIN; gaps = GAP; 8081 stage file without
  GATE → exit 2); verify-before-exit gate (SURVIVES forbidden on incomplete
  records; gaps named GAP-##); Phase 4 receives complete stage records +
  mechanically generated adverse-ID list (navigation, not sole evidence).
- `tools/dispatch_blueprint_validator.py` v8 — sections from blueprint `##`
  headings (alternating 8081-first), 14-token config.json, report port = recon
  lane, `main_continue()` (--continue).
- `tools/validation_claim.py` — RESIDUAL recover guard (rc 4,
  `REFUSED_RESIDUAL`).
- 8081 deterministic modules (delegated): `bpv_format.py` (extended with
  PREFIX_STAGE/PREFIX_CHECKPOINT), `bpv_combiner.py`, `bpv_coverage_check.py`,
  `bpv_lane_split.py`, `bpv_merge_report.py`, `bpv_phase3c_check.py`,
  `bpv_workload_weights.json` (calibrated to BPV-00018 register).
- Docs: `AGENTS.md` (Two-lane validator (v8) binding rules under "Supervised
  worker dispatch"), `ontology_dev/supervised_worker_dispatch.md` (full v8
  mechanism), `prompts/blueprint.md` Exit (v8 dispatch + --continue).

## Key facts settled

1. **Two format-mismatch classes caught before ship** — (a) 19 template
   machine-line examples written in prose `O-01:` form vs the `OBJ id=O-01 ::`
   all-key=value contract: template examples rewritten, 31/31 shapes parse;
   (b) 3 coverage-checker bugs (per-file GATE vs cross-file false exit 2; GATE
   presence required only for 8081 slices; gapfill files now parsed).
2. **Zombie root cause (found twice, same bug class):** `kill -0` answers yes for
   state-Z (unreaped) processes — "residual live writers" in two separate
   scenarios were actually unreaped children. Authoritative liveness =
   `Popen.poll()` in-process + /proc state-Z-aware fallback. Any future
   "process still alive" alarm on a child we spawned should be checked against
   /proc state first.
3. **3B station pre-resolution:** the runner resolves every manifest `source_id`
   to its corpus card deterministically (station holds corpus + manifest) and
   writes `stages/resolved_obligations.md`; the 8081 worker reads the file and
   never does the lookup. 3C families path is station-level
   (`ontology_dev/families.json`).
4. **Upstream integration:** origin/master advanced mid-work (1780400 generalized
   the BPV dispatch doctrine into "Supervised worker dispatch" + study-ledger step
   lines). Only `prompts/blueprint.md` overlapped; stash → fast-forward → pop,
   no conflict. Plain push to master cannot overwrite (non-FF rejected); the ship
   was a fast-forward over concurrent seats' commits.
5. **Verification:** 51 unit checks (`tools/test_bpv_units.py`) + 37 stub checks
   (`tools/test_bpv_v8.sh` S1–S7: happy path, gap+gapfill, T2 budget, freeze
   STOPPED, child failure, --continue resume, full supervisor envelope
   fill→launch→publish→anchored-verdict→claim-release) + SIGTERM path (all
   children reaped, TERMINATED, zero orphans) + claim-guard scenario + dispatcher
   dry-run on credit_fly_fat_premium (14/14 tokens, 16 sections → 8/8 two-lane).
   Test seams: `BPV_TEST_WORKER_CMD`, `BPV_STUB_*`, `BPV_CLAIM_DIR`/`BPV_CLAIM_AUDIT`.
6. **Frozen prompts baseline** (step-1 receipt, AF-00376):
   `receipts/prompts_freeze_baseline_2026-09-26.md` — 13 files, sha256-16 table,
   baseline commit `7983577`.
7. Artifacts registered: AF-00386…00392; telemetry CALL-00181 / EV-00854.

## Open / next

1. **Activation:** next review-ready exit of any study
   (`tools/dispatch_blueprint_validator.py --review-ready --study <name>`). First
   production run = the 10-minute concurrency measurement experiment (stubs prove
   the control plane, not model wall time).
2. **Calibrate** `tools/bpv_workload_weights.json` if the first real run shows
   lane imbalance (weights were calibrated to the BPV-00018 register).
3. Anchored-verdict contract unchanged (v7): last match in final 80 lines, three
   verdicts within 20 lines of each other — the runner pins the final bytes'
   sha256 in the claim.
