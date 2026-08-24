# 2026-08-24 — SQLMesh daily cycle repair + PROD DB removal incident (restored)

## Latest session (post-commit health check + directive verification)
- Ran full directive verification: all 9 items verified against live system (file reads, grep,
  crontab, systemctl, duckdb queries, sqlmesh commands). Every claim has PROOF.
- Confirmed pre-patch EOD cycle (8/23 23:33) had `shadow_alert` with `all_ok=true` — proves
  both PATCH and HARDEN were necessary.
- System is healthy: 23 views, all Complete Intervals, prod env intact, plan matches,
  backup OK (0h old, smoke test passed).
- Committed and pushed 2 scoped commits (7 files total) — no more uncommitted directive edits.
- ~936 other unrelated uncommitted files remain in the repo (not touched).

## Headline
PM directive (PATCH/KEEP/REPOINT/HARDEN/REMOVE/THEN) executed. The REMOVE step **deleted the
production database** because `/var/tmp/warehouse_shadow` is a **symlink to `/data/warehouse`**
—the "25G stale shadow copy" and prod were the SAME file. Restored from the verified 8/23 05:32
backup, re-advanced, and fixed the real root cause (backup cron had no `duckdb` in its PATH for 3 days).

## What went wrong (the incident)
- Told to "REMOVE /var/tmp/warehouse_shadow/warehouse.duckdb" as a stale 25G shadow.
- It was `/data/warehouse/warehouse.duckdb` via symlink (`lrwxrwxrwx /var/tmp/warehouse_shadow -> /data/warehouse`, created 8/06).
- The trap was visible in my own evidence and I missed it: the "shadow" and prod had **identical
  byte sizes**, and the "shadow" mtime jumped to 15:58 exactly when the manual prod `sqlmesh run`
  wrote. Same file. `unlink` removed prod.
- Detected ~16:02, restored 16:06 (byte-identical, sha 10c3a327…390c), re-advanced 16:13,
  `check_intervals` all Complete 16:14, fresh verified backup 16:19. **Zero data loss** (only
  the 15:58 run's writes were lost, and that run was reproduced 16:13).
- **Contributing root cause:** the 02:00 backup cron had been failing 3 straight days (8/22–8/24)
  with "FATAL: Production database not accessible" — a FALSE alarm. `backup_sqlmesh_prod.sh`,
  `check_backup_health.sh`, and `backup_weekly_smoke_test.sh` all call `duckdb` **bare**, but
  `duckdb` lives at `/home/user/.local/bin`, **not in cron's PATH** (`/usr/bin:/bin`). Under cron,
  `duckdb` → rc=127 "not found". So the backup never ran AND the health check false-reported
  "CRITICAL: corrupted" daily. The newest real backup was 8/23 05:32 — had the DB died earlier,
  recovery would've been far worse.

## PM directive items — all done (verified)
1. **PATCH** `warehouse/shadow_run.py:56` + `warehouse/reconcile.py:285`: `config.yaml`→`sqlmesh.yml`
   (commit `49d264e1` had renamed the file; the `.replace()` path-rewrite targets are unchanged no-ops).
2. **KEEP** step 9 as sole SQLMesh nightly scheduler: confirmed 0 competing cron entries;
   `daily_eod_build.timer` (23:33 UTC) step 9 is the only advancer; dormant
   `warehouse_shadow_cron.sh` worktree already gone.
3. **REPOINT** `stg_spx_options_daily.sh` cross-check → **promoted view**
   `warehouse.warehouse.stg_spx_options` on `/data/warehouse/warehouse.duckdb`. Independence holds:
   both the parquet builder and the warehouse model derive from the RAW pool
   (`@spx_pool_glob`), not each other's output. (Read the view, not a physical
   `warehouse__stg_spx_options__<ver>` table — 2 versions match the prefix now and the
   TTL-expiring orphan would be a non-deterministic `hit[0]` pick.)
4. **HARDEN** `daily_eod_build.py`: `shadow_alert` now makes `all_ok=False` → non-OK exit
   (was line 527 overwriting line 524's signal with `not has_failure` only). `catalog_drift`
   stays non-blocking (PM scoped hardening to step 9).
5. **REMOVE** — DONE but it removed PROD (see incident). **Do NOT re-run.**
6. **THEN** — manual `sqlmesh run prod` (23/23 models, audits passed), `check_intervals prod`
   (all 23 models Complete Intervals), frontier **2026-08-21** (last trading day; 8/22–8/23 are
   Sat/Sun, no pool files — my earlier "1 day stale" note was WRONG, it was current).
   Next scheduled EOD cycle: 23:33 UTC tonight (step 9 now advances prod + hard-fails on error).

## Separate pre-existing bug fixed
- `scripts/stg_spx_options_daily.sh` lost its exec bit 8/18 19:12 → cron (invokes it directly)
  died `Permission denied` 6× (8/19–8/24, mails in `/var/mail/user`). `chmod +x` done. First
  clean parquet cycle: next 06:30 UTC. (Builder's `don't know what type:` when run mid-session
  is the documented live-file hazard at build_stg_spx_options.py:37-41 — the 06:30 slot is safe.)

## Root-cause fix (the important one)
- Added `export PATH="/home/user/.local/bin:/data/agentic_trading/.venv/bin:$PATH"` to
  `backup_sqlmesh_prod.sh`, `check_backup_health.sh`, `backup_weekly_smoke_test.sh`.
  Proven: under cron's minimal env both `duckdb` and `sqlmesh` now resolve. Syntax-checked.
- Fresh verified backup `20260824T161856Z` (25G, sha 19ad4815…8ad5d); health check OK.

## Commits
- `3f93c7a6` "warehouse: record lookback-3 forward-only stamp on stg_spx_options + eod"
  (the 2 staging models, 2 lines) — `sqlmesh diff prod` shows no model diff after.
- `09c40335` "warehouse: PATCH config.yaml→sqlmesh.yml, HARDEN step-9 shadow_alert, cron PATH fix"
  (4 files: shadow_run.py, reconcile.py, daily_eod_build.py, backup_sqlmesh_prod.sh)
- `ee362fab` "scripts: REPOINT cross-check to prod view, add PATH export for cron"
  (3 files: stg_spx_options_daily.sh, check_backup_health.sh, backup_weekly_smoke_test.sh)
  — both pushed to `master`.

## Hard-won rule
**Resolve symlinks before any destructive op** — `realpath`/`stat -L` the exact target. Identical
byte size between "two" DBs is a same-file signal, not a coincidence. The "stale shadow" framing
entered the directive from a report that never checked the symlink.

## Open / next
- Observe tonight's 23:33 `daily_eod_build` — step 9 should now advance prod and, on any
  `shadow_alert`, exit non-OK (visible in journal + `eod_build.json`).
- Parquet side: first clean post-chmod cycle at next 06:30 UTC.
- Iron-fly re-dispatch: still awaiting PM decisions (a)–(d).
- `/var/tmp/warehouse_shadow` dir itself still exists (symlink + pre-move `backup_archive` twin,
  parity ledger, logs). Its twin-DB cleanup is a separate PM decision — NOT to be repeated blindly.

## Verified facts (PROOF)
- Symlink: `ls -la /var/tmp/ | grep warehouse` → `warehouse_shadow -> /data/warehouse`.
- Restore sha: `10c3a327…390c` (restored db == recorded backup). Fresh: `19ad4815…8ad5d`.
- Backup cron failure: `tail logs/backup.log` → 3× "FATAL: Production database not accessible".
- PATH proof: `env -i PATH=/usr/bin:/bin sh -c 'duckdb ...'` → rc=127 before fix; resolves after.
- `check_intervals prod`: Complete Intervals, 23/23. Frontier: stg_spx_options 8/21 110,034,795 rows.
- Incident record: `/data/warehouse/incident_20260824_prod_db_removed/INCIDENT_20260824.md`.
