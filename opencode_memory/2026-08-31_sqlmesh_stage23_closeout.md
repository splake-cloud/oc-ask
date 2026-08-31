# 2026-08-31 — SQLMesh Stage 2+3 iron-fly recovery: formal closeout

Resumed after ctx-overflow mid-build. The full-week restate had ALREADY
applied successfully (rc=0) and P1–P7 passed before the overflow; the
overflow truncated the closeout JSON and left the scratch clone in place.
This session re-verified, regenerated the closeout, snapshotted, and cleaned up.
**Stage 2+3 iron-fly recovery is formally CLOSED.**

## What was done (all PM-directed, all verify-run-transcripted)

1. **Re-verified live state read-only.** DB sha `80a489f5…`, WAL absent,
   quiescent (no writers/fd holders). Confirmed the full-week restate
   `[2026-08-24, 2026-08-29)` on `iron_fly_weekly_substrate_v2` (version
   `1103730983`) is live: 1,949,021 rows / 901 days / phys max 2026-08-28 /
   interval max_end(excl) 2026-08-29 / 5 dates 08-24..28 = 1620/2340/2340/2340/2100
   / dup(key,valuation_ts)=0 / only iron v2 changed / prod refs unchanged.
2. **Regenerated `08_closeout_proofs.json`** (was truncated 460 B, invalid JSON).
   Fail-closed generator `/tmp/opencode/wh_recovery_20260830/regen_closeout.py`:
   preserved the truncated file as `08_closeout_proofs.json.truncated` (never
   overwritten), wrote to `.tmp`, JSON-parsed the temp, atomically renamed.
   Reconciles 12 values vs BOTH `07_apply_and_proofs.json` (authoritative) AND a
   fresh live read-only query — all match. `ALL_CLOSEOUT_OK=true`.
3. **Created + hash-verified the post-restatement snapshot** (none existed):
   `backup_archive/permanent/warehouse.duckdb.bak-post-restatement-stage23-20260831T034447Z`,
   sha256 `80a489f5…` == live.
4. **Marked the failed-apply backup** `…bak-FAILED-apply-2day-restate-20260831T030110Z`
   with a `.DO_NOT_RESTORE` sidecar: "DO_NOT_RESTORE — INCIDENT EVIDENCE: two-day
   restatement produced zero physical rows and added false-complete interval
   state." (PM wording; deliberately NO "version None" explanation — that wording
   is not independently proven by the failed-apply receipt and differs from the
   recorded mechanism.)
5. **Removed only the two scratch targets** (no wildcards, parent dir intact,
   28 evidence/script entries preserved): `/tmp/opencode/wh_recovery_20260830/warehouse.duckdb`
   + `clone_fw/` = **53.70 GB reclaimed**.

## Key facts settled (paths)

- Durable evidence: `/data/agentic_trading/verify/stage2_wal_recovery_20260831T015141Z/`
  — `07_apply_and_post_proofs.json` (authoritative, P1–P8 ALL PASS),
  `08_closeout_proofs.json` (regenerated, valid), `08_closeout_proofs.json.truncated`
  (preserved), `09_postrestatement_snapshot.json`, `10_final_closeout_verify.json`
  (21/21 checks PASS).
- verify-run transcripts: `verify/stage23_closeout_regen_08.*`,
  `stage23_postrestatement_snapshot.*`, `stage23_scratch_cleanup.*`,
  `stage23_closeout_final_verify.*` (all exit=0).
- Backups KEPT in `permanent/`: pre-migration-02360, pre-apply-stage2 (0.236.1),
  FAILED-apply-2day-restate (now DO_NOT_RESTORE), post-restatement-stage23 (new).
- Live DB `/data/warehouse/warehouse.duckdb` sha256 `80a489f5…`, WAL absent.

## Traps / notes

- The ctx-overflow symptom was a **truncated JSON write** (file cut mid-key), not a
  data problem — the DB itself was already correct. Always regenerate the closeout
  via temp+validate+atomic-rename, never in-place.
- The `q(con, …)` closure bug in my generator (closure `q(sql)` vs `q(con, sql)`)
  aborted fail-closed before any rename — the preserved-truncated step had already
  run, so re-runs were idempotent.
- Scratch `warehouse.duckdb` (26.8 GB) is the CLONE copy used to validate the plan
  before the live apply; `clone_fw/` is its sqlmesh working dir. Both disposable.
- The dirty `/data/agentic_trading` git worktree (L3-A/L3-B, iv_weekly, etc.) is
  UNRELATED to this build and was left untouched.

## Open / next

- **CLOSED (2026-08-31, PM ruling).** Committed `7a980379` "ops: close iron fly
  warehouse recovery" (22 files: evidence dir incl. `.truncated` + 5
  verify/stage23_closeout_* transcripts + the incident receipt, which was
  previously untracked). Commit on branch `iron-fly-economic-baseline`.
- Provenance section added to the incident receipt
  (`studies/iv_weekly_substrate/receipts/2026-08-30_stale_warehouse_incident_forensics_and_recovery_plan.md`):
  2-day restate = NOT a valid recovery (0 rows + false-complete interval);
  authoritative recovery = full-week restate [2026-08-24, 2026-08-29), version
  1103730983; DO_NOT_RESTORE sidecar represented in-repo (sidecar itself stays
  in the backup archive).
- The 2-day restate that failed (0 rows + false-complete interval) is preserved
  as incident evidence only — do not restore.
- Residual non-incident workstreams (unchanged by this closeout): Stage 1
  source-refresh (blocked), Stage 4 conditional janitor, Stage 5 re-enable
  advance (K=3), durable invocation auditing (approved design task).
